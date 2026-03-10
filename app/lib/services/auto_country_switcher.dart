import '../core/model/country.dart';
import '../core/model/installed_pack.dart';

typedef Bounds = ({double north, double south, double east, double west});

/// Provides bounding boxes for country packs.
/// Implemented by reading meta table from installed pack SQLite files.
abstract class BoundsProvider {
  Bounds? getBounds(String countryCode);
}

/// Determines whether the user's GPS location requires a country switch.
class AutoCountrySwitcher {
  final BoundsProvider _boundsProvider;

  AutoCountrySwitcher({required BoundsProvider boundsProvider})
      : _boundsProvider = boundsProvider;

  CountrySwitchAction checkLocation({
    required double lat,
    required double lon,
    required String? activeCountry,
    required List<InstalledPack> installedPacks,
    required List<Country>? cachedCountries,
    Map<String, Bounds>? countryBoundsOverride,
  }) {
    // Check active pack bounds
    if (activeCountry != null && activeCountry.isNotEmpty) {
      if (_isInside(lat, lon, activeCountry)) {
        return const CountrySwitchNone();
      }
    }

    // Check other installed packs
    for (final pack in installedPacks) {
      if (pack.countryCode != activeCountry) {
        if (_isInside(lat, lon, pack.countryCode)) {
          return CountrySwitchAutoSwitch(pack.countryCode);
        }
      }
    }

    // Check available (not installed) countries
    if (cachedCountries == null) {
      return const CountrySwitchNone();
    }

    final installedCodes = installedPacks.map((p) => p.countryCode).toSet();
    for (final country in cachedCountries) {
      if (!installedCodes.contains(country.code)) {
        final bounds = countryBoundsOverride?[country.code];
        if (bounds != null && _isInsideBounds(lat, lon, bounds)) {
          return CountrySwitchPromptDownload(country);
        }
      }
    }

    return const CountrySwitchNoData();
  }

  bool _isInside(double lat, double lon, String countryCode) {
    final bounds = _boundsProvider.getBounds(countryCode);
    if (bounds == null) return false;
    return _isInsideBounds(lat, lon, bounds);
  }

  static bool _isInsideBounds(double lat, double lon, Bounds bounds) {
    return lat >= bounds.south &&
        lat <= bounds.north &&
        lon >= bounds.west &&
        lon <= bounds.east;
  }
}

sealed class CountrySwitchAction {
  const CountrySwitchAction();
}

class CountrySwitchNone extends CountrySwitchAction {
  const CountrySwitchNone();
}

class CountrySwitchAutoSwitch extends CountrySwitchAction {
  final String countryCode;
  const CountrySwitchAutoSwitch(this.countryCode);
}

class CountrySwitchPromptDownload extends CountrySwitchAction {
  final Country country;
  const CountrySwitchPromptDownload(this.country);
}

class CountrySwitchNoData extends CountrySwitchAction {
  const CountrySwitchNoData();
}
