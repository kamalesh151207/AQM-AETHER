// AQM AETHER — Smart Notification Preferences
// Manages application-level notification toggles persisted via SharedPreferences

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferences extends ChangeNotifier {
  static final NotificationPreferences _instance =
      NotificationPreferences._internal();
  factory NotificationPreferences() => _instance;
  NotificationPreferences._internal();

  bool _enableTempAlerts = true;
  bool _enableHumAlerts = true;
  bool _enableDeviceConnected = true;
  bool _enableDeviceDisconnected = true;
  bool _enableMonitoringUpdates = true;
  bool _enableSound = true;
  bool _enableVibration = true;

  bool get enableTempAlerts => _enableTempAlerts;
  bool get enableHumAlerts => _enableHumAlerts;
  bool get enableDeviceConnected => _enableDeviceConnected;
  bool get enableDeviceDisconnected => _enableDeviceDisconnected;
  bool get enableMonitoringUpdates => _enableMonitoringUpdates;
  bool get enableSound => _enableSound;
  bool get enableVibration => _enableVibration;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enableTempAlerts = prefs.getBool('notif_temp_enabled') ?? true;
      _enableHumAlerts = prefs.getBool('notif_hum_enabled') ?? true;
      _enableDeviceConnected = prefs.getBool('notif_device_connected') ?? true;
      _enableDeviceDisconnected = prefs.getBool('notif_device_disconnected') ?? true;
      _enableMonitoringUpdates = prefs.getBool('notif_monitoring_updates') ?? true;
      _enableSound = prefs.getBool('notif_sound_enabled') ?? true;
      _enableVibration = prefs.getBool('notif_vibration_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationPreferences] Load error: $e');
    }
  }

  Future<void> setEnableTempAlerts(bool value) async {
    _enableTempAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_temp_enabled', value);
    notifyListeners();
  }

  Future<void> setEnableHumAlerts(bool value) async {
    _enableHumAlerts = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_hum_enabled', value);
    notifyListeners();
  }

  Future<void> setEnableDeviceConnected(bool value) async {
    _enableDeviceConnected = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_device_connected', value);
    notifyListeners();
  }

  Future<void> setEnableDeviceDisconnected(bool value) async {
    _enableDeviceDisconnected = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_device_disconnected', value);
    notifyListeners();
  }

  Future<void> setEnableMonitoringUpdates(bool value) async {
    _enableMonitoringUpdates = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_monitoring_updates', value);
    notifyListeners();
  }

  Future<void> setEnableSound(bool value) async {
    _enableSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_sound_enabled', value);
    notifyListeners();
  }

  Future<void> setEnableVibration(bool value) async {
    _enableVibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_vibration_enabled', value);
    notifyListeners();
  }
}

