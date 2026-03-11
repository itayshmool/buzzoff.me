import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/model/app_settings.dart';
import '../data/preferences/user_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final userPreferencesProvider = Provider<UserPreferences>((ref) {
  return UserPreferences(ref.watch(sharedPreferencesProvider));
});

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(userPreferencesProvider);
  return SettingsNotifier(prefs);
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final UserPreferences _prefs;

  SettingsNotifier(this._prefs) : super(_prefs.load());

  void updateAlertDistance(double meters) {
    state = state.copyWith(alertDistanceMeters: meters);
    _prefs.save(state);
  }

  void toggleVibration(bool enabled) {
    state = state.copyWith(vibrationEnabled: enabled);
    _prefs.save(state);
  }

  void toggleSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    _prefs.save(state);
  }

  void updateActivateAtSpeed(double kmh) {
    state = state.copyWith(activateAtSpeedKmh: kmh);
    _prefs.save(state);
  }

  void toggleSpeedCameras(bool enabled) {
    state = state.copyWith(speedCamerasEnabled: enabled);
    _prefs.save(state);
  }

  void toggleRedLightCameras(bool enabled) {
    state = state.copyWith(redLightCamerasEnabled: enabled);
    _prefs.save(state);
  }

  void toggleAvgSpeedZones(bool enabled) {
    state = state.copyWith(avgSpeedZonesEnabled: enabled);
    _prefs.save(state);
  }

  void updateSleepAfterMinutes(int minutes) {
    state = state.copyWith(sleepAfterMinutes: minutes);
    _prefs.save(state);
  }
}
