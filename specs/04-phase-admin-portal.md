# Phase 4: Admin Portal

## Goal

Build a web-based admin dashboard to manage the data pipeline visually. Add countries, configure data sources, trigger fetches, review geocoding failures, preview cameras on a map, and publish packs. Replaces manual database/script operations with a UI.

## Depends On

- Phase 1 (backend API and data pipeline)

## Deliverables

1. React SPA (admin frontend)
2. Admin API endpoints (FastAPI extension)
3. Country management (CRUD)
4. Source management (add/edit/test sources per country)
5. Camera map preview
6. Geocoding review queue (manual fixes)
7. Pack publishing workflow
8. Basic auth (single admin user, no public access)

## Admin API Endpoints

```
Authentication:
POST /admin/api/auth/login          → JWT token

Countries:
GET    /admin/api/countries          → list all countries
POST   /admin/api/countries          → create country
PUT    /admin/api/countries/{code}   → update country
DELETE /admin/api/countries/{code}   → delete country (and all related data)

Sources:
GET    /admin/api/countries/{code}/sources          → list sources for country
POST   /admin/api/countries/{code}/sources          → add source
PUT    /admin/api/sources/{id}                      → update source
DELETE /admin/api/sources/{id}                       → delete source
POST   /admin/api/sources/{id}/test                 → test fetch (dry run, return sample records)
POST   /admin/api/sources/{id}/fetch                → trigger manual fetch

Cameras:
GET    /admin/api/countries/{code}/cameras           → list cameras (paginated, filterable)
GET    /admin/api/countries/{code}/cameras/geojson   → cameras as GeoJSON (for map)
GET    /admin/api/countries/{code}/cameras/stats      → count by type, source, confidence

Geocoding:
GET    /admin/api/geocoding/queue                    → records needing geocoding
GET    /admin/api/geocoding/failed                   → records that failed geocoding
PUT    /admin/api/geocoding/{id}/resolve             → manually set lat/lon for a record
POST   /admin/api/geocoding/retry-failed             → retry all failed records

Packs:
GET    /admin/api/countries/{code}/packs             → list pack versions
POST   /admin/api/countries/{code}/packs/generate    → trigger pack generation
GET    /admin/api/countries/{code}/packs/{version}   → pack details

Jobs:
GET    /admin/api/jobs                               → list recent job runs
GET    /admin/api/jobs/{id}                          → job details + logs
POST   /admin/api/jobs/fetch-all                     → trigger all source fetches
POST   /admin/api/jobs/geocode-pending               → trigger geocoding run
POST   /admin/api/jobs/merge                         → trigger merge/dedup run

Dashboard:
GET    /admin/api/dashboard/stats                    → overview stats
```

## Admin UI Screens

### Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│ BuzzOff Admin                              [admin] [logout]│
│─────────────────────────────────────────────────────────────│
│                                                             │
│  Countries: 2        Total Cameras: 2,528                   │
│  Sources: 5          Pending Geocoding: 12                  │
│  Pack Downloads: 847 Failed Geocoding: 3                    │
│                                                             │
│  Recent Activity                                            │
│  ─────────────                                              │
│  ● 10:00  Fetched gov.il source (IL) — 187 records         │
│  ● 09:45  Fetched OSM source (DE) — 2,341 records          │
│  ● 09:30  Generated pack IL v4 — 187 cameras               │
│  ● 09:15  Geocoded 15 records for IL                        │
│  ⚠ 08:00  Geocoding failed for 3 records (IL)              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Country Detail

```
┌─────────────────────────────────────────────────────────────┐
│ ← Countries    Israel (IL)                     [Edit] [Delete]│
│─────────────────────────────────────────────────────────────│
│                                                             │
│  Cameras: 187    Speed unit: km/h    Status: Enabled        │
│  Latest pack: v4 (2026-03-10)       Pack size: 45 KB       │
│                                                             │
│  Sources                                        [+ Add]    │
│  ─────────                                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ gov.il Enforcement Cameras    [Excel]                │   │
│  │ Schedule: Weekly    Last fetch: 2026-03-10            │   │
│  │ Records: 154       Confidence: 1.0                    │   │
│  │ [Test] [Fetch Now] [Edit] [Disable]                   │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ OpenStreetMap Israel          [Overpass]              │   │
│  │ Schedule: Daily     Last fetch: 2026-03-10            │   │
│  │ Records: 45         Confidence: 0.7                   │   │
│  │ [Test] [Fetch Now] [Edit] [Disable]                   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Camera Map Preview                                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                                                      │   │
│  │              [Leaflet/Mapbox map]                     │   │
│  │              dots = cameras                           │   │
│  │              color = source                           │   │
│  │              click = details popup                    │   │
│  │                                                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
│  Packs                                      [Generate New]  │
│  ─────                                                      │
│  v4  2026-03-10  187 cameras  45 KB  ✅ published           │
│  v3  2026-03-03  185 cameras  44 KB  archived               │
│  v2  2026-02-24  180 cameras  43 KB  archived               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Source Editor

```
┌─────────────────────────────────────────────────────────────┐
│ ← Israel    Edit Source: gov.il Enforcement Cameras         │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  Name:     [gov.il Enforcement Cameras                    ] │
│  Adapter:  [Excel ▼]                                        │
│  URL:      [https://data.gov.il/dataset/.../download/...  ] │
│  Schedule: [Weekly ▼] (cron: 0 0 * * 0)                    │
│  Confidence: [1.0   ]                                       │
│                                                             │
│  Column Mapping                                             │
│  ──────────────                                             │
│  Road name:   [Column B ▼]                                  │
│  Address:     [Column C ▼]                                  │
│  Speed limit: [Column D ▼]                                  │
│  Type:        [Column E ▼]                                  │
│  Latitude:    [— none — ▼]  ← triggers geocoding           │
│  Longitude:   [— none — ▼]                                  │
│                                                             │
│  Type Mapping                                               │
│  ────────────                                               │
│  "מצלמת מהירות"               → [fixed_speed ▼]            │
│  "מצלמת רמזור"                → [red_light ▼]              │
│  "מצלמת מהירות ממוצעת - התחלה" → [avg_speed_start ▼]       │
│  [+ Add mapping]                                            │
│                                                             │
│                        [Test Fetch]  [Save]                 │
└─────────────────────────────────────────────────────────────┘
```

### Geocoding Review Queue

```
┌─────────────────────────────────────────────────────────────┐
│ Geocoding Review                                            │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  Filter: [Failed ▼] [Israel ▼]          3 records           │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ "כביש 90, קילומטר 23"                                │   │
│  │ Source: gov.il    Type: fixed_speed                   │   │
│  │ Nominatim: ✗ failed   Google: ✗ failed                │   │
│  │                                                      │   │
│  │ [Map - click to set location]                        │   │
│  │ Lat: [31.7683___]  Lon: [35.2137___]                 │   │
│  │ [Resolve] [Skip]                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Admin Frontend Structure

```
admin/
├── src/
│   ├── api/
│   │   ├── client.ts               # axios instance with auth
│   │   ├── countries.ts
│   │   ├── sources.ts
│   │   ├── cameras.ts
│   │   ├── geocoding.ts
│   │   ├── packs.ts
│   │   └── jobs.ts
│   ├── components/
│   │   ├── layout/
│   │   │   ├── AppLayout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   └── Header.tsx
│   │   ├── maps/
│   │   │   ├── CameraMap.tsx        # Leaflet map
│   │   │   └── LocationPicker.tsx   # click-to-set-coords
│   │   ├── sources/
│   │   │   ├── SourceCard.tsx
│   │   │   ├── SourceEditor.tsx
│   │   │   └── ColumnMapper.tsx
│   │   └── common/
│   │       ├── DataTable.tsx
│   │       ├── StatusBadge.tsx
│   │       └── ConfirmDialog.tsx
│   ├── pages/
│   │   ├── DashboardPage.tsx
│   │   ├── CountriesPage.tsx
│   │   ├── CountryDetailPage.tsx
│   │   ├── SourceEditorPage.tsx
│   │   ├── GeocodingQueuePage.tsx
│   │   ├── JobsPage.tsx
│   │   └── LoginPage.tsx
│   ├── hooks/
│   │   ├── useAuth.ts
│   │   └── useCountries.ts
│   ├── App.tsx
│   └── main.tsx
├── package.json
├── vite.config.ts
├── tsconfig.json
└── index.html
```

## Authentication

Simple approach for admin portal:
- Single admin user, credentials in environment variables
- JWT token issued on login, stored in localStorage
- Token sent via Authorization header
- No public registration, no user management
- Can be upgraded to OAuth/SSO later if needed

## Acceptance Criteria

- [ ] Admin can log in with credentials
- [ ] Admin can create/edit/delete countries
- [ ] Admin can add/edit/delete sources per country
- [ ] Admin can test a source (dry run fetch, preview sample records)
- [ ] Admin can trigger a manual source fetch
- [ ] Admin can view cameras on a map per country
- [ ] Admin can review and manually resolve failed geocoding records
- [ ] Admin can trigger pack generation
- [ ] Admin can see pack version history
- [ ] Admin can see recent job runs and their status
- [ ] Dashboard shows overview stats
- [ ] Admin portal deployed as static site on Render
- [ ] Admin API endpoints secured behind authentication
