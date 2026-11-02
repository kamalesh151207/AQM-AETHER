// AQM AETHER — Intelligence Screen
// Environmental analysis, statistics, trends, history, and data export

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/monitoring_event.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/csv_export_service.dart';

class IntelligenceScreen extends StatelessWidget {
  const IntelligenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer2<AnalyticsProvider, MonitoringProvider>(
          builder: (context, analytics, monitoring, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.lg,
              ),
              children: [
                _ScreenHeader(),
                const SizedBox(height: AppSpacing.base),
                _StatisticalSummaryPanel(analytics: analytics),
                const SizedBox(height: AppSpacing.md),
                _TrendAnalysisPanel(analytics: analytics),
                const SizedBox(height: AppSpacing.md),
                _EnvironmentalHistorySection(analytics: analytics),
                const SizedBox(height: AppSpacing.md),
                _EventAnalysisPanel(monitoring: monitoring),
                const SizedBox(height: AppSpacing.md),
                _DataExportSection(analytics: analytics, monitoring: monitoring),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Screen Header ────────────────────────────────────────────────────────────

class _ScreenHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intelligence',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.6,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          'Environmental Analysis',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Panel Wrapper ────────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Color? accentColor;

  const _Panel({
    required this.title,
    this.subtitle,
    required this.child,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.base,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (accentColor != null) ...[
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.border),
          child,
        ],
      ),
    );
  }
}

// ─── Statistical Summary Panel ────────────────────────────────────────────────

class _StatisticalSummaryPanel extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _StatisticalSummaryPanel({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final tempStats = analytics.temperatureStats;
    final humStats = analytics.humidityStats;

    if (tempStats == null && humStats == null) {
      return const _Panel(
        title: 'Statistical Summary',
        subtitle: 'Aggregate sensor metrics',
        accentColor: AppColors.accentPrimary,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.analytics_outlined,
                    color: AppColors.textMuted, size: 32),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Insufficient data — connect device to begin recording',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalSamples = analytics.allReadings.length;

    return _Panel(
      title: 'Statistical Summary',
      subtitle: 'Aggregate sensor metrics',
      accentColor: AppColors.accentPrimary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatsColumn(
                    label: 'Temperature',
                    unit: '°C',
                    color: AppColors.accentTemperature,
                    stats: tempStats,
                  ),
                ),
                Container(
                  width: 1,
                  height: 120,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base),
                ),
                Expanded(
                  child: _StatsColumn(
                    label: 'Humidity',
                    unit: '%',
                    color: AppColors.accentHumidity,
                    stats: humStats,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.base),
            Container(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _MetaPill(
                  icon: Icons.data_array_rounded,
                  label: '$totalSamples total samples',
                  color: AppColors.accentPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                if (tempStats != null)
                  _MetaPill(
                    icon: Icons.check_circle_outline_rounded,
                    label: '${tempStats.availabilityPercent.toStringAsFixed(1)}% available',
                    color: AppColors.success,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsColumn extends StatelessWidget {
  final String label;
  final String unit;
  final Color color;
  final SensorStats? stats;

  const _StatsColumn({
    required this.label,
    required this.unit,
    required this.color,
    this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'No data',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _StatRow(label: 'MIN', value: stats!.min, unit: unit, color: AppColors.accentSecondary),
        const SizedBox(height: AppSpacing.sm),
        _StatRow(label: 'MAX', value: stats!.max, unit: unit, color: AppColors.critical),
        const SizedBox(height: AppSpacing.sm),
        _StatRow(label: 'AVG', value: stats!.average, unit: unit, color: color, large: true),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final bool large;

  const _StatRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Text(
          value.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: large ? 22 : 16,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: large ? 12 : 10,
            fontWeight: FontWeight.w500,
            color: color.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Trend Analysis Panel ─────────────────────────────────────────────────────

class _TrendAnalysisPanel extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _TrendAnalysisPanel({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final tempTrend = analytics.temperatureStats?.trend ?? TrendDirection.insufficient;
    final humTrend = analytics.humidityStats?.trend ?? TrendDirection.insufficient;

    return _Panel(
      title: 'Trend Analysis',
      subtitle: 'Calculated from last 20 readings',
      accentColor: AppColors.accentSecondary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _TrendCard(
                    label: 'Temperature',
                    trend: tempTrend,
                    accentColor: AppColors.accentTemperature,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TrendCard(
                    label: 'Humidity',
                    trend: humTrend,
                    accentColor: AppColors.accentHumidity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 12, color: AppColors.textMuted),
                SizedBox(width: AppSpacing.xs),
                Text(
                  'Trend calculated from last 20 recorded readings',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  final String label;
  final TrendDirection trend;
  final Color accentColor;

  const _TrendCard({
    required this.label,
    required this.trend,
    required this.accentColor,
  });

  Color get _trendColor {
    switch (trend) {
      case TrendDirection.increasing:
        return AppColors.accentTemperature;
      case TrendDirection.decreasing:
        return AppColors.accentSecondary;
      case TrendDirection.stable:
        return AppColors.accentPrimary;
      case TrendDirection.insufficient:
        return AppColors.textMuted;
    }
  }

  String get _trendIcon {
    switch (trend) {
      case TrendDirection.increasing:
        return '↑';
      case TrendDirection.decreasing:
        return '↓';
      case TrendDirection.stable:
        return '—';
      case TrendDirection.insufficient:
        return '?';
    }
  }

  String get _trendLabel {
    switch (trend) {
      case TrendDirection.increasing:
        return 'Increasing';
      case TrendDirection.decreasing:
        return 'Decreasing';
      case TrendDirection.stable:
        return 'Stable';
      case TrendDirection.insufficient:
        return 'Insufficient';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _trendColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: accentColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _trendColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Text(
                    _trendIcon,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _trendColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  _trendLabel,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _trendColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Environmental History Section ────────────────────────────────────────────

class _EnvironmentalHistorySection extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _EnvironmentalHistorySection({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final readings = analytics.allReadings.reversed.take(20).toList();

    return _Panel(
      title: 'Environmental History',
      subtitle: 'Last 20 recorded readings',
      accentColor: AppColors.accentPrimary,
      child: readings.isEmpty
          ? _EmptyHistoryState()
          : Column(
              children: [
                // Table header
                Container(
                  color: AppColors.elevatedSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.sm,
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'TIME',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'TEMP',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'HUMIDITY',
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ...readings.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final reading = entry.value;
                  final isEven = idx.isEven;
                  final timeStr = DateFormat('HH:mm:ss').format(reading.timestamp);

                  return Container(
                    color: isEven
                        ? AppColors.panelBackground
                        : AppColors.elevatedSurface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM').format(reading.timestamp),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            reading.temperature != null
                                ? '${reading.temperature!.toStringAsFixed(1)}°C'
                                : '—',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentTemperature,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            reading.humidity != null
                                ? '${reading.humidity!.toStringAsFixed(1)}%'
                                : '—',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentHumidity,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Container(
                  height: 48,
                  color: AppColors.elevatedSurface,
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.base),
                  child: Row(
                    children: [
                      const Icon(Icons.history_rounded,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Showing ${readings.length} of ${analytics.allReadings.length} total readings',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.timeline_rounded, color: AppColors.textMuted, size: 32),
            SizedBox(height: AppSpacing.md),
            Text(
              'No readings recorded yet',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'Connect a device to start collecting environmental data',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Event Analysis Panel ─────────────────────────────────────────────────────

class _EventAnalysisPanel extends StatelessWidget {
  final MonitoringProvider monitoring;

  const _EventAnalysisPanel({required this.monitoring});

  @override
  Widget build(BuildContext context) {
    final events = monitoring.events;

    // Count by category
    int connectionCount = 0;
    int readingCount = 0;
    int intervalCount = 0;
    int warningErrorCount = 0;

    for (final e in events) {
      switch (e.type) {
        case MonitoringEventType.deviceConnected:
        case MonitoringEventType.deviceDisconnected:
        case MonitoringEventType.monitoringStarted:
        case MonitoringEventType.monitoringStopped:
        case MonitoringEventType.reconnecting:
        case MonitoringEventType.reconnected:
          connectionCount++;
          break;
        case MonitoringEventType.readingReceived:
          readingCount++;
          break;
        case MonitoringEventType.samplingIntervalChanged:
          intervalCount++;
          break;
        case MonitoringEventType.warning:
        case MonitoringEventType.error:
          warningErrorCount++;
          break;
      }
    }

    return _Panel(
      title: 'Event Analysis',
      subtitle: 'Activity breakdown',
      accentColor: AppColors.accentSecondary,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _EventBadge(
                    icon: Icons.link_rounded,
                    label: 'Connection',
                    count: connectionCount,
                    color: AppColors.accentPrimary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _EventBadge(
                    icon: Icons.sensors_rounded,
                    label: 'Readings',
                    count: readingCount,
                    color: AppColors.accentSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _EventBadge(
                    icon: Icons.timer_outlined,
                    label: 'Interval',
                    count: intervalCount,
                    color: AppColors.accentTemperature,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _EventBadge(
                    icon: Icons.warning_amber_rounded,
                    label: 'Warnings',
                    count: warningErrorCount,
                    color: AppColors.critical,
                  ),
                ),
              ],
            ),
            if (events.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'No events logged yet',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _EventBadge({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Data Export Section ──────────────────────────────────────────────────────

class _DataExportSection extends StatefulWidget {
  final AnalyticsProvider analytics;
  final MonitoringProvider monitoring;

  const _DataExportSection({
    required this.analytics,
    required this.monitoring,
  });

  @override
  State<_DataExportSection> createState() => _DataExportSectionState();
}

class _DataExportSectionState extends State<_DataExportSection> {
  bool _exporting = false;

  Future<void> _doExport() async {
    if (_exporting) return;
    setState(() => _exporting = true);
    try {
      final service = CsvExportService();
      await service.shareExport(widget.analytics.allReadings);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.critical.withOpacity(0.85),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final readings = widget.analytics.allReadings;
    final hasData = readings.isNotEmpty;

    String dateRange = '—';
    if (hasData) {
      final first = readings.first.timestamp;
      final last = readings.last.timestamp;
      final fmt = DateFormat('dd MMM yyyy');
      dateRange = '${fmt.format(first)} → ${fmt.format(last)}';
    }

    return _Panel(
      title: 'Export Data',
      subtitle: 'Share sensor readings as CSV',
      accentColor: AppColors.success,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info rows
            _ExportInfoRow(
              icon: Icons.data_array_rounded,
              label: 'Total readings',
              value: '${readings.length}',
            ),
            const SizedBox(height: AppSpacing.sm),
            _ExportInfoRow(
              icon: Icons.date_range_rounded,
              label: 'Date range',
              value: dateRange,
            ),
            const SizedBox(height: AppSpacing.sm),
            const _ExportInfoRow(
              icon: Icons.description_outlined,
              label: 'CSV includes',
              value: 'Timestamp, Temperature, Humidity',
            ),
            const SizedBox(height: AppSpacing.base),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: hasData && !_exporting ? _doExport : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasData
                        ? AppColors.success.withOpacity(_exporting ? 0.5 : 0.12)
                        : AppColors.border.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: hasData
                          ? AppColors.success.withOpacity(_exporting ? 0.4 : 0.5)
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_exporting)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.success),
                          ),
                        )
                      else
                        Icon(
                          Icons.ios_share_rounded,
                          size: 18,
                          color: hasData
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        _exporting ? 'Exporting…' : 'Export to CSV',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: hasData
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!hasData) ...[
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'No data to export — connect device and record readings first.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExportInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ExportInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
