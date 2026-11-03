// AQM AETHER — Data Quality Telemetry Badge

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

  Color get _bgColor {
    switch (quality) {
      case DataQuality.fresh:
        return AppColors.successLight;
      case DataQuality.delayed:
        return AppColors.warningLight;
      case DataQuality.stale:
        return AppColors.criticalLight;
      case DataQuality.unavailable:
        return AppColors.elevatedSurface;
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: _color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 10, color: _color),
          const SizedBox(width: 4),
          Text(
            quality.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

