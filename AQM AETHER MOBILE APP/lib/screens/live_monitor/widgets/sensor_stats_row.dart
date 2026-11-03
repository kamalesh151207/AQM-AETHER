// AQM AETHER — Sensor Stats Row Widget
// Displays Min / Max / Avg statistics in a three-column layout

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/analytics_provider.dart';

class SensorStatsRow extends StatelessWidget {
  final SensorStats? stats;
  final Color accentColor;

  const SensorStatsRow({
    super.key,
    required this.stats,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _StatColumn(
              label: 'MIN',
              value: stats?.min,
              accentColor: accentColor,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatColumn(
              label: 'MAX',
              value: stats?.max,
              accentColor: accentColor,
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _StatColumn(
              label: 'AVG',
              value: stats?.average,
              accentColor: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final double? value;
  final Color accentColor;

  const _StatColumn({
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: AppColors.border.withOpacity(0.5),
    );
  }
}
