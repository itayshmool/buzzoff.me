# Deployment Architecture — Render

## Domain & DNS

### Primary Domain: `buzzoff.me`
- **Registrar:** Namecheap
- **Also owns:** `bazzoff.me` (typo variant, not in use)

### DNS Records (Namecheap Advanced DNS)

| Type | Host | Value | TTL |
|------|------|-------|-----|
| CNAME | `api` | `buzzoff-api.onrender.com.` | Automatic |
| CNAME | `www` | `buzzoff-admin.onrender.com.` | Automatic |
| URL Redirect | `@` | `https://www.buzzoff.me` | Permanent (301) |

### Render Custom Domains

| Render Service | Custom Domain | Purpose |
|----------------|---------------|---------|
| buzzoff-admin | `www.buzzoff.me` | Admin dashboard |
| buzzoff-api | `api.buzzoff.me` | Backend API |

- Root domain `buzzoff.me` → 301 redirect to `www.buzzoff.me` (handled by Namecheap URL redirect)
- Render auto-provisions SSL via Let's Encrypt for both custom domains
- `www.buzzoff.me` → Render redirects to `buzzoff.me` internally (Render's default behavior)

### URL Map

| URL | Service | Notes |
|-----|---------|-------|
| `https://www.buzzoff.me` | Admin dashboard (static site) | Also serves `/buzzoff.apk` |
| `https://api.buzzoff.me` | FastAPI backend | Public + Admin APIs |
| `https://api.buzzoff.me/api/v1/*` | Public API | Country list, pack downloads |
| `https://api.buzzoff.me/admin/api/*` | Admin API | CRUD operations, jobs |
| `https://buzzoff.me` | 301 → `www.buzzoff.me` | Namecheap redirect |

### App API Base URLs

| Client | Base URL | Config Location |
|--------|----------|-----------------|
| Admin dashboard | `https://api.buzzoff.me` | `admin/.env` → `VITE_API_URL` |
| Flutter app | `https://api.buzzoff.me` | `app/lib/services/pack_api_client.dart` |
| Fallback (Render) | `https://buzzoff-api.onrender.com` | Direct Render URL, always works |

## Render Service IDs

| Service | Render ID | Type |
|---------|-----------|------|
| buzzoff-admin | `srv-d6o8gah4tr6s73bkm73g` | Static Site |
| buzzoff-api | `srv-d6o8ltia214c73enbs9g` | Web Service |
| buzzoff-db | `dpg-d6o8rnqa214c73b5vhlg-a` | PostgreSQL |

## Overview

All backend infrastructure runs on Render. The Android app is distributed via APK download from the admin dashboard and eventually via Google Play.

```
┌──────────────────────────────────────────────────────────────────┐
│                         RENDER PLATFORM                           │
│                                                                   │
│  ┌──────────────────────┐    ┌─────────────────────────────────┐ │
│  │  buzzoff-api          │    │  buzzoff-admin                  │ │
│  │  Web Service (Python) │    │  Static Site (React)            │ │
│  │  api.buzzoff.me       │    │  www.buzzoff.me                 │ │
│  │                       │    │                                 │ │
│  │  FastAPI app:         │    │  Admin dashboard SPA            │ │
│  │  - Public API         │    │  - Talks to api.buzzoff.me      │ │
│  │    /api/v1/*           │    │  - Protected by login           │ │
│  │  - Admin API          │    │  - Serves buzzoff.apk           │ │
│  │    /admin/api/*        │    │                                 │ │
│  │  - Pack file serving   │    │  Build: npm run build           │ │
│  │    /api/v1/packs/*/data│    │  Publish: dist/                 │ │
│  │                       │    │                                 │ │
│  └──────────┬───────────┘    └─────────────────────────────────┘ │
│             │                                                    │
│             │ connects to                                        │
│             ▼                                                    │
│  ┌──────────────────────┐                                        │
│  │  buzzoff-db           │                                        │
│  │  PostgreSQL + PostGIS │                                        │
│  │                       │                                        │
│  │  Tables:              │                                        │
│  │  - countries           │                                       │
│  │  - sources             │                                       │
│  │  - raw_cameras         │                                       │
│  │  - cameras             │                                       │
│  │  - geocode_cache       │                                       │
│  │  - packs               │                                       │
│  │  - community_reports   │                                       │
│  │                       │                                        │
│  │  Plan: Starter ($7/mo)│                                        │
│  │  PostGIS: via extension│                                       │
│  └──────────────────────┘                                        │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  CRON JOBS                                                    │ │
│  │                                                               │ │
│  │  buzzoff-fetch    (Weekly: 0 0 * * 0)                         │ │
│  │  → python jobs/fetch_sources.py                               │ │
│  │  → Fetches all enabled sources for all countries              │ │
│  │                                                               │ │
│  │  buzzoff-geocode  (Daily: 0 2 * * *)                          │ │
│  │  → python jobs/geocode_pending.py                             │ │
│  │  → Geocodes raw records missing coordinates                   │ │
│  │                                                               │ │
│  │  buzzoff-merge    (Daily: 0 4 * * *)                          │ │
│  │  → python jobs/merge_cameras.py                               │ │
│  │  → Deduplicates and merges raw records into cameras table     │ │
│  │                                                               │ │
│  │  buzzoff-packgen  (Daily: 0 6 * * *)                          │ │
│  │  → python jobs/generate_packs.py                              │ │
│  │  → Regenerates packs for countries with changed data          │ │
│  │                                                               │ │
│  │  All cron jobs share the same repo/codebase as buzzoff-api    │ │
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
│  Namecheap              — domain registrar (buzzoff.me)           │
│  Nominatim (OSM)        — geocoding, free, 1 req/sec             │
│  Overpass API (OSM)     — camera data, free                      │
│  Google Geocoding API   — fallback geocoding, pay-per-use        │
│  data.gov.il            — Israeli government camera data         │
│  Google Play Console    — Android app distribution (future)      │
│  GitHub                 — source code, CI/CD                     │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                      ANDROID APP                                  │
│                                                                   │
│  APK download: https://www.buzzoff.me/buzzoff.apk                │
│                                                                   │
│  On first launch:                                                │
│  GET api.buzzoff.me/api/v1/countries                             │
│  GET api.buzzoff.me/api/v1/packs/IL/data                         │
│                                                                   │
│  Weekly (WiFi only):                                             │
│  GET api.buzzoff.me/api/v1/packs/IL/meta                         │
│  GET api.buzzoff.me/api/v1/packs/IL/data (if new)                │
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
region: oregon
repo: https://github.com/itayshmool/buzzoff.me
branch: main
buildCommand: cd backend && pip install -r requirements.txt && alembic upgrade head
startCommand: cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT
customDomains:
  - api.buzzoff.me
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
repo: https://github.com/itayshmool/buzzoff.me
branch: main
buildCommand: cd admin && npm ci && npm run build
publishPath: admin/dist
customDomains:
  - www.buzzoff.me
envVars:
  - key: VITE_API_URL
    value: https://api.buzzoff.me
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
region: oregon
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
repo: https://github.com/itayshmool/buzzoff.me
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
    region: oregon
    postgresMajorVersion: 16

services:
  - type: web
    name: buzzoff-api
    runtime: python
    plan: starter
    region: oregon
    buildCommand: cd backend && pip install -r requirements.txt && alembic upgrade head
    startCommand: cd backend && uvicorn app.main:app --host 0.0.0.0 --port $PORT
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
    buildCommand: cd admin && npm ci && npm run build
    publishPath: admin/dist
    routes:
      - type: rewrite
        source: /*
        destination: /index.html
    envVars:
      - key: VITE_API_URL
        value: https://api.buzzoff.me

  - type: cron
    name: buzzoff-fetch
    runtime: python
    region: oregon
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
    region: oregon
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
    region: oregon
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
    region: oregon
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
Android App → Cloudflare (cache pack files) → api.buzzoff.me
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

## Deployment Gotchas & Lessons Learned

### 1. `render.yaml` does NOT update existing env vars
Changing env vars in `render.yaml` only affects **initial provisioning** of new services. To update env vars on an already-running service, use the Render Dashboard or API directly.

**Example:** Adding `https://admin.buzzoff.me` to `ADMIN_CORS_ORIGINS` in `render.yaml` did not update the live service. The env var had to be updated via the Render API.

### 2. Android INTERNET permission required in release builds
Flutter debug builds auto-inject the `INTERNET` permission via the debug `AndroidManifest.xml`. **Release builds do not.** The main `AndroidManifest.xml` must explicitly include:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```
Without it, all HTTP requests silently fail — no error, just connection timeouts.

### 3. Pack files must be regenerated after disk changes
Pack `.sqlite` files live on Render's persistent disk at `/data/packs`. If the disk is recreated or the service is reprovisioned, the DB still has pack records but the files are gone. Fix: trigger `generate_packs` via the admin API:
```
POST /admin/api/jobs/run/generate_packs
```

### 4. CORS preflight returns 400 for disallowed origins
Starlette's CORS middleware returns HTTP 400 (not 403) when a preflight `OPTIONS` request comes from a disallowed origin. This can be confusing — the browser shows a CORS error, but the server logs show `400 Bad Request` on `OPTIONS`.

## Monitoring

Render provides:
- Service logs (stdout/stderr)
- Deploy logs
- Health check monitoring
- Basic metrics (CPU, memory, request count)

Additional monitoring (future):
- Sentry for error tracking (FastAPI + Android)
- Simple uptime check on /api/v1/health
