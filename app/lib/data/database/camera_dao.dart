import 'package:sqlite3/sqlite3.dart';

import '../../core/model/camera.dart';
import '../../core/proximity/proximity_engine.dart';

class CameraDao implements CameraQueryPort {
  final Database _db;

  CameraDao(this._db);

  @override
  List<Camera> getCamerasInBounds(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  ) {
    final result = _db.select('''
      SELECT c.id, c.lat, c.lon, c.type, c.speed_limit, c.heading, c.road_name
      FROM cameras c
      INNER JOIN cameras_rtree r ON c.id = r.id
      WHERE r.min_lat <= ? AND r.max_lat >= ?
        AND r.min_lon <= ? AND r.max_lon >= ?
    ''', [maxLat, minLat, maxLon, minLon]);

    return result.map(_rowToCamera).toList();
  }

  int getCameraCount() {
    final result = _db.select('SELECT COUNT(*) as cnt FROM cameras');
    return result.first['cnt'] as int;
  }

  String? getMeta(String key) {
    final result = _db.select(
      'SELECT value FROM meta WHERE key = ?',
      [key],
    );
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Camera _rowToCamera(Row row) {
    return Camera(
      id: _parseId(row['id']),
      lat: (row['lat'] as num).toDouble(),
      lon: (row['lon'] as num).toDouble(),
      type: _parseCameraType(row['type'] as String),
      speedLimit: row['speed_limit'] as int?,
      heading: row['heading'] != null
          ? (row['heading'] as num).toDouble()
          : null,
      roadName: row['road_name'] as String?,
    );
  }

  static int _parseId(Object? raw) {
    if (raw is int) return raw;
    if (raw is String) return raw.hashCode;
    return raw.hashCode;
  }

  static CameraType _parseCameraType(String type) {
    switch (type) {
      case 'fixed_speed':
        return CameraType.fixedSpeed;
      case 'red_light':
        return CameraType.redLight;
      case 'avg_speed_start':
        return CameraType.avgSpeedStart;
      case 'avg_speed_end':
        return CameraType.avgSpeedEnd;
      case 'mobile_zone':
        return CameraType.mobileZone;
      default:
        return CameraType.fixedSpeed;
    }
  }
}
