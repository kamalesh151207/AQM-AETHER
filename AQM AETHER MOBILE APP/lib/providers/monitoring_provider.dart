// AQM AETHER — Monitoring Provider
// Persistent Sensor Telemetry & Analytics Store with Smart Insights

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/sensor_reading.dart';
import '../models/monitoring_event.dart';
import '../services/storage_service.dart';
import '../services/csv_export_service.dart';
import '../core/constants/ble_constants.dart';

class MonitoringProvider extends ChangeNotifier {
  final StorageService _storage;

  final List<SensorReading> _readings = [];
  final List<MonitoringEvent> _events = [];

  // Batching partial readings
  double? _pendingTemp;
  double? _pendingHumidity;
  int? _pendingGas;
  String? _pendingAlert = 'NORMAL';
  String? _pendingConnection = 'Connected';
  int? _pendingInterval = 2;
  double? _pendingAx;
  double? _pendingAy;
  double? _pendingAz;
  double? _pendingGx;
  double? _pendingGy;
  double? _pendingGz;
  Timer? _readingFlushTimer;

  DateTime? _monitoringStartedAt;
  int _totalSamplesReceived = 0;
  bool _isLoading = false;
  bool _isRecordingPaused = false;

  MonitoringProvider(this._storage) {
    _loadHistory();
  }

  // ── Getters ────────────────────────────────────────────────────────────────

  List<SensorReading> get readings => List.unmodifiable(_readings);
  List<MonitoringEvent> get events => List.unmodifiable(_events);
  List<SensorReading> get gasReadings =>
      _readings.where((r) => r.gasRawAdc != null).toList();
  List<SensorReading> get motionReadings =>
      _readings.where((r) => r.accelX != null || r.gyroX != null).toList();
  int get totalSamplesReceived => _totalSamplesReceived;
  DateTime? get monitoringStartedAt => _monitoringStartedAt;
  bool get isLoading => _isLoading;
  bool get isRecordingPaused => _isRecordingPaused;

  void toggleRecording() {
    _isRecordingPaused = !_isRecordingPaused;
    addEvent(MonitoringEvent(
      timestamp: DateTime.now(),
      type: _isRecordingPaused
          ? MonitoringEventType.warning
          : MonitoringEventType.monitoringStarted,
      message: _isRecordingPaused
          ? 'Data persistence paused by user'
          : 'Data persistence resumed',
      detail: _isRecordingPaused
          ? 'Live stream continues, storage writes suspended.'
          : 'Incoming readings are saved to local database.',
    ));
    notifyListeners();
  }

  void toggleRecordingPause() => toggleRecording();

  Future<bool> exportCsv() async {
    if (_readings.isEmpty) return false;
    try {
      await CsvExportService().shareExport(_readings);
      return true;
    } catch (e) {
      debugPrint('[MonitoringProvider] CSV Export error: $e');
      return false;
    }
  }

  List<SensorReading> readingsInRange(DateTime from, DateTime to) {
    return _readings
        .where((r) => r.timestamp.isAfter(from) && r.timestamp.isBefore(to))
        .toList();
  }

  List<SensorReading> get readingsLast1Minute {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<SensorReading> get readingsLast5Minutes {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<SensorReading> get readingsLast15Minutes {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 15));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<SensorReading> get readingsLast1Hour {
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<SensorReading> get readingsLast24Hours {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  List<SensorReading> get readingsLast7Days {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return _readings.where((r) => r.timestamp.isAfter(cutoff)).toList();
  }

  // ── Smart Insights (Computed from real telemetry) ──────────────────────────

  List<String> get smartInsights {
    final insights = <String>[];
    if (_readings.length < 5) {
      insights.add(
        'Collecting telemetry: at least 5 readings required for trend analysis.',
      );
      return insights;
    }

    final recent = readingsLast15Minutes;
    if (recent.length >= 3) {
      final first = recent.first;
      final last = recent.last;

      if (first.temperature != null && last.temperature != null) {
        final diff = last.temperature! - first.temperature!;
        if (diff.abs() >= 0.4) {
          insights.add(
            'Temperature ${diff > 0 ? "increased" : "decreased"} by ${diff.abs().toStringAsFixed(1)}°C during the last 15 minutes.',
          );
        } else {
          insights.add(
            'Temperature remained stable at ~${last.temperature!.toStringAsFixed(1)}°C over the last 15 minutes.',
          );
        }
      }

      if (first.humidity != null && last.humidity != null) {
        final diff = last.humidity! - first.humidity!;
        if (diff.abs() >= 2.0) {
          insights.add(
            'Humidity shifted by ${diff > 0 ? "+" : ""}${diff.toStringAsFixed(1)}% recently.',
          );
        } else {
          insights.add('Humidity remained steady within comfortable range.');
        }
      }
    }

    // Historical range
    final temps = _readings
        .map((r) => r.temperature)
        .whereType<double>()
        .toList();
    if (temps.isNotEmpty) {
      final min = temps.reduce((a, b) => a < b ? a : b);
      final max = temps.reduce((a, b) => a > b ? a : b);
      insights.add(
        'Recorded extremes: min ${min.toStringAsFixed(1)}°C, max ${max.toStringAsFixed(1)}°C.',
      );
    }

    return insights;
  }

  // ── Load History ───────────────────────────────────────────────────────────

  Future<void> _loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final readings = await _storage.getReadings(limit: 2000);
      final events = await _storage.getEvents(limit: 100);
      _readings.addAll(readings);
      _events.addAll(events);
    } catch (e) {
      debugPrint('[MonitoringProvider] Load history error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ── Record Readings ────────────────────────────────────────────────────────

  void recordReading({
    double? temperature,
    double? humidity,
    int? gasRawAdc,
    String? alertStatus,
    String? connectionStatus,
    int? samplingInterval,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
  }) {
    if (temperature != null) _pendingTemp = temperature;
    if (humidity != null) _pendingHumidity = humidity;
    if (gasRawAdc != null) _pendingGas = gasRawAdc;
    if (alertStatus != null) _pendingAlert = alertStatus;
    if (connectionStatus != null) _pendingConnection = connectionStatus;
    if (samplingInterval != null) _pendingInterval = samplingInterval;
    if (accelX != null) _pendingAx = accelX;
    if (accelY != null) _pendingAy = accelY;
    if (accelZ != null) _pendingAz = accelZ;
    if (gyroX != null) _pendingGx = gyroX;
    if (gyroY != null) _pendingGy = gyroY;
    if (gyroZ != null) _pendingGz = gyroZ;

    // 350ms debounce batches paired environmental & motion packets
    _readingFlushTimer?.cancel();
    _readingFlushTimer = Timer(const Duration(milliseconds: 350), _flushReading);

    notifyListeners();
  }

  void _flushReading() {
    if (_pendingTemp == null &&
        _pendingHumidity == null &&
        _pendingGas == null &&
        _pendingAx == null &&
        _pendingGx == null) {
      return;
    }

    final reading = SensorReading(
      timestamp: DateTime.now(),
      temperature: _pendingTemp,
      humidity: _pendingHumidity,
      gasRawAdc: _pendingGas,
      alertStatus: _pendingAlert ?? 'NORMAL',
      connectionStatus: _pendingConnection ?? 'Connected',
      samplingInterval: _pendingInterval ?? 2,
      accelX: _pendingAx,
      accelY: _pendingAy,
      accelZ: _pendingAz,
      gyroX: _pendingGx,
      gyroY: _pendingGy,
      gyroZ: _pendingGz,
    );

    _readings.add(reading);
    _totalSamplesReceived++;
    _monitoringStartedAt ??= DateTime.now();

    if (_readings.length > AppConstants.maxHistoryEntries) {
      _readings.removeRange(0, _readings.length - AppConstants.maxHistoryEntries);
    }

    if (!_isRecordingPaused) {
      _storage.insertReading(reading).catchError((e) {
        debugPrint('[MonitoringProvider] Insert reading error: $e');
        return -1;
      });
    }

    // Throttled event logging (max 1 reading event per minute in timeline)
    final lastReadingEvent = _events.firstWhere(
      (e) => e.type == MonitoringEventType.readingReceived,
      orElse: () => MonitoringEvent(
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
        type: MonitoringEventType.readingReceived,
        message: '',
      ),
    );

    if (DateTime.now().difference(lastReadingEvent.timestamp).inMinutes >= 1) {
      final parts = <String>[];
      if (_pendingTemp != null) parts.add('T: ${_pendingTemp!.toStringAsFixed(1)}°C');
      if (_pendingHumidity != null) parts.add('H: ${_pendingHumidity!.toStringAsFixed(1)}%');
      if (_pendingGas != null) parts.add('Gas: $_pendingGas ADC');
      if (_pendingAx != null) parts.add('Motion active');

      final event = MonitoringEvent(
        timestamp: DateTime.now(),
        type: MonitoringEventType.readingReceived,
        message: 'Telemetry packet received',
        detail: parts.join(', '),
      );
      _insertEvent(event);
    }

    _pendingTemp = null;
    _pendingHumidity = null;
    _pendingGas = null;
    _pendingAx = null;
    _pendingAy = null;
    _pendingAz = null;
    _pendingGx = null;
    _pendingGy = null;
    _pendingGz = null;
    notifyListeners();
  }

  // ── Events ─────────────────────────────────────────────────────────────────

  void addEvent(MonitoringEvent event) {
    _insertEvent(event);
    notifyListeners();
  }

  void _insertEvent(MonitoringEvent event) {
    _events.insert(0, event);
    if (_events.length > AppConstants.maxEventEntries) {
      _events.removeLast();
    }
    _storage.insertEvent(event).catchError((e) {
      debugPrint('[MonitoringProvider] Insert event error: $e');
      return -1;
    });
  }

  // ── Clear History ──────────────────────────────────────────────────────────

  Future<void> clearHistory() async {
    _readings.clear();
    _events.clear();
    await _storage.clearAll();
    _totalSamplesReceived = 0;
    _monitoringStartedAt = null;
    notifyListeners();
  }
}
