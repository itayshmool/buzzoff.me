import 'dart:async';

import 'package:flutter/foundation.dart' show protected;
import 'package:geolocator/geolocator.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final double speed; // m/s
  final double heading; // degrees
  final double accuracy;
  final DateTime timestamp;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.accuracy,
    required this.timestamp,
  });

  double get speedKmh => speed * 3.6;
}

class LocationService {
  StreamSubscription<Position>? _subscription;
  @protected
  final controller = StreamController<LocationData>.broadcast();

  Stream<LocationData> get locationStream => controller.stream;

  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<void> startTracking() async {
    if (_subscription != null) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _subscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((position) {
      controller.add(LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      ));
    });
  }

  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<LocationData?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    stopTracking();
    controller.close();
  }
}
