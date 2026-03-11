import 'package:flutter/material.dart';

import '../../core/model/camera.dart';
import '../theme/racing_colors.dart';

/// Groups CameraType values into user-facing filter categories.
enum CameraFilter {
  speed(
      label: 'Blue Shells',
      color: RacingColors.cameraSpeed,
      types: {CameraType.fixedSpeed}),
  redLight(
      label: 'Red Shells',
      color: RacingColors.cameraRedLight,
      types: {CameraType.redLight}),
  avgSpeed(
      label: 'Stars',
      color: RacingColors.cameraAvgSpeed,
      types: {CameraType.avgSpeedStart, CameraType.avgSpeedEnd}),
  mobile(
      label: 'Bananas',
      color: RacingColors.cameraMobile,
      types: {CameraType.mobileZone});

  final String label;
  final Color color;
  final Set<CameraType> types;

  const CameraFilter(
      {required this.label, required this.color, required this.types});
}

class CameraFilterBar extends StatelessWidget {
  final Set<CameraType> activeTypes;
  final List<Camera> cameras;
  final ValueChanged<CameraFilter> onToggle;

  const CameraFilterBar({
    super.key,
    required this.activeTypes,
    required this.cameras,
    required this.onToggle,
  });

  int _countFor(CameraFilter filter) {
    return cameras.where((c) => filter.types.contains(c.type)).length;
  }

  bool _isActive(CameraFilter filter) {
    return filter.types.any(activeTypes.contains);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CameraFilter.values.map((filter) {
          final active = _isActive(filter);
          final count = _countFor(filter);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text('${filter.label} ($count)'),
              selected: active,
              onSelected: (_) => onToggle(filter),
              selectedColor: filter.color.withValues(alpha: 0.3),
              checkmarkColor: filter.color,
              side: BorderSide(
                color: active
                    ? filter.color
                    : RacingColors.coinGold.withValues(alpha: 0.3),
              ),
              labelStyle: TextStyle(
                color: active ? filter.color : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: RacingColors.trackSurface.withValues(alpha: 0.9),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
