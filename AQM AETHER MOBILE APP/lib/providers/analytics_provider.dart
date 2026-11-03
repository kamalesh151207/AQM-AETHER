// AQM AETHER — Analytics Provider
// Computes real statistical KPI metrics (Min, Max, Avg, Trend) for Temp, Humidity, and Gas ADC

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
  SensorStats? _gasStats;

  AnalyticsProvider(this._monitoring) {
    _compute();
  }

  void updateFromMonitoring(MonitoringProvider monitoring) {
    _monitoring = monitoring;
    _compute();
  }

  SensorStats? get temperatureStats => _temperatureStats;
  SensorStats? get humidityStats => _humidityStats;
  SensorStats? get gasStats => _gasStats;

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
      _gasStats = null;
      notifyListeners();
      return;
    }

    final totalCount = readings.length;

    // 1. Temperature Statistics
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

    // 2. Humidity Statistics
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

    // 3. MQ-2 / MQ-135 Gas RAW ADC Statistics
    final gasReadings = readings
        .where((r) => r.gasRawAdc != null)
        .map((r) => r.gasRawAdc!.toDouble())
        .toList();

    if (gasReadings.isNotEmpty) {
      _gasStats = SensorStats(
        min: gasReadings.reduce((a, b) => a < b ? a : b),
        max: gasReadings.reduce((a, b) => a > b ? a : b),
        average: gasReadings.reduce((a, b) => a + b) / gasReadings.length,
        count: gasReadings.length,
        availabilityPercent: (gasReadings.length / totalCount) * 100,
        trend: _computeTrend(gasReadings),
      );
    } else {
      _gasStats = null;
    }

    notifyListeners();
  }

  SensorStats? computeStatsForValues(List<double> values, int totalCount) {
    if (values.isEmpty) return null;
    return SensorStats(
      min: values.reduce((a, b) => a < b ? a : b),
      max: values.reduce((a, b) => a > b ? a : b),
      average: values.reduce((a, b) => a + b) / values.length,
      count: values.length,
      availabilityPercent: (values.length / totalCount) * 100,
      trend: _computeTrend(values),
    );
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

    final denominator = (n * sumX2 - sumX * sumX);
    if (denominator == 0) return TrendDirection.stable;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    final range = (recent.reduce((a, b) => a > b ? a : b) -
        recent.reduce((a, b) => a < b ? a : b));

    final threshold = range > 0 ? range * 0.005 : 0.05;

    if (slope > threshold) return TrendDirection.increasing;
    if (slope < -threshold) return TrendDirection.decreasing;
    return TrendDirection.stable;
  }

  void refresh() {
    _compute();
  }
}
