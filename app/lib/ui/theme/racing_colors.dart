import 'package:flutter/material.dart';

class RacingColors {
  RacingColors._();

  // Primary palette
  static const Color racingRed = Color(0xFFE52521);
  static const Color shellBlue = Color(0xFF049CD8);
  static const Color shellGreen = Color(0xFF43B047);
  static const Color coinGold = Color(0xFFFBD000);
  static const Color starYellow = Color(0xFFFFE135);
  static const Color bananaYellow = Color(0xFFFFD700);

  // Surface / background
  static const Color trackDark = Color(0xFF1A1A2E);
  static const Color trackSurface = Color(0xFF16213E);
  static const Color asphalt = Color(0xFF0F3460);

  // Rainbow gradient
  static const rainbowGradient = LinearGradient(
    colors: [
      Color(0xFFFF0000),
      Color(0xFFFF7F00),
      Color(0xFFFFFF00),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
      Color(0xFF8B00FF),
    ],
  );

  // Camera type colors (Mario Kart themed)
  static const Color cameraSpeed = shellBlue;
  static const Color cameraRedLight = racingRed;
  static const Color cameraAvgSpeed = starYellow;
  static const Color cameraMobile = bananaYellow;
}
