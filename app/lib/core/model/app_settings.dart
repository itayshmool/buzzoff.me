enum SpeedUnit { kmh, mph }

extension SpeedUnitX on SpeedUnit {
  String get label => switch (this) {
        SpeedUnit.kmh => 'km/h',
        SpeedUnit.mph => 'mph',
      };

  double convert(double kmh) => switch (this) {
        SpeedUnit.kmh => kmh,
        SpeedUnit.mph => kmh * 0.621371,
      };

  int convertLimit(int kmhLimit) => switch (this) {
        SpeedUnit.kmh => kmhLimit,
        SpeedUnit.mph => (kmhLimit * 0.621371).round(),
      };
}

enum VibrationIntensity { low, medium, high }

enum AlertSound {
  classicBeep,
  radarPing,
  siren,
  coin,
  shellWarning,
  raceHorn,
}

extension AlertSoundX on AlertSound {
  String get displayName => switch (this) {
        AlertSound.classicBeep => 'Classic Beep',
        AlertSound.radarPing => 'Radar Ping',
        AlertSound.siren => 'Siren',
        AlertSound.coin => 'Coin',
        AlertSound.shellWarning => 'Shell Warning',
        AlertSound.raceHorn => 'Race Horn',
      };

  String get assetFilename => switch (this) {
        AlertSound.classicBeep => 'alert_classic.wav',
        AlertSound.radarPing => 'alert_radar.wav',
        AlertSound.siren => 'alert_siren.wav',
        AlertSound.coin => 'alert_coin.wav',
        AlertSound.shellWarning => 'alert_shell.wav',
        AlertSound.raceHorn => 'alert_horn.wav',
      };
}

class AppSettings {
  final double alertDistanceMeters;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final AlertSound alertSound;
  final double activateAtSpeedKmh;
  final bool speedCamerasEnabled;
  final bool redLightCamerasEnabled;
  final bool avgSpeedZonesEnabled;
  final int sleepAfterMinutes;
  final VibrationIntensity vibrationIntensity;
  final SpeedUnit speedUnit;

  const AppSettings({
    this.alertDistanceMeters = 800.0,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.alertSound = AlertSound.classicBeep,
    this.activateAtSpeedKmh = 40.0,
    this.speedCamerasEnabled = true,
    this.redLightCamerasEnabled = true,
    this.avgSpeedZonesEnabled = true,
    this.sleepAfterMinutes = 5,
    this.vibrationIntensity = VibrationIntensity.high,
    this.speedUnit = SpeedUnit.kmh,
  });

  AppSettings copyWith({
    double? alertDistanceMeters,
    bool? vibrationEnabled,
    bool? soundEnabled,
    AlertSound? alertSound,
    double? activateAtSpeedKmh,
    bool? speedCamerasEnabled,
    bool? redLightCamerasEnabled,
    bool? avgSpeedZonesEnabled,
    int? sleepAfterMinutes,
    VibrationIntensity? vibrationIntensity,
    SpeedUnit? speedUnit,
  }) {
    return AppSettings(
      alertDistanceMeters: alertDistanceMeters ?? this.alertDistanceMeters,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      alertSound: alertSound ?? this.alertSound,
      activateAtSpeedKmh: activateAtSpeedKmh ?? this.activateAtSpeedKmh,
      speedCamerasEnabled: speedCamerasEnabled ?? this.speedCamerasEnabled,
      redLightCamerasEnabled:
          redLightCamerasEnabled ?? this.redLightCamerasEnabled,
      avgSpeedZonesEnabled:
          avgSpeedZonesEnabled ?? this.avgSpeedZonesEnabled,
      sleepAfterMinutes: sleepAfterMinutes ?? this.sleepAfterMinutes,
      vibrationIntensity: vibrationIntensity ?? this.vibrationIntensity,
      speedUnit: speedUnit ?? this.speedUnit,
    );
  }
}
