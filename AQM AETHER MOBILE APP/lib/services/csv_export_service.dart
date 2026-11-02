// AQM AETHER — CSV Export Service

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../models/sensor_reading.dart';

class CsvExportService {
  Future<String?> exportReadings(List<SensorReading> readings) async {
    if (readings.isEmpty) return null;

    final buffer = StringBuffer();
    buffer.writeln(SensorReading.csvHeader());
    for (final r in readings) {
      buffer.writeln(r.toCsvRow());
    }

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'aqm_aether_export_$timestamp.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    return file.path;
  }

  Future<void> shareExport(List<SensorReading> readings) async {
    final path = await exportReadings(readings);
    if (path == null) return;

    await Share.shareXFiles(
      [XFile(path)],
      subject: 'AQM AETHER Sensor Data Export',
      text: 'AQM AETHER Environmental Data — Exported ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
    );
  }
}

