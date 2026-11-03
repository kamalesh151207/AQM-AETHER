// AQM AETHER — Sensor Value Tile Widget

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/analytics_provider.dart';
import '../common/status_badge.dart';

class SensorValueTile extends StatelessWidget {
  final String label;
  final double? value;
  final String unit;
  final Color accentColor;
  final bool isSimulated;
  final bool isStale;
  final DateTime? lastUpdate;
  final TrendDirection? trend;

  const SensorValueTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    this.isSimulated = false,
    this.isStale = false,
    this.lastUpdate,
    this.trend,
  });

  String _formatLastUpdate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return DateFormat('HH:mm').format(dt);
  }

  Widget _trendIcon(TrendDirection direction) {
    IconData icon;
    Color color;
    switch (direction) {
      case TrendDirection.increasing:
        icon = Icons.trending_up_rounded;
        color = AppColors.critical;
        break;
      case TrendDirection.decreasing:
        icon = Icons.trending_down_rounded;
        color = AppColors.accentSecondary;
        break;
      case TrendDirection.stable:
        icon = Icons.trending_flat_rounded;
        color = AppColors.success;
        break;
      case TrendDirection.insufficient:
        icon = Icons.remove_rounded;
        color = AppColors.textMuted;
        break;
    }
    return Icon(icon, size: 16, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isStale
              ? AppColors.warning.withOpacity(0.4)
              : accentColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: label + badges
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isSimulated)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: StatusBadge(
                    label: 'SIMULATED',
                    color: AppColors.warning,
                    outlined: true,
                  ),
                ),
              if (isStale)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: StatusBadge(
                    label: 'STALE',
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Large value display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasValue)
                Text(
                  value!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: isStale
                        ? AppColors.textMuted
                        : accentColor,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                )
              else
                const Text(
                  '--.-',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: -1.0,
                    height: 1.0,
                  ),
                ),
              const SizedBox(width: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isStale
                        ? AppColors.textMuted
                        : accentColor.withOpacity(0.7),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Spacer(),
              if (trend != null && trend != TrendDirection.insufficient)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _trendIcon(trend!),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Last update row
          if (lastUpdate != null)
            Text(
              'Updated ${_formatLastUpdate(lastUpdate!)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: 0.1,
              ),
            )
          else if (!hasValue)
            const Text(
              'No data received',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                letterSpacing: 0.1,
              ),
            ),
        ],
      ),
    );
  }
}
