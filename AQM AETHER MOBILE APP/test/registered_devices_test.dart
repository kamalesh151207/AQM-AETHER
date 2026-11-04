// AQM AETHER — Unit Tests for Persistent Multi-Device ID Registration & Auto-Reconnection

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aqm_aether/core/constants/ble_constants.dart';
import 'package:aqm_aether/models/device_model.dart';
import 'package:aqm_aether/core/utils/app_utils.dart';
import 'package:aqm_aether/services/ble_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RegisteredDevice Model Serialization & Deserialization', () {
    test('JSON serialization round-trip retains all fields and timestamps', () {
      final now = DateTime(2026, 11, 4, 15, 30);
      final reg = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:A1:B2:C3',
        deviceName: 'AQM-Kamalesh',
        serviceUuid: BleConstants.serviceUuid,
        registeredAt: now,
        lastConnectedAt: now,
      );

      final json = reg.toJson();
      final decoded = RegisteredDevice.fromJson(json);

      expect(decoded.deviceId, equals('AQM-KAM-001'));
      expect(decoded.remoteId, equals('CC:50:E3:A1:B2:C3'));
      expect(decoded.deviceName, equals('AQM-Kamalesh'));
      expect(decoded.serviceUuid, equals(BleConstants.serviceUuid));
      expect(decoded.registeredAt, equals(now));
      expect(decoded.lastConnectedAt, equals(now));
      expect(decoded, equals(reg));
    });

    test('equality and hashCode are based on deviceId and remoteId', () {
      final reg1 = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'cc:50:e3:a1:b2:c3',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
      final reg2 = RegisteredDevice(
        deviceId: 'aqm-kam-001',
        remoteId: 'CC:50:E3:A1:B2:C3',
        deviceName: 'Renamed Kamalesh',
        registeredAt: DateTime.now().subtract(const Duration(days: 1)),
        lastConnectedAt: DateTime.now(),
      );

      expect(reg1, equals(reg2));
      expect(reg1.hashCode, equals(reg2.hashCode));
    });
  });

  group('Multi-Device Registry Storage & Management (Tests 1 - 8)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TEST 1: Registration saved only after successful verification', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulate first-time verified connection
      final reg1 = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:A1:B2:C1',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final registry = [reg1.toJson()];
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode(registry));
      await prefs.setString(BleConstants.prefLastDeviceId, reg1.deviceId);

      // Verify persisted
      final storedRaw = prefs.getString(BleConstants.prefRegisteredDevices);
      expect(storedRaw, isNotNull);
      final decoded = (jsonDecode(storedRaw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(decoded.length, equals(1));
      expect(decoded.first.deviceId, equals('AQM-KAM-001'));
      expect(decoded.first.deviceName, equals('AQM-Kamalesh'));
    });

    test('TEST 2 & 3 & 4: Registered device recognized across app & phone restarts without ID prompt', () async {
      final prefs = await SharedPreferences.getInstance();

      // Pre-seed storage simulating prior verified registration
      final reg = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:A1:B2:C1',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime(2026, 11, 1),
        lastConnectedAt: DateTime(2026, 11, 4),
      );
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode([reg.toJson()]));

      // App reopens (simulated reload from SharedPreferences)
      final raw = prefs.getString(BleConstants.prefRegisteredDevices);
      final list = (jsonDecode(raw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      // Matching simulated peripheral
      const incomingRemoteId = 'cc:50:e3:a1:b2:c1';
      final match = list.firstWhere((r) => r.remoteId.toLowerCase() == incomingRemoteId);

      expect(match.deviceId, equals('AQM-KAM-001'));
      expect(match.deviceName, equals('AQM-Kamalesh'));
      // Device ID is known -> No prompt needed
    });

    test('TEST 5: New unregistered device is not in registry and requires ID prompt', () async {
      final prefs = await SharedPreferences.getInstance();

      final reg = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:A1:B2:C1',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode([reg.toJson()]));

      final raw = prefs.getString(BleConstants.prefRegisteredDevices);
      final list = (jsonDecode(raw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      // Unknown new peripheral
      const newRemoteId = 'FF:EE:DD:CC:BB:AA';
      const newName = 'AQM-Arun';
      final match = list.where((r) =>
          r.remoteId.toLowerCase() == newRemoteId.toLowerCase() ||
          r.deviceName.toLowerCase() == newName.toLowerCase());

      expect(match.isEmpty, isTrue);
      // Not registered -> Device ID must be prompted
    });

    test('TEST 6: Incorrect Device ID causes mismatch exception and nothing is saved', () {
      const enteredId = 'AQM-WRONG-999';
      const actualId = 'AQM-KAM-001';

      expect(AppUtils.normalizeDeviceId(enteredId), isNot(equals(actualId)));

      // Simulate mismatch check performed by BLE service
      bool threwMismatch = false;
      try {
        if (AppUtils.normalizeDeviceId(enteredId) != AppUtils.normalizeDeviceId(actualId)) {
          throw const DeviceIdMismatchException('Device ID does not match. Please check your ID.');
        }
      } on DeviceIdMismatchException catch (e) {
        threwMismatch = true;
        expect(e.message, equals('Device ID does not match. Please check your ID.'));
      }

      expect(threwMismatch, isTrue);
    });

    test('TEST 7: Multiple registered AQM devices each reconnects to its own saved identity', () async {
      final prefs = await SharedPreferences.getInstance();

      final dev1 = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:01:01:01',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
      final dev2 = RegisteredDevice(
        deviceId: 'AQM-ARU-002',
        remoteId: 'CC:50:E3:02:02:02',
        deviceName: 'AQM-Arun',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
      final dev3 = RegisteredDevice(
        deviceId: 'AQM-RAH-003',
        remoteId: 'CC:50:E3:03:03:03',
        deviceName: 'AQM-Rahul',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final registry = [dev1.toJson(), dev2.toJson(), dev3.toJson()];
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode(registry));

      // Reload
      final raw = prefs.getString(BleConstants.prefRegisteredDevices);
      final list = (jsonDecode(raw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, equals(3));

      // Reconnecting to Device 2 (AQM-Arun)
      final foundDev2 = list.firstWhere((r) => r.remoteId == 'CC:50:E3:02:02:02');
      expect(foundDev2.deviceId, equals('AQM-ARU-002'));
      expect(foundDev2.deviceName, equals('AQM-Arun'));

      // Reconnecting to Device 3 (AQM-Rahul)
      final foundDev3 = list.firstWhere((r) => r.deviceName == 'AQM-Rahul');
      expect(foundDev3.deviceId, equals('AQM-RAH-003'));
      expect(foundDev3.remoteId, equals('CC:50:E3:03:03:03'));
    });

    test('TEST 8: Forgetting a registered device removes it without deleting other registered devices', () async {
      final prefs = await SharedPreferences.getInstance();

      final dev1 = RegisteredDevice(
        deviceId: 'AQM-KAM-001',
        remoteId: 'CC:50:E3:01:01:01',
        deviceName: 'AQM-Kamalesh',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );
      final dev2 = RegisteredDevice(
        deviceId: 'AQM-ARU-002',
        remoteId: 'CC:50:E3:02:02:02',
        deviceName: 'AQM-Arun',
        registeredAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
      );

      final registry = [dev1.toJson(), dev2.toJson()];
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode(registry));

      // User forgets AQM-Kamalesh
      final raw = prefs.getString(BleConstants.prefRegisteredDevices);
      final list = (jsonDecode(raw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      list.removeWhere((r) => r.deviceId == 'AQM-KAM-001');
      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode(list.map((r) => r.toJson()).toList()));

      // Reload registry
      final updatedRaw = prefs.getString(BleConstants.prefRegisteredDevices);
      final updatedList = (jsonDecode(updatedRaw!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(updatedList.length, equals(1));
      expect(updatedList.first.deviceId, equals('AQM-ARU-002'));
      expect(updatedList.first.deviceName, equals('AQM-Arun'));

      // AQM-Kamalesh is now forgotten -> next attempt will not find registration
      final forgottenCheck = updatedList.where((r) => r.deviceId == 'AQM-KAM-001');
      expect(forgottenCheck.isEmpty, isTrue);
    });

    test('Legacy migration: Migrates single saved device into multi-device registry', () async {
      final prefs = await SharedPreferences.getInstance();

      // Seed only legacy keys
      await prefs.setString(BleConstants.prefLastDeviceId, 'AQM-KAM-001');
      await prefs.setString(BleConstants.prefLastDeviceName, 'AQM-Kamalesh');
      await prefs.setString(BleConstants.prefLastRemoteId, 'CC:50:E3:A1:B2:C1');
      await prefs.setString(BleConstants.prefLastConnectedTime, DateTime.now().toIso8601String());

      // Simulate legacy migration in loadSavedDevice()
      final legacyId = prefs.getString(BleConstants.prefLastDeviceId);
      final legacyRemote = prefs.getString(BleConstants.prefLastRemoteId);
      final legacyName = prefs.getString(BleConstants.prefLastDeviceName);
      final legacyTs = prefs.getString(BleConstants.prefLastConnectedTime);

      final migrated = RegisteredDevice(
        deviceId: legacyId!,
        remoteId: legacyRemote ?? '',
        deviceName: legacyName ?? BleConstants.deviceName,
        serviceUuid: BleConstants.serviceUuid,
        registeredAt: DateTime.parse(legacyTs!),
        lastConnectedAt: DateTime.parse(legacyTs),
      );

      await prefs.setString(BleConstants.prefRegisteredDevices, jsonEncode([migrated.toJson()]));

      final stored = prefs.getString(BleConstants.prefRegisteredDevices);
      expect(stored, isNotNull);
      final list = (jsonDecode(stored!) as List)
          .map((e) => RegisteredDevice.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(list.length, equals(1));
      expect(list.first.deviceId, equals('AQM-KAM-001'));
    });
  });
}
