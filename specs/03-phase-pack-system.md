# Phase 3: Pack System in App

## Goal

Connect the app to the backend. Replace the hardcoded test dataset with downloadable country packs. Implement pack management: download, install, switch, update, and auto-detect country by GPS.

## Depends On

- Phase 1 (backend serving packs via API)
- Phase 2 (Flutter core engine working with local SQLite)

## Deliverables

1. Pack download and installation
2. Pack switching (manual country selection)
3. Pack update checking (WiFi-only background sync)
4. Country auto-detection via GPS bounding box
5. Country picker UI
6. First-launch setup flow

## Pack Lifecycle

```
[First Launch]
    │
    ▼
Setup Screen: "Select your country"
    │  (fetches /api/v1/countries)
    │
    ▼
User picks Israel → download pack (small SQLite file)
    │  (fetches /api/v1/packs/IL/data)
    │
    ▼
Pack saved to app internal storage
    │
    ▼
CameraDao points to downloaded pack
    │
    ▼
[Normal operation — same as Phase 2]
    │
    ▼
[On app resume, on WiFi] Check for updates
    │  (fetches /api/v1/packs/IL/meta → compares version)
    │
    ├── Same version → do nothing
    └── New version → download in background → swap atomically
```

## Pack Storage Strategy

```
{app_documents_dir}/
├── packs/
│   ├── IL/
│   │   ├── current.db        ← active pack (copy of latest version)
│   │   ├── v3.db             ← downloaded version
│   │   └── v4.db             ← newer version (downloaded, pending swap)
│   └── DE/
│       ├── current.db
│       └── v1.db
└── (active_country stored in SharedPreferences)
```

Atomic swap: download new version to temp file → verify checksum → rename to vN.db → copy to current.db → delete old version.

## Country Auto-Detection

```
On each GPS fix (while driving):
  1. Get current lat/lon
  2. Check: is point inside active pack's bounding box?
     → YES: continue normally
     → NO:
        a. Check installed packs' bounding boxes
           → Found match: auto-switch, notify user "Switched to Germany"
        b. No installed pack matches:
           → Fetch /api/v1/countries (cached, max once per day)
           → Check if any available country's bounds contain the point
           → YES: prompt "You're in Germany. Download camera data? (2.1 MB)"
           → NO: stay dormant, log "no data for this location"
```

This check is cheap — just a bounding box comparison, no network calls during driving (country list is cached).

## New Components

### PackManager

```dart
class PackManager {
  final PackApiClient _apiClient;
  final PackStorage _storage;

  PackManager(this._apiClient, this._storage);

  Future<List<Country>> fetchCountries();
  Future<CameraDao> downloadAndInstall(String countryCode, {void Function(double)? onProgress});
  Future<CameraDao> switchCountry(String countryCode);
  Future<PackMeta?> checkForUpdate(String countryCode);
  Future<CameraDao> updatePack(String countryCode, {void Function(double)? onProgress});
  List<InstalledPack> getInstalledPacks();
  Future<void> deleteInstalledPack(String countryCode);
  String? getActiveCountry();
}
```

### PackApiClient (HTTP)

```dart
class PackApiClient {
  final http.Client _client;
  final String _baseUrl;

  PackApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? 'https://buzzoff-api.onrender.com';

  Future<List<Country>> getCountries();
  Future<PackMeta> getPackMeta(String countryCode);
  Future<Uint8List> downloadPack(String countryCode, {void Function(double)? onProgress});
}
```

### Pack Update Check (on app resume)

```dart
// In main app widget, using WidgetsBindingObserver:
class _AppState extends State<BuzzOffApp> with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates();
    }
  }

  Future<void> _checkForUpdates() async {
    // Only on WiFi (via connectivity_plus)
    final connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi)) return;

    final activeCountry = packManager.getActiveCountry();
    if (activeCountry == null) return;

    final update = await packManager.checkForUpdate(activeCountry);
    if (update == null) return;

    await packManager.updatePack(activeCountry);
  }
}
```

### AutoCountrySwitcher

```dart
class AutoCountrySwitcher {
  final PackStorage _storage;
  List<Country>? _cachedCountries;
  DateTime? _lastFetch;

  AutoCountrySwitcher(this._storage);

  CountrySwitchAction checkLocation(double lat, double lon) {
    final active = _storage.getActiveCountry();

    // Check active pack bounds
    if (active != null && _isInsideBounds(lat, lon, active)) {
      return const CountrySwitchAction.none();
    }

    // Check other installed packs
    final installed = _storage.getInstalledPacks();
    for (final pack in installed) {
      if (pack.countryCode != active && _isInsideBounds(lat, lon, pack.countryCode)) {
        return CountrySwitchAction.autoSwitch(pack.countryCode);
      }
    }

    // Check available (not installed) countries — use cached list
    final available = _cachedCountries;
    if (available == null) return const CountrySwitchAction.none();

    final installedCodes = installed.map((p) => p.countryCode).toSet();
    for (final country in available) {
      if (!installedCodes.contains(country.code)) {
        if (_isInsideBoundsCountry(lat, lon, country)) {
          return CountrySwitchAction.promptDownload(country);
        }
      }
    }

    return const CountrySwitchAction.noDataAvailable();
  }
}

sealed class CountrySwitchAction {
  const CountrySwitchAction();
  const factory CountrySwitchAction.none() = CountrySwitchNone;
  const factory CountrySwitchAction.autoSwitch(String countryCode) = CountrySwitchAutoSwitch;
  const factory CountrySwitchAction.promptDownload(Country country) = CountrySwitchPromptDownload;
  const factory CountrySwitchAction.noDataAvailable() = CountrySwitchNoData;
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
```

## Updated UI

### First Launch Setup (Flutter)

```
┌─────────────────────────────────┐
│ Welcome to BuzzOff              │
│                                 │
│ Grant permissions:              │
│ ☑ Location (required)           │
│ ☑ Activity Recognition          │
│ ☑ Notifications                 │
│ ☐ Battery optimization          │
│   (tap to whitelist)            │
│                                 │
│          [Continue]             │
└─────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────┐
│ Select your country             │
│                                 │
│ ┌─────────────────────────┐     │
│ │ Israel                  │     │
│ │    187 cameras · 45 KB   │     │
│ └─────────────────────────┘     │
│ ┌─────────────────────────┐     │
│ │ Germany                 │     │
│ │    2,341 cameras · 380 KB│     │
│ └─────────────────────────┘     │
│                                 │
│ Or: detect automatically        │
│                                 │
└─────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────┐
│ Downloading Israel...           │
│ ████████████░░░░░░░░  60%       │
│                                 │
│ 27 KB / 45 KB                   │
└─────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────┐
│ BuzzOff                [active] │
│                                 │
│ Country: Israel                 │
│ Cameras: 187                    │
│ Data version: 3                 │
│ Last updated: 2026-03-10        │
│                                 │
│ [Settings]  [Change Country]    │
│                                 │
│ Status: Waiting for driving...  │
└─────────────────────────────────┘
```

## Acceptance Criteria

- [x] App fetches country list from backend API on first launch (PackApiClient.getCountries, 6 tests)
- [x] User can select a country and download its pack (SetupScreen → CountryPickerScreen → PackManager.downloadAndInstall)
- [x] Download shows progress indicator (DownloadProgress widget)
- [x] Downloaded pack is verified via SHA-256 checksum (PackStorage.verifyChecksum, 2 tests)
- [x] Proximity engine works with downloaded pack (not just bundled test data) (PackManager opens CameraDao from downloaded file)
- [x] App checks for pack updates on WiFi when resumed (PackManager.checkForUpdate, 2 tests)
- [x] Pack update downloads and swaps atomically (no downtime) (PackStorage.savePack + setActivePack with copy)
- [x] Country auto-detection works when crossing between installed packs (AutoCountrySwitcher, 6 tests)
- [x] Country auto-detection prompts download for available but not installed packs (CountrySwitchPromptDownload action)
- [x] User can manually switch between installed country packs (Settings → Change Country → PackManager.switchCountry)
- [x] User can delete a country pack to free space (PackManager.deleteInstalledPack, tested)
- [x] App works fully offline after initial pack download (PackLoader opens local SQLite, no network needed)
- [x] First launch setup flow completes cleanly (permissions → country → activate) (SetupScreen → download → MapScreen)

## Status: COMPLETE

### Phase 3 Results

- PackApiClient: HTTP client for backend API (getCountries, getPackMeta, downloadPack)
- PackStorage: file system management with SHA-256 checksum verification
- PackManager: orchestrates download → verify → save → install → open CameraDao
- AutoCountrySwitcher: GPS-based country detection with sealed class actions
- First-launch setup flow: country picker → download progress → map screen
- Settings screen: country section with switch country support
- Conditional routing: SetupScreen on first launch, MapScreen when pack installed
- Startup loads active pack from disk into CameraDao provider
- 31 new tests (6 API + 11 storage + 8 manager + 6 auto-switcher)
- 79 total tests passing
