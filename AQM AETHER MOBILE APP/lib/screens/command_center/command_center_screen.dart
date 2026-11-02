// AQM AETHER — Command Center Screen
// Main landing screen: Environmental Intelligence Dashboard

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/ble_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/device_model.dart';
import '../../models/monitoring_event.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/connection_indicator.dart';
import 'widgets/environment_status_card.dart';

class CommandCenterScreen extends StatefulWidget {
  const CommandCenterScreen({super.key});

  @override
  State<CommandCenterScreen> createState() => _CommandCenterScreenState();
}

class _CommandCenterScreenState extends State<CommandCenterScreen> {
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

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer2<DeviceProvider, MonitoringProvider>(
          builder: (context, deviceProvider, monitoringProvider, _) {
            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.base,
              ),
              children: [
                // ── Header ──────────────────────────────────────────────────
                _buildHeader(deviceProvider),

                const SizedBox(height: AppSpacing.lg),

                // ── Device Status Panel ─────────────────────────────────────
                const _SectionHeader(
                  label: 'Device Status',
                  icon: Icons.bluetooth_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildDeviceStatusPanel(deviceProvider),

                const SizedBox(height: AppSpacing.lg),

                // ── Live Environment ────────────────────────────────────────
                _SectionHeader(
                  label: 'Live Environment',
                  icon: Icons.sensors_rounded,
                  trailing: deviceProvider.isConnected
                      ? _LiveBadge()
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildLiveEnvironmentSection(deviceProvider),

                const SizedBox(height: AppSpacing.lg),

                // ── Environmental Status ────────────────────────────────────
                const _SectionHeader(
                  label: 'Environmental Status',
                  icon: Icons.shield_outlined,
                ),
                const SizedBox(height: AppSpacing.sm),
                EnvironmentStatusCard(
                  temperature: deviceProvider.temperature,
                  humidity: deviceProvider.humidity,
                  isConnected: deviceProvider.isConnected,
                  alertStatus: deviceProvider.device.alertStatus,
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── Monitoring Activity ─────────────────────────────────────
                const _SectionHeader(
                  label: 'Monitoring Activity',
                  icon: Icons.sensors_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildMonitoringPanel(deviceProvider, monitoringProvider),

                const SizedBox(height: AppSpacing.lg),

                // ── Recent Activity Timeline ────────────────────────────────
                const _SectionHeader(
                  label: 'Recent Activity',
                  icon: Icons.history_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildActivityTimeline(monitoringProvider),

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
    final timeStr = DateFormat('HH:mm:ss').format(_now);
    final dateStr = DateFormat('EEE, d MMM yyyy').format(_now);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App name + subtitle
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accentPrimary,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Environmental Intelligence',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),

        // Right side: time + date + actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                // BLE status dot
                _BleStatusDot(status: deviceProvider.device.status),
                const SizedBox(width: AppSpacing.sm),
                // Settings button
                GestureDetector(
                  onTap: _openSettings,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              timeStr,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Device Status Panel ────────────────────────────────────────────────────

  Widget _buildDeviceStatusPanel(DeviceProvider deviceProvider) {
    final device = deviceProvider.device;
    final status = device.status;
    final isActive = status.isActive || status.isConnected;

    return _PanelContainer(
      child: Column(
        children: [
          // Top row: device name + animated indicator
          Row(
            children: [
              ConnectionIndicator(status: status, size: 10),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  device.name,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: _statusColor(status).withOpacity(0.35),
                    width: 1,
                  ),
                ),
                child: Text(
                  status.label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          if (device.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.critical.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: AppColors.critical.withOpacity(0.3), width: 1),
              ),
              child: Text(
                device.errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  color: AppColors.critical,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: AppSpacing.md),

          // Detail rows
          _DeviceDetailRow(
            icon: Icons.bluetooth_rounded,
            label: 'Connection',
            value: status.isConnected ? 'CONNECTED' : 'DISCONNECTED',
            valueColor: status.isConnected ? AppColors.success : AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeviceDetailRow(
            icon: Icons.bluetooth_searching,
            label: 'Bluetooth',
            value: deviceProvider.isBluetoothOn ? 'ON' : 'OFF',
            valueColor: deviceProvider.isBluetoothOn ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeviceDetailRow(
            icon: Icons.access_time_rounded,
            label: 'Last Connected',
            value: device.lastConnectedAt != null
                ? AppUtils.formatRelativeTime(device.lastConnectedAt!)
                : 'Never',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeviceDetailRow(
            icon: Icons.update_rounded,
            label: 'Last Update',
            value: device.lastUpdatedAt != null
                ? '${AppUtils.formatTime(device.lastUpdatedAt!)} (${AppUtils.formatRelativeTime(device.lastUpdatedAt!)})'
                : '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeviceDetailRow(
            icon: Icons.timer_outlined,
            label: 'Sampling Interval',
            value: device.samplingInterval != null
                ? '${device.samplingInterval} seconds'
                : '2 seconds (default)',
          ),
          const SizedBox(height: AppSpacing.sm),
          _DeviceDetailRow(
            icon: isActive
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_unchecked_rounded,
            label: 'Monitoring',
            value: status.isConnected ? 'Active' : 'Inactive',
            valueColor:
                status.isConnected ? AppColors.success : AppColors.textMuted,
          ),
          if (!status.isConnected) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: status == DeviceConnectionStatus.connecting ||
                        status == DeviceConnectionStatus.scanning ||
                        status == DeviceConnectionStatus.discoveringServices
                    ? null
                    : () {
                        if (!deviceProvider.isBluetoothOn) {
                          deviceProvider.enableBluetooth();
                        } else {
                          deviceProvider.connectToAqm();
                        }
                      },
                icon: Icon(
                  !deviceProvider.isBluetoothOn
                      ? Icons.bluetooth_disabled
                      : Icons.bluetooth_searching,
                  size: 16,
                ),
                label: Text(
                  !deviceProvider.isBluetoothOn
                      ? 'ENABLE BLUETOOTH'
                      : status == DeviceConnectionStatus.scanning
                          ? 'SCANNING FOR AQM-KAMALESH...'
                          : status == DeviceConnectionStatus.connecting ||
                                  status == DeviceConnectionStatus.discoveringServices
                              ? 'CONNECTING TO AQM-KAMALESH...'
                              : (status == DeviceConnectionStatus.error
                                  ? 'RETRY CONNECTION TO AQM-KAMALESH'
                                  : 'CONNECT TO AQM-KAMALESH'),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary.withOpacity(0.15),
                  foregroundColor: AppColors.accentPrimary,
                  side: const BorderSide(color: AppColors.accentPrimary, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Live Environment ───────────────────────────────────────────────────────

  Widget _buildLiveEnvironmentSection(DeviceProvider deviceProvider) {
    return Row(
      children: [
        Expanded(
          child: _SensorCard(
            label: 'Temperature',
            value: deviceProvider.temperature != null
                ? AppUtils.formatTemperature(deviceProvider.temperature!)
                : '—',
            unit: deviceProvider.temperature != null ? '°C' : '',
            color: deviceProvider.temperature != null
                ? AppColors.accentTemperature
                : AppColors.textMuted,
            icon: Icons.thermostat_rounded,
            lastUpdate: deviceProvider.lastTempUpdate,
            isStale: deviceProvider.isTemperatureStale,
            isConnected: deviceProvider.isConnected,
            trend: _computeTrend(deviceProvider, isTempRequest: true),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _SensorCard(
            label: 'Humidity',
            value: deviceProvider.humidity != null
                ? AppUtils.formatHumidity(deviceProvider.humidity!)
                : '—',
            unit: deviceProvider.humidity != null ? '%' : '',
            color: deviceProvider.humidity != null
                ? AppColors.accentHumidity
                : AppColors.textMuted,
            icon: Icons.water_drop_rounded,
            lastUpdate: deviceProvider.lastHumidityUpdate,
            isStale: deviceProvider.isHumidityStale,
            isConnected: deviceProvider.isConnected,
            trend: _computeTrend(deviceProvider, isTempRequest: false),
          ),
        ),
      ],
    );
  }

  /// Trivial trend from the last two sensor readings in MonitoringProvider.
  /// Pass `isTempRequest = true` for temperature trend, `false` for humidity.
  _TrendDirection _computeTrend(
    DeviceProvider deviceProvider, {
    required bool isTempRequest,
  }) {
    final mp = Provider.of<MonitoringProvider>(context, listen: false);
    if (mp.readings.length < 2) return _TrendDirection.stable;

    final recent = mp.readings.reversed.toList();
    final r1 = recent[0];
    final r2 = recent[1];

    final double? v1 = isTempRequest ? r1.temperature : r1.humidity;
    final double? v2 = isTempRequest ? r2.temperature : r2.humidity;

    if (v1 == null || v2 == null) return _TrendDirection.stable;
    if (v1 > v2 + 0.2) return _TrendDirection.up;
    if (v1 < v2 - 0.2) return _TrendDirection.down;
    return _TrendDirection.stable;
  }

  // ── Monitoring Panel ───────────────────────────────────────────────────────

  Widget _buildMonitoringPanel(
    DeviceProvider deviceProvider,
    MonitoringProvider monitoringProvider,
  ) {
    final started = monitoringProvider.monitoringStartedAt;
    final duration = started != null
        ? AppUtils.formatDuration(DateTime.now().difference(started))
        : '—';
    final interval = deviceProvider.device.samplingInterval;

    return _PanelContainer(
      child: Column(
        children: [
          _MonitoringRow(
            icon: Icons.stacked_bar_chart_rounded,
            label: 'Total Samples',
            value: monitoringProvider.totalSamplesReceived.toString(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MonitoringRow(
            icon: Icons.timer_outlined,
            label: 'Sampling Interval',
            value: interval != null
                ? AppUtils.formatSamplingInterval(interval)
                : '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MonitoringRow(
            icon: Icons.hourglass_bottom_rounded,
            label: 'Monitoring Duration',
            value: duration,
          ),
          const SizedBox(height: AppSpacing.sm),
          _MonitoringRow(
            icon: Icons.access_time_rounded,
            label: 'Last Update',
            value: deviceProvider.device.lastUpdatedAt != null
                ? AppUtils.formatRelativeTime(deviceProvider.device.lastUpdatedAt!)
                : '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _MonitoringRow(
            icon: Icons.sensors_rounded,
            label: 'Sensor Availability',
            value: deviceProvider.isConnected
                ? (deviceProvider.device.temperatureCharFound &&
                        deviceProvider.device.humidityCharFound
                    ? 'Temperature · Humidity'
                    : 'Partial')
                : 'Unavailable',
            valueColor: deviceProvider.isConnected
                ? AppColors.success
                : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  // ── Activity Timeline ──────────────────────────────────────────────────────

  Widget _buildActivityTimeline(MonitoringProvider monitoringProvider) {
    final events = monitoringProvider.events.take(5).toList();

    if (events.isEmpty) {
      return const _PanelContainer(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Column(
              children: [
                Icon(Icons.timeline_rounded,
                    size: 32, color: AppColors.textMuted),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'No activity recorded',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'Events will appear here once the device connects.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _PanelContainer(
      child: Column(
        children: [
          for (int i = 0; i < events.length; i++) ...[
            _ActivityEventRow(event: events[i]),
            if (i < events.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Container(
                  height: 1,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _statusColor(DeviceConnectionStatus status) {
    switch (status) {
      case DeviceConnectionStatus.connected:
        return AppColors.success;
      case DeviceConnectionStatus.reconnecting:
        return AppColors.warning;
      case DeviceConnectionStatus.error:
        return AppColors.critical;
      case DeviceConnectionStatus.scanning:
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.discoveringServices:
      case DeviceConnectionStatus.subscribingNotifications:
        return AppColors.accentSecondary;
      case DeviceConnectionStatus.disconnected:
      case DeviceConnectionStatus.idle:
        return AppColors.textMuted;
    }
  }
}

// ── Section Header ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.label,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.accentPrimary),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.accentPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Panel Container ────────────────────────────────────────────────────────────

class _PanelContainer extends StatelessWidget {
  final Widget child;

  const _PanelContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: child,
    );
  }
}

// ── BLE Status Dot ─────────────────────────────────────────────────────────────

class _BleStatusDot extends StatelessWidget {
  final DeviceConnectionStatus status;

  const _BleStatusDot({required this.status});

  Color get _color {
    switch (status) {
      case DeviceConnectionStatus.connected:
        return AppColors.success;
      case DeviceConnectionStatus.reconnecting:
        return AppColors.warning;
      case DeviceConnectionStatus.error:
        return AppColors.critical;
      default:
        return AppColors.textMuted;
    }
  }

  String get _label {
    switch (status) {
      case DeviceConnectionStatus.connected:
        return 'BLE';
      case DeviceConnectionStatus.reconnecting:
        return 'BLE';
      case DeviceConnectionStatus.error:
        return 'ERR';
      default:
        return 'BLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Live Badge ─────────────────────────────────────────────────────────────────

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
            color: AppColors.success.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'LIVE',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device Detail Row ──────────────────────────────────────────────────────────

class _DeviceDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DeviceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

// ── Sensor Card ────────────────────────────────────────────────────────────────

enum _TrendDirection { up, down, stable }

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;
  final DateTime? lastUpdate;
  final bool isStale;
  final bool isConnected;
  final _TrendDirection trend;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
    required this.lastUpdate,
    required this.isStale,
    required this.isConnected,
    required this.trend,
  });

  IconData get _trendIcon {
    switch (trend) {
      case _TrendDirection.up:
        return Icons.trending_up_rounded;
      case _TrendDirection.down:
        return Icons.trending_down_rounded;
      case _TrendDirection.stable:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = isConnected && value != '—';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: hasValue ? color.withOpacity(0.25) : AppColors.border,
          width: 1,
        ),
        gradient: hasValue
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.06),
                  AppColors.panelBackground,
                ],
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row with icon
          Row(
            children: [
              Icon(icon, size: 13, color: hasValue ? color : AppColors.textMuted),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: hasValue ? color.withOpacity(0.8) : AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // Simulated badge
              if (hasValue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: const Text(
                    'SIM',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Main value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    color: hasValue ? color : AppColors.textMuted,
                    letterSpacing: -1.5,
                    height: 1.0,
                  ),
                ),
              ),
              if (unit.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: hasValue ? color.withOpacity(0.7) : AppColors.textMuted,
                    ),
                  ),
                ),
              const Spacer(),
              if (hasValue)
                Icon(
                  _trendIcon,
                  size: 16,
                  color: color.withOpacity(0.6),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Status / Last update
          if (!isConnected)
            const Text(
              'No Signal',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            )
          else if (lastUpdate != null)
            Text(
              isStale
                  ? 'Stale · ${AppUtils.formatRelativeTime(lastUpdate!)}'
                  : AppUtils.formatRelativeTime(lastUpdate!),
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                color: isStale ? AppColors.warning : AppColors.textMuted,
              ),
            )
          else
            const Text(
              'Awaiting reading…',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Monitoring Row ─────────────────────────────────────────────────────────────

class _MonitoringRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _MonitoringRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
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

// ── Activity Event Row ─────────────────────────────────────────────────────────

class _ActivityEventRow extends StatelessWidget {
  final MonitoringEvent event;

  const _ActivityEventRow({required this.event});

  Color _eventColor(MonitoringEventType type) {
    switch (type) {
      case MonitoringEventType.deviceConnected:
      case MonitoringEventType.monitoringStarted:
      case MonitoringEventType.reconnected:
        return AppColors.success;
      case MonitoringEventType.deviceDisconnected:
      case MonitoringEventType.monitoringStopped:
        return AppColors.textMuted;
      case MonitoringEventType.reconnecting:
      case MonitoringEventType.warning:
        return AppColors.warning;
      case MonitoringEventType.error:
        return AppColors.critical;
      case MonitoringEventType.readingReceived:
        return AppColors.accentPrimary;
      case MonitoringEventType.samplingIntervalChanged:
        return AppColors.accentSecondary;
    }
  }

  IconData _eventIcon(MonitoringEventType type) {
    switch (type) {
      case MonitoringEventType.deviceConnected:
        return Icons.bluetooth_connected_rounded;
      case MonitoringEventType.deviceDisconnected:
        return Icons.bluetooth_disabled_rounded;
      case MonitoringEventType.monitoringStarted:
        return Icons.play_circle_outline_rounded;
      case MonitoringEventType.monitoringStopped:
        return Icons.stop_circle_outlined;
      case MonitoringEventType.readingReceived:
        return Icons.sensors_rounded;
      case MonitoringEventType.samplingIntervalChanged:
        return Icons.timer_outlined;
      case MonitoringEventType.warning:
        return Icons.warning_amber_rounded;
      case MonitoringEventType.error:
        return Icons.error_outline_rounded;
      case MonitoringEventType.reconnecting:
        return Icons.sync_rounded;
      case MonitoringEventType.reconnected:
        return Icons.check_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _eventColor(event.type);
    final icon = _eventIcon(event.type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    event.type.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    AppUtils.formatRelativeTime(event.timestamp),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                event.message,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              if (event.detail != null) ...[
                const SizedBox(height: 1),
                Text(
                  event.detail!,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
