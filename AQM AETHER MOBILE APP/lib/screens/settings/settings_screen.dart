// AQM AETHER — Settings & System Configuration
// Clean Modern Industrial White Interface

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/ble_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/threshold/threshold_service.dart';
import '../../services/notifications/notification_service.dart';
import '../../widgets/common/app_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _intervalSliderValue = 2;
  bool _isWritingInterval = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<DeviceProvider>().device.samplingInterval;
    if (current != null && current >= 1 && current <= 3600) {
      _intervalSliderValue = current;
    }
  }

  Future<void> _applySamplingInterval(BuildContext context, DeviceProvider provider) async {
    setState(() => _isWritingInterval = true);
    try {
      final success = await provider.setSamplingInterval(_intervalSliderValue);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                  color: success ? AppColors.normal : AppColors.critical,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  success
                      ? 'Sampling interval updated to ${_intervalSliderValue}s on ESP32'
                      : 'Failed to write interval to peripheral',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppColors.textPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isWritingInterval = false);
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        title: const Text(
          'Clear Recorded History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: const Text(
          'This will permanently delete all stored sensor readings and monitoring events from local SQLite storage. This action cannot be undone.',
          style: TextStyle(
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
            child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final settings = context.read<SettingsProvider>();
      final monitoring = context.read<MonitoringProvider>();
      await settings.clearStoredHistory();
      await monitoring.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database history cleared successfully'),
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
        child: Consumer4<DeviceProvider, MonitoringProvider, SettingsProvider, ThresholdService>(
          builder: (context, deviceProvider, monitoringProvider, settingsProvider, thresholdService, _) {
            final isConnected = deviceProvider.isConnected;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── Header ───────────────────────────────────────────────────
                _buildHeader(),

                const SizedBox(height: AppSpacing.base),

                // ── Section 1: Intelligent Threshold Configuration ───────────
                _buildThresholdConfigCard(context, thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Section 2: Audible Alarm Preferences ─────────────────────
                _buildAlarmPreferencesCard(context, thresholdService),

                const SizedBox(height: AppSpacing.base),

                // ── Section 3: Smart Android System Notifications ────────────
                _buildNotificationPreferencesCard(context),

                const SizedBox(height: AppSpacing.base),

                // ── Section 4: Sampling Interval Control ─────────────────────
                _buildIntervalConfigCard(deviceProvider, isConnected),

                const SizedBox(height: AppSpacing.base),

                // ── Section 5: Connection Reliability & Diagnostics ──────────
                _buildReliabilityMonitorCard(deviceProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Section 6: Data Persistence & Storage ────────────────────
                _buildDataPersistenceCard(context, monitoringProvider, settingsProvider),

                const SizedBox(height: AppSpacing.base),

                // ── Section 7: About AQM AETHER ──────────────────────────────
                _buildAboutCard(),

                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONFIGURATION',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Threshold limits, audio alarms & device parameters',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── 1. Threshold Configuration Card ────────────────────────────────────────

  Widget _buildThresholdConfigCard(
    BuildContext context,
    ThresholdService thresholdService,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentTemperatureLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 16, color: AppColors.accentTemperature),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'INTELLIGENT THRESHOLD ENGINE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  await thresholdService.resetToDefaults();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thresholds reset to defaults (30°C / 60%)'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 24),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accentSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Configure safety limits that trigger audible alarms and local notifications upon breach:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.base),

          // Temperature Threshold Editor
          _buildThresholdSliderTile(
            title: 'TEMPERATURE THRESHOLD',
            unit: '°C',
            value: thresholdService.temperatureThreshold,
            min: 15.0,
            max: 45.0,
            step: 0.5,
            accentColor: AppColors.accentTemperature,
            onChanged: (val) => thresholdService.setTemperatureThreshold(val),
          ),

          const Divider(height: 24, color: AppColors.borderSubtle),

          // Humidity Threshold Editor
          _buildThresholdSliderTile(
            title: 'HUMIDITY THRESHOLD',
            unit: '%',
            value: thresholdService.humidityThreshold,
            min: 20.0,
            max: 90.0,
            step: 1.0,
            accentColor: AppColors.accentHumidity,
            onChanged: (val) => thresholdService.setHumidityThreshold(val),
          ),
        ],
      ),
    );
  }

  Widget _buildThresholdSliderTile({
    required String title,
    required String unit,
    required double value,
    required double min,
    required double max,
    required double step,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: value > min ? () => onChanged(value - step) : null,
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.textSecondary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '${value.toStringAsFixed(1)} $unit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: value < max ? () => onChanged(value + step) : null,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: ((max - min) / step).round(),
          activeColor: accentColor,
          inactiveColor: AppColors.borderSubtle,
          label: '${value.toStringAsFixed(1)} $unit',
          onChanged: (val) => onChanged(double.parse(val.toStringAsFixed(1))),
        ),
      ],
    );
  }

  // ── 2. Audible Alarm Preferences Card ──────────────────────────────────────

  Widget _buildAlarmPreferencesCard(
    BuildContext context,
    ThresholdService thresholdService,
  ) {
    final isSoundOn = thresholdService.isSoundEnabled;
    final repeatSecs = thresholdService.repeatIntervalSeconds;
    final muteMins = thresholdService.muteDurationMinutes;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.criticalLight,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.volume_up_rounded, size: 16, color: AppColors.critical),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'AUDIBLE ALARM SETTINGS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await thresholdService.testAlarmSound();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testing dual-tone warning chime...'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 14),
                label: const Text('TEST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.critical),
                  foregroundColor: AppColors.critical,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(50, 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Sound Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audible Warning Chime',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Plays dual-tone alert tone when thresholds are breached',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Switch(
                value: isSoundOn,
                activeColor: AppColors.critical,
                onChanged: (val) => thresholdService.setSoundEnabled(val),
              ),
            ],
          ),

          const Divider(height: 16, color: AppColors.borderSubtle),

          // Alarm Repeat Interval
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alarm Repeat Cooldown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Minimum seconds between repeat sound warnings',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: repeatSecs,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 10, child: Text('10s')),
                  DropdownMenuItem(value: 15, child: Text('15s')),
                  DropdownMenuItem(value: 30, child: Text('30s')),
                  DropdownMenuItem(value: 60, child: Text('60s')),
                ],
                onChanged: (val) {
                  if (val != null) thresholdService.setRepeatInterval(val);
                },
              ),
            ],
          ),

          const Divider(height: 16, color: AppColors.borderSubtle),

          // Mute Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporary Mute Duration',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Duration when user taps Mute on active alarm',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: muteMins,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 5, child: Text('5 min')),
                  DropdownMenuItem(value: 15, child: Text('15 min')),
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 60, child: Text('1 hour')),
                ],
                onChanged: (val) {
                  if (val != null) thresholdService.setMuteDuration(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Smart Android Notifications Preferences Card ────────────────────────

  Widget _buildNotificationPreferencesCard(BuildContext context) {
    final notifService = NotificationService();
    final prefs = notifService.preferences;

    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) {
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.accentSecondaryLight,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(Icons.notifications_active_outlined, size: 16, color: AppColors.accentSecondary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Text(
                        'ANDROID SYSTEM NOTIFICATIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await notifService.sendTestNotification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification dispatched via Android system channel'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.send_rounded, size: 12),
                    label: const Text('TEST NOTIF', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.accentSecondary),
                      foregroundColor: AppColors.accentSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: const Size(50, 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Customize notifications across 3 dedicated Android channels (Critical Alerts, Device Status, Monitoring Updates):',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),

              // Temperature Alerts Toggle
              _buildNotifToggleRow(
                title: 'Temperature Threshold Alerts',
                subtitle: 'Channel: AQM Critical Alerts (High Priority)',
                value: prefs.enableTempAlerts,
                color: AppColors.accentTemperature,
                onChanged: (val) => prefs.setEnableTempAlerts(val),
              ),
              const Divider(height: 16, color: AppColors.borderSubtle),

              // Humidity Alerts Toggle
              _buildNotifToggleRow(
                title: 'Humidity Threshold Alerts',
                subtitle: 'Channel: AQM Critical Alerts (High Priority)',
                value: prefs.enableHumAlerts,
                color: AppColors.accentHumidity,
                onChanged: (val) => prefs.setEnableHumAlerts(val),
              ),
              const Divider(height: 16, color: AppColors.borderSubtle),

              // Device Connected Toggle
              _buildNotifToggleRow(
                title: 'Device Connected Alerts',
                subtitle: 'Channel: AQM Device Status',
                value: prefs.enableDeviceConnected,
                color: AppColors.connection,
                onChanged: (val) => prefs.setEnableDeviceConnected(val),
              ),
              const Divider(height: 16, color: AppColors.borderSubtle),

              // Device Disconnected Toggle
              _buildNotifToggleRow(
                title: 'Device Disconnected Alerts',
                subtitle: 'Channel: AQM Device Status (Anti-spam rate-limited)',
                value: prefs.enableDeviceDisconnected,
                color: AppColors.warning,
                onChanged: (val) => prefs.setEnableDeviceDisconnected(val),
              ),
              const Divider(height: 16, color: AppColors.borderSubtle),

              // Monitoring Updates Toggle
              _buildNotifToggleRow(
                title: 'Informational & System Updates',
                subtitle: 'Channel: AQM Monitoring Updates (Low Priority)',
                value: prefs.enableMonitoringUpdates,
                color: AppColors.accentAnalytics,
                onChanged: (val) => prefs.setEnableMonitoringUpdates(val),
              ),
              const SizedBox(height: AppSpacing.md),

              // System Settings Action
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tune_rounded, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    const Expanded(
                      child: Text(
                        'Android System Channel Settings',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => notifService.openAndroidSettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(60, 26),
                      ),
                      child: const Text('CONFIGURE IN ANDROID', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotifToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Switch(
          value: value,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ── 4. Sampling Interval Card ──────────────────────────────────────────────

  Widget _buildIntervalConfigCard(DeviceProvider deviceProvider, bool isConnected) {
    final activeInterval = deviceProvider.device.samplingInterval ?? 2;
    final presets = [1, 2, 5, 10, 30];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(Icons.timer_outlined, size: 16, color: AppColors.accentSecondary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'ESP32 SAMPLING INTERVAL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accentSecondaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  'ACTIVE: ${activeInterval}s',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Adjust how frequently the ESP32 samples and broadcasts sensor telemetry (1s to 3600s):',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.base),
          // Presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: presets.map((sec) {
              final isPresetSelected = _intervalSliderValue == sec;
              return InkWell(
                onTap: () => setState(() => _intervalSliderValue = sec),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPresetSelected ? AppColors.accentSecondary : AppColors.backgroundPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: isPresetSelected ? AppColors.accentSecondary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '${sec}s',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isPresetSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.base),
          // Slider
          Row(
            children: [
              const Text('1s', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Expanded(
                child: Slider(
                  value: _intervalSliderValue.toDouble().clamp(1.0, 60.0),
                  min: 1.0,
                  max: 60.0,
                  divisions: 59,
                  activeColor: AppColors.accentSecondary,
                  inactiveColor: AppColors.borderSubtle,
                  label: '${_intervalSliderValue}s',
                  onChanged: (val) => setState(() => _intervalSliderValue = val.round()),
                ),
              ),
              const Text('60s', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected: $_intervalSliderValue seconds',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton(
                onPressed: (!isConnected || _isWritingInterval)
                    ? null
                    : () => _applySamplingInterval(context, deviceProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentSecondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
                child: _isWritingInterval
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('APPLY TO ESP32', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. Reliability Monitor Card ────────────────────────────────────────────

  Widget _buildReliabilityMonitorCard(DeviceProvider provider) {
    final dev = provider.device;
    final isConnected = provider.isConnected;
    final logs = provider.diagnosticsLog;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(Icons.shield_outlined, size: 16, color: AppColors.normal),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'CONNECTION RELIABILITY & TELEMETRY',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTelemetryMetricRow('Successful Connections', '${dev.successfulConnections}'),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow(
            'Unexpected Disconnections',
            '${dev.unexpectedDisconnections}',
            valueColor: dev.unexpectedDisconnections > 0 ? AppColors.warning : AppColors.textPrimary,
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('Reconnection Attempts', '${dev.totalReconnectionAttempts}'),
          const Divider(height: 16, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow(
            'Active Link Duration',
            dev.connectionDuration != null
                ? AppUtils.formatDuration(dev.connectionDuration!)
                : (isConnected ? 'Active' : 'Offline'),
          ),
          if (dev.errorMessage != null) ...[
            const Divider(height: 16, color: AppColors.borderSubtle),
            _buildTelemetryMetricRow('Last Failure Code', dev.errorMessage!, valueColor: AppColors.critical),
          ],
          if (logs.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Text(
              'LIVE DIAGNOSTICS LOG',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                itemCount: logs.length > 10 ? 10 : logs.length,
                itemBuilder: (context, idx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(
                      logs[idx],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 6. Data Persistence Card ───────────────────────────────────────────────

  Widget _buildDataPersistenceCard(
    BuildContext context,
    MonitoringProvider monitoring,
    SettingsProvider settings,
  ) {
    final readingCount = monitoring.readings.length;
    final isPaused = monitoring.isRecordingPaused;

    return AppCard(
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
                child: const Icon(Icons.storage_rounded, size: 16, color: AppColors.accentAnalytics),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text(
                'STORAGE & DATA PERSISTENCE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Pause/Resume recording
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Record to Local SQLite',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    isPaused ? 'Data recording suspended' : 'Storing samples to device storage',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              Switch(
                value: !isPaused,
                activeColor: AppColors.accentSecondary,
                onChanged: (_) => monitoring.toggleRecordingPause(),
              ),
            ],
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          // Clear history button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Database Storage',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$readingCount sample${readingCount == 1 ? "" : "s"} indexed',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => _confirmClearHistory(context),
                icon: const Icon(Icons.delete_outline, size: 14, color: AppColors.critical),
                label: const Text('CLEAR ALL', style: TextStyle(fontSize: 10, color: AppColors.critical, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.critical),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 7. About AQM AETHER ────────────────────────────────────────────────────

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.navyLight,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.air_rounded, color: AppColors.navyPrimary, size: 20),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AQM AETHER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Smart Air Quality Monitoring System',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'AQM AETHER is an IoT environmental monitoring platform interfacing with ESP32 microcontrollers via Bluetooth Low Energy to provide real-time telemetry, threshold alerts, and persistent historical tracking.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 16, color: AppColors.borderSubtle),
          const Text(
            'SENSOR CONFIGURATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTelemetryMetricRow('DHT11 / DHT22', 'Temperature & Relative Humidity'),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('MQ-135 / MQ-2', 'Raw 12-bit ADC (0–4095)'),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('MPU6050 Module', '6-Axis Accel (g) & Gyro (°/s)'),
          const Divider(height: 16, color: AppColors.borderSubtle),
          const Text(
            'SYSTEM & BUILD INFORMATION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTelemetryMetricRow('Application Version', 'v${AppConstants.appVersion} (Production Build)'),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('Target BLE Peripheral', 'AQM-Kamalesh'),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('Data Protocol', 'ASCII Stream over BLE GATT'),
          const Divider(height: 12, color: AppColors.borderSubtle),
          _buildTelemetryMetricRow('Local Database', 'SQLite v3 (Offline Capable)'),
        ],
      ),
    );
  }

  Widget _buildTelemetryMetricRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
