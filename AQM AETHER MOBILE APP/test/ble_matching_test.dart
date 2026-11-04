// AQM AETHER — Unit Tests for BLE Device Matching & UUID Normalization

import 'package:flutter_test/flutter_test.dart';
import 'package:aqm_aether/core/constants/ble_constants.dart';

void main() {
  group('BLE Constants & UUID Normalization', () {
    test('exact UUID match for all 11 AQM characteristics', () {
      expect(BleConstants.serviceUuid, equals('12345678-1234-1234-1234-123456789001'));
      expect(BleConstants.temperatureUuid, equals('12345678-1234-1234-1234-123456789002'));
      expect(BleConstants.humidityUuid, equals('12345678-1234-1234-1234-123456789003'));
      expect(BleConstants.samplingIntervalUuid, equals('12345678-1234-1234-1234-123456789004'));
      expect(BleConstants.alertUuid, equals('12345678-1234-1234-1234-123456789005'));
      expect(BleConstants.gasUuid, equals('12345678-1234-1234-1234-123456789006'));
      expect(BleConstants.deviceIdUuid, equals('12345678-1234-1234-1234-123456789007'));
      expect(BleConstants.defaultDeviceId, equals('AQM-KAM-001'));
      expect(BleConstants.accelXUuid, equals('12345678-1234-1234-1234-123456789007'));
      expect(BleConstants.accelYUuid, equals('12345678-1234-1234-1234-123456789008'));
      expect(BleConstants.accelZUuid, equals('12345678-1234-1234-1234-123456789009'));
      expect(BleConstants.gyroXUuid, equals('12345678-1234-1234-1234-12345678900A'));
      expect(BleConstants.gyroYUuid, equals('12345678-1234-1234-1234-12345678900B'));
      expect(BleConstants.gyroZUuid, equals('12345678-1234-1234-1234-12345678900C'));
    });

    test('reconnection backoff schedule is controlled and bounded', () {
      expect(BleConstants.reconnectBackoff.length, equals(5));
      expect(BleConstants.reconnectBackoff[0], equals(Duration.zero));
      expect(BleConstants.reconnectBackoff[1], equals(const Duration(seconds: 2)));
      expect(BleConstants.reconnectBackoff[2], equals(const Duration(seconds: 5)));
      expect(BleConstants.reconnectBackoff[3], equals(const Duration(seconds: 10)));
      expect(BleConstants.reconnectBackoff[4], equals(const Duration(seconds: 20)));
      expect(BleConstants.reconnectMaxInterval, equals(const Duration(seconds: 30)));
      expect(BleConstants.maxAutoReconnectAttempts, equals(10));
    });

    test('sampling interval constraints match firmware', () {
      expect(BleConstants.defaultSamplingInterval, equals(2));
      expect(BleConstants.minSamplingInterval, equals(1));
      expect(BleConstants.maxSamplingInterval, equals(3600));
    });

    test('case-insensitive UUID normalization handles variations', () {
      String norm(String u) => u.replaceAll('-', '').toLowerCase();

      final targetNorm = norm(BleConstants.serviceUuid);
      expect(norm('12345678-1234-1234-1234-123456789001'), equals(targetNorm));
      expect(norm('12345678123412341234123456789001'), equals(targetNorm));
      expect(norm('12345678-1234-1234-1234-123456789001'.toUpperCase()), equals(targetNorm));
    });
  });
}

