// AQM AETHER — Android Notification Channels Definition
// Configures dedicated channels with specific importance levels and vibration profiles

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class AqmNotificationChannels {
  // ── Channel 1: Critical Threshold Alerts ────────────────────────────────────
  static const String criticalAlertsId = 'aqm_critical_alerts';
  static const String criticalAlertsName = 'AQM Critical Alerts';
  static const String criticalAlertsDesc =
      'High-priority warnings triggered when temperature or humidity thresholds are breached.';

  static const AndroidNotificationChannel criticalAlertsChannel =
      AndroidNotificationChannel(
    criticalAlertsId,
    criticalAlertsName,
    description: criticalAlertsDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  // ── Channel 2: Device Connection & Status ──────────────────────────────────
  static const String deviceStatusId = 'aqm_device_status';
  static const String deviceStatusName = 'AQM Device Status';
  static const String deviceStatusDesc =
      'Notifications regarding ESP32 BLE connection, disconnection, and reconnection events.';

  static const AndroidNotificationChannel deviceStatusChannel =
      AndroidNotificationChannel(
    deviceStatusId,
    deviceStatusName,
    description: deviceStatusDesc,
    importance: Importance.defaultImportance,
    playSound: true,
    enableVibration: false,
    showBadge: true,
  );

  // ── Channel 3: Monitoring & Telemetry Updates ──────────────────────────────
  static const String monitoringUpdatesId = 'aqm_monitoring_updates';
  static const String monitoringUpdatesName = 'AQM Monitoring Updates';
  static const String monitoringUpdatesDesc =
      'Informational telemetry updates, report summaries, and data logging milestones.';

  static const AndroidNotificationChannel monitoringUpdatesChannel =
      AndroidNotificationChannel(
    monitoringUpdatesId,
    monitoringUpdatesName,
    description: monitoringUpdatesDesc,
    importance: Importance.low,
    playSound: false,
    enableVibration: false,
    showBadge: false,
  );

  static const List<AndroidNotificationChannel> allChannels = [
    criticalAlertsChannel,
    deviceStatusChannel,
    monitoringUpdatesChannel,
  ];
}

