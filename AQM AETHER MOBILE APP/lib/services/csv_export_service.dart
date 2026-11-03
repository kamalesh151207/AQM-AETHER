// AQM AETHER — CSV Export Service
// Generates UTF-8 encoded, RFC 4180 compliant CSV exports of sensor telemetry

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';

class CsvExportService {
  Future<String?> exportReadings(List<SensorReading> readings) async {
    if (readings.isEmpty) return null;

    try {
      final buffer = StringBuffer();
      // Write RFC 4180 Header
      buffer.writeln(SensorReading.csvHeader());

      // Write Rows in batches to handle large datasets efficiently
      for (final r in readings) {
        buffer.writeln(r.toCsvRow());
      }

      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'aqm_aether_sensor_export_$timestamp.csv';
      final file = File('${dir.path}/$fileName');

      // Write with explicit UTF-8 encoding
      await file.writeAsBytes(utf8.encode(buffer.toString()), flush: true);

      debugPrint('[CsvExportService] Exported ${readings.length} records to ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('[CsvExportService] Export failed: $e');
      return null;
    }
  }

  Future<bool> shareExport(List<SensorReading> readings) async {
    final path = await exportReadings(readings);
    if (path == null) return false;

    try {
      final result = await Share.shareXFiles(
        [XFile(path, mimeType: 'text/csv')],
        subject: 'AQM AETHER Sensor Data Export',
        text: 'AQM AETHER Environmental Telemetry — Exported ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} (${readings.length} records)',
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (e) {
      debugPrint('[CsvExportService] Share failed: $e');
      return false;
    }
  }
}

