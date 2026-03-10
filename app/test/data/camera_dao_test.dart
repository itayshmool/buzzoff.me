import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:buzzoff/data/database/camera_dao.dart';
import 'package:buzzoff/core/model/camera.dart';

Database _createTestDb(List<Map<String, Object?>> cameras) {
  final db = sqlite3.openInMemory();

  db.execute('''
    CREATE TABLE meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');

  db.execute('''
    CREATE TABLE cameras (
      id TEXT PRIMARY KEY,
      lat REAL NOT NULL,
      lon REAL NOT NULL,
      type TEXT NOT NULL,
      speed_limit INTEGER,
      heading REAL,
      road_name TEXT,
      linked_camera_id TEXT,
      source TEXT NOT NULL DEFAULT 'test',
      confidence REAL NOT NULL DEFAULT 1.0,
      last_verified TEXT
    )
  ''');

  db.execute('''
    CREATE VIRTUAL TABLE cameras_rtree USING rtree(
      id,
      min_lat, max_lat,
      min_lon, max_lon
    )
  ''');

  db.execute("INSERT INTO meta (key, value) VALUES ('country_code', 'IL')");
  db.execute("INSERT INTO meta (key, value) VALUES ('camera_count', '${cameras.length}')");

  for (var i = 0; i < cameras.length; i++) {
    final c = cameras[i];
    final id = c['id'] ?? (i + 1).toString();
    final lat = c['lat'] as double;
    final lon = c['lon'] as double;
    final type = c['type'] ?? 'fixed_speed';
    final speedLimit = c['speed_limit'];
    final heading = c['heading'];
    final roadName = c['road_name'];

    db.execute('''
      INSERT INTO cameras (id, lat, lon, type, speed_limit, heading, road_name, source)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'test')
    ''', [id, lat, lon, type, speedLimit, heading, roadName]);

    db.execute('''
      INSERT INTO cameras_rtree (id, min_lat, max_lat, min_lon, max_lon)
      VALUES (?, ?, ?, ?, ?)
    ''', [i + 1, lat, lat, lon, lon]);
  }

  return db;
}

void main() {
  group('CameraDao', () {
    test('returns cameras within bounding box', () {
      final db = _createTestDb([
        {'lat': 32.08, 'lon': 34.78, 'type': 'fixed_speed'},
        {'lat': 32.09, 'lon': 34.79, 'type': 'red_light'},
        {'lat': 33.0, 'lon': 35.0, 'type': 'fixed_speed'}, // far away
      ]);
      final dao = CameraDao(db);

      final cameras = dao.getCamerasInBounds(32.07, 32.10, 34.77, 34.80);
      expect(cameras, hasLength(2));
      db.dispose();
    });

    test('returns empty list when no cameras in bounds', () {
      final db = _createTestDb([
        {'lat': 33.0, 'lon': 35.0, 'type': 'fixed_speed'},
      ]);
      final dao = CameraDao(db);

      final cameras = dao.getCamerasInBounds(32.07, 32.10, 34.77, 34.80);
      expect(cameras, isEmpty);
      db.dispose();
    });

    test('parses camera types correctly', () {
      final db = _createTestDb([
        {'lat': 32.08, 'lon': 34.78, 'type': 'fixed_speed'},
        {'lat': 32.081, 'lon': 34.781, 'type': 'red_light'},
        {'lat': 32.082, 'lon': 34.782, 'type': 'avg_speed_start'},
      ]);
      final dao = CameraDao(db);

      final cameras = dao.getCamerasInBounds(32.07, 32.10, 34.77, 34.80);
      final types = cameras.map((c) => c.type).toSet();
      expect(types, contains(CameraType.fixedSpeed));
      expect(types, contains(CameraType.redLight));
      expect(types, contains(CameraType.avgSpeedStart));
      db.dispose();
    });

    test('returns speed limit and road name', () {
      final db = _createTestDb([
        {
          'lat': 32.08,
          'lon': 34.78,
          'type': 'fixed_speed',
          'speed_limit': 80,
          'road_name': 'Ayalon Highway',
        },
      ]);
      final dao = CameraDao(db);

      final cameras = dao.getCamerasInBounds(32.07, 32.10, 34.77, 34.80);
      expect(cameras.first.speedLimit, 80);
      expect(cameras.first.roadName, 'Ayalon Highway');
      db.dispose();
    });

    test('getCameraCount returns total count', () {
      final db = _createTestDb([
        {'lat': 32.08, 'lon': 34.78, 'type': 'fixed_speed'},
        {'lat': 32.09, 'lon': 34.79, 'type': 'red_light'},
        {'lat': 33.0, 'lon': 35.0, 'type': 'fixed_speed'},
      ]);
      final dao = CameraDao(db);

      expect(dao.getCameraCount(), 3);
      db.dispose();
    });

    test('getMeta returns meta values', () {
      final db = _createTestDb([]);
      final dao = CameraDao(db);

      expect(dao.getMeta('country_code'), 'IL');
      expect(dao.getMeta('nonexistent'), isNull);
      db.dispose();
    });

    test('implements CameraQueryPort for ProximityEngine', () {
      final db = _createTestDb([
        {'lat': 32.08, 'lon': 34.78, 'type': 'fixed_speed'},
      ]);
      final dao = CameraDao(db);

      // CameraQueryPort interface works
      final cameras = dao.getCamerasInBounds(32.07, 32.10, 34.77, 34.80);
      expect(cameras, hasLength(1));
      expect(cameras.first.lat, closeTo(32.08, 0.001));
      db.dispose();
    });
  });
}
