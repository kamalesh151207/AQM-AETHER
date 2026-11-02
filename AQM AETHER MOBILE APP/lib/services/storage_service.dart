// AQM AETHER — Storage Service (SQLite)

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../core/constants/ble_constants.dart';
import '../models/sensor_reading.dart';
import '../models/monitoring_event.dart';

class StorageService {
  Database? _db;

  Future<void> initialize() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    _db = await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_readings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        temperature REAL,
        humidity REAL,
        is_temp_simulated INTEGER DEFAULT 1,
        is_humidity_simulated INTEGER DEFAULT 1,
        gas_raw_adc INTEGER,
        accel_x REAL,
        accel_y REAL,
        accel_z REAL,
        gyro_x REAL,
        gyro_y REAL,
        gyro_z REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE monitoring_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        type INTEGER NOT NULL,
        message TEXT NOT NULL,
        detail TEXT
      )
    ''');

    // Index for performance
    await db.execute(
        'CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp)');
    await db.execute(
        'CREATE INDEX idx_events_timestamp ON monitoring_events(timestamp)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN gas_raw_adc INTEGER;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN accel_x REAL;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN accel_y REAL;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN accel_z REAL;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN gyro_x REAL;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN gyro_y REAL;');
      await db.execute('ALTER TABLE sensor_readings ADD COLUMN gyro_z REAL;');
    }
  }

  // ── Sensor Readings ──────────────────────────────────────────────────────────

  Future<int> insertReading(SensorReading reading) async {
    assert(_db != null, 'Database not initialized');
    final id = await _db!.insert(
      'sensor_readings',
      reading.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Prune to max entries
    await _pruneReadings();
    return id;
  }

  Future<List<SensorReading>> getReadings({
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    assert(_db != null, 'Database not initialized');

    String where = '';
    List<Object?> args = [];

    if (from != null) {
      where += 'timestamp >= ?';
      args.add(from.millisecondsSinceEpoch);
    }
    if (to != null) {
      if (where.isNotEmpty) where += ' AND ';
      where += 'timestamp <= ?';
      args.add(to.millisecondsSinceEpoch);
    }

    final maps = await _db!.query(
      'sensor_readings',
      where: where.isEmpty ? null : where,
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'timestamp ASC',
      limit: limit,
    );

    return maps.map(SensorReading.fromMap).toList();
  }

  Future<int> getReadingCount() async {
    assert(_db != null, 'Database not initialized');
    final result = await _db!.rawQuery(
        'SELECT COUNT(*) as count FROM sensor_readings');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> clearReadings() async {
    assert(_db != null, 'Database not initialized');
    await _db!.delete('sensor_readings');
  }

  Future<void> _pruneReadings() async {
    final count = await getReadingCount();
    if (count > AppConstants.maxHistoryEntries) {
      final excess = count - AppConstants.maxHistoryEntries;
      await _db!.rawDelete(
          'DELETE FROM sensor_readings WHERE id IN '
          '(SELECT id FROM sensor_readings ORDER BY timestamp ASC LIMIT ?)',
          [excess]);
    }
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<int> insertEvent(MonitoringEvent event) async {
    assert(_db != null, 'Database not initialized');
    final id = await _db!.insert(
      'monitoring_events',
      event.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _pruneEvents();
    return id;
  }

  Future<List<MonitoringEvent>> getEvents({int? limit}) async {
    assert(_db != null, 'Database not initialized');
    final maps = await _db!.query(
      'monitoring_events',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return maps.map(MonitoringEvent.fromMap).toList();
  }

  Future<void> clearEvents() async {
    assert(_db != null, 'Database not initialized');
    await _db!.delete('monitoring_events');
  }

  Future<void> _pruneEvents() async {
    await _db!.rawDelete(
        'DELETE FROM monitoring_events WHERE id NOT IN '
        '(SELECT id FROM monitoring_events ORDER BY timestamp DESC LIMIT ?)',
        [AppConstants.maxEventEntries]);
  }

  Future<void> clearAll() async {
    await clearReadings();
    await clearEvents();
  }

  Future<void> close() async {
    await _db?.close();
  }
}

