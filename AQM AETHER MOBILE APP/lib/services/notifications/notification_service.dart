// AQM AETHER — Android Local Notification Service
// Complete Android notification system with dedicated channels, permission handling, deep links & audit logs

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_channels.dart';
import 'notification_preferences.dart';
import '../../models/notification_history_item.dart';
import '../threshold/threshold_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final NotificationPreferences _prefs = NotificationPreferences();

  bool _isInitialized = false;
  final ValueNotifier<String?> navigationPayloadNotifier = ValueNotifier(null);

  // Rate Limiting & Anti-Spam state
  DateTime? _lastCriticalNotificationTime;
  String? _lastCriticalSignature;
  DateTime? _lastDisconnectNotificationTime;
  static const Duration _disconnectCooldown = Duration(seconds: 45);
  static const Duration _criticalCooldown = Duration(seconds: 25);

  // Persistent Notification Audit Log
  final List<NotificationHistoryItem> _history = [];
  List<NotificationHistoryItem> get history => List.unmodifiable(_history);

  NotificationPreferences get preferences => _prefs;

  // ── Initialization ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _prefs.initialize();
    await _loadHistory();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationResponse,
      );

      // Create all 3 dedicated Android Notification Channels
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        for (final channel in AqmNotificationChannels.allChannels) {
          await androidPlugin.createNotificationChannel(channel);
        }
      }

      // Check if launched from terminated state via notification tap
      final launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        _handleNotificationResponse(launchDetails.notificationResponse!);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Initialization error: $e');
    }
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    debugPrint('[Notification] Tap response: payload=$payload, action=$actionId');

    // Handle action buttons
    if (actionId == 'action_ack') {
      ThresholdService().acknowledgeAlert();
      _markNotificationAcknowledged(payload);
      return;
    }

    if (payload != null && payload.isNotEmpty) {
      if (payload.startsWith('alert:')) {
        navigationPayloadNotifier.value = 'nav:alerts';
      } else if (payload.startsWith('device:')) {
        navigationPayloadNotifier.value = 'nav:settings';
      } else {
        navigationPayloadNotifier.value = 'nav:overview';
      }
    }
  }

  // ── Permissions Handling ───────────────────────────────────────────────────

  Future<PermissionStatus> checkPermissionStatus() async {
    try {
      return await Permission.notification.status;
    } catch (e) {
      debugPrint('[NotificationService] Check permission error: $e');
      return PermissionStatus.denied;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == true) return true;
      }

      // Fallback via permission_handler
      final status = await Permission.notification.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('[NotificationService] Permission request error: $e');
      return false;
    }
  }

  Future<void> openAndroidSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      debugPrint('[NotificationService] Open settings error: $e');
    }
  }

  // ── Channel 1: Critical Threshold Alerts ────────────────────────────────────

  Future<void> showThresholdAlert({
    required AlertSource source,
    required double temp,
    required double hum,
    required double tempThreshold,
    required double humThreshold,
  }) async {
    if (!_isInitialized) await initialize();

    // Check application-level user preferences
    if (source == AlertSource.temperature && !_prefs.enableTempAlerts) return;
    if (source == AlertSource.humidity && !_prefs.enableHumAlerts) return;
    if (source == AlertSource.both &&
        !_prefs.enableTempAlerts &&
        !_prefs.enableHumAlerts) {
      return;
    }

    // Rate-limiting / anti-spam guard
    final now = DateTime.now();
    final signature = '${source.name}_${temp.toStringAsFixed(0)}_${hum.toStringAsFixed(0)}';
    if (_lastCriticalNotificationTime != null &&
        now.difference(_lastCriticalNotificationTime!) < _criticalCooldown &&
        _lastCriticalSignature == signature) {
      debugPrint('[NotificationService] Suppressing duplicate critical alert');
      return;
    }

    _lastCriticalNotificationTime = now;
    _lastCriticalSignature = signature;

    String title;
    String body;
    NotificationCategory category;
    const int notifId = 1001;

    if (source == AlertSource.both) {
      category = NotificationCategory.combined;
      title = 'AQM AETHER – Environmental Warning';
      body =
          'Temperature: ${temp.toStringAsFixed(1)}°C (Limit: ${tempThreshold.toStringAsFixed(1)}°C)\n'
          'Humidity: ${hum.toStringAsFixed(1)}% (Limit: ${humThreshold.toStringAsFixed(1)}%)\n'
          'Both configured thresholds have been exceeded.';
    } else if (source == AlertSource.temperature) {
      category = NotificationCategory.temperature;
      title = 'AQM AETHER – Temperature Alert';
      body =
          'Temperature reached ${temp.toStringAsFixed(1)}°C.\n'
          'Your configured limit is ${tempThreshold.toStringAsFixed(1)}°C.';
    } else {
      category = NotificationCategory.humidity;
      title = 'AQM AETHER – Humidity Alert';
      body =
          'Humidity reached ${hum.toStringAsFixed(1)}%.\n'
          'Your configured limit is ${humThreshold.toStringAsFixed(1)}%.';
    }

    final androidDetails = AndroidNotificationDetails(
      AqmNotificationChannels.criticalAlertsId,
      AqmNotificationChannels.criticalAlertsName,
      channelDescription: AqmNotificationChannels.criticalAlertsDesc,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Environmental Threshold Exceeded',
      icon: '@mipmap/ic_launcher',
      playSound: _prefs.enableSound,
      enableVibration: _prefs.enableVibration,
      category: AndroidNotificationCategory.alarm,
      actions: const [
        AndroidNotificationAction(
          'action_view',
          'View Alert',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_ack',
          'Acknowledge',
          showsUserInterface: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        notifId,
        title,
        body,
        details,
        payload: 'alert:${source.name}',
      );

      _recordHistory(
        notificationId: notifId,
        category: category,
        title: title,
        body: body,
        measuredTemp: temp,
        measuredHum: hum,
        thresholdInfo:
            'T:${tempThreshold.toStringAsFixed(1)}°C, H:${humThreshold.toStringAsFixed(1)}%',
      );
    } catch (e) {
      debugPrint('[NotificationService] Show threshold alert error: $e');
    }
  }

  // ── Channel 2: Device Connection & Status Alerts ───────────────────────────

  Future<void> showDeviceConnected({required String deviceName}) async {
    if (!_isInitialized) await initialize();
    if (!_prefs.enableDeviceConnected) return;

    const notifId = 2001;
    const title = 'AQM AETHER – Device Connected';
    final body = '$deviceName is connected successfully.';

    final androidDetails = AndroidNotificationDetails(
      AqmNotificationChannels.deviceStatusId,
      AqmNotificationChannels.deviceStatusName,
      channelDescription: AqmNotificationChannels.deviceStatusDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      playSound: _prefs.enableSound,
      enableVibration: false,
      actions: const [
        AndroidNotificationAction(
          'action_view_device',
          'View Device',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        notifId,
        title,
        body,
        details,
        payload: 'device:connected',
      );

      _recordHistory(
        notificationId: notifId,
        category: NotificationCategory.deviceConnected,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show connected error: $e');
    }
  }

  Future<void> showDeviceDisconnected({
    required String deviceName,
    String? reason,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_prefs.enableDeviceDisconnected) return;

    // Rate-limiting guard: prevent repeating disconnection notifications during reconnect backoff loops!
    final now = DateTime.now();
    if (_lastDisconnectNotificationTime != null &&
        now.difference(_lastDisconnectNotificationTime!) < _disconnectCooldown) {
      debugPrint('[NotificationService] Suppressing repeated disconnect notification during backoff');
      return;
    }
    _lastDisconnectNotificationTime = now;

    const notifId = 2002;
    const title = 'AQM AETHER – Device Disconnected';
    final body =
        'The $deviceName connection was interrupted.\n'
        'Reconnection will be attempted automatically.';

    final androidDetails = AndroidNotificationDetails(
      AqmNotificationChannels.deviceStatusId,
      AqmNotificationChannels.deviceStatusName,
      channelDescription: AqmNotificationChannels.deviceStatusDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      playSound: _prefs.enableSound,
      enableVibration: false,
      actions: const [
        AndroidNotificationAction(
          'action_view_device',
          'View Device',
          showsUserInterface: true,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        notifId,
        title,
        body,
        details,
        payload: 'device:disconnected',
      );

      _recordHistory(
        notificationId: notifId,
        category: NotificationCategory.deviceDisconnected,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show disconnected error: $e');
    }
  }

  // ── Channel 3: Monitoring & Informational Updates ──────────────────────────

  Future<void> showMonitoringUpdate({
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) await initialize();
    if (!_prefs.enableMonitoringUpdates) return;

    const notifId = 3001;

    const androidDetails = AndroidNotificationDetails(
      AqmNotificationChannels.monitoringUpdatesId,
      AqmNotificationChannels.monitoringUpdatesName,
      channelDescription: AqmNotificationChannels.monitoringUpdatesDesc,
      importance: Importance.low,
      priority: Priority.low,
      icon: '@mipmap/ic_launcher',
      playSound: false,
      enableVibration: false,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(
        notifId,
        title,
        body,
        details,
        payload: 'monitoring:update',
      );

      _recordHistory(
        notificationId: notifId,
        category: NotificationCategory.monitoring,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show monitoring update error: $e');
    }
  }

  // ── Immediate Test Notification ────────────────────────────────────────────

  Future<void> sendTestNotification() async {
    if (!_isInitialized) await initialize();

    await requestPermission();

    const notifId = 9999;
    const title = 'AQM AETHER – Test Notification';
    const body =
        'System notifications and dedicated Android channels are fully operational.';

    const androidDetails = AndroidNotificationDetails(
      AqmNotificationChannels.criticalAlertsId,
      AqmNotificationChannels.criticalAlertsName,
      channelDescription: AqmNotificationChannels.criticalAlertsDesc,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      actions: [
        AndroidNotificationAction(
          'action_view',
          'Open App',
          showsUserInterface: true,
        ),
      ],
    );

    try {
      await _notifications.show(
        notifId,
        title,
        body,
        const NotificationDetails(android: androidDetails),
        payload: 'alert:test',
      );

      _recordHistory(
        notificationId: notifId,
        category: NotificationCategory.monitoring,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('[NotificationService] Send test notification error: $e');
    }
  }

  // ── Audit History Management ───────────────────────────────────────────────

  void _recordHistory({
    required int notificationId,
    required NotificationCategory category,
    required String title,
    required String body,
    double? measuredTemp,
    double? measuredHum,
    String? thresholdInfo,
  }) {
    final item = NotificationHistoryItem(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      notificationId: notificationId,
      category: category,
      title: title,
      body: body,
      measuredTemp: measuredTemp,
      measuredHum: measuredHum,
      thresholdInfo: thresholdInfo,
      timestamp: DateTime.now(),
      isDelivered: true,
    );

    _history.insert(0, item);
    if (_history.length > 100) _history.removeLast();
    _saveHistory();
    notifyListeners();
  }

  void _markNotificationAcknowledged(String? payload) {
    if (_history.isNotEmpty) {
      _history.first.isAcknowledged = true;
      _history.first.actionTaken = 'Acknowledged via notification action';
      _saveHistory();
      notifyListeners();
    }
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('aqm_notification_history') ?? [];
      _history.clear();
      for (final s in list) {
        try {
          _history.add(NotificationHistoryItem.fromJson(jsonDecode(s)));
        } catch (_) {}
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationService] Load history error: $e');
    }
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _history.take(100).map((i) => jsonEncode(i.toJson())).toList();
      await prefs.setStringList('aqm_notification_history', list);
    } catch (e) {
      debugPrint('[NotificationService] Save history error: $e');
    }
  }

  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('aqm_notification_history');
    notifyListeners();
  }
}
