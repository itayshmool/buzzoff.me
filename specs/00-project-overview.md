# BuzzOff - Project Overview

## Product

A silent, lightweight mobile app that warns drivers about speed cameras.
Install it, grant permissions, forget about it. It detects driving, checks proximity to known cameras, and vibrates your phone. No navigation, no account, no internet required while driving. Android first, iOS post-launch.

When opened, the app shows a live map centered on your position with camera markers around you. The map follows your movement in real-time with zoom in/out. This is NOT a navigation app — no routes, no directions. Just a radar-like view of you and the cameras nearby.

## Platform

The app is a generic proximity alert engine. Camera data is decoupled into downloadable "country packs." An admin portal manages data sources per country, processes them into packs, and publishes them. Adding a new country means adding a data source config — not writing code.

## Architecture Principles

- **Data-decoupled**: App knows nothing about cameras. It consumes packs.
- **Offline-first**: App works without internet while driving.
- **Multi-country**: GPS-based auto-detection or manual country selection.
- **Multi-language**: English first. RTL-ready structure from day one.
- **Cross-platform**: Flutter (Dart) for Android + iOS from a single codebase.
- **Minimal footprint**: Tiny app, data downloaded on demand.
- **Battery-conscious**: GPS only while driving. Activity Recognition when idle.

## Tech Stack

| Component           | Technology                  |
|---------------------|-----------------------------|
| Mobile App          | Flutter (Dart) — Android + iOS |
| App State           | Riverpod                    |
| App Database        | Drift + sqlite3 (R-tree enabled) |
| App Map             | flutter_map (OSM tiles)     |
| App GPS             | geolocator                  |
| App Background      | flutter_foreground_task     |
| Admin Backend       | Python, FastAPI             |
| Admin Frontend      | React (Vite)                |
| Database            | PostgreSQL + PostGIS        |
| Pack Hosting        | Render Web Service + CDN    |
| Geocoding           | Nominatim (primary), Google (fallback) |
| Deployment          | Render                      |
| CI/CD               | GitHub Actions              |
| Domain              | buzzoff.me                  |

## Phases

| Phase | Name                          | Depends On | Status |
|-------|-------------------------------|------------|--------|
| 1     | Data Pipeline + Pack Gen      | —          | DONE   |
| 2     | Flutter App Core Engine       | —          | DONE   |
| 3     | Pack System in App            | 1, 2       | DONE   |
| 4     | Admin Portal                  | 1          | UP NEXT |
| 5     | Multi-Country + Auto-Detect   | 3, 4       | —      |
| 6     | Hebrew + RTL + Community      | 5          | —      |

## Country Pack Format (Standard Schema)

Every country pack is a SQLite file with this schema:

```sql
CREATE TABLE meta (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
-- Keys: country_code, country_name, version, generated_at,
--       camera_count, bounds_north, bounds_south, bounds_east,
--       bounds_west, speed_unit

CREATE TABLE cameras (
    id                TEXT PRIMARY KEY,
    lat               REAL NOT NULL,
    lon               REAL NOT NULL,
    type              TEXT NOT NULL, -- fixed_speed, red_light, avg_speed_start, avg_speed_end, mobile_zone
    speed_limit       INTEGER,
    heading           REAL,         -- 0-360, direction camera faces
    road_name         TEXT,
    linked_camera_id  TEXT,         -- pairs avg_speed start<->end
    source            TEXT NOT NULL, -- government, osm, community, third_party
    confidence        REAL NOT NULL DEFAULT 0.5, -- 0.0-1.0
    last_verified     TEXT
);

CREATE VIRTUAL TABLE cameras_rtree USING rtree(
    id,
    min_lat, max_lat,
    min_lon, max_lon
);
```

## Repository Structure

```
buzzoff/
├── specs/                  # this directory - project specs
├── backend/                # FastAPI admin backend + pack generation
│   ├── app/
│   │   ├── api/            # REST endpoints
│   │   ├── core/           # config, security
│   │   ├── models/         # SQLAlchemy models
│   │   ├── services/       # business logic
│   │   │   ├── adapters/   # source adapters (excel, osm, csv, geojson)
│   │   │   ├── geocoding/  # address -> lat/lon
│   │   │   └── packs/      # pack generation
│   │   └── schemas/        # Pydantic schemas
│   ├── jobs/               # cron job scripts
│   ├── migrations/         # Alembic
│   ├── tests/
│   ├── requirements.txt
│   └── Dockerfile
├── admin/                  # React admin portal
│   ├── src/
│   ├── package.json
│   └── vite.config.ts
├── app/                    # Flutter mobile app (Android + iOS)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── .github/
│   └── workflows/
└── render.yaml             # Render blueprint
```
