// AQM AETHER — Alert Center & Intelligent Threshold Monitoring
// Clean Modern Industrial White Interface

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../widgets/common/app_card.dart';

enum AlertFilter {
  all('All'),
  temperature('Temperature'),
  humidity('Humidity'),
  active('Active'),
  cleared('Cleared');

  final String label;
  const AlertFilter(this.label);
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertFilter _selectedFilter = AlertFilter.all;

  Future<void> _confirmClearAlerts(
    BuildContext context,
    ThresholdService thresholdService,
    MonitoringProvider monitoringProvider,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: const Text(
          'Clear Alert Log History',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will permanently delete all stored threshold violation events and alarm activity logs. This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      thresholdService.clearAlertHistory();
      await monitoringProvider.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert log history cleared successfully'),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
            final alertHistory = thresholdService.alertHistory;

            // Apply filter
            final filteredHistory = alertHistory.where((item) {
              switch (_selectedFilter) {
                case AlertFilter.all:
                  return true;
                case AlertFilter.temperature:
                  return item.isTempExceeded;
                case AlertFilter.humidity:
                  return item.isHumExceeded;
                case AlertFilter.active:
                  return !item.isResolved;
                case AlertFilter.cleared:
                  return item.isResolved;
              }
            }).toList();

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── Header & Test Sound Action ───────────────────────────────
                _buildHeader(context, isAlarmActive, isConnected, thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Active Alert Hero Banner ─────────────────────────────────
                _buildActiveAlertHero(context, thresholdService, deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Configured Thresholds Summary ────────────────────────────
                _buildThresholdLimitsCard(thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Filter Chips ─────────────────────────────────────────────
                _buildFilterChips(alertHistory),

                const SizedBox(height: AppSpacing.md),

                // ── Chronological Alert History Log ──────────────────────────
                _buildAlertHistoryList(
                  context,
                  filteredHistory,
                  thresholdService,
                  monitoringProvider,
                ),

                const SizedBox(height: AppSpacing.base),

                // ── Honest Sensor Channel Disclaimers ────────────────────────
                _buildSensorDisclaimersCard(),

                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isAlarmActive,
    bool isConnected,
    ThresholdService thresholdService,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ALERT CENTER',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Threshold safety management & audio alarms',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        // Test Sound Button
        OutlinedButton.icon(
          onPressed: () async {
            await thresholdService.testAlarmSound();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.volume_up_rounded, color: AppColors.normal, size: 18),
                      SizedBox(width: AppSpacing.sm),
                      Text('Tested dual-tone alarm chime & haptics'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: const Icon(Icons.volume_up_rounded, size: 14, color: AppColors.textPrimary),
          label: const Text('TEST ALARM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveAlertHero(
    BuildContext context,
    ThresholdService thresholdService,
    DeviceProvider deviceProvider,
  ) {
    final isAlarmActive = thresholdService.isAlarmActive && deviceProvider.isConnected;
    final source = thresholdService.activeSource;
    final isAck = thresholdService.isUserAcknowledged;
    final isMuted = thresholdService.isMuted;

    final bannerBg = isAlarmActive ? AppColors.criticalLight : AppColors.normalLight;
    final bannerColor = isAlarmActive ? AppColors.critical : AppColors.normal;

    final temp = deviceProvider.temperature;
    final hum = deviceProvider.humidity;

    return AppCard(
      color: bannerBg,
      borderColor: bannerColor.withOpacity(0.4),
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
                  color: bannerColor,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  isAlarmActive ? Icons.notifications_active_rounded : Icons.verified_user_rounded,
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
                      isAlarmActive
                          ? (source == AlertSource.both
                              ? 'DUAL THRESHOLD BREACH'
                              : '${source.label.toUpperCase()} THRESHOLD EXCEEDED')
                          : 'OPTIMAL ENVIRONMENTAL CONDITIONS',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: bannerColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !deviceProvider.isConnected
                          ? 'Device offline — awaiting BLE link'
                          : (isAlarmActive
                              ? (isMuted ? 'Muted temporarily' : (isAck ? 'Acknowledged' : 'Audible alarm active'))
                              : 'All live telemetry values within safe boundaries'),
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
          const SizedBox(height: AppSpacing.md),
          // Comparison row
          Row(
            children: [
              Expanded(
                child: _buildParameterTile(
                  title: 'Temperature',
                  current: temp != null ? '${temp.toStringAsFixed(1)}°C' : '—',
                  threshold: 'Limit: ≤${thresholdService.temperatureThreshold}°C',
                  isExceeded: temp != null && temp >= thresholdService.temperatureThreshold,
                  accentColor: AppColors.accentTemperature,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildParameterTile(
                  title: 'Humidity',
                  current: hum != null ? '${hum.toStringAsFixed(1)}%' : '—',
                  threshold: 'Limit: ≤${thresholdService.humidityThreshold}%',
                  isExceeded: hum != null && hum >= thresholdService.humidityThreshold,
                  accentColor: AppColors.accentHumidity,
                ),
              ),
            ],
          ),
          if (isAlarmActive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (!isAck) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => thresholdService.acknowledgeAlert(),
                      icon: const Icon(Icons.check_circle_rounded, size: 14),
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
                      isMuted ? 'UNMUTE' : 'MUTE (15m)',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.critical),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.critical),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildParameterTile({
    required String title,
    required String current,
    required String threshold,
    required bool isExceeded,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: isExceeded ? Colors.white : AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isExceeded ? AppColors.critical.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(
                isExceeded ? Icons.error_rounded : Icons.check_circle_rounded,
                size: 14,
                color: isExceeded ? AppColors.critical : AppColors.normal,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            current,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isExceeded ? AppColors.critical : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            threshold,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdLimitsCard(ThresholdService thresholdService) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INTELLIGENT THRESHOLD CRITERIA',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Incoming readings are continuously checked against configured thresholds. Audible alarms and local notifications trigger immediately upon violation:',
            style: TextStyle(fontFamily: 'Manrope', fontSize: 11, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildCriterionBadge(
                  label: 'TEMP THRESHOLD',
                  value: '≥ ${thresholdService.temperatureThreshold}°C',
                  color: AppColors.accentTemperature,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildCriterionBadge(
                  label: 'HUMIDITY THRESHOLD',
                  value: '≥ ${thresholdService.humidityThreshold}%',
                  color: AppColors.accentHumidity,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(List<ThresholdAlertItem> items) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AlertFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: Colors.white,
              backgroundColor: AppColors.backgroundPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                side: BorderSide(
                  color: isSelected ? AppColors.accentAnalytics : AppColors.border,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              labelStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.accentAnalytics : AppColors.textSecondary,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAlertHistoryList(
    BuildContext context,
    List<ThresholdAlertItem> items,
    ThresholdService thresholdService,
    MonitoringProvider monitoringProvider,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Flexible(
                      child: Text(
                        'CHRONOLOGICAL ALERT AUDIT LOG',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        '${items.length} LOGGED',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (items.isNotEmpty)
                TextButton(
                  onPressed: () => _confirmClearAlerts(context, thresholdService, monitoringProvider),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 24),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Clear Log',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.critical,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (items.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.shield_outlined, size: 36, color: AppColors.normal),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'No Threshold Violations Recorded',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All environmental telemetry has remained within configured thresholds.',
                    style: TextStyle(fontFamily: 'Manrope', fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 20 ? 20 : items.length,
              separatorBuilder: (_, __) => const Divider(height: 16, color: AppColors.borderSubtle),
              itemBuilder: (context, index) {
                final item = items[index];
                final isTemp = item.source == AlertSource.temperature;
                final isBoth = item.source == AlertSource.both;
                final accent = isBoth
                    ? AppColors.critical
                    : (isTemp ? AppColors.accentTemperature : AppColors.accentHumidity);

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(
                        isBoth
                            ? Icons.warning_rounded
                            : (isTemp ? Icons.thermostat_rounded : Icons.water_drop_rounded),
                        color: accent,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${item.source.label.toUpperCase()} BREACH',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: accent,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: item.isResolved ? AppColors.normalLight : AppColors.criticalLight,
                                  borderRadius: BorderRadius.circular(AppRadius.xs),
                                ),
                                child: Text(
                                  item.isResolved ? 'CLEARED' : (item.isAcknowledged ? 'ACKNOWLEDGED' : 'ACTIVE'),
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    color: item.isResolved ? AppColors.normal : AppColors.critical,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isBoth
                                ? 'Temp ${item.measuredTemp.toStringAsFixed(1)}°C (Limit: ${item.tempThreshold}°C) • Hum ${item.measuredHum.toStringAsFixed(1)}% (Limit: ${item.humThreshold}%)'
                                : (isTemp
                                    ? 'Temp ${item.measuredTemp.toStringAsFixed(1)}°C exceeded threshold limit of ${item.tempThreshold}°C'
                                    : 'Humidity ${item.measuredHum.toStringAsFixed(1)}% exceeded threshold limit of ${item.humThreshold}%'),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppUtils.formatTime(item.timestamp),
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSensorDisclaimersCard() {
    return const AppCard(
      color: AppColors.backgroundPrimary,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.accentSecondary),
              SizedBox(width: AppSpacing.xs),
              Text(
                'SENSOR CHANNEL TRANSPARENCY',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'AQM AETHER hardware demonstration features Temperature and Humidity channels. Particulate channels (PM2.5, PM10), CO2, and VOC are simulated or reserved for future hardware revisions.',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
