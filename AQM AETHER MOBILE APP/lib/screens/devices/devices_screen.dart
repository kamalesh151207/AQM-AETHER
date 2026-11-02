// AQM AETHER — BLE Device Discovery & GATT Explorer
// Categorized Scanning: AQM AETHER Devices vs Other BLE Peripherals

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../widgets/common/app_card.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, provider, _) {
        final aqmList = provider.aqmDevices;
        final otherList = provider.otherDevices;
        final isConnected = provider.isConnected;
        final isScanning = provider.isScanning;
        final currentDev = provider.device;

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundPrimary,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.bluetooth_searching_rounded,
                      color: AppColors.accentPrimary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'BLE DEVICE LAB',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              if (isScanning)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Scan for Peripherals',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textPrimary),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    provider.startScan();
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            children: [
              // 1. Connection Status Banner
              _buildActiveStatusCard(context, provider),
              const SizedBox(height: AppSpacing.md),

              // 2. Scan Controls
              _buildScanControlBar(context, provider),
              const SizedBox(height: AppSpacing.md),

              // 3. Section: AQM AETHER DEVICE
              _buildSectionHeader(
                context,
                title: 'AQM AETHER DEVICES',
                count: aqmList.length,
                isTarget: true,
              ),
              const SizedBox(height: AppSpacing.xs),
              if (aqmList.isEmpty)
                _buildEmptyPlaceholder(
                  icon: Icons.sensors_off_rounded,
                  title: isScanning ? 'Searching for AQM peripherals…' : 'No AQM device discovered',
                  subtitle: 'Ensure the physical ESP32 is powered on, within Bluetooth range (~10m), and advertising "AQM-Kamalesh".',
                  onRetry: isScanning ? null : () => provider.startScan(),
                )
              else
                ...aqmList.map((res) => _buildAqmDeviceCard(context, provider, res)),

              const SizedBox(height: AppSpacing.lg),

              // 4. Section: OTHER BLE DEVICES
              _buildSectionHeader(
                context,
                title: 'OTHER BLE PERIPHERALS',
                count: otherList.length,
                isTarget: false,
              ),
              const SizedBox(height: AppSpacing.xs),
              if (otherList.isEmpty)
                _buildEmptyPlaceholder(
                  icon: Icons.bluetooth_rounded,
                  title: isScanning ? 'Scanning for nearby peripherals…' : 'No other BLE devices found',
                  subtitle: 'Nearby Bluetooth Low Energy devices will appear here.',
                )
              else
                ...otherList.take(25).map((res) => _buildOtherDeviceCard(context, provider, res)),

              const SizedBox(height: AppSpacing.lg),

              // 5. Section: Safe GATT Explorer View (if connected)
              if (isConnected && currentDev.discoveredServices.isNotEmpty)
                _buildGattExplorerCard(context, currentDev),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  // ── Active Status Card ───────────────────────────────────────────────────────

  Widget _buildActiveStatusCard(BuildContext context, DeviceProvider provider) {
    final dev = provider.device;
    final isConnected = provider.isConnected;
    final statusColor = isConnected ? AppColors.normal : (provider.isScanning ? AppColors.warning : AppColors.textMuted);

    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  dev.status.userMessage,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.normal.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    dev.isGenericDevice ? 'GENERIC GATT' : 'AQM LINK',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.normal,
                    ),
                  ),
                ),
            ],
          ),
          if (isConnected) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 12, color: AppColors.borderSubtle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Connected to: ${dev.name}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    provider.disconnect();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.critical,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'DISCONNECT',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
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

  // ── Scan Control Bar ────────────────────────────────────────────────────────

  Widget _buildScanControlBar(BuildContext context, DeviceProvider provider) {
    final isScanning = provider.isScanning;
    final isBtOn = provider.isBluetoothOn;

    return Column(
      children: [
        if (!isBtOn) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.criticalLight,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.critical.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bluetooth_disabled_rounded,
                    color: AppColors.critical, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Bluetooth is disabled on your phone. Please enable Bluetooth to discover nearby BLE devices.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.critical,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => provider.enableBluetooth(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.critical,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'ENABLE',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isScanning
                    ? () {
                        HapticFeedback.selectionClick();
                        provider.stopScan();
                      }
                    : () {
                        HapticFeedback.lightImpact();
                        provider.startScan();
                      },
                icon: Icon(
                  isScanning ? Icons.stop_rounded : Icons.bluetooth_searching_rounded,
                  size: 18,
                ),
                label: Text(
                  isScanning ? 'STOP SCANNING' : 'SCAN DEVICES',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isScanning ? AppColors.critical : AppColors.accentPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: isScanning
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      provider.startScan();
                    },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'REFRESH',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                side: const BorderSide(color: AppColors.borderMedium),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ),
        if (isScanning) ...[
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
            ),
          ),
        ],
      ],
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────

  Widget _buildSectionHeader(BuildContext context,
      {required String title, required int count, required bool isTarget}) {
    return Row(
      children: [
        Icon(
          isTarget ? Icons.verified_rounded : Icons.devices_other_rounded,
          size: 16,
          color: isTarget ? AppColors.accentPrimary : AppColors.textMuted,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isTarget ? AppColors.textPrimary : AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isTarget
                ? AppColors.accentPrimary.withOpacity(0.12)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isTarget ? AppColors.accentPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  // ── AQM Device Card ─────────────────────────────────────────────────────────

  Widget _buildAqmDeviceCard(
      BuildContext context, DeviceProvider provider, ScanResult result) {
    final devName = provider.resolveDeviceName(result);
    final devId = result.device.remoteId.str;
    final rssi = result.rssi;
    final isThisConnected = provider.isConnected &&
        provider.device.id == devId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: AppColors.backgroundPrimary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.air_rounded,
                      color: AppColors.accentPrimary, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        devId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildRssiBadge(rssi),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Text(
                    'SERVICE 9001 ACTIVE',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
                const Spacer(),
                if (isThisConnected)
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      provider.disconnect();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.critical.withOpacity(0.1),
                      foregroundColor: AppColors.critical,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'DISCONNECT',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      provider.connect(result.device, isAqm: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: const Text(
                      'CONNECT',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Other Device Card ───────────────────────────────────────────────────────

  Widget _buildOtherDeviceCard(
      BuildContext context, DeviceProvider provider, ScanResult result) {
    final devName = provider.resolveDeviceName(result);
    final devId = result.device.remoteId.str;
    final rssi = result.rssi;
    final isThisConnected = provider.isConnected &&
        provider.device.id == devId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: AppCard(
        color: AppColors.backgroundPrimary,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Icon(Icons.bluetooth_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    devName,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    devId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            _buildRssiBadge(rssi),
            const SizedBox(width: AppSpacing.xs),
            OutlinedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (isThisConnected) {
                  provider.disconnect();
                } else {
                  provider.connect(result.device, isAqm: false);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                side: BorderSide(
                  color: isThisConnected ? AppColors.critical : AppColors.borderMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text(
                isThisConnected ? 'LEAVE' : 'EXPLORE',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isThisConnected ? AppColors.critical : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── GATT Explorer Tree View ─────────────────────────────────────────────────

  Widget _buildGattExplorerCard(BuildContext context, DeviceModel dev) {
    return AppCard(
      color: AppColors.backgroundSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded,
                  color: AppColors.accentPrimary, size: 18),
              const SizedBox(width: AppSpacing.xs),
              const Text(
                'DISCOVERED GATT ARCHITECTURE',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Text(
                  'SAFE READ-ONLY',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Peripheral: ${dev.name} • Services: ${dev.discoveredServices.length}',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const Divider(height: 16, color: AppColors.borderSubtle),
          ...dev.discoveredServices.map((service) => _buildServiceTile(service)),
        ],
      ),
    );
  }

  Widget _buildServiceTile(DiscoveredServiceInfo service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_outlined, size: 14, color: AppColors.accentPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'SERVICE: ${service.uuid}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...service.characteristics.map((char) => _buildCharacteristicRow(char)),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacteristicRow(DiscoveredCharacteristicInfo char) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  char.uuid,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                if (char.canRead) _buildPropTag('READ', AppColors.normal),
                if (char.canWrite) _buildPropTag('WRITE', AppColors.accentSecondary),
                if (char.canNotify) _buildPropTag('NOTIFY', AppColors.accentPrimary),
                if (char.canIndicate) _buildPropTag('INDICATE', AppColors.warning),
                if (char.lastReadString != null && char.lastReadString!.isNotEmpty)
                  Text(
                    'Val: "${char.lastReadString}"',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 9,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildRssiBadge(int rssi) {
    Color color = AppColors.normal;
    if (rssi < -80) {
      color = AppColors.critical;
    } else if (rssi < -65) {
      color = AppColors.warning;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.signal_cellular_alt_rounded, size: 14, color: color),
        const SizedBox(width: 2),
        Text(
          '$rssi dBm',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg, horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 10,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text(
                'RETRY SCAN',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentPrimary,
                side: const BorderSide(color: AppColors.accentPrimary),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
