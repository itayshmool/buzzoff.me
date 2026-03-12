# Feature: Automated Pipeline Scheduler (Cron)

## Status: PLANNED

## Overview
Add automatic scheduling for the camera data pipeline (fetch → merge → generate packs) so new data feeds and developer submissions are processed without manual admin intervention. Configurable from the admin dashboard.

## Problem
Currently all three pipeline jobs are manual-only:
1. `fetch_sources` — pull camera data from enabled feeds
2. `merge_cameras` — deduplicate and merge raw cameras
3. `generate_packs` — create SQLite pack files for the app

When a new data feed is added (e.g. Germany via Developer API), an admin must manually trigger all three jobs via the API. If the Render disk gets wiped, packs disappear until someone notices and regenerates them. There's no visibility into when the next run will happen.

## Solution
Add APScheduler to the FastAPI backend with admin UI controls on a new "Cron" page in the admin dashboard.

---

## Architecture

### Why APScheduler (not Render Cron Job)
- Single Render instance → no distributed scheduling issues
- Starter plan doesn't sleep → scheduler stays alive
- Configurable from admin UI without redeploying
- Per-source schedule support possible via existing `Source.schedule` DB field
- No extra Render service or cost

### Scheduler Setup
- **Library:** `apscheduler[asyncio]` (v4.x or latest 3.x with AsyncIOScheduler)
- **Job store:** In-memory (state reconstructed from DB on startup)
- **Executor:** AsyncIO (matches existing async job functions)
- **Lifecycle:** Start on FastAPI startup event, shut down on shutdown event

---

## Backend Changes

### 1. New Model: `SchedulerSettings`

```
Table: scheduler_settings (single-row config)
├── id              UUID (PK, default)
├── enabled         Boolean (default: true)
├── interval_hours  Integer (default: 6)
├── last_run_at     DateTime (nullable)
├── next_run_at     DateTime (nullable)
├── updated_at      DateTime
```

Single-row table — stores the global pipeline schedule. One row, upserted on changes.

### 2. New File: `backend/app/services/scheduler.py`

Responsibilities:
- Initialize APScheduler on app startup
- Load `SchedulerSettings` from DB
- Register the pipeline job at the configured interval
- Expose functions: `start_scheduler()`, `stop_scheduler()`, `reschedule(interval_hours)`
- Pipeline job: run `fetch_all_sources()` → `merge_all_countries()` → `generate_all_packs()` in sequence
- Log each run to `JobRun` table with `job_type = "auto_pipeline"`
- Handle errors: if one step fails, log it and continue to next step (don't block the whole pipeline)

### 3. New API Endpoints: `backend/app/api/routes/admin_scheduler.py`

```
GET  /admin/api/scheduler        → current scheduler state
PUT  /admin/api/scheduler        → update settings (enable/disable, interval)
POST /admin/api/scheduler/run    → trigger pipeline immediately
```

**GET response:**
```json
{
  "enabled": true,
  "interval_hours": 6,
  "last_run_at": "2026-03-12T14:00:00Z",
  "next_run_at": "2026-03-12T20:00:00Z",
  "status": "idle"
}
```

`status` values: `"idle"`, `"running"`, `"disabled"`

**PUT body:**
```json
{
  "enabled": true,
  "interval_hours": 6
}
```

Interval options: `1, 3, 6, 12, 24` (hours). Validated server-side.

### 4. Pipeline Runner: `backend/jobs/pipeline.py`

New file — orchestrates the full pipeline as a single operation:

```python
async def run_full_pipeline() -> PipelineResult:
    """Run fetch → merge → generate in sequence. Log to JobRun."""
    results = {}
    for step_name, runner in [
        ("fetch_sources", fetch_all_sources),
        ("merge_cameras", merge_all_countries),
        ("generate_packs", generate_all_packs),
    ]:
        try:
            await runner()
            results[step_name] = "completed"
        except Exception as e:
            results[step_name] = f"failed: {e}"
            logger.exception("Pipeline step %s failed", step_name)
    return results
```

### 5. Wire Into FastAPI App

In `backend/app/main.py`:
- Import scheduler
- Add `@app.on_event("startup")` → `start_scheduler()`
- Add `@app.on_event("shutdown")` → `stop_scheduler()`
- Register `admin_scheduler` router under `/admin/api/`

### 6. Alembic Migration

New migration for `scheduler_settings` table + seed with defaults:
- `enabled = True`
- `interval_hours = 6`

### 7. Update `requirements.txt`

Add:
```
apscheduler==3.10.4
```

(Use 3.x — stable, well-tested with AsyncIOScheduler. 4.x is still in alpha.)

---

## Admin Dashboard Changes

### New Page: `SchedulerPage.tsx`

**Route:** `/scheduler`
**Nav label:** `CRON` (added to Sidebar between LAP LOG and DRIVERS)

**Layout:**

```
┌──────────────────────────────────────────────┐
│  AUTO ⚡ PILOT                                │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │  Pipeline Scheduler         [ON/OFF]   │  │
│  │                                        │  │
│  │  Interval: [● 1h] [3h] [6h] [12h] [24h] │
│  │                                        │  │
│  │  Last run:  2026-03-12 14:00 UTC       │  │
│  │  Next run:  2026-03-12 20:00 UTC       │  │
│  │  Status:    Idle ●                     │  │
│  │                                        │  │
│  │  [ 🏁 RUN NOW ]                        │  │
│  └────────────────────────────────────────┘  │
│                                              │
│  RECENT PIPELINE RUNS                        │
│  ┌────────────────────────────────────────┐  │
│  │ Time        │ Fetch │ Merge │ Packs    │  │
│  │ 14:00 today │  ✅   │  ✅   │  ✅     │  │
│  │ 08:00 today │  ✅   │  ✅   │  ❌     │  │
│  │ 02:00 today │  ✅   │  ✅   │  ✅     │  │
│  └────────────────────────────────────────┘  │
└──────────────────────────────────────────────┘
```

### Components:
- **Toggle switch** — enable/disable scheduler (PUT `/admin/api/scheduler`)
- **Interval selector** — button group with preset options (1h, 3h, 6h, 12h, 24h)
- **Status display** — last run, next run, current status with color indicator
- **Run Now button** — triggers immediate pipeline run (POST `/admin/api/scheduler/run`)
- **Recent runs table** — last 10 pipeline runs showing per-step status, filtered from JobRun where `job_type = "auto_pipeline"`

### New API Client: `admin/src/api/scheduler.ts`

```typescript
export const getScheduler = () => client.get('/scheduler');
export const updateScheduler = (data: { enabled?: boolean; interval_hours?: number }) =>
  client.put('/scheduler', data);
export const runPipelineNow = () => client.post('/scheduler/run');
```

### Sidebar Update: `admin/src/components/layout/Sidebar.tsx`

Add between LAP LOG and DRIVERS:
```typescript
{ to: '/scheduler', label: 'CRON' },
```

### Route Update: `admin/src/App.tsx`

Add:
```typescript
<Route path="/scheduler" element={<SchedulerPage />} />
```

---

## Styling

Match existing admin dashboard racing theme:
- Card background: `bg-surface-card` with `border-grid` border
- Toggle: green glow when ON, dim when OFF
- Interval buttons: match the filter buttons on JobsPage
- "RUN NOW" button: styled like existing action buttons (green, racing theme)
- Status indicator: green dot for idle, pulsing gold for running, red for disabled
- Section title: `AUTO ⚡ PILOT` with glow effect matching other page titles

---

## Files to Create

| File | Purpose |
|------|---------|
| `backend/app/services/scheduler.py` | APScheduler setup and management |
| `backend/app/api/routes/admin_scheduler.py` | Scheduler admin API endpoints |
| `backend/jobs/pipeline.py` | Full pipeline orchestrator |
| `backend/alembic/versions/xxx_add_scheduler_settings.py` | DB migration |
| `admin/src/pages/SchedulerPage.tsx` | Admin scheduler UI |
| `admin/src/api/scheduler.ts` | Scheduler API client |

## Files to Modify

| File | Change |
|------|--------|
| `backend/requirements.txt` | Add `apscheduler==3.10.4` |
| `backend/app/main.py` | Wire scheduler startup/shutdown + register router |
| `backend/app/models/__init__.py` | Export `SchedulerSettings` |
| `admin/src/App.tsx` | Add `/scheduler` route |
| `admin/src/components/layout/Sidebar.tsx` | Add CRON nav link |

---

## Edge Cases

- **Render redeploy:** Scheduler state is in DB, reconstructed on startup. No data lost.
- **Overlapping runs:** APScheduler's `max_instances=1` prevents concurrent pipeline runs. If a run is still going when the next is due, it's skipped.
- **Job failure:** Each pipeline step is independent. If `fetch_sources` fails, `merge_cameras` and `generate_packs` still run (using existing data).
- **Disk wipe:** `generate_packs` recreates all pack files from DB data. The scheduler will auto-fix this on next run.
- **Startup race:** Scheduler starts after DB connection is established (FastAPI lifespan dependency).

---

## Verification

1. `cd backend && pip install -r requirements.txt` — installs APScheduler
2. `cd backend && alembic upgrade head` — creates scheduler_settings table
3. Start backend → scheduler initializes with 6h default
4. `GET /admin/api/scheduler` → returns enabled=true, interval=6, next_run_at set
5. `PUT /admin/api/scheduler {"interval_hours": 1}` → next_run_at updates
6. `POST /admin/api/scheduler/run` → pipeline runs immediately
7. Admin UI → /scheduler page shows controls and recent runs
8. Wait for interval → pipeline runs automatically, JobRun row created

---

## Future Enhancements (not in scope)
- Per-source schedules using `Source.schedule` field (cron expressions)
- Webhook/email notifications on pipeline failure
- Pipeline step retries with exponential backoff
- Selective pipeline (e.g. only run for specific countries)
