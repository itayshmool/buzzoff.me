# Phase 3: Pack System in App

## Goal

Connect the Android app to the backend. Replace the hardcoded test dataset with downloadable country packs. Implement pack management: download, install, switch, update, and auto-detect country by GPS.

## Depends On

- Phase 1 (backend serving packs via API)
- Phase 2 (Android core engine working with local SQLite)

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
Room database points to downloaded pack
    │
    ▼
[Normal operation — same as Phase 2]
    │
    ▼
[Weekly, on WiFi] WorkManager checks for updates
    │  (fetches /api/v1/packs/IL/meta → compares version)
    │
    ├── Same version → do nothing
    └── New version → download in background → swap atomically
```

## Pack Storage Strategy

```
/data/data/com.buzzoff/files/
├── packs/
│   ├── IL/
│   │   ├── current.db        ← active pack (symlink or copy)
│   │   ├── v3.db             ← downloaded version
│   │   └── v4.db             ← newer version (downloaded, pending swap)
│   └── DE/
│       ├── current.db
│       └── v1.db
└── active_country.txt         ← "IL"
```

Atomic swap: download new version to temp file → verify checksum → rename to vN.db → update current.db → delete old version.

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

```kotlin
class PackManager @Inject constructor(
    private val packApi: PackApiService,
    private val packStorage: PackStorage,
    private val database: CameraDatabase,
    private val preferences: UserPreferences
) {
    suspend fun getAvailableCountries(): List<CountryInfo>
    suspend fun downloadPack(countryCode: String, onProgress: (Float) -> Unit)
    suspend fun installPack(countryCode: String, version: Int)
    suspend fun switchCountry(countryCode: String)
    suspend fun checkForUpdates(countryCode: String): UpdateInfo?
    suspend fun getInstalledPacks(): List<InstalledPack>
    suspend fun deletePack(countryCode: String)
    fun getActiveCountry(): String?
}
```

### PackApiService (Retrofit)

```kotlin
interface PackApiService {
    @GET("api/v1/countries")
    suspend fun getCountries(): List<CountryResponse>

    @GET("api/v1/packs/{country}/meta")
    suspend fun getPackMeta(@Path("country") code: String): PackMetaResponse

    @GET("api/v1/packs/{country}/data")
    @Streaming
    suspend fun downloadPack(@Path("country") code: String): ResponseBody
}
```

### PackUpdateWorker (WorkManager)

```kotlin
class PackUpdateWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        // Only runs on WiFi (constraint set at scheduling time)
        val activeCountry = packManager.getActiveCountry() ?: return Result.success()
        val update = packManager.checkForUpdates(activeCountry) ?: return Result.success()

        packManager.downloadPack(activeCountry) { progress -> setProgress(progress) }
        packManager.installPack(activeCountry, update.version)

        return Result.success()
    }
}

// Scheduled once on app start:
val constraints = Constraints.Builder()
    .setRequiredNetworkType(NetworkType.UNMETERED)  // WiFi only
    .build()

val updateWork = PeriodicWorkRequestBuilder<PackUpdateWorker>(7, TimeUnit.DAYS)
    .setConstraints(constraints)
    .build()

WorkManager.getInstance(context).enqueueUniquePeriodicWork(
    "pack_update", ExistingPeriodicWorkPolicy.KEEP, updateWork
)
```

### AutoCountrySwitcher

```kotlin
class AutoCountrySwitcher @Inject constructor(
    private val packManager: PackManager,
    private val preferences: UserPreferences
) {
    private var cachedCountries: List<CountryBounds>? = null
    private var lastCheck: Long = 0

    fun checkLocation(lat: Double, lon: Double): CountrySwitchAction {
        val active = packManager.getActiveCountry()

        // Check active pack bounds
        if (active != null && isInsideBounds(lat, lon, active)) {
            return CountrySwitchAction.None
        }

        // Check other installed packs
        val installed = packManager.getInstalledPacks()
        for (pack in installed) {
            if (pack.countryCode != active && isInsideBounds(lat, lon, pack)) {
                return CountrySwitchAction.AutoSwitch(pack.countryCode)
            }
        }

        // Check available (not installed) countries - use cached list
        val available = cachedCountries ?: return CountrySwitchAction.None
        for (country in available) {
            if (country.code !in installed.map { it.countryCode }) {
                if (isInsideBounds(lat, lon, country)) {
                    return CountrySwitchAction.PromptDownload(country)
                }
            }
        }

        return CountrySwitchAction.NoDataAvailable
    }
}

sealed class CountrySwitchAction {
    object None : CountrySwitchAction()
    data class AutoSwitch(val countryCode: String) : CountrySwitchAction()
    data class PromptDownload(val country: CountryBounds) : CountrySwitchAction()
    object NoDataAvailable : CountrySwitchAction()
}
```

## Updated UI

### First Launch Setup

```
┌─────────────────────────────────┐
│ Welcome to BuzzOff           │
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
│ │ 🇮🇱 Israel               │     │
│ │    187 cameras · 45 KB   │     │
│ └─────────────────────────┘     │
│ ┌─────────────────────────┐     │
│ │ 🇩🇪 Germany              │     │
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
│ BuzzOff             [active] │
│                                 │
│ Country: Israel 🇮🇱              │
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

- [ ] App fetches country list from backend API on first launch
- [ ] User can select a country and download its pack
- [ ] Download shows progress indicator
- [ ] Downloaded pack is verified via SHA-256 checksum
- [ ] Proximity engine works with downloaded pack (not just bundled test data)
- [ ] WorkManager checks for pack updates weekly on WiFi
- [ ] Pack update downloads and swaps atomically (no downtime)
- [ ] Country auto-detection works when crossing between installed packs
- [ ] Country auto-detection prompts download for available but not installed packs
- [ ] User can manually switch between installed country packs
- [ ] User can delete a country pack to free space
- [ ] App works fully offline after initial pack download
- [ ] First launch setup flow completes cleanly (permissions → country → activate)
