import 'package:vibration/vibration.dart';

import '../core/proximity/alert_event.dart';

class VibrationPatterns {
  VibrationPatterns._();

  // Pattern: [pause, vibrate, pause, vibrate, ...]
  static const approaching = [0, 100, 200, 100]; // ∙∙
  static const close = [0, 500]; // ———
  static const avgZoneEnter = [0, 100, 150, 100, 150, 100]; // ∙∙∙
  static const avgZoneWarn = [0, 200]; // ∙

  // Amplitudes
  static const approachingAmp = [0, 180, 0, 180];
  static const closeAmp = [0, 255];
}

class AlertService {
  Future<void> triggerAlert(AlertEvent event) async {
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (!hasVibrator) return;

    final pattern = switch (event.level) {
      AlertLevel.approaching => VibrationPatterns.approaching,
      AlertLevel.close => VibrationPatterns.close,
    };

    await Vibration.vibrate(pattern: pattern);
  }
}
