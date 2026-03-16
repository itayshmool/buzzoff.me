# BuzzOff — Complete System Specification

## Overview

BuzzOff is a **Mario Kart-themed speed camera warning system**. It detects driving via GPS, alerts users (vibration, sound, notification) when approaching speed cameras, and distributes camera databases as downloadable SQLite packs. The system has four main components: a Flutter mobile app, a FastAPI backend, a React admin dashboard, and a data pipeline.

---

## Domain & Deployment

| Service | URL | Platform |
|---------|-----|----------|
| Website | `https://buzzoff.me` | GitHub Pages (`gh-pages` branch) |
| Backend API | `https://buzzoff-api.onrender.com` (or `https://buzzoff.me/api/`) | Render (Python) |
| Admin Dashboard | `https://admin.buzzoff.me` | Render (static) |
| APK Download | `https://admin.buzzoff.me/buzzoff.apk` | Hosted in admin/public/ |

- **Android package name**: `me.buzzoff.app` (NOT `com.buzzoff.app`)
- **Render service ID**: `srv-d6o8ltia214c73enbs9g`
- **Persistent disk**: 1GB at `/data/packs` for generated `.db` files
- **Admin credentials**: env vars `ADMIN_USERNAME`, `ADMIN_PASSWORD` on Render; `backend/.env` locally
- **Auth**: JWT (HS256, 24h expiry) via `POST /admin/api/auth/login`

---

## Key Paths

| Component | Path |
|-----------|------|
| Flutter app | `app/` |
| Backend API | `backend/` |
| Admin dashboard | `admin/` |
| Website source | `website/` |
| Python SDK | `sdk/` |
| Feature specs | `FEATURES/` |
| Phase specs | `specs/` |
| Store assets | `play-store-materials/` |
| App icon source | `app/assets/icon/buzzoff_icon.png` |
| Deploy config | `render.yaml`, `docker-compose.yml` |

---

## Design System — Mario Kart Theme

**CRITICAL: All UI changes MUST preserve the Mario Kart racing theme. Never replace themed widgets with plain Material widgets.**

### Color Palette (`app/lib/ui/theme/racing_colors.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| `racingRed` | `#E52521` | Primary accent, selected chips, section titles |
| `shellBlue` | `#049CD8` | Speed cameras ("Blue Shells") |
| `shellGreen` | `#43B047` | Active/driving state, switch thumb |
| `coinGold` | `#FBD000` | AppBar title, secondary accent, card borders |
| `starYellow` | `#FFE135` | Avg speed cameras ("Stars") |
| `bananaYellow` | `#FFD700` | Mobile camera zones ("Bananas") |
| `trackDark` | `#1A1A2E` | Scaffold background |
| `trackSurface` | `#16213E` | Cards, bottom sheets, dialogs |
| `asphalt` | `#0F3460` | Secondary surface |
| `rainbowGradient` | Red→Orange→Yellow→Green→Blue→Purple | Section dividers |

### Typography (`app/lib/ui/theme/app_theme.dart`)

| Style | Font | Usage |
|-------|------|-------|
| Headlines | `PressStart2P` | Retro arcade feel (titles, status bar) |
| Body/Labels | `RussoOne` | Futuristic racing feel (all other text) |

### Themed Widgets (ALWAYS use these, never plain alternatives)

| Widget | File | Purpose |
|--------|------|---------|
| `RainbowDivider` | `ui/widgets/racing_decorations.dart` | Section separator (2px rainbow gradient line) |
| `RacingStripeCard` | `ui/widgets/racing_decorations.dart` | Card with 4px left accent stripe + gold border |
| `PowerButton` | `ui/widgets/power_button.dart` | Circular start/stop button with glow by state |
| `StatusBar` | `ui/widgets/status_bar.dart` | Pill badges: "START LINE" / "RACING" / "PIT STOP" / "SIM" |
| `CameraFilterBar` | `ui/widgets/camera_filter_bar.dart` | Horizontal FilterChips: "Blue Shells", "Red Shells", "Stars", "Bananas" |
| `ZoomControls` | `ui/widgets/zoom_controls.dart` | Column of circular map control buttons |
| `CameraMarkerWidget` | `ui/widgets/camera_marker.dart` | Colored circle markers by camera type |
| `DownloadProgress` | `ui/widgets/download_progress.dart` | Pack download progress bar |

### Mario Kart Vocabulary

| Real term | Mario Kart name | Used in |
|-----------|-----------------|---------|
| Speed cameras | Blue Shells | Filter bar, settings |
| Red light cameras | Red Shells | Filter bar, settings |
| Avg speed zones | Stars / Star Zones | Filter bar, settings |
| Mobile camera zones | Bananas | Filter bar, settings |
| Settings screen | RACE SETUP | AppBar title |
| Alert distance | WARNING RANGE | Settings section |
| Vibration | RUMBLE | Settings section |
| Sound | HORN | Settings section |
| Min activation speed | MIN RACE SPEED | Settings section |
| Sleep timeout | PIT STOP TIMER | Settings section |
| Camera types | ITEM TYPES | Settings section |
| Country selection | TRACK REGION | Settings section |
| About | PIT CREW | Settings section |
| Idle state | START LINE | Status bar |
| Driving state | RACING | Status bar |
| Stopping state | PIT STOP | Status bar |

---

## Flutter App Architecture

### Entry Point (`app/lib/main.dart`)

```
main() → init ForegroundTask → load SharedPreferences → load PackStorage
       → open active pack (if exists) → ProviderScope with overrides → BuzzOffApp
```

`BuzzOffApp` routes to `MapScreen` if a country is active, or `SetupScreen` on first launch.

### Directory Structure

```
app/lib/
├── main.dart                     # Entry point (mobile)
├── main_preview.dart             # Entry point (web preview — flutter run -d chrome)
├── app.dart                      # Root widget (routes to Map or Setup)
├── core/
│   ├── geo/geo_utils.dart        # haversine(), bearing(), isAhead()
│   ├── model/
│   │   ├── app_settings.dart     # AppSettings + enums (AlertSound, VibrationIntensity)
│   │   ├── camera.dart           # Camera + CameraType enum
│   │   ├── country.dart          # Country model
│   │   ├── installed_pack.dart   # InstalledPack model
│   │   └── pack_meta.dart        # PackMeta model (version, checksum)
│   └── proximity/
│       ├── alert_event.dart      # AlertEvent + AlertLevel enum
│       └── proximity_engine.dart # Core detection algorithm
├── data/
│   ├── database/
│   │   ├── camera_dao.dart       # SQLite queries via R-tree
│   │   └── pack_loader.dart      # Open SQLite in read-only mode
│   └── preferences/
│       └── user_preferences.dart # SharedPreferences serialization
├── preview/
│   ├── mock_camera_dao.dart      # In-memory camera store (6 Tel Aviv cameras)
│   ├── mock_pack_storage.dart    # Stub PackStorage (no filesystem)
│   ├── preview_map_screen.dart   # Web-safe map (no ForegroundTask/sqlite3)
│   └── preview_settings_screen.dart # Web-safe settings (no PackManager/sqlite3)
├── providers/
│   ├── database_provider.dart    # cameraDaoProvider (CameraQueryPort?), cameraCountProvider
│   ├── driving_state_provider.dart  # orchestratorProvider, alertServiceProvider
│   ├── location_provider.dart    # locationServiceProvider, locationStreamProvider
│   ├── nearby_cameras_provider.dart # nearbyCamerasProvider (map viewport)
│   ├── pack_manager_provider.dart # packManagerProvider, countriesProvider (sqlite3 deps)
│   ├── pack_provider.dart        # packStorageProvider, activeCountryProvider (no sqlite3)
│   ├── settings_provider.dart    # settingsProvider (SettingsNotifier)
│   └── simulation_provider.dart  # simulationEnabledProvider (debug GPS)
├── services/
│   ├── alert_service.dart        # Vibration + sound + notification delivery
│   ├── auto_country_switcher.dart # GPS-based country detection
│   ├── foreground_task.dart      # Persistent Android notification
│   ├── location_service.dart     # GPS stream wrapper (geolocator)
│   ├── orchestrator.dart         # State machine: idle → driving → stopping
│   ├── pack_api_client.dart      # HTTP client for backend API
│   ├── pack_manager.dart         # Download, verify, install packs
│   ├── pack_storage.dart         # Filesystem management for .db files
│   ├── shake_detector.dart       # Accelerometer shake detection
│   └── simulated_location_service.dart # Fake GPS along Tel Aviv highway
├── ui/
│   ├── screens/
│   │   ├── map_screen.dart       # Main map with cameras, controls, filters
│   │   ├── settings_screen.dart  # Mario Kart styled settings
│   │   ├── country_picker_screen.dart # Country list for pack download
│   │   └── setup_screen.dart     # First-launch pack download
│   ├── theme/
│   │   ├── app_theme.dart        # Material theme with Google Fonts
│   │   └── racing_colors.dart    # Color constants
│   └── widgets/
│       ├── camera_filter_bar.dart # "Blue Shells (30)" filter chips
│       ├── camera_marker.dart    # Colored circle markers on map
│       ├── download_progress.dart # Pack download progress
│       ├── power_button.dart     # Circular start/stop with glow
│       ├── racing_decorations.dart # RainbowDivider + RacingStripeCard
│       ├── status_bar.dart       # "START LINE" / "RACING" / "PIT STOP" pills
│       └── zoom_controls.dart    # +/- zoom, my location, settings
└── util/
    └── constants.dart            # Distance thresholds, heading tolerance
```

### Core Engine

#### ProximityEngine (`core/proximity/proximity_engine.dart`)

| Constant | Value | Purpose |
|----------|-------|---------|
| `approachDistance` | 800m | First alert trigger |
| `closeDistance` | 400m | Second alert trigger |
| `headingTolerance` | 45° | Camera must be within ±45° of heading |
| `cooldownDistance` | 200m | Reset alerts after passing camera |
| `_latOffset` | 0.018 | ~2km latitude query radius |
| `_lonOffset` | 0.025 | ~2km longitude query radius |

**Algorithm**: Query R-tree bounds → for each camera: Haversine distance + bearing → `isAhead()` check → fire alert if within threshold and not already alerted → reset when camera is behind beyond cooldown.

**State**: `_alertedApproaching` and `_alertedClose` Set<int> prevent duplicate alerts per camera.

#### Orchestrator (`services/orchestrator.dart`)

State machine: `idle ←→ driving ←→ stopping → idle`

| Transition | Condition |
|------------|-----------|
| idle → driving | Speed ≥ `minSpeedKmh` (default 40) |
| driving → stopping | Speed < `minSpeedKmh` for `sleepAfterMinutes / 2` |
| stopping → idle | Speed < `minSpeedKmh` for full `sleepAfterMinutes` (default 5) |
| stopping → driving | Speed ≥ `minSpeedKmh` again |

On each location update while driving: calls `ProximityEngine.check()` → for each alert: `AlertService.triggerAlert()`.

#### AlertService (`services/alert_service.dart`)

| Alert Level | Vibration Pattern | Amplitude |
|-------------|-------------------|-----------|
| approaching | `[0,100,200,100]` (two short) | `[0,180,0,180]` × intensity |
| close | `[0,500]` (one long) | `[0,255]` × intensity |

**Intensity scaling**: low=30%, medium=60%, high=100%

**Sound**: Plays asset file via `audioplayers` (6 sound options: classicBeep, radarPing, siren, coin, shellWarning, raceHorn)

**Notification**: Via ForegroundTaskService — flash alert for 5 seconds, then revert to state notification.

### AppSettings (`core/model/app_settings.dart`)

| Setting | Type | Default | Options |
|---------|------|---------|---------|
| alertDistanceMeters | double | 800.0 | 500, 800, 1200 |
| vibrationEnabled | bool | true | — |
| vibrationIntensity | VibrationIntensity | high | low, medium, high |
| soundEnabled | bool | false | — |
| alertSound | AlertSound | classicBeep | 6 options |
| activateAtSpeedKmh | double | 40.0 | 30, 40, 50 |
| sleepAfterMinutes | int | 5 | 3, 5, 10, 15 |
| speedCamerasEnabled | bool | true | — |
| redLightCamerasEnabled | bool | true | — |
| avgSpeedZonesEnabled | bool | true | — |

### Pack System

**Download flow**: `PackApiClient.getPackMeta()` → `downloadPack()` → `PackStorage.verifyChecksum(SHA256)` → `savePack()` → `setActivePack()` → `PackLoader.openPack()` → `CameraDao`

**File structure**: `${appDocuments}/packs/{countryCode}/v{version}.db` + `current.db` (copy of active)

**API endpoints**:
- `GET /api/v1/countries` → country list with pack versions
- `GET /api/v1/packs/{code}/meta` → version, size, checksum, count
- `GET /api/v1/packs/{code}/data` → binary SQLite file

**Pack SQLite schema**:
- `cameras` table: id, lat, lon, type, speed_limit, heading, road_name
- `cameras_rtree`: R-tree spatial index
- `meta` table: key-value pairs (country_code, version, bounds, etc.)

### Screens

**MapScreen** — Main screen with:
- OpenStreetMap tile layer
- Camera markers (colored by type, 28×28)
- User position marker (red circle with car icon, glow)
- StatusBar (top): "START LINE" / "RACING" / "PIT STOP" + "SIM" badge
- CameraFilterBar (below status): Blue Shells / Red Shells / Stars / Bananas with counts
- PowerButton (bottom-left): start/stop driving toggle with glow
- ZoomControls (bottom-right): +/- zoom, my location (follow mode toggle), settings
- Camera tap → bottom sheet with details (type, speed limit, road, heading, coords)
- Follow mode: auto-tracks user position; disabled on manual pan; re-enabled on "my location" tap

**SettingsScreen** — Sections (all Mario Kart themed):
WARNING RANGE → RUMBLE (toggle + intensity + test) → HORN (toggle + sound picker + test) → MIN RACE SPEED → PIT STOP TIMER → ITEM TYPES → RACE TRACK (active country + camera count + switch) → DEBUG (simulation mode toggle) → PIT CREW (version info + check for updates)

### Simulation Mode

Fake GPS along Ayalon Highway (Tel Aviv) at ~80km/h, 27 waypoints in a loop. Toggled in Settings debug section. Requires app restart.

---

## Backend Architecture

### Tech Stack
- **Framework**: FastAPI (Python 3.12, async)
- **Database**: PostgreSQL 16 + PostGIS
- **ORM**: SQLAlchemy (async) + Alembic migrations
- **Auth**: JWT (python-jose, HS256)
- **Scheduling**: APScheduler
- **HTTP**: httpx (async)

### Directory Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI app, router registration, scheduler start
│   ├── config.py               # Pydantic Settings
│   ├── api/
│   │   ├── deps.py             # Auth dependency (JWT), DB session
│   │   └── routes/
│   │       ├── health.py       # GET /api/v1/health
│   │       ├── countries.py    # GET /api/v1/countries
│   │       ├── packs.py        # GET /api/v1/packs/{code}/meta, /data
│   │       ├── developer.py    # Developer API (x-api-key auth)
│   │       ├── auth.py         # POST /admin/api/auth/login
│   │       ├── admin_countries.py
│   │       ├── admin_sources.py
│   │       ├── admin_cameras.py
│   │       ├── admin_geocoding.py
│   │       ├── admin_packs.py
│   │       ├── admin_jobs.py
│   │       ├── admin_dashboard.py
│   │       ├── admin_scheduler.py
│   │       ├── admin_developers.py
│   │       └── admin_submissions.py
│   ├── models/                 # SQLAlchemy ORM models
│   │   ├── camera.py           # cameras table (PostGIS POINT)
│   │   ├── raw_camera.py       # raw_cameras table
│   │   ├── country.py          # countries table
│   │   ├── source.py           # sources table (adapter config)
│   │   ├── pack.py             # packs table (versioned)
│   │   ├── developer.py        # developer_keys + developer_submissions
│   │   ├── geocode_cache.py    # address → coordinates cache
│   │   ├── job_run.py          # pipeline execution log
│   │   └── scheduler_settings.py
│   ├── schemas/                # Pydantic request/response models
│   ├── services/
│   │   ├── merger.py           # Haversine-based spatial deduplication (50m threshold)
│   │   ├── pack_generator.py   # SQLite + R-tree pack creation
│   │   ├── scheduler.py        # APScheduler wrapper
│   │   ├── adapters/
│   │   │   ├── base.py         # Abstract adapter interface
│   │   │   ├── osm_overpass.py # OpenStreetMap Overpass API
│   │   │   ├── csv_adapter.py
│   │   │   ├── excel_adapter.py
│   │   │   └── registry.py     # Adapter discovery
│   │   └── geocoding/
│   │       ├── nominatim.py    # Nominatim API client
│   │       ├── db_cache.py     # Cache layer
│   │       └── service.py      # Geocoding orchestration
│   └── db/
│       ├── base.py             # SQLAlchemy declarative base
│       └── session.py          # Async session factory
├── jobs/                       # CLI pipeline scripts
│   ├── pipeline.py             # Full pipeline orchestrator
│   ├── fetch_sources.py        # Adapter-based data fetching
│   ├── merge_cameras.py        # Spatial deduplication
│   ├── generate_packs.py       # SQLite pack generation
│   ├── geocode_pending.py      # Batch geocoding
│   └── seed_israel.py          # Initialize Israel + OSM source
├── migrations/                 # Alembic
├── tests/                      # 121 tests (pytest)
├── requirements.txt
└── Dockerfile
```

### Database Schema

**countries**: code (PK), name, name_local, speed_unit, bounds (POLYGON), enabled
**cameras**: id (UUID), country_code, location (POINT), type, speed_limit, heading, road_name, confidence, source_ids[], last_verified
**raw_cameras**: id (UUID), source_id, country_code, external_id, lat, lon, address, type, raw_data (JSONB), geocoded, geocode_failed
**sources**: id (UUID), country_code, name, adapter, config (JSONB), confidence, enabled, last_fetched_at
**packs**: id (UUID), country_code, version, camera_count, file_size_bytes, file_path, checksum_sha256, published_at
**developer_keys**: id (UUID), name, email, api_key_hash (SHA256), key_prefix, scopes (JSONB), enabled
**developer_submissions**: id (UUID), developer_key_id, country_code, status, cameras_json (JSONB), submitted_at, reviewed_at, review_note
**job_runs**: id (UUID), job_type, status, started_at, finished_at, result_summary, items_processed
**geocode_cache**: address_hash (SHA256, PK), address, lat, lon, provider
**scheduler_settings**: id (UUID), enabled, interval_hours, last_run_at, next_run_at

### Data Pipeline

**Full pipeline**: `fetch_sources` → `merge_cameras` → `generate_packs`

1. **Fetch**: For each enabled source, run adapter (CSV/Excel/OSM Overpass) → insert `raw_cameras`
2. **Merge**: Spatial clustering within 50m (Haversine) → deduplicate → insert `cameras`
3. **Generate**: Query cameras per country → create SQLite .db with R-tree → compute SHA256 → insert `pack`

**Scheduler**: APScheduler runs pipeline every N hours (configurable: 1, 3, 6, 12, 24)

### API Surface

**Public** (`/api/v1`): health, countries list, pack meta + download

**Developer** (`/developer`, x-api-key): profile, country CRUD (scoped), source CRUD (scoped), camera query + submit, submission tracking

**Admin** (`/admin/api`, Bearer JWT): auth, country/source/camera CRUD, geocoding queue, job management, scheduler config, developer key management, submission moderation (approve/reject)

---

## Admin Dashboard

### Tech Stack
- React 19, TypeScript, Vite, Tailwind CSS
- React Router (SPA), React Query (data fetching), Axios (HTTP)
- Leaflet (maps)

### Pages
LoginPage, DashboardPage, CountriesPage, CountryDetailPage, CamerasPage (with map), SourceEditorPage, GeocodingQueuePage, JobsPage, SchedulerPage, DeveloperKeysPage, SubmissionsPage, SubmissionDetailPage

---

## Testing

| Component | Framework | Count | Path |
|-----------|-----------|-------|------|
| Flutter app | flutter_test + mocktail | ~79 tests | `app/test/` |
| Backend | pytest + pytest-asyncio | ~121 tests | `backend/tests/` |

Key test files:
- `app/test/core/geo_utils_test.dart` — distance, bearing, isAhead
- `app/test/core/proximity_engine_test.dart` — alert logic
- `app/test/services/orchestrator_test.dart` — state machine
- `backend/tests/test_api/` — all API endpoints
- `backend/tests/test_merger/` — deduplication
- `backend/tests/test_pack_generator/` — pack creation

---

## Build & Run

### Flutter App
```bash
cd app
flutter pub get
flutter run                      # Debug on connected device
flutter build apk --release      # Release APK
# Copy APK to admin for distribution:
cp build/app/outputs/flutter-apk/app-release.apk ../admin/public/buzzoff.apk
```

### Web Preview
```bash
cd app
flutter run -d chrome --target lib/main_preview.dart
```
Opens in Chrome with mock data (6 cameras around Tel Aviv, simulation mode on). Bottom tab nav between Map and Settings. No real GPS, SQLite, or backend needed.

### Backend (local)
```bash
docker compose up -d             # Start PostgreSQL + PostGIS
cd backend
pip install -r requirements.txt
alembic upgrade head             # Run migrations
uvicorn app.main:app --reload    # Start API on :8000
```

### Admin Dashboard
```bash
cd admin
npm ci
npm run dev                      # Start Vite dev server on :5173
```

### Run Tests
```bash
cd app && flutter test
cd backend && pytest
```

---

## Versioning

- App version in `app/pubspec.yaml`: `version: X.Y.Z+buildNumber`
- Pack versions: integer, incremented per generation per country
- Changelogs: `app/android/fastlane/metadata/android/en-US/changelogs/{buildNumber}.txt`

---

## Development Workflow — Preview First

**Every UI/feature change follows this flow:**

1. **Implement in web preview first** (`preview/` screens + `main_preview.dart`)
2. **User approves** the layout/behavior in Chrome
3. **Port to the real app** (`ui/screens/` + production providers)
4. **Build APK** and copy to `admin/public/buzzoff.apk`

This ensures visual validation before deploying to mobile. The web preview uses mock data and avoids native dependencies (sqlite3, ForegroundTask, Geolocator).

**Provider split for web compatibility:**
- `pack_provider.dart` — storage-only providers (no sqlite3 transitive deps)
- `pack_manager_provider.dart` — PackManager/countries providers (sqlite3 deps via CameraDao)
- `database_provider.dart` — uses `CameraQueryPort` interface (not concrete `CameraDao`)
- Preview screens import only web-safe providers; production screens import both

---

## Critical Rules for Development

1. **NEVER replace themed widgets** (RainbowDivider, RacingStripeCard, PowerButton, StatusBar, CameraFilterBar) with plain Material equivalents
2. **ALWAYS use RacingColors** constants — never hardcode hex values
3. **ALWAYS use the Mario Kart vocabulary** in UI text (Blue Shells, not "speed cameras")
4. **ALWAYS `git pull`** before making changes to avoid diverging from remote
5. **All internal values are metric** — only convert for display
6. **Android package is `me.buzzoff.app`** — never use `com.buzzoff.app`
7. **Pack API timeout is 90 seconds** to handle Render cold starts
8. **ProximityEngine is stateful** — tracks alerted cameras to prevent duplicates
9. **Foreground service is required** for background GPS on Android
10. **Copy release APK to `admin/public/buzzoff.apk`** after every build
11. **Preview first** — implement UI changes in web preview, get approval, then port to real app
