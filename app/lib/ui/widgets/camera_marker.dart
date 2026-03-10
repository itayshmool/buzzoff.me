import 'package:flutter/material.dart';

import '../../core/model/camera.dart';

class CameraMarkerWidget extends StatelessWidget {
  final Camera camera;

  const CameraMarkerWidget({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: _colorForType(camera.type),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  static Color _colorForType(CameraType type) {
    return switch (type) {
      CameraType.fixedSpeed => Colors.blue,
      CameraType.redLight => Colors.red,
      CameraType.avgSpeedStart => Colors.amber,
      CameraType.avgSpeedEnd => Colors.amber,
      CameraType.mobileZone => Colors.orange,
    };
  }
}
