// AQM AETHER — Data Quality Telemetry Badge (AETHER GRAPHITE Theme)

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ble_constants.dart';

class DataQualityBadge extends StatelessWidget {
  final DataQuality quality;

  const DataQualityBadge({super.key, required this.quality});

  Color get _color {
    switch (quality) {
      case DataQuality.fresh:
        return AppColors.success;
      case DataQuality.delayed:
        return AppColors.warning;
      case DataQuality.stale:
        return AppColors.critical;
      case DataQuality.unavailable:
        return AppColors.textMuted;
    }
  }

  IconData get _icon {
    switch (quality) {
      case DataQuality.fresh:
        return Icons.bolt_rounded;
      case DataQuality.delayed:
        return Icons.access_time_rounded;
      case DataQuality.stale:
        return Icons.timer_off_rounded;
      case DataQuality.unavailable:
        return Icons.sensors_off_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = _color;
    final bgColor = isDark ? color.withOpacity(0.15) : color.withOpacity(0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            quality.label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
