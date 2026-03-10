# Phase 5: Multi-Country + Auto-Detection

## Goal

Enable the platform to serve multiple countries simultaneously. Implement GPS-based country auto-detection, seamless country switching while driving (border crossing), and onboard a second country (Germany) to validate the multi-country architecture.

## Depends On

- Phase 3 (pack system in app)
- Phase 4 (admin portal for managing countries)

## Deliverables

1. Germany onboarded as second country via admin portal
2. GPS-based country auto-detection in app
3. Border-crossing auto-switch
4. Multi-pack management (install multiple countries)
5. Country download prompts
6. Cached country metadata (offline country detection)

## Germany Onboarding Plan

Validate the "add a country with zero code changes" promise by onboarding Germany entirely through the admin portal.

### Steps (all via admin UI)

1. Create country: DE, "Germany", speed_unit=kmh
2. Add source: OSM Overpass
   ```json
   {
     "adapter": "osm_overpass",
     "config": {
       "query": "[out:json][timeout:120];area['name'='Deutschland']->.a;(node['highway'='speed_camera'](area.a););out geom;",
       "type_mapping": {
         "maxspeed": "fixed_speed",
         "traffic_signals": "red_light",
         "average_speed": "avg_speed_start"
       }
     }
   }
   ```
3. Add source: SCDB.info (if license allows, or manual CSV import)
4. Trigger fetch → review results on map
5. Run merge/dedup
6. Generate pack → publish
7. Test: download pack in app, verify alerts work

Expected camera count for Germany: ~4,000+ from OSM (Germany has excellent OSM coverage).

## Auto-Detection Logic

### Bounding Box Approach

Each country pack includes its bounding box in the meta table. The app caches bounding boxes of all available countries (fetched once from API, refreshed weekly).

```
Country bounding boxes (simplified):
  IL: 29.45°N – 33.33°N, 34.27°E – 35.90°E
  DE: 47.27°N – 55.06°N,  5.87°E – 15.04°E
```

### Detection algorithm

```
on_location_update(lat, lon):
    active = get_active_country()

    # Fast path: still in active country
    if active and point_in_bounds(lat, lon, active.bounds):
        return  # no change

    # Check installed packs
    for pack in installed_packs:
        if pack != active and point_in_bounds(lat, lon, pack.bounds):
            switch_to(pack.country_code)
            notify_user("Switched to {pack.country_name}")
            return

    # Check available (not installed) countries
    for country in cached_available_countries:
        if country.code not in installed and point_in_bounds(lat, lon, country.bounds):
            prompt_download(country)
            return

    # No data for this location
    enter_dormant_mode()
```

### Edge cases

**Overlapping bounding boxes** (e.g., small countries near each other):
- Bounding boxes are rectangles, they overlap at corners
- If multiple matches: prefer the installed pack, then prefer the smaller country (more specific)
- In practice, for Israel and Germany this isn't an issue

**Border regions**:
- GPS signal jitters near borders
- Add 500m hysteresis: don't switch unless clearly 500m+ inside new country bounds
- If user has both packs installed, cameras from both countries work (both packs loaded into R-tree)

**Airplane mode / GPS unavailable**:
- Keep last known country active
- Don't switch without GPS confirmation

## Multi-Pack Loading

When driving near a border, load cameras from both countries:

```kotlin
class MultiPackProximityEngine(
    private val packManager: PackManager
) {
    fun check(lat: Double, lon: Double, heading: Float, speed: Float): List<AlertEvent> {
        val nearbyPacks = packManager.getPacksNearLocation(lat, lon, radiusKm = 10.0)

        val allAlerts = mutableListOf<AlertEvent>()
        for (pack in nearbyPacks) {
            val dao = packManager.getDaoForPack(pack)
            val engine = ProximityEngine(dao)
            allAlerts.addAll(engine.check(lat, lon, heading, speed))
        }

        return allAlerts
    }
}
```

## Updated App Settings

```
┌─────────────────────────────────┐
│ BuzzOff            [active]  │
│─────────────────────────────────│
│                                 │
│ Countries                       │
│ ┌─────────────────────────┐     │
│ │ 🇮🇱 Israel     v4  ✓ active│   │
│ │    187 cameras  45 KB   │     │
│ └─────────────────────────┘     │
│ ┌─────────────────────────┐     │
│ │ 🇩🇪 Germany    v1       │     │
│ │    4,102 cameras  380 KB│     │
│ └─────────────────────────┘     │
│                                 │
│ [+ Download more countries]     │
│                                 │
│ Auto-detect country             │
│ ● On (switch by GPS)            │
│ ○ Off (manual only)             │
│                                 │
│ ── Alert Settings ──            │
│ (same as before)                │
│                                 │
└─────────────────────────────────┘
```

## Acceptance Criteria

- [ ] Germany onboarded entirely through admin portal (no code changes)
- [ ] Germany pack generated with 2,000+ cameras from OSM
- [ ] App can have multiple country packs installed simultaneously
- [ ] Auto-detection correctly identifies country from GPS position
- [ ] Auto-switch works when crossing from one installed country to another
- [ ] Download prompt appears when entering a country with available but not installed pack
- [ ] 500m hysteresis prevents border jitter
- [ ] Near-border driving loads cameras from both countries
- [ ] User can disable auto-detection and select country manually
- [ ] Country metadata cached locally for offline country detection
- [ ] App works offline after all desired packs are downloaded
