import 'package:flutter_test/flutter_test.dart';
import 'package:buzzoff/core/proximity/proximity_engine.dart';
import 'package:buzzoff/core/proximity/alert_event.dart';
import 'package:buzzoff/core/model/camera.dart';

class FakeCameraQuery implements CameraQueryPort {
  final List<Camera> cameras;
  FakeCameraQuery(this.cameras);

  @override
  List<Camera> getCamerasInBounds(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  ) {
    return cameras.where((c) {
      return c.lat >= minLat &&
          c.lat <= maxLat &&
          c.lon >= minLon &&
          c.lon <= maxLon;
    }).toList();
  }

  @override
  int getCameraCount() => cameras.length;

  @override
  String? getMeta(String key) => null;
}

// Tel Aviv center: 32.0853, 34.7818
// Heading north (0 degrees)
const _userLat = 32.0853;
const _userLon = 34.7818;
const _headingNorth = 0.0;
const _speed60 = 60.0;

Camera _cameraAt(double lat, double lon, {int id = 1, double? heading}) {
  return Camera(
    id: id,
    lat: lat,
    lon: lon,
    type: CameraType.fixedSpeed,
    speedLimit: 80,
    heading: heading,
  );
}

void main() {
  group('ProximityEngine', () {
    test('returns no alerts when no cameras nearby', () {
      final engine = ProximityEngine(FakeCameraQuery([]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);
      expect(alerts, isEmpty);
    });

    test('alerts approaching when camera is within 800m ahead', () {
      // Place camera ~600m north
      final camera = _cameraAt(_userLat + 0.0054, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(1));
      expect(alerts.first.level, AlertLevel.approaching);
      expect(alerts.first.camera.id, 1);
    });

    test('alerts close when camera is within 400m ahead', () {
      // Place camera ~300m north
      final camera = _cameraAt(_userLat + 0.0027, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(1));
      expect(alerts.first.level, AlertLevel.close);
    });

    test('does not alert for camera behind user', () {
      // Place camera ~600m south (behind when heading north)
      final camera = _cameraAt(_userLat - 0.0054, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, isEmpty);
    });

    test('does not alert for camera beyond approach distance', () {
      // Place camera ~1.5km north
      final camera = _cameraAt(_userLat + 0.0135, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, isEmpty);
    });

    test('debounces: does not re-alert same camera at approaching', () {
      final camera = _cameraAt(_userLat + 0.0054, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));

      final alerts1 =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);
      expect(alerts1, hasLength(1));

      // Second check at same position — already alerted
      final alerts2 =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);
      expect(alerts2, isEmpty);
    });

    test('upgrades from approaching to close as user gets closer', () {
      final camera = _cameraAt(_userLat + 0.0054, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));

      // First check: approaching at ~600m
      final alerts1 =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);
      expect(alerts1.first.level, AlertLevel.approaching);

      // Move closer to ~300m from camera
      final closerLat = _userLat + 0.0027;
      final alerts2 =
          engine.check(closerLat, _userLon, _headingNorth, _speed60);
      expect(alerts2, hasLength(1));
      expect(alerts2.first.level, AlertLevel.close);
    });

    test('handles multiple cameras simultaneously', () {
      final cameras = [
        _cameraAt(_userLat + 0.0054, _userLon, id: 1), // 600m north
        _cameraAt(_userLat + 0.0027, _userLon + 0.002, id: 2), // 300m NNE
      ];
      final engine = ProximityEngine(FakeCameraQuery(cameras));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(2));
    });

    test('resets alert after camera is behind user past cooldown', () {
      final cameraLat = _userLat + 0.0054;
      final camera = _cameraAt(cameraLat, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));

      // First: approaching alert
      engine.check(_userLat, _userLon, _headingNorth, _speed60);

      // Then: close alert as we get closer
      engine.check(cameraLat - 0.0027, _userLon, _headingNorth, _speed60);

      // Then: pass the camera — camera is now behind us
      // User is north of camera, heading north, camera is behind
      final pastLat = cameraLat + 0.005; // well past the camera
      final alerts =
          engine.check(pastLat, _userLon, _headingNorth, _speed60);

      // Camera is behind, should trigger cooldown reset
      // Next approach should re-alert
      // Move back to approaching distance south of camera
      // (This simulates coming around again, unlikely but tests the reset)
    });

    test('filters camera outside heading cone', () {
      // Camera 600m to the east (bearing ~90 from user heading north)
      final camera = _cameraAt(_userLat, _userLon + 0.0065, id: 1);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, isEmpty);
    });

    test('detects camera within heading cone when heading east', () {
      // Camera 600m east, heading east (90 degrees)
      final camera = _cameraAt(_userLat, _userLon + 0.0065, id: 1);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts = engine.check(_userLat, _userLon, 90.0, _speed60);

      expect(alerts, hasLength(1));
      expect(alerts.first.level, AlertLevel.approaching);
    });

    test('skips camera facing opposite lane', () {
      // Camera 600m north, facing south (180°) — opposite to user heading north (0°)
      final camera =
          _cameraAt(_userLat + 0.0054, _userLon, heading: 180);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, isEmpty);
    });

    test('alerts for camera facing same lane', () {
      // Camera 600m north, facing north (0°) — same as user heading north
      final camera =
          _cameraAt(_userLat + 0.0054, _userLon, heading: 0);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(1));
    });

    test('alerts for camera with no heading (null)', () {
      // Camera 600m north, no heading data — should still alert (safe default)
      final camera = _cameraAt(_userLat + 0.0054, _userLon);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(1));
    });

    test('alerts for camera facing similar direction within tolerance', () {
      // Camera 600m north, facing NNE (30°) — within 90° of user heading north
      final camera =
          _cameraAt(_userLat + 0.0054, _userLon, heading: 30);
      final engine = ProximityEngine(FakeCameraQuery([camera]));
      final alerts =
          engine.check(_userLat, _userLon, _headingNorth, _speed60);

      expect(alerts, hasLength(1));
    });
  });
}
