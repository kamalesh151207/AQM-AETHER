// AQM AETHER — Environmental Telemetry Dashboard
// Temperature, Humidity, and MQ-135 Gas Sensor RAW 12-bit ADC Integration

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/export_csv_button.dart';

enum EnvironmentalMetric { temperature, humidity, gasAdc }

class EnvironmentScreen extends StatefulWidget {
  const EnvironmentScreen({super.key});

  @override
  State<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends State<EnvironmentScreen> {
  EnvironmentalMetric _selectedMetric = EnvironmentalMetric.temperature;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<DeviceProvider, MonitoringProvider, ThresholdService>(
      builder: (context, deviceProv, monProv, threshServ, _) {
        final temp = deviceProv.temperature;
        final hum = deviceProv.humidity;
        final gasAdc = deviceProv.gasRawAdc;
        final isConnected = deviceProv.isConnected;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundPrimary,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.eco_rounded,
                      color: AppColors.accentPrimary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Flexible(
                  child: Text(
                    'ENVIRONMENT',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  child: ExportCsvButton(
                    isExporting: _isExporting,
                    onPressed: () => _handleCsvExport(context, monProv),
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              // 1. Data Freshness Bar
              _buildFreshnessBar(deviceProv),
              const SizedBox(height: AppSpacing.md),

              // 2. Temperature & Humidity Primary Cards (Side-by-Side)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTempCard(
                      context,
                      temp: temp,
                      threshold: threshServ.temperatureThreshold,
                      isStale: deviceProv.isTemperatureStale,
                      isConnected: isConnected,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildHumidityCard(
                      context,
                      humidity: hum,
                      threshold: threshServ.humidityThreshold,
                      isStale: deviceProv.isHumidityStale,
                      isConnected: isConnected,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. MQ-135 Gas Sensor Card (Raw 12-bit ADC)
              _buildGasCard(
                context,
                gasAdc: gasAdc,
                isConnected: isConnected,
                gasCharFound: deviceProv.device.gasCharFound,
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. Interactive Trend Chart
              _buildChartCard(context, monProv),
              const SizedBox(height: AppSpacing.md),

              // 5. Environmental Calibration Notice
              _buildCalibrationNotice(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  // ── Freshness Bar ──────────────────────────────────────────────────────────

  Widget _buildFreshnessBar(DeviceProvider provider) {
    final quality = provider.dataQuality;
    final color = AppUtils.dataQualityColor(quality);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'DATA FEED: ${quality.label}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (provider.lastTempUpdate != null)
            Text(
              'Updated: ${AppUtils.formatRelativeTime(provider.lastTempUpdate!)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }

  // ── Temperature Card ───────────────────────────────────────────────────────

  Widget _buildTempCard(
    BuildContext context, {
    required double? temp,
    required double threshold,
    required bool isStale,
    required bool isConnected,
  }) {
    final isBreached = temp != null && temp > threshold;
    final displayColor = isBreached
        ? AppColors.critical
        : (temp != null ? AppUtils.temperatureColor(temp) : AppColors.textMuted);

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TEMPERATURE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.thermostat_rounded, size: 16, color: displayColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temp != null ? AppUtils.formatTemperature(temp) : '--',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: displayColor,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '°C',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Limit: ${threshold.toStringAsFixed(1)}°C',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isBreached ? AppColors.critical : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Humidity Card ──────────────────────────────────────────────────────────

  Widget _buildHumidityCard(
    BuildContext context, {
    required double? humidity,
    required double threshold,
    required bool isStale,
    required bool isConnected,
  }) {
    final isBreached = humidity != null && humidity > threshold;
    final displayColor = isBreached
        ? AppColors.critical
        : (humidity != null ? AppUtils.humidityColor(humidity) : AppColors.textMuted);

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HUMIDITY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(Icons.water_drop_rounded, size: 16, color: displayColor),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                humidity != null ? AppUtils.formatHumidity(humidity) : '--',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: displayColor,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Limit: ${threshold.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isBreached ? AppColors.critical : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── MQ-135 Gas Card (Raw 12-bit ADC) ───────────────────────────────────────

  Widget _buildGasCard(
    BuildContext context, {
    required int? gasAdc,
    required bool isConnected,
    required bool gasCharFound,
  }) {
    final double fraction = gasAdc != null ? (gasAdc / 4095.0).clamp(0.0, 1.0) : 0.0;
    Color gasColor = AppColors.normal;
    if (gasAdc != null) {
      if (gasAdc > 2800) {
        gasColor = AppColors.critical;
      } else if (gasAdc > 1800) {
        gasColor = AppColors.warning;
      }
    }

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.cloud_outlined,
                    color: AppColors.accentSecondary, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GAS SENSOR (RAW ADC)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'MQ-2 / MQ-135 Sensor • ESP32 ADC1_CH6 (GPIO 34)',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!gasCharFound && isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'CHAR NOT FOUND',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                gasAdc != null ? '$gasAdc' : '--',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: gasColor,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ 4095 (12-bit Counts)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Linear ADC Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(gasColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0 (Clean Air Base)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                '${(fraction * 100).toStringAsFixed(1)}% Full-Scale',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: gasColor,
                ),
              ),
              const Text(
                '4095 (Max Saturation)',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 9,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chart Card ─────────────────────────────────────────────────────────────

  Widget _buildChartCard(BuildContext context, MonitoringProvider monProv) {
    final readings = monProv.readingsLast15Minutes;

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'LIVE TELEMETRY STREAM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildMetricChip(EnvironmentalMetric.temperature, 'TEMP'),
                    _buildMetricChip(EnvironmentalMetric.humidity, 'HUM'),
                    _buildMetricChip(EnvironmentalMetric.gasAdc, 'GAS ADC'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: readings.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting sensor telemetry packets…',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  )
                : LineChart(_buildChartData(readings)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(EnvironmentalMetric metric, String label) {
    final isSelected = _selectedMetric == metric;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMetric = metric);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm - 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  LineChartData _buildChartData(List<dynamic> readings) {
    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      double? val;
      if (_selectedMetric == EnvironmentalMetric.temperature) {
        val = r.temperature;
      } else if (_selectedMetric == EnvironmentalMetric.humidity) {
        val = r.humidity;
      } else {
        val = r.gasRawAdc?.toDouble();
      }
      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    Color lineColor = AppColors.accentTemperature;
    if (_selectedMetric == EnvironmentalMetric.humidity) {
      lineColor = AppColors.accentHumidity;
    } else if (_selectedMetric == EnvironmentalMetric.gasAdc) {
      lineColor = AppColors.accentSecondary;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => const FlLine(
          color: AppColors.borderSubtle,
          strokeWidth: 1,
        ),
      ),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
          isCurved: true,
          color: lineColor,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: lineColor.withOpacity(0.08),
          ),
        ),
      ],
    );
  }

  // ── Calibration Disclaimer ─────────────────────────────────────────────────

  Widget _buildCalibrationNotice() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.secondary),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Sensor note: MQ-2 / MQ-135 values are raw 12-bit ADC counts (0–4095). Readings reflect analog conductivity and do not represent calibrated ppm or AQI.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CSV Export ─────────────────────────────────────────────────────────────

  Future<void> _handleCsvExport(
      BuildContext context, MonitoringProvider monProv) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();
    final ok = await monProv.exportCsv();
    if (!mounted) return;
    setState(() => _isExporting = false);
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ok ? AppColors.navyPrimary : AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        content: Row(
          children: [
            Icon(
              ok ? Icons.check_circle_rounded : Icons.info_outline_rounded,
              color: ok ? AppColors.success : AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                ok
                    ? 'Telemetry CSV exported successfully'
                    : 'No telemetry data to export',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
