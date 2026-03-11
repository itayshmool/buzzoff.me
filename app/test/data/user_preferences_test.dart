import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buzzoff/data/preferences/user_preferences.dart';
import 'package:buzzoff/core/model/app_settings.dart';

void main() {
  group('UserPreferences', () {
    test('loads default settings when no prefs stored', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = UserPreferences(prefs);

      final settings = userPrefs.load();
      expect(settings.alertDistanceMeters, 800.0);
      expect(settings.vibrationEnabled, isTrue);
      expect(settings.soundEnabled, isFalse);
      expect(settings.activateAtSpeedKmh, 40.0);
      expect(settings.speedCamerasEnabled, isTrue);
      expect(settings.redLightCamerasEnabled, isTrue);
      expect(settings.avgSpeedZonesEnabled, isTrue);
      expect(settings.sleepAfterMinutes, 5);
    });

    test('saves and loads custom settings', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = UserPreferences(prefs);

      final custom = AppSettings(
        alertDistanceMeters: 1200.0,
        vibrationEnabled: false,
        soundEnabled: true,
        activateAtSpeedKmh: 50.0,
        speedCamerasEnabled: false,
        redLightCamerasEnabled: true,
        avgSpeedZonesEnabled: false,
        sleepAfterMinutes: 10,
      );

      await userPrefs.save(custom);
      final loaded = userPrefs.load();

      expect(loaded.alertDistanceMeters, 1200.0);
      expect(loaded.vibrationEnabled, isFalse);
      expect(loaded.soundEnabled, isTrue);
      expect(loaded.activateAtSpeedKmh, 50.0);
      expect(loaded.speedCamerasEnabled, isFalse);
      expect(loaded.redLightCamerasEnabled, isTrue);
      expect(loaded.avgSpeedZonesEnabled, isFalse);
      expect(loaded.sleepAfterMinutes, 10);
    });

    test('preserves unchanged defaults when saving partial update', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final userPrefs = UserPreferences(prefs);

      const defaults = AppSettings();
      final modified = defaults.copyWith(alertDistanceMeters: 500.0);
      await userPrefs.save(modified);

      final loaded = userPrefs.load();
      expect(loaded.alertDistanceMeters, 500.0);
      expect(loaded.vibrationEnabled, isTrue); // unchanged default
      expect(loaded.activateAtSpeedKmh, 40.0); // unchanged default
    });
  });
}
