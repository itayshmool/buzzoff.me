import 'package:flutter/material.dart';

import '../../core/model/camera.dart';
import '../theme/racing_colors.dart';

class CameraMarkerWidget extends StatelessWidget {
  final Camera camera;

  const CameraMarkerWidget({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    final color = colorForType(camera.type);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        iconForType(camera.type),
        size: 14,
        color: Colors.white,
      ),
    );
  }

  static Color colorForType(CameraType type) {
    return switch (type) {
      CameraType.fixedSpeed => RacingColors.cameraSpeed,
      CameraType.redLight => RacingColors.cameraRedLight,
      CameraType.avgSpeedStart => RacingColors.cameraAvgSpeed,
      CameraType.avgSpeedEnd => RacingColors.cameraAvgSpeed,
      CameraType.mobileZone => RacingColors.cameraMobile,
    };
  }

  static IconData iconForType(CameraType type) {
    return switch (type) {
      CameraType.fixedSpeed => Icons.speed,
      CameraType.redLight => Icons.traffic,
      CameraType.avgSpeedStart => Icons.timer,
      CameraType.avgSpeedEnd => Icons.timer_off,
      CameraType.mobileZone => Icons.phone_android,
    };
  }
}
