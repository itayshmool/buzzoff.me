# Feature: Camera Reports (Crowdsourced Verification)

## Goal

Let drivers report camera issues with one tap while driving. Reports are collected and shown in the admin dashboard for review. "Opposite lane" reports can later auto-enrich camera heading data.

## Report Types

| Type | Label | Icon | Meaning |
|------|-------|------|---------|
| `no_camera` | NO CAMERA | crossed-out camera | Camera doesn't exist at this location |
| `dummy` | DUMMY | warning triangle | Physical camera exists but isn't active |
| `opposite_lane` | WRONG LANE | arrows ↔ | Camera is facing the opposite direction |

## UX Flow

### Trigger: Camera detail bottom sheet

When user taps a camera marker on the map, the detail sheet slides up showing camera info (type, speed limit, road name). Below the info, three large report buttons are shown side by side.

```
┌─────────────────────────────────────┐
│  Speed Camera · 80 km/h             │
│  Road 4, Ayalon Highway             │
│─────────────────────────────────────│
│                                     │
│  ┌───────┐ ┌───────┐ ┌───────────┐ │
│  │   ✕   │ │   ⚠   │ │    ↔      │ │
│  │  NO   │ │ DUMMY │ │  WRONG    │ │
│  │CAMERA │ │       │ │  LANE     │ │
│  └───────┘ └───────┘ └───────────┘ │
│                                     │
└─────────────────────────────────────┘
```

### Button Design (driving-safe)

- Min tap target: 48x64dp (larger than Material minimum)
- High contrast: muted background, bright icon + text
- Single tap = report sent, brief confirmation ("Reported"), sheet dismisses
- No confirmation dialog (driver shouldn't need two taps)
- Debounce: same camera + same report type from same device within 24h is silently ignored

### Post-alert floating action (future)

After an alert fires, a small "Report" chip appears near the speedometer for 10 seconds. Tapping it opens the bottom sheet for the alerted camera. This is a future enhancement — start with the marker tap flow only.

## Data Model

### `camera_reports` table (backend)

| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| camera_id | UUID | FK to cameras.id |
| country_code | VARCHAR(2) | Denormalized for easy querying |
| report_type | VARCHAR(20) | `no_camera`, `dummy`, `opposite_lane` |
| device_hash | VARCHAR(64) | SHA-256 of device ID (anonymous) |
| reporter_lat | FLOAT | User's lat at time of report |
| reporter_lon | FLOAT | User's lon at time of report |
| reporter_heading | FLOAT | User's heading at time of report |
| created_at | TIMESTAMP | When the report was submitted |

### API Endpoint

```
POST /api/v1/cameras/{camera_id}/reports
Body: {
  "report_type": "opposite_lane",
  "device_hash": "abc123...",
  "lat": 32.0853,
  "lon": 34.7818,
  "heading": 180.0
}
Response: 201 Created
```

No auth required (public endpoint). Rate limited by device_hash (max 10 reports/hour).

### Admin Dashboard

New "REPORTS" page in admin sidebar showing:
- Table: camera ID, country, report type, reporter heading, time, count
- Aggregate view: cameras with most reports
- Filter by report type, country
- Action buttons: dismiss report, apply heading fix, lower confidence

## Implementation Phases

### Phase 1 (now): Preview mock + collect data
- Add report buttons to camera detail bottom sheet (preview first)
- Backend: create table + API endpoint
- Admin: reports list page
- No auto-actions on reports

### Phase 2 (later): Auto-enrichment
- 3+ "opposite lane" reports from different devices → auto-set camera heading
- 5+ "no camera" reports → lower confidence below alert threshold
- "dummy" reports shown as badge on admin camera detail

## Heading Enrichment Logic (Phase 2)

When an "opposite_lane" report is submitted, the camera's actual facing direction can be inferred:
```
inferred_heading = (reporter_heading + 180) % 360
```
The reporter is driving in one direction and says the camera faces the other way, so the camera must be facing ~opposite to the reporter's heading. After 3+ consistent reports (inferred headings within 30° of each other), update the camera's heading field.
