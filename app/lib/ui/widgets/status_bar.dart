import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/orchestrator.dart';
import '../theme/racing_colors.dart';

class StatusBar extends StatelessWidget {
  final DrivingState state;

  const StatusBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final (text, color, icon) = switch (state) {
      DrivingState.driving => ('RACING', RacingColors.shellGreen, Icons.flag),
      DrivingState.stopping => ('PIT STOP', RacingColors.coinGold, Icons.local_gas_station),
      DrivingState.idle => ('START LINE', Colors.grey, Icons.sports_score),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: RacingColors.trackSurface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.pressStart2p(
              fontSize: 9,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
