import 'dart:async';

import '../core/proximity/proximity_engine.dart';
import 'location_service.dart';
import 'alert_service.dart';

enum DrivingState {
  idle,
  driving,
  stopping,
}

class Orchestrator {
  final ProximityEngine _proximityEngine;
  final LocationService _locationService;
  final AlertService _alertService;
  final double _minSpeedKmh;

  StreamSubscription<LocationData>? _locationSub;
  DrivingState _state = DrivingState.idle;
  Timer? _stopTimer;
  DateTime? _lowSpeedSince;

  DrivingState get state => _state;

  Orchestrator({
    required ProximityEngine proximityEngine,
    required LocationService locationService,
    required AlertService alertService,
    double minSpeedKmh = 40.0,
  })  : _proximityEngine = proximityEngine,
        _locationService = locationService,
        _alertService = alertService,
        _minSpeedKmh = minSpeedKmh;

  Future<void> startDriving() async {
    if (_state == DrivingState.driving) return;

    _cancelStopTimer();
    _state = DrivingState.driving;
    _proximityEngine.reset();

    await _locationService.startTracking();
    _locationSub = _locationService.locationStream.listen(_onLocation);
  }

  void scheduleStopping() {
    if (_state != DrivingState.driving) return;

    _state = DrivingState.stopping;
    _stopTimer = Timer(const Duration(minutes: 2), () {
      stopDriving();
    });
  }

  void cancelStopping() {
    if (_state != DrivingState.stopping) return;
    _cancelStopTimer();
    _state = DrivingState.driving;
  }

  void stopDriving() {
    _cancelStopTimer();
    _locationSub?.cancel();
    _locationSub = null;
    _locationService.stopTracking();
    _proximityEngine.reset();
    _state = DrivingState.idle;
    _lowSpeedSince = null;
  }

  void _onLocation(LocationData loc) {
    if (loc.speedKmh < _minSpeedKmh) {
      _lowSpeedSince ??= DateTime.now();
      final lowDuration = DateTime.now().difference(_lowSpeedSince!);
      if (lowDuration.inMinutes >= 5) {
        stopDriving();
      }
      return;
    }

    _lowSpeedSince = null;

    final alerts = _proximityEngine.check(
      loc.latitude,
      loc.longitude,
      loc.heading,
      loc.speedKmh,
    );

    for (final alert in alerts) {
      _alertService.triggerAlert(alert);
    }
  }

  void _cancelStopTimer() {
    _stopTimer?.cancel();
    _stopTimer = null;
  }

  void dispose() {
    stopDriving();
  }
}
