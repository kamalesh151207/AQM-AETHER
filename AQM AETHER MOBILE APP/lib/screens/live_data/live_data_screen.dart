// AQM AETHER — Live Telemetry & Real-Time Monitoring
// Clean Modern Industrial White Interface

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/sensor_reading.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/data_quality_badge.dart';

enum TimeRangeWindow {
  oneMinute('1m', '1 Minute', Duration(minutes: 1)),
  fiveMinutes('5m', '5 Minutes', Duration(minutes: 5)),
  fifteenMinutes('15m', '15 Minutes', Duration(minutes: 15)),
  oneHour('1h', '1 Hour', Duration(hours: 1));

  final String label;
  final String title;
  final Duration duration;
  const TimeRangeWindow(this.label, this.title, this.duration);
}

enum MetricFocus {
  both('Combined'),
  temperature('Temperature (°C)'),
  humidity('Humidity (%)');

  final String label;
  const MetricFocus(this.label);
}

class LiveDataScreen extends StatefulWidget {
  const LiveDataScreen({super.key});

  @override
  State<LiveDataScreen> createState() => _LiveDataScreenState();
}

class _LiveDataScreenState extends State<LiveDataScreen> {
  TimeRangeWindow _selectedWindow = TimeRangeWindow.fiveMinutes;
  MetricFocus _metricFocus = MetricFocus.both;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every second so the live time and chart x-axis step smoothly
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  List<SensorReading> _getWindowReadings(MonitoringProvider provider) {
    switch (_selectedWindow) {
      case TimeRangeWindow.oneMinute:
        return provider.readingsLast1Minute;
      case TimeRangeWindow.fiveMinutes:
        return provider.readingsLast5Minutes;
      case TimeRangeWindow.fifteenMinutes:
        return provider.readingsLast15Minutes;
      case TimeRangeWindow.oneHour:
        return provider.readingsLast1Hour;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer3<DeviceProvider, MonitoringProvider, ThresholdService>(
          builder: (context, deviceProvider, monitoringProvider, thresholdService, _) {
            final isConnected = deviceProvider.isConnected;
            final isPaused = monitoringProvider.isRecordingPaused;
            final windowReadings = _getWindowReadings(monitoringProvider);

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── Header ───────────────────────────────────────────────────
                _buildHeader(deviceProvider, monitoringProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Live Metric Cards ────────────────────────────────────────
                _buildMetricCards(deviceProvider, windowReadings, thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Controls: Time Window & Metric Selection ─────────────────
                _buildControlBar(),

                const SizedBox(height: AppSpacing.md),

                // ── Main Chart Card ──────────────────────────────────────────
                _buildChartCard(windowReadings, isConnected, isPaused, thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Telemetry Window Statistics ──────────────────────────────
                _buildWindowStats(windowReadings),

                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
  ) {
    final isPaused = monitoringProvider.isRecordingPaused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE TELEMETRY',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'High-frequency BLE sensor streams',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Row(
          children: [
            // Pause / Resume Button
            InkWell(
              onTap: () => monitoringProvider.toggleRecordingPause(),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPaused
                      ? AppColors.warningLight
                      : AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isPaused ? AppColors.warning : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 16,
                      color: isPaused
                          ? AppColors.warning
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPaused ? 'RESUME' : 'PAUSE',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: isPaused
                            ? AppColors.warning
                            : AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            DataQualityBadge(quality: deviceProvider.dataQuality),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCards(
    DeviceProvider deviceProvider,
    List<SensorReading> windowReadings,
    ThresholdService thresholdService,
  ) {
    final temp = deviceProvider.temperature;
    final hum = deviceProvider.humidity;
    final isTempCrit = temp != null && temp >= thresholdService.temperatureThreshold;
    final isHumCrit = hum != null && hum >= thresholdService.humidityThreshold;

    // Calculate window min/max
    double? minTemp, maxTemp, minHum, maxHum;
    for (final r in windowReadings) {
      if (r.temperature != null) {
        minTemp = (minTemp == null)
            ? r.temperature!
            : (r.temperature! < minTemp ? r.temperature! : minTemp);
        maxTemp = (maxTemp == null)
            ? r.temperature!
            : (r.temperature! > maxTemp ? r.temperature! : maxTemp);
      }
      if (r.humidity != null) {
        minHum = (minHum == null)
            ? r.humidity!
            : (r.humidity! < minHum ? r.humidity! : minHum);
        maxHum = (maxHum == null)
            ? r.humidity!
            : (r.humidity! > maxHum ? r.humidity! : maxHum);
      }
    }

    return Row(
      children: [
        // Temperature Hero
        Expanded(
          child: AppCard(
            borderColor: isTempCrit ? AppColors.critical.withOpacity(0.5) : AppColors.border,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TEMPERATURE',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(
                      Icons.thermostat_rounded,
                      size: 16,
                      color: isTempCrit ? AppColors.critical : AppColors.accentTemperature,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      temp != null ? AppUtils.formatTemperature(temp) : '—',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isTempCrit ? AppColors.critical : AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '°C',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isTempCrit ? AppColors.critical : AppColors.accentTemperature,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        minTemp != null && maxTemp != null
                            ? 'L: ${minTemp.toStringAsFixed(1)}° | H: ${maxTemp.toStringAsFixed(1)}°'
                            : 'Awaiting data',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isTempCrit ? AppColors.criticalLight : AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '≤${thresholdService.temperatureThreshold}°C',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isTempCrit ? AppColors.critical : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Humidity Hero
        Expanded(
          child: AppCard(
            borderColor: isHumCrit ? AppColors.critical.withOpacity(0.5) : AppColors.border,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HUMIDITY',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(
                      Icons.water_drop_rounded,
                      size: 16,
                      color: isHumCrit ? AppColors.critical : AppColors.accentHumidity,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hum != null ? AppUtils.formatHumidity(hum) : '—',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isHumCrit ? AppColors.critical : AppColors.textPrimary,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '%',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHumCrit ? AppColors.critical : AppColors.accentHumidity,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        minHum != null && maxHum != null
                            ? 'L: ${minHum.toStringAsFixed(1)}% | H: ${maxHum.toStringAsFixed(1)}%'
                            : 'Awaiting data',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isHumCrit ? AppColors.criticalLight : AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '≤${thresholdService.humidityThreshold}%',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: isHumCrit ? AppColors.critical : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlBar() {
    return Column(
      children: [
        // Time window pills
        Row(
          children: TimeRangeWindow.values.map((w) {
            final isSelected = _selectedWindow == w;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => setState(() => _selectedWindow = w),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accentSecondary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected ? AppShadows.card : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      w.label,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.accentSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Metric selector
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: MetricFocus.values.map((m) {
            final isSelected = _metricFocus == m;
            Color dotColor = AppColors.accentSecondary;
            if (m == MetricFocus.temperature) dotColor = AppColors.accentTemperature;
            if (m == MetricFocus.humidity) dotColor = AppColors.accentHumidity;

            return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (m != MetricFocus.both) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(m.label),
                  ],
                ),
                selected: isSelected,
                onSelected: (_) => setState(() => _metricFocus = m),
                selectedColor: AppColors.cardBackground,
                backgroundColor: AppColors.backgroundPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  side: BorderSide(
                    color: isSelected ? dotColor : AppColors.border,
                  ),
                ),
                labelStyle: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildChartCard(
    List<SensorReading> windowReadings,
    bool isConnected,
    bool isPaused,
    ThresholdService thresholdService,
  ) {
    if (windowReadings.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(
              Icons.query_stats_rounded,
              size: 48,
              color: AppColors.textMuted.withOpacity(0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              isConnected
                  ? 'Awaiting Sensor Telemetry…'
                  : 'ESP32 Device Disconnected',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isConnected
                  ? 'Incoming samples will appear here dynamically in real-time.'
                  : 'Connect to AQM-Kamalesh from Overview or Command Center to start live stream.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Build spots
    final now = DateTime.now();
    final windowStart = now.subtract(_selectedWindow.duration);

    final tempSpots = <FlSpot>[];
    final humSpots = <FlSpot>[];

    for (final r in windowReadings) {
      final secondsFromStart =
          r.timestamp.difference(windowStart).inMilliseconds / 1000.0;
      if (r.temperature != null) {
        tempSpots.add(FlSpot(secondsFromStart, r.temperature!));
      }
      if (r.humidity != null) {
        humSpots.add(FlSpot(secondsFromStart, r.humidity!));
      }
    }

    final maxX = _selectedWindow.duration.inSeconds.toDouble();

    final lines = <LineChartBarData>[];

    if (_metricFocus == MetricFocus.both ||
        _metricFocus == MetricFocus.temperature) {
      if (tempSpots.isNotEmpty) {
        lines.add(
          LineChartBarData(
            spots: tempSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.accentTemperature,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: _metricFocus == MetricFocus.temperature,
              color: AppColors.accentTemperatureLight.withOpacity(0.3),
            ),
          ),
        );
      }
    }

    if (_metricFocus == MetricFocus.both ||
        _metricFocus == MetricFocus.humidity) {
      if (humSpots.isNotEmpty) {
        lines.add(
          LineChartBarData(
            spots: humSpots,
            isCurved: true,
            curveSmoothness: 0.2,
            color: AppColors.accentHumidity,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: _metricFocus == MetricFocus.humidity,
              color: AppColors.accentHumidityLight.withOpacity(0.3),
            ),
          ),
        );
      }
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'TELEMETRY STREAM',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isPaused) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warningLight,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: const Text(
                          'PAUSED',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Window: ${_selectedWindow.title}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: AppColors.borderSubtle,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: maxX / 4,
                      getTitlesWidget: (value, meta) {
                        final remainingSecs = (maxX - value).round();
                        if (remainingSecs <= 0) return const Text('Now', style: _axisStyle);
                        return Text('-${remainingSecs}s', style: _axisStyle);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                minX: 0,
                maxX: maxX,
                minY: 10,
                maxY: 80,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (_metricFocus == MetricFocus.both || _metricFocus == MetricFocus.temperature)
                      HorizontalLine(
                        y: thresholdService.temperatureThreshold,
                        color: AppColors.accentTemperature.withOpacity(0.85),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6, bottom: 2),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentTemperature,
                          ),
                          labelResolver: (_) => 'T-Limit: ${thresholdService.temperatureThreshold}°C',
                        ),
                      ),
                    if (_metricFocus == MetricFocus.both || _metricFocus == MetricFocus.humidity)
                      HorizontalLine(
                        y: thresholdService.humidityThreshold,
                        color: AppColors.accentHumidity.withOpacity(0.85),
                        strokeWidth: 1.5,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 6, bottom: 2),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accentHumidity,
                          ),
                          labelResolver: (_) => 'H-Limit: ${thresholdService.humidityThreshold}%',
                        ),
                      ),
                  ],
                ),
                lineBarsData: lines,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isTemp = spot.bar.color == AppColors.accentTemperature;
                        return LineTooltipItem(
                          '${isTemp ? "Temp" : "Hum"}: ${spot.y.toStringAsFixed(1)}${isTemp ? "°C" : "%"}',
                          TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: spot.bar.color,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Legend
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: 4,
            children: [
              _buildLegendItem('Temp (°C)', AppColors.accentTemperature),
              _buildLegendItem('Hum (%)', AppColors.accentHumidity),
              _buildLegendItem('Limits (- -)', AppColors.critical),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWindowStats(List<SensorReading> windowReadings) {
    if (windowReadings.isEmpty) return const SizedBox.shrink();

    double sumTemp = 0;
    int countTemp = 0;
    double sumHum = 0;
    int countHum = 0;

    for (final r in windowReadings) {
      if (r.temperature != null) {
        sumTemp += r.temperature!;
        countTemp++;
      }
      if (r.humidity != null) {
        sumHum += r.humidity!;
        countHum++;
      }
    }

    final avgTemp = countTemp > 0 ? (sumTemp / countTemp).toStringAsFixed(1) : '—';
    final avgHum = countHum > 0 ? (sumHum / countHum).toStringAsFixed(1) : '—';

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WINDOW TELEMETRY SUMMARY',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _buildStatItem('Window Points', '${windowReadings.length}')),
              Expanded(child: _buildStatItem('Avg Temp', '$avgTemp °C')),
              Expanded(child: _buildStatItem('Avg Hum', '$avgHum %')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  static const _axisStyle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 10,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
  );
}
