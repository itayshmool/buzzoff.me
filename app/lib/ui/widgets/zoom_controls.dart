import 'package:flutter/material.dart';

import '../theme/racing_colors.dart';

class ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final bool followMode;
  final VoidCallback onSettings;

  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    this.followMode = false,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ControlButton(
          icon: Icons.add,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.remove,
          onTap: onZoomOut,
        ),
        const SizedBox(height: 8),
        _ControlButton(
          icon: Icons.my_location,
          onTap: onMyLocation,
          active: followMode,
        ),
        const SizedBox(height: 16),
        _ControlButton(
          icon: Icons.settings,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  const _ControlButton({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = active ? RacingColors.shellBlue : RacingColors.coinGold;
    return Material(
      color: RacingColors.trackSurface.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(
          color: color.withValues(alpha: active ? 0.8 : 0.4),
          width: active ? 2 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
