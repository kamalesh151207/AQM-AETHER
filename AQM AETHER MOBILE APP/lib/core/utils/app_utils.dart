// AQM AETHER — Utility Functions

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../constants/ble_constants.dart';

abstract class AppUtils {
  // Date/Time formatting
  static String formatDateTime(DateTime dt) {
    return DateFormat('dd MMM yyyy, HH:mm:ss').format(dt);
  }

  static String formatTime(DateTime dt) {
    return DateFormat('HH:mm:ss').format(dt);
  }

  static String formatTimeShort(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  static String formatDate(DateTime dt) {
    return DateFormat('dd MMM yyyy').format(dt);
  }

  static String formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 10) return 'just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  static String formatDuration(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    if (d.inMinutes < 60) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    if (d.inHours < 24) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inDays}d ${d.inHours % 24}h';
  }

  static String formatSamplingInterval(int seconds) {
    if (seconds < 60) return '${seconds}s';
    if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
    return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
  }

  // Sensor value formatting
  static String formatTemperature(double value) {
    return value.toStringAsFixed(1);
  }

  static String formatHumidity(double value) {
    return value.toStringAsFixed(1);
  }

  static String formatGasAdc(int value) {
    return '$value';
  }

  static String formatMotionAxis(double? value, {String unit = 'g'}) {
    if (value == null) return '--';
    return '${value >= 0 ? "+" : ""}${value.toStringAsFixed(2)} $unit';
  }

  // Color utilities
  static Color temperatureColor(double temp) {
    if (temp < 15) return AppColors.accentSecondary;
    if (temp < 25) return AppColors.accentPrimary;
    if (temp < 35) return AppColors.accentTemperature;
    return AppColors.critical;
  }

  static Color humidityColor(double humidity) {
    if (humidity < 30) return AppColors.warning;
    if (humidity < 70) return AppColors.accentHumidity;
    return AppColors.accentSecondary;
  }

  // Data Quality Colors
  static Color dataQualityColor(DataQuality quality) {
    switch (quality) {
      case DataQuality.fresh:
        return AppColors.success;
      case DataQuality.delayed:
        return AppColors.warning;
      case DataQuality.stale:
        return AppColors.critical;
      case DataQuality.unavailable:
        return AppColors.textMuted;
    }
  }

  // Connection Status Color
  static Color statusColor(dynamic status) {
    final str = status.toString().toLowerCase();
    if (str.contains('ready') || str.contains('connected')) return AppColors.success;
    if (str.contains('connecting') ||
        str.contains('scanning') ||
        str.contains('devicefound') ||
        str.contains('reconnecting') ||
        str.contains('discovering') ||
        str.contains('subscribing') ||
        str.contains('disconnecting')) {
      return AppColors.warning;
    }
    if (str.contains('error') || str.contains('failed')) return AppColors.critical;
    return AppColors.textMuted;
  }

  // Parse BLE payload
  // ESP32 firmware sends values as ASCII strings (e.g., "26.5", "54.0")
  static double? parseFloatPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      // 1. Try ASCII string parsing first (Primary ESP32 protocol)
      final rawStr = String.fromCharCodes(bytes).trim();
      final clean = rawStr.replaceAll(RegExp(r'[^\d.-]'), '');
      if (clean.isNotEmpty) {
        final val = double.tryParse(clean);
        if (val != null && !val.isNaN && !val.isInfinite) {
          return val;
        }
      }

      // 2. Fallback: Little-endian 4-byte IEEE 754 float
      if (bytes.length == 4) {
        final bdata = ByteData.sublistView(Uint8List.fromList(bytes));
        final val = bdata.getFloat32(0, Endian.little);
        if (!val.isNaN && !val.isInfinite) {
          return val;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Parse MQ-2 / MQ-135 Gas RAW 12-bit ADC payload (0-4095)
  // Protocol: ASCII string (e.g., "1234")
  static int? parseGasPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      // 1. ASCII string parsing
      final rawStr = String.fromCharCodes(bytes).trim();
      final clean = rawStr.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.isNotEmpty) {
        final val = int.tryParse(clean);
        if (val != null) return val.clamp(0, 4095);
      }

      // 2. Binary fallbacks
      if (bytes.length >= 4) {
        final bdata = ByteData.sublistView(Uint8List.fromList(bytes));
        return bdata.getUint32(0, Endian.little).clamp(0, 4095);
      }
      if (bytes.length >= 2) {
        final raw = bytes[0] | (bytes[1] << 8);
        return raw.clamp(0, 4095);
      }
      if (bytes.length == 1) {
        return bytes[0].clamp(0, 4095);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Parse sampling interval from bytes
  // Protocol: ASCII string in seconds (min 2, max 3600, default 2)
  static int? parseIntervalPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      // 1. Try ASCII string format (e.g., "2", "5")
      final rawStr = String.fromCharCodes(bytes).trim();
      final clean = rawStr.replaceAll(RegExp(r'[^\d]'), '');
      if (clean.isNotEmpty) {
        final val = int.tryParse(clean);
        if (val != null) return val.clamp(2, 3600);
      }

      // 2. Binary fallback
      if (bytes.length >= 4) {
        final bdata = ByteData.sublistView(Uint8List.fromList(bytes));
        return bdata.getUint32(0, Endian.little).clamp(2, 3600);
      }
      if (bytes.length >= 2) {
        final raw = bytes[0] | (bytes[1] << 8);
        return raw.clamp(2, 3600);
      }
      if (bytes.length == 1) {
        return bytes[0].clamp(2, 3600);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Parse Alert status ASCII string (e.g., "NORMAL", "ALERT", "TEMP_ALERT")
  static String parseAlertPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return 'NORMAL';
    try {
      final str = String.fromCharCodes(bytes).trim();
      final clean = str.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      if (clean.isEmpty) return 'NORMAL';
      return clean.toUpperCase();
    } catch (_) {
      return 'NORMAL';
    }
  }

  // Encode sampling interval to bytes (ASCII string format matching ESP32 firmware)
  // Protocol: Minimum 2 seconds, Maximum 3600 seconds
  static List<int> encodeInterval(int seconds) {
    final clamped = seconds.clamp(2, 3600);
    return clamped.toString().codeUnits;
  }

  // Escape a string value for safe RFC 4180 CSV export
  static String escapeCsv(String? value) {
    if (value == null) return '';
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ── Unique Device ID Utilities ─────────────────────────────────────────────

  // Parse ASCII string payload (e.g. Device ID "AQM-KAM-001")
  static String? parseStringPayload(List<int>? bytes) {
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final str = String.fromCharCodes(bytes).trim();
      final clean = str.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
      return clean.isNotEmpty ? clean : null;
    } catch (_) {
      return null;
    }
  }

  // Normalize Device ID (e.g., " aqm-kam-001 " -> "AQM-KAM-001")
  static String normalizeDeviceId(String raw) {
    return raw.trim().toUpperCase();
  }

  // Validate BLE UUID format (e.g. 12345678-1234-1234-1234-123456789001)
  // Supports standard 128-bit hyphenated UUIDs (36 chars: 8-4-4-4-12),
  // 32-character hex UUIDs without hyphens, and 16/32-bit short UUIDs
  static bool isValidBleUuid(String raw) {
    final clean = raw.trim().toLowerCase();
    // 128-bit standard UUID with hyphens (e.g. 12345678-1234-1234-1234-123456789001)
    if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(clean)) {
      return true;
    }
    // 128-bit hex UUID without hyphens (32 hex characters)
    if (RegExp(r'^[0-9a-f]{32}$').hasMatch(clean)) {
      return true;
    }
    // 16-bit or 32-bit short UUIDs
    if (RegExp(r'^[0-9a-f]{4}$').hasMatch(clean) || RegExp(r'^[0-9a-f]{8}$').hasMatch(clean)) {
      return true;
    }
    return false;
  }

  // Validate MAC address format (e.g. CC:50:E3:A1:B2:C3 or cc-50-e3-a1-b2-c3)
  static bool isValidMacAddress(String raw) {
    final clean = raw.trim().toUpperCase();
    return RegExp(r'^([0-9A-F]{2}[:\-]){5}[0-9A-F]{2}$').hasMatch(clean);
  }

  // Validate Device ID, Service UUID, or BLE device identifier
  // Accepts:
  // - Valid 128-bit BLE UUIDs with hyphens (e.g. 12345678-1234-1234-1234-123456789001)
  // - MAC addresses (e.g. CC:50:E3:A1:B2:C3)
  // - Device names and configured identifiers (e.g. AQM-Kamalesh, AQM-KAM-001)
  static bool isValidDeviceId(String raw) {
    final clean = raw.trim();
    if (clean.length < 3 || clean.length > 64) return false;
    if (isValidBleUuid(clean)) return true;
    if (isValidMacAddress(clean)) return true;
    // Allow alphanumeric characters, hyphens, underscores, colons, dots, spaces
    return RegExp(r'^[A-Za-z0-9_\-:\.\s]+$').hasMatch(clean);
  }

  // Check if a peripheral identity matches target Device ID, Service UUID, or Name
  static bool matchesDeviceIdentity({
    required String targetId,
    String? advertisedName,
    String? platformName,
    String? remoteId,
    List<String>? serviceUuids,
    String? manufacturerData,
    String? readCharacteristicValue,
  }) {
    final target = normalizeDeviceId(targetId);
    if (target.isEmpty) return false;

    // 1. BLE Service UUID match (e.g. 12345678-1234-1234-1234-123456789001)
    if (serviceUuids != null && serviceUuids.isNotEmpty) {
      final targetNorm = target.replaceAll('-', '').toLowerCase();
      for (final u in serviceUuids) {
        final uNorm = u.replaceAll('-', '').toLowerCase();
        if (uNorm == targetNorm || uNorm.contains(targetNorm)) return true;
      }
    }

    // 2. BLE Remote ID / MAC address match
    if (remoteId != null) {
      final rClean = remoteId.replaceAll(':', '').replaceAll('-', '').toUpperCase();
      final tClean = target.replaceAll(':', '').replaceAll('-', '').toUpperCase();
      if (rClean == tClean) return true;
    }

    // 3. Direct characteristic match (definitive source of truth if available)
    if (readCharacteristicValue != null) {
      final readClean = normalizeDeviceId(readCharacteristicValue);
      if (readClean == target) return true;
    }

    // 4. Advertised name match
    if (advertisedName != null) {
      final advClean = normalizeDeviceId(advertisedName);
      if (advClean == target || advClean.contains(target) || target.contains(advClean)) return true;
    }

    // 5. Platform name match
    if (platformName != null) {
      final platClean = normalizeDeviceId(platformName);
      if (platClean == target || platClean.contains(target) || target.contains(platClean)) return true;
    }

    // 6. Manufacturer data advertisement match
    if (manufacturerData != null) {
      final mfgClean = normalizeDeviceId(manufacturerData);
      if (mfgClean == target || mfgClean.contains(target)) return true;
    }

    return false;
  }
}

