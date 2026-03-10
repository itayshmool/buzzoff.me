# Deployment Architecture — Render

## Overview

All backend infrastructure runs on Render. The Android app is distributed via Google Play (or APK sideload during development).

```
┌──────────────────────────────────────────────────────────────────┐
│                         RENDER PLATFORM                           │
│                                                                   │
│  ┌──────────────────────┐    ┌─────────────────────────────────┐ │
│  │  buzzoff-api      │    │  buzzoff-admin               │ │
│  │  Web Service (Python) │    │  Static Site (React)            │ │
│  │                      │    │                                 │ │
│  │  FastAPI app:        │    │  Admin dashboard SPA            │ │
│  │  - Public API        │    │  - Talks to buzzoff-api      │ │
│  │    /api/v1/*          │    │  - Protected by login           │ │
│  │  - Admin API         │    │                                 │ │
│  │    /admin/api/*       │    │  Build: npm run build           │ │
│  │  - Pack file serving  │    │  Publish: dist/                 │ │
│  │    /api/v1/packs/*/data│   │                                 │ │
│  │                      │    │  URL: buzzoff-admin.onrender.com│
│  │  URL: buzzoff-api │    └─────────────────────────────────┘ │
│  │  .onrender.com        │                                       │
│  └──────────┬───────────┘                                        │
│             │                                                    │
│             │ connects to                                        │
│             ▼                                                    │
│  ┌──────────────────────┐                                        │
│  │  buzzoff-db       │                                        │
│  │  PostgreSQL + PostGIS │                                       │
│  │                      │                                        │
│  │  Tables:             │                                        │
│  │  - countries          │                                       │
│  │  - sources            │                                       │
│  │  - raw_cameras        │                                       │
│  │  - cameras            │                                       │
│  │  - geocode_cache      │                                       │
│  │  - packs              │                                       │
│  │  - community_reports  │                                       │
│  │                      │                                        │
│  │  Plan: Starter ($7/mo)│                                       │
│  │  PostGIS: via extension│                                      │
│  └──────────────────────┘                                        │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  CRON JOBS                                                    │ │
│  │                                                               │ │
│  │  buzzoff-fetch    (Weekly: 0 0 * * 0)                      │ │
│  │  → python jobs/fetch_sources.py                               │ │
│  │  → Fetches all enabled sources for all countries              │ │
│  │                                                               │ │
│  │  buzzoff-geocode  (Daily: 0 2 * * *)                       │ │
│  │  → python jobs/geocode_pending.py                             │ │
│  │  → Geocodes raw records missing coordinates                   │ │
│  │                                                               │ │
│  │  buzzoff-merge    (Daily: 0 4 * * *)                       │ │
│  │  → python jobs/merge_cameras.py                               │ │
│  │  → Deduplicates and merges raw records into cameras table     │ │
│  │                                                               │ │
│  │  buzzoff-packgen  (Daily: 0 6 * * *)                       │ │
│  │  → python jobs/generate_packs.py                              │ │
│  │  → Regenerates packs for countries with changed data          │ │
│  │                                                               │ │
│  │  All cron jobs share the same repo/codebase as buzzoff-api │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────┐                                        │
│  │  Persistent Disk     │                                        │
│  │  (attached to api)   │                                        │
│  │                      │                                        │
│  │  /data/packs/        │                                        │
│  │  ├── IL/             │                                        │
│  │  │   ├── v3.db       │                                        │
│  │  │   └── v4.db       │                                        │
│  │  └── DE/             │                                        │
│  │      └── v1.db       │                                        │
│  │                      │                                        │
│  │  Size: 1 GB          │                                        │
│  └──────────────────────┘                                        │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      EXTERNAL SERVICES                            │
│                                                                   │
│  Nominatim (OSM)         — geocoding, free, 1 req/sec            │
│  Overpass API (OSM)      — camera data, free                     │
│  Google Geocoding API    — fallback geocoding, pay-per-use       │
│  data.gov.il             — Israeli government camera data        │
│  Google Play Console     — Android app distribution              │
│  GitHub                  — source code, CI/CD                    │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      ANDROID APP                                  │
│                                                                   │
│  On first launch:                                                │
│  GET buzzoff-api.onrender.com/api/v1/countries                │
│  GET buzzoff-api.onrender.com/api/v1/packs/IL/data            │
│                                                                   │
│  Weekly (WiFi only):                                             │
│  GET buzzoff-api.onrender.com/api/v1/packs/IL/meta            │
│  GET buzzoff-api.onrender.com/api/v1/packs/IL/data (if new)   │
│                                                                   │
│  While driving: ZERO network calls. Fully offline.                │
└──────────────────────────────────────────────────────────────────┘
```

## Render Services Configuration

### 1. buzzoff-api (Web Service)

```yaml
name: buzzoff-api
type: web
runtime: python
plan: starter             # $7/mo - always on, no sleep
region: frankfurt          # closest to Israel + Europe
repo: https://github.com/{you}/buzzoff
branch: main
rootDir: backend
buildCommand: pip install -r requirements.txt
startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: buzzoff-db
      property: connectionString
  - key: ADMIN_USERNAME
    value: admin
  - key: ADMIN_PASSWORD
    generateValue: true
  - key: JWT_SECRET
    generateValue: true
  - key: NOMINATIM_USER_AGENT
    value: buzzoff-app
  - key: GOOGLE_GEOCODING_API_KEY
    value: (set manually)
  - key: PACK_STORAGE_PATH
    value: /data/packs
disk:
  name: pack-storage
  mountPath: /data/packs
  sizeGB: 1
healthCheckPath: /api/v1/health
```

### 2. buzzoff-admin (Static Site)

```yaml
name: buzzoff-admin
type: static
repo: https://github.com/{you}/buzzoff
branch: main
rootDir: admin
buildCommand: npm ci && npm run build
publishPath: dist
envVars:
  - key: VITE_API_URL
    value: https://buzzoff-api.onrender.com
headers:
  - path: /*
    name: X-Frame-Options
    value: DENY
routes:
  - type: rewrite
    source: /*
    destination: /index.html    # SPA routing
```

### 3. buzzoff-db (PostgreSQL)

```yaml
name: buzzoff-db
type: postgres
plan: starter             # $7/mo - 1 GB, persistent
region: frankfurt
version: 16
postgresMajorVersion: 16
```

PostGIS setup (run once after DB creation):
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### 4. Cron Jobs

```yaml
# Fetch all enabled data sources
name: buzzoff-fetch
type: cron
runtime: python
schedule: "0 0 * * 0"    # weekly, Sunday midnight
repo: https://github.com/{you}/buzzoff
branch: main
rootDir: backend
buildCommand: pip install -r requirements.txt
startCommand: python -m jobs.fetch_sources
envVars:
  - key: DATABASE_URL
    fromDatabase:
      name: buzzoff-db
      property: connectionString

# Geocode pending records
name: buzzoff-geocode
type: cron
runtime: python
schedule: "0 2 * * *"    # daily, 2 AM
startCommand: python -m jobs.geocode_pending
# same repo, env as above

# Merge/dedup cameras
name: buzzoff-merge
type: cron
runtime: python
schedule: "0 4 * * *"    # daily, 4 AM
startCommand: python -m jobs.merge_cameras
# same repo, env as above

# Generate packs
name: buzzoff-packgen
type: cron
runtime: python
schedule: "0 6 * * *"    # daily, 6 AM
startCommand: python -m jobs.generate_packs
# same repo, env as above
```

## Render Blueprint (render.yaml)

All services defined in a single file for one-click deploy:

```yaml
databases:
  - name: buzzoff-db
    plan: starter
    region: frankfurt
    postgresMajorVersion: 16

services:
  - type: web
    name: buzzoff-api
    runtime: python
    plan: starter
    region: frankfurt
    rootDir: backend
    buildCommand: pip install -r requirements.txt
    startCommand: uvicorn app.main:app --host 0.0.0.0 --port $PORT
    healthCheckPath: /api/v1/health
    disk:
      name: pack-storage
      mountPath: /data/packs
      sizeGB: 1
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: buzzoff-db
          property: connectionString
      - key: ADMIN_USERNAME
        value: admin
      - key: ADMIN_PASSWORD
        generateValue: true
      - key: JWT_SECRET
        generateValue: true
      - key: NOMINATIM_USER_AGENT
        value: buzzoff-app
      - key: GOOGLE_GEOCODING_API_KEY
        sync: false
      - key: PACK_STORAGE_PATH
        value: /data/packs

  - type: static
    name: buzzoff-admin
    rootDir: admin
    buildCommand: npm ci && npm run build
    publishPath: dist
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
    envVars:
      - key: VITE_API_URL
        fromService:
          type: web
          name: buzzoff-api
          property: host

  - type: cron
    name: buzzoff-fetch
    runtime: python
    region: frankfurt
    plan: starter
    rootDir: backend
    schedule: "0 0 * * 0"
    buildCommand: pip install -r requirements.txt
    startCommand: python -m jobs.fetch_sources
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: buzzoff-db
          property: connectionString
      - key: NOMINATIM_USER_AGENT
        value: buzzoff-app

  - type: cron
    name: buzzoff-geocode
    runtime: python
    region: frankfurt
    plan: starter
    rootDir: backend
    schedule: "0 2 * * *"
    buildCommand: pip install -r requirements.txt
    startCommand: python -m jobs.geocode_pending
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: buzzoff-db
          property: connectionString
      - key: NOMINATIM_USER_AGENT
        value: buzzoff-app
      - key: GOOGLE_GEOCODING_API_KEY
        sync: false

  - type: cron
    name: buzzoff-merge
    runtime: python
    region: frankfurt
    plan: starter
    rootDir: backend
    schedule: "0 4 * * *"
    buildCommand: pip install -r requirements.txt
    startCommand: python -m jobs.merge_cameras
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: buzzoff-db
          property: connectionString

  - type: cron
    name: buzzoff-packgen
    runtime: python
    region: frankfurt
    plan: starter
    rootDir: backend
    schedule: "0 6 * * *"
    buildCommand: pip install -r requirements.txt
    startCommand: python -m jobs.generate_packs
    envVars:
      - key: DATABASE_URL
        fromDatabase:
          name: buzzoff-db
          property: connectionString
      - key: PACK_STORAGE_PATH
        value: /data/packs
```

## Cost Estimate (Render)

| Service | Plan | Monthly Cost |
|---------|------|-------------|
| buzzoff-api (Web Service) | Starter | $7 |
| buzzoff-admin (Static Site) | Free | $0 |
| buzzoff-db (PostgreSQL) | Starter | $7 |
| buzzoff-fetch (Cron) | Starter | $1* |
| buzzoff-geocode (Cron) | Starter | $1* |
| buzzoff-merge (Cron) | Starter | $1* |
| buzzoff-packgen (Cron) | Starter | $1* |
| Persistent Disk (1 GB) | — | $0.25 |
| **Total** | | **~$18/mo** |

*Cron jobs on Starter are $7/mo each but only billed for runtime. With short execution times (minutes/day), actual cost is minimal. Consider combining into a single cron job to reduce cost.

### Cost optimization: Single cron job

Instead of 4 separate cron jobs, run one that chains all steps:

```yaml
- type: cron
  name: buzzoff-pipeline
  schedule: "0 2 * * *"    # daily, 2 AM
  startCommand: python -m jobs.run_pipeline  # fetch → geocode → merge → pack
```

This reduces to 1 cron job instead of 4. Estimated total: **~$15/mo**.

## Scaling Notes

### When to scale

| Metric | Current | Action needed |
|--------|---------|--------------|
| API requests | < 1000/day | Starter is fine |
| API requests | > 10,000/day | Upgrade to Standard ($25/mo) |
| Pack downloads | > 100 concurrent | Add Cloudflare CDN in front |
| Database size | > 1 GB | Upgrade Postgres plan |
| Pack storage | > 1 GB | Increase disk size |
| Countries | > 20 | Consider S3 for pack storage |

### CDN layer (when needed)

```
Android App → Cloudflare (cache pack files) → Render API
                    ↑
              Cache TTL: 1 hour for /packs/*/meta
              Cache TTL: 1 day for /packs/*/data
              Free tier handles millions of requests
```

Add Cloudflare when pack downloads exceed what a single Render instance handles. Until then, Render serves files directly.

## Environment Management

### Development
- Local FastAPI + local PostgreSQL (Docker Compose)
- Android emulator hitting localhost (or ngrok tunnel)

### Staging (optional)
- Separate Render services with `-staging` suffix
- Separate database
- Deploy from `develop` branch

### Production
- Render services as described above
- Deploy from `main` branch
- Auto-deploy on push

## Monitoring

Render provides:
- Service logs (stdout/stderr)
- Deploy logs
- Health check monitoring
- Basic metrics (CPU, memory, request count)

Additional monitoring (future):
- Sentry for error tracking (FastAPI + Android)
- Simple uptime check on /api/v1/health
