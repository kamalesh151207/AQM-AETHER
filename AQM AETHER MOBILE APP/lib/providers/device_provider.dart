// AQM AETHER — Device Provider
// State Management for BLE Device Connection, Diagnostics, and Telemetry

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/ble_constants.dart';
import '../core/utils/app_utils.dart';
import '../models/device_model.dart';
import '../models/monitoring_event.dart';
import '../services/ble_service.dart';
import '../services/threshold/threshold_service.dart';
import '../services/notifications/notification_service.dart';
import 'monitoring_provider.dart';

class DeviceProvider extends ChangeNotifier {
  final BleService _bleService = BleService();
  final MonitoringProvider _monitoringProvider;

  DeviceModel _device = const DeviceModel(name: BleConstants.deviceName);
  double? _temperature;
  double? _humidity;
  DateTime? _lastTempUpdate;
  DateTime? _lastHumidityUpdate;

  // MQ-135 Gas Sensor
  int? _gasRawAdc;
  DateTime? _lastGasUpdate;

  // MPU6050 Motion Sensors
  double? _accelX;
  double? _accelY;
  double? _accelZ;
  double? _gyroX;
  double? _gyroY;
  double? _gyroZ;
  DateTime? _lastMotionUpdate;

  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  bool _isBluetoothOn = true;
  StreamSubscription<BluetoothAdapterState>? _adapterSubscription;

  // Unique AQM Device Identification & Verification State
  String _targetDeviceId = '';
  ScanResult? _matchedDeviceResult;
  String? _matchedDeviceId;
  String? _matchedDeviceName;
  bool _isFindingDevice = false;
  String? _findingDeviceStatus;
  String? _deviceSearchError;

  // Local Storage for Remembered Device
  String? _savedDeviceId;
  String? _savedDeviceName;
  String? _savedRemoteId;
  DateTime? _savedConnectedTimestamp;

  // Multiple Registered Devices Registry (Key: normalized remoteId or deviceId)
  final Map<String, RegisteredDevice> _registeredDevices = {};

  // Diagnostics log stream
  final List<String> _diagnosticsLog = [];

  // Reliability counters
  int _successfulConnections = 0;
  int _unexpectedDisconnections = 0;
  int _totalReconnectionAttempts = 0;
  DateTime? _sessionConnectedSince;
  DateTime? _lastDisconnectedAt;

  // Periodic timer to keep UI data freshness fresh
  Timer? _freshnessTimer;

  DeviceProvider(this._monitoringProvider) {
    _setupBleCallbacks();
    _initBluetoothState();
    _startFreshnessTimer();
    loadSavedDevice();
  }

  void _initBluetoothState() {
    _adapterSubscription = FlutterBluePlus.adapterState.listen((state) {
      _isBluetoothOn = state == BluetoothAdapterState.on;
      notifyListeners();
    });
  }

  void _startFreshnessTimer() {
    _freshnessTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_lastTempUpdate != null || isConnected) {
        notifyListeners();
      }
    });
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  DeviceModel get device => _device;
  double? get temperature => _temperature;
  double? get humidity => _humidity;
  DateTime? get lastTempUpdate => _lastTempUpdate;
  DateTime? get lastHumidityUpdate => _lastHumidityUpdate;

  // Unique AQM Device Identification & Verification
  String get targetDeviceId => _targetDeviceId;
  set targetDeviceId(String id) {
    _targetDeviceId = AppUtils.normalizeDeviceId(id);
    notifyListeners();
  }

  ScanResult? get matchedDeviceResult => _matchedDeviceResult;
  String? get matchedDeviceId => _matchedDeviceId;
  String? get matchedDeviceName => _matchedDeviceName;
  bool get isFindingDevice => _isFindingDevice;
  String? get findingDeviceStatus => _findingDeviceStatus;
  String? get deviceSearchError => _deviceSearchError;

  // Local Storage for Remembered Device
  String? get savedDeviceId => _savedDeviceId;
  String? get savedDeviceName => _savedDeviceName;
  String? get savedRemoteId => _savedRemoteId;
  DateTime? get savedConnectedTimestamp => _savedConnectedTimestamp;
  bool get hasSavedDevice => _savedDeviceId != null && _savedDeviceId!.isNotEmpty;

  // Multiple Registered Devices Registry
  List<RegisteredDevice> get registeredDevices => _registeredDevices.values.toList();
  bool get hasRegisteredDevices => _registeredDevices.isNotEmpty;

  RegisteredDevice? getRegisteredDevice(String remoteId) {
    if (remoteId.isEmpty) return null;
    return _registeredDevices[remoteId.toLowerCase().trim()];
  }

  RegisteredDevice? getRegistrationForDevice(BluetoothDevice device, {String? advertisedName}) {
    // 1. Primary match: by BLE remote identifier
    final remoteId = device.remoteId.str.toLowerCase().trim();
    if (_registeredDevices.containsKey(remoteId)) {
      return _registeredDevices[remoteId];
    }

    // 2. Secondary match: by device name if unique and not generic placeholder
    final name = (advertisedName != null && advertisedName.trim().isNotEmpty)
        ? advertisedName.trim()
        : (device.platformName.trim().isNotEmpty ? device.platformName.trim() : null);

    if (name != null &&
        name.toLowerCase() != 'aqm' &&
        name.toLowerCase() != 'esp32' &&
        name.toLowerCase() != 'generic') {
      for (final reg in _registeredDevices.values) {
        if (reg.deviceName.toLowerCase() == name.toLowerCase()) {
          return reg;
        }
      }
    }

    // 3. Match if device advertised name directly equals a registered Device ID (e.g. "AQM-KAM-001")
    if (name != null) {
      for (final reg in _registeredDevices.values) {
        if (reg.deviceId.toUpperCase() == name.toUpperCase()) {
          return reg;
        }
      }
    }

    return null;
  }

  bool isDeviceRegistered(BluetoothDevice device, {String? advertisedName}) {
    return getRegistrationForDevice(device, advertisedName: advertisedName) != null;
  }

  // MQ-135 Gas
  int? get gasRawAdc => _gasRawAdc;
  DateTime? get lastGasUpdate => _lastGasUpdate;

  // MPU6050 Motion
  double? get accelX => _accelX;
  double? get accelY => _accelY;
  double? get accelZ => _accelZ;
  double? get gyroX => _gyroX;
  double? get gyroY => _gyroY;
  double? get gyroZ => _gyroZ;
  DateTime? get lastMotionUpdate => _lastMotionUpdate;
  bool get hasMotionData => _accelX != null || _gyroX != null;

  double? get motionMagnitude {
    if (_accelX == null || _accelY == null || _accelZ == null) return null;
    return sqrt(_accelX! * _accelX! + _accelY! * _accelY! + _accelZ! * _accelZ!);
  }

  String get motionState {
    final mag = motionMagnitude;
    if (mag == null) return 'Stationary / No Data';
    final delta = (mag - 1.0).abs();
    if (delta < 0.08) return 'Resting / Stable';
    if (delta < 0.35) return 'Minor Movement';
    return 'Active Dynamic Motion';
  }

  // Scan Results & Categorization
  List<ScanResult> get scanResults => _scanResults;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  set searchQuery(String q) {
    _searchQuery = q.trim().toLowerCase();
    notifyListeners();
  }

  bool isAqmDevice(ScanResult r) => _isAqmMatch(r);

  List<ScanResult> get aqmDevices {
    final list = _scanResults.where(_isAqmMatch).toList();
    if (_searchQuery.isEmpty) return list;
    return list.where((r) {
      final name = resolveDeviceName(r).toLowerCase();
      final id = r.device.remoteId.str.toLowerCase();
      return name.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  List<ScanResult> get otherDevices {
    final list = _scanResults.where((r) => !_isAqmMatch(r)).toList();
    if (_searchQuery.isEmpty) return list;
    return list.where((r) {
      final name = resolveDeviceName(r).toLowerCase();
      final id = r.device.remoteId.str.toLowerCase();
      return name.contains(_searchQuery) || id.contains(_searchQuery);
    }).toList();
  }

  List<DiscoveredServiceInfo> get discoveredServices => _device.discoveredServices;

  bool get isScanning => _isScanning;
  bool get isConnected => _device.status.isConnected;
  bool get isBluetoothOn => _isBluetoothOn;
  List<String> get diagnosticsLog => List.unmodifiable(_diagnosticsLog);

  // Data Quality Indicator
  DataQuality get dataQuality {
    if (!isConnected || _lastTempUpdate == null) {
      return DataQuality.unavailable;
    }
    final diff = DateTime.now().difference(_lastTempUpdate!);
    if (diff <= BleConstants.dataFreshThreshold) return DataQuality.fresh;
    if (diff <= BleConstants.dataDelayedThreshold) return DataQuality.delayed;
    return DataQuality.stale;
  }

  bool get isTemperatureStale {
    if (_lastTempUpdate == null) return true;
    return DateTime.now().difference(_lastTempUpdate!) >
        BleConstants.dataDelayedThreshold;
  }

  bool get isHumidityStale {
    if (_lastHumidityUpdate == null) return true;
    return DateTime.now().difference(_lastHumidityUpdate!) >
        BleConstants.dataDelayedThreshold;
  }

  Future<void> enableBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      debugPrint('[BLE] turnOn error: $e');
    }
  }

  // ── BLE Callback Setup ─────────────────────────────────────────────────────

  void _setupBleCallbacks() {
    _bleService.onStatusChanged = _handleStatusChanged;
    _bleService.onTemperatureReceived = _handleTemperatureReceived;
    _bleService.onHumidityReceived = _handleHumidityReceived;
    _bleService.onGasReceived = _handleGasReceived;
    _bleService.onMotionReceived = _handleMotionReceived;
    _bleService.onDiscoveredGattTree = _handleDiscoveredGattTree;
    _bleService.onIntervalReceived = _handleIntervalReceived;
    _bleService.onAlertReceived = _handleAlertReceived;
    _bleService.onScanResult = _handleScanResult;
    _bleService.onBleLog = _handleBleLog;
    _bleService.onDeviceIdReceived = _handleDeviceIdReceived;
  }

  void _handleDeviceIdReceived(String deviceId) {
    _device = _device.copyWith(deviceId: deviceId);
    if (!_device.isGenericDevice) {
      saveConnectedDevice(
        deviceId: deviceId,
        deviceName: _device.name,
        remoteId: _device.id ?? '',
      );
    }
    notifyListeners();
  }

  void _handleBleLog(String msg, {bool isError = false}) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final entry = '[$time] ${isError ? "ERR: " : ""}$msg';
    _diagnosticsLog.insert(0, entry);
    if (_diagnosticsLog.length > 200) {
      _diagnosticsLog.removeLast();
    }
    notifyListeners();
  }

  void _handleStatusChanged(DeviceConnectionStatus status, String? error) {
    if (status == DeviceConnectionStatus.ready) {
      _successfulConnections++;
      _sessionConnectedSince = DateTime.now();

      _device = _device.copyWith(
        name: _bleService.isGenericDevice
            ? (_device.name.isEmpty ? 'Generic Peripheral' : _device.name)
            : _device.name,
        status: status,
        clearError: true,
        lastConnectedAt: DateTime.now(),
        sessionConnectedSince: _sessionConnectedSince,
        successfulConnections: _successfulConnections,
        serviceFound: _bleService.serviceFound,
        temperatureCharFound: _bleService.temperatureCharFound,
        humidityCharFound: _bleService.humidityCharFound,
        samplingIntervalCharFound: _bleService.samplingIntervalCharFound,
        alertCharFound: _bleService.alertCharFound,
        gasCharFound: _bleService.gasCharFound,
        mpuCharFound: _bleService.mpuCharFound,
        deviceIdCharFound: _bleService.deviceIdCharFound,
        deviceId: _device.deviceId ?? _matchedDeviceId,
        isGenericDevice: _bleService.isGenericDevice,
        discoveredServices: _bleService.discoveredServices,
      );

      final currentDevId = _device.deviceId ?? _matchedDeviceId;
      if (!_device.isGenericDevice && currentDevId != null && currentDevId.isNotEmpty) {
        saveConnectedDevice(
          deviceId: currentDevId,
          deviceName: _device.name,
          remoteId: _device.id ?? '',
        );
      }

      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.deviceConnected,
        message: 'Device connected & telemetry ready',
        detail: _device.name,
      ));
      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.monitoringStarted,
        message: _bleService.isGenericDevice
            ? 'Generic GATT peripheral exploration active'
            : 'Live telemetry stream active',
      ));
      NotificationService().showDeviceConnected(deviceName: _device.name);
    } else if (status == DeviceConnectionStatus.connected) {
      _device = _device.copyWith(
        status: status,
        clearError: true,
      );
    } else if (status == DeviceConnectionStatus.disconnected) {
      _lastDisconnectedAt = DateTime.now();
      _unexpectedDisconnections++;

      _device = _device.copyWith(
        status: status,
        errorMessage: error,
        lastDisconnectedAt: _lastDisconnectedAt,
        unexpectedDisconnections: _unexpectedDisconnections,
        sessionConnectedSince: null,
      );

      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.deviceDisconnected,
        message: error ?? 'Device disconnected',
      ));
      NotificationService().showDeviceDisconnected(
        deviceName: _device.name,
        reason: error,
      );
    } else if (status == DeviceConnectionStatus.reconnecting) {
      _totalReconnectionAttempts++;
      _device = _device.copyWith(
        status: status,
        errorMessage: error,
        reconnectAttempt: _bleService.reconnectAttempts,
        totalReconnectionAttempts: _totalReconnectionAttempts,
      );

      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.reconnecting,
        message: error ?? 'Attempting to reconnect…',
      ));
    } else {
      _device = _device.copyWith(status: status, errorMessage: error);
      if (status == DeviceConnectionStatus.connectionFailed && error != null) {
        _monitoringProvider.addEvent(MonitoringEvent(
          timestamp: DateTime.now(),
          type: MonitoringEventType.error,
          message: error,
        ));
      }
    }

    notifyListeners();
  }

  void _handleTemperatureReceived(double value) {
    _temperature = value;
    _lastTempUpdate = DateTime.now();
    _device = _device.copyWith(lastUpdatedAt: DateTime.now());
    _monitoringProvider.recordReading(
      temperature: value,
      alertStatus: _device.alertStatus,
      connectionStatus: _device.status.label,
      samplingInterval: _device.samplingInterval,
    );
    ThresholdService().evaluateTelemetry(
      temperature: _temperature,
      humidity: _humidity,
      isStale: isTemperatureStale || isHumidityStale,
    );
    notifyListeners();
  }

  void _handleHumidityReceived(double value) {
    _humidity = value;
    _lastHumidityUpdate = DateTime.now();
    _device = _device.copyWith(lastUpdatedAt: DateTime.now());
    _monitoringProvider.recordReading(
      humidity: value,
      alertStatus: _device.alertStatus,
      connectionStatus: _device.status.label,
      samplingInterval: _device.samplingInterval,
    );
    ThresholdService().evaluateTelemetry(
      temperature: _temperature,
      humidity: _humidity,
      isStale: isTemperatureStale || isHumidityStale,
    );
    notifyListeners();
  }

  void _handleGasReceived(int val) {
    _gasRawAdc = val;
    _lastGasUpdate = DateTime.now();
    _device = _device.copyWith(lastUpdatedAt: DateTime.now());
    _monitoringProvider.recordReading(
      gasRawAdc: val,
      alertStatus: _device.alertStatus,
      connectionStatus: _device.status.label,
      samplingInterval: _device.samplingInterval,
    );
    notifyListeners();
  }

  void _handleMotionReceived({
    double? ax,
    double? ay,
    double? az,
    double? gx,
    double? gy,
    double? gz,
  }) {
    if (ax != null) _accelX = ax;
    if (ay != null) _accelY = ay;
    if (az != null) _accelZ = az;
    if (gx != null) _gyroX = gx;
    if (gy != null) _gyroY = gy;
    if (gz != null) _gyroZ = gz;
    _lastMotionUpdate = DateTime.now();
    _device = _device.copyWith(lastUpdatedAt: DateTime.now());

    _monitoringProvider.recordReading(
      accelX: ax,
      accelY: ay,
      accelZ: az,
      gyroX: gx,
      gyroY: gy,
      gyroZ: gz,
    );
    notifyListeners();
  }

  void _handleDiscoveredGattTree(List<DiscoveredServiceInfo> services) {
    _device = _device.copyWith(discoveredServices: services);
    notifyListeners();
  }

  void _handleIntervalReceived(int seconds) {
    final previous = _device.samplingInterval;
    _device = _device.copyWith(samplingInterval: seconds);
    if (previous != seconds) {
      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.samplingIntervalChanged,
        message: 'Sampling interval updated to ${seconds}s',
        detail: '${seconds}s',
      ));
    }
    notifyListeners();
  }

  void _handleAlertReceived(String alert) {
    final oldAlert = _device.alertStatus;
    _device = _device.copyWith(alertStatus: alert);
    final isAlert = alert.trim().toUpperCase() == 'ALERT';

    if (oldAlert != alert) {
      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: isAlert ? MonitoringEventType.warning : MonitoringEventType.readingReceived,
        message: isAlert ? 'ESP32 ALERT CONDITION TRIGGERED' : 'ESP32 Status Returned to NORMAL',
        detail: alert,
      ));
    }
    notifyListeners();
  }

  void _handleScanResult(List<ScanResult> results) {
    _scanResults = results;
    notifyListeners();
  }

  // ── Discovery & Connection Actions ─────────────────────────────────────────

  String resolveDeviceName(ScanResult r) {
    final advName = r.advertisementData.advName.trim();
    if (advName.isNotEmpty) return advName;

    final platName = r.device.platformName.trim();
    if (platName.isNotEmpty) return platName;

    if (_isAqmMatch(r)) {
      return BleConstants.deviceName; // "AQM-Kamalesh"
    }

    final id = r.device.remoteId.str;
    final suffix = id.length > 5 ? id.substring(id.length - 5) : id;
    return 'BLE Peripheral ($suffix)';
  }

  bool _isAqmMatch(ScanResult r) {
    final targetName = BleConstants.deviceName.toLowerCase();
    final devName = r.device.platformName.trim().toLowerCase();
    final advName = r.advertisementData.advName.trim().toLowerCase();

    // Exact or substring name match
    if (devName == targetName || advName == targetName) return true;
    if (devName.contains('aqm-kamalesh') || advName.contains('aqm-kamalesh')) return true;
    if (devName.contains('aqm') || advName.contains('aqm')) return true;

    // Service UUID match
    final targetUuid = BleConstants.serviceUuid.replaceAll('-', '').toLowerCase();
    for (final u in r.advertisementData.serviceUuids) {
      if (u.str128.replaceAll('-', '').toLowerCase() == targetUuid) return true;
    }

    // Service data match
    for (final entry in r.advertisementData.serviceData.entries) {
      if (entry.key.str128.replaceAll('-', '').toLowerCase() == targetUuid) return true;
    }

    return false;
  }

  bool _isDeviceMatch(BluetoothDevice d) {
    final targetName = BleConstants.deviceName.toLowerCase();
    final devName = d.platformName.trim().toLowerCase();
    return devName == targetName || devName.contains('aqm');
  }

  Future<void> startScan() async {
    _isScanning = true;
    _scanResults = [];
    notifyListeners();
    // Scan comprehensively without early termination so all nearby peripherals and name updates appear
    await _bleService.startScan(
      timeout: const Duration(seconds: 12),
    );
    _isScanning = false;
    notifyListeners();
  }

  Future<void> stopScan() async {
    await _bleService.stopScan();
    _isScanning = false;
    notifyListeners();
  }

  ScanResult? get aqmDevice {
    return _scanResults.firstWhereOrNull(_isAqmMatch);
  }

  Future<void> connect(
    BluetoothDevice device, {
    bool isAqm = true,
    String? expectedDeviceId,
  }) async {
    final devName = device.platformName.isNotEmpty ? device.platformName : device.remoteId.str;
    final cleanId = expectedDeviceId != null ? AppUtils.normalizeDeviceId(expectedDeviceId) : null;
    _device = _device.copyWith(name: devName, id: device.remoteId.str, deviceId: cleanId);
    notifyListeners();
    await _bleService.connectToDevice(
      device,
      isAqm: isAqm,
      expectedDeviceId: cleanId,
    );
  }

  Future<void> connectWithDeviceId(BluetoothDevice device, String expectedDeviceId) =>
      connect(device, isAqm: true, expectedDeviceId: expectedDeviceId);

  Future<void> connectToDevice(
    BluetoothDevice device, {
    bool isAqm = true,
    String? expectedDeviceId,
  }) =>
      connect(device, isAqm: isAqm, expectedDeviceId: expectedDeviceId);

  Future<void> connectToAqm({String? expectedDeviceId}) async {
    if (isConnected || _bleService.isConnecting) return;
    final targetId = expectedDeviceId ?? _savedDeviceId;

    // 1. Check if device is already connected via system Bluetooth
    final systemDevices = FlutterBluePlus.connectedDevices;
    final connectedTarget = systemDevices.firstWhereOrNull(_isDeviceMatch);
    if (connectedTarget != null) {
      _handleBleLog('Found previously connected system peripheral: ${connectedTarget.platformName}');
      await connect(connectedTarget, isAqm: true, expectedDeviceId: targetId);
      return;
    }

    // 2. Check existing scan results
    final target = aqmDevice;
    if (target != null) {
      _handleBleLog('Connecting to known cached peripheral: ${target.device.remoteId.str}');
      await connect(target.device, isAqm: true, expectedDeviceId: targetId);
      return;
    }

    // 3. Scan and locate peripheral (auto-terminates as soon as AQM peripheral is heard)
    _isScanning = true;
    notifyListeners();
    await _bleService.startScan(
      timeout: const Duration(seconds: 8),
      onFoundTarget: _isAqmMatch,
    );
    _isScanning = false;
    notifyListeners();

    final found = aqmDevice;
    if (found == null) {
      _handleStatusChanged(
        DeviceConnectionStatus.error,
        'Device "AQM-Kamalesh" not found. Ensure the ESP32 is powered on, within Bluetooth range, and advertising.',
      );
      return;
    }
    await connect(found.device, isAqm: true, expectedDeviceId: targetId);
  }

  // ── Unique Device ID Storage & Finding ─────────────────────────────────────

  Future<void> _persistRegistry(SharedPreferences prefs) async {
    final list = _registeredDevices.values.map((r) => r.toJson()).toList();
    await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode(list));
  }

  Future<void> loadSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _registeredDevices.clear();

      // 1. Load multi-device registry from JSON
      final rawRegistry = prefs.getString(BleConstants.prefRegisteredDevices);
      if (rawRegistry != null && rawRegistry.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawRegistry);
          if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic>) {
                final reg = RegisteredDevice.fromJson(item);
                if (reg.deviceId.isNotEmpty) {
                  final key = (reg.remoteId.isNotEmpty ? reg.remoteId : reg.deviceId).toLowerCase().trim();
                  _registeredDevices[key] = reg;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('[Storage] Error decoding registered devices registry: $e');
        }
      }

      // 2. Legacy Migration: If registry was empty, migrate single saved device if present
      final legacyId = prefs.getString(BleConstants.prefLastDeviceId);
      final legacyRemote = prefs.getString(BleConstants.prefLastRemoteId);
      final legacyName = prefs.getString(BleConstants.prefLastDeviceName);
      final legacyTs = prefs.getString(BleConstants.prefLastConnectedTime);

      if (_registeredDevices.isEmpty && legacyId != null && legacyId.isNotEmpty) {
        final reg = RegisteredDevice(
          deviceId: legacyId,
          remoteId: legacyRemote ?? '',
          deviceName: legacyName ?? BleConstants.deviceName,
          serviceUuid: BleConstants.serviceUuid,
          registeredAt: legacyTs != null ? (DateTime.tryParse(legacyTs) ?? DateTime.now()) : DateTime.now(),
          lastConnectedAt: legacyTs != null ? (DateTime.tryParse(legacyTs) ?? DateTime.now()) : DateTime.now(),
        );
        final key = (legacyRemote != null && legacyRemote.isNotEmpty ? legacyRemote : legacyId).toLowerCase().trim();
        _registeredDevices[key] = reg;
        await _persistRegistry(prefs);
      }

      // 3. Populate single active device pointers for backward compatibility
      _savedDeviceId = prefs.getString(BleConstants.prefLastDeviceId);
      _savedDeviceName = prefs.getString(BleConstants.prefLastDeviceName);
      _savedRemoteId = prefs.getString(BleConstants.prefLastRemoteId);
      final tsStr = prefs.getString(BleConstants.prefLastConnectedTime);
      if (tsStr != null) {
        _savedConnectedTimestamp = DateTime.tryParse(tsStr);
      }

      if (_savedDeviceId == null && _registeredDevices.isNotEmpty) {
        final mostRecent = _registeredDevices.values.reduce(
          (a, b) => a.lastConnectedAt.isAfter(b.lastConnectedAt) ? a : b,
        );
        _savedDeviceId = mostRecent.deviceId;
        _savedDeviceName = mostRecent.deviceName;
        _savedRemoteId = mostRecent.remoteId;
        _savedConnectedTimestamp = mostRecent.lastConnectedAt;
      }

      if (_savedDeviceId != null && _targetDeviceId.isEmpty) {
        _targetDeviceId = _savedDeviceId!;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[Storage] Error loading saved device: $e');
    }
  }

  Future<void> saveConnectedDevice({
    required String deviceId,
    required String deviceName,
    required String remoteId,
  }) async {
    try {
      final cleanId = AppUtils.normalizeDeviceId(deviceId);
      final cleanRemoteId = remoteId.trim();
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Look for existing registration to keep original registeredAt timestamp
      final existingKey = cleanRemoteId.toLowerCase();
      RegisteredDevice? existing = _registeredDevices[existingKey];
      if (existing == null) {
        for (final reg in _registeredDevices.values) {
          if (reg.deviceId.toUpperCase() == cleanId.toUpperCase()) {
            existing = reg;
            break;
          }
        }
      }

      final newRegistration = RegisteredDevice(
        deviceId: cleanId,
        remoteId: cleanRemoteId.isNotEmpty ? cleanRemoteId : (existing?.remoteId ?? cleanId),
        deviceName: deviceName.isNotEmpty ? deviceName : (existing?.deviceName ?? BleConstants.deviceName),
        serviceUuid: BleConstants.serviceUuid,
        registeredAt: existing?.registeredAt ?? now,
        lastConnectedAt: now,
      );

      final storeKey = (cleanRemoteId.isNotEmpty ? cleanRemoteId : cleanId).toLowerCase();
      _registeredDevices[storeKey] = newRegistration;

      // Persist full registry to SharedPreferences
      await _persistRegistry(prefs);

      // Also persist legacy keys for backward compatibility
      await prefs.setString(BleConstants.prefLastDeviceId, cleanId);
      await prefs.setString(BleConstants.prefLastDeviceName, newRegistration.deviceName);
      await prefs.setString(BleConstants.prefLastRemoteId, cleanRemoteId);
      await prefs.setString(BleConstants.prefLastConnectedTime, now.toIso8601String());

      _savedDeviceId = cleanId;
      _savedDeviceName = newRegistration.deviceName;
      _savedRemoteId = cleanRemoteId;
      _savedConnectedTimestamp = now;
      _targetDeviceId = cleanId;

      _handleBleLog('Device identity saved to registry [ID: $cleanId] (${newRegistration.deviceName})');
      notifyListeners();
    } catch (e) {
      debugPrint('[Storage] Error saving connected device: $e');
    }
  }

  Future<void> forgetDevice(String remoteId, {String? deviceId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final targetKey = remoteId.toLowerCase().trim();
      final targetId = deviceId != null ? AppUtils.normalizeDeviceId(deviceId) : null;

      // Remove from registry matching remoteId or deviceId
      _registeredDevices.remove(targetKey);
      if (targetId != null) {
        _registeredDevices.removeWhere((k, v) => v.deviceId.toUpperCase() == targetId.toUpperCase());
      }
      _registeredDevices.removeWhere((k, v) => v.remoteId.toLowerCase().trim() == targetKey);

      await _persistRegistry(prefs);

      // If the forgotten device was the active saved device, clear or update legacy pointers
      if ((_savedRemoteId != null && _savedRemoteId!.toLowerCase().trim() == targetKey) ||
          (_savedDeviceId != null && targetId != null && _savedDeviceId!.toUpperCase() == targetId.toUpperCase())) {
        if (_registeredDevices.isNotEmpty) {
          final next = _registeredDevices.values.first;
          _savedDeviceId = next.deviceId;
          _savedDeviceName = next.deviceName;
          _savedRemoteId = next.remoteId;
          _savedConnectedTimestamp = next.lastConnectedAt;
          await prefs.setString(BleConstants.prefLastDeviceId, next.deviceId);
          await prefs.setString(BleConstants.prefLastDeviceName, next.deviceName);
          await prefs.setString(BleConstants.prefLastRemoteId, next.remoteId);
          await prefs.setString(BleConstants.prefLastConnectedTime, next.lastConnectedAt.toIso8601String());
        } else {
          _savedDeviceId = null;
          _savedDeviceName = null;
          _savedRemoteId = null;
          _savedConnectedTimestamp = null;
          await prefs.remove(BleConstants.prefLastDeviceId);
          await prefs.remove(BleConstants.prefLastDeviceName);
          await prefs.remove(BleConstants.prefLastRemoteId);
          await prefs.remove(BleConstants.prefLastConnectedTime);
        }
      }

      _handleBleLog('Device registration removed: $remoteId');
      notifyListeners();
    } catch (e) {
      debugPrint('[Storage] Error forgetting device: $e');
    }
  }

  Future<void> clearSavedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _registeredDevices.clear();
      await prefs.remove(BleConstants.prefRegisteredDevices);
      await prefs.remove(BleConstants.prefLastDeviceId);
      await prefs.remove(BleConstants.prefLastDeviceName);
      await prefs.remove(BleConstants.prefLastRemoteId);
      await prefs.remove(BleConstants.prefLastConnectedTime);

      _savedDeviceId = null;
      _savedDeviceName = null;
      _savedRemoteId = null;
      _savedConnectedTimestamp = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[Storage] Error clearing saved device: $e');
    }
  }

  Future<void> reconnectRegisteredDevice(BluetoothDevice device, RegisteredDevice reg) async {
    _handleBleLog('Reconnecting to registered AQM device "${reg.deviceName}" [ID: ${reg.deviceId}]');
    await connect(
      device,
      isAqm: true,
      expectedDeviceId: reg.deviceId,
    );
  }

  Future<void> connectToRegisteredDevice(RegisteredDevice reg) async {
    if (isConnected || _bleService.isConnecting) return;

    // 1. Check if device is in current scan results
    final inScan = _scanResults.firstWhereOrNull((r) {
      if (reg.remoteId.isNotEmpty && r.device.remoteId.str.toLowerCase() == reg.remoteId.toLowerCase()) {
        return true;
      }
      final name = resolveDeviceName(r).toLowerCase();
      return name == reg.deviceName.toLowerCase();
    });

    if (inScan != null) {
      await reconnectRegisteredDevice(inScan.device, reg);
      return;
    }

    // 2. Check if already connected in system
    final systemDevices = FlutterBluePlus.connectedDevices;
    final sysTarget = systemDevices.firstWhereOrNull((d) {
      if (reg.remoteId.isNotEmpty && d.remoteId.str.toLowerCase() == reg.remoteId.toLowerCase()) {
        return true;
      }
      return d.platformName.toLowerCase() == reg.deviceName.toLowerCase();
    });

    if (sysTarget != null) {
      await reconnectRegisteredDevice(sysTarget, reg);
      return;
    }

    // 3. Scan briefly to find this specific peripheral
    _isScanning = true;
    notifyListeners();
    await _bleService.startScan(
      timeout: const Duration(seconds: 8),
      onFoundTarget: (r) {
        if (reg.remoteId.isNotEmpty && r.device.remoteId.str.toLowerCase() == reg.remoteId.toLowerCase()) {
          return true;
        }
        return resolveDeviceName(r).toLowerCase() == reg.deviceName.toLowerCase();
      },
    );
    _isScanning = false;
    notifyListeners();

    final found = _scanResults.firstWhereOrNull((r) {
      if (reg.remoteId.isNotEmpty && r.device.remoteId.str.toLowerCase() == reg.remoteId.toLowerCase()) {
        return true;
      }
      return resolveDeviceName(r).toLowerCase() == reg.deviceName.toLowerCase();
    });

    if (found == null) {
      _handleStatusChanged(
        DeviceConnectionStatus.error,
        'Device "${reg.deviceName}" is not in range. Ensure the device is powered on and advertising.',
      );
      return;
    }

    await reconnectRegisteredDevice(found.device, reg);
  }

  Future<bool> findMyDevice(String rawId) async {
    final cleanId = AppUtils.normalizeDeviceId(rawId);
    if (!AppUtils.isValidDeviceId(cleanId)) {
      _deviceSearchError = 'Invalid Device ID format. Example: AQM-KAM-001';
      _matchedDeviceResult = null;
      notifyListeners();
      return false;
    }

    if (!_isBluetoothOn) {
      _deviceSearchError = 'Please enable Bluetooth to find your device.';
      notifyListeners();
      return false;
    }

    _targetDeviceId = cleanId;
    _isFindingDevice = true;
    _deviceSearchError = null;
    _matchedDeviceResult = null;
    _matchedDeviceId = null;
    _matchedDeviceName = null;
    _findingDeviceStatus = 'Scanning for BLE peripherals with ID "$cleanId"…';
    notifyListeners();

    try {
      // 1. Check currently connected system devices first
      final systemDevices = FlutterBluePlus.connectedDevices;
      for (final dev in systemDevices) {
        if (dev.platformName.toUpperCase().contains(cleanId)) {
          _matchedDeviceResult = ScanResult(
            device: dev,
            advertisementData: AdvertisementData(
              advName: dev.platformName,
              txPowerLevel: null,
              appearance: null,
              connectable: true,
              manufacturerData: {},
              serviceData: {},
              serviceUuids: [Guid(BleConstants.serviceUuid)],
            ),
            rssi: -50,
            timeStamp: DateTime.now(),
          );
          _matchedDeviceId = cleanId;
          _matchedDeviceName = dev.platformName.isNotEmpty ? dev.platformName : BleConstants.deviceName;
          _isFindingDevice = false;
          _findingDeviceStatus = null;
          notifyListeners();
          return true;
        }
      }

      // 2. Perform low-latency scan
      ScanResult? candidateMatch;
      final candidatePeripherals = <ScanResult>[];

      await _bleService.startScan(
        timeout: const Duration(seconds: 8),
        onFoundTarget: (res) {
          final advName = res.advertisementData.advName;
          final platName = res.device.platformName;
          String? mfgString;
          if (res.advertisementData.manufacturerData.isNotEmpty) {
            final allBytes = res.advertisementData.manufacturerData.values.expand((x) => x).toList();
            mfgString = String.fromCharCodes(allBytes);
          }

          if (AppUtils.matchesDeviceIdentity(
            targetId: cleanId,
            advertisedName: advName,
            platformName: platName,
            manufacturerData: mfgString,
          )) {
            candidateMatch = res;
            return true;
          }

          if (_isAqmMatch(res)) {
            candidatePeripherals.add(res);
          }
          return false;
        },
      );

      // If directly matched via advertisement
      if (candidateMatch != null) {
        _matchedDeviceResult = candidateMatch;
        _matchedDeviceId = cleanId;
        _matchedDeviceName = resolveDeviceName(candidateMatch!);
        _isFindingDevice = false;
        _findingDeviceStatus = null;
        notifyListeners();
        return true;
      }

      // 3. Fallback: inspect candidate AQM devices by reading identity characteristic
      if (candidatePeripherals.isNotEmpty) {
        _findingDeviceStatus = 'Verifying identity on candidate AQM peripherals…';
        notifyListeners();

        for (final candidate in candidatePeripherals) {
          final candidateDevId = await _bleService.readDeviceIdentity(candidate.device);
          if (candidateDevId != null && AppUtils.normalizeDeviceId(candidateDevId) == cleanId) {
            _matchedDeviceResult = candidate;
            _matchedDeviceId = cleanId;
            _matchedDeviceName = resolveDeviceName(candidate);
            _isFindingDevice = false;
            _findingDeviceStatus = null;
            notifyListeners();
            return true;
          }
        }
      }

      // 4. Device not found
      _deviceSearchError = 'Device with ID "$cleanId" not found. Ensure the ESP32 is powered on, within Bluetooth range (~10m), and advertising.';
      _isFindingDevice = false;
      _findingDeviceStatus = null;
      notifyListeners();
      return false;
    } catch (e) {
      _deviceSearchError = 'Error during device search: $e';
      _isFindingDevice = false;
      _findingDeviceStatus = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> connectMatchedDevice() async {
    if (_matchedDeviceResult == null) return;
    final r = _matchedDeviceResult!;
    await connect(r.device, isAqm: true);
    if (_matchedDeviceId != null) {
      _device = _device.copyWith(deviceId: _matchedDeviceId);
      await saveConnectedDevice(
        deviceId: _matchedDeviceId!,
        deviceName: _matchedDeviceName ?? _device.name,
        remoteId: r.device.remoteId.str,
      );
    }
  }

  void clearMatchedDevice() {
    _matchedDeviceResult = null;
    _matchedDeviceId = null;
    _matchedDeviceName = null;
    _deviceSearchError = null;
    _findingDeviceStatus = null;
    notifyListeners();
  }

  Future<void> reconnect() async {
    _bleService.resetReconnectAttempts();
    if (_bleService.connectedDevice != null) {
      final reg = getRegistrationForDevice(_bleService.connectedDevice!);
      await connect(
        _bleService.connectedDevice!,
        isAqm: !_device.isGenericDevice,
        expectedDeviceId: reg?.deviceId ?? _device.deviceId ?? _savedDeviceId,
      );
    } else {
      await connectToAqm(expectedDeviceId: _savedDeviceId);
    }
  }

  Future<void> disconnect() async {
    await _bleService.disconnect();
    _temperature = null;
    _humidity = null;
    _gasRawAdc = null;
    _accelX = null;
    _accelY = null;
    _accelZ = null;
    _gyroX = null;
    _gyroY = null;
    _gyroZ = null;
    notifyListeners();
  }

  // ── Sampling Interval Control ──────────────────────────────────────────────

  Future<bool> writeSamplingInterval(int seconds) async {
    final success = await _bleService.writeSamplingInterval(seconds);
    if (success) {
      _device = _device.copyWith(samplingInterval: seconds);
      _monitoringProvider.addEvent(MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.samplingIntervalChanged,
        message: 'Sampling interval updated to ${seconds}s',
        detail: '${seconds}s',
      ));
      notifyListeners();
    }
    return success;
  }

  Future<bool> setSamplingInterval(int seconds) => writeSamplingInterval(seconds);

  // ── App Lifecycle ──────────────────────────────────────────────────────────

  void handleAppResume() => _bleService.handleAppResume();
  void handleAppPause() => _bleService.handleAppPause();

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    _adapterSubscription?.cancel();
    _bleService.dispose();
    super.dispose();
  }
}
