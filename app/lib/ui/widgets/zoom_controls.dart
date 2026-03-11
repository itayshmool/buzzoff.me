import 'package:flutter/material.dart';

import '../theme/racing_colors.dart';

class ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onSettings;

  const ZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
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

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RacingColors.trackSurface.withValues(alpha: 0.9),
      shape: CircleBorder(
        side: BorderSide(
          color: RacingColors.coinGold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: RacingColors.coinGold, size: 22),
        ),
      ),
    );
  }
}
