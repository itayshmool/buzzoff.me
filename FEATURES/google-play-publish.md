# Feature: Publish BuzzOff to Google Play

## Status: IN PROGRESS

## Overview
Publish the BuzzOff Android app to Google Play Store. Covers all technical and content requirements for a production release.

## Checklist

### Phase 1: Blockers (do first)
- [x] **Developer account verification** — Complete identity verification in Play Console (#8) ✅ DONE 2026-03-12
- [x] **Upload keystore** — Generate signing key and configure `key.properties` (#1) ✅ DONE 2026-03-12
- [x] **Privacy policy** — Create and publish `buzzoff.me/privacy` (#2) ✅ DONE 2026-03-12

### Phase 2: Play Console Declarations
- [x] **App access** — "All functionality available without special access" (#3) ✅ DONE 2026-03-12
- [x] **Ads** — "No ads" (#3) ✅ DONE 2026-03-12
- [x] **Content rating** — IARC questionnaire, rated 3+ (#3) ✅ DONE 2026-03-12
- [x] **Target audience** — 18+ (driving app) (#3) ✅ DONE 2026-03-12
- [x] **Government apps** — No (#3) ✅ DONE 2026-03-12
- [x] **Financial features** — No (#3) ✅ DONE 2026-03-12
- [x] **Health** — No (#3) ✅ DONE 2026-03-12
- [x] **Data safety** — Location only, on-device, no sharing (#4) ✅ DONE 2026-03-12
- [x] **App category** — Maps & Navigation (#5) ✅ DONE 2026-03-12
- [x] **Contact details** — Email + website URL (#5) ✅ DONE 2026-03-12

### Phase 3: Store Listing Assets
- [x] **App icon** — 512x512 PNG (Racing Lens design) (#6) ✅ DONE 2026-03-12
- [x] **Feature graphic** — 1024x500 PNG banner (#9) ✅ DONE 2026-03-12
- [x] **Phone screenshots** — Min 4 screenshots (#10) ✅ DONE 2026-03-12
- [x] **App name** — "BuzzOff - Speed Camera Alerts" (#6) ✅ DONE 2026-03-12
- [x] **Short description** — 80 chars (#6) ✅ DONE 2026-03-12
- [x] **Full description** — Full marketing copy (#6) ✅ DONE 2026-03-12

### Phase 4: Build & Release
- [ ] **Build signed AAB** — `flutter build appbundle --release` (#7)
- [ ] **Upload to Play Console** — Production or closed testing (#7)
- [ ] **Release notes** — First release changelog (#7)
- [ ] **Submit for review** (#7)

### Phase 5: Post-Launch
- [ ] **Update website** — Change APK link to Play Store URL (#11)

---

## Detailed Specs

### App Identity
| Field | Value |
|-------|-------|
| Package name | `me.buzzoff.app` |
| App name | BuzzOff - Speed Camera Alerts |
| Category | Maps & Navigation |
| Content rating | Everyone |
| Target audience | 18+ |
| Price | Free |
| Ads | None |

### Short Description (80 chars)
```
Silent speed camera alerts. Offline. Background mode. Never get flashed again.
```

### Full Description
```
BuzzOff alerts you to speed cameras before you reach them. Silent vibration warnings keep you informed without distracting sounds.

HOW IT WORKS
1. Pick your country and download the camera pack
2. Start driving — BuzzOff auto-detects when you're on the road
3. Get silent haptic alerts as you approach speed cameras

KEY FEATURES
• Speed camera detection — fixed, mobile, red light, and average speed cameras
• Silent vibration alerts — no distracting sounds needed
• Works in background — use with Waze, Spotify, or any other app
• 100% offline — all camera data stored locally, zero data usage while driving
• Auto-detection — monitoring starts automatically at driving speed
• Manual control — power button to force-start or stop monitoring
• Multiple countries — Israel, UK, and more
• Lightweight packs — under 5MB per country
• Configurable — adjust alert distance, vibration intensity, minimum speed

PRIVACY FIRST
• No account required
• No ads
• No tracking or analytics
• Location data stays on your device
• Camera data downloaded once, used offline

Free. No account. No ads. Just drive safe.
```

### Data Safety Declaration
| Data type | Collected | Shared | Purpose |
|-----------|-----------|--------|---------|
| Approximate location | Yes | No | Camera proximity alerts |
| Precise location | Yes | No | Camera proximity alerts |
| All other data types | No | No | — |

- Data processed on-device only
- Not used for advertising
- Not transferred off device
- No third-party data sharing

### Required Assets
| Asset | Size | Status | Path |
|-------|------|--------|------|
| App icon | 512x512 PNG | DONE | `app/assets/icon/play-store-512.png` |
| Feature graphic | 1024x500 PNG | DONE | `app/assets/store/feature-graphic.png` |
| Screenshot 1 — Map Alert | 1080x1920 | DONE | `app/assets/store/screenshot-1-alert.png` |
| Screenshot 2 — Map Idle | 1080x1920 | DONE | `app/assets/store/screenshot-2-idle.png` |
| Screenshot 3 — Settings | 1080x1920 | DONE | `app/assets/store/screenshot-3-settings.png` |
| Screenshot 4 — Country Picker | 1080x1920 | DONE | `app/assets/store/screenshot-4-countries.png` |

### Release Notes (v1.0.0)
```
Initial release of BuzzOff — Speed Camera Alerts

• Speed camera alerts with silent vibration warnings
• Works offline with downloadable camera packs
• Background mode — use with any navigation app
• Auto-detects driving speed
• Manual on/off power button
• Map with camera markers and follow mode
• Multiple countries supported
```

### Privacy Policy URL
```
https://buzzoff.me/privacy
```

### Signing Config
- Keystore: `upload-keystore.jks` (NOT in git)
- Key alias: `upload`
- Config file: `app/android/key.properties` (NOT in git)
- Adaptive icon background: `#1a1a1a`

---

## Progress Log

| Date | Item | Status |
|------|------|--------|
| 2026-03-12 | App icon 512x512 | DONE |
| 2026-03-12 | Feature spec created | DONE |
| 2026-03-12 | Privacy policy page | DONE |
| 2026-03-12 | Feature graphic | DONE |
| 2026-03-12 | Phone screenshots (4x) | DONE |
| | Upload keystore | TODO |
| | Play Console declarations | TODO |
| | Store listing | TODO |
| | Build signed AAB | TODO |
| | Submit for review | TODO |
