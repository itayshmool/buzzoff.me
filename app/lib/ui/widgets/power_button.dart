import 'package:flutter/material.dart';

import '../../services/orchestrator.dart';
import '../theme/racing_colors.dart';

class PowerButton extends StatelessWidget {
  final DrivingState state;
  final VoidCallback onToggle;

  const PowerButton({
    super.key,
    required this.state,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final (color, glowAlpha) = switch (state) {
      DrivingState.driving => (RacingColors.shellGreen, 0.5),
      DrivingState.stopping => (RacingColors.coinGold, 0.4),
      DrivingState.idle => (Colors.grey, 0.0),
    };

    final isActive = state != DrivingState.idle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Material(
        color: RacingColors.trackSurface.withValues(alpha: 0.9),
        shape: CircleBorder(
          side: BorderSide(
            color: color.withValues(alpha: isActive ? 0.8 : 0.4),
            width: isActive ? 2 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Icon(
              Icons.power_settings_new,
              color: color,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }
}
