// AQM AETHER — Industrial BLE Connection Manager
// Architecture: Resilient Connection Management with Controlled Exponential Backoff
// Resolves Android 147 GATT_CONNECTION_TIMEOUT and provides automatic recovery

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/constants/ble_constants.dart';
import '../core/utils/app_utils.dart';
import '../models/device_model.dart';

typedef OnTemperatureReceived = void Function(double value);
typedef OnHumidityReceived = void Function(double value);
typedef OnIntervalReceived = void Function(int seconds);
typedef OnAlertReceived = void Function(String alert);
typedef OnGasReceived = void Function(int rawAdc);
typedef OnMotionReceived = void Function({
  double? ax,
  double? ay,
  double? az,
  double? gx,
  double? gy,
  double? gz,
});
typedef OnDiscoveredGattTree = void Function(List<DiscoveredServiceInfo> services);
typedef OnStatusChanged = void Function(DeviceConnectionStatus status, String? error);
typedef OnScanResult = void Function(List<ScanResult> results);
typedef OnBleLog = void Function(String message, {bool isError});

class DeviceIdMismatchException implements Exception {
  final String message;
  const DeviceIdMismatchException(this.message);
  @override
  String toString() => message;
}

class BleService {
  // Callbacks
  OnTemperatureReceived? onTemperatureReceived;
  OnHumidityReceived? onHumidityReceived;
  OnIntervalReceived? onIntervalReceived;
  OnAlertReceived? onAlertReceived;
  OnGasReceived? onGasReceived;
  OnMotionReceived? onMotionReceived;
  OnDiscoveredGattTree? onDiscoveredGattTree;
  OnStatusChanged? onStatusChanged;
  OnScanResult? onScanResult;
  OnBleLog? onBleLog;
  void Function(String deviceId)? onDeviceIdReceived;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _tempChar;
  BluetoothCharacteristic? _humidityChar;
  BluetoothCharacteristic? _intervalChar;
  BluetoothCharacteristic? _alertChar;
  BluetoothCharacteristic? _deviceIdChar;
  String? _currentDeviceId;

  // Gas Sensor (MQ-2 / MQ-135)
  BluetoothCharacteristic? _gasChar;

  // MPU6050 Motion Sensors
  BluetoothCharacteristic? _accelXChar;
  BluetoothCharacteristic? _accelYChar;
  BluetoothCharacteristic? _accelZChar;
  BluetoothCharacteristic? _gyroXChar;
  BluetoothCharacteristic? _gyroYChar;
  BluetoothCharacteristic? _gyroZChar;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;
  StreamSubscription<List<int>>? _tempSubscription;
  StreamSubscription<List<int>>? _humiditySubscription;
  StreamSubscription<List<int>>? _alertSubscription;
  StreamSubscription<List<int>>? _gasSubscription;
  StreamSubscription<List<int>>? _accelXSubscription;
  StreamSubscription<List<int>>? _accelYSubscription;
  StreamSubscription<List<int>>? _accelZSubscription;
  StreamSubscription<List<int>>? _gyroXSubscription;
  StreamSubscription<List<int>>? _gyroYSubscription;
  StreamSubscription<List<int>>? _gyroZSubscription;

  Timer? _reconnectTimer;
  Completer<void>? _activeScanCompleter;
  int _reconnectAttempts = 0;
  bool _autoReconnect = true;
  bool _userExplicitDisconnect = false;
  bool _isConnecting = false;
  bool _isFullyConnected = false;
  bool _isDisposing = false;
  bool _isScanning = false;
  bool _isGenericDevice = false;
  String? _expectedDeviceId;

  final List<ScanResult> _scanResults = [];
  final Map<String, ScanResult> _deviceCache = {};
  final List<DiscoveredServiceInfo> _discoveredServices = [];

  // Motion aggregation cache
  double? _lastAx, _lastAy, _lastAz, _lastGx, _lastGy, _lastGz;

  BleService() {
    _initAdapterListener();
  }

  // ── Public Telemetry State ─────────────────────────────────────────────────

  bool get isConnected => _device != null && _device!.isConnected && _isFullyConnected;
  bool get isConnecting => _isConnecting;
  bool get isScanning => _isScanning;
  String? get connectedDeviceId => _device?.remoteId.str;
  BluetoothDevice? get connectedDevice => _device;
  int get reconnectAttempts => _reconnectAttempts;

  bool get serviceFound => _tempChar != null || _humidityChar != null;
  bool get temperatureCharFound => _tempChar != null;
  bool get humidityCharFound => _humidityChar != null;
  bool get samplingIntervalCharFound => _intervalChar != null;
  bool get alertCharFound => _alertChar != null;
  bool get gasCharFound => _gasChar != null;
  bool get deviceIdCharFound => _deviceIdChar != null;
  String? get currentDeviceId => _currentDeviceId;
  bool get mpuCharFound => _accelXChar != null || _gyroXChar != null;
  bool get isGenericDevice => _isGenericDevice;
  List<DiscoveredServiceInfo> get discoveredServices => List.unmodifiable(_discoveredServices);

  void _log(String message, {bool isError = false}) {
    debugPrint('[BLE] $message');
    onBleLog?.call(message, isError: isError);
  }

  // ── Adapter State Monitoring ───────────────────────────────────────────────

  void _initAdapterListener() {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      _log('Bluetooth adapter state: $state');
      if (state == BluetoothAdapterState.on) {
        _log('Bluetooth adapter is ON');
        if (!_userExplicitDisconnect && _device != null && !isConnected && !_isConnecting) {
          _log('Resuming connection now that Bluetooth is ON');
          _scheduleReconnect(immediate: true);
        }
      } else if (state == BluetoothAdapterState.off) {
        _log('Bluetooth adapter turned OFF', isError: true);
        _cancelReconnectTimer();
        _cleanupSubscriptions();
        _isFullyConnected = false;
        onStatusChanged?.call(DeviceConnectionStatus.connectionFailed, 'Bluetooth adapter is disabled. Please enable Bluetooth.');
      }
    });
  }

  // ── Android Bluetooth & Location Permissions ───────────────────────────────

  Future<bool> requestPermissions({bool forConnecting = false}) async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        _log('Checking Android runtime permissions (forConnecting: $forConnecting)…');

        // Request modern Android 12+ permissions
        final scanStatus = await Permission.bluetoothScan.request();
        final locationStatus = await Permission.locationWhenInUse.request();

        PermissionStatus connectStatus = PermissionStatus.granted;
        if (forConnecting) {
          connectStatus = await Permission.bluetoothConnect.request();
        } else {
          connectStatus = await Permission.bluetoothConnect.status;
        }

        _log('Permissions: scan=$scanStatus, connect=$connectStatus, location=$locationStatus');

        if (scanStatus.isPermanentlyDenied) {
          _log('Bluetooth Scan permission permanently denied', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.connectionFailed,
            'Bluetooth Scan permission permanently denied. Please enable in Android App Settings.',
          );
          return false;
        }

        if (forConnecting && connectStatus.isPermanentlyDenied) {
          _log('Bluetooth Connect permission permanently denied', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.connectionFailed,
            'Bluetooth Connect permission permanently denied. Please enable in Android App Settings.',
          );
          return false;
        }

        final scanGranted = scanStatus.isGranted || locationStatus.isGranted;
        if (!scanGranted) {
          _log('Bluetooth Scan or Location permission not granted', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.connectionFailed,
            'Bluetooth Scan or Location permission is required to discover nearby BLE peripherals.',
          );
          return false;
        }

        if (forConnecting && !connectStatus.isGranted && !locationStatus.isGranted) {
          _log('BLUETOOTH_CONNECT permission required for connection', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.connectionFailed,
            'Bluetooth Connect permission is required to establish GATT link.',
          );
          return false;
        }

        try {
          final isLocationOn = await Permission.locationWhenInUse.serviceStatus.isEnabled;
          if (!isLocationOn) {
            _log('Notice: Location Services (GPS) are OFF. Enabling GPS in Android Quick Settings is required on some phones to receive BLE scan responses.');
          }
        } catch (_) {}

        return true;
      } catch (e) {
        _log('Permission check exception: $e', isError: true);
        return false;
      }
    }
    return true;
  }

  // ── Scanning ───────────────────────────────────────────────────────────────

  Future<void> startScan({
    Duration? timeout,
    bool Function(ScanResult result)? onFoundTarget,
  }) async {
    // 1. Prevent overlapping scans
    if (_isScanning) {
      _log('Active scan already running. Stopping previous scan cleanly before restarting.');
      await stopScan();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final permGranted = await requestPermissions(forConnecting: false);
    if (!permGranted) return;

    final btState = await FlutterBluePlus.adapterState.first;
    if (btState != BluetoothAdapterState.on) {
      _log('Cannot start scan: Bluetooth is disabled ($btState)', isError: true);
      onStatusChanged?.call(DeviceConnectionStatus.connectionFailed, 'Please enable Bluetooth on your device');
      return;
    }

    _isScanning = true;
    _activeScanCompleter = Completer<void>();
    _deviceCache.clear();
    _scanResults.clear();
    onScanResult?.call([]);
    onStatusChanged?.call(DeviceConnectionStatus.scanning, null);

    final scanDuration = timeout ?? BleConstants.scanTimeout;
    _log('BLE scanning started for ${scanDuration.inSeconds}s (fineLocation: true, lowLatency)');

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final id = r.device.remoteId.str;
          _deviceCache[id] = r;

          // Target hunt for direct connection
          if (onFoundTarget != null && onFoundTarget(r)) {
            _log('Target device located during scan: ${r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName}');
            onStatusChanged?.call(DeviceConnectionStatus.deviceFound, null);
            if (_activeScanCompleter != null && !_activeScanCompleter!.isCompleted) {
              _activeScanCompleter!.complete();
            }
          }
        }

        // Sort scan results: AQM matching devices first, then by signal strength (RSSI)
        final sortedList = _deviceCache.values.toList()
          ..sort((a, b) {
            final aIsAqm = _isAqmAdv(a);
            final bIsAqm = _isAqmAdv(b);
            if (aIsAqm && !bIsAqm) return -1;
            if (!aIsAqm && bIsAqm) return 1;
            return b.rssi.compareTo(a.rssi);
          });

        _scanResults.clear();
        _scanResults.addAll(sortedList);
        onScanResult?.call(List.unmodifiable(_scanResults));
      }, onError: (e) {
        _log('Scan results stream error: $e', isError: true);
      });

      // Start low-latency continuous scan across all BLE peripherals
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: true,
      );

      // Await scan completion or manual cancellation
      await Future.any([
        _activeScanCompleter!.future,
        Future.delayed(scanDuration),
      ]);
    } catch (e) {
      _log('Scan execution error: $e', isError: true);
      onStatusChanged?.call(DeviceConnectionStatus.connectionFailed, 'Scan failed: $e');
    } finally {
      await stopScan();
    }

    if (!isConnected && !_isConnecting) {
      onStatusChanged?.call(DeviceConnectionStatus.idle, null);
    }
  }

  bool _isAqmAdv(ScanResult r) {
    final targetUuid = BleConstants.serviceUuid.replaceAll('-', '').toLowerCase();
    for (final u in r.advertisementData.serviceUuids) {
      if (u.str128.replaceAll('-', '').toLowerCase() == targetUuid) return true;
    }
    for (final entry in r.advertisementData.serviceData.entries) {
      if (entry.key.str128.replaceAll('-', '').toLowerCase() == targetUuid) return true;
    }
    final name = (r.advertisementData.advName.isNotEmpty
            ? r.advertisementData.advName
            : r.device.platformName)
        .toLowerCase();
    return name.contains('aqm');
  }

  Future<void> stopScan() async {
    if (!_isScanning && _scanSubscription == null) return;
    _isScanning = false;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    if (_activeScanCompleter != null && !_activeScanCompleter!.isCompleted) {
      _activeScanCompleter!.complete();
    }
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _log('BLE scan stopped. Discovered ${_deviceCache.length} peripherals in range.');
  }

  // ── Connection Management ──────────────────────────────────────────────────

  Future<void> connectToDevice(
    BluetoothDevice device, {
    bool isAqm = true,
    String? expectedDeviceId,
  }) async {
    if (_isConnecting) {
      _log('Connection already in progress to ${_device?.remoteId.str}. Rejecting concurrent request.');
      return;
    }

    _userExplicitDisconnect = false;
    _autoReconnect = isAqm;
    _isGenericDevice = !isAqm;
    _device = device;
    _expectedDeviceId = expectedDeviceId;
    _reconnectAttempts = 0;
    _cancelReconnectTimer();
    _discoveredServices.clear();

    await _doConnect();
  }

  Future<void> _doConnect() async {
    if (_device == null || _isConnecting) return;

    _isConnecting = true;
    _isFullyConnected = false;
    _cancelReconnectTimer();

    onStatusChanged?.call(DeviceConnectionStatus.connecting, null);
    _log('Connecting to [${_device!.remoteId.str}] (${_device!.platformName}) [isAQM: ${!_isGenericDevice}]');

    try {
      // 1. Validate permissions
      final permGranted = await requestPermissions(forConnecting: true);
      if (!permGranted) {
        _isConnecting = false;
        return;
      }

      // 2. Stop any active scan and settle Bluetooth controller (essential on Oppo/Android)
      if (_isScanning) {
        await stopScan();
      }
      await Future.delayed(const Duration(milliseconds: 350));

      // 3. Clean up prior subscriptions
      await _cleanupSubscriptions();
      _cleanupCharacteristics();

      // 4. Clear dirty connection states
      if (_device!.isConnected) {
        _log('Device in dirty connected state. Clearing prior GATT client…');
        try {
          await _device!.disconnect(queue: false);
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (_) {}
      }

      // 5. Connect with 15s timeout
      _log('Establishing GATT link (timeout: ${BleConstants.connectTimeout.inSeconds}s)…');
      await _device!.connect(
        timeout: BleConstants.connectTimeout,
        autoConnect: false,
      );
      _log('GATT link established with ${_device!.remoteId.str}');
      onStatusChanged?.call(DeviceConnectionStatus.connected, null);

      // 6. Give GATT stack time to settle
      await Future.delayed(const Duration(milliseconds: 250));

      // 7. Request balanced connection priority to stabilize link
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _device!.requestConnectionPriority(
            connectionPriorityRequest: ConnectionPriority.balanced,
          );
          _log('Applied ConnectionPriority.balanced');
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          _log('requestConnectionPriority notice: $e');
        }
      }

      // 8. Discover services
      if (_isGenericDevice) {
        await _discoverGenericServices();
      } else {
        await _discoverServices();
      }

      // 8.5 Verify Device ID if requested
      if (_expectedDeviceId != null && !_isGenericDevice) {
        onStatusChanged?.call(
          DeviceConnectionStatus.discoveringServices,
          'Verifying Device ID "$_expectedDeviceId"…',
        );

        if (_deviceIdChar == null || !_deviceIdChar!.properties.read) {
          _log('Device ID characteristic missing on peripheral', isError: true);
          throw const DeviceIdMismatchException('Device ID does not match. Please check your ID.');
        }

        final bytes = await _deviceIdChar!.read();
        final reportedId = AppUtils.parseStringPayload(bytes);
        _log('ESP32 reported Device ID: "$reportedId", expected: "$_expectedDeviceId"');

        if (reportedId == null ||
            AppUtils.normalizeDeviceId(reportedId) != AppUtils.normalizeDeviceId(_expectedDeviceId!)) {
          _log('Device ID mismatch: Reported "$reportedId" != Expected "$_expectedDeviceId"', isError: true);
          throw const DeviceIdMismatchException('Device ID does not match. Please check your ID.');
        }

        _currentDeviceId = reportedId;
        onDeviceIdReceived?.call(reportedId);
      }

      // 9. Fully connected and operational
      _isConnecting = false;
      _isFullyConnected = true;
      _reconnectAttempts = 0;

      // 10. Attach runtime connectionState monitor
      _setupConnectionMonitor();

      onStatusChanged?.call(DeviceConnectionStatus.ready, null);
      _log('Device fully configured: telemetry notifications active (State: READY)');
    } on DeviceIdMismatchException catch (e) {
      _isConnecting = false;
      _isFullyConnected = false;
      _autoReconnect = false; // Never auto-reconnect if device ID did not match
      _log('Connection aborted due to Device ID mismatch: ${e.message}', isError: true);
      try {
        await _device?.disconnect(queue: false);
      } catch (_) {}
      _cleanupCharacteristics();
      _cleanupSubscriptions();
      onStatusChanged?.call(DeviceConnectionStatus.connectionFailed, e.message);
    } catch (e) {
      _isConnecting = false;
      _isFullyConnected = false;
      _log('Connection failed at step: $e', isError: true);

      final errStr = e.toString().toLowerCase();
      String userError;
      if (errStr.contains('147') || errStr.contains('timeout')) {
        userError = 'GATT connection timeout (Android 147). Peripheral may be busy, sleeping, or out of range.';
      } else if (errStr.contains('133')) {
        userError = 'Android GATT 133 error. Bluetooth radio busy or advertising restarted.';
      } else if (errStr.contains('permission') || errStr.contains('securityexception')) {
        userError = 'Bluetooth permission denied.';
      } else if (errStr.contains('aqm service not found')) {
        userError = 'Connected, but peripheral does not advertise AQM Service UUID (...9001).';
      } else {
        userError = 'Connection error: ${e.toString()}';
      }

      onStatusChanged?.call(DeviceConnectionStatus.connectionFailed, userError);

      if (_autoReconnect && !_userExplicitDisconnect) {
        _scheduleReconnect();
      }
    }
  }

  // ── Generic Safe Read-Only GATT Discovery ──────────────────────────────────

  Future<void> _discoverGenericServices() async {
    if (_device == null) return;
    onStatusChanged?.call(DeviceConnectionStatus.discoveringServices, null);
    _log('Discovering generic GATT services (Safe Explorer Mode)…');

    final services = await _device!.discoverServices();
    _discoveredServices.clear();

    for (final s in services) {
      final charList = <DiscoveredCharacteristicInfo>[];
      for (final c in s.characteristics) {
        String? readString;
        List<int>? readBytes;

        if (c.properties.read) {
          try {
            readBytes = await c.read().timeout(const Duration(milliseconds: 600));
            readString = String.fromCharCodes(readBytes).trim();
            if (readString.isEmpty) {
              readString = readBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
            }
          } catch (_) {}
        }

        charList.add(DiscoveredCharacteristicInfo(
          uuid: c.uuid.str128,
          canRead: c.properties.read,
          canWrite: c.properties.write || c.properties.writeWithoutResponse,
          canNotify: c.properties.notify,
          canIndicate: c.properties.indicate,
          lastReadString: readString,
          lastReadBytes: readBytes,
        ));
      }

      _discoveredServices.add(DiscoveredServiceInfo(
        uuid: s.uuid.str128,
        isPrimary: s.isPrimary,
        characteristics: charList,
      ));
    }

    _log('Generic GATT exploration complete: ${_discoveredServices.length} services indexed.');
    onDiscoveredGattTree?.call(_discoveredServices);
  }

  void _setupConnectionMonitor() {
    _connectionSubscription?.cancel();
    _connectionSubscription = _device?.connectionState.listen(
      (state) {
        _log('GATT runtime connectionState: $state');
        if (state == BluetoothConnectionState.disconnected) {
          if (_isFullyConnected && !_userExplicitDisconnect && !_isDisposing) {
            _isFullyConnected = false;
            _cleanupCharacteristics();
            _log('Unexpected disconnection from peripheral', isError: true);
            onStatusChanged?.call(
              DeviceConnectionStatus.disconnected,
              'Connection to ${_device?.platformName ?? "AQM peripheral"} lost',
            );

            if (_autoReconnect) {
              _scheduleReconnect();
            }
          }
        }
      },
      onError: (e) {
        _log('Connection monitor stream error: $e', isError: true);
      },
    );
  }

  // ── Reconnection Strategy with Controlled Backoff & Advertising Scan ────────

  void _scheduleReconnect({bool immediate = false}) {
    if (_userExplicitDisconnect || _isDisposing) return;

    if (_reconnectAttempts >= BleConstants.maxAutoReconnectAttempts) {
      _log('Max auto-reconnect attempts (${BleConstants.maxAutoReconnectAttempts}) reached. Halting auto-retry.', isError: true);
      _cancelReconnectTimer();
      onStatusChanged?.call(
        DeviceConnectionStatus.connectionFailed,
        'Reconnection halted after ${BleConstants.maxAutoReconnectAttempts} attempts. Tap RECONNECT to retry manually.',
      );
      return;
    }

    _reconnectTimer?.cancel();

    Duration delay;
    if (immediate || _reconnectAttempts == 0) {
      delay = Duration.zero;
    } else if (_reconnectAttempts < BleConstants.reconnectBackoff.length) {
      delay = BleConstants.reconnectBackoff[_reconnectAttempts];
    } else {
      delay = BleConstants.reconnectMaxInterval;
    }

    _reconnectAttempts++;
    _log('Scheduling reconnect attempt $_reconnectAttempts/${BleConstants.maxAutoReconnectAttempts} in ${delay.inSeconds}s');

    onStatusChanged?.call(
      DeviceConnectionStatus.reconnecting,
      'Connection lost. Reconnecting (attempt $_reconnectAttempts/${BleConstants.maxAutoReconnectAttempts})…',
    );

    _reconnectTimer = Timer(delay, () async {
      if (!_userExplicitDisconnect && !_isDisposing) {
        try {
          await _device?.disconnect(queue: false);
        } catch (_) {}

        // If after 1st attempt the link failed, perform a quick 3s targeted scan to refresh the advertising handle
        if (_reconnectAttempts >= 2) {
          _log('Searching for refreshed ESP32 advertising instance…');
          BluetoothDevice? refreshedDevice;
          try {
            final scanSub = FlutterBluePlus.scanResults.listen((results) {
              for (final r in results) {
                if (_isAqmAdv(r)) {
                  refreshedDevice = r.device;
                }
              }
            });
            await FlutterBluePlus.startScan(
              timeout: const Duration(seconds: 3),
              androidUsesFineLocation: true,
              androidScanMode: AndroidScanMode.lowLatency,
            );
            await Future.delayed(const Duration(seconds: 3));
            await FlutterBluePlus.stopScan();
            await scanSub.cancel();
          } catch (_) {}

          if (refreshedDevice != null) {
            _device = refreshedDevice;
            _log('Located fresh ESP32 advertising instance: [${_device!.remoteId.str}]');
          }
        }

        await Future.delayed(const Duration(milliseconds: 300));
        await _doConnect();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _userExplicitDisconnect = true;
    _autoReconnect = false;
    _isConnecting = false;
    _isFullyConnected = false;
    _cancelReconnectTimer();

    _log('Explicit disconnect requested by user');
    onStatusChanged?.call(DeviceConnectionStatus.disconnecting, null);

    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    await _cleanupSubscriptions();
    _cleanupCharacteristics();

    try {
      await _device?.disconnect(queue: false);
    } catch (e) {
      _log('Disconnect notice: $e');
    }

    _device = null;
    _reconnectAttempts = 0;
    onStatusChanged?.call(DeviceConnectionStatus.disconnected, null);
  }

  // ── GATT Service Discovery & Subscription ──────────────────────────────────

  Future<void> _discoverServices() async {
    if (_device == null) return;

    onStatusChanged?.call(DeviceConnectionStatus.discoveringServices, null);
    _log('Discovering GATT services on peripheral…');

    final services = await _device!.discoverServices();
    _log('Discovered ${services.length} GATT services on peripheral');

    String norm(String u) => u.replaceAll('-', '').toLowerCase();

    final targetServiceUuid = norm(BleConstants.serviceUuid);
    BluetoothService? aqmService;

    for (final s in services) {
      if (norm(s.uuid.str128) == targetServiceUuid) {
        aqmService = s;
        break;
      }
    }

    if (aqmService == null) {
      final foundUuids = services.map((s) => s.uuid.str128).join(', ');
      _log('AQM Service UUID ${BleConstants.serviceUuid} not found. Discovered: [$foundUuids]', isError: true);
      throw Exception('AQM Service not found on device');
    }

    _log('AQM GATT Service located: ${aqmService.uuid.str128}');

    final targetTempUuid = norm(BleConstants.temperatureUuid);
    final targetHumUuid = norm(BleConstants.humidityUuid);
    final targetIntervalUuid = norm(BleConstants.samplingIntervalUuid);
    final targetAlertUuid = norm(BleConstants.alertUuid);
    final targetGasUuid = norm(BleConstants.gasUuid);
    final targetDeviceIdUuid = norm(BleConstants.deviceIdUuid);
    final targetAxUuid = norm(BleConstants.accelXUuid);
    final targetAyUuid = norm(BleConstants.accelYUuid);
    final targetAzUuid = norm(BleConstants.accelZUuid);
    final targetGxUuid = norm(BleConstants.gyroXUuid);
    final targetGyUuid = norm(BleConstants.gyroYUuid);
    final targetGzUuid = norm(BleConstants.gyroZUuid);

    for (final c in aqmService.characteristics) {
      final cNorm = norm(c.uuid.str128);
      if (cNorm == targetTempUuid) {
        _tempChar = c;
        _log('Temperature characteristic mapped');
      } else if (cNorm == targetHumUuid) {
        _humidityChar = c;
        _log('Humidity characteristic mapped');
      } else if (cNorm == targetIntervalUuid) {
        _intervalChar = c;
        _log('Sampling interval characteristic mapped');
      } else if (cNorm == targetAlertUuid) {
        _alertChar = c;
        _log('Alert characteristic mapped');
      } else if (cNorm == targetGasUuid) {
        _gasChar = c;
        _log('MQ-2 / MQ-135 Gas characteristic mapped');
      } else if (cNorm == targetDeviceIdUuid) {
        _deviceIdChar = c;
        _log('Device Identity characteristic mapped (UUID: ${c.uuid.str128})');
      } else if (cNorm == targetAxUuid) {
        _accelXChar = c;
      } else if (cNorm == targetAyUuid) {
        _accelYChar = c;
      } else if (cNorm == targetAzUuid) {
        _accelZChar = c;
      } else if (cNorm == targetGxUuid) {
        _gyroXChar = c;
      } else if (cNorm == targetGyUuid) {
        _gyroYChar = c;
      } else if (cNorm == targetGzUuid) {
        _gyroZChar = c;
      }
    }

    if (_tempChar == null && _humidityChar == null) {
      _log('Neither temperature nor humidity characteristics found', isError: true);
      throw Exception('Temperature and Humidity characteristics missing from AQM service');
    }

    onStatusChanged?.call(DeviceConnectionStatus.subscribingNotifications, null);
    _log('Subscribing to notification streams sequentially…');

    await _subscribeNotifications();
    await _readInitialValues();
  }

  void _emitMotion() {
    onMotionReceived?.call(
      ax: _lastAx,
      ay: _lastAy,
      az: _lastAz,
      gx: _lastGx,
      gy: _lastGy,
      gz: _lastGz,
    );
  }

  Future<void> _subscribeNotifications() async {
    // 1. Temperature Stream
    if (_tempChar != null) {
      _tempSubscription?.cancel();
      _tempSubscription = _tempChar!.onValueReceived.listen((bytes) {
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          onTemperatureReceived?.call(value);
        }
      }, onError: (e) {
        _log('Temperature notification error: $e', isError: true);
      });

      if (_tempChar!.properties.notify) {
        try {
          await _tempChar!.setNotifyValue(true);
          _log('Temperature notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Temp setNotifyValue notice: $e');
        }
      }
    }

    // 2. Humidity Stream
    if (_humidityChar != null) {
      _humiditySubscription?.cancel();
      _humiditySubscription = _humidityChar!.onValueReceived.listen((bytes) {
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          onHumidityReceived?.call(value);
        }
      }, onError: (e) {
        _log('Humidity notification error: $e', isError: true);
      });

      if (_humidityChar!.properties.notify) {
        try {
          await _humidityChar!.setNotifyValue(true);
          _log('Humidity notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Humidity setNotifyValue notice: $e');
        }
      }
    }

    // 3. Alert Stream
    if (_alertChar != null) {
      _alertSubscription?.cancel();
      _alertSubscription = _alertChar!.onValueReceived.listen((bytes) {
        final alert = AppUtils.parseAlertPayload(bytes);
        onAlertReceived?.call(alert);
      }, onError: (e) {
        _log('Alert notification error: $e', isError: true);
      });

      if (_alertChar!.properties.notify) {
        try {
          await _alertChar!.setNotifyValue(true);
          _log('Alert notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Alert setNotifyValue notice: $e');
        }
      }
    }

    // 4. MQ-2 / MQ-135 Gas Stream
    if (_gasChar != null) {
      _gasSubscription?.cancel();
      _gasSubscription = _gasChar!.onValueReceived.listen((bytes) {
        final val = AppUtils.parseGasPayload(bytes);
        if (val != null) {
          onGasReceived?.call(val);
        }
      }, onError: (e) {
        _log('Gas notification error: $e', isError: true);
      });

      if (_gasChar!.properties.notify) {
        try {
          await _gasChar!.setNotifyValue(true);
          _log('Gas notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Gas setNotifyValue notice: $e');
        }
      }
    }

    // 5. MPU6050 Motion Streams
    final motionChars = [
      MapEntry(_accelXChar, (double v) => _lastAx = v),
      MapEntry(_accelYChar, (double v) => _lastAy = v),
      MapEntry(_accelZChar, (double v) => _lastAz = v),
      MapEntry(_gyroXChar, (double v) => _lastGx = v),
      MapEntry(_gyroYChar, (double v) => _lastGy = v),
      MapEntry(_gyroZChar, (double v) => _lastGz = v),
    ];

    for (final entry in motionChars) {
      final char = entry.key;
      final setter = entry.value;
      if (char != null) {
        char.onValueReceived.listen((bytes) {
          final v = AppUtils.parseFloatPayload(bytes);
          if (v != null) {
            setter(v);
            _emitMotion();
          }
        }, onError: (e) {
          _log('Motion stream error: $e', isError: true);
        });

        if (char.properties.notify) {
          try {
            await char.setNotifyValue(true);
            await Future.delayed(const Duration(milliseconds: 80));
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _readInitialValues() async {
    _log('Reading initial values from characteristics…');

    // Read initial temperature
    if (_tempChar != null && _tempChar!.properties.read) {
      try {
        final bytes = await _tempChar!.read();
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          _log('Initial Temperature: $value°C');
          onTemperatureReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial temperature read notice: $e');
      }
    }

    // Read initial humidity
    if (_humidityChar != null && _humidityChar!.properties.read) {
      try {
        final bytes = await _humidityChar!.read();
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          _log('Initial Humidity: $value%');
          onHumidityReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial humidity read notice: $e');
      }
    }

    // Read initial sampling interval
    if (_intervalChar != null && _intervalChar!.properties.read) {
      try {
        final bytes = await _intervalChar!.read();
        final value = AppUtils.parseIntervalPayload(bytes);
        if (value != null) {
          _log('Initial Sampling Interval: ${value}s');
          onIntervalReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial interval read notice: $e');
      }
    }

    // Read initial alert
    if (_alertChar != null && _alertChar!.properties.read) {
      try {
        final bytes = await _alertChar!.read();
        final alert = AppUtils.parseAlertPayload(bytes);
        _log('Initial Alert Status: $alert');
        onAlertReceived?.call(alert);
      } catch (e) {
        _log('Initial alert read notice: $e');
      }
    }

    // Read initial Gas
    if (_gasChar != null && _gasChar!.properties.read) {
      try {
        final bytes = await _gasChar!.read();
        final val = AppUtils.parseGasPayload(bytes);
        if (val != null) {
          _log('Initial Gas RAW ADC: $val');
          onGasReceived?.call(val);
        }
      } catch (e) {
        _log('Initial gas read notice: $e');
      }
    }

    // Read Device ID identity
    if (_deviceIdChar != null && _deviceIdChar!.properties.read) {
      try {
        final bytes = await _deviceIdChar!.read();
        final id = AppUtils.parseStringPayload(bytes);
        if (id != null) {
          _currentDeviceId = id;
          _log('Verified Device ID from GATT: $id');
          onDeviceIdReceived?.call(id);
        }
      } catch (e) {
        _log('Device ID read notice: $e');
      }
    }

    // Read initial Motion if readable
    if (_accelXChar != null && _accelXChar!.properties.read) {
      try {
        final bytes = await _accelXChar!.read();
        _lastAx = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_accelYChar != null && _accelYChar!.properties.read) {
      try {
        final bytes = await _accelYChar!.read();
        _lastAy = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_accelZChar != null && _accelZChar!.properties.read) {
      try {
        final bytes = await _accelZChar!.read();
        _lastAz = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_gyroXChar != null && _gyroXChar!.properties.read) {
      try {
        final bytes = await _gyroXChar!.read();
        _lastGx = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_gyroYChar != null && _gyroYChar!.properties.read) {
      try {
        final bytes = await _gyroYChar!.read();
        _lastGy = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_gyroZChar != null && _gyroZChar!.properties.read) {
      try {
        final bytes = await _gyroZChar!.read();
        _lastGz = AppUtils.parseFloatPayload(bytes);
      } catch (_) {}
    }
    if (_lastAx != null || _lastGx != null) {
      _emitMotion();
    }
  }

  // ── Sampling Interval Write ────────────────────────────────────────────────

  Future<bool> writeSamplingInterval(int seconds) async {
    if (_intervalChar == null) {
      _log('Interval characteristic not available', isError: true);
      return false;
    }

    if (!_intervalChar!.properties.write &&
        !_intervalChar!.properties.writeWithoutResponse) {
      _log('Interval characteristic does not support write', isError: true);
      return false;
    }

    try {
      final bytes = AppUtils.encodeInterval(seconds);
      _log('Writing sampling interval $seconds s (ASCII payload) to ESP32…');

      if (_intervalChar!.properties.write) {
        await _intervalChar!.write(bytes, withoutResponse: false);
      } else {
        await _intervalChar!.write(bytes, withoutResponse: true);
      }

      // Read back to confirm write acceptance by peripheral
      if (_intervalChar!.properties.read) {
        await Future.delayed(const Duration(milliseconds: 300));
        final readBytes = await _intervalChar!.read();
        final confirmed = AppUtils.parseIntervalPayload(readBytes);
        if (confirmed != null) {
          _log('Sampling interval confirmed by ESP32: ${confirmed}s');
          onIntervalReceived?.call(confirmed);
        }
      }

      return true;
    } catch (e) {
      _log('Write sampling interval error: $e', isError: true);
      return false;
    }
  }

  // ── Standalone Device ID Verification ──────────────────────────────────────

  /// Connects briefly to candidate peripheral to read the device identity characteristic
  Future<String?> readDeviceIdentity(BluetoothDevice device) async {
    try {
      _log('Inspecting candidate device for Device ID: ${device.remoteId.str}');
      if (device.isConnected) {
        try {
          await device.disconnect(queue: false);
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (_) {}
      }

      await device.connect(timeout: const Duration(seconds: 4), autoConnect: false);
      await Future.delayed(const Duration(milliseconds: 200));

      final services = await device.discoverServices();
      final targetServiceUuid = BleConstants.serviceUuid.replaceAll('-', '').toLowerCase();
      final targetDevIdUuid = BleConstants.deviceIdUuid.replaceAll('-', '').toLowerCase();

      for (final s in services) {
        if (s.uuid.str128.replaceAll('-', '').toLowerCase() == targetServiceUuid) {
          for (final c in s.characteristics) {
            if (c.uuid.str128.replaceAll('-', '').toLowerCase() == targetDevIdUuid) {
              final bytes = await c.read();
              final id = AppUtils.parseStringPayload(bytes);
              _log('Candidate ${device.remoteId.str} returned Device ID: $id');
              try {
                await device.disconnect(queue: false);
              } catch (_) {}
              return id;
            }
          }
        }
      }

      try {
        await device.disconnect(queue: false);
      } catch (_) {}
      return null;
    } catch (e) {
      _log('Could not read identity characteristic from ${device.remoteId.str}: $e');
      try {
        await device.disconnect(queue: false);
      } catch (_) {}
      return null;
    }
  }

  // ── Lifecycle Support ──────────────────────────────────────────────────────

  void handleAppResume() {
    _log('App resumed to foreground');
    if (!_userExplicitDisconnect && _device != null && !isConnected && !_isConnecting) {
      _log('Triggering foreground reconnect attempt');
      _scheduleReconnect(immediate: true);
    }
  }

  void handleAppPause() {
    _log('App entered background');
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────

  Future<void> _cleanupSubscriptions() async {
    await _tempSubscription?.cancel();
    _tempSubscription = null;
    await _humiditySubscription?.cancel();
    _humiditySubscription = null;
    await _alertSubscription?.cancel();
    _alertSubscription = null;
    await _gasSubscription?.cancel();
    _gasSubscription = null;
    await _accelXSubscription?.cancel();
    _accelXSubscription = null;
    await _accelYSubscription?.cancel();
    _accelYSubscription = null;
    await _accelZSubscription?.cancel();
    _accelZSubscription = null;
    await _gyroXSubscription?.cancel();
    _gyroXSubscription = null;
    await _gyroYSubscription?.cancel();
    _gyroYSubscription = null;
    await _gyroZSubscription?.cancel();
    _gyroZSubscription = null;
  }

  void _cleanupCharacteristics() {
    _tempChar = null;
    _humidityChar = null;
    _intervalChar = null;
    _alertChar = null;
    _gasChar = null;
    _deviceIdChar = null;
    _currentDeviceId = null;
    _accelXChar = null;
    _accelYChar = null;
    _accelZChar = null;
    _gyroXChar = null;
    _gyroYChar = null;
    _gyroZChar = null;
    _lastAx = null;
    _lastAy = null;
    _lastAz = null;
    _lastGx = null;
    _lastGy = null;
    _lastGz = null;
  }

  void dispose() {
    _isDisposing = true;
    _cancelReconnectTimer();
    _cleanupSubscriptions();
    _connectionSubscription?.cancel();
    _adapterSubscription?.cancel();
    _scanSubscription?.cancel();
    try {
      _device?.disconnect(queue: false);
    } catch (_) {}
    _device = null;
  }
}
