# BuzzOff

Silent speed camera warning app. Detects driving, alerts via vibration when approaching cameras. Offline-first, lightweight, no navigation. Built with Flutter for Android + iOS (iOS post-launch).

## What it does

- Runs silently in the background
- Detects when you start driving (Activity Recognition)
- Vibrates your phone when approaching a speed camera or red light camera
- Shows a live map with your position and nearby cameras
- Works offline while driving (camera data downloaded as country packs)

## Architecture

```
                    +-----------+
                    | Flutter   |
                    |   App     |
                    +-----+-----+
                          |
                    downloads pack
                          |
                    +-----v-----+
                    |  FastAPI   |
                    |  Backend   |
                    +-----+-----+
                          |
              +-----------+-----------+
              |           |           |
         +----v---+  +---v----+  +---v----+
         |  OSM   |  |  CSV   |  | Excel  |
         |Overpass |  |Adapter |  |Adapter |
         +--------+  +--------+  +--------+
              |
         fetch cameras
              |
         +----v----+     +----------+     +----------+     +-----------+
         |Raw Cams  | --> | Geocoder | --> |  Merger  | --> |Pack Gen   |
         |PostgreSQL|     |Nominatim |     | Dedup    |     |SQLite+Rtree|
         +---------+     +----------+     +----------+     +-----------+
```

## Project Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Data Pipeline + Pack Generation | Done |
| 2 | Flutter App Core Engine | Done |
| 3 | Pack System in App | Done |
| 4 | Admin Portal | Done |
| 5 | Multi-Country + Auto-Detect | - |
| 6 | Hebrew + RTL + Community | - |

### Phase 1 Results

- 148 speed cameras fetched from OpenStreetMap Overpass API for Israel
- Merged into 147 unique cameras (1 duplicate within 50m)
- Packed into 48KB SQLite file with R-tree spatial index
- 69 fixed speed + 78 red light cameras
- API serving country list, pack metadata, and pack downloads
- 88 tests passing

### Phase 2 Results

- Flutter 3.41.4 app with full core engine architecture
- Pure Dart proximity engine: haversine distance, heading filter, debouncing
- SQLite R-tree spatial queries via CameraDao (implements CameraQueryPort)
- Orchestrator: driving state machine (idle → driving → stopping)
- Live map screen (OSM tiles) + settings screen with persistent preferences
- 10-camera test dataset near Tel Aviv (32KB SQLite)
- Android manifest with all permissions, foreground service, boot receiver
- 48 tests passing

### Phase 3 Results

- Pack download system: API client, file storage, SHA-256 verification
- PackManager orchestrates download → verify → install → open CameraDao
- AutoCountrySwitcher: GPS-based country detection with bounding box checks
- First-launch setup: country picker → download → map screen
- Settings screen with country switching support
- Conditional routing: setup screen on first launch, map when pack installed
- 31 new tests (79 total passing)

### Phase 4 Results

- Admin API: 8 endpoint groups (auth, countries, sources, cameras, geocoding, packs, jobs, dashboard) — all JWT-protected
- Admin SPA: 7 pages (dashboard, countries, country detail, source editor, geocoding queue, jobs, login)
- Leaflet camera map with color-coded markers by type, auto-fit bounds
- Geocoding queue with click-to-set-coords LocationPicker
- 33 new backend tests (121 total passing)
- Render Blueprint (`render.yaml`) for one-click infrastructure deployment
- Build: 489KB JS / 30KB CSS gzipped

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Python, FastAPI, SQLAlchemy, PostgreSQL + PostGIS |
| Pack Format | SQLite with R-tree spatial index |
| Data Sources | OSM Overpass, CSV, Excel (pluggable adapter system) |
| Geocoding | Nominatim (OSM) with DB caching |
| Mobile App | Flutter (Dart) — Android + iOS |
| App State | Riverpod |
| App Database | Drift + sqlite3 (R-tree enabled) |
| App Map | flutter_map (OSM tiles) |
| App GPS | geolocator |
| App Background | flutter_foreground_task |
| Admin Frontend | React, Vite, TypeScript, Tailwind CSS, Leaflet |
| Deployment | Render |

## Backend Setup (Local Dev)

```bash
cd backend
python3.13 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Requires PostgreSQL with PostGIS extension
# Configure .env with DATABASE_URL

# Run migrations
alembic upgrade head

# Seed Israel + OSM source
python -m jobs.seed_israel

# Run the full pipeline
python -m jobs.fetch_sources
python -m jobs.merge_cameras
python -m jobs.generate_packs

# Start the API
uvicorn app.main:app --reload

# Run tests
pytest -v
```

## Admin Frontend Setup (Local Dev)

```bash
cd admin
npm install
npm run dev        # http://localhost:5173 — login with admin/changeme
npm run build      # production build → dist/
```

## Flutter App Setup (Local Dev)

```bash
cd app
flutter pub get
flutter test        # 79 tests
flutter run         # requires Android emulator or device
```

## Publishing to Google Play

To build a release App Bundle and publish to the Play Store, see **[docs/PUBLISH_GOOGLE_PLAY.md](docs/PUBLISH_GOOGLE_PLAY.md)**. Summary: create an upload keystore, configure `app/android/key.properties`, then run `flutter build appbundle --release` and upload the AAB in [Play Console](https://play.google.com/console).

## API Endpoints

```
Public API:
GET  /api/v1/health              -> { "status": "ok" }
GET  /api/v1/countries           -> [{ code, name, pack_version, camera_count }]
GET  /api/v1/packs/{code}/meta   -> { version, camera_count, file_size_bytes, checksum_sha256 }
GET  /api/v1/packs/{code}/data   -> SQLite file download

Admin API (JWT protected):
POST /admin/api/auth/login                      -> { access_token }
CRUD /admin/api/countries                        -> Country management
CRUD /admin/api/countries/{code}/sources         -> Source management
GET  /admin/api/countries/{code}/cameras         -> Paginated camera list
GET  /admin/api/countries/{code}/cameras/stats   -> Camera stats by type
GET  /admin/api/geocoding/queue                  -> Pending geocoding records
GET  /admin/api/geocoding/failed                 -> Failed geocoding records
PUT  /admin/api/geocoding/{id}/resolve           -> Manual lat/lon resolution
GET  /admin/api/countries/{code}/packs           -> Pack version history
GET  /admin/api/jobs                             -> Job run history
GET  /admin/api/dashboard/stats                  -> Overview stats
```

## Repo Structure

```
buzzoff.me/
├── specs/           # Project specs (6 phases + deployment)
├── backend/
│   ├── app/
│   │   ├── api/routes/      # FastAPI endpoints (public + admin)
│   │   ├── models/          # SQLAlchemy models (7 tables)
│   │   ├── schemas/         # Pydantic response schemas
│   │   └── services/
│   │       ├── adapters/    # OSM, CSV, Excel + registry
│   │       ├── geocoding/   # Nominatim + DB cache
│   │       ├── merger.py    # Haversine-based dedup
│   │       └── pack_generator.py  # SQLite + R-tree
│   ├── jobs/                # Pipeline scripts
│   ├── migrations/          # Alembic
│   ├── tests/               # 121 tests
│   └── packs/               # Generated pack files
├── admin/                   # React admin SPA
│   ├── src/
│   │   ├── api/             # Axios API client (9 modules)
│   │   ├── components/      # Reusable UI (DataTable, maps, etc.)
│   │   ├── contexts/        # AuthContext
│   │   ├── pages/           # 7 page components
│   │   └── types/           # TypeScript interfaces
│   └── dist/                # Production build output
├── app/                     # Flutter mobile app
│   ├── lib/
│   │   ├── core/            # Pure Dart engine (geo, proximity, models)
│   │   ├── data/            # SQLite DAO, preferences
│   │   ├── services/        # Location, alert, orchestrator, pack system
│   │   ├── providers/       # Riverpod state management
│   │   └── ui/              # Map screen, settings screen, widgets
│   ├── test/                # 79 tests
│   └── assets/              # Test camera dataset
└── render.yaml              # Render Blueprint (API + admin + DB)
```
