import 'dart:async';

import '../core/proximity/proximity_engine.dart';
import 'alert_service.dart';
import 'foreground_task.dart';
import 'location_service.dart';

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
  final void Function(DrivingState)? onStateChange;

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
    this.onStateChange,
  })  : _proximityEngine = proximityEngine,
        _locationService = locationService,
        _alertService = alertService,
        _minSpeedKmh = minSpeedKmh;

  void _setState(DrivingState newState) {
    if (_state == newState) return;
    _state = newState;
    _alertService.updateDrivingState(newState);
    ForegroundTaskService.updateForState(newState);
    onStateChange?.call(newState);
  }

  Future<void> startMonitoring() async {
    if (_locationSub != null) return;

    await _locationService.startTracking();
    _locationSub = _locationService.locationStream.listen(_onLocation);
  }

  Future<void> startDriving() async {
    if (_state == DrivingState.driving) return;

    _cancelStopTimer();
    _setState(DrivingState.driving);
    _proximityEngine.reset();

    await _locationService.startTracking();
    _locationSub ??= _locationService.locationStream.listen(_onLocation);
  }

  void scheduleStopping() {
    if (_state != DrivingState.driving) return;

    _setState(DrivingState.stopping);
    _stopTimer = Timer(const Duration(minutes: 2), () {
      stopDriving();
    });
  }

  void cancelStopping() {
    if (_state != DrivingState.stopping) return;
    _cancelStopTimer();
    _setState(DrivingState.driving);
  }

  void stopDriving() {
    _cancelStopTimer();
    _proximityEngine.reset();
    _setState(DrivingState.idle);
    _lowSpeedSince = null;
    // Keep location subscription alive for auto-resume
  }

  void _onLocation(LocationData loc) {
    // Auto-detect driving based on speed
    if (loc.speedKmh >= _minSpeedKmh && _state == DrivingState.idle) {
      startDriving();
      return;
    }

    if (_state == DrivingState.idle) return;

    if (loc.speedKmh < _minSpeedKmh) {
      _lowSpeedSince ??= DateTime.now();
      final lowDuration = DateTime.now().difference(_lowSpeedSince!);
      if (lowDuration.inMinutes >= 5) {
        stopDriving();
      } else if (_state == DrivingState.driving &&
          lowDuration.inSeconds >= 30) {
        scheduleStopping();
      }
      return;
    }

    _lowSpeedSince = null;
    if (_state == DrivingState.stopping) {
      cancelStopping();
    }

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
    _locationSub?.cancel();
    _locationSub = null;
    _locationService.stopTracking();
  }
}
