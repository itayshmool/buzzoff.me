import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:buzzoff/core/model/camera.dart';
import 'package:buzzoff/core/proximity/proximity_engine.dart';
import 'package:buzzoff/core/proximity/alert_event.dart';
import 'package:buzzoff/services/location_service.dart';
import 'package:buzzoff/services/alert_service.dart';
import 'package:buzzoff/services/orchestrator.dart';

class FakeCameraQuery implements CameraQueryPort {
  final List<Camera> cameras;
  FakeCameraQuery(this.cameras);

  @override
  List<Camera> getCamerasInBounds(
      double minLat, double maxLat, double minLon, double maxLon) {
    return cameras.where((c) {
      return c.lat >= minLat &&
          c.lat <= maxLat &&
          c.lon >= minLon &&
          c.lon <= maxLon;
    }).toList();
  }
}

class FakeLocationService extends LocationService {
  final _controller = StreamController<LocationData>.broadcast();
  bool trackingStarted = false;
  bool trackingStopped = false;

  @override
  Stream<LocationData> get locationStream => _controller.stream;

  @override
  Future<void> startTracking() async {
    trackingStarted = true;
  }

  @override
  void stopTracking() {
    trackingStopped = true;
  }

  void emitLocation(LocationData data) {
    _controller.add(data);
  }
}

class FakeAlertService extends AlertService {
  final List<AlertEvent> triggeredAlerts = [];

  @override
  Future<void> triggerAlert(AlertEvent event) async {
    triggeredAlerts.add(event);
  }
}

LocationData _loc({
  double lat = 32.0853,
  double lon = 34.7818,
  double speedMs = 16.7, // ~60 km/h
  double heading = 0.0,
}) {
  return LocationData(
    latitude: lat,
    longitude: lon,
    speed: speedMs,
    heading: heading,
    accuracy: 5.0,
    timestamp: DateTime.now(),
  );
}

void main() {
  group('Orchestrator', () {
    late FakeLocationService locationService;
    late FakeAlertService alertService;
    late ProximityEngine proximityEngine;
    late Orchestrator orchestrator;

    setUp(() {
      locationService = FakeLocationService();
      alertService = FakeAlertService();

      // Camera 600m north of user
      final cameras = [
        Camera(
          id: 1,
          lat: 32.0907,
          lon: 34.7818,
          type: CameraType.fixedSpeed,
          speedLimit: 80,
        ),
      ];
      proximityEngine = ProximityEngine(FakeCameraQuery(cameras));

      orchestrator = Orchestrator(
        proximityEngine: proximityEngine,
        locationService: locationService,
        alertService: alertService,
        minSpeedKmh: 40.0,
      );
    });

    test('starts in idle state', () {
      expect(orchestrator.state, DrivingState.idle);
    });

    test('transitions to driving when startDriving called', () async {
      await orchestrator.startDriving();
      expect(orchestrator.state, DrivingState.driving);
      expect(locationService.trackingStarted, isTrue);
    });

    test('transitions to idle when stopDriving called', () async {
      await orchestrator.startDriving();
      orchestrator.stopDriving();
      expect(orchestrator.state, DrivingState.idle);
      expect(locationService.trackingStopped, isTrue);
    });

    test('transitions to stopping state with 2-min delay', () async {
      await orchestrator.startDriving();
      orchestrator.scheduleStopping();
      expect(orchestrator.state, DrivingState.stopping);
    });

    test('cancels stopping when cancelStopping called', () async {
      await orchestrator.startDriving();
      orchestrator.scheduleStopping();
      orchestrator.cancelStopping();
      expect(orchestrator.state, DrivingState.driving);
    });

    test('triggers alert when location near camera above speed', () async {
      await orchestrator.startDriving();

      // Emit location heading north at ~60 km/h, camera is 600m north
      locationService.emitLocation(_loc());

      // Give the stream listener time to process
      await Future.delayed(Duration.zero);

      expect(alertService.triggeredAlerts, hasLength(1));
      expect(alertService.triggeredAlerts.first.level, AlertLevel.approaching);
    });

    test('does not trigger alert when speed is below threshold', () async {
      await orchestrator.startDriving();

      // Emit location at ~20 km/h (below 40 km/h threshold)
      locationService.emitLocation(_loc(speedMs: 5.5));

      await Future.delayed(Duration.zero);

      expect(alertService.triggeredAlerts, isEmpty);
    });

    test('does not start tracking twice', () async {
      await orchestrator.startDriving();
      await orchestrator.startDriving();
      expect(orchestrator.state, DrivingState.driving);
    });

    tearDown(() {
      orchestrator.dispose();
    });
  });
}
