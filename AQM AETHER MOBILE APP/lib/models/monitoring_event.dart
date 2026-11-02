// AQM AETHER — Monitoring Event Model

enum MonitoringEventType {
  deviceConnected,
  deviceDisconnected,
  monitoringStarted,
  monitoringStopped,
  readingReceived,
  samplingIntervalChanged,
  warning,
  error,
  reconnecting,
  reconnected,
}

extension MonitoringEventTypeExtension on MonitoringEventType {
  String get label {
    switch (this) {
      case MonitoringEventType.deviceConnected:
        return 'Device Connected';
      case MonitoringEventType.deviceDisconnected:
        return 'Device Disconnected';
      case MonitoringEventType.monitoringStarted:
        return 'Monitoring Started';
      case MonitoringEventType.monitoringStopped:
        return 'Monitoring Stopped';
      case MonitoringEventType.readingReceived:
        return 'Reading Received';
      case MonitoringEventType.samplingIntervalChanged:
        return 'Interval Changed';
      case MonitoringEventType.warning:
        return 'Warning';
      case MonitoringEventType.error:
        return 'Error';
      case MonitoringEventType.reconnecting:
        return 'Reconnecting';
      case MonitoringEventType.reconnected:
        return 'Reconnected';
    }
  }

  String get icon {
    switch (this) {
      case MonitoringEventType.deviceConnected:
        return '🔗';
      case MonitoringEventType.deviceDisconnected:
        return '🔌';
      case MonitoringEventType.monitoringStarted:
        return '▶';
      case MonitoringEventType.monitoringStopped:
        return '⏹';
      case MonitoringEventType.readingReceived:
        return '📡';
      case MonitoringEventType.samplingIntervalChanged:
        return '⏱';
      case MonitoringEventType.warning:
        return '⚠';
      case MonitoringEventType.error:
        return '✕';
      case MonitoringEventType.reconnecting:
        return '↺';
      case MonitoringEventType.reconnected:
        return '✓';
    }
  }
}

class MonitoringEvent {
  final int? id;
  final DateTime timestamp;
  final MonitoringEventType type;
  final String message;
  final String? detail;

  const MonitoringEvent({
    this.id,
    required this.timestamp,
    required this.type,
    required this.message,
    this.detail,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.index,
      'message': message,
      'detail': detail,
    };
  }

  factory MonitoringEvent.fromMap(Map<String, dynamic> map) {
    return MonitoringEvent(
      id: map['id'] as int?,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      type: MonitoringEventType.values[map['type'] as int],
      message: map['message'] as String,
      detail: map['detail'] as String?,
    );
  }
}

