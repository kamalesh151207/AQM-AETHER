// AQM AETHER — Utility Functions

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
    final str = status.toString();
    if (str.contains('connected')) return AppColors.success;
    if (str.contains('connecting') || str.contains('scanning') || str.contains('reconnecting') || str.contains('discovering') || str.contains('subscribing')) {
      return AppColors.warning;
    }
    if (str.contains('error')) return AppColors.critical;
    return AppColors.textMuted;
  }

  // Parse BLE payload
  // ESP32 firmware sends values as UTF-8 encoded strings (e.g., "25.3")
  static double? parseFloatPayload(List<int> bytes) {
    try {
      final str = String.fromCharCodes(bytes).trim();
      return double.parse(str);
    } catch (_) {
      return null;
    }
  }

  // Parse MQ-135 Gas RAW 12-bit ADC payload (0-4095)
  static int? parseGasPayload(List<int> bytes) {
    try {
      final str = String.fromCharCodes(bytes).trim();
      final val = int.tryParse(str);
      if (val != null) return val.clamp(0, 4095);
      if (bytes.length >= 2) {
        final raw = bytes[0] | (bytes[1] << 8);
        return raw.clamp(0, 4095);
      }
      if (bytes.length == 1) {
        return bytes[0];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // Parse sampling interval from bytes
  static int? parseIntervalPayload(List<int> bytes) {
    try {
      // Try string format first (e.g., "5")
      final str = String.fromCharCodes(bytes).trim();
      return int.parse(str);
    } catch (_) {
      // Fallback: try 4-byte little-endian int
      if (bytes.length >= 4) {
        return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
      }
      if (bytes.length >= 2) {
        return bytes[0] | (bytes[1] << 8);
      }
      if (bytes.length == 1) {
        return bytes[0];
      }
      return null;
    }
  }

  // Encode sampling interval to bytes (string format matching ESP32 firmware)
  static List<int> encodeInterval(int seconds) {
    return seconds.toString().codeUnits;
  }
}

