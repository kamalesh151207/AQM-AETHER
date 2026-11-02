// AQM AETHER — Settings Provider

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  bool _autoReconnect = true;
  bool _hapticFeedback = true;
  bool _darkTheme = true; // Always dark for this app

  SettingsProvider(this._storage) {
    _load();
  }

  bool get autoReconnect => _autoReconnect;
  bool get hapticFeedback => _hapticFeedback;
  bool get darkTheme => _darkTheme;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _autoReconnect = prefs.getBool('autoReconnect') ?? true;
    _hapticFeedback = prefs.getBool('hapticFeedback') ?? true;
    _darkTheme = prefs.getBool('darkTheme') ?? true;
    notifyListeners();
  }

  Future<void> setAutoReconnect(bool value) async {
    _autoReconnect = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoReconnect', value);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hapticFeedback', value);
    notifyListeners();
  }

  Future<void> setDarkTheme(bool value) async {
    _darkTheme = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkTheme', value);
    notifyListeners();
  }

  Future<void> clearStoredHistory() async {
    await _storage.clearAll();
    notifyListeners();
  }
}

