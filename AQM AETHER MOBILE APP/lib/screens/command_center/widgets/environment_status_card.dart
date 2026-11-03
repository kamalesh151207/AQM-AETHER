// AQM AETHER — Environmental Status Card Widget
// Analyzes live readings and provides an intelligent status summary

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/ble_constants.dart';

enum _EnvironmentStatus {
  normal,
  elevated,
  attentionRequired,
  sensorUnavailable,
}

class EnvironmentStatusCard extends StatelessWidget {
  final double? temperature;
  final double? humidity;
  final bool isConnected;
  final String? alertStatus;

  const EnvironmentStatusCard({
    super.key,
    required this.temperature,
    required this.humidity,
    required this.isConnected,
    this.alertStatus,
  });

  _EnvironmentStatus get _status {
    if (!isConnected || (temperature == null && humidity == null)) {
      return _EnvironmentStatus.sensorUnavailable;
    }
    if (temperature != null) {
      if (temperature! > 35.0 || temperature! < 10.0) {
        return _EnvironmentStatus.attentionRequired;
      }
      if (temperature! > 28.0) {
        return _EnvironmentStatus.elevated;
      }
    }
    return _EnvironmentStatus.normal;
  }

  Color _statusColor(_EnvironmentStatus s) {
    switch (s) {
      case _EnvironmentStatus.normal:
        return AppColors.success;
      case _EnvironmentStatus.elevated:
        return AppColors.warning;
      case _EnvironmentStatus.attentionRequired:
        return AppColors.critical;
      case _EnvironmentStatus.sensorUnavailable:
        return AppColors.textMuted;
    }
  }

  IconData _statusIcon(_EnvironmentStatus s) {
    switch (s) {
      case _EnvironmentStatus.normal:
        return Icons.check_circle_outline_rounded;
      case _EnvironmentStatus.elevated:
        return Icons.warning_amber_rounded;
      case _EnvironmentStatus.attentionRequired:
        return Icons.error_outline_rounded;
      case _EnvironmentStatus.sensorUnavailable:
        return Icons.sensors_off_rounded;
    }
  }

  String _statusLabel(_EnvironmentStatus s) {
    switch (s) {
      case _EnvironmentStatus.normal:
        return 'Normal';
      case _EnvironmentStatus.elevated:
        return 'Elevated';
      case _EnvironmentStatus.attentionRequired:
        return 'Attention Required';
      case _EnvironmentStatus.sensorUnavailable:
        return 'Sensor Unavailable';
    }
  }

  String _statusDescription(_EnvironmentStatus s) {
    switch (s) {
      case _EnvironmentStatus.normal:
        return 'Temperature within optimal range (18–28°C). Conditions appear stable.';
      case _EnvironmentStatus.elevated:
        if (temperature != null) {
          return 'Temperature reading of ${temperature!.toStringAsFixed(1)}°C is above the comfortable threshold of 28°C.';
        }
        return 'Temperature is above the comfortable threshold of 28°C.';
      case _EnvironmentStatus.attentionRequired:
        if (temperature != null && temperature! > 35.0) {
          return 'Temperature of ${temperature!.toStringAsFixed(1)}°C exceeds 35°C — verify environment or sensor placement.';
        }
        if (temperature != null && temperature! < 10.0) {
          return 'Temperature of ${temperature!.toStringAsFixed(1)}°C is below 10°C — unusually cold reading detected.';
        }
        return 'Sensor reading is outside expected range. Verify placement.';
      case _EnvironmentStatus.sensorUnavailable:
        return isConnected
            ? 'Waiting for first sensor reading from device.'
            : 'No device connected. Connect AQM-Kamalesh via BLE to receive data.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    final label = _statusLabel(status);
    final description = _statusDescription(status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: color.withOpacity(0.4), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isConnected && alertStatus != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: (alertStatus?.toUpperCase() == 'ALERT'
                            ? AppColors.critical
                            : AppColors.success)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: (alertStatus?.toUpperCase() == 'ALERT'
                              ? AppColors.critical
                              : AppColors.success)
                          .withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        alertStatus?.toUpperCase() == 'ALERT'
                            ? Icons.warning_rounded
                            : Icons.check_circle_rounded,
                        size: 11,
                        color: alertStatus?.toUpperCase() == 'ALERT'
                            ? AppColors.critical
                            : AppColors.success,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'ESP32: ${alertStatus!.toUpperCase()}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: alertStatus?.toUpperCase() == 'ALERT'
                              ? AppColors.critical
                              : AppColors.success,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: AppSpacing.sm),
              // Color dot indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 11,
                  color: AppColors.textMuted,
                ),
                SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Prototype indicator — not a certified assessment. '
                    '${AppConstants.appName} uses simulated sensor values for BLE demonstration.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
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
