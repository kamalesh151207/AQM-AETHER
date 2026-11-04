// AQM AETHER — BLE Constants & System Configuration

abstract class BleConstants {
  // Device Identity
  static const String deviceName = 'AQM-Kamalesh';
  static const String defaultDeviceId = 'AQM-KAM-001';

  // Service UUID
  static const String serviceUuid = '12345678-1234-1234-1234-123456789001';

  // Characteristic UUIDs
  static const String temperatureUuid = '12345678-1234-1234-1234-123456789002';
  static const String humidityUuid = '12345678-1234-1234-1234-123456789003';
  static const String samplingIntervalUuid = '12345678-1234-1234-1234-123456789004';
  static const String alertUuid = '12345678-1234-1234-1234-123456789005';

  // Gas Sensor (MQ-135) Characteristic UUID
  static const String gasUuid = '12345678-1234-1234-1234-123456789006';

  // Unique AQM Device Identity Characteristic UUID
  static const String deviceIdUuid = '12345678-1234-1234-1234-123456789007';

  // Local Storage Preference Keys for Remembered Device & Multiple Device Registry
  static const String prefRegisteredDevices = 'aqm_registered_devices_registry';
  static const String prefLastDeviceId = 'aqm_last_connected_device_id';
  static const String prefLastDeviceName = 'aqm_last_connected_device_name';
  static const String prefLastRemoteId = 'aqm_last_connected_remote_id';
  static const String prefLastServiceUuid = 'aqm_last_connected_service_uuid';
  static const String prefLastConnectedTime = 'aqm_last_connected_timestamp';

  // MPU6050 Accelerometer & Gyroscope Characteristic UUIDs
  static const String accelXUuid = '12345678-1234-1234-1234-123456789007';
  static const String accelYUuid = '12345678-1234-1234-1234-123456789008';
  static const String accelZUuid = '12345678-1234-1234-1234-123456789009';
  static const String gyroXUuid = '12345678-1234-1234-1234-12345678900A';
  static const String gyroYUuid = '12345678-1234-1234-1234-12345678900B';
  static const String gyroZUuid = '12345678-1234-1234-1234-12345678900C';

  // Connection timeouts
  static const Duration scanTimeout = Duration(seconds: 12);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration serviceDiscoveryTimeout = Duration(seconds: 10);

  // Exponential Reconnection Backoff Schedule:
  // Attempt 1: Immediately (0s)
  // Attempt 2: After 2 seconds
  // Attempt 3: After 5 seconds
  // Attempt 4: After 10 seconds
  // Attempt 5: After 20 seconds
  // Further attempts capped at 30 seconds
  static const List<Duration> reconnectBackoff = [
    Duration.zero,
    Duration(seconds: 2),
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
  ];
  static const Duration reconnectMaxInterval = Duration(seconds: 30);
  static const int maxAutoReconnectAttempts = 10;

  // Sampling interval constraints (seconds)
  static const int minSamplingInterval = 1;
  static const int maxSamplingInterval = 3600;
  static const int defaultSamplingInterval = 2;

  // Preset sampling intervals (seconds)
  static const List<int> presetIntervals = [1, 2, 5, 10, 30, 60, 300];

  // Data Freshness thresholds
  static const Duration dataFreshThreshold = Duration(seconds: 6);
  static const Duration dataDelayedThreshold = Duration(seconds: 15);
  static const Duration dataStaleThreshold = Duration(seconds: 30);
}

enum DataQuality {
  fresh,
  delayed,
  stale,
  unavailable;

  String get label {
    switch (this) {
      case DataQuality.fresh:
        return 'FRESH';
      case DataQuality.delayed:
        return 'DELAYED';
      case DataQuality.stale:
        return 'STALE';
      case DataQuality.unavailable:
        return 'UNAVAILABLE';
    }
  }
}

abstract class AppConstants {
  static const String appName = 'AQM AETHER';
  static const String appVersion = '1.1.0';
  static const String productDescription =
      'Intelligent Environmental Monitoring & Sensor Intelligence Platform';
  static const String tagline = 'Understand Your Environment.';

  // History limits
  static const int maxHistoryEntries = 5000;
  static const int maxEventEntries = 500;

  // Moving average
  static const int movingAverageWindow = 5;

  // Database
  static const String dbName = 'aqm_aether.db';
  static const int dbVersion = 3;

  // Honest sensor limitations disclaimer
  static const String prototypeDisclaimer =
      'PROTOTYPE TELEMETRY: The current ESP32 prototype broadcasts simulated temperature and '
      'humidity readings for demonstration of Bluetooth Low Energy data pipelining. '
      'No physical PM2.5, PM10, CO2, or VOC sensors are currently connected. Unsupported sensor '
      'channels are displayed as Not Connected.';
}
