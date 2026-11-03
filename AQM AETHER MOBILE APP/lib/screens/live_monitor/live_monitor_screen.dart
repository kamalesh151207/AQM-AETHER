// AQM AETHER — Live Monitor Screen
// Real-time temperature & humidity monitoring with charts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/sensor_reading.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/analytics_provider.dart';
import 'widgets/live_value_display.dart';
import 'widgets/sensor_chart.dart';

// ── Time filter options ──────────────────────────────────────────────────────

enum _TimeFilter {
  oneHour(label: '1H', duration: Duration(hours: 1)),
  sixHours(label: '6H', duration: Duration(hours: 6)),
  twentyFourHours(label: '24H', duration: Duration(hours: 24)),
  sevenDays(label: '7D', duration: Duration(days: 7));

  final String label;
  final Duration duration;

  const _TimeFilter({required this.label, required this.duration});
}

// ── Screen ───────────────────────────────────────────────────────────────────

class LiveMonitorScreen extends StatefulWidget {
  const LiveMonitorScreen({super.key});

  @override
  State<LiveMonitorScreen> createState() => _LiveMonitorScreenState();
}

class _LiveMonitorScreenState extends State<LiveMonitorScreen>
    with SingleTickerProviderStateMixin {
  _TimeFilter _selectedFilter = _TimeFilter.oneHour;

  late AnimationController _statusPulseController;
  late Animation<double> _statusPulseAnimation;

  @override
  void initState() {
    super.initState();
    _statusPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _statusPulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
          parent: _statusPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _statusPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<DeviceProvider, MonitoringProvider, AnalyticsProvider>(
      builder: (context, device, monitoring, analytics, _) {
        final isConnected = device.isConnected;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.backgroundPrimary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                expandedHeight: 0,
                titleSpacing: AppSpacing.base,
                title: Row(
                  children: [
                    const Text(
                      'Live Monitor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ConnectionStatusIndicator(
                      isConnected: isConnected,
                      pulseAnimation: _statusPulseAnimation,
                    ),
                  ],
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: AppColors.border.withOpacity(0.4),
                  ),
                ),
              ),

              // ── Content ──────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.base),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),

                      // Time filter row
                      _TimeFilterRow(
                        selected: _selectedFilter,
                        onSelected: (f) =>
                            setState(() => _selectedFilter = f),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Temperature section
                      _SensorSection(
                        title: 'Temperature',
                        icon: Icons.thermostat_rounded,
                        iconColor: AppColors.accentTemperature,
                        value: device.temperature,
                        unit: '°C',
                        accentColor: AppColors.accentTemperature,
                        isLive: isConnected && device.temperature != null,
                        stats: _computeStats(
                          analytics
                              .readingsForDuration(_selectedFilter.duration),
                          isTemperature: true,
                        ),
                        readings: monitoring.readings,
                        timeRange: _selectedFilter.duration,
                        isTemperature: true,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Humidity section
                      _SensorSection(
                        title: 'Humidity',
                        icon: Icons.water_drop_rounded,
                        iconColor: AppColors.accentHumidity,
                        value: device.humidity,
                        unit: '%',
                        accentColor: AppColors.accentHumidity,
                        isLive: isConnected && device.humidity != null,
                        stats: _computeStats(
                          analytics
                              .readingsForDuration(_selectedFilter.duration),
                          isTemperature: false,
                        ),
                        readings: monitoring.readings,
                        timeRange: _selectedFilter.duration,
                        isTemperature: false,
                      ),

                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Compute stats from filtered readings (not using AnalyticsProvider's
  /// global stats so we respect the time range).
  _LocalStats? _computeStats(
    List<SensorReading> filtered, {
    required bool isTemperature,
  }) {
    final values = filtered
        .map((r) => isTemperature ? r.temperature : r.humidity)
        .whereType<double>()
        .toList();

    if (values.isEmpty) return null;

    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return _LocalStats(min: min, max: max, average: avg);
  }
}

// ── Local stats container ────────────────────────────────────────────────────

class _LocalStats {
  final double min;
  final double max;
  final double average;
  const _LocalStats({
    required this.min,
    required this.max,
    required this.average,
  });
}

// ── Connection status indicator ──────────────────────────────────────────────

class _ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final Animation<double> pulseAnimation;

  const _ConnectionStatusIndicator({
    required this.isConnected,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isConnected
            ? AppColors.success.withOpacity(0.12)
            : AppColors.critical.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isConnected
              ? AppColors.success.withOpacity(0.3)
              : AppColors.critical.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseAnimation,
            builder: (context, _) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? AppColors.success.withOpacity(pulseAnimation.value)
                      : AppColors.critical.withOpacity(0.7),
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: AppColors.success
                                .withOpacity(0.4 * pulseAnimation.value),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 5),
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isConnected ? AppColors.success : AppColors.critical,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Time filter row ──────────────────────────────────────────────────────────

class _TimeFilterRow extends StatelessWidget {
  final _TimeFilter selected;
  final ValueChanged<_TimeFilter> onSelected;

  const _TimeFilterRow({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _TimeFilter.values.map((filter) {
        final isSelected = filter == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _TimeChip(
            label: filter.label,
            isSelected: isSelected,
            onTap: () => onSelected(filter),
          ),
        );
      }).toList(),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPrimary.withOpacity(0.12)
              : AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPrimary
                : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.accentPrimary : AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Sensor section (reused for temp & humidity) ──────────────────────────────

class _SensorSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final double? value;
  final String unit;
  final Color accentColor;
  final bool isLive;
  final _LocalStats? stats;
  final List<SensorReading> readings;
  final Duration timeRange;
  final bool isTemperature;

  const _SensorSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.isLive,
    required this.stats,
    required this.readings,
    required this.timeRange,
    required this.isTemperature,
  });

  // Convert _LocalStats → SensorStats-like wrapper for SensorStatsRow
  _AdaptedStats? get _adaptedStats => stats == null
      ? null
      : _AdaptedStats(
          min: stats!.min,
          max: stats!.max,
          average: stats!.average,
        );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              0,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Live value display
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.md,
              AppSpacing.base,
              0,
            ),
            child: LiveValueDisplay(
              value: value,
              unit: unit,
              color: accentColor,
              isLive: isLive,
            ),
          ),

          // Divider
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.md,
              horizontal: AppSpacing.base,
            ),
            child: Divider(
              color: AppColors.border.withOpacity(0.4),
              height: 1,
              thickness: 1,
            ),
          ),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
            child: _AdaptedStatsRow(
              adapted: _adaptedStats,
              accentColor: accentColor,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Chart
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              0,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: SizedBox(
              height: 180,
              child: SensorChart(
                readings: readings,
                timeRange: timeRange,
                lineColor: accentColor,
                valueUnit: unit,
                isTemperature: isTemperature,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Adapter: _LocalStats → SensorStatsRow ────────────────────────────────────
// SensorStatsRow accepts SensorStats (from AnalyticsProvider), but we use a
// local stats model here to allow per-timerange filtering. We pass through an
// adapter so we don't duplicate widget code.

class _AdaptedStats {
  final double min;
  final double max;
  final double average;
  const _AdaptedStats({
    required this.min,
    required this.max,
    required this.average,
  });
}

class _AdaptedStatsRow extends StatelessWidget {
  final _AdaptedStats? adapted;
  final Color accentColor;

  const _AdaptedStatsRow({
    required this.adapted,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatCol(
              label: 'MIN',
              value: adapted?.min,
              accentColor: accentColor,
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: AppColors.border.withOpacity(0.5),
          ),
          Expanded(
            child: _StatCol(
              label: 'MAX',
              value: adapted?.max,
              accentColor: accentColor,
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: AppColors.border.withOpacity(0.5),
          ),
          Expanded(
            child: _StatCol(
              label: 'AVG',
              value: adapted?.average,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCol extends StatelessWidget {
  final String label;
  final double? value;
  final Color accentColor;

  const _StatCol({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value != null ? value!.toStringAsFixed(1) : '—',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: value != null ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
