// AQM AETHER — Industrial BLE Connection Manager
// Architecture: Resilient Connection Management with Exponential Backoff
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

  BluetoothDevice? _device;
  BluetoothCharacteristic? _tempChar;
  BluetoothCharacteristic? _humidityChar;
  BluetoothCharacteristic? _intervalChar;
  BluetoothCharacteristic? _alertChar;

  // Gas Sensor (MQ-135)
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
  int _reconnectAttempts = 0;
  bool _autoReconnect = true;
  bool _userExplicitDisconnect = false;
  bool _isConnecting = false;
  bool _isFullyConnected = false;
  bool _isDisposing = false;
  bool _isScanning = false;
  bool _isGenericDevice = false;

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
  int get reconnectAttempts => _reconnectAttempts;

  bool get serviceFound => _tempChar != null || _humidityChar != null;
  bool get temperatureCharFound => _tempChar != null;
  bool get humidityCharFound => _humidityChar != null;
  bool get samplingIntervalCharFound => _intervalChar != null;
  bool get alertCharFound => _alertChar != null;
  bool get gasCharFound => _gasChar != null;
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
        onStatusChanged?.call(DeviceConnectionStatus.error, 'Please enable Bluetooth');
      }
    });
  }

  // ── Android Bluetooth Permissions ──────────────────────────────────────────

  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        _log('Validating Android Bluetooth & Location runtime permissions…');

        // Request modern Android 12+ permissions first
        final scanStatus = await Permission.bluetoothScan.request();
        final connectStatus = await Permission.bluetoothConnect.request();

        // Also request location for older Android versions (<= API 30) or OEM stacks (Oppo, ColorOS)
        final locationStatus = await Permission.locationWhenInUse.request();

        _log('Permissions: scan=$scanStatus, connect=$connectStatus, location=$locationStatus');

        if (connectStatus.isPermanentlyDenied || scanStatus.isPermanentlyDenied) {
          _log('Bluetooth permissions permanently denied', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.error,
            'Bluetooth permissions permanently denied. Please allow in Android App Settings.',
          );
          return false;
        }

        // On Android 12+, bluetoothConnect is strictly required to call connect()
        if (connectStatus.isDenied) {
          _log('BLUETOOTH_CONNECT permission was denied', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.error,
            'Bluetooth Connect permission required to connect to AQM-Kamalesh',
          );
          return false;
        }

        if (scanStatus.isDenied && locationStatus.isDenied) {
          _log('Bluetooth Scan and Location permissions denied', isError: true);
          onStatusChanged?.call(
            DeviceConnectionStatus.error,
            'Bluetooth Scan or Location permission required to discover ESP32',
          );
          return false;
        }

        try {
          final isLocationOn = await Permission.locationWhenInUse.serviceStatus.isEnabled;
          if (!isLocationOn) {
            _log('Notice: Location Services (GPS) are currently turned OFF. On Oppo/Android phones, enabling Location in Quick Settings ensures all BLE devices are discovered.');
          }
        } catch (_) {}

        _log('Bluetooth permissions verified and active');
        return true;
      } catch (e) {
        _log('Permission request error: $e', isError: true);
        return false;
      }
    }
    return true;
  }

  // ── Scanning ───────────────────────────────────────────────────────────────

  Future<void> startScan({Duration? timeout, bool Function(ScanResult result)? onFoundTarget}) async {
    if (_isScanning) {
      _log('Scan already in progress. Re-using active scan.');
      return;
    }

    final permGranted = await requestPermissions();
    if (!permGranted) return;

    final btState = await FlutterBluePlus.adapterState.first;
    if (btState != BluetoothAdapterState.on) {
      _log('Cannot start scan: Bluetooth is not ON ($btState)', isError: true);
      onStatusChanged?.call(DeviceConnectionStatus.error, 'Please enable Bluetooth to discover devices');
      return;
    }

    _isScanning = true;
    _deviceCache.clear();
    _scanResults.clear();
    onScanResult?.call([]);
    onStatusChanged?.call(DeviceConnectionStatus.scanning, null);
    _log('BLE scanning started (androidUsesFineLocation: true, lowLatency)');

    final scanDuration = timeout ?? BleConstants.scanTimeout;

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();

      final completer = Completer<void>();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final id = r.device.remoteId.str;
          final existing = _deviceCache[id];

          if (existing == null) {
            _deviceCache[id] = r;
            final name = r.device.platformName.isNotEmpty
                ? r.device.platformName
                : (r.advertisementData.advName.isNotEmpty
                    ? r.advertisementData.advName
                    : '(unnamed)');
            _log('Discovered BLE peripheral: "$name" [$id] RSSI: ${r.rssi} dBm');
          } else {
            // Update device in cache with latest packet & RSSI
            _deviceCache[id] = r;
          }

          // If target hunt requested (for direct connection)
          if (onFoundTarget != null && onFoundTarget(r)) {
            _log('Target device located during scan: ${r.device.platformName.isNotEmpty ? r.device.platformName : r.advertisementData.advName}');
            if (!completer.isCompleted) completer.complete();
          }
        }

        _scanResults.clear();
        _scanResults.addAll(_deviceCache.values);
        onScanResult?.call(List.unmodifiable(_scanResults));
      }, onError: (e) {
        _log('Scan results stream error: $e', isError: true);
      });

      // Start scan with fine location and low latency for complete discovery on all Android phones
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
        androidScanMode: AndroidScanMode.lowLatency,
        continuousUpdates: true,
      );

      if (onFoundTarget != null) {
        await Future.any([
          completer.future,
          Future.delayed(scanDuration),
        ]);
      } else {
        await Future.delayed(scanDuration);
      }
    } catch (e) {
      _log('Scan error: $e', isError: true);
      _isScanning = false;
      onStatusChanged?.call(DeviceConnectionStatus.error, 'Scan failed: $e');
      return;
    } finally {
      await stopScan();
    }

    if (!isConnected && !_isConnecting) {
      onStatusChanged?.call(DeviceConnectionStatus.idle, null);
    }
  }

  Future<void> stopScan() async {
    if (!_isScanning && _scanSubscription == null) return;
    _isScanning = false;
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _log('BLE scanning stopped. Cached ${_deviceCache.length} peripherals.');
  }

  // ── Connection Management ──────────────────────────────────────────────────

  Future<void> connectToDevice(BluetoothDevice device, {bool isAqm = true}) async {
    // 1. Prevent concurrent connection attempts
    if (_isConnecting) {
      _log('Connection attempt already in progress to ${_device?.remoteId.str}. Ignoring overlapping request.');
      return;
    }

    _userExplicitDisconnect = false;
    _autoReconnect = isAqm; // Generic devices do not auto-reconnect
    _isGenericDevice = !isAqm;
    _device = device;
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
    _log('Connection initiated to peripheral [${_device!.remoteId.str}] (${_device!.platformName}) [isAQM: ${!_isGenericDevice}]');

    try {
      // 1. Validate permissions before attempting connection
      final permGranted = await requestPermissions();
      if (!permGranted) {
        _isConnecting = false;
        return;
      }

      // 2. Tear down any active scan cleanly and wait for radio idle settling
      if (_isScanning) {
        await stopScan();
      }
      // Vital for Android/Oppo: Allow Bluetooth controller to switch from scanning to connection mode
      await Future.delayed(const Duration(milliseconds: 350));

      // 3. Clean up prior subscriptions & characteristics
      await _cleanupSubscriptions();
      _cleanupCharacteristics();

      // 4. If device is already in a dirty or dangling state, force disconnect first
      if (_device!.isConnected) {
        _log('Device in dirty connected state. Clearing prior GATT client…');
        try {
          await _device!.disconnect(queue: false);
          await Future.delayed(const Duration(milliseconds: 250));
        } catch (_) {}
      }

      // 5. Connect with controlled timeout (15 seconds)
      _log('Establishing physical GATT link (timeout: ${BleConstants.connectTimeout.inSeconds}s)…');
      await _device!.connect(
        timeout: BleConstants.connectTimeout,
        autoConnect: false,
      );
      _log('Physical link established with ${_device!.remoteId.str}');

      // 6. Give Android GATT stack time to settle before querying services
      await Future.delayed(const Duration(milliseconds: 250));

      // 7. Request balanced connection priority on Android to prevent supervision timeout 147
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          await _device!.requestConnectionPriority(
            connectionPriorityRequest: ConnectionPriority.balanced,
          );
          _log('Set ConnectionPriority.balanced to stabilize GATT link');
          await Future.delayed(const Duration(milliseconds: 150));
        } catch (e) {
          _log('requestConnectionPriority non-fatal notice: $e');
        }
      }

      // 8. Discover services
      if (_isGenericDevice) {
        await _discoverGenericServices();
      } else {
        await _discoverServices();
      }

      // 9. Now that services, characteristics, and notifications are fully verified:
      _isConnecting = false;
      _isFullyConnected = true;
      _reconnectAttempts = 0;

      // 10. Attach runtime connectionState monitor
      _setupConnectionMonitor();

      onStatusChanged?.call(DeviceConnectionStatus.connected, null);
      _log('Device fully connected, GATT exploration & telemetry active');
    } catch (e) {
      _isConnecting = false;
      _isFullyConnected = false;
      _log('Connection failed at step: $e', isError: true);

      // Parse error code for informative user messaging
      final errStr = e.toString().toLowerCase();
      String userError;
      if (errStr.contains('147') || errStr.contains('timeout')) {
        userError = 'Connection failed: GATT connection timeout (Android 147). Peripheral may be busy or out of range.';
      } else if (errStr.contains('133')) {
        userError = 'Connection failed: Android GATT 133. Device radio busy.';
      } else if (errStr.contains('securityexception') || errStr.contains('permission')) {
        userError = 'Connection failed: Bluetooth permission denied.';
      } else if (errStr.contains('service not found')) {
        userError = 'Connection established, but AQM Service UUID was not found on device.';
      } else {
        userError = 'Connection error: ${e.toString()}';
      }

      onStatusChanged?.call(DeviceConnectionStatus.error, userError);

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

        // Safely read non-intrusively if readable
        if (c.properties.read) {
          try {
            readBytes = await c.read().timeout(const Duration(milliseconds: 600));
            readString = String.fromCharCodes(readBytes).trim();
            if (readString.isEmpty) {
              readString = readBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
            }
          } catch (_) {
            // Some characteristics may require encryption/auth; ignore read errors safely
          }
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
        _log('GATT runtime state: $state');
        if (state == BluetoothConnectionState.disconnected) {
          if (_isFullyConnected && !_userExplicitDisconnect && !_isDisposing) {
            _isFullyConnected = false;
            _cleanupCharacteristics();
            _log('Unexpected disconnection from peripheral', isError: true);
            onStatusChanged?.call(
              DeviceConnectionStatus.disconnected,
              'Connection to AQM-Kamalesh lost',
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

  // ── Reconnection Strategy with Exponential Backoff ─────────────────────────

  void _scheduleReconnect({bool immediate = false}) {
    if (_userExplicitDisconnect || _isDisposing || _device == null) return;

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
    _log('Scheduling reconnect attempt $_reconnectAttempts after ${delay.inSeconds}s');

    onStatusChanged?.call(
      DeviceConnectionStatus.reconnecting,
      'Connection interrupted. Reconnecting (attempt $_reconnectAttempts)…',
    );

    _reconnectTimer = Timer(delay, () async {
      if (!_userExplicitDisconnect && !_isDisposing && _device != null) {
        try {
          await _device?.disconnect(queue: false);
        } catch (_) {}

        await Future.delayed(const Duration(milliseconds: 300));
        await _doConnect();
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ── Disconnect ─────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _userExplicitDisconnect = true;
    _autoReconnect = false;
    _isConnecting = false;
    _isFullyConnected = false;
    _cancelReconnectTimer();

    _log('Explicit disconnect requested by user');

    _connectionSubscription?.cancel();
    _connectionSubscription = null;

    await _cleanupSubscriptions();
    _cleanupCharacteristics();

    try {
      await _device?.disconnect(queue: false);
    } catch (e) {
      _log('Disconnect error: $e');
    }

    _device = null;
    _reconnectAttempts = 0;
    onStatusChanged?.call(DeviceConnectionStatus.disconnected, null);
  }

  // ── GATT Service Discovery & Subscription ──────────────────────────────────

  Future<void> _discoverServices() async {
    if (_device == null) return;

    onStatusChanged?.call(DeviceConnectionStatus.discoveringServices, null);
    _log('Discovering GATT services…');

    final services = await _device!.discoverServices();
    _log('Discovered ${services.length} GATT services on peripheral');

    // Helper: Normalize UUIDs (lowercase, strip dashes) for flawless comparison
    String norm(String u) => u.replaceAll('-', '').toLowerCase();

    final targetServiceUuid = norm(BleConstants.serviceUuid);
    BluetoothService? aqmService;

    for (final s in services) {
      final sNorm = norm(s.uuid.str128);
      if (sNorm == targetServiceUuid) {
        aqmService = s;
        break;
      }
    }

    if (aqmService == null) {
      final foundUuids = services.map((s) => s.uuid.str128).join(', ');
      _log('AQM Service UUID ${BleConstants.serviceUuid} not found. Available services: [$foundUuids]', isError: true);
      throw Exception('AQM Service not found. Discovered: [$foundUuids]');
    }

    _log('AQM GATT Service located: ${aqmService.uuid.str128}');

    // Map characteristics using normalized UUIDs
    final targetTempUuid = norm(BleConstants.temperatureUuid);
    final targetHumUuid = norm(BleConstants.humidityUuid);
    final targetIntervalUuid = norm(BleConstants.samplingIntervalUuid);
    final targetAlertUuid = norm(BleConstants.alertUuid);
    final targetGasUuid = norm(BleConstants.gasUuid);
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
        _log('Temperature characteristic discovered');
      } else if (cNorm == targetHumUuid) {
        _humidityChar = c;
        _log('Humidity characteristic discovered');
      } else if (cNorm == targetIntervalUuid) {
        _intervalChar = c;
        _log('Sampling interval characteristic discovered');
      } else if (cNorm == targetAlertUuid) {
        _alertChar = c;
        _log('Alert characteristic discovered');
      } else if (cNorm == targetGasUuid) {
        _gasChar = c;
        _log('MQ-135 Gas characteristic discovered');
      } else if (cNorm == targetAxUuid) {
        _accelXChar = c;
        _log('MPU6050 Accel-X characteristic discovered');
      } else if (cNorm == targetAyUuid) {
        _accelYChar = c;
        _log('MPU6050 Accel-Y characteristic discovered');
      } else if (cNorm == targetAzUuid) {
        _accelZChar = c;
        _log('MPU6050 Accel-Z characteristic discovered');
      } else if (cNorm == targetGxUuid) {
        _gyroXChar = c;
        _log('MPU6050 Gyro-X characteristic discovered');
      } else if (cNorm == targetGyUuid) {
        _gyroYChar = c;
        _log('MPU6050 Gyro-Y characteristic discovered');
      } else if (cNorm == targetGzUuid) {
        _gyroZChar = c;
        _log('MPU6050 Gyro-Z characteristic discovered');
      }
    }

    if (_tempChar == null && _humidityChar == null) {
      _log('Neither temperature nor humidity characteristics were found', isError: true);
      throw Exception('Temperature and Humidity characteristics missing from AQM service');
    }

    if (_gasChar == null) {
      _log('MQ-135 characteristic not present in GATT service.');
    }
    if (_accelXChar == null && _gyroXChar == null) {
      _log('MPU6050 characteristics not present in GATT service (Hardware / firmware absent).');
    }

    onStatusChanged?.call(DeviceConnectionStatus.subscribingNotifications, null);
    _log('Subscribing to notification streams sequentially…');

    // Sequential subscription with slight delay between descriptor writes
    await _subscribeNotifications();

    // Read initial values so UI displays immediate data
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
        _log('Temperature notification stream error: $e', isError: true);
      });

      if (_tempChar!.properties.notify) {
        try {
          await _tempChar!.setNotifyValue(true);
          _log('Temperature notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Temp setNotifyValue error: $e');
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
        _log('Humidity notification stream error: $e', isError: true);
      });

      if (_humidityChar!.properties.notify) {
        try {
          await _humidityChar!.setNotifyValue(true);
          _log('Humidity notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Humidity setNotifyValue error: $e');
        }
      }
    }

    // 3. Alert Stream
    if (_alertChar != null) {
      _alertSubscription?.cancel();
      _alertSubscription = _alertChar!.onValueReceived.listen((bytes) {
        final alert = String.fromCharCodes(bytes).trim();
        if (alert.isNotEmpty) {
          onAlertReceived?.call(alert);
        }
      }, onError: (e) {
        _log('Alert notification stream error: $e', isError: true);
      });

      if (_alertChar!.properties.notify) {
        try {
          await _alertChar!.setNotifyValue(true);
          _log('Alert notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Alert setNotifyValue error: $e');
        }
      }
    }

    // 4. MQ-135 Gas Stream
    if (_gasChar != null) {
      _gasSubscription?.cancel();
      _gasSubscription = _gasChar!.onValueReceived.listen((bytes) {
        final val = AppUtils.parseGasPayload(bytes);
        if (val != null) {
          onGasReceived?.call(val);
        }
      }, onError: (e) {
        _log('Gas notification stream error: $e', isError: true);
      });

      if (_gasChar!.properties.notify) {
        try {
          await _gasChar!.setNotifyValue(true);
          _log('MQ-135 Gas notifications enabled');
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          _log('Gas setNotifyValue error: $e');
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
    _log('Reading initial characteristic values from peripheral…');

    // Read initial temperature
    if (_tempChar != null && _tempChar!.properties.read) {
      try {
        final bytes = await _tempChar!.read();
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          _log('Initial Temperature read: $value°C');
          onTemperatureReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial temperature read non-fatal error: $e');
      }
    }

    // Read initial humidity
    if (_humidityChar != null && _humidityChar!.properties.read) {
      try {
        final bytes = await _humidityChar!.read();
        final value = AppUtils.parseFloatPayload(bytes);
        if (value != null) {
          _log('Initial Humidity read: $value%');
          onHumidityReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial humidity read non-fatal error: $e');
      }
    }

    // Read initial sampling interval
    if (_intervalChar != null && _intervalChar!.properties.read) {
      try {
        final bytes = await _intervalChar!.read();
        final value = AppUtils.parseIntervalPayload(bytes);
        if (value != null) {
          _log('Initial Sampling Interval read: ${value}s');
          onIntervalReceived?.call(value);
        }
        await Future.delayed(const Duration(milliseconds: 60));
      } catch (e) {
        _log('Initial interval read non-fatal error: $e');
      }
    }

    // Read initial alert
    if (_alertChar != null && _alertChar!.properties.read) {
      try {
        final bytes = await _alertChar!.read();
        final alert = String.fromCharCodes(bytes).trim();
        if (alert.isNotEmpty) {
          _log('Initial Alert Status read: $alert');
          onAlertReceived?.call(alert);
        }
      } catch (e) {
        _log('Initial alert read non-fatal error: $e');
      }
    }

    // Read initial MQ-135 Gas
    if (_gasChar != null && _gasChar!.properties.read) {
      try {
        final bytes = await _gasChar!.read();
        final val = AppUtils.parseGasPayload(bytes);
        if (val != null) {
          _log('Initial MQ-135 Gas read: $val ADC');
          onGasReceived?.call(val);
        }
      } catch (e) {
        _log('Initial gas read non-fatal error: $e');
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
      _log('Interval characteristic not discovered', isError: true);
      return false;
    }

    if (!_intervalChar!.properties.write &&
        !_intervalChar!.properties.writeWithoutResponse) {
      _log('Interval characteristic does not support write', isError: true);
      return false;
    }

    try {
      final bytes = AppUtils.encodeInterval(seconds);
      _log('Writing interval $seconds seconds to ESP32: "$seconds"');

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

  // ── Lifecycle Support ──────────────────────────────────────────────────────

  void handleAppResume() {
    _log('App resumed to foreground');
    if (!_userExplicitDisconnect && _device != null && !isConnected && !_isConnecting) {
      _log('Device disconnected during background. Triggering reconnect.');
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
