# Phase 1: Data Pipeline + Pack Generation

## Goal

Build the backend that fetches speed camera data from multiple sources, normalizes it, geocodes addresses when needed, merges duplicates, and outputs country pack SQLite files. This phase proves the data works before any app code is written.

## Deliverables

1. FastAPI backend with PostgreSQL (PostGIS)
2. Source adapter system (pluggable, config-driven)
3. Geocoding service with caching
4. Pack generation pipeline
5. REST API to serve packs
6. Deployed on Render

## Data Flow

```
Source (gov.il, OSM, CSV, etc.)
  │
  ▼
Source Adapter (parses, normalizes to common schema)
  │
  ▼
Raw Camera Records → PostgreSQL (raw_cameras table)
  │
  ▼
Geocoder (if lat/lon missing, resolve from address)
  │
  ▼
Merger / Deduplicator (same camera from multiple sources → one record)
  │
  ▼
Verified Camera Records → PostgreSQL (cameras table)
  │
  ▼
Pack Generator (query by country → build SQLite file)
  │
  ▼
Pack File → stored on disk, served via API
```

## Database Schema (PostgreSQL + PostGIS)

```sql
-- Countries available in the system
CREATE TABLE countries (
    code        VARCHAR(2) PRIMARY KEY,   -- ISO 3166-1 alpha-2
    name        VARCHAR(100) NOT NULL,
    name_local  VARCHAR(100),             -- name in local language
    speed_unit  VARCHAR(3) NOT NULL DEFAULT 'kmh', -- kmh or mph
    bounds      GEOMETRY(POLYGON, 4326),  -- country bounding box
    enabled     BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Configured data sources per country
CREATE TABLE sources (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(2) NOT NULL REFERENCES countries(code),
    name        VARCHAR(200) NOT NULL,
    adapter     VARCHAR(50) NOT NULL,     -- excel, osm_overpass, csv, geojson, api
    config      JSONB NOT NULL,           -- adapter-specific config (url, column mapping, etc.)
    schedule    VARCHAR(50),              -- cron expression for auto-fetch
    confidence  REAL NOT NULL DEFAULT 0.5,
    enabled     BOOLEAN NOT NULL DEFAULT true,
    last_fetched_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Raw camera records as fetched from sources (before merge/dedup)
CREATE TABLE raw_cameras (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_id       UUID NOT NULL REFERENCES sources(id),
    country_code    VARCHAR(2) NOT NULL REFERENCES countries(code),
    external_id     TEXT,                 -- ID from the source, if any
    lat             DOUBLE PRECISION,     -- may be null if geocoding needed
    lon             DOUBLE PRECISION,
    address         TEXT,                 -- original address text
    type            VARCHAR(50) NOT NULL,
    speed_limit     INTEGER,
    heading         REAL,
    road_name       TEXT,
    raw_data        JSONB,               -- original record for debugging
    geocoded        BOOLEAN NOT NULL DEFAULT false,
    geocode_failed  BOOLEAN NOT NULL DEFAULT false,
    fetched_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_raw_cameras_source ON raw_cameras(source_id);
CREATE INDEX idx_raw_cameras_country ON raw_cameras(country_code);

-- Merged, deduplicated, verified cameras (the "truth")
CREATE TABLE cameras (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code    VARCHAR(2) NOT NULL REFERENCES countries(code),
    location        GEOMETRY(POINT, 4326) NOT NULL,
    type            VARCHAR(50) NOT NULL,
    speed_limit     INTEGER,
    heading         REAL,
    road_name       TEXT,
    linked_camera_id UUID,               -- for avg speed pairs
    confidence      REAL NOT NULL DEFAULT 0.5,
    source_ids      UUID[] NOT NULL,     -- which sources contributed
    last_verified   TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_cameras_country ON cameras(country_code);
CREATE INDEX idx_cameras_location ON cameras USING GIST(location);

-- Geocoding cache (avoid re-geocoding the same address)
CREATE TABLE geocode_cache (
    address_hash VARCHAR(64) PRIMARY KEY, -- SHA-256 of normalized address
    address     TEXT NOT NULL,
    lat         DOUBLE PRECISION NOT NULL,
    lon         DOUBLE PRECISION NOT NULL,
    provider    VARCHAR(50) NOT NULL,     -- nominatim, google
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Published packs
CREATE TABLE packs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code    VARCHAR(2) NOT NULL REFERENCES countries(code),
    version         INTEGER NOT NULL,
    camera_count    INTEGER NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    file_path       TEXT NOT NULL,        -- path to SQLite file on disk
    checksum_sha256 VARCHAR(64) NOT NULL,
    published_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(country_code, version)
);
```

## Source Adapter System

Each adapter implements a common interface:

```python
class SourceAdapter(ABC):
    @abstractmethod
    async def fetch(self, config: dict) -> list[RawCameraRecord]:
        """Fetch camera records from the source."""
        pass
```

### Adapters to build in Phase 1

**1. ExcelAdapter**
- Downloads Excel/XLSX from URL
- Maps columns via config: `{ "lat": "column_B", "address": "column_C", ... }`
- Supports Hebrew type mapping: `{ "מצלמת מהירות": "fixed_speed" }`
- Primary use: gov.il data

**2. OSMOverpassAdapter**
- Runs Overpass API query
- Extracts `highway=speed_camera` nodes
- Reads tags: `maxspeed`, `direction`, enforcement type
- Outputs normalized records with lat/lon (always available from OSM)

**3. CSVAdapter**
- Generic CSV/TSV parser
- Column mapping via config
- Useful for bulk imports and third-party data

**4. GeoJSONAdapter**
- Parses GeoJSON files
- Extracts coordinates from geometry
- Maps properties via config

### Adapter config examples

```json
{
  "adapter": "excel",
  "config": {
    "url": "https://data.gov.il/dataset/.../download/file.xlsx",
    "sheet": 0,
    "skip_rows": 1,
    "column_mapping": {
      "road_name": "B",
      "address": "C",
      "speed_limit": "D",
      "type": "E"
    },
    "type_mapping": {
      "מצלמת מהירות": "fixed_speed",
      "מצלמת רמזור": "red_light",
      "מצלמת מהירות ממוצעת - התחלה": "avg_speed_start",
      "מצלמת מהירות ממוצעת - סוף": "avg_speed_end"
    }
  }
}
```

```json
{
  "adapter": "osm_overpass",
  "config": {
    "query": "[out:json][timeout:60];area['name:en'='Israel']->.a;(node['highway'='speed_camera'](area.a););out geom;",
    "type_mapping": {
      "maxspeed": "fixed_speed",
      "traffic_signals": "red_light",
      "average_speed": "avg_speed_start"
    }
  }
}
```

## Geocoding Service

For sources that provide addresses but not coordinates (likely gov.il):

```
Input: "כביש 1, קילומטר 23, כיוון ירושלים"

1. Normalize address (strip Hebrew prefixes, standardize road names)
2. Check geocode_cache table
3. If miss → call Nominatim (free, OSM-based)
4. If Nominatim fails → call Google Geocoding API (paid fallback)
5. If both fail → mark geocode_failed=true, flag for manual review
6. Cache result
```

Rate limiting: Nominatim requires max 1 request/second. Batch geocoding should respect this.

## Merge / Dedup Logic

When the same camera appears in multiple sources:

```
1. Group raw_cameras by proximity (within 50m of each other)
2. For each group:
   a. Take the highest-confidence source as primary
   b. Average the lat/lon positions
   c. Take speed_limit from highest-confidence source
   d. Merge source_ids
   e. Set confidence = max(individual confidences)
3. Insert into cameras table
```

## Pack Generation

```python
async def generate_pack(country_code: str) -> PackFile:
    cameras = await db.get_cameras_by_country(country_code)
    country = await db.get_country(country_code)

    # Create SQLite file
    pack_db = create_sqlite(f"pack_{country_code}_v{next_version}.db")

    # Write meta table
    pack_db.insert_meta({
        "country_code": country_code,
        "country_name": country.name,
        "version": next_version,
        "generated_at": now_iso(),
        "camera_count": len(cameras),
        "bounds_north": country.bounds.north,
        "bounds_south": country.bounds.south,
        "bounds_east": country.bounds.east,
        "bounds_west": country.bounds.west,
        "speed_unit": country.speed_unit,
    })

    # Write cameras + R-tree index
    for cam in cameras:
        pack_db.insert_camera(cam)
        pack_db.insert_rtree(cam)

    # Compute checksum
    checksum = sha256(pack_db.file_path)

    # Store in packs table
    await db.create_pack(country_code, next_version, len(cameras), file_size, file_path, checksum)

    return pack_db
```

## REST API Endpoints (Phase 1)

```
GET  /api/v1/countries
     → [{ code: "IL", name: "Israel", pack_version: 3, camera_count: 187 }]

GET  /api/v1/packs/{country_code}/meta
     → { version: 3, camera_count: 187, file_size_bytes: 45000, checksum_sha256: "abc..." }

GET  /api/v1/packs/{country_code}/data
     → binary SQLite file download

GET  /api/v1/packs/{country_code}/data?since_version=2
     → delta update (future, can return full file for now)

GET  /api/v1/health
     → { status: "ok" }
```

## Backend Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app
│   ├── config.py                  # settings from env vars
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes/
│   │   │   ├── countries.py
│   │   │   ├── packs.py
│   │   │   └── health.py
│   │   └── deps.py                # dependencies (db session, etc.)
│   ├── models/
│   │   ├── __init__.py
│   │   ├── country.py
│   │   ├── source.py
│   │   ├── camera.py
│   │   ├── raw_camera.py
│   │   ├── pack.py
│   │   └── geocode_cache.py
│   ├── schemas/
│   │   ├── __init__.py
│   │   ├── country.py
│   │   ├── pack.py
│   │   └── camera.py
│   ├── services/
│   │   ├── __init__.py
│   │   ├── adapters/
│   │   │   ├── __init__.py
│   │   │   ├── base.py            # ABC
│   │   │   ├── excel.py
│   │   │   ├── osm_overpass.py
│   │   │   ├── csv_adapter.py
│   │   │   └── geojson.py
│   │   ├── geocoding/
│   │   │   ├── __init__.py
│   │   │   ├── service.py         # orchestrator
│   │   │   ├── nominatim.py
│   │   │   └── google.py
│   │   ├── merger.py              # dedup + merge logic
│   │   └── pack_generator.py      # SQLite pack builder
│   └── db/
│       ├── __init__.py
│       ├── session.py
│       └── base.py
├── jobs/
│   ├── fetch_sources.py           # cron: fetch all enabled sources
│   ├── geocode_pending.py         # cron: geocode raw records missing coords
│   ├── merge_cameras.py           # cron: run dedup/merge
│   └── generate_packs.py          # cron: rebuild packs for changed countries
├── migrations/
│   └── alembic/
├── packs/                         # generated pack files (gitignored, persistent disk)
├── tests/
│   ├── test_adapters/
│   ├── test_geocoding/
│   ├── test_merger/
│   └── test_pack_generator/
├── alembic.ini
├── requirements.txt
├── Dockerfile
└── README.md
```

## Acceptance Criteria

- [ ] FastAPI app runs on Render with PostgreSQL + PostGIS
- [ ] ExcelAdapter can fetch and parse the gov.il enforcement cameras file
- [ ] OSMOverpassAdapter can fetch speed cameras for a given country
- [ ] Geocoding service resolves Hebrew addresses to lat/lon with caching
- [ ] Merge service deduplicates cameras from multiple sources within 50m
- [ ] Pack generator produces valid SQLite files with R-tree index
- [ ] `/api/v1/countries` returns list of available countries
- [ ] `/api/v1/packs/IL/data` returns downloadable SQLite pack for Israel
- [ ] Cron jobs run on Render: fetch weekly, geocode daily, generate on change
- [ ] Israel pack contains cameras from gov.il + OSM sources
- [ ] All cameras in pack have valid lat/lon coordinates
