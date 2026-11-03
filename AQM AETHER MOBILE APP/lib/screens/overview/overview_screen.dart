// AQM AETHER — Overview Dashboard
// Premium Industrial Environmental Intelligence Platform

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
  final VoidCallback onNavigateToLive;
  final VoidCallback onNavigateToSettings;
  final VoidCallback onNavigateToAlerts;

  const OverviewScreen({
    super.key,
    required this.onNavigateToLive,
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
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
                // ── App Header ───────────────────────────────────────────────
                _buildHeader(deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Active Audio Alarm Banner (When Threshold Exceeded) ───────
                if (isAlarmActive) ...[
                  _buildAudibleAlarmBanner(thresholdService, deviceProvider),
                  const SizedBox(height: AppSpacing.base),
                ],

                // ── Central Environmental Status Component ───────────────────
                _buildEnvironmentalStatusCard(thresholdService, deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Connection & Quick Control Bar ───────────────────────────
                _buildConnectionBanner(deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Hero Sensor Cards (Temperature & Humidity) ───────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTemperatureCard(
                        deviceProvider,
                        monitoringProvider,
                        thresholdService,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildHumidityCard(
                        deviceProvider,
                        monitoringProvider,
                        thresholdService,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // ── Hero Sensor Cards Row 2 (Gas & Motion Preview) ───────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildGasPreviewCard(deviceProvider),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildMotionPreviewCard(deviceProvider),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.base),

                // ── Quick Actions Grid ───────────────────────────────────────
                _buildQuickActions(deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Device Health & Telemetry Metrics ────────────────────────
                _buildDeviceHealthCard(deviceProvider, monitoringProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Quick Insights Banner ────────────────────────────────────
                _buildSmartInsightsCard(monitoringProvider),

                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(DeviceProvider deviceProvider) {
    final isConnected = deviceProvider.isConnected;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isConnected ? AppColors.connection : AppColors.textMuted,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isConnected ? AppColors.connection : AppColors.textMuted)
                              .withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'AQM AETHER',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Intelligent Environmental Monitoring',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppUtils.formatTime(_now),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppUtils.formatDate(_now),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 9,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Active Audible Alarm Banner ────────────────────────────────────────────

  Widget _buildAudibleAlarmBanner(
    ThresholdService thresholdService,
    DeviceProvider deviceProvider,
  ) {
    final source = thresholdService.activeSource;
    final isAck = thresholdService.isUserAcknowledged;
    final isMuted = thresholdService.isMuted;

    String bannerTitle = 'CRITICAL THRESHOLD EXCEEDED';
    if (source == AlertSource.both) {
      bannerTitle = 'DUAL THRESHOLD ALARM (TEMP & HUMIDITY)';
    } else if (source == AlertSource.temperature) {
      bannerTitle = 'TEMPERATURE THRESHOLD ALARM';
    } else if (source == AlertSource.humidity) {
      bannerTitle = 'HUMIDITY THRESHOLD ALARM';
    }

    final measuredTemp = deviceProvider.temperature?.toStringAsFixed(1) ?? '—';
    final measuredHum = deviceProvider.humidity?.toStringAsFixed(1) ?? '—';

    return AppCard(
      color: AppColors.criticalLight,
      borderColor: AppColors.critical.withOpacity(0.5),
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.critical,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bannerTitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.critical,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isMuted
                          ? 'Audible tone muted temporarily'
                          : (isAck ? 'Alarm sound acknowledged' : 'Audible warning sounding continuously'),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Measured Values: Temp $measuredTemp°C (Limit: ${thresholdService.temperatureThreshold}°C) • Hum $measuredHum% (Limit: ${thresholdService.humidityThreshold}%)',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Actions: Acknowledge, Mute, View Details
          Row(
            children: [
              if (!isAck) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => thresholdService.acknowledgeAlert(),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('ACKNOWLEDGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.critical,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => isMuted
                      ? thresholdService.unmuteAlert()
                      : thresholdService.muteAlert(const Duration(minutes: 15)),
                  icon: Icon(
                    isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                    size: 14,
                    color: AppColors.critical,
                  ),
                  label: Text(
                    isMuted ? 'UNMUTE' : 'MUTE 15M',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.critical),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.critical),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: widget.onNavigateToAlerts,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Text('DETAILS', style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.textPrimary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Central Environmental Status Card ──────────────────────────────────────

  Widget _buildEnvironmentalStatusCard(
    ThresholdService thresholdService,
    DeviceProvider deviceProvider,
  ) {
    final temp = deviceProvider.temperature;
    final hum = deviceProvider.humidity;
    final isConnected = deviceProvider.isConnected;

    Color statusColor = AppColors.textMuted;
    Color statusBg = AppColors.elevatedSurface;
    String statusTitle = 'OFFLINE';
    String statusDesc = 'Connect to AQM-Kamalesh to monitor live environmental baseline.';
    IconData statusIcon = Icons.sensors_off_rounded;

    if (isConnected && temp != null && hum != null) {
      final isTempCrit = temp >= thresholdService.temperatureThreshold;
      final isHumCrit = hum >= thresholdService.humidityThreshold;
      final isTempWarn = temp >= (thresholdService.temperatureThreshold - 2.0);
      final isHumWarn = hum >= (thresholdService.humidityThreshold - 5.0);

      if (isTempCrit || isHumCrit) {
        statusColor = AppColors.critical;
        statusBg = AppColors.criticalLight;
        statusTitle = 'CRITICAL STATUS';
        statusDesc = 'Environmental threshold breached. Immediate inspection or ventilation required.';
        statusIcon = Icons.warning_rounded;
      } else if (isTempWarn || isHumWarn) {
        statusColor = AppColors.warning;
        statusBg = AppColors.warningLight;
        statusTitle = 'WARNING STATUS';
        statusDesc = 'Telemetry approaching designated thresholds (${thresholdService.temperatureThreshold}°C / ${thresholdService.humidityThreshold}%).';
        statusIcon = Icons.error_outline_rounded;
      } else {
        statusColor = AppColors.normal;
        statusBg = AppColors.normalLight;
        statusTitle = 'NORMAL STATUS';
        statusDesc = 'All environmental parameters remain within optimal calibrated boundaries.';
        statusIcon = Icons.verified_rounded;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENVIRONMENTAL STATE',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  isConnected ? 'LIVE' : 'STANDBY',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            statusDesc,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Connection Banner ──────────────────────────────────────────────────────

  Widget _buildConnectionBanner(DeviceProvider deviceProvider) {
    final status = deviceProvider.device.status;
    final isConnected = status.isConnected;
    final isBtOn = deviceProvider.isBluetoothOn;

    Color badgeColor;
    Color badgeBg;
    if (isConnected) {
      badgeColor = AppColors.success;
      badgeBg = AppColors.successLight;
    } else if (status.isActive) {
      badgeColor = AppColors.warning;
      badgeBg = AppColors.warningLight;
    } else {
      badgeColor = AppColors.textMuted;
      badgeBg = AppColors.elevatedSurface;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: badgeColor.withOpacity(0.3)),
            ),
            child: Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
              size: 20,
              color: badgeColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        deviceProvider.device.name,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        status.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  !isBtOn
                      ? 'Bluetooth is disabled on your phone'
                      : ((status == DeviceConnectionStatus.error || status == DeviceConnectionStatus.connectionFailed) &&
                              deviceProvider.device.errorMessage != null
                          ? deviceProvider.device.errorMessage!
                          : status.userMessage),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: !isBtOn ||
                            status == DeviceConnectionStatus.error ||
                            status == DeviceConnectionStatus.connectionFailed
                        ? AppColors.critical
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Action Button
          if (!isBtOn)
            ElevatedButton(
              onPressed: () => deviceProvider.enableBluetooth(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              child: const Text('ENABLE BT', style: TextStyle(fontSize: 10)),
            )
          else if (!isConnected)
            ElevatedButton(
              onPressed: status.isActive ? null : () => deviceProvider.connectToAqm(),
              style: ElevatedButton.styleFrom(
                backgroundColor: (status == DeviceConnectionStatus.error ||
                        status == DeviceConnectionStatus.connectionFailed)
                    ? AppColors.critical
                    : AppColors.accentPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text(
                status.isActive
                    ? 'CONNECTING…'
                    : ((status == DeviceConnectionStatus.error ||
                            status == DeviceConnectionStatus.connectionFailed)
                        ? 'RETRY'
                        : 'CONNECT'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => deviceProvider.disconnect(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
              ),
              child: const Text('DISCONNECT', style: TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  // ── Temperature Card ───────────────────────────────────────────────────────

  Widget _buildTemperatureCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    ThresholdService thresholdService,
  ) {
    final temp = deviceProvider.temperature;
    final quality = deviceProvider.dataQuality;
    final readings = monitoringProvider.readings;
    final isBreached = temp != null && temp >= thresholdService.temperatureThreshold;

    // Mini sparkline data points
    final recent = readings.length > 15
        ? readings.sublist(readings.length - 15)
        : readings;
    final spots = <FlSpot>[];
    for (int i = 0; i < recent.length; i++) {
      if (recent[i].temperature != null) {
        spots.add(FlSpot(i.toDouble(), recent[i].temperature!));
      }
    }

    // Trend calculation
    String trendStr = '→ Stable';
    if (recent.length >= 2) {
      final first = recent.first.temperature ?? 0;
      final last = recent.last.temperature ?? 0;
      final diff = last - first;
      if (diff >= 0.2) trendStr = '↗ +${diff.toStringAsFixed(1)}°C';
      if (diff <= -0.2) trendStr = '↘ ${diff.toStringAsFixed(1)}°C';
    }

    return AppCard(
      borderColor: isBreached ? AppColors.critical.withOpacity(0.5) : AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentTemperatureLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.thermostat_rounded,
                  size: 18,
                  color: AppColors.accentTemperature,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: DataQualityBadge(quality: quality),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'TEMPERATURE',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                temp != null ? AppUtils.formatTemperature(temp) : '—',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isBreached ? AppColors.critical : AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '°C',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentTemperature,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  trendStr,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '≤${thresholdService.temperatureThreshold.toStringAsFixed(0)}°C',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isBreached ? AppColors.critical : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Mini sparkline chart
          if (spots.length >= 2)
            SizedBox(
              height: 32,
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
                        color: AppColors.accentTemperatureLight.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 32,
              alignment: Alignment.centerLeft,
              child: const Text(
                'Awaiting telemetry…',
                style: TextStyle(fontFamily: 'Manrope', fontSize: 10, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }

  // ── Humidity Card ──────────────────────────────────────────────────────────

  Widget _buildHumidityCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
    ThresholdService thresholdService,
  ) {
    final hum = deviceProvider.humidity;
    final quality = deviceProvider.dataQuality;
    final isBreached = hum != null && hum >= thresholdService.humidityThreshold;
    final percentValue = hum != null ? (hum / 100.0).clamp(0.0, 1.0) : 0.0;

    return AppCard(
      borderColor: isBreached ? AppColors.critical.withOpacity(0.5) : AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentHumidityLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  size: 18,
                  color: AppColors.accentHumidity,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: DataQualityBadge(quality: quality),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'HUMIDITY',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                hum != null ? AppUtils.formatHumidity(hum) : '—',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isBreached ? AppColors.critical : AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '%',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentHumidity,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Relative',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isBreached ? AppColors.criticalLight : AppColors.elevatedSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  '≤${thresholdService.humidityThreshold.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: isBreached ? AppColors.critical : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Humidity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: percentValue,
              minHeight: 6,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                isBreached ? AppColors.critical : AppColors.accentHumidity,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(
            deviceProvider.lastHumidityUpdate != null
                ? 'Updated ${AppUtils.formatRelativeTime(deviceProvider.lastHumidityUpdate!)}'
                : 'Awaiting first sample',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ── MQ-135 Gas RAW ADC Preview Card ─────────────────────────────────────────

  Widget _buildGasPreviewCard(DeviceProvider deviceProvider) {
    final gasAdc = deviceProvider.gasRawAdc;
    final isConnected = deviceProvider.isConnected;

    Color color = AppColors.normal;
    if (gasAdc != null) {
      if (gasAdc > 2800) {
        color = AppColors.critical;
      } else if (gasAdc > 1800) {
        color = AppColors.warning;
      }
    }

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accentSecondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.cloud_outlined,
                  size: 18,
                  color: AppColors.accentSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Text(
                  '0-4095',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'GAS RAW ADC',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                gasAdc != null ? '$gasAdc' : '—',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isConnected && gasAdc != null ? color : AppColors.textPrimary,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'ADC',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            deviceProvider.device.gasCharFound
                ? 'MQ-2 / MQ-135 telemetry active'
                : 'Raw ADC stream (GPIO 34)',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── MPU6050 Motion Preview Card ─────────────────────────────────────────────

  Widget _buildMotionPreviewCard(DeviceProvider deviceProvider) {
    final mpuFound = deviceProvider.device.mpuCharFound;
    final mag = deviceProvider.motionMagnitude;
    final isConnected = deviceProvider.isConnected;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (mpuFound ? AppColors.accentPrimary : AppColors.warning).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  mpuFound ? Icons.screen_rotation_rounded : Icons.sensors_off_rounded,
                  size: 18,
                  color: mpuFound ? AppColors.accentPrimary : AppColors.warning,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: (mpuFound ? AppColors.normal : AppColors.surfaceVariant).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  mpuFound ? '6-AXIS' : 'INACTIVE',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: mpuFound ? AppColors.normal : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'MPU6050 MOTION',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          if (!isConnected || !mpuFound) ...[
            const Text(
              'NOT AVAILABLE',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textMuted,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Firmware char absent',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  mag != null ? mag.toStringAsFixed(2) : '—',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'g',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              deviceProvider.motionState,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // ── Quick Actions Grid ─────────────────────────────────────────────────────

  Widget _buildQuickActions(DeviceProvider deviceProvider) {
    final isConnected = deviceProvider.isConnected;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK MONITORING CONTROLS',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _buildActionButton(
                icon: isConnected ? Icons.link_off_rounded : Icons.bluetooth_searching_rounded,
                label: isConnected ? 'Disconnect' : 'Connect',
                color: isConnected ? AppColors.critical : AppColors.connection,
                onTap: isConnected ? () => deviceProvider.disconnect() : () => deviceProvider.connectToAqm(),
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildActionButton(
                icon: Icons.query_stats_rounded,
                label: 'Live Stream',
                color: AppColors.accentHumidity,
                onTap: widget.onNavigateToLive,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildActionButton(
                icon: Icons.tune_rounded,
                label: 'Thresholds',
                color: AppColors.accentTemperature,
                onTap: widget.onNavigateToSettings,
              ),
              const SizedBox(width: AppSpacing.sm),
              _buildActionButton(
                icon: Icons.notifications_none_rounded,
                label: 'Alert Center',
                color: AppColors.accentAnalytics,
                onTap: widget.onNavigateToAlerts,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
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
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Device Health Card ─────────────────────────────────────────────────────

  Widget _buildDeviceHealthCard(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
  ) {
    final device = deviceProvider.device;
    final isConnected = deviceProvider.isConnected;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'DEVICE TELEMETRY & HEALTH',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: widget.onNavigateToSettings,
                child: const Text(
                  'Configure',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _HealthMetricRow(
            label: 'Connection State',
            value: device.status.label,
            valueColor: AppUtils.statusColor(device.status.label),
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _HealthMetricRow(
            label: 'Device Peripheral',
            value: device.name,
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _HealthMetricRow(
            label: 'Sampling Interval',
            value: device.samplingInterval != null
                ? '${device.samplingInterval}s'
                : '2s (firmware default)',
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _HealthMetricRow(
            label: 'Total Samples Logged',
            value: '${monitoringProvider.totalSamplesReceived} samples',
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _HealthMetricRow(
            label: 'Active Link Duration',
            value: device.connectionDuration != null
                ? AppUtils.formatDuration(device.connectionDuration!)
                : (isConnected ? 'Active' : 'Offline'),
          ),
        ],
      ),
    );
  }

  // ── Smart Insights Card ────────────────────────────────────────────────────

  Widget _buildSmartInsightsCard(MonitoringProvider monitoringProvider) {
    final insights = monitoringProvider.smartInsights;

    return AppCard(
      borderColor: AppColors.accentAnalytics.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.accentAnalyticsLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.accentAnalytics,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'SMART DATA INSIGHTS',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...insights.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(
                      Icons.circle,
                      size: 5,
                      color: AppColors.accentAnalytics,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HealthMetricRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
