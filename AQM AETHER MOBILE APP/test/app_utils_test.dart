// AQM AETHER — Unit Tests for Utility & BLE Protocol Parsing

import 'package:flutter_test/flutter_test.dart';
import 'package:aqm_aether/core/utils/app_utils.dart';
import 'package:aqm_aether/models/device_model.dart';
import 'package:aqm_aether/models/sensor_reading.dart';

void main() {
  group('AppUtils - BLE ASCII Protocol Parsing', () {
    test('parses standard ASCII temperature float', () {
      final bytes = '26.5'.codeUnits;
      expect(AppUtils.parseFloatPayload(bytes), closeTo(26.5, 0.001));
    });

    test('parses ASCII temperature with whitespace and null terminators', () {
      final bytes = '  31.2\x00 '.codeUnits;
      expect(AppUtils.parseFloatPayload(bytes), closeTo(31.2, 0.001));
    });

    test('parses negative float values safely', () {
      final bytes = '-5.4'.codeUnits;
      expect(AppUtils.parseFloatPayload(bytes), closeTo(-5.4, 0.001));
    });

    test('handles invalid, empty, or null bytes safely without crashing', () {
      expect(AppUtils.parseFloatPayload(null), isNull);
      expect(AppUtils.parseFloatPayload([]), isNull);
      expect(AppUtils.parseFloatPayload('invalid_text'.codeUnits), isNull);
      expect(AppUtils.parseFloatPayload('NaN'.codeUnits), isNull);
      expect(AppUtils.parseFloatPayload('Infinity'.codeUnits), isNull);
    });

    test('parses MQ-2 / MQ-135 Gas RAW 12-bit ADC ASCII payload', () {
      final bytes = '1234'.codeUnits;
      expect(AppUtils.parseGasPayload(bytes), equals(1234));
    });

    test('clamps Gas ADC to 0-4095 range', () {
      final highBytes = '65535'.codeUnits;
      expect(AppUtils.parseGasPayload(highBytes), equals(4095));
      final lowBytes = '0'.codeUnits;
      expect(AppUtils.parseGasPayload(lowBytes), equals(0));
    });

    test('parses sampling interval within 2-3600 seconds', () {
      expect(AppUtils.parseIntervalPayload('2'.codeUnits), equals(2));
      expect(AppUtils.parseIntervalPayload('5'.codeUnits), equals(5));
      expect(AppUtils.parseIntervalPayload('3600'.codeUnits), equals(3600));

      // Clamps to min 2 and max 3600
      expect(AppUtils.parseIntervalPayload('0'.codeUnits), equals(2));
      expect(AppUtils.parseIntervalPayload('1'.codeUnits), equals(2));
      expect(AppUtils.parseIntervalPayload('99999'.codeUnits), equals(3600));
    });

    test('encodes sampling interval to ASCII bytes correctly', () {
      expect(AppUtils.encodeInterval(2), equals([50])); // ASCII '2'
      expect(AppUtils.encodeInterval(10), equals([49, 48])); // ASCII '10'
      // Clamps minimum to 2
      expect(AppUtils.encodeInterval(1), equals([50]));
    });

    test('parses alert status ASCII string', () {
      expect(AppUtils.parseAlertPayload('NORMAL'.codeUnits), equals('NORMAL'));
      expect(AppUtils.parseAlertPayload('ALERT'.codeUnits), equals('ALERT'));
      expect(AppUtils.parseAlertPayload('temp_alert'.codeUnits), equals('TEMP_ALERT'));
      expect(AppUtils.parseAlertPayload(null), equals('NORMAL'));
      expect(AppUtils.parseAlertPayload([]), equals('NORMAL'));
    });

    test('escapes CSV cells containing commas, quotes, and newlines', () {
      expect(AppUtils.escapeCsv('Simple Text'), equals('Simple Text'));
      expect(AppUtils.escapeCsv('Value, with comma'), equals('"Value, with comma"'));
      expect(AppUtils.escapeCsv('Value with "quotes"'), equals('"Value with ""quotes"""'));
      expect(AppUtils.escapeCsv('Line1\nLine2'), equals('"Line1\nLine2"'));
      expect(AppUtils.escapeCsv(null), equals(''));
    });
  });

  group('DeviceConnectionStatus - State Machine', () {
    test('verifies connection state lifecycle properties', () {
      expect(DeviceConnectionStatus.ready.isConnected, isTrue);
      expect(DeviceConnectionStatus.connected.isConnected, isTrue);
      expect(DeviceConnectionStatus.connecting.isConnected, isFalse);
      expect(DeviceConnectionStatus.disconnected.isDisconnected, isTrue);
      expect(DeviceConnectionStatus.idle.isDisconnected, isTrue);
      expect(DeviceConnectionStatus.connectionFailed.isDisconnected, isTrue);

      expect(DeviceConnectionStatus.scanning.isActive, isTrue);
      expect(DeviceConnectionStatus.deviceFound.isActive, isTrue);
      expect(DeviceConnectionStatus.connecting.isActive, isTrue);
      expect(DeviceConnectionStatus.ready.isActive, isFalse);
    });

    test('verifies all connection status user messages', () {
      for (final status in DeviceConnectionStatus.values) {
        expect(status.label.isNotEmpty, isTrue);
        expect(status.userMessage.isNotEmpty, isTrue);
      }
    });
  });

  group('SensorReading - CSV Export Formatting', () {
    test('formats valid telemetry row matching RFC 4180', () {
      final reading = SensorReading(
        timestamp: DateTime(2026, 11, 3, 10, 30, 0),
        temperature: 26.54,
        humidity: 55.20,
        gasRawAdc: 1250,
        alertStatus: 'NORMAL',
        connectionStatus: 'Connected',
        samplingInterval: 2,
        accelX: 0.021,
        accelY: -0.015,
        accelZ: 0.982,
        gyroX: 0.12,
        gyroY: -0.05,
        gyroZ: 0.01,
      );

      final row = reading.toCsvRow();
      expect(row, contains('2026-11-03 10:30:00'));
      expect(row, contains('26.54'));
      expect(row, contains('55.20'));
      expect(row, contains('1250'));
      expect(row, contains('NORMAL'));
      expect(row, contains('Connected'));
      expect(row, contains('2'));
      expect(row, contains('0.021'));
      expect(row, contains('0.982'));
    });

    test('csvHeader contains all required sensor and telemetry columns', () {
      final header = SensorReading.csvHeader();
      expect(header, contains('Timestamp'));
      expect(header, contains('Temperature (°C)'));
      expect(header, contains('Humidity (%)'));
      expect(header, contains('MQ-2 RAW ADC'));
      expect(header, contains('Alert Status'));
      expect(header, contains('BLE Connection Status'));
      expect(header, contains('Sampling Interval (s)'));
    });
  });
}

