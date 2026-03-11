import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'racing_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: RacingColors.racingRed,
      brightness: Brightness.dark,
      surface: RacingColors.trackDark,
      primary: RacingColors.racingRed,
      secondary: RacingColors.coinGold,
      tertiary: RacingColors.shellBlue,
    );

    final baseText = ThemeData.dark().textTheme;

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: RacingColors.trackDark,

      // Typography
      textTheme: GoogleFonts.russoOneTextTheme(baseText).copyWith(
        headlineLarge: GoogleFonts.pressStart2p(
          fontSize: 18,
          color: RacingColors.coinGold,
        ),
        headlineMedium: GoogleFonts.pressStart2p(
          fontSize: 14,
          color: RacingColors.coinGold,
        ),
        titleLarge: GoogleFonts.russoOne(fontSize: 22, color: Colors.white),
        titleMedium: GoogleFonts.russoOne(
            fontSize: 16, color: RacingColors.starYellow),
        bodyLarge: GoogleFonts.russoOne(fontSize: 16, color: Colors.white),
        bodyMedium: GoogleFonts.russoOne(fontSize: 14, color: Colors.white70),
        labelLarge: GoogleFonts.russoOne(fontSize: 14, color: Colors.white),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: RacingColors.trackSurface,
        foregroundColor: RacingColors.coinGold,
        titleTextStyle: GoogleFonts.pressStart2p(
          fontSize: 12,
          color: RacingColors.coinGold,
        ),
        elevation: 0,
      ),

      // Cards
      cardTheme: CardThemeData(
        color: RacingColors.trackSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: RacingColors.coinGold.withValues(alpha: 0.3), width: 0.5),
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: RacingColors.trackSurface,
        selectedColor: RacingColors.racingRed,
        labelStyle: GoogleFonts.russoOne(fontSize: 12),
        side: BorderSide(
            color: RacingColors.coinGold.withValues(alpha: 0.3), width: 0.5),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? RacingColors.shellGreen
                : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? RacingColors.shellGreen.withValues(alpha: 0.5)
                : Colors.grey.withValues(alpha: 0.3)),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: RacingColors.racingRed,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.russoOne(fontSize: 14),
        ),
      ),

      // BottomSheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: RacingColors.trackSurface,
      ),

      // Dialog
      dialogTheme: const DialogThemeData(
        backgroundColor: RacingColors.trackSurface,
      ),
    );
  }
}
