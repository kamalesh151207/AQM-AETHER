// AQM AETHER — BLE Device Discovery & GATT Explorer
// Categorized Discovery: AQM-Compatible Devices vs Other Nearby BLE Peripherals

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/theme/app_theme.dart';
import '../../models/device_model.dart';
import '../../providers/device_provider.dart';
import '../../widgets/common/app_card.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: 'Scan Again',
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
              // 1. Bluetooth Adapter Disabled Warning
              if (!provider.isBluetoothOn) ...[
                _buildBluetoothDisabledBanner(context, provider),
                const SizedBox(height: AppSpacing.sm),
              ],

              // 2. Connection Status Banner
              _buildActiveStatusCard(context, provider),
              const SizedBox(height: AppSpacing.md),

              // 3. Scan Control Toolbar & Search Filter
              _buildScanControlBar(context, provider),
              const SizedBox(height: AppSpacing.md),

              // 4. Section: AQM-Compatible Devices
              _buildSectionHeader(
                context,
                title: 'AQM-COMPATIBLE DEVICES',
                count: aqmList.length,
                isTarget: true,
                tooltip: 'Peripherals advertising Service UUID ...9001 or named AQM-Kamalesh',
              ),
              const SizedBox(height: AppSpacing.xs),
              if (aqmList.isEmpty)
                _buildEmptyPlaceholder(
                  icon: Icons.sensors_off_rounded,
                  title: isScanning
                      ? 'Searching for AQM peripherals…'
                      : 'No AQM device discovered in range',
                  subtitle:
                      'Ensure your ESP32 is powered on, advertising, and within Bluetooth range (~10m).',
                  onRetry: isScanning ? null : () => provider.startScan(),
                )
              else
                ...aqmList.map((res) => _buildDeviceCard(context, provider, res, isAqm: true)),

              const SizedBox(height: AppSpacing.lg),

              // 5. Section: Other Nearby BLE Devices
              _buildSectionHeader(
                context,
                title: 'OTHER NEARBY BLE DEVICES',
                count: otherList.length,
                isTarget: false,
                tooltip: 'All other discoverable Bluetooth Low Energy peripherals in range',
              ),
              const SizedBox(height: AppSpacing.xs),
              if (otherList.isEmpty)
                _buildEmptyPlaceholder(
                  icon: Icons.bluetooth_rounded,
                  title: isScanning
                      ? 'Scanning for nearby peripherals…'
                      : 'No other BLE devices discovered',
                  subtitle:
                      'Other broadcasting BLE devices (friend\'s device, smartwatch, beacons) will appear here.',
                )
              else
                ...otherList.take(30).map((res) => _buildDeviceCard(context, provider, res, isAqm: false)),

              const SizedBox(height: AppSpacing.md),

              // 6. Educational Note on BLE Advertising
              _buildBleAdvertisingNoticeCard(),
              const SizedBox(height: AppSpacing.lg),

              // 7. Section: Safe GATT Explorer View (when connected)
              if (isConnected && currentDev.discoveredServices.isNotEmpty)
                _buildGattExplorerCard(context, currentDev),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }

  // ── Bluetooth Disabled Warning Banner ──────────────────────────────────────

  Widget _buildBluetoothDisabledBanner(BuildContext context, DeviceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.criticalLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.critical.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bluetooth_disabled_rounded, color: AppColors.critical, size: 22),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Bluetooth is turned OFF. Enable Bluetooth to discover and connect to ESP32.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.critical,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => provider.enableBluetooth(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
            child: const Text(
              'ENABLE',
              style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  // ── Active Connection Status Card ──────────────────────────────────────────

  Widget _buildActiveStatusCard(BuildContext context, DeviceProvider provider) {
    final dev = provider.device;
    final isConnected = provider.isConnected;
    final isConnecting = dev.status.isActive && !isConnected;

    Color statusColor = AppColors.textMuted;
    if (isConnected) {
      statusColor = AppColors.normal;
    } else if (isConnecting) {
      statusColor = AppColors.warning;
    } else if (dev.status == DeviceConnectionStatus.connectionFailed) {
      statusColor = AppColors.critical;
    }

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
          if (dev.errorMessage != null && !isConnected) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              dev.errorMessage!,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                color: AppColors.critical,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (isConnected) ...[
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 12, color: AppColors.borderSubtle),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Connected to: ${dev.name} [${dev.id ?? "--"}]',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
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
          ] else if (dev.status == DeviceConnectionStatus.connectionFailed) ...[
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => provider.reconnect(),
                icon: const Icon(Icons.refresh_rounded, size: 14),
                label: const Text(
                  'RECONNECT',
                  style: TextStyle(fontFamily: 'Manrope', fontSize: 11, fontWeight: FontWeight.w800),
                ),
                style: TextButton.styleFrom(foregroundColor: AppColors.accentPrimary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Scan Control Bar ───────────────────────────────────────────────────────

  Widget _buildScanControlBar(BuildContext context, DeviceProvider provider) {
    final isScanning = provider.isScanning;

    return Column(
      children: [
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
                  isScanning ? Icons.stop_circle_rounded : Icons.bluetooth_searching_rounded,
                  size: 18,
                ),
                label: Text(
                  isScanning ? 'STOP SCAN' : 'SCAN DEVICES',
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
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xs),
            child: const LinearProgressIndicator(
              minHeight: 3,
              backgroundColor: AppColors.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentPrimary),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        // Search & Filter Input Field
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => provider.searchQuery = val,
            style: const TextStyle(fontFamily: 'Manrope', fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Filter by device name or MAC address…',
              hintStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11.5,
                color: AppColors.textMuted,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 14),
                      onPressed: () {
                        _searchController.clear();
                        provider.searchQuery = '';
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // ── Section Header ─────────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    required bool isTarget,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Row(
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
      ),
    );
  }

  // ── Unified, Accessible Device Card ────────────────────────────────────────

  Widget _buildDeviceCard(
    BuildContext context,
    DeviceProvider provider,
    ScanResult result, {
    required bool isAqm,
  }) {
    final devName = provider.resolveDeviceName(result);
    final devId = result.device.remoteId.str;
    final rssi = result.rssi;
    final isThisConnected = provider.isConnected && provider.device.id == devId;
    final isThisConnecting = provider.device.status.isActive &&
        !provider.isConnected &&
        provider.device.id == devId;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        color: AppColors.backgroundSecondary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAqm
                        ? AppColors.accentPrimary.withOpacity(0.12)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    isAqm ? Icons.air_rounded : Icons.bluetooth_rounded,
                    color: isAqm ? AppColors.accentPrimary : AppColors.textSecondary,
                    size: 20,
                  ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
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
                _buildRssiBadge(rssi),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                // Compatibility Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isAqm
                        ? AppColors.accentPrimary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    isAqm ? 'AQM PROTOCOL VERIFIED' : 'GENERIC BLE PERIPHERAL',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isAqm ? AppColors.accentPrimary : AppColors.textSecondary,
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
                else if (isThisConnecting)
                  ElevatedButton.icon(
                    onPressed: null,
                    icon: const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text(
                      'CONNECTING…',
                      style: TextStyle(fontFamily: 'Manrope', fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      provider.connect(result.device, isAqm: isAqm);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAqm ? AppColors.accentPrimary : const Color(0xFF1B365D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      isAqm ? 'CONNECT' : 'EXPLORE',
                      style: const TextStyle(
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

  // ── Signal Strength (RSSI) Badge ───────────────────────────────────────────

  Widget _buildRssiBadge(int rssi) {
    Color color = AppColors.normal;
    String quality = 'Good';
    if (rssi >= -60) {
      color = AppColors.normal;
      quality = 'Strong';
    } else if (rssi >= -75) {
      color = const Color(0xFF16B8A6);
      quality = 'Good';
    } else if (rssi >= -88) {
      color = AppColors.warning;
      quality = 'Fair';
    } else {
      color = AppColors.critical;
      quality = 'Weak';
    }

    return Tooltip(
      message: 'Signal: $quality ($rssi dBm)',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.signal_cellular_alt_rounded, size: 13, color: color),
            const SizedBox(width: 3),
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
        ),
      ),
    );
  }

  // ── Educational Note on BLE Advertising ────────────────────────────────────

  Widget _buildBleAdvertisingNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Bluetooth Low Energy Note: Discovered peripherals are limited to devices actively transmitting 2.4GHz BLE advertising beacons. Idle devices in deep sleep or peripherals paired via Bluetooth Classic will not appear until they start advertising.',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State Placeholder ────────────────────────────────────────────────

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
                'SCAN AGAIN',
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

  // ── GATT Explorer Tree View ────────────────────────────────────────────────

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
}
