class Distances {
  Distances._();
  static const double approachMeters = 800.0;
  static const double closeMeters = 400.0;
  static const double cooldownMeters = 200.0;
  static const double queryRadiusKm = 2.0;
}

class HeadingConfig {
  HeadingConfig._();
  static const double toleranceDegrees = 45.0;
}

class LocationConfig {
  LocationConfig._();
  static const int intervalMs = 3000;
  static const int fastestIntervalMs = 1000;
  static const double smallestDisplacementMeters = 10.0;
  static const double minSpeedKmh = 5.0;
  static const int parkingTimeoutMinutes = 5;
  static const int activityStopDelayMinutes = 2;
}
