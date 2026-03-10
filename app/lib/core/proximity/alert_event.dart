import '../model/camera.dart';

enum AlertLevel {
  approaching,
  close,
}

class AlertEvent {
  final Camera camera;
  final AlertLevel level;
  final double distanceMeters;

  const AlertEvent(this.camera, this.level, this.distanceMeters);
}
