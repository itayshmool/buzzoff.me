import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/racing_colors.dart';

class Speedometer extends StatelessWidget {
  final double speedKmh;
  final int? speedLimit;

  const Speedometer({
    super.key,
    required this.speedKmh,
    this.speedLimit,
  });

  @override
  Widget build(BuildContext context) {
    final displaySpeed = speedKmh.round();
    final overLimit = speedLimit != null && speedKmh > speedLimit!;

    return SizedBox(
      width: 96,
      height: 96,
      child: CustomPaint(
        painter: _SpeedometerPainter(
          speedKmh: speedKmh,
          speedLimit: speedLimit,
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
                'km/h',
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
  final double speedKmh;
  final int? speedLimit;

  _SpeedometerPainter({required this.speedKmh, this.speedLimit});

  static const _startAngle = 135.0; // degrees, bottom-left
  static const _sweepRange = 270.0; // degrees, full arc
  static const _maxSpeed = 180.0; // km/h for full arc

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
    final fraction = (speedKmh / _maxSpeed).clamp(0.0, 1.0);
    if (fraction > 0) {
      final overLimit = speedLimit != null && speedKmh > speedLimit!;
      final arcColor = overLimit
          ? RacingColors.racingRed
          : speedKmh > 100
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
      final limitFraction = (speedLimit! / _maxSpeed).clamp(0.0, 1.0);
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
      oldDelegate.speedKmh != speedKmh || oldDelegate.speedLimit != speedLimit;
}
