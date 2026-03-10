# Phase 2: Android Core Engine

## Goal

Build the core driving detection and proximity alert engine. This phase uses a hardcoded test dataset (a small SQLite file with a few cameras) to validate the full loop: detect driving → GPS tracking → proximity check → vibration alert. No network, no pack downloads — just the engine.

## Deliverables

1. Activity Recognition (detect driving)
2. Foreground location service (GPS tracking while driving)
3. Proximity engine (spatial queries against camera DB)
4. Alert manager (vibration patterns)
5. Boot receiver (survive reboots)
6. Minimal settings UI (one screen)
7. Test dataset bundled in assets

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

The brains of the app. Pure Kotlin, no Android dependencies — fully testable.

```kotlin
class ProximityEngine(private val cameraDao: CameraDao) {

    private val alertedCameras = mutableSetOf<String>() // IDs already alerted
    private val APPROACH_DISTANCE = 800.0  // meters
    private val CLOSE_DISTANCE = 400.0     // meters
    private val HEADING_TOLERANCE = 45.0   // degrees
    private val COOLDOWN_DISTANCE = 200.0  // meters past camera, reset

    fun check(lat: Double, lon: Double, heading: Float, speed: Float): List<AlertEvent> {
        // 1. Query R-tree for cameras within 2km bounding box
        val nearby = cameraDao.getCamerasInBounds(
            minLat = lat - 0.018,  // ~2km
            maxLat = lat + 0.018,
            minLon = lon - 0.025,
            maxLon = lon + 0.025
        )

        // 2. For each camera, calculate exact distance and bearing
        val alerts = mutableListOf<AlertEvent>()
        for (camera in nearby) {
            val distance = haversine(lat, lon, camera.lat, camera.lon)
            val bearing = bearing(lat, lon, camera.lat, camera.lon)

            // 3. Is camera ahead of us? (within heading cone)
            if (!isAhead(heading, bearing, HEADING_TOLERANCE)) continue

            // 4. Check alert thresholds
            val cameraKey = camera.id
            when {
                distance <= CLOSE_DISTANCE && cameraKey !in alertedCameras -> {
                    alerts.add(AlertEvent(camera, AlertLevel.CLOSE, distance))
                    alertedCameras.add(cameraKey)
                }
                distance <= APPROACH_DISTANCE && cameraKey !in alertedCameras -> {
                    alerts.add(AlertEvent(camera, AlertLevel.APPROACHING, distance))
                    // don't add to alertedCameras yet — will alert again at CLOSE
                }
            }

            // 5. Reset if we've passed the camera
            if (distance > COOLDOWN_DISTANCE && cameraKey in alertedCameras) {
                // Check if camera is now behind us
                if (!isAhead(heading, bearing, 90.0)) {
                    alertedCameras.remove(cameraKey)
                }
            }
        }
        return alerts
    }
}
```

### 4. AlertManager

```kotlin
object VibrationPatterns {
    // Alert levels
    val APPROACHING = longArrayOf(0, 100, 200, 100)       // ∙∙
    val CLOSE       = longArrayOf(0, 500)                  // ———
    val AVG_ZONE_ENTER = longArrayOf(0, 100, 150, 100, 150, 100) // ∙∙∙
    val AVG_ZONE_WARN  = longArrayOf(0, 200)               // ∙

    // Amplitudes (0-255, -1 for default)
    val APPROACHING_AMP = intArrayOf(0, 180, 0, 180)
    val CLOSE_AMP       = intArrayOf(0, 255)
}
```

AlertManager reads user preferences and dispatches:
- Vibration (always available)
- Sound (optional, uses AudioManager with STREAM_NOTIFICATION)
- The alert respects Do Not Disturb if user has system DND on — vibration still works

### 5. BootReceiver

```kotlin
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            // Re-register activity recognition
            ActivityRecognitionService.register(context)
        }
    }
}
```

### 6. Settings UI (Single Screen - Jetpack Compose)

```
┌─────────────────────────────────┐
│ BuzzOff            [active]  │
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
│ Status: Waiting for driving...  │
│ Cameras loaded: 187             │
│                                 │
└─────────────────────────────────┘
```

## Project Structure (Android)

```
android/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/buzzoff/
│   │   │   │   ├── BuzzOffApp.kt           # Application class, Hilt
│   │   │   │   │
│   │   │   │   ├── core/                       # pure logic, no Android
│   │   │   │   │   ├── proximity/
│   │   │   │   │   │   ├── ProximityEngine.kt
│   │   │   │   │   │   └── HeadingFilter.kt
│   │   │   │   │   ├── geo/
│   │   │   │   │   │   └── GeoUtils.kt         # haversine, bearing
│   │   │   │   │   └── model/
│   │   │   │   │       ├── Camera.kt
│   │   │   │   │       ├── AlertEvent.kt
│   │   │   │   │       └── AlertLevel.kt
│   │   │   │   │
│   │   │   │   ├── data/
│   │   │   │   │   ├── local/
│   │   │   │   │   │   ├── CameraDatabase.kt   # Room DB
│   │   │   │   │   │   ├── CameraDao.kt        # spatial queries
│   │   │   │   │   │   └── CameraEntity.kt
│   │   │   │   │   └── prefs/
│   │   │   │   │       └── UserPreferences.kt   # DataStore
│   │   │   │   │
│   │   │   │   ├── service/
│   │   │   │   │   ├── ActivityRecognitionService.kt
│   │   │   │   │   ├── LocationTrackingService.kt
│   │   │   │   │   └── BuzzOffOrchestrator.kt
│   │   │   │   │
│   │   │   │   ├── alert/
│   │   │   │   │   ├── AlertManager.kt
│   │   │   │   │   └── VibrationPatterns.kt
│   │   │   │   │
│   │   │   │   ├── receiver/
│   │   │   │   │   ├── BootReceiver.kt
│   │   │   │   │   └── ActivityTransitionReceiver.kt
│   │   │   │   │
│   │   │   │   ├── ui/
│   │   │   │   │   ├── MainActivity.kt
│   │   │   │   │   ├── screens/
│   │   │   │   │   │   └── SettingsScreen.kt
│   │   │   │   │   └── theme/
│   │   │   │   │       └── Theme.kt             # RTL-ready
│   │   │   │   │
│   │   │   │   └── di/
│   │   │   │       ├── AppModule.kt
│   │   │   │       └── DatabaseModule.kt
│   │   │   │
│   │   │   ├── res/
│   │   │   │   ├── values/
│   │   │   │   │   └── strings.xml              # English
│   │   │   │   └── xml/
│   │   │   │       └── backup_rules.xml
│   │   │   │
│   │   │   ├── assets/
│   │   │   │   └── test_cameras.db              # small test dataset
│   │   │   │
│   │   │   └── AndroidManifest.xml
│   │   │
│   │   └── test/                                # unit tests
│   │       └── java/com/buzzoff/
│   │           ├── core/
│   │           │   ├── ProximityEngineTest.kt
│   │           │   └── GeoUtilsTest.kt
│   │           └── alert/
│   │               └── AlertManagerTest.kt
│   │
│   └── build.gradle.kts
│
├── build.gradle.kts                             # project-level
├── settings.gradle.kts
└── gradle.properties
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
