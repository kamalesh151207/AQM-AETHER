// AQM AETHER — MPU6050 6-Axis Motion Intelligence & Dynamic Telemetry
// Accelerometer (X, Y, Z in g) and Gyroscope (X, Y, Z in °/s)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/common/app_card.dart';

class MotionScreen extends StatelessWidget {
  const MotionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DeviceProvider, MonitoringProvider>(
      builder: (context, deviceProv, monProv, _) {
        final dev = deviceProv.device;
        final isConnected = deviceProv.isConnected;
        final mpuFound = dev.mpuCharFound;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppColors.darkBackground : AppColors.backgroundPrimary;
        final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkPrimaryBlue : AppColors.accentPrimary).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.screen_rotation_rounded,
                      color: isDark ? AppColors.darkPrimaryBlue : AppColors.accentPrimary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AERION AQM',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Motion Telemetry',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              // 1. Connection & Availability Banner
              if (!isConnected)
                _buildNotConnectedCard()
              else if (!mpuFound)
                _buildMpuNotAvailableCard()
              else
                ...[
                  // 2. Motion Classification & Magnitude Card
                  _buildMotionSummaryCard(deviceProv),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Accelerometer 3-Axis Grid
                  _buildSectionLabel('3-AXIS ACCELEROMETER', 'UUIDs 9007, 9008, 9009 (g)'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _buildAxisCard('ACCEL X', deviceProv.accelX, 'g', AppColors.critical)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildAxisCard('ACCEL Y', deviceProv.accelY, 'g', AppColors.normal)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildAxisCard('ACCEL Z', deviceProv.accelZ, 'g', AppColors.accentPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Gyroscope 3-Axis Grid
                  _buildSectionLabel('3-AXIS GYROSCOPE', 'UUIDs 900A, 900B, 900C (°/s)'),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(child: _buildAxisCard('GYRO X', deviceProv.gyroX, '°/s', AppColors.warning)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildAxisCard('GYRO Y', deviceProv.gyroY, '°/s', AppColors.accentSecondary)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: _buildAxisCard('GYRO Z', deviceProv.gyroZ, '°/s', AppColors.critical)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Motion Waveform Chart
                  _buildMotionChartCard(monProv),
                  const SizedBox(height: AppSpacing.xl),
                ],
            ],
          ),
        );
      },
    );
  }

  // ── MPU Not Available State ────────────────────────────────────────────────

  Widget _buildMpuNotAvailableCard() {
    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.sensors_off_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text(
                  'MPU6050 NOT AVAILABLE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'The MPU6050 accelerometer & gyroscope characteristics are not advertised by the connected ESP32 firmware.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline_rounded,
                    size: 14, color: AppColors.textMuted),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No synthetic or mock motion data is generated.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
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

  Widget _buildNotConnectedCard() {
    return const AppCard(
      color: AppColors.backgroundSecondary,
      child: Row(
        children: [
          Icon(Icons.bluetooth_disabled_rounded,
              color: AppColors.textMuted, size: 24),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISCONNECTED',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Connect to AQM-Kamalesh in the Devices tab to stream motion telemetry.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Motion Summary Card ────────────────────────────────────────────────────

  Widget _buildMotionSummaryCard(DeviceProvider provider) {
    final mag = provider.motionMagnitude;
    final stateStr = provider.motionState;

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MOTION CLASSIFICATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.normal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  stateStr,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.normal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                mag != null ? mag.toStringAsFixed(3) : '--',
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'g (Vector Magnitude ||a||)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Formula: √(ax² + ay² + az²) • Earth normal reference ~1.000g',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── 3-Axis Gauge Card ──────────────────────────────────────────────────────

  Widget _buildAxisCard(String label, double? value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value != null ? '${value >= 0 ? "+" : ""}${value.toStringAsFixed(2)}' : '--',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── Waveform Chart ─────────────────────────────────────────────────────────

  Widget _buildMotionChartCard(MonitoringProvider monProv) {
    final readings = monProv.motionReadings.take(40).toList();

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACCELERATION DYNAMICS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 160,
            child: readings.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting MPU6050 packets…',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        _buildLineBar(readings, (r) => r.accelX, AppColors.critical),
                        _buildLineBar(readings, (r) => r.accelY, AppColors.normal),
                        _buildLineBar(readings, (r) => r.accelZ, AppColors.accentPrimary),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.critical, label: 'X'),
              SizedBox(width: 12),
              _LegendDot(color: AppColors.normal, label: 'Y'),
              SizedBox(width: 12),
              _LegendDot(color: AppColors.accentPrimary, label: 'Z'),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLineBar(
      List<dynamic> readings, double? Function(dynamic) getter, Color color) {
    final spots = <FlSpot>[];
    for (int i = 0; i < readings.length; i++) {
      final val = getter(readings[i]);
      if (val != null) spots.add(FlSpot(i.toDouble(), val));
    }
    return LineChartBarData(
      spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
      color: color,
      barWidth: 2,
      isCurved: true,
      dotData: const FlDotData(show: false),
    );
  }

  Widget _buildSectionLabel(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 9,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
