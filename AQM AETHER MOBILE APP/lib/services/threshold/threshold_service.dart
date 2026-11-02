// AQM AETHER — Threshold & Audible Alarm Engine
// Evaluates live telemetry, controls audio chimes, manages state machine & persistence

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../alarm/alarm_audio_generator.dart';
import '../notifications/notification_service.dart';

enum AlarmState {
  normal('NORMAL', 'Optimal environmental state'),
  warning('WARNING', 'Approaching threshold limits'),
  critical('CRITICAL', 'Threshold limit breached'),
  acknowledged('ACKNOWLEDGED', 'Alert acknowledged by user'),
  muted('MUTED', 'Audible alert temporarily muted');

  final String label;
  final String description;
  const AlarmState(this.label, this.description);
}

enum AlertSource {
  none('None'),
  temperature('Temperature'),
  humidity('Humidity'),
  both('Temperature & Humidity');

  final String label;
  const AlertSource(this.label);
}

class ThresholdAlertItem {
  final String id;
  final AlertSource source;
  final double measuredTemp;
  final double tempThreshold;
  final double measuredHum;
  final double humThreshold;
  final DateTime timestamp;
  final bool isTempExceeded;
  final bool isHumExceeded;
  bool isAcknowledged;
  DateTime? resolvedAt;

  ThresholdAlertItem({
    required this.id,
    required this.source,
    required this.measuredTemp,
    required this.tempThreshold,
    required this.measuredHum,
    required this.humThreshold,
    required this.timestamp,
    required this.isTempExceeded,
    required this.isHumExceeded,
    this.isAcknowledged = false,
    this.resolvedAt,
  });

  bool get isResolved => resolvedAt != null;
}

class ThresholdService extends ChangeNotifier {
  static final ThresholdService _instance = ThresholdService._internal();
  factory ThresholdService() => _instance;
  ThresholdService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService();
  Uint8List? _cachedWavBytes;

  // ── Configuration State (Persisted) ────────────────────────────────────────
  double _temperatureThreshold = 30.0;
  double _humidityThreshold = 60.0;
  bool _isSoundEnabled = true;
  double _alarmVolume = 1.0;
  int _repeatIntervalSeconds = 30;
  int _muteDurationMinutes = 15;
  bool _isNotificationsEnabled = true;

  // ── Runtime Alarm State ───────────────────────────────────────────────────
  AlarmState _state = AlarmState.normal;
  AlertSource _activeSource = AlertSource.none;

  DateTime? _lastTriggeredAt;
  DateTime? _lastSoundPlayedAt;
  DateTime? _mutedUntil;
  bool _isUserAcknowledged = false;

  // Recorded Alert History
  final List<ThresholdAlertItem> _alertHistory = [];

  // Getters
  double get temperatureThreshold => _temperatureThreshold;
  double get humidityThreshold => _humidityThreshold;
  bool get isSoundEnabled => _isSoundEnabled;
  double get alarmVolume => _alarmVolume;
  int get repeatIntervalSeconds => _repeatIntervalSeconds;
  int get muteDurationMinutes => _muteDurationMinutes;
  bool get isNotificationsEnabled => _isNotificationsEnabled;

  AlarmState get state => _state;
  AlertSource get activeSource => _activeSource;
  DateTime? get lastTriggeredAt => _lastTriggeredAt;
  DateTime? get mutedUntil => _mutedUntil;
  bool get isUserAcknowledged => _isUserAcknowledged;
  List<ThresholdAlertItem> get alertHistory => List.unmodifiable(_alertHistory);

  bool get isMuted {
    if (_mutedUntil == null) return false;
    return DateTime.now().isBefore(_mutedUntil!);
  }

  bool get isAlarmActive =>
      _state == AlarmState.critical ||
      _state == AlarmState.acknowledged ||
      _state == AlarmState.muted;

  // ── Initialization & Persistence ──────────────────────────────────────────

  Future<void> initialize() async {
    _cachedWavBytes = AlarmAudioGenerator.generateWarningWav();
    await _notificationService.initialize();
    await _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _temperatureThreshold = prefs.getDouble('thresh_temp') ?? 30.0;
      _humidityThreshold = prefs.getDouble('thresh_hum') ?? 60.0;
      _isSoundEnabled = prefs.getBool('thresh_sound_enabled') ?? true;
      _alarmVolume = prefs.getDouble('thresh_alarm_volume') ?? 1.0;
      _repeatIntervalSeconds = prefs.getInt('thresh_repeat_seconds') ?? 30;
      _muteDurationMinutes = prefs.getInt('thresh_mute_minutes') ?? 15;
      _isNotificationsEnabled = prefs.getBool('thresh_notif_enabled') ?? true;
      notifyListeners();
    } catch (e) {
      debugPrint('[ThresholdService] Load prefs error: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('thresh_temp', _temperatureThreshold);
      await prefs.setDouble('thresh_hum', _humidityThreshold);
      await prefs.setBool('thresh_sound_enabled', _isSoundEnabled);
      await prefs.setDouble('thresh_alarm_volume', _alarmVolume);
      await prefs.setInt('thresh_repeat_seconds', _repeatIntervalSeconds);
      await prefs.setInt('thresh_mute_minutes', _muteDurationMinutes);
      await prefs.setBool('thresh_notif_enabled', _isNotificationsEnabled);
    } catch (e) {
      debugPrint('[ThresholdService] Save prefs error: $e');
    }
  }

  // ── Configuration Setters ──────────────────────────────────────────────────

  Future<void> setTemperatureThreshold(double value) async {
    _temperatureThreshold = double.parse(value.toStringAsFixed(1));
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setHumidityThreshold(double value) async {
    _humidityThreshold = double.parse(value.toStringAsFixed(1));
    await _savePreferences();
    notifyListeners();
  }

  Future<void> resetToDefaults() async {
    _temperatureThreshold = 30.0;
    _humidityThreshold = 60.0;
    _isSoundEnabled = true;
    _alarmVolume = 1.0;
    _repeatIntervalSeconds = 30;
    _muteDurationMinutes = 15;
    _isNotificationsEnabled = true;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool enabled) async {
    _isSoundEnabled = enabled;
    if (!enabled) await stopAlarmSound();
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setAlarmVolume(double volume) async {
    _alarmVolume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_alarmVolume);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setRepeatInterval(int seconds) async {
    _repeatIntervalSeconds = seconds.clamp(5, 300);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMuteDuration(int minutes) async {
    _muteDurationMinutes = minutes.clamp(1, 120);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _isNotificationsEnabled = enabled;
    if (enabled) {
      await _notificationService.requestPermission();
    }
    await _savePreferences();
    notifyListeners();
  }

  // ── Telemetry Evaluation Engine ────────────────────────────────────────────

  void evaluateTelemetry({
    required double? temperature,
    required double? humidity,
    required bool isStale,
  }) {
    // Strict Guard: Never evaluate stale or uninitialized readings
    if (temperature == null || humidity == null || isStale) {
      return;
    }

    final bool isTempBreached = temperature >= _temperatureThreshold;
    final bool isHumBreached = humidity >= _humidityThreshold;

    if (isTempBreached || isHumBreached) {
      // Threshold Exceeded
      AlertSource source = AlertSource.none;
      if (isTempBreached && isHumBreached) {
        source = AlertSource.both;
      } else if (isTempBreached) {
        source = AlertSource.temperature;
      } else {
        source = AlertSource.humidity;
      }

      _handleThresholdViolation(
        source: source,
        temp: temperature,
        hum: humidity,
        isTempBreached: isTempBreached,
        isHumBreached: isHumBreached,
      );
    } else {
      // Both parameters within normal baseline
      _handleThresholdRestoration();
    }
  }

  void _handleThresholdViolation({
    required AlertSource source,
    required double temp,
    required double hum,
    required bool isTempBreached,
    required bool isHumBreached,
  }) {
    final now = DateTime.now();
    _activeSource = source;

    // Check if transitioning from normal
    final bool isNewViolation = _state == AlarmState.normal || _state == AlarmState.warning;

    if (isNewViolation) {
      _state = AlarmState.critical;
      _lastTriggeredAt = now;
      _isUserAcknowledged = false;
      _mutedUntil = null;

      // Create alert record in history
      final alertItem = ThresholdAlertItem(
        id: 'alert_${now.millisecondsSinceEpoch}',
        source: source,
        measuredTemp: temp,
        tempThreshold: _temperatureThreshold,
        measuredHum: hum,
        humThreshold: _humidityThreshold,
        timestamp: now,
        isTempExceeded: isTempBreached,
        isHumExceeded: isHumBreached,
      );
      _alertHistory.insert(0, alertItem);
      if (_alertHistory.length > 100) _alertHistory.removeLast();

      // Trigger immediate audio & notification
      _triggerAlarmSound();
      _dispatchLocalNotification(source, temp, hum);
    } else {
      // Condition remains active: Respect Mute & Repeat Cooldown
      if (isMuted) {
        _state = AlarmState.muted;
      } else if (_isUserAcknowledged) {
        _state = AlarmState.acknowledged;
      } else {
        _state = AlarmState.critical;
        // Check cooldown interval for sound repeat
        if (_lastSoundPlayedAt == null ||
            now.difference(_lastSoundPlayedAt!).inSeconds >= _repeatIntervalSeconds) {
          _triggerAlarmSound();
        }
      }
    }

    notifyListeners();
  }

  void _handleThresholdRestoration() {
    if (_state != AlarmState.normal) {
      // Mark active alert as resolved in history
      if (_alertHistory.isNotEmpty && !_alertHistory.first.isResolved) {
        _alertHistory.first.resolvedAt = DateTime.now();
      }

      _state = AlarmState.normal;
      _activeSource = AlertSource.none;
      _isUserAcknowledged = false;
      _mutedUntil = null;
      stopAlarmSound();
      notifyListeners();
    }
  }

  // ── Alarm Controls (Acknowledge, Mute, Test) ───────────────────────────────

  void acknowledgeAlert() {
    if (isAlarmActive) {
      _isUserAcknowledged = true;
      _state = AlarmState.acknowledged;
      stopAlarmSound();
      if (_alertHistory.isNotEmpty) {
        _alertHistory.first.isAcknowledged = true;
      }
      notifyListeners();
    }
  }

  void muteAlert([Duration? duration]) {
    final effectiveDuration = duration ?? Duration(minutes: _muteDurationMinutes);
    _mutedUntil = DateTime.now().add(effectiveDuration);
    _state = AlarmState.muted;
    stopAlarmSound();
    notifyListeners();
  }

  void unmuteAlert() {
    _mutedUntil = null;
    if (_state == AlarmState.muted) {
      _state = _isUserAcknowledged ? AlarmState.acknowledged : AlarmState.critical;
    }
    notifyListeners();
  }

  Future<void> testAlarmSound() async {
    await _triggerAlarmSound(force: true);
  }

  Future<void> _triggerAlarmSound({bool force = false}) async {
    if (!_isSoundEnabled && !force) return;

    try {
      _lastSoundPlayedAt = DateTime.now();

      // Multi-sensory feedback: Haptics + Audio Tone
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);

      _cachedWavBytes ??= AlarmAudioGenerator.generateWarningWav();
      await _audioPlayer.setVolume(_alarmVolume);
      await _audioPlayer.stop();
      await _audioPlayer.play(BytesSource(_cachedWavBytes!));
    } catch (e) {
      debugPrint('[ThresholdService] Audio play error: $e');
    }
  }

  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      debugPrint('[ThresholdService] Audio stop error: $e');
    }
  }

  Future<void> _dispatchLocalNotification(
    AlertSource source,
    double temp,
    double hum,
  ) async {
    if (!_isNotificationsEnabled) return;

    await _notificationService.showThresholdAlert(
      source: source,
      temp: temp,
      hum: hum,
      tempThreshold: _temperatureThreshold,
      humThreshold: _humidityThreshold,
    );
  }

  void clearAlertHistory() {
    _alertHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
