import 'package:flutter_test/flutter_test.dart';

import 'package:buzzoff/core/model/country.dart';
import 'package:buzzoff/core/model/installed_pack.dart';
import 'package:buzzoff/services/auto_country_switcher.dart';

/// Fake bounds provider for testing.
class FakeBoundsProvider implements BoundsProvider {
  final Map<String, ({double north, double south, double east, double west})> _bounds = {};

  void addBounds(String countryCode, double north, double south, double east, double west) {
    _bounds[countryCode] = (north: north, south: south, east: east, west: west);
  }

  @override
  ({double north, double south, double east, double west})? getBounds(String countryCode) {
    return _bounds[countryCode];
  }
}

void main() {
  group('AutoCountrySwitcher', () {
    test('returns none when inside active country bounds', () {
      final bounds = FakeBoundsProvider();
      bounds.addBounds('IL', 33.5, 29.0, 36.0, 34.0); // Israel approx bounds

      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      final action = switcher.checkLocation(
        lat: 32.08,
        lon: 34.78,
        activeCountry: 'IL',
        installedPacks: [
          InstalledPack(countryCode: 'IL', version: 3, filePath: '/packs/IL/current.db', installedAt: DateTime.now()),
        ],
        cachedCountries: null,
      );

      expect(action, isA<CountrySwitchNone>());
    });

    test('returns autoSwitch when inside a different installed pack', () {
      final bounds = FakeBoundsProvider();
      bounds.addBounds('IL', 33.5, 29.0, 36.0, 34.0);
      bounds.addBounds('DE', 55.0, 47.0, 15.0, 5.0); // Germany approx bounds

      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      // User is in Germany (Munich ~48.13, 11.58), active country is Israel
      final action = switcher.checkLocation(
        lat: 48.13,
        lon: 11.58,
        activeCountry: 'IL',
        installedPacks: [
          InstalledPack(countryCode: 'IL', version: 3, filePath: '/packs/IL/current.db', installedAt: DateTime.now()),
          InstalledPack(countryCode: 'DE', version: 1, filePath: '/packs/DE/current.db', installedAt: DateTime.now()),
        ],
        cachedCountries: null,
      );

      expect(action, isA<CountrySwitchAutoSwitch>());
      expect((action as CountrySwitchAutoSwitch).countryCode, 'DE');
    });

    test('returns promptDownload when inside an available but not installed country', () {
      final bounds = FakeBoundsProvider();
      bounds.addBounds('IL', 33.5, 29.0, 36.0, 34.0);

      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      final germany = const Country(
        code: 'DE', name: 'Germany', packVersion: 1, cameraCount: 2341,
      );

      // User is in Germany, only IL installed, DE available
      final action = switcher.checkLocation(
        lat: 48.13,
        lon: 11.58,
        activeCountry: 'IL',
        installedPacks: [
          InstalledPack(countryCode: 'IL', version: 3, filePath: '/packs/IL/current.db', installedAt: DateTime.now()),
        ],
        cachedCountries: [
          const Country(code: 'IL', name: 'Israel', packVersion: 3, cameraCount: 147),
          germany,
        ],
        countryBoundsOverride: {
          'DE': (north: 55.0, south: 47.0, east: 15.0, west: 5.0),
        },
      );

      expect(action, isA<CountrySwitchPromptDownload>());
      expect((action as CountrySwitchPromptDownload).country.code, 'DE');
    });

    test('returns noDataAvailable when no pack matches location', () {
      final bounds = FakeBoundsProvider();
      bounds.addBounds('IL', 33.5, 29.0, 36.0, 34.0);

      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      // User is in Antarctica, nothing matches
      final action = switcher.checkLocation(
        lat: -75.0,
        lon: 0.0,
        activeCountry: 'IL',
        installedPacks: [
          InstalledPack(countryCode: 'IL', version: 3, filePath: '/packs/IL/current.db', installedAt: DateTime.now()),
        ],
        cachedCountries: [
          const Country(code: 'IL', name: 'Israel', packVersion: 3, cameraCount: 147),
        ],
        countryBoundsOverride: {},
      );

      expect(action, isA<CountrySwitchNoData>());
    });

    test('returns none when no active country and no packs installed', () {
      final bounds = FakeBoundsProvider();
      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      final action = switcher.checkLocation(
        lat: 32.08,
        lon: 34.78,
        activeCountry: null,
        installedPacks: [],
        cachedCountries: null,
      );

      expect(action, isA<CountrySwitchNone>());
    });

    test('returns none when cached countries is null and not inside any installed pack', () {
      final bounds = FakeBoundsProvider();
      bounds.addBounds('IL', 33.5, 29.0, 36.0, 34.0);

      final switcher = AutoCountrySwitcher(boundsProvider: bounds);

      // User is in Germany, only IL installed, no cached countries
      final action = switcher.checkLocation(
        lat: 48.13,
        lon: 11.58,
        activeCountry: 'IL',
        installedPacks: [
          InstalledPack(countryCode: 'IL', version: 3, filePath: '/packs/IL/current.db', installedAt: DateTime.now()),
        ],
        cachedCountries: null,
      );

      expect(action, isA<CountrySwitchNone>());
    });
  });
}
