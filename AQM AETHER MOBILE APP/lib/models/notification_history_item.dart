// AQM AETHER — Notification History Item Model
// Persistent record of dispatched system notifications with audit metadata

enum NotificationCategory {
  temperature('Temperature Alert'),
  humidity('Humidity Alert'),
  combined('Environmental Warning'),
  deviceConnected('Device Connected'),
  deviceDisconnected('Device Disconnected'),
  monitoring('Monitoring Update');

  final String label;
  const NotificationCategory(this.label);
}

class NotificationHistoryItem {
  final String id;
  final int notificationId;
  final NotificationCategory category;
  final String title;
  final String body;
  final double? measuredTemp;
  final double? measuredHum;
  final String? thresholdInfo;
  final DateTime timestamp;
  final bool isDelivered;
  bool isAcknowledged;
  String? actionTaken;

  NotificationHistoryItem({
    required this.id,
    required this.notificationId,
    required this.category,
    required this.title,
    required this.body,
    this.measuredTemp,
    this.measuredHum,
    this.thresholdInfo,
    required this.timestamp,
    this.isDelivered = true,
    this.isAcknowledged = false,
    this.actionTaken,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'notificationId': notificationId,
        'category': category.name,
        'title': title,
        'body': body,
        'measuredTemp': measuredTemp,
        'measuredHum': measuredHum,
        'thresholdInfo': thresholdInfo,
        'timestamp': timestamp.toIso8601String(),
        'isDelivered': isDelivered,
        'isAcknowledged': isAcknowledged,
        'actionTaken': actionTaken,
      };

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) =>
      NotificationHistoryItem(
        id: json['id'] as String,
        notificationId: json['notificationId'] as int,
        category: NotificationCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => NotificationCategory.monitoring,
        ),
        title: json['title'] as String,
        body: json['body'] as String,
        measuredTemp: (json['measuredTemp'] as num?)?.toDouble(),
        measuredHum: (json['measuredHum'] as num?)?.toDouble(),
        thresholdInfo: json['thresholdInfo'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isDelivered: json['isDelivered'] as bool? ?? true,
        isAcknowledged: json['isAcknowledged'] as bool? ?? false,
        actionTaken: json['actionTaken'] as String?,
      );
}

