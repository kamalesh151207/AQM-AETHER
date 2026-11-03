// AQM AETHER — AETHER BLUE: Intelligent Environmental Monitoring Dashboard
// Primary Blue #1769AA, Deep Navy #123456, Accent Cyan #19B5C5, Background #F5F8FC

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/data_quality_badge.dart';

class OverviewScreen extends StatefulWidget {
  final VoidCallback onNavigateToEnvironment;
  final VoidCallback onNavigateToDevices;
  final VoidCallback onNavigateToMotion;
  final VoidCallback onNavigateToAlerts;
  final VoidCallback onNavigateToSettings;

  const OverviewScreen({
    super.key,
    required this.onNavigateToEnvironment,
    required this.onNavigateToDevices,
    required this.onNavigateToMotion,
    required this.onNavigateToAlerts,
    required this.onNavigateToSettings,
  });

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer3<DeviceProvider, MonitoringProvider, ThresholdService>(
          builder: (context, deviceProvider, monitoringProvider, thresholdService, _) {
            final isConnected = deviceProvider.isConnected;
            final isAlarmActive = thresholdService.isAlarmActive && isConnected;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── A. HEADER ────────────────────────────────────────────────
                _buildHeader(deviceProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // Active Audio Alarm Banner (When breached)
                if (isAlarmActive) ...[
                  _buildAudibleAlarmBanner(thresholdService, deviceProvider),
                  const SizedBox(height: AppSpacing.base),
                ],

                // ── B. ENVIRONMENTAL STATUS PANEL ────────────────────────────
                _buildEnvironmentalStatusPanel(deviceProvider, thresholdService, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── C. DEVICE CONNECTION PANEL ───────────────────────────────
                _buildDeviceConnectionPanel(context, deviceProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── D. SENSOR READING SECTION ────────────────────────────────
                // Section Title
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.accentCyan,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'REAL-TIME ENVIRONMENTAL TELEMETRY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // 1. Temperature Card
                _buildTemperatureCard(deviceProvider, monitoringProvider, thresholdService, isDark),
                const SizedBox(height: AppSpacing.md),

                // 2. Humidity Card
                _buildHumidityCard(deviceProvider, monitoringProvider, thresholdService, isDark),
                const SizedBox(height: AppSpacing.md),

                // 3. MQ-2 Gas Raw ADC Card
                _buildGasCard(deviceProvider, isDark),
                const SizedBox(height: AppSpacing.md),

                // 4. MPU6050 Motion Card
                _buildMotionCard(deviceProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── E. QUICK MONITORING CONTROLS ─────────────────────────────
                _buildQuickControlsSection(context, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── F. DEVICE TELEMETRY AND HEALTH ───────────────────────────
                _buildDeviceHealthSection(deviceProvider, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── A. Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(DeviceProvider deviceProvider, bool isDark) {
    final status = deviceProvider.device.status;
    final isConnected = status.isConnected;

    Color statusDotColor;
    String statusLabel;
    if (isConnected) {
      statusDotColor = AppColors.success;
      statusLabel = 'ONLINE';
    } else if (status.isActive) {
      statusDotColor = AppColors.warning;
      statusLabel = 'SEARCHING';
    } else {
      statusDotColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
      statusLabel = 'OFFLINE';
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Branding & Subtitle
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.deepNavy, AppColors.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F123456),
                      offset: Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.air_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQM AETHER',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Text(
                    'Intelligent Environmental Monitoring',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Date & Time + Connection Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusDotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusDotColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                AppUtils.formatTime(_now),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
              Text(
                AppUtils.formatDate(_now),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── B. Environmental Status Panel ──────────────────────────────────────────

  Widget _buildEnvironmentalStatusPanel(
    DeviceProvider deviceProvider,
    ThresholdService thresholdService,
    bool isDark,
  ) {
    final isConnected = deviceProvider.isConnected;
    final temp = deviceProvider.temperature;
    final hum = deviceProvider.humidity;
    final gas = deviceProvider.gasRawAdc;

    Color panelColor;
    String statusTitle;
    String statusDescription;
    IconData statusIcon;

    if (!isConnected) {
      panelColor = isDark ? AppColors.darkBorder : AppColors.borderMedium;
      statusTitle = 'SYSTEM STANDBY / OFFLINE';
      statusDescription = 'Connect ESP32 (AQM-Kamalesh) to commence continuous environmental telemetry.';
      statusIcon = Icons.sensors_off_rounded;
    } else {
      // Evaluate based strictly on available readings and configured thresholds
      final isTempBreached = temp != null && temp >= thresholdService.temperatureThreshold;
      final isHumBreached = hum != null && hum >= thresholdService.humidityThreshold;
      final isGasHigh = gas != null && gas > 2800;

      if (isTempBreached || isHumBreached || isGasHigh) {
        panelColor = AppColors.error;
        statusTitle = 'ENVIRONMENTAL THRESHOLD BREACH';
        final causes = <String>[];
        if (isTempBreached) causes.add('Temp ≥ ${thresholdService.temperatureThreshold}°C');
        if (isHumBreached) causes.add('Humidity ≥ ${thresholdService.humidityThreshold}%');
        if (isGasHigh) causes.add('Gas density elevated ($gas ADC)');
        statusDescription = causes.join(' • ');
        statusIcon = Icons.warning_amber_rounded;
      } else if ((temp != null && temp >= thresholdService.temperatureThreshold - 2.0) ||
          (hum != null && hum >= thresholdService.humidityThreshold - 5.0) ||
          (gas != null && gas > 1800)) {
        panelColor = AppColors.warning;
        statusTitle = 'MODERATE READING / APPROACHING LIMIT';
        statusDescription = 'Readings are within safe range but approaching configured warning thresholds.';
        statusIcon = Icons.info_outline_rounded;
      } else {
        panelColor = AppColors.success;
        statusTitle = 'NORMAL ENVIRONMENTAL CONDITION';
        statusDescription = 'Atmospheric conditions and volatile parameters operating within nominal thresholds.';
        statusIcon = Icons.verified_rounded;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: panelColor.withOpacity(isDark ? 0.4 : 0.25),
          width: 1.5,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: panelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(statusIcon, color: panelColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: panelColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    Text(
                      statusDescription,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 12, color: AppColors.borderSubtle),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Temp Limit: ≤${thresholdService.temperatureThreshold.toStringAsFixed(0)}°C',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.borderMedium)),
              Text(
                'Hum Limit: ≤${thresholdService.humidityThreshold.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
              Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.borderMedium)),
              const Text(
                'Gas: 12-Bit ADC',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── C. Horizontal Device Connection Panel ──────────────────────────────────

  Widget _buildDeviceConnectionPanel(
    BuildContext context,
    DeviceProvider deviceProvider,
    bool isDark,
  ) {
    final dev = deviceProvider.device;
    final isConnected = deviceProvider.isConnected;
    final isBusy = dev.status.isActive && !isConnected;
    final lastUpdated = dev.lastUpdatedAt;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.md),
      child: Row(
        children: [
          // Bluetooth Signal Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isConnected
                  ? AppColors.accentCyanLight
                  : (isDark ? AppColors.darkElevated : AppColors.mutedBackground),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: isConnected ? AppColors.accentCyan.withOpacity(0.4) : AppColors.border,
              ),
            ),
            child: Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
              color: isConnected ? AppColors.accentCyan : AppColors.textMuted,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Device Information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dev.name.isNotEmpty ? dev.name : 'AQM-Kamalesh',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: (isConnected ? AppColors.success : AppColors.textMuted).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        isConnected ? 'GATT LINK' : 'DISCONNECTED',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isConnected ? AppColors.success : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isConnected
                      ? (lastUpdated != null ? 'Last sync: ${AppUtils.formatTime(lastUpdated)}' : 'BLE radio active')
                      : 'Target peripheral in standby',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Connect / Disconnect Action Button
          if (isConnected)
            OutlinedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                deviceProvider.disconnect();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(60, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('DISCONNECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            )
          else
            ElevatedButton(
              onPressed: isBusy
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      widget.onNavigateToDevices();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(64, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: isBusy
                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONNECT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  // ── D1. Temperature Sensor Card ────────────────────────────────────────────

  Widget _buildTemperatureCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    ThresholdService thresholdService,
    bool isDark,
  ) {
    final temp = deviceProvider.temperature;
    final isConnected = deviceProvider.isConnected;
    final isBreached = temp != null && temp >= thresholdService.temperatureThreshold;
    final lastUpdate = deviceProvider.lastTempUpdate;
    final readings = monitoringProvider.readings;

    final spots = <FlSpot>[];
    final recent = readings.length > 20 ? readings.sublist(readings.length - 20) : readings;
    for (int i = 0; i < recent.length; i++) {
      if (recent[i].temperature != null) {
        spots.add(FlSpot(i.toDouble(), recent[i].temperature!));
      }
    }

    return AppCard(
      borderColor: isBreached ? AppColors.error.withOpacity(0.5) : null,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accentTemperatureLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.thermostat_rounded, color: AppColors.accentTemperature, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEMPERATURE',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'DHT11 / DHT22 Sensor',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              DataQualityBadge(quality: deviceProvider.dataQuality),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Numerical Value Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temp != null ? AppUtils.formatTemperature(temp) : '--.-',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: isBreached ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '°C',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTemperature,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : (isDark ? AppColors.darkElevated : AppColors.mutedBackground),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isBreached ? AppColors.error.withOpacity(0.3) : AppColors.border,
                  ),
                ),
                child: Text(
                  'Threshold: ≤${thresholdService.temperatureThreshold.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isBreached ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Mini Sparkline Trend
          if (spots.length >= 2) ...[
            SizedBox(
              height: 48,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: AppColors.accentTemperature,
                      barWidth: 2.2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accentTemperature.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isConnected
                    ? (lastUpdate != null ? 'Synced ${AppUtils.formatRelativeTime(lastUpdate)}' : 'Awaiting stream')
                    : 'Sensor link standby',
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              Text(
                isBreached ? '⚠️ THRESHOLD EXCEEDED' : 'Normal Operating Range',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isBreached ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── D2. Humidity Sensor Card ───────────────────────────────────────────────

  Widget _buildHumidityCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    ThresholdService thresholdService,
    bool isDark,
  ) {
    final hum = deviceProvider.humidity;
    final isConnected = deviceProvider.isConnected;
    final isBreached = hum != null && hum >= thresholdService.humidityThreshold;
    final lastUpdate = deviceProvider.lastHumidityUpdate;
    final percent = hum != null ? (hum / 100.0).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      borderColor: isBreached ? AppColors.error.withOpacity(0.5) : null,
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accentHumidityLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.accentCyan, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RELATIVE HUMIDITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Capacitive Polymer Sensor',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : (isDark ? AppColors.darkElevated : AppColors.mutedBackground),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isBreached ? AppColors.error.withOpacity(0.3) : AppColors.border,
                  ),
                ),
                child: Text(
                  'Threshold: ≤${thresholdService.humidityThreshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isBreached ? AppColors.error : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Numerical Value Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hum != null ? AppUtils.formatHumidity(hum) : '--.-',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: isBreached ? AppColors.error : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentCyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Cyan Precision Level Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBreached ? AppColors.error : AppColors.accentCyan,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isConnected
                    ? (lastUpdate != null ? 'Synced ${AppUtils.formatRelativeTime(lastUpdate)}' : 'Awaiting stream')
                    : 'Sensor link standby',
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              Text(
                isBreached ? '⚠️ THRESHOLD EXCEEDED' : 'Ideal Comfort Range',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isBreached ? AppColors.error : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── D3. MQ-2 Gas Raw ADC Card ──────────────────────────────────────────────

  Widget _buildGasCard(DeviceProvider deviceProvider, bool isDark) {
    final gasAdc = deviceProvider.gasRawAdc;
    final isConnected = deviceProvider.isConnected;

    Color levelColor = AppColors.success;
    String levelText = 'LOW VOLATILE ACTIVITY';
    if (gasAdc != null) {
      if (gasAdc > 2800) {
        levelColor = AppColors.error;
        levelText = 'ELEVATED GAS DENSITY';
      } else if (gasAdc > 1800) {
        levelColor = AppColors.warning;
        levelText = 'MODERATE READING';
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
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accentGasLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.cloud_outlined, color: AppColors.accentGas, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MQ-2 / MQ-135 GAS SENSOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Raw 12-Bit Analog Output',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  isConnected && gasAdc != null ? levelText : 'RANGE: 0–4095',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: isConnected && gasAdc != null ? levelColor : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Numerical Value Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                gasAdc != null ? '$gasAdc' : '----',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'RAW ADC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentGas,
                ),
              ),
              const Spacer(),
              Text(
                gasAdc != null ? '${((gasAdc / 4095.0) * 100).toStringAsFixed(0)}% FS' : '0% FS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Explicit Scientific Transparency Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.mutedBackground,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentGas),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Raw uncalibrated 12-bit ADC counts (0–4095). Represents electrochemical sensor conductivity; not verified ppm or AQI.',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── D4. MPU6050 Motion Card ────────────────────────────────────────────────

  Widget _buildMotionCard(DeviceProvider deviceProvider, bool isDark) {
    final dev = deviceProvider.device;
    final isConnected = deviceProvider.isConnected;
    final mpuFound = dev.mpuCharFound;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.accentMotionLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.screen_rotation_rounded, color: AppColors.accentMotion, size: 20),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MPU6050 6-AXIS MOTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        'Accelerometer (g) & Gyroscope (°/s)',
                        style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: (mpuFound ? AppColors.success : AppColors.textMuted).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  mpuFound ? 'CHANNEL ACTIVE' : 'UNAVAILABLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: mpuFound ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (!isConnected || !mpuFound) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkElevated : AppColors.mutedBackground,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sensors_off_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Motion channel standby. Hardware sensor not broadcasting on current ESP32 firmware build.',
                      style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(child: _buildMiniAxisTile('ACCEL X', '${deviceProvider.accelX?.toStringAsFixed(2) ?? "--"}g', AppColors.accentMotion)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildMiniAxisTile('ACCEL Y', '${deviceProvider.accelY?.toStringAsFixed(2) ?? "--"}g', AppColors.accentMotion)),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: _buildMiniAxisTile('ACCEL Z', '${deviceProvider.accelZ?.toStringAsFixed(2) ?? "--"}g', AppColors.accentMotion)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniAxisTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 1),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── E. Quick Monitoring Controls ───────────────────────────────────────────

  Widget _buildQuickControlsSection(
    BuildContext context,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK MONITORING CONTROLS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  icon: Icons.bluetooth_searching_rounded,
                  label: 'Devices',
                  color: AppColors.primaryBlue,
                  onTap: widget.onNavigateToDevices,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.eco_rounded,
                  label: 'Environment',
                  color: AppColors.accentCyan,
                  onTap: widget.onNavigateToEnvironment,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.notifications_active_rounded,
                  label: 'Alerts',
                  color: AppColors.warning,
                  onTap: widget.onNavigateToAlerts,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionTile(
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  color: AppColors.deepNavy,
                  onTap: widget.onNavigateToSettings,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── F. Device Telemetry & Health ───────────────────────────────────────────

  Widget _buildDeviceHealthSection(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    final isConnected = deviceProvider.isConnected;
    final totalSamples = monitoringProvider.totalSamplesReceived;
    final duration = deviceProvider.device.connectionDuration;
    final interval = deviceProvider.device.samplingInterval ?? 2;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEVICE TELEMETRY & HEALTH',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.deepNavy,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : AppColors.textMuted).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  isConnected ? 'LINK ACTIVE' : 'STANDBY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isConnected ? AppColors.success : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBlock(
                  label: 'PACKETS RECEIVED',
                  value: '$totalSamples',
                  color: AppColors.deepNavy,
                ),
              ),
              Expanded(
                child: _buildTelemetryBlock(
                  label: 'SAMPLING INTERVAL',
                  value: '${interval}s',
                  color: AppColors.primaryBlue,
                ),
              ),
              Expanded(
                child: _buildTelemetryBlock(
                  label: 'LINK UPTIME',
                  value: duration != null ? AppUtils.formatDuration(duration) : (isConnected ? 'Active' : 'Offline'),
                  color: isConnected ? AppColors.success : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBlock({required String label, required String value, required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  // ── Active Audible Alarm Banner ────────────────────────────────────────────

  Widget _buildAudibleAlarmBanner(ThresholdService thresholdService, DeviceProvider deviceProvider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.criticalLight,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'THRESHOLD BREACH DETECTED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.error,
                    letterSpacing: 0.3,
                  ),
                ),
                Text(
                  'Temp: ${deviceProvider.temperature?.toStringAsFixed(1) ?? "—"}°C (Limit: ${thresholdService.temperatureThreshold}°C) • Hum: ${deviceProvider.humidity?.toStringAsFixed(1) ?? "—"}% (Limit: ${thresholdService.humidityThreshold}%)',
                  style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: widget.onNavigateToAlerts,
            child: const Text('MANAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
