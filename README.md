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
| 2 | Flutter App Core Engine | Up Next |
| 3 | Pack System in App | - |
| 4 | Admin Portal | - |
| 5 | Multi-Country + Auto-Detect | - |
| 6 | Hebrew + RTL + Community | - |

### Phase 1 Results

- 148 speed cameras fetched from OpenStreetMap Overpass API for Israel
- Merged into 147 unique cameras (1 duplicate within 50m)
- Packed into 48KB SQLite file with R-tree spatial index
- 69 fixed speed + 78 red light cameras
- API serving country list, pack metadata, and pack downloads
- 88 tests passing

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

## API Endpoints

```
GET /api/v1/health              -> { "status": "ok" }
GET /api/v1/countries           -> [{ code, name, pack_version, camera_count }]
GET /api/v1/packs/{code}/meta   -> { version, camera_count, file_size_bytes, checksum_sha256 }
GET /api/v1/packs/{code}/data   -> SQLite file download
```

## Repo Structure

```
buzzoff.me/
├── specs/           # Project specs (6 phases + deployment)
├── backend/
│   ├── app/
│   │   ├── api/routes/      # FastAPI endpoints
│   │   ├── models/          # SQLAlchemy models (6 tables)
│   │   ├── schemas/         # Pydantic response schemas
│   │   └── services/
│   │       ├── adapters/    # OSM, CSV, Excel + registry
│   │       ├── geocoding/   # Nominatim + DB cache
│   │       ├── merger.py    # Haversine-based dedup
│   │       └── pack_generator.py  # SQLite + R-tree
│   ├── jobs/                # Pipeline scripts
│   ├── migrations/          # Alembic
│   ├── tests/               # 88 tests
│   └── packs/               # Generated pack files
└── app/                     # Flutter mobile app (Phase 2)
```
