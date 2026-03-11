import 'package:flutter/material.dart';

import '../theme/racing_colors.dart';

/// Thin horizontal rainbow gradient line.
class RainbowDivider extends StatelessWidget {
  const RainbowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        gradient: RacingColors.rainbowGradient,
        borderRadius: BorderRadius.all(Radius.circular(1)),
      ),
    );
  }
}

/// Card with a diagonal racing stripe accent on the left.
class RacingStripeCard extends StatelessWidget {
  final Widget child;
  final Color stripeColor;

  const RacingStripeCard({
    super.key,
    required this.child,
    this.stripeColor = RacingColors.racingRed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RacingColors.trackSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: RacingColors.coinGold.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Racing stripe accent
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: Container(color: stripeColor),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: child,
          ),
        ],
      ),
    );
  }
}
