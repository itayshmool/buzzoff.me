import 'package:vibration/vibration.dart';

import '../core/model/camera.dart';
import '../core/proximity/alert_event.dart';
import 'foreground_task.dart';
import 'orchestrator.dart';

class VibrationPatterns {
  VibrationPatterns._();

  // Pattern: [pause, vibrate, pause, vibrate, ...]
  static const approaching = [0, 100, 200, 100]; // ..
  static const close = [0, 500]; // ---
  static const avgZoneEnter = [0, 100, 150, 100, 150, 100]; // ...
  static const avgZoneWarn = [0, 200]; // .

  // Amplitudes
  static const approachingAmp = [0, 180, 0, 180];
  static const closeAmp = [0, 255];
}

class AlertService {
  DrivingState _currentDrivingState = DrivingState.idle;

  void updateDrivingState(DrivingState state) {
    _currentDrivingState = state;
  }

  Future<void> triggerAlert(AlertEvent event) async {
    // Vibration
    final bool? vibratorResult = await Vibration.hasVibrator();
    final hasVibrator = vibratorResult ?? false;
    if (hasVibrator) {
      final pattern = switch (event.level) {
        AlertLevel.approaching => VibrationPatterns.approaching,
        AlertLevel.close => VibrationPatterns.close,
      };
      await Vibration.vibrate(pattern: pattern);
    }

    // Push notification
    final distanceText = event.distanceMeters < 1000
        ? '${event.distanceMeters.round()}m'
        : '${(event.distanceMeters / 1000).toStringAsFixed(1)}km';

    final typeLabel = switch (event.camera.type) {
      CameraType.fixedSpeed => 'Speed camera',
      CameraType.redLight => 'Red light camera',
      CameraType.avgSpeedStart => 'Avg speed zone start',
      CameraType.avgSpeedEnd => 'Avg speed zone end',
      CameraType.mobileZone => 'Mobile camera zone',
    };

    final message = switch (event.level) {
      AlertLevel.approaching => '$typeLabel ahead  $distanceText',
      AlertLevel.close => '$typeLabel nearby  $distanceText',
    };

    ForegroundTaskService.showCameraAlert(message, _currentDrivingState);
  }
}
