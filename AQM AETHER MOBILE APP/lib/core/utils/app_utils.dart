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
}

