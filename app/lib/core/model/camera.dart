enum CameraType {
  fixedSpeed,
  redLight,
  avgSpeedStart,
  avgSpeedEnd,
  mobileZone,
}

class Camera {
  final int id;
  final double lat;
  final double lon;
  final CameraType type;
  final int? speedLimit;
  final double? heading;
  final String? roadName;

  const Camera({
    required this.id,
    required this.lat,
    required this.lon,
    required this.type,
    this.speedLimit,
    this.heading,
    this.roadName,
  });
}
