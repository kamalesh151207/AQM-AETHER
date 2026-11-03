// AQM AETHER — Industrial IoT Telemetry Dashboard
// Precision Environmental Monitoring Interface

import 'dart:async';
import 'package:flutter/material.dart';
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
  final VoidCallback onNavigateToAnalytics;
  final VoidCallback onNavigateToHistory;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onNavigateToAlerts;

  const OverviewScreen({
    super.key,
    required this.onNavigateToAnalytics,
    required this.onNavigateToHistory,
    required this.onNavigateToSettings,
    required this.onNavigateToAlerts,
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
                // ── A. TOP HEADER ────────────────────────────────────────────
                _buildTopHeader(deviceProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // Active Audio Alarm Banner (When breached)
                if (isAlarmActive) ...[
                  _buildAudibleAlarmBanner(thresholdService, deviceProvider),
                  const SizedBox(height: AppSpacing.base),
                ],

                // ── B. ENVIRONMENT OVERVIEW (HERO CARDS) ─────────────────────
                // 1. Temperature Card
                _buildTemperatureHeroCard(deviceProvider, monitoringProvider, thresholdService, isDark),
                const SizedBox(height: AppSpacing.md),

                // 2. Humidity Card
                _buildHumidityHeroCard(deviceProvider, monitoringProvider, thresholdService, isDark),
                const SizedBox(height: AppSpacing.md),

                // 3. MQ-2 Gas Raw ADC Card
                _buildGasHeroCard(deviceProvider, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── D. LIVE MONITORING & TELEMETRY STREAM ────────────────────
                _buildLiveTelemetryCard(deviceProvider, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.base),

                // ── E. QUICK DEVICE INFORMATION & CONTROLS ───────────────────
                _buildQuickDeviceCard(deviceProvider, monitoringProvider, isDark),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── A. Top Header ──────────────────────────────────────────────────────────

  Widget _buildTopHeader(DeviceProvider deviceProvider, bool isDark) {
    final status = deviceProvider.device.status;
    final isConnected = status.isConnected;
    final deviceName = deviceProvider.device.name.isNotEmpty
        ? deviceProvider.device.name
        : 'AQM-Kamalesh';

    Color statusColor;
    String statusText;
    if (isConnected) {
      statusColor = AppColors.success;
      statusText = 'CONNECTED';
    } else if (status.isActive) {
      statusColor = AppColors.warning;
      statusText = status == DeviceConnectionStatus.reconnecting ? 'RECONNECTING' : 'CONNECTING';
    } else if (status == DeviceConnectionStatus.connectionFailed || status == DeviceConnectionStatus.error) {
      statusColor = AppColors.critical;
      statusText = 'CONNECTION FAILED';
    } else {
      statusColor = isDark ? AppColors.darkTextSecondary : AppColors.textMuted;
      statusText = 'DISCONNECTED';
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Branding & Device
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.air_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AQM AETHER',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Device: $deviceName',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Connection Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 12, color: AppColors.borderSubtle),

          // Date & Time Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    AppUtils.formatDate(_now),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    AppUtils.formatTime(_now),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── B. Environment Overview Hero Cards ──────────────────────────────────────

  Widget _buildTemperatureHeroCard(
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
      borderColor: isBreached ? AppColors.critical.withOpacity(0.5) : null,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentTemperatureLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.thermostat_rounded, color: AppColors.accentTemperature, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TEMPERATURE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'DHT11 / DHT22 Sensor',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
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
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isBreached ? AppColors.critical : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '°C',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentTemperature,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Threshold: ≤${thresholdService.temperatureThreshold.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isBreached ? AppColors.critical : AppColors.primary,
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
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accentTemperature.withOpacity(0.1),
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
                    ? (lastUpdate != null ? 'Updated ${AppUtils.formatRelativeTime(lastUpdate)}' : 'Awaiting stream')
                    : 'Device offline',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                isBreached ? '⚠️ THRESHOLD EXCEEDED' : 'Normal Operating Range',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isBreached ? AppColors.critical : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHumidityHeroCard(
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
      borderColor: isBreached ? AppColors.critical.withOpacity(0.5) : null,
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentHumidityLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: AppColors.accentHumidity, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RELATIVE HUMIDITY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Capacitive Polymer Sensor',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Threshold: ≤${thresholdService.humidityThreshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isBreached ? AppColors.critical : AppColors.primary,
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
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isBreached ? AppColors.critical : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentHumidity,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Precision Level Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: isDark ? AppColors.darkBorder : AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBreached ? AppColors.critical : AppColors.accentHumidity,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isConnected
                    ? (lastUpdate != null ? 'Updated ${AppUtils.formatRelativeTime(lastUpdate)}' : 'Awaiting stream')
                    : 'Device offline',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                isBreached ? '⚠️ THRESHOLD EXCEEDED' : 'Normal Environmental Level',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isBreached ? AppColors.critical : AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGasHeroCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    final gasAdc = deviceProvider.gasRawAdc;
    final isConnected = deviceProvider.isConnected;

    Color levelColor = AppColors.success;
    String levelText = 'LOW VOLATILE ACTIVITY';
    if (gasAdc != null) {
      if (gasAdc > 2800) {
        levelColor = AppColors.critical;
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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.accentGasLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.cloud_outlined, color: AppColors.accentGas, size: 18),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MQ-2 / MQ-135 GAS SENSOR',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Raw 12-Bit Analog Output',
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
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
                    fontSize: 10,
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
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'RAW ADC',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentGas,
                ),
              ),
              const Spacer(),
              Text(
                gasAdc != null ? '${((gasAdc / 4095.0) * 100).toStringAsFixed(0)}% FS' : '0% FS',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Explicit Scientific Transparency Disclaimer
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkElevated : AppColors.elevatedSurface,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.borderSubtle),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 14, color: AppColors.accentGas),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Uncalibrated raw ADC reading. Reflects electrochemical sensor conductivity; not verified ppm or AQI.',
                    style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── D. Live Telemetry Stream ───────────────────────────────────────────────

  Widget _buildLiveTelemetryCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    final isConnected = deviceProvider.isConnected;
    final totalSamples = monitoringProvider.totalSamplesReceived;
    final duration = deviceProvider.device.connectionDuration;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, size: 18, color: AppColors.primary),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    'LIVE MONITORING & TELEMETRY STREAM',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.success.withOpacity(0.12) : AppColors.textMuted.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isConnected ? 'STREAMING ACTIVE' : 'STREAM OFFLINE',
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
                  label: 'SAMPLES RECEIVED',
                  value: '$totalSamples',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildTelemetryBlock(
                  label: 'SAMPLING INTERVAL',
                  value: '${deviceProvider.device.samplingInterval ?? 2}s',
                  color: AppColors.secondary,
                ),
              ),
              Expanded(
                child: _buildTelemetryBlock(
                  label: 'LINK DURATION',
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
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }

  // ── E. Quick Device Information & Controls ─────────────────────────────────

  Widget _buildQuickDeviceCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    bool isDark,
  ) {
    final dev = deviceProvider.device;
    final isConnected = deviceProvider.isConnected;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'QUICK DEVICE INFORMATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Text(
                isConnected ? 'GATT Ready' : 'Standby',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isConnected ? AppColors.success : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildInfoRow('Connected Device', dev.name.isNotEmpty ? dev.name : 'AQM-Kamalesh'),
          _buildInfoRow('GATT Characteristics', '${dev.discoveredServices.length} Services / 11 Chars'),
          _buildInfoRow('Primary Protocol', 'ASCII Telemetry Stream'),
          const SizedBox(height: AppSpacing.md),

          // Quick Navigation Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onNavigateToAnalytics,
                  icon: const Icon(Icons.insights_rounded, size: 16),
                  label: const Text('Analytics', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onNavigateToHistory,
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: const Text('History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onNavigateToSettings,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  // ── Active Audible Alarm Banner ────────────────────────────────────────────

  Widget _buildAudibleAlarmBanner(ThresholdService thresholdService, DeviceProvider deviceProvider) {
    return AppCard(
      color: AppColors.criticalLight,
      borderColor: AppColors.critical.withOpacity(0.5),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.critical,
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
                  'ENVIRONMENTAL THRESHOLD BREACHED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.critical,
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
            child: const Text('MANAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.critical)),
          ),
        ],
      ),
    );
  }
}
