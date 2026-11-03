// AQM AETHER — Analytics & Statistical Intelligence
// Comprehensive sensor analytics for Temperature, Humidity, and MQ-2 Gas Raw ADC

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sensor_reading.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/export_csv_button.dart';

enum AnalyticsRange {
  oneHour('1 Hour', Duration(hours: 1)),
  sixHours('6 Hours', Duration(hours: 6)),
  twentyFourHours('24 Hours', Duration(hours: 24)),
  sevenDays('7 Days', Duration(days: 7));

  final String label;
  final Duration duration;
  const AnalyticsRange(this.label, this.duration);
}

enum SelectedMetric {
  temperature('Temperature (°C)', AppColors.accentTemperature),
  humidity('Humidity (%)', AppColors.accentHumidity),
  gas('MQ-2 Raw ADC', AppColors.accentGas);

  final String title;
  final Color color;
  const SelectedMetric(this.title, this.color);
}

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsRange _selectedRange = AnalyticsRange.twentyFourHours;
  SelectedMetric _selectedMetric = SelectedMetric.temperature;
  bool _isExporting = false;

  List<SensorReading> _getFilteredReadings(MonitoringProvider provider) {
    final cutoff = DateTime.now().subtract(_selectedRange.duration);
    return provider.readings
        .where((r) => r.timestamp.isAfter(cutoff))
        .toList();
  }

  Future<void> _handleExportCsv(BuildContext context, MonitoringProvider provider) async {
    setState(() => _isExporting = true);
    try {
      final success = await provider.exportCsv();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.primary : AppColors.warning,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline,
                color: success ? AppColors.success : Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  success ? 'CSV telemetry exported successfully' : 'No telemetry records to export',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundPrimary,
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
                // Header
                _buildHeader(context, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // Time Range Selector (1h, 6h, 24h, 7d)
                _buildRangeSelector(isDark),
                const SizedBox(height: AppSpacing.base),

                if (readings.isEmpty)
                  const EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'No Historical Data in Range',
                    message: 'Connect to the ESP32 (AQM-Kamalesh) to stream and record sensor readings.',
                  )
                else ...[
                  // Statistical KPI Cards
                  _buildKpiMetrics(readings),
                  const SizedBox(height: AppSpacing.base),

                  // Sensor Metric Switcher for Chart
                  _buildMetricSelector(isDark),
                  const SizedBox(height: AppSpacing.md),

                  // Interactive Chart
                  _buildChartCard(readings),
                  const SizedBox(height: AppSpacing.base),

                  // Data Availability & Quality Card
                  _buildDataQualityCard(readings),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, MonitoringProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ANALYTICS',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Sensor telemetry statistics & historical analysis',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ExportCsvButton(
          isExporting: _isExporting,
          onPressed: () => _handleExportCsv(context, provider),
        ),
      ],
    );
  }

  Widget _buildRangeSelector(bool isDark) {
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
                  color: isSelected ? AppColors.primaryNavy : (isDark ? AppColors.darkSurface : AppColors.cardBackground),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryNavy : (isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  range.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricSelector(bool isDark) {
    return Row(
      children: SelectedMetric.values.map((metric) {
        final isSelected = _selectedMetric == metric;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: ChoiceChip(
              label: Text(
                metric.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
              ),
              selected: isSelected,
              selectedColor: metric.color,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.mutedBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: isSelected ? metric.color : (isDark ? AppColors.darkBorder : AppColors.border)),
              ),
              onSelected: (_) => setState(() => _selectedMetric = metric),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKpiMetrics(List<SensorReading> readings) {
    double? minTemp, maxTemp, sumTemp = 0;
    int countTemp = 0;
    double? minHum, maxHum, sumHum = 0;
    int countHum = 0;
    int? minGas, maxGas, sumGas = 0;
    int countGas = 0;

    for (final r in readings) {
      if (r.temperature != null) {
        minTemp = (minTemp == null) ? r.temperature! : (r.temperature! < minTemp ? r.temperature! : minTemp);
        maxTemp = (maxTemp == null) ? r.temperature! : (r.temperature! > maxTemp ? r.temperature! : maxTemp);
        sumTemp = sumTemp! + r.temperature!;
        countTemp++;
      }
      if (r.humidity != null) {
        minHum = (minHum == null) ? r.humidity! : (r.humidity! < minHum ? r.humidity! : minHum);
        maxHum = (maxHum == null) ? r.humidity! : (r.humidity! > maxHum ? r.humidity! : maxHum);
        sumHum = sumHum! + r.humidity!;
        countHum++;
      }
      if (r.gasRawAdc != null) {
        minGas = (minGas == null) ? r.gasRawAdc! : (r.gasRawAdc! < minGas ? r.gasRawAdc! : minGas);
        maxGas = (maxGas == null) ? r.gasRawAdc! : (r.gasRawAdc! > maxGas ? r.gasRawAdc! : maxGas);
        sumGas = sumGas! + r.gasRawAdc!;
        countGas++;
      }
    }

    final avgTemp = countTemp > 0 ? (sumTemp! / countTemp).toStringAsFixed(1) : '—';
    final avgHum = countHum > 0 ? (sumHum! / countHum).toStringAsFixed(1) : '—';
    final avgGas = countGas > 0 ? (sumGas! ~/ countGas).toString() : '—';

    return Column(
      children: [
        // Temperature Summary Card
        _buildStatCard(
          title: 'TEMPERATURE SUMMARY',
          icon: Icons.thermostat_rounded,
          color: AppColors.accentTemperature,
          minStr: minTemp != null ? '${minTemp.toStringAsFixed(1)}°C' : '—',
          meanStr: '$avgTemp°C',
          maxStr: maxTemp != null ? '${maxTemp.toStringAsFixed(1)}°C' : '—',
        ),
        const SizedBox(height: AppSpacing.sm),

        // Humidity Summary Card
        _buildStatCard(
          title: 'HUMIDITY SUMMARY',
          icon: Icons.water_drop_rounded,
          color: AppColors.accentHumidity,
          minStr: minHum != null ? '${minHum.toStringAsFixed(1)}%' : '—',
          meanStr: '$avgHum%',
          maxStr: maxHum != null ? '${maxHum.toStringAsFixed(1)}%' : '—',
        ),
        const SizedBox(height: AppSpacing.sm),

        // MQ-2 Gas Raw ADC Summary Card
        _buildStatCard(
          title: 'MQ-2 GAS RAW ADC SUMMARY',
          icon: Icons.cloud_outlined,
          color: AppColors.accentGas,
          minStr: minGas != null ? '$minGas ADC' : '—',
          meanStr: '$avgGas ADC',
          maxStr: maxGas != null ? '$maxGas ADC' : '—',
          footnote: 'Raw uncalibrated 12-bit ADC counts (0–4095)',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required IconData icon,
    required Color color,
    required String minStr,
    required String meanStr,
    required String maxStr,
    String? footnote,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatTile('MINIMUM', minStr),
              _buildStatTile('AVERAGE', meanStr, isHighlight: true, color: color),
              _buildStatTile('MAXIMUM', maxStr),
            ],
          ),
          if (footnote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            const Divider(height: 12, color: AppColors.borderSubtle),
            Text(
              footnote,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, {bool isHighlight = false, Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: FontWeight.w700,
            color: isHighlight ? (color ?? AppColors.primary) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<SensorReading> readings) {
    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      final r = readings[i];
      double? val;
      if (_selectedMetric == SelectedMetric.temperature) val = r.temperature;
      if (_selectedMetric == SelectedMetric.humidity) val = r.humidity;
      if (_selectedMetric == SelectedMetric.gas) val = r.gasRawAdc?.toDouble();

      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_selectedMetric.title.toUpperCase()} TREND',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _selectedMetric.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '${spots.length} DATA POINTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _selectedMetric.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (spots.length < 2)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: const Text(
                'Insufficient data points to render trend line',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => const FlLine(
                      color: AppColors.borderSubtle,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                      ),
                    ),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: _selectedMetric.color,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _selectedMetric.color.withOpacity(0.12),
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

  Widget _buildDataQualityCard(List<SensorReading> readings) {
    final firstTime = readings.first.timestamp;
    final lastTime = readings.last.timestamp;
    final durationSeconds = lastTime.difference(firstTime).inSeconds.abs();
    final expectedSamples = durationSeconds > 0 ? (durationSeconds / 2.0).ceil() : readings.length;
    final availability = expectedSamples > 0
        ? ((readings.length / expectedSamples) * 100).clamp(0.0, 100.0).toStringAsFixed(0)
        : '100';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Text('TOTAL READINGS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                '${readings.length}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 24, child: VerticalDivider(color: AppColors.border)),
          Column(
            children: [
              const Text('DATA AVAILABILITY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                '$availability%',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 24, child: VerticalDivider(color: AppColors.border)),
          Column(
            children: [
              const Text('RANGE DURATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text(
                _selectedRange.label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.secondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
