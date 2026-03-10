import '../geo/geo_utils.dart';
import '../model/camera.dart';
import 'alert_event.dart';

abstract class CameraQueryPort {
  List<Camera> getCamerasInBounds(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  );
}

class ProximityEngine {
  final CameraQueryPort _cameraQuery;
  final Set<int> _alertedApproaching = {};
  final Set<int> _alertedClose = {};

  static const approachDistance = 800.0; // meters
  static const closeDistance = 400.0;
  static const headingTolerance = 45.0; // degrees
  static const cooldownDistance = 200.0;

  // ~2km in lat/lon offsets
  static const _latOffset = 0.018;
  static const _lonOffset = 0.025;

  ProximityEngine(this._cameraQuery);

  List<AlertEvent> check(
    double lat,
    double lon,
    double heading,
    double speed,
  ) {
    final nearby = _cameraQuery.getCamerasInBounds(
      lat - _latOffset,
      lat + _latOffset,
      lon - _lonOffset,
      lon + _lonOffset,
    );

    final alerts = <AlertEvent>[];
    for (final camera in nearby) {
      final distance = GeoUtils.haversine(lat, lon, camera.lat, camera.lon);
      final bearing = GeoUtils.bearing(lat, lon, camera.lat, camera.lon);

      // Is camera ahead of us?
      if (!GeoUtils.isAhead(heading, bearing, headingTolerance)) {
        // Check if camera is behind and we should reset cooldown
        if (distance > cooldownDistance && _alertedClose.contains(camera.id)) {
          _alertedClose.remove(camera.id);
          _alertedApproaching.remove(camera.id);
        }
        continue;
      }

      // Check alert thresholds
      if (distance <= closeDistance && !_alertedClose.contains(camera.id)) {
        alerts.add(AlertEvent(camera, AlertLevel.close, distance));
        _alertedClose.add(camera.id);
      } else if (distance <= approachDistance &&
          !_alertedApproaching.contains(camera.id)) {
        alerts.add(AlertEvent(camera, AlertLevel.approaching, distance));
        _alertedApproaching.add(camera.id);
      }
    }
    return alerts;
  }

  void reset() {
    _alertedApproaching.clear();
    _alertedClose.clear();
  }
}
