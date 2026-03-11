import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

typedef ShakeCallback = void Function();

class ShakeDetector {
  final ShakeCallback onShake;
  final double shakeThreshold;
  final Duration debounceDuration;

  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime? _lastShakeTime;

  ShakeDetector({
    required this.onShake,
    this.shakeThreshold = 15.0,
    this.debounceDuration = const Duration(milliseconds: 1500),
  });

  void start() {
    if (_subscription != null) return;
    _subscription = accelerometerEventStream().listen(_onAccelerometer);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onAccelerometer(AccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z,
    );

    // Subtract gravity (~9.8) to get user-caused acceleration
    final userAcceleration = (magnitude - 9.81).abs();

    if (userAcceleration < shakeThreshold) return;

    final now = DateTime.now();
    if (_lastShakeTime != null &&
        now.difference(_lastShakeTime!) < debounceDuration) {
      return;
    }

    _lastShakeTime = now;
    onShake();
  }

  void dispose() {
    stop();
    _lastShakeTime = null;
  }
}

typedef VoidCallback = void Function();
