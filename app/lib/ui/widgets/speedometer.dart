import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/racing_colors.dart';

class Speedometer extends StatelessWidget {
  /// Current speed in display units (km/h or mph).
  final double speed;

  /// Speed limit in display units (already converted), or null.
  final int? speedLimit;

  /// Unit label shown below the number ("km/h" or "mph").
  final String unitLabel;

  /// Max speed for the arc gauge (in display units).
  final double maxSpeed;

  const Speedometer({
    super.key,
    required this.speed,
    this.speedLimit,
    this.unitLabel = 'km/h',
    this.maxSpeed = 180,
  });

  @override
  Widget build(BuildContext context) {
    final displaySpeed = speed.round();
    final overLimit = speedLimit != null && speed > speedLimit!;

    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _SpeedometerPainter(
          speed: speed,
          speedLimit: speedLimit,
          maxSpeed: maxSpeed,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$displaySpeed',
                style: GoogleFonts.pressStart2p(
                  fontSize: 18,
                  color: overLimit ? RacingColors.racingRed : Colors.white,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unitLabel,
                style: GoogleFonts.russoOne(
                  fontSize: 10,
                  color: Colors.white54,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final int? speedLimit;
  final double maxSpeed;

  _SpeedometerPainter({
    required this.speed,
    this.speedLimit,
    required this.maxSpeed,
  });

  static const _startAngle = 135.0;
  static const _sweepRange = 270.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background circle
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = RacingColors.trackSurface.withValues(alpha: 0.92)
        ..style = PaintingStyle.fill,
    );

    // Track arc (dim)
    final trackPaint = Paint()
      ..color = RacingColors.asphalt
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      _degToRad(_startAngle),
      _degToRad(_sweepRange),
      false,
      trackPaint,
    );

    // Speed arc (colored)
    final fraction = (speed / maxSpeed).clamp(0.0, 1.0);
    if (fraction > 0) {
      final overLimit = speedLimit != null && speed > speedLimit!;
      final arcColor = overLimit
          ? RacingColors.racingRed
          : fraction > 0.55
              ? RacingColors.coinGold
              : RacingColors.shellGreen;

      final speedPaint = Paint()
        ..color = arcColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        rect,
        _degToRad(_startAngle),
        _degToRad(_sweepRange * fraction),
        false,
        speedPaint,
      );
    }

    // Speed limit tick mark
    if (speedLimit != null) {
      final limitFraction = (speedLimit! / maxSpeed).clamp(0.0, 1.0);
      final tickAngle = _degToRad(_startAngle + _sweepRange * limitFraction);
      final innerR = radius - 5;
      final outerR = radius + 5;

      final tickPaint = Paint()
        ..color = RacingColors.racingRed.withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx + innerR * cos(tickAngle),
            center.dy + innerR * sin(tickAngle)),
        Offset(center.dx + outerR * cos(tickAngle),
            center.dy + outerR * sin(tickAngle)),
        tickPaint,
      );
    }

    // Outer ring
    canvas.drawCircle(
      center,
      radius + 4,
      Paint()
        ..color = RacingColors.coinGold.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  double _degToRad(double deg) => deg * pi / 180;

  @override
  bool shouldRepaint(_SpeedometerPainter oldDelegate) =>
      oldDelegate.speed != speed ||
      oldDelegate.speedLimit != speedLimit ||
      oldDelegate.maxSpeed != maxSpeed;
}
