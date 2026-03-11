import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

import '../core/model/app_settings.dart';
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

  // Amplitudes (base values at high intensity)
  static const approachingAmp = [0, 180, 0, 180];
  static const closeAmp = [0, 255];

  static List<int> scaleAmplitudes(
      List<int> amps, VibrationIntensity intensity) {
    final scale = switch (intensity) {
      VibrationIntensity.low => 0.3,
      VibrationIntensity.medium => 0.6,
      VibrationIntensity.high => 1.0,
    };
    return amps.map((a) => (a * scale).round()).toList();
  }
}

class AlertService {
  DrivingState _currentDrivingState = DrivingState.idle;
  bool vibrationEnabled;
  bool soundEnabled;
  AlertSound alertSound;
  VibrationIntensity vibrationIntensity;
  final AudioPlayer _audioPlayer = AudioPlayer();

  AlertService({
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.alertSound = AlertSound.classicBeep,
    this.vibrationIntensity = VibrationIntensity.high,
  });

  void updateDrivingState(DrivingState state) {
    _currentDrivingState = state;
  }

  void updateSettings({
    required bool vibrationEnabled,
    required bool soundEnabled,
    required AlertSound alertSound,
    required VibrationIntensity vibrationIntensity,
  }) {
    this.vibrationEnabled = vibrationEnabled;
    this.soundEnabled = soundEnabled;
    this.alertSound = alertSound;
    this.vibrationIntensity = vibrationIntensity;
  }

  Future<void> triggerAlert(AlertEvent event) async {
    // Vibration
    if (vibrationEnabled) {
      final bool? vibratorResult = await Vibration.hasVibrator();
      final hasVibrator = vibratorResult ?? false;
      if (hasVibrator) {
        final pattern = switch (event.level) {
          AlertLevel.approaching => VibrationPatterns.approaching,
          AlertLevel.close => VibrationPatterns.close,
        };
        final baseAmps = switch (event.level) {
          AlertLevel.approaching => VibrationPatterns.approachingAmp,
          AlertLevel.close => VibrationPatterns.closeAmp,
        };
        final amps =
            VibrationPatterns.scaleAmplitudes(baseAmps, vibrationIntensity);
        await Vibration.vibrate(pattern: pattern, intensities: amps);
      }
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

    // Sound
    if (soundEnabled) {
      await _audioPlayer.play(AssetSource(alertSound.assetFilename));
    }

    ForegroundTaskService.showCameraAlert(message, _currentDrivingState);
  }

  Future<void> testVibration() async {
    final bool? vibratorResult = await Vibration.hasVibrator();
    final hasVibrator = vibratorResult ?? false;
    if (hasVibrator) {
      final amps = VibrationPatterns.scaleAmplitudes(
          VibrationPatterns.closeAmp, vibrationIntensity);
      await Vibration.vibrate(
          pattern: VibrationPatterns.close, intensities: amps);
    }
  }

  Future<void> testSound() async {
    await _audioPlayer.play(AssetSource(alertSound.assetFilename));
  }
}
