// AQM AETHER — History & Data Management Screen
// Displays timestamped telemetry records, search/filtering, and CSV export

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_utils.dart';
import '../../models/sensor_reading.dart';
import '../../providers/monitoring_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/export_csv_button.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isExporting = false;
  String _filterType = 'all'; // all, alerts, normal

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleCsvExport(BuildContext context, MonitoringProvider provider) async {
    setState(() => _isExporting = true);
    HapticFeedback.mediumImpact();
    try {
      final success = await provider.exportCsv();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? AppColors.primary : AppColors.warning,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: success ? AppColors.success : Colors.white,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  success ? 'CSV telemetry exported successfully' : 'No telemetry records to export',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Sensor History?'),
        content: const Text(
          'This will permanently delete all stored sensor readings from local SQLite database storage. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final settings = context.read<SettingsProvider>();
      final monitoring = context.read<MonitoringProvider>();
      await settings.clearStoredHistory();
      await monitoring.clearHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Sensor history database cleared'),
          ),
        );
      }
    }
  }

  List<SensorReading> _applyFilter(List<SensorReading> readings) {
    var result = readings;
    final query = _searchController.text.trim().toLowerCase();

    if (query.isNotEmpty) {
      result = result.where((r) {
        final timeStr = AppUtils.formatDateTime(r.timestamp).toLowerCase();
        final tempStr = r.temperature?.toStringAsFixed(1) ?? '';
        final humStr = r.humidity?.toStringAsFixed(1) ?? '';
        final gasStr = r.gasRawAdc?.toString() ?? '';
        return timeStr.contains(query) ||
            tempStr.contains(query) ||
            humStr.contains(query) ||
            gasStr.contains(query);
      }).toList();
    }

    if (_filterType == 'alerts') {
      result = result.where((r) => r.alertStatus == 'ALERT').toList();
    } else if (_filterType == 'normal') {
      result = result.where((r) => r.alertStatus != 'ALERT').toList();
    }

    return result.reversed.toList(); // Newest first
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<MonitoringProvider>(
      builder: (context, provider, _) {
        final allReadings = provider.readings;
        final filtered = _applyFilter(allReadings);

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'SENSOR HISTORY',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Center(
                  child: ExportCsvButton(
                    isExporting: _isExporting,
                    onPressed: () => _handleCsvExport(context, provider),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Clear History',
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: allReadings.isEmpty ? null : () => _confirmClearHistory(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search & Filter Toolbar
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.sm, AppSpacing.base, AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.border,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search timestamp, temperature, ADC...',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Text(
                        '${filtered.length} logs',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('All Records', 'all'),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Alerts Only', 'alerts'),
                    const SizedBox(width: AppSpacing.xs),
                    _buildFilterChip('Normal', 'normal'),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Data Table / List View
              Expanded(
                child: filtered.isEmpty
                    ? EmptyState(
                        icon: Icons.history_toggle_off_rounded,
                        title: allReadings.isEmpty ? 'No Sensor Readings Recorded' : 'No Matching Readings Found',
                        message: allReadings.isEmpty
                            ? 'Connect to the ESP32 (AQM-Kamalesh) to begin streaming and persisting telemetry.'
                            : 'Try adjusting your search query or filter chip.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return _buildHistoryCard(item, isDark);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = _filterType == type;
    return InkWell(
      onTap: () => setState(() => _filterType = type),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SensorReading item, bool isDark) {
    final isAlert = item.alertStatus == 'ALERT';
    final tempStr = item.temperature != null ? '${item.temperature!.toStringAsFixed(1)}°C' : '--.-°C';
    final humStr = item.humidity != null ? '${item.humidity!.toStringAsFixed(1)}%' : '--.-%';
    final gasStr = item.gasRawAdc != null ? '${item.gasRawAdc} ADC' : '---- ADC';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        borderColor: isAlert ? AppColors.critical.withOpacity(0.4) : null,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppUtils.formatDateTime(item.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isAlert ? AppColors.critical : AppColors.success).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    isAlert ? 'ALERT' : 'NORMAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isAlert ? AppColors.critical : AppColors.success,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.borderSubtle),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCol(
                    label: 'TEMPERATURE',
                    value: tempStr,
                    color: AppColors.accentTemperature,
                  ),
                ),
                Expanded(
                  child: _buildMetricCol(
                    label: 'HUMIDITY',
                    value: humStr,
                    color: AppColors.accentHumidity,
                  ),
                ),
                Expanded(
                  child: _buildMetricCol(
                    label: 'MQ-2 RAW ADC',
                    value: gasStr,
                    color: AppColors.accentGas,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
