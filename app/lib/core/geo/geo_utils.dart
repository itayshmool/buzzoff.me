import 'dart:math';

class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Haversine distance between two lat/lon points, in meters.
  static double haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Initial bearing from point 1 to point 2, in degrees (0-360).
  static double bearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final y = sin(dLon) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLon);

    final b = atan2(y, x);
    return (_toDegrees(b) + 360) % 360;
  }

  /// Whether [cameraBearing] is within [tolerance] degrees of [heading].
  /// All values in degrees (0-360).
  static bool isAhead(
    double heading,
    double cameraBearing,
    double tolerance,
  ) {
    var diff = (cameraBearing - heading).abs();
    if (diff > 180) diff = 360 - diff;
    return diff <= tolerance;
  }

  static double _toRadians(double deg) => deg * pi / 180;
  static double _toDegrees(double rad) => rad * 180 / pi;
}
