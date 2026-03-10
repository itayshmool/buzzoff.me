class AppSettings {
  final double alertDistanceMeters;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final double activateAtSpeedKmh;
  final bool speedCamerasEnabled;
  final bool redLightCamerasEnabled;
  final bool avgSpeedZonesEnabled;

  const AppSettings({
    this.alertDistanceMeters = 800.0,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.activateAtSpeedKmh = 40.0,
    this.speedCamerasEnabled = true,
    this.redLightCamerasEnabled = true,
    this.avgSpeedZonesEnabled = true,
  });

  AppSettings copyWith({
    double? alertDistanceMeters,
    bool? vibrationEnabled,
    bool? soundEnabled,
    double? activateAtSpeedKmh,
    bool? speedCamerasEnabled,
    bool? redLightCamerasEnabled,
    bool? avgSpeedZonesEnabled,
  }) {
    return AppSettings(
      alertDistanceMeters: alertDistanceMeters ?? this.alertDistanceMeters,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      activateAtSpeedKmh: activateAtSpeedKmh ?? this.activateAtSpeedKmh,
      speedCamerasEnabled: speedCamerasEnabled ?? this.speedCamerasEnabled,
      redLightCamerasEnabled:
          redLightCamerasEnabled ?? this.redLightCamerasEnabled,
      avgSpeedZonesEnabled:
          avgSpeedZonesEnabled ?? this.avgSpeedZonesEnabled,
    );
  }
}
