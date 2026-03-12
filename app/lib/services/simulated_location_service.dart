import 'dart:async';
import 'dart:math';

import 'location_service.dart';

/// Simulated GPS that drives along a route in Tel Aviv (Ayalon Hwy / Route 20).
/// Emits [LocationData] at 1-second intervals at ~80 km/h.
/// Used for testing alerts without physically driving.
class SimulatedLocationService extends LocationService {
  Timer? _timer;
  int _waypointIndex = 0;
  double _segmentProgress = 0.0;

  // ~80 km/h in m/s
  static const _speedMs = 22.2;

  // Waypoints along Ayalon Highway (south-bound then looping).
  // Each: [lat, lon]
  static const _waypoints = [
    [32.0920, 34.7870], // North — near Arlozorov
    [32.0880, 34.7872],
    [32.0840, 34.7875],
    [32.0800, 34.7878], // Hashalom area
    [32.0760, 34.7880],
    [32.0720, 34.7882],
    [32.0680, 34.7885],
    [32.0640, 34.7888], // Azrieli area
    [32.0600, 34.7890],
    [32.0560, 34.7893],
    [32.0520, 34.7895],
    [32.0480, 34.7898], // South — near HaShalom interchange
    [32.0440, 34.7900],
    [32.0400, 34.7902],
    // U-turn — heading back north
    [32.0400, 34.7910],
    [32.0440, 34.7908],
    [32.0480, 34.7906],
    [32.0520, 34.7903],
    [32.0560, 34.7901],
    [32.0600, 34.7898],
    [32.0640, 34.7896],
    [32.0680, 34.7893],
    [32.0720, 34.7890],
    [32.0760, 34.7888],
    [32.0800, 34.7886],
    [32.0840, 34.7883],
    [32.0880, 34.7880],
    [32.0920, 34.7878], // Back to start
  ];

  LocationData? _lastEmitted;

  LocationData? get lastEmitted => _lastEmitted;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> startTracking() async {
    if (_timer != null) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _advance();
    });
  }

  @override
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<LocationData?> getCurrentPosition() async {
    return _lastEmitted ?? _locationAt(_waypointIndex, 0.0);
  }

  void _advance() {
    final from = _waypoints[_waypointIndex];
    final to = _waypoints[(_waypointIndex + 1) % _waypoints.length];

    final segmentDistance = _haversine(from[0], from[1], to[0], to[1]);
    if (segmentDistance < 1.0) {
      // Skip zero-length segments
      _waypointIndex = (_waypointIndex + 1) % _waypoints.length;
      _segmentProgress = 0.0;
      return;
    }

    // How far we move in one tick (1 second at _speedMs m/s)
    _segmentProgress += _speedMs / segmentDistance;

    if (_segmentProgress >= 1.0) {
      _waypointIndex = (_waypointIndex + 1) % _waypoints.length;
      _segmentProgress = 0.0;
    }

    final loc = _locationAt(_waypointIndex, _segmentProgress);
    _lastEmitted = loc;
    controller.add(loc);
  }

  LocationData _locationAt(int wpIndex, double progress) {
    final from = _waypoints[wpIndex];
    final to = _waypoints[(wpIndex + 1) % _waypoints.length];

    final lat = from[0] + (to[0] - from[0]) * progress;
    final lon = from[1] + (to[1] - from[1]) * progress;
    final heading = _bearing(from[0], from[1], to[0], to[1]);

    return LocationData(
      latitude: lat,
      longitude: lon,
      speed: _speedMs,
      heading: heading,
      accuracy: 5.0,
      timestamp: DateTime.now(),
    );
  }

  /// Haversine distance in meters.
  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  /// Bearing from point 1 to point 2 in degrees (0-360).
  static double _bearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _rad(lon2 - lon1);
    final y = sin(dLon) * cos(_rad(lat2));
    final x = cos(_rad(lat1)) * sin(_rad(lat2)) -
        sin(_rad(lat1)) * cos(_rad(lat2)) * cos(dLon);
    return (atan2(y, x) * 180.0 / pi + 360.0) % 360.0;
  }

  static double _rad(double deg) => deg * pi / 180.0;

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
