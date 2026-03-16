import '../core/model/camera.dart';
import '../core/proximity/proximity_engine.dart';

/// In-memory camera store for web preview. No SQLite needed.
class MockCameraDao implements CameraQueryPort {
  static final _cameras = <Camera>[
    // Ayalon Highway area (Tel Aviv) — mix of types
    const Camera(
      id: 1,
      lat: 32.0920,
      lon: 34.7870,
      type: CameraType.fixedSpeed,
      speedLimit: 80,
      roadName: 'Ayalon North',
    ),
    const Camera(
      id: 2,
      lat: 32.0880,
      lon: 34.7872,
      type: CameraType.fixedSpeed,
      speedLimit: 80,
      heading: 180,
      roadName: 'Ayalon South',
    ),
    const Camera(
      id: 3,
      lat: 32.0850,
      lon: 34.7750,
      type: CameraType.redLight,
      speedLimit: 50,
      roadName: 'Begin Rd / Arlozorov',
    ),
    const Camera(
      id: 4,
      lat: 32.0800,
      lon: 34.7900,
      type: CameraType.avgSpeedStart,
      roadName: 'Namir Rd',
    ),
    const Camera(
      id: 5,
      lat: 32.0750,
      lon: 34.7900,
      type: CameraType.avgSpeedEnd,
      roadName: 'Namir Rd',
    ),
    const Camera(
      id: 6,
      lat: 32.0830,
      lon: 34.7820,
      type: CameraType.mobileZone,
      roadName: 'Ibn Gvirol St',
    ),
  ];

  @override
  List<Camera> getCamerasInBounds(
    double minLat,
    double maxLat,
    double minLon,
    double maxLon,
  ) {
    return _cameras
        .where((c) =>
            c.lat >= minLat &&
            c.lat <= maxLat &&
            c.lon >= minLon &&
            c.lon <= maxLon)
        .toList();
  }

  int getCameraCount() => _cameras.length;

  String? getMeta(String key) => null;
}
