// AQM AETHER — Analytics Provider
// Computes statistics and trends from actual sensor readings

import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';
import 'monitoring_provider.dart';

enum TrendDirection { increasing, decreasing, stable, insufficient }

extension TrendDirectionExtension on TrendDirection {
  String get label {
    switch (this) {
      case TrendDirection.increasing:
        return 'Increasing ↑';
      case TrendDirection.decreasing:
        return 'Decreasing ↓';
      case TrendDirection.stable:
        return 'Stable —';
      case TrendDirection.insufficient:
        return 'Insufficient Data';
    }
  }
}

class SensorStats {
  final double min;
  final double max;
  final double average;
  final int count;
  final double availabilityPercent;
  final TrendDirection trend;

  const SensorStats({
    required this.min,
    required this.max,
    required this.average,
    required this.count,
    required this.availabilityPercent,
    required this.trend,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  MonitoringProvider _monitoring;

  SensorStats? _temperatureStats;
  SensorStats? _humidityStats;

  AnalyticsProvider(this._monitoring) {
    _compute();
  }

  void updateFromMonitoring(MonitoringProvider monitoring) {
    _monitoring = monitoring;
    _compute();
  }

  SensorStats? get temperatureStats => _temperatureStats;
  SensorStats? get humidityStats => _humidityStats;

  List<SensorReading> get allReadings => _monitoring.readings;

  List<SensorReading> readingsForDuration(Duration duration) {
    final from = DateTime.now().subtract(duration);
    return _monitoring.readings
        .where((r) => r.timestamp.isAfter(from))
        .toList();
  }

  void _compute() {
    final readings = _monitoring.readings;
    if (readings.isEmpty) {
      _temperatureStats = null;
      _humidityStats = null;
      notifyListeners();
      return;
    }

    final totalCount = readings.length;

    // Temperature
    final tempReadings = readings
        .where((r) => r.temperature != null)
        .map((r) => r.temperature!)
        .toList();

    if (tempReadings.isNotEmpty) {
      _temperatureStats = SensorStats(
        min: tempReadings.reduce((a, b) => a < b ? a : b),
        max: tempReadings.reduce((a, b) => a > b ? a : b),
        average: tempReadings.reduce((a, b) => a + b) / tempReadings.length,
        count: tempReadings.length,
        availabilityPercent: (tempReadings.length / totalCount) * 100,
        trend: _computeTrend(tempReadings),
      );
    } else {
      _temperatureStats = null;
    }

    // Humidity
    final humReadings = readings
        .where((r) => r.humidity != null)
        .map((r) => r.humidity!)
        .toList();

    if (humReadings.isNotEmpty) {
      _humidityStats = SensorStats(
        min: humReadings.reduce((a, b) => a < b ? a : b),
        max: humReadings.reduce((a, b) => a > b ? a : b),
        average: humReadings.reduce((a, b) => a + b) / humReadings.length,
        count: humReadings.length,
        availabilityPercent: (humReadings.length / totalCount) * 100,
        trend: _computeTrend(humReadings),
      );
    } else {
      _humidityStats = null;
    }

    notifyListeners();
  }

  TrendDirection _computeTrend(List<double> values) {
    if (values.length < 5) return TrendDirection.insufficient;

    // Use last 20 values for trend analysis
    final recent = values.length > 20 ? values.sublist(values.length - 20) : values;
    final n = recent.length.toDouble();

    // Linear regression slope
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < recent.length; i++) {
      sumX += i;
      sumY += recent[i];
      sumXY += i * recent[i];
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final range = (recent.reduce((a, b) => a > b ? a : b) -
        recent.reduce((a, b) => a < b ? a : b));

    // Relative threshold: 10% of range per step
    final threshold = range > 0 ? range * 0.005 : 0.05;

    if (slope > threshold) return TrendDirection.increasing;
    if (slope < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  void refresh() {
    _compute();
  }
}

