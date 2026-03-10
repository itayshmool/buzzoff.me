# Phase 6: Hebrew + RTL + Community Reporting

## Goal

Add Hebrew language support with RTL layout, and introduce community camera reporting so users can contribute new camera locations.

## Depends On

- Phase 5 (multi-country working)

## Deliverables

1. Hebrew translation
2. RTL layout support
3. Language auto-detection (follows system locale)
4. Community camera reporting (user submits location + type)
5. Moderation queue in admin portal
6. Community data as a source in the pipeline

## Part A: Internationalization + RTL

### String extraction

The app has ~35 strings total. All already in `res/values/strings.xml` (English).

Add `res/values-he/strings.xml` with Hebrew translations.

### RTL Implementation

Since the app was built RTL-ready from Phase 2:
- All layouts use `start`/`end` (not `left`/`right`)
- Compose uses `LocalLayoutDirection`
- Icons that imply direction (arrows, etc.) flip automatically

Remaining work:
- Test all screens in forced RTL mode (Developer Options → Force RTL)
- Fix any hardcoded margins/paddings that break
- Ensure notification text renders correctly in Hebrew
- Ensure map (if any in future) handles RTL labels

### Language selection

Follow system locale. No in-app language picker needed for now.

```
System locale = he_IL → Hebrew strings loaded, RTL layout
System locale = de_DE → English strings (no German translation yet)
System locale = en_US → English strings, LTR layout
```

### Strings to translate (complete list)

```xml
<!-- Setup -->
<string name="welcome_title">Welcome to BuzzOff</string>
<string name="grant_permissions">Grant permissions to get started</string>
<string name="permission_location">Location access</string>
<string name="permission_location_desc">Required to detect speed cameras nearby</string>
<string name="permission_activity">Activity recognition</string>
<string name="permission_activity_desc">Required to detect when you are driving</string>
<string name="permission_notification">Notifications</string>
<string name="permission_notification_desc">Required for background operation</string>
<string name="permission_battery">Battery optimization</string>
<string name="permission_battery_desc">Tap to exempt from battery optimization</string>
<string name="btn_continue">Continue</string>

<!-- Country picker -->
<string name="select_country">Select your country</string>
<string name="cameras_count">%d cameras</string>
<string name="detect_automatically">Detect automatically</string>
<string name="downloading">Downloading %s…</string>

<!-- Settings -->
<string name="app_name">BuzzOff</string>
<string name="settings_title">Settings</string>
<string name="alert_distance">Alert distance</string>
<string name="alert_type">Alert type</string>
<string name="alert_vibration">Vibration</string>
<string name="alert_sound">Sound</string>
<string name="activate_speed">Activate at speed</string>
<string name="camera_types">Camera types</string>
<string name="type_speed">Speed cameras</string>
<string name="type_redlight">Red light cameras</string>
<string name="type_avgspeed">Average speed zones</string>
<string name="auto_detect_country">Auto-detect country</string>
<string name="status_waiting">Waiting for driving…</string>
<string name="status_active">Active — monitoring</string>
<string name="status_no_data">No camera data for this location</string>
<string name="cameras_loaded">Cameras loaded: %d</string>
<string name="data_version">Data version: %d</string>
<string name="last_updated">Last updated: %s</string>
<string name="change_country">Change Country</string>
<string name="download_more">Download more countries</string>

<!-- Notifications -->
<string name="notif_channel_name">Driving Monitor</string>
<string name="notif_active_title">BuzzOff</string>
<string name="notif_active_text">Monitoring active</string>

<!-- Country switch -->
<string name="switched_to">Switched to %s</string>
<string name="country_available">You are in %s. Download camera data?</string>

<!-- Community reporting (Phase 6) -->
<string name="report_camera">Report a camera</string>
<string name="report_type">Camera type</string>
<string name="report_speed_limit">Speed limit (optional)</string>
<string name="report_submit">Submit</string>
<string name="report_thanks">Thanks! Your report will be reviewed.</string>
```

## Part B: Community Camera Reporting

### User flow

```
User is driving and sees a camera not in the database
    │
    ▼
Long-press volume button (or shake phone, or open app)
    │
    ▼
Quick report dialog (overlay, minimal):
┌──────────────────────┐
│ Report Camera         │
│                       │
│ Type:                 │
│ ● Speed camera        │
│ ○ Red light           │
│ ○ Average speed       │
│                       │
│ Speed limit: [__] kmh │
│                       │
│ Location: current GPS │
│ (31.7683, 35.2137)   │
│                       │
│   [Cancel] [Submit]   │
└──────────────────────┘
    │
    ▼
Report sent to backend (queued if offline, sent on WiFi)
    │
    ▼
Admin reviews in moderation queue
    │
    ├── Approve → added to cameras table (confidence: 0.4)
    ├── Reject → discarded
    └── Merge → matches existing camera, boosts confidence
```

### Backend additions

```sql
CREATE TABLE community_reports (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code    VARCHAR(2) NOT NULL REFERENCES countries(code),
    lat             DOUBLE PRECISION NOT NULL,
    lon             DOUBLE PRECISION NOT NULL,
    type            VARCHAR(50) NOT NULL,
    speed_limit     INTEGER,
    device_id       VARCHAR(64) NOT NULL,  -- anonymous device hash
    status          VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, approved, rejected, merged
    reviewed_at     TIMESTAMPTZ,
    reviewed_by     TEXT,
    merged_into     UUID,  -- camera ID if merged
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reports_status ON community_reports(status);
CREATE INDEX idx_reports_country ON community_reports(country_code);
```

### API endpoints

```
POST /api/v1/reports
     body: { lat, lon, type, speed_limit, device_id }
     → 201 Created

Admin:
GET    /admin/api/reports?status=pending&country=IL
PUT    /admin/api/reports/{id}/approve
PUT    /admin/api/reports/{id}/reject
PUT    /admin/api/reports/{id}/merge?camera_id=...
```

### Privacy

- No user accounts required
- `device_id` is a hash of Android ID — used only for rate limiting and spam detection
- No personal data collected
- Reports contain only: GPS point, camera type, speed limit
- Rate limit: max 10 reports per device per day

### Spam prevention

- Rate limiting per device_id
- Require minimum speed > 20 kmh when reporting (must be driving)
- Reports within 30m of existing camera → auto-suggest merge
- Reports from same device in same spot → deduplicate
- Admin moderation as final gate

### Admin moderation UI

```
┌─────────────────────────────────────────────────────────────┐
│ Community Reports                          12 pending        │
│─────────────────────────────────────────────────────────────│
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │ Speed camera — 90 kmh                                │   │
│  │ Route 1, km 42 (31.8234, 35.1567)                    │   │
│  │ Reported: 2026-03-10 14:23                            │   │
│  │                                                      │   │
│  │ [Map preview — dot on map]                           │   │
│  │                                                      │   │
│  │ Nearby existing cameras: 1 (85m away, same type)     │   │
│  │                                                      │   │
│  │ [Approve] [Merge with existing] [Reject]             │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Acceptance Criteria

### RTL / i18n
- [ ] Hebrew strings.xml complete and accurate
- [ ] All screens render correctly in RTL mode
- [ ] Notification text renders correctly in Hebrew
- [ ] Language follows system locale automatically
- [ ] No hardcoded LTR assumptions in layouts

### Community reporting
- [ ] User can submit a camera report with type and optional speed limit
- [ ] Report uses current GPS location
- [ ] Reports queued locally if offline, sent when WiFi available
- [ ] Backend receives and stores reports
- [ ] Admin can view pending reports on map
- [ ] Admin can approve, reject, or merge reports
- [ ] Approved reports appear in next pack generation
- [ ] Rate limiting prevents spam (10/day/device)
- [ ] No personal data stored beyond device hash
