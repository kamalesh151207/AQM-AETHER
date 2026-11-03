// AQM AETHER — Device Model & Connection State Hierarchy

enum DeviceConnectionStatus {
  idle,
  scanning,
  deviceFound,
  connecting,
  connected,
  discoveringServices,
  subscribingNotifications,
  ready,
  disconnecting,
  disconnected,
  reconnecting,
  connectionFailed,
  error,
}

extension DeviceConnectionStatusExtension on DeviceConnectionStatus {
  String get label {
    switch (this) {
      case DeviceConnectionStatus.idle:
        return 'Idle';
      case DeviceConnectionStatus.scanning:
        return 'Scanning…';
      case DeviceConnectionStatus.deviceFound:
        return 'Device Located';
      case DeviceConnectionStatus.connecting:
        return 'Connecting…';
      case DeviceConnectionStatus.connected:
        return 'Link Established';
      case DeviceConnectionStatus.discoveringServices:
        return 'Discovering Services…';
      case DeviceConnectionStatus.subscribingNotifications:
        return 'Subscribing…';
      case DeviceConnectionStatus.ready:
        return 'Ready / Live';
      case DeviceConnectionStatus.disconnecting:
        return 'Disconnecting…';
      case DeviceConnectionStatus.disconnected:
        return 'Disconnected';
      case DeviceConnectionStatus.reconnecting:
        return 'Reconnecting…';
      case DeviceConnectionStatus.connectionFailed:
      case DeviceConnectionStatus.error:
        return 'Connection Failed';
    }
  }

  String get userMessage {
    switch (this) {
      case DeviceConnectionStatus.idle:
        return 'Ready to connect';
      case DeviceConnectionStatus.scanning:
        return 'Scanning for BLE devices…';
      case DeviceConnectionStatus.deviceFound:
        return 'Target BLE peripheral located. Preparing link…';
      case DeviceConnectionStatus.connecting:
        return 'Establishing secure GATT link…';
      case DeviceConnectionStatus.connected:
        return 'Physical GATT link established';
      case DeviceConnectionStatus.discoveringServices:
        return 'Discovering peripheral GATT services…';
      case DeviceConnectionStatus.subscribingNotifications:
        return 'Subscribing to live telemetry notifications…';
      case DeviceConnectionStatus.ready:
        return 'Device connected & telemetry active';
      case DeviceConnectionStatus.disconnecting:
        return 'Releasing peripheral resources…';
      case DeviceConnectionStatus.disconnected:
        return 'Disconnected from device';
      case DeviceConnectionStatus.reconnecting:
        return 'Connection interrupted. Reconnecting…';
      case DeviceConnectionStatus.connectionFailed:
      case DeviceConnectionStatus.error:
        return 'Connection failed. Please check device status.';
    }
  }

  bool get isActive =>
      this == DeviceConnectionStatus.scanning ||
      this == DeviceConnectionStatus.deviceFound ||
      this == DeviceConnectionStatus.connecting ||
      this == DeviceConnectionStatus.connected ||
      this == DeviceConnectionStatus.discoveringServices ||
      this == DeviceConnectionStatus.subscribingNotifications ||
      this == DeviceConnectionStatus.disconnecting ||
      this == DeviceConnectionStatus.reconnecting;

  bool get isConnected =>
      this == DeviceConnectionStatus.connected ||
      this == DeviceConnectionStatus.ready;

  bool get isDisconnected =>
      this == DeviceConnectionStatus.disconnected ||
      this == DeviceConnectionStatus.idle ||
      this == DeviceConnectionStatus.connectionFailed ||
      this == DeviceConnectionStatus.error;
}

/// Generic Read-Only GATT characteristic representation for safe peripheral exploration
class DiscoveredCharacteristicInfo {
  final String uuid;
  final bool canRead;
  final bool canWrite;
  final bool canNotify;
  final bool canIndicate;
  final String? lastReadString;
  final List<int>? lastReadBytes;

  const DiscoveredCharacteristicInfo({
    required this.uuid,
    required this.canRead,
    required this.canWrite,
    required this.canNotify,
    required this.canIndicate,
    this.lastReadString,
    this.lastReadBytes,
  });
}

/// Generic Read-Only GATT service representation
class DiscoveredServiceInfo {
  final String uuid;
  final bool isPrimary;
  final List<DiscoveredCharacteristicInfo> characteristics;

  const DiscoveredServiceInfo({
    required this.uuid,
    required this.isPrimary,
    required this.characteristics,
  });
}

class DeviceModel {
  final String name;
  final String? id;
  final int? rssi;
  final DeviceConnectionStatus status;
  final DateTime? lastConnectedAt;
  final DateTime? lastDisconnectedAt;
  final DateTime? lastUpdatedAt;
  final int? samplingInterval;
  final String? errorMessage;
  final bool serviceFound;
  final bool temperatureCharFound;
  final bool humidityCharFound;
  final bool samplingIntervalCharFound;
  final bool alertCharFound;
  final bool gasCharFound;
  final bool mpuCharFound;
  final bool isGenericDevice;
  final String? alertStatus;

  // Generic GATT tree for explorer view
  final List<DiscoveredServiceInfo> discoveredServices;

  // Reliability telemetry
  final int reconnectAttempt;
  final int successfulConnections;
  final int unexpectedDisconnections;
  final int totalReconnectionAttempts;
  final DateTime? sessionConnectedSince;

  const DeviceModel({
    required this.name,
    this.id,
    this.rssi,
    this.status = DeviceConnectionStatus.idle,
    this.lastConnectedAt,
    this.lastDisconnectedAt,
    this.lastUpdatedAt,
    this.samplingInterval,
    this.errorMessage,
    this.serviceFound = false,
    this.temperatureCharFound = false,
    this.humidityCharFound = false,
    this.samplingIntervalCharFound = false,
    this.alertCharFound = false,
    this.gasCharFound = false,
    this.mpuCharFound = false,
    this.isGenericDevice = false,
    this.discoveredServices = const [],
    this.alertStatus,
    this.reconnectAttempt = 0,
    this.successfulConnections = 0,
    this.unexpectedDisconnections = 0,
    this.totalReconnectionAttempts = 0,
    this.sessionConnectedSince,
  });

  Duration? get connectionDuration {
    if (sessionConnectedSince == null || !status.isConnected) return null;
    return DateTime.now().difference(sessionConnectedSince!);
  }

  DeviceModel copyWith({
    String? name,
    String? id,
    int? rssi,
    DeviceConnectionStatus? status,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    DateTime? lastUpdatedAt,
    int? samplingInterval,
    String? errorMessage,
    bool clearError = false,
    bool? serviceFound,
    bool? temperatureCharFound,
    bool? humidityCharFound,
    bool? samplingIntervalCharFound,
    bool? alertCharFound,
    bool? gasCharFound,
    bool? mpuCharFound,
    bool? isGenericDevice,
    List<DiscoveredServiceInfo>? discoveredServices,
    String? alertStatus,
    int? reconnectAttempt,
    int? successfulConnections,
    int? unexpectedDisconnections,
    int? totalReconnectionAttempts,
    DateTime? sessionConnectedSince,
  }) {
    return DeviceModel(
      name: name ?? this.name,
      id: id ?? this.id,
      rssi: rssi ?? this.rssi,
      status: status ?? this.status,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? this.lastDisconnectedAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      samplingInterval: samplingInterval ?? this.samplingInterval,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      serviceFound: serviceFound ?? this.serviceFound,
      temperatureCharFound: temperatureCharFound ?? this.temperatureCharFound,
      humidityCharFound: humidityCharFound ?? this.humidityCharFound,
      samplingIntervalCharFound:
          samplingIntervalCharFound ?? this.samplingIntervalCharFound,
      alertCharFound: alertCharFound ?? this.alertCharFound,
      gasCharFound: gasCharFound ?? this.gasCharFound,
      mpuCharFound: mpuCharFound ?? this.mpuCharFound,
      isGenericDevice: isGenericDevice ?? this.isGenericDevice,
      discoveredServices: discoveredServices ?? this.discoveredServices,
      alertStatus: alertStatus ?? this.alertStatus,
      reconnectAttempt: reconnectAttempt ?? this.reconnectAttempt,
      successfulConnections:
          successfulConnections ?? this.successfulConnections,
      unexpectedDisconnections:
          unexpectedDisconnections ?? this.unexpectedDisconnections,
      totalReconnectionAttempts:
          totalReconnectionAttempts ?? this.totalReconnectionAttempts,
      sessionConnectedSince:
          sessionConnectedSince ?? this.sessionConnectedSince,
    );
  }
}
