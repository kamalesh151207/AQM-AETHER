// AQM AETHER — Sensor Chart Widget
// fl_chart LineChart for sensor history with empty state overlay

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/sensor_reading.dart';

class SensorChart extends StatefulWidget {
  final List<SensorReading> readings;
  final Duration timeRange;
  final Color lineColor;
  final String valueUnit;
  final bool isTemperature;

  const SensorChart({
    super.key,
    required this.readings,
    required this.timeRange,
    required this.lineColor,
    required this.valueUnit,
    this.isTemperature = true,
  });

  @override
  State<SensorChart> createState() => _SensorChartState();
}

class _SensorChartState extends State<SensorChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(SensorChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readings != widget.readings ||
        oldWidget.timeRange != widget.timeRange) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  List<SensorReading> _filterReadings(
      List<SensorReading> readings, Duration range) {
    final cutoff = DateTime.now().subtract(range);
    return readings
        .where((r) =>
            r.timestamp.isAfter(cutoff) &&
            (widget.isTemperature ? r.temperature != null : r.humidity != null))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  List<FlSpot> _toSpots(List<SensorReading> filtered) {
    if (filtered.isEmpty) return [];
    final startMs = filtered.first.timestamp.millisecondsSinceEpoch.toDouble();
    return filtered.map((r) {
      final x =
          (r.timestamp.millisecondsSinceEpoch.toDouble() - startMs) / 1000.0;
      final y = widget.isTemperature ? r.temperature! : r.humidity!;
      return FlSpot(x, y);
    }).toList();
  }

  String _formatAxisTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  List<DateTime> _pickLabelTimes(List<SensorReading> filtered, int count) {
    if (filtered.isEmpty) return [];
    if (filtered.length <= count) {
      return filtered.map((r) => r.timestamp).toList();
    }
    final step = (filtered.length - 1) / (count - 1);
    return List.generate(
      count,
      (i) => filtered[(i * step).round()].timestamp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterReadings(widget.readings, widget.timeRange);
    final spots = _toSpots(filtered);

    if (filtered.isEmpty) {
      return _EmptyChartState(lineColor: widget.lineColor);
    }

    final values = filtered
        .map((r) => widget.isTemperature ? r.temperature! : r.humidity!)
        .toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final padding = (maxVal - minVal) < 0.5 ? 1.0 : (maxVal - minVal) * 0.15;
    final yMin = (minVal - padding).floorToDouble();
    final yMax = (maxVal + padding).ceilToDouble();

    final labelTimes = _pickLabelTimes(filtered, 5);
    final startMs =
        filtered.first.timestamp.millisecondsSinceEpoch.toDouble();

    final showDots = filtered.length < 5;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return LineChart(
          LineChartData(
            clipData: const FlClipData.all(),
            minX: spots.first.x,
            maxX: spots.last.x,
            minY: yMin,
            maxY: yMax,
            backgroundColor: AppColors.panelBackground,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              drawHorizontalLine: true,
              horizontalInterval: ((yMax - yMin) / 4).clamp(0.1, 100),
              verticalInterval:
                  spots.last.x > 0 ? spots.last.x / 4 : 1,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.chartGrid,
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
              getDrawingVerticalLine: (_) => const FlLine(
                color: AppColors.chartGrid,
                strokeWidth: 1,
                dashArray: [4, 6],
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: AppColors.border.withOpacity(0.5),
                width: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: ((yMax - yMin) / 4).clamp(0.5, 50),
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (value, meta) {
                    // Find nearest label time
                    DateTime? match;
                    for (final lt in labelTimes) {
                      final ltX = (lt.millisecondsSinceEpoch.toDouble() -
                              startMs) /
                          1000.0;
                      if ((ltX - value).abs() < 0.01) {
                        match = lt;
                        break;
                      }
                    }
                    if (match == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _formatAxisTime(match),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
                      ),
                    );
                  },
                  // Only show at label positions
                  interval: spots.last.x > 0 ? spots.last.x / 4 : 1,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => AppColors.elevatedSurface,
                tooltipBorder: BorderSide(
                  color: widget.lineColor.withOpacity(0.4),
                  width: 1,
                ),
                tooltipRoundedRadius: AppRadius.md,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((ts) {
                    final idx = ts.spotIndex;
                    final reading = idx < filtered.length ? filtered[idx] : null;
                    final timeStr = reading != null
                        ? DateFormat('HH:mm:ss').format(reading.timestamp)
                        : '';
                    return LineTooltipItem(
                      '${ts.y.toStringAsFixed(1)} ${widget.valueUnit}\n',
                      TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.lineColor,
                      ),
                      children: [
                        TextSpan(
                          text: timeStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              handleBuiltInTouches: true,
              getTouchedSpotIndicator: (barData, indicators) {
                return indicators.map((idx) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: widget.lineColor.withOpacity(0.5),
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                    ),
                    FlDotData(
                      getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                        radius: 5,
                        color: widget.lineColor,
                        strokeWidth: 2,
                        strokeColor: AppColors.panelBackground,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: widget.lineColor,
                barWidth: 2.5,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: showDots,
                  getDotPainter: (spot, percent, bar, idx) =>
                      FlDotCirclePainter(
                    radius: 3.5,
                    color: widget.lineColor,
                    strokeWidth: 1.5,
                    strokeColor: AppColors.panelBackground,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      widget.lineColor.withOpacity(0.18 * _animation.value),
                      widget.lineColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
        );
      },
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  final Color lineColor;

  const _EmptyChartState({required this.lineColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 36,
              color: AppColors.textMuted.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No data recorded yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect to AQM-Kamalesh to begin monitoring',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
