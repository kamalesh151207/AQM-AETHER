// AQM AETHER — Device Lab Screen
// Technical IoT Device Configuration Console & GATT Management

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/constants/ble_constants.dart';
import '../../core/utils/app_utils.dart';
import '../../models/device_model.dart';
import '../../models/monitoring_event.dart';
import '../../providers/device_provider.dart';
import '../../providers/monitoring_provider.dart';
import '../../widgets/common/panel_container.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/common/status_badge.dart';
import '../../widgets/common/empty_state.dart';

class DeviceLabScreen extends StatefulWidget {
  const DeviceLabScreen({super.key});

  @override
  State<DeviceLabScreen> createState() => _DeviceLabScreenState();
}

class _DeviceLabScreenState extends State<DeviceLabScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _customIntervalController =
      TextEditingController();
  int? _selectedPreset;
  bool _isWritingInterval = false;
  String? _writeStatusMessage;
  bool _writeSuccess = false;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  Future<void> _handleApplyInterval(DeviceProvider deviceProvider) async {
    final text = _customIntervalController.text.trim();
    int? interval;

    if (_selectedPreset != null) {
      interval = _selectedPreset;
    } else if (text.isNotEmpty) {
      interval = int.tryParse(text);
    }

    if (interval == null) {
      _showFeedback(false, 'Please select or enter an interval in seconds');
      return;
    }

    if (interval < BleConstants.minSamplingInterval ||
        interval > BleConstants.maxSamplingInterval) {
      _showFeedback(
        false,
        'Interval must be between ${BleConstants.minSamplingInterval} and ${BleConstants.maxSamplingInterval} seconds',
      );
      return;
    }

    setState(() {
      _isWritingInterval = true;
      _writeStatusMessage = null;
    });

    HapticFeedback.mediumImpact();

    final success = await deviceProvider.writeSamplingInterval(interval);

    if (mounted) {
      setState(() {
        _isWritingInterval = false;
        _writeSuccess = success;
        _writeStatusMessage = success
            ? 'Interval confirmed: ${interval}s updated on ESP32'
            : 'Write failed: ESP32 characteristic rejected payload';
      });

      if (success) {
        _customIntervalController.clear();
        setState(() => _selectedPreset = null);
        HapticFeedback.lightImpact();
      }
    }
  }

  void _showFeedback(bool success, String message) {
    setState(() {
      _writeSuccess = success;
      _writeStatusMessage = message;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.error_outline,
              color: success ? AppColors.success : AppColors.critical,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.elevatedSurface,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Consumer2<DeviceProvider, MonitoringProvider>(
          builder: (context, deviceProvider, monitoringProvider, _) {
            final device = deviceProvider.device;
            final isConnected = device.status.isConnected;

            return ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              children: [
                _buildHeader(deviceProvider),
                const SizedBox(height: AppSpacing.lg),
                _buildDeviceDiscoveryPanel(deviceProvider),
                const SizedBox(height: AppSpacing.lg),
                if (isConnected || device.serviceFound) ...[
                  _buildGattArchitecturePanel(device),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSamplingConfigPanel(deviceProvider),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _buildDiagnosticsConsole(monitoringProvider),
                if (isConnected) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildDisconnectButton(deviceProvider),
                ],
                const SizedBox(height: AppSpacing.xxl),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(DeviceProvider deviceProvider) {
    final status = deviceProvider.device.status;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Device Lab',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'BLE Configuration Console & GATT Management',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        _buildConnectionPill(status),
      ],
    );
  }

  Widget _buildConnectionPill(DeviceConnectionStatus status) {
    Color color;
    switch (status) {
      case DeviceConnectionStatus.connected:
        color = AppColors.success;
        break;
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.discoveringServices:
      case DeviceConnectionStatus.subscribingNotifications:
      case DeviceConnectionStatus.reconnecting:
        color = AppColors.warning;
        break;
      case DeviceConnectionStatus.error:
        color = AppColors.critical;
        break;
      case DeviceConnectionStatus.scanning:
        color = AppColors.accentSecondary;
        break;
      case DeviceConnectionStatus.disconnected:
      case DeviceConnectionStatus.idle:
        color = AppColors.textMuted;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            status.label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceDiscoveryPanel(DeviceProvider deviceProvider) {
    final isScanning = deviceProvider.isScanning;
    final results = deviceProvider.scanResults;
    final isConnected = deviceProvider.isConnected;

    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Device Discovery',
                subtitle: 'Scan for Bluetooth Low Energy peripherals',
              ),
              if (isScanning)
                FadeTransition(
                  opacity: _pulseAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      'SCANNING',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (isScanning) {
                      deviceProvider.stopScan();
                    } else {
                      deviceProvider.startScan();
                    }
                  },
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: isScanning
                          ? AppColors.elevatedSurface
                          : AppColors.accentPrimary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isScanning
                            ? AppColors.border
                            : AppColors.accentPrimary.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isScanning
                              ? Icons.stop_circle_outlined
                              : Icons.radar_outlined,
                          size: 18,
                          color: isScanning
                              ? AppColors.textSecondary
                              : AppColors.accentPrimary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          isScanning ? 'STOP SCAN' : 'SCAN PERIPHERALS',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isScanning
                                ? AppColors.textSecondary
                                : AppColors.accentPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (!isConnected)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    deviceProvider.connectToAqm();
                  },
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentSecondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: AppColors.accentSecondary.withOpacity(0.6),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_connected,
                          size: 16,
                          color: AppColors.accentSecondary,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'FAST CONNECT',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (results.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.borderSubtle, width: 1),
              ),
              child: EmptyState(
                icon: isScanning
                    ? Icons.sensors_outlined
                    : Icons.bluetooth_searching,
                title: isScanning
                    ? 'Scanning for BLE signals…'
                    : 'No Peripherals Discovered',
                message: isScanning
                    ? 'Looking for "${BleConstants.deviceName}" and nearby BLE advertisers'
                    : 'Tap "SCAN PERIPHERALS" to discover nearby devices',
              ),
            )
          else
            Column(
              children: results.map((result) {
                final isAqm =
                    result.device.platformName == BleConstants.deviceName;
                final isConnecting = deviceProvider.device.status ==
                        DeviceConnectionStatus.connecting &&
                    deviceProvider.device.id == result.device.remoteId.str;
                final isCurrent = deviceProvider.isConnected &&
                    deviceProvider.device.id == result.device.remoteId.str;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isAqm
                        ? AppColors.elevatedSurface
                        : AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isAqm
                          ? AppColors.accentPrimary.withOpacity(0.5)
                          : AppColors.borderSubtle,
                      width: isAqm ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isAqm
                              ? AppColors.accentPrimary.withOpacity(0.15)
                              : AppColors.panelBackground,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAqm ? Icons.developer_board : Icons.bluetooth_audio,
                          size: 18,
                          color: isAqm
                              ? AppColors.accentPrimary
                              : AppColors.textMuted,
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
                                    result.device.platformName.isNotEmpty
                                        ? result.device.platformName
                                        : 'Unnamed Device',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isAqm
                                          ? AppColors.accentPrimary
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isAqm) ...[
                                  const SizedBox(width: AppSpacing.xs),
                                  const StatusBadge(
                                    label: 'TARGET',
                                    color: AppColors.accentPrimary,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.device.remoteId.str,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${result.rssi} dBm',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: result.rssi > -70
                                  ? AppColors.success
                                  : result.rssi > -85
                                      ? AppColors.warning
                                      : AppColors.critical,
                            ),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: isConnecting || isCurrent
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    deviceProvider.connect(result.device);
                                  },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm + 2,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.success.withOpacity(0.15)
                                    : isConnecting
                                        ? AppColors.warning.withOpacity(0.15)
                                        : AppColors.elevatedSurface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.success
                                      : isConnecting
                                          ? AppColors.warning
                                          : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: isConnecting
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.warning,
                                      ),
                                    )
                                  : Text(
                                      isCurrent ? 'CONNECTED' : 'CONNECT',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: isCurrent
                                            ? AppColors.success
                                            : AppColors.textPrimary,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildGattArchitecturePanel(DeviceModel device) {
    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'GATT Architecture & Characteristics',
            subtitle: 'Technical inspection of ESP32 custom GATT services',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildGattRow(
            name: 'Primary AQM Service',
            uuid: BleConstants.serviceUuid,
            found: device.serviceFound,
            properties: 'GATT PRIMARY',
            isPrimary: true,
          ),
          const Divider(color: AppColors.border, height: AppSpacing.lg),
          _buildGattRow(
            name: 'Temperature Characteristic',
            uuid: BleConstants.temperatureUuid,
            found: device.temperatureCharFound,
            properties: 'READ | NOTIFY',
            color: AppColors.accentTemperature,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGattRow(
            name: 'Humidity Characteristic',
            uuid: BleConstants.humidityUuid,
            found: device.humidityCharFound,
            properties: 'READ | NOTIFY',
            color: AppColors.accentHumidity,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGattRow(
            name: 'Sampling Interval Characteristic',
            uuid: BleConstants.samplingIntervalUuid,
            found: device.samplingIntervalCharFound,
            properties: 'READ | WRITE',
            color: AppColors.accentPrimary,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildGattRow(
            name: 'Alert / Alarm Characteristic',
            uuid: BleConstants.alertUuid,
            found: device.alertCharFound,
            properties: 'READ | NOTIFY (ALERT / NORMAL)',
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _buildGattRow({
    required String name,
    required String uuid,
    required bool found,
    required String properties,
    Color? color,
    bool isPrimary = false,
  }) {
    final accent = color ?? AppColors.accentPrimary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isPrimary
            ? AppColors.elevatedSurface
            : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isPrimary ? AppColors.border : AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? AppColors.textPrimary : accent,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: found ? AppColors.success : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    found ? 'DISCOVERED' : 'NOT FOUND',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: found ? AppColors.success : AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            uuid,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROPERTIES: $properties',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 12),
                color: AppColors.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: uuid));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied UUID: $uuid'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSamplingConfigPanel(DeviceProvider deviceProvider) {
    final currentInterval = deviceProvider.device.samplingInterval;

    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Sampling Configuration',
                subtitle:
                    'Configures sensor cycle time directly on ESP32 firmware',
              ),
              if (currentInterval != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(
                      color: AppColors.accentPrimary.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ACTIVE: ${currentInterval}s',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'QUICK PRESETS (SECONDS)',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: BleConstants.presetIntervals.map((preset) {
              final isSelected = _selectedPreset == preset;
              final isCurrent = currentInterval == preset;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedPreset = preset;
                    _customIntervalController.text = preset.toString();
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentPrimary
                        : isCurrent
                            ? AppColors.accentPrimary.withOpacity(0.15)
                            : AppColors.elevatedSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentPrimary
                          : isCurrent
                              ? AppColors.accentPrimary.withOpacity(0.5)
                              : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${preset}s',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.backgroundPrimary
                          : isCurrent
                              ? AppColors.accentPrimary
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.base),
          const Text(
            'CUSTOM INTERVAL (1 - 3600 SECONDS)',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customIntervalController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter interval in seconds',
                    hintStyle: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm + 2,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.accentPrimary,
                        width: 1,
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    final parsed = int.tryParse(val);
                    if (parsed != _selectedPreset) {
                      setState(() => _selectedPreset = null);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _isWritingInterval
                    ? null
                    : () => _handleApplyInterval(deviceProvider),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  decoration: BoxDecoration(
                    color: _isWritingInterval
                        ? AppColors.elevatedSurface
                        : AppColors.accentPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Center(
                    child: _isWritingInterval
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.backgroundPrimary,
                            ),
                          )
                        : const Text(
                            'APPLY CONFIG',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.backgroundPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_writeStatusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  _writeSuccess ? Icons.check_circle : Icons.error_outline,
                  size: 14,
                  color: _writeSuccess ? AppColors.success : AppColors.critical,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    _writeStatusMessage!,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _writeSuccess
                          ? AppColors.success
                          : AppColors.critical,
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

  Widget _buildDiagnosticsConsole(MonitoringProvider monitoringProvider) {
    final events = monitoringProvider.events.take(12).toList();

    return PanelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Diagnostics Console',
                subtitle: 'Low-level BLE communication trace',
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                color: AppColors.textMuted,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  monitoringProvider.clearHistory();
                },
                tooltip: 'Clear Console Log',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFF070C12),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: events.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(
                        '// Communication bus idle — awaiting peripheral events',
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: events.map((event) {
                      Color color;
                      switch (event.type) {
                        case MonitoringEventType.deviceConnected:
                        case MonitoringEventType.reconnected:
                          color = AppColors.success;
                          break;
                        case MonitoringEventType.deviceDisconnected:
                        case MonitoringEventType.error:
                          color = AppColors.critical;
                          break;
                        case MonitoringEventType.warning:
                        case MonitoringEventType.reconnecting:
                          color = AppColors.warning;
                          break;
                        case MonitoringEventType.samplingIntervalChanged:
                          color = AppColors.accentPrimary;
                          break;
                        case MonitoringEventType.readingReceived:
                          color = AppColors.accentSecondary;
                          break;
                        case MonitoringEventType.monitoringStarted:
                        case MonitoringEventType.monitoringStopped:
                          color = AppColors.textPrimary;
                          break;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppUtils.formatTime(event.timestamp),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '[${event.type.label.toUpperCase()}]',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                event.detail != null
                                    ? '${event.message} — ${event.detail}'
                                    : event.message,
                                style: const TextStyle(
                                  fontFamily: 'Courier',
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectButton(DeviceProvider deviceProvider) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.panelBackground,
            title: const Text(
              'Disconnect Peripheral?',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            content: const Text(
              'Active notifications will be stopped and BLE connection to AQM-Kamalesh terminated.',
              style: TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.textSecondary,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'DISCONNECT',
                  style: TextStyle(color: AppColors.critical),
                ),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          HapticFeedback.heavyImpact();
          await deviceProvider.disconnect();
        }
      },
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.critical.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.critical.withOpacity(0.4),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.power_settings_new,
              size: 18,
              color: AppColors.critical,
            ),
            SizedBox(width: AppSpacing.sm),
            Text(
              'DISCONNECT AQM-KAMALESH',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.critical,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
