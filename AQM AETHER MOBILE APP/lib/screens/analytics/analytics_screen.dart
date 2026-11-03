// AQM AETHER — Analytics & Statistical Intelligence
// Clean Modern Industrial White Interface

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/sensor_reading.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/export_csv_button.dart';

enum AnalyticsRange {
  today('Today'),
  last24Hours('24 Hours'),
  last7Days('7 Days');

  final String label;
  const AnalyticsRange(this.label);
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsRange _selectedRange = AnalyticsRange.today;
  bool _isExporting = false;

  List<SensorReading> _getFilteredReadings(MonitoringProvider provider) {
    switch (_selectedRange) {
      case AnalyticsRange.today:
        final now = DateTime.now();
        final startOfDay = DateTime(now.year, now.month, now.day);
        return provider.readings
            .where((r) => r.timestamp.isAfter(startOfDay))
            .toList();
      case AnalyticsRange.last24Hours:
        return provider.readingsLast24Hours;
      case AnalyticsRange.last7Days:
        return provider.readingsLast7Days;
    }
  }

  Future<void> _handleExportCsv(
      BuildContext context, MonitoringProvider provider) async {
    setState(() => _isExporting = true);
    try {
      final success = await provider.exportCsv();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.info_outline,
                  color: success ? AppColors.success : AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  success
                      ? 'CSV telemetry exported successfully'
                      : 'No telemetry records to export',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer<MonitoringProvider>(
          builder: (context, monitoringProvider, _) {
            final readings = _getFilteredReadings(monitoringProvider);

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── Header & CSV Export Action ───────────────────────────────
                _buildHeader(context, monitoringProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Date Range Selector ──────────────────────────────────────
                _buildRangeSelector(),

                const SizedBox(height: AppSpacing.base),

                // ── Statistical KPI Cards ────────────────────────────────────
                _buildKpiMetrics(readings),

                const SizedBox(height: AppSpacing.base),

                // ── Regression & Trend Analysis ──────────────────────────────
                _buildTrendAnalysis(readings),

                const SizedBox(height: AppSpacing.base),

                // ── Smart Insights Card ──────────────────────────────────────
                _buildSmartInsights(monitoringProvider),

                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MonitoringProvider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYTICS',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Environmental statistics & trends',
                style: TextStyle(
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
        // Export CSV Button
        ExportCsvButton(
          isExporting: _isExporting,
          onPressed: () => _handleExportCsv(context, provider),
        ),
      ],
    );
  }

  Widget _buildRangeSelector() {
    return Row(
      children: AnalyticsRange.values.map((range) {
        final isSelected = _selectedRange == range;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => setState(() => _selectedRange = range),
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentAnalytics
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: isSelected ? AppShadows.card : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.accentAnalytics
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiMetrics(List<SensorReading> readings) {
    if (readings.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.bar_chart_rounded,
                size: 40, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'No Historical Data in Range',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect to the ESP32 to gather environmental telemetry samples.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    double? minTemp, maxTemp, sumTemp = 0;
    int countTemp = 0;
    double? minHum, maxHum, sumHum = 0;
    int countHum = 0;

    for (final r in readings) {
      if (r.temperature != null) {
        minTemp = (minTemp == null)
            ? r.temperature!
            : (r.temperature! < minTemp ? r.temperature! : minTemp);
        maxTemp = (maxTemp == null)
            ? r.temperature!
            : (r.temperature! > maxTemp ? r.temperature! : maxTemp);
        sumTemp = sumTemp! + r.temperature!;
        countTemp++;
      }
      if (r.humidity != null) {
        minHum = (minHum == null)
            ? r.humidity!
            : (r.humidity! < minHum ? r.humidity! : minHum);
        maxHum = (maxHum == null)
            ? r.humidity!
            : (r.humidity! > maxHum ? r.humidity! : maxHum);
        sumHum = sumHum! + r.humidity!;
        countHum++;
      }
    }

    final avgTemp =
        countTemp > 0 ? (sumTemp! / countTemp).toStringAsFixed(1) : '—';
    final avgHum = countHum > 0 ? (sumHum! / countHum).toStringAsFixed(1) : '—';

    // Data availability % (estimated vs expected samples at 2s interval)
    final firstTime = readings.first.timestamp;
    final lastTime = readings.last.timestamp;
    final durationSeconds = lastTime.difference(firstTime).inSeconds.abs();
    final expectedSamples =
        durationSeconds > 0 ? (durationSeconds / 2.0).ceil() : readings.length;
    final availability = expectedSamples > 0
        ? ((readings.length / expectedSamples) * 100)
            .clamp(0.0, 100.0)
            .toStringAsFixed(0)
        : '100';

    return Column(
      children: [
        // Temperature summary
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentTemperatureLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.thermostat_rounded,
                        size: 16, color: AppColors.accentTemperature),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'TEMPERATURE SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatTile(
                      'MIN', '${minTemp?.toStringAsFixed(1) ?? "—"}°C'),
                  _buildStatTile('MEAN', '$avgTemp°C', isPrimary: true),
                  _buildStatTile(
                      'MAX', '${maxTemp?.toStringAsFixed(1) ?? "—"}°C'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Humidity summary
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentHumidityLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        size: 16, color: AppColors.accentHumidity),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'HUMIDITY SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatTile(
                      'MIN', '${minHum?.toStringAsFixed(1) ?? "—"}%'),
                  _buildStatTile('MEAN', '$avgHum%', isPrimary: true),
                  _buildStatTile(
                      'MAX', '${maxHum?.toStringAsFixed(1) ?? "—"}%'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Dataset reliability stats
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL SAMPLES', style: _metricLabelStyle),
                    const SizedBox(height: 4),
                    Text(
                      '${readings.length}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DATA AVAILABILITY', style: _metricLabelStyle),
                    const SizedBox(height: 4),
                    Text(
                      '$availability%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Alert Count & Monitoring Duration stats
        Row(
          children: [
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALERT COUNT', style: _metricLabelStyle),
                    const SizedBox(height: 4),
                    Consumer<ThresholdService>(
                      builder: (_, thresh, __) {
                        final alertCount = readings.where((r) {
                          final t = r.temperature ?? 0;
                          final h = r.humidity ?? 0;
                          return t >= thresh.temperatureThreshold || h >= thresh.humidityThreshold;
                        }).length;

                        return Text(
                          '$alertCount',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: alertCount > 0 ? AppColors.critical : AppColors.normal,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MONITORING SPAN', style: _metricLabelStyle),
                    const SizedBox(height: 4),
                    Text(
                      readings.length >= 2
                          ? AppUtils.formatDuration(readings.last.timestamp.difference(readings.first.timestamp))
                          : '—',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendAnalysis(List<SensorReading> readings) {
    if (readings.length < 5) return const SizedBox.shrink();

    // Simple linear regression slope calculation
    // Slope = (N*sum(xy) - sum(x)*sum(y)) / (N*sum(x^2) - (sum(x))^2)
    final n = readings.length;
    double sumX = 0, sumYTemp = 0, sumYHum = 0;
    double sumXYTemp = 0, sumXYHum = 0;
    double sumX2 = 0;

    for (int i = 0; i < n; i++) {
      final x = i.toDouble();
      final temp = readings[i].temperature ?? 0;
      final hum = readings[i].humidity ?? 0;

      sumX += x;
      sumX2 += x * x;
      sumYTemp += temp;
      sumYHum += hum;
      sumXYTemp += x * temp;
      sumXYHum += x * hum;
    }

    final denom = (n * sumX2 - sumX * sumX);
    final slopeTemp =
        denom != 0 ? (n * sumXYTemp - sumX * sumYTemp) / denom : 0.0;
    final slopeHum = denom != 0 ? (n * sumXYHum - sumX * sumYHum) / denom : 0.0;

    final tempTrendText = slopeTemp.abs() < 0.01
        ? 'Stable thermal equilibrium'
        : (slopeTemp > 0
            ? 'Warming trend (+${(slopeTemp * 60).toStringAsFixed(2)}°C/min)'
            : 'Cooling trend (${(slopeTemp * 60).toStringAsFixed(2)}°C/min)');

    final humTrendText = slopeHum.abs() < 0.02
        ? 'Steady relative humidity'
        : (slopeHum > 0
            ? 'Humidifying trend (+${(slopeHum * 60).toStringAsFixed(2)}%/min)'
            : 'Dehumidifying trend (${(slopeHum * 60).toStringAsFixed(2)}%/min)');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentAnalyticsLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.trending_up_rounded,
                    size: 16, color: AppColors.accentAnalytics),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'REGRESSION & TREND ANALYSIS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTrendRow(
            label: 'Thermal Trajectory',
            desc: tempTrendText,
            color: AppColors.accentTemperature,
            icon: slopeTemp > 0
                ? Icons.north_east_rounded
                : (slopeTemp < 0
                    ? Icons.south_east_rounded
                    : Icons.east_rounded),
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildTrendRow(
            label: 'Moisture Trajectory',
            desc: humTrendText,
            color: AppColors.accentHumidity,
            icon: slopeHum > 0
                ? Icons.north_east_rounded
                : (slopeHum < 0
                    ? Icons.south_east_rounded
                    : Icons.east_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendRow({
    required String label,
    required String desc,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsights(MonitoringProvider provider) {
    final insights = provider.smartInsights;

    return AppCard(
      borderColor: AppColors.accentAnalytics.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentAnalyticsLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.psychology_rounded,
                    size: 16, color: AppColors.accentAnalytics),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'SYSTEM TELEMETRY INSIGHTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle,
                        size: 5, color: AppColors.accentAnalytics),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, {bool isPrimary = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isPrimary ? AppColors.accentAnalytics : AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrimary ? 18 : 15,
            fontWeight: FontWeight.w600,
            color:
                isPrimary ? AppColors.accentAnalytics : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  static const _metricLabelStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );
}
