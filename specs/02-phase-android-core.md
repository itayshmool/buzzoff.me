# Phase 2: Flutter App Core Engine

## Goal

Build the core driving detection and proximity alert engine using **Flutter (Dart)** for cross-platform support (Android first, iOS post-launch). This phase uses a hardcoded test dataset (a small SQLite file with a few cameras) to validate the full loop: detect driving → GPS tracking → proximity check → vibration alert. No network, no pack downloads — just the engine.

## Framework Decision

**Flutter** was chosen over native Kotlin to enable iOS support from the same codebase post-launch. Key packages: `flutter_map` (OSM tiles), `geolocator` (GPS), `flutter_foreground_task` (background service), `drift` + `sqlite3` (R-tree spatial queries), `riverpod` (state management).

## Deliverables

1. Activity Recognition (detect driving)
2. Foreground location service (GPS tracking while driving)
3. Proximity engine (pure Dart, spatial queries against camera DB)
4. Alert manager (vibration patterns)
5. Boot receiver (survive reboots)
6. Live map screen (OSM tiles, centered on user, camera markers)
7. Settings screen (alert preferences)
8. Test dataset bundled in assets

## Core Loop

```
[Phone idle]
    │
    ▼
ActivityRecognitionReceiver detects IN_VEHICLE
    │
    ▼
Starts LocationTrackingService (foreground)
    │  persistent notification: "BuzzOff active"
    │
    ▼
GPS updates every 3-5 seconds
    │
    ├── speed < threshold? → skip proximity check
    │
    ▼
ProximityEngine.check(lat, lon, heading, speed)
    │
    ├── query R-tree: cameras within 2km
    ├── filter by heading (±45° cone ahead)
    ├── calculate distance to each
    ├── check alert thresholds (800m, 400m)
    ├── debounce (don't re-alert same camera)
    │
    ▼
AlertManager.trigger(alertType, cameraType)
    │
    ├── APPROACHING (800m): vibrate ∙∙ (2x 100ms, 200ms gap)
    ├── CLOSE (400m):       vibrate ——— (1x 500ms)
    │
    ▼
[Camera passed → cooldown → back to GPS loop]
    │
    ▼
ActivityRecognitionReceiver detects STILL (>2 min)
    │
    ▼
Stops LocationTrackingService
    │
    ▼
[Phone idle again]
```

## Android Permissions Required

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS" />
```

## Component Details

### 1. ActivityRecognitionService

Registers for activity transition updates using the Activity Recognition Transition API.

```
Transitions monitored:
  - ENTER IN_VEHICLE  → start LocationTrackingService
  - EXIT  IN_VEHICLE  → schedule delayed stop (2 min)
  - ENTER STILL       → if pending stop, confirm stop
  - ENTER ON_FOOT     → if pending stop, confirm stop
```

The 2-minute delay prevents stopping at traffic lights. If the user is detected as IN_VEHICLE again within 2 minutes, cancel the stop.

Must survive app kill → uses BroadcastReceiver, not just Activity callbacks.

### 2. LocationTrackingService (Foreground Service)

```
Type: FOREGROUND_SERVICE_LOCATION
Notification: low-priority, persistent
  - Title: "BuzzOff"
  - Text: "Monitoring active"
  - No sound, no vibration for the notification itself

Location request config:
  - Priority: PRIORITY_HIGH_ACCURACY
  - Interval: 3000ms (3 seconds)
  - Fastest interval: 1000ms
  - Smallest displacement: 10m

On each location update:
  1. Calculate speed from GPS (location.speed)
  2. Calculate heading from GPS (location.bearing)
  3. If speed > user threshold → call ProximityEngine.check()
  4. If speed < 5 kmh for > 5 min → assume parked, trigger stop
```

### 3. ProximityEngine

The brains of the app. Pure Dart, no Flutter/platform dependencies — fully testable.

```dart
abstract class CameraQueryPort {
  List<Camera> getCamerasInBounds(double minLat, double maxLat, double minLon, double maxLon);
}

class ProximityEngine {
  final CameraQueryPort _cameraQuery;
  final Set<int> _alertedApproaching = {};
  final Set<int> _alertedClose = {};

  static const approachDistance = 800.0;  // meters
  static const closeDistance = 400.0;
  static const headingTolerance = 45.0;   // degrees
  static const cooldownDistance = 200.0;

  ProximityEngine(this._cameraQuery);

  List<AlertEvent> check(double lat, double lon, double heading, double speed) {
    // 1. Query R-tree for cameras within ~2km bounding box
    final nearby = _cameraQuery.getCamerasInBounds(
      lat - 0.018, lat + 0.018, lon - 0.025, lon + 0.025,
    );

    final alerts = <AlertEvent>[];
    for (final camera in nearby) {
      final distance = GeoUtils.haversine(lat, lon, camera.lat, camera.lon);
      final bearing = GeoUtils.bearing(lat, lon, camera.lat, camera.lon);

      // 2. Is camera ahead of us? (within heading cone)
      if (!GeoUtils.isAhead(heading, bearing, headingTolerance)) continue;

      // 3. Check alert thresholds
      if (distance <= closeDistance && !_alertedClose.contains(camera.id)) {
        alerts.add(AlertEvent(camera, AlertLevel.close, distance));
        _alertedClose.add(camera.id);
      } else if (distance <= approachDistance && !_alertedApproaching.contains(camera.id)) {
        alerts.add(AlertEvent(camera, AlertLevel.approaching, distance));
        _alertedApproaching.add(camera.id);
      }

      // 4. Reset if camera is behind us past cooldown
      if (distance > cooldownDistance && _alertedClose.contains(camera.id)) {
        if (!GeoUtils.isAhead(heading, bearing, 90.0)) {
          _alertedClose.remove(camera.id);
          _alertedApproaching.remove(camera.id);
        }
      }
    }
    return alerts;
  }
}
```

### 4. AlertManager

```dart
class VibrationPatterns {
  // Pattern format: [pause, vibrate, pause, vibrate, ...]
  // Alert levels
  static const approaching = [0, 100, 200, 100];        // ∙∙
  static const close       = [0, 500];                   // ———
  static const avgZoneEnter = [0, 100, 150, 100, 150, 100]; // ∙∙∙
  static const avgZoneWarn  = [0, 200];                  // ∙

  // Amplitudes (0-255, -1 for default)
  static const approachingAmp = [0, 180, 0, 180];
  static const closeAmp       = [0, 255];
}
```

AlertManager reads user preferences and dispatches:
- Vibration (always available, uses `vibration` package)
- Sound (optional, uses `audioplayers` package)
- The alert respects Do Not Disturb if user has system DND on — vibration still works

### 5. Boot / App Restart Handling

On Android, a native `BroadcastReceiver` in Kotlin handles `BOOT_COMPLETED` to restart the foreground task. Flutter's `flutter_foreground_task` package provides this via configuration:

```dart
FlutterForegroundTask.init(
  androidNotificationOptions: AndroidNotificationOptions(
    channelId: 'buzzoff_location',
    channelName: 'BuzzOff Location',
    channelImportance: NotificationChannelImportance.LOW,
  ),
  iosNotificationOptions: const IOSNotificationOptions(),
  foregroundTaskOptions: const ForegroundTaskOptions(
    autoRunOnBoot: true,  // re-register after reboot
    allowWakeLock: true,
  ),
);
```

On iOS (post-launch), background location updates are handled via `CLLocationManager` significant-change monitoring, which the OS restarts automatically after reboot.

### 6. Main UI (Flutter)

The app has two screens: **Map** (main) and **Settings**.

#### Map Screen (default)

A live map centered on the user's current position. NOT a navigation app — no routes, no directions. Think of it as a radar view.

```
┌─────────────────────────────────┐
│ [map fills entire screen]       │
│                                 │
│         ○  (camera dot)         │
│                                 │
│              ●                  │
│           (you are here)        │
│                                 │
│     ○          ○                │
│                                 │
│                          [+][-] │
│                          [⚙]   │
└─────────────────────────────────┘
```

- Map centered on user's GPS position, follows movement in real-time
- Camera markers as colored dots (blue=speed, red=red light, amber=avg speed)
- Zoom in/out controls
- Small settings gear button to access settings
- Status bar at top or bottom showing: "Active" / "Waiting for driving..."
- Uses OpenStreetMap tiles (free, no API key)

#### Settings Screen

```
┌─────────────────────────────────┐
│ ← Settings                      │
│─────────────────────────────────│
│                                 │
│ Alert Distance                  │
│ ○ 500m  ● 800m  ○ 1200m        │
│                                 │
│ Alert Type                      │
│ ☑ Vibration                     │
│ ☐ Sound                         │
│                                 │
│ Activate at speed               │
│ ○ 30 kmh  ● 40 kmh  ○ 50 kmh   │
│                                 │
│ Camera types                    │
│ ☑ Speed cameras                 │
│ ☑ Red light cameras             │
│ ☑ Average speed zones           │
│                                 │
│ Cameras loaded: 187             │
│                                 │
└─────────────────────────────────┘
```

## Project Structure (Flutter)

```
app/
├── pubspec.yaml
├── analysis_options.yaml
│
├── assets/
│   └── test_cameras.db              # bundled test dataset (~10 cameras)
│
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # permissions, foreground service, boot receiver
│
├── ios/                             # iOS support (post-launch)
│
├── lib/
│   ├── main.dart                    # entry point, ProviderScope
│   ├── app.dart                     # MaterialApp.router, theme, routing
│   │
│   ├── core/                        # Pure Dart — zero platform dependency, fully testable
│   │   ├── geo/
│   │   │   ├── geo_utils.dart       # haversine, bearing, isAhead
│   │   │   └── bounding_box.dart    # lat/lon offset calculations
│   │   ├── proximity/
│   │   │   ├── proximity_engine.dart # check(lat, lon, heading, speed) → alerts
│   │   │   ├── heading_filter.dart  # heading cone logic
│   │   │   └── alert_event.dart     # AlertEvent, AlertLevel enum
│   │   └── model/
│   │       ├── camera.dart          # Camera data class
│   │       └── app_settings.dart    # Settings value object
│   │
│   ├── data/
│   │   ├── database/
│   │   │   ├── camera_database.dart # Drift database definition
│   │   │   ├── camera_dao.dart      # DAO with R-tree spatial queries
│   │   │   └── pack_loader.dart     # open .db from assets or downloads
│   │   └── preferences/
│   │       └── user_preferences.dart # SharedPreferences wrapper
│   │
│   ├── services/
│   │   ├── location_service.dart    # geolocator wrapper, GPS stream
│   │   ├── activity_service.dart    # activity recognition wrapper
│   │   ├── foreground_task.dart     # flutter_foreground_task handler
│   │   ├── alert_service.dart       # vibration/sound dispatch
│   │   └── orchestrator.dart        # activity → location → proximity → alert
│   │
│   ├── providers/                   # Riverpod state management
│   │   ├── database_provider.dart
│   │   ├── settings_provider.dart
│   │   ├── location_provider.dart
│   │   ├── driving_state_provider.dart
│   │   └── nearby_cameras_provider.dart
│   │
│   ├── ui/
│   │   ├── screens/
│   │   │   ├── map_screen.dart      # flutter_map, centered on user, camera dots
│   │   │   └── settings_screen.dart # alert preferences
│   │   ├── widgets/
│   │   │   ├── camera_marker.dart   # colored dot by camera type
│   │   │   ├── status_bar.dart      # "Active" / "Waiting..."
│   │   │   └── zoom_controls.dart   # +/- buttons, settings gear
│   │   └── theme/
│   │       └── app_theme.dart       # dark theme, RTL-ready
│   │
│   └── util/
│       └── constants.dart           # distances, intervals, thresholds
│
├── test/
│   ├── core/
│   │   ├── proximity_engine_test.dart
│   │   ├── geo_utils_test.dart
│   │   └── heading_filter_test.dart
│   ├── data/
│   │   └── camera_dao_test.dart
│   └── ui/
│       ├── map_screen_test.dart
│       └── settings_screen_test.dart
│
└── integration_test/
    └── driving_loop_test.dart
```

## Battery Optimization Details

### Power states

| State | GPS | Activity Recog | CPU | Battery/hr |
|-------|-----|---------------|-----|------------|
| Idle  | OFF | passive (system-managed) | sleep | ~0.1% |
| Driving | ON (3s interval) | passive | partial wake | ~3-5% |
| Transition | ON (reduced, 10s) | active check | partial wake | ~1-2% |

### OEM battery killer mitigation

Many OEMs (Xiaomi, Samsung, Huawei, Oppo) aggressively kill background services.

Mitigations:
1. Request `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` (whitelist prompt)
2. Foreground service with notification (cannot be killed)
3. Boot receiver to restart after reboot
4. Guide user to device-specific settings on first launch (link to dontkillmyapp.com instructions per device)

## Test Dataset

Bundle a small test SQLite in `assets/test_cameras.db` with ~10 cameras:
- 5 near a location you can physically test (your city)
- 2 red light cameras
- 1 average speed zone pair
- 2 cameras with different headings

This allows real-world testing without the full data pipeline.

## Acceptance Criteria

- [ ] Activity Recognition detects IN_VEHICLE and starts GPS tracking
- [ ] Activity Recognition detects STILL/ON_FOOT and stops GPS (with 2-min delay)
- [ ] Foreground service runs with persistent notification
- [ ] GPS updates arrive every 3-5 seconds while driving
- [ ] ProximityEngine correctly identifies cameras within alert distance
- [ ] ProximityEngine filters cameras by heading (only ahead)
- [ ] ProximityEngine debounces (no double-alert for same camera)
- [ ] Vibration triggers at 800m (approaching) and 400m (close)
- [ ] App survives phone reboot (BootReceiver restarts recognition)
- [ ] App survives being backgrounded / swiped from recents
- [ ] Battery drain < 5% per hour while driving
- [ ] Settings persist across app restarts
- [ ] Unit tests pass for ProximityEngine, GeoUtils, HeadingFilter
