import 'package:shared_preferences/shared_preferences.dart';

import '../../core/model/app_settings.dart';

class UserPreferences {
  static const _keyAlertDistance = 'alert_distance';
  static const _keyVibrationEnabled = 'vibration_enabled';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyActivateAtSpeed = 'activate_at_speed';
  static const _keySpeedCameras = 'speed_cameras_enabled';
  static const _keyRedLightCameras = 'red_light_cameras_enabled';
  static const _keyAvgSpeedZones = 'avg_speed_zones_enabled';
  static const _keySleepAfterMinutes = 'sleep_after_minutes';

  final SharedPreferences _prefs;

  UserPreferences(this._prefs);

  AppSettings load() {
    return AppSettings(
      alertDistanceMeters: _prefs.getDouble(_keyAlertDistance) ?? 800.0,
      vibrationEnabled: _prefs.getBool(_keyVibrationEnabled) ?? true,
      soundEnabled: _prefs.getBool(_keySoundEnabled) ?? false,
      activateAtSpeedKmh: _prefs.getDouble(_keyActivateAtSpeed) ?? 40.0,
      speedCamerasEnabled: _prefs.getBool(_keySpeedCameras) ?? true,
      redLightCamerasEnabled: _prefs.getBool(_keyRedLightCameras) ?? true,
      avgSpeedZonesEnabled: _prefs.getBool(_keyAvgSpeedZones) ?? true,
      sleepAfterMinutes: _prefs.getInt(_keySleepAfterMinutes) ?? 5,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _prefs.setDouble(_keyAlertDistance, settings.alertDistanceMeters);
    await _prefs.setBool(_keyVibrationEnabled, settings.vibrationEnabled);
    await _prefs.setBool(_keySoundEnabled, settings.soundEnabled);
    await _prefs.setDouble(_keyActivateAtSpeed, settings.activateAtSpeedKmh);
    await _prefs.setBool(_keySpeedCameras, settings.speedCamerasEnabled);
    await _prefs.setBool(_keyRedLightCameras, settings.redLightCamerasEnabled);
    await _prefs.setBool(_keyAvgSpeedZones, settings.avgSpeedZonesEnabled);
    await _prefs.setInt(_keySleepAfterMinutes, settings.sleepAfterMinutes);
  }
}
