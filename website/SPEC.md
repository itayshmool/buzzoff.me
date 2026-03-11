# BuzzOff Landing Page — Website Spec

## Overview
Single-page mobile-first landing site at **buzzoff.me** (root domain).
Goal: Drive app downloads (App Store + Google Play).
Theme: **Mario Kart inspired** — racing game UI, retro-pixel typography, checkered flags, power-up items, dark asphalt backgrounds, neon speed accents.

## Tech
- Pure HTML + CSS + vanilla JS, single `index.html` file
- Mobile-first responsive (breakpoints: 480, 768, 1024, 1200)
- Smooth scroll navigation
- CSS-only animations (no libraries)
- App icon at `../app/assets/icon/buzzoff_icon.png`

## Fonts
- **Headings**: `Press Start 2P` (Google Fonts) — pixel/retro arcade feel
- **Body**: `Outfit` (Google Fonts) — clean modern contrast

## Color Palette
- Background: `#1a1a2e` (dark asphalt navy)
- Primary accent: `#ff4757` (Mario red)
- Secondary: `#ffa502` (coin gold/yellow)
- Tertiary: `#2ed573` (green shell / go)
- Blue accent: `#3742fa` (blue shell)
- Text: `#f1f2f6` (white-ish)
- Muted text: `#a4a4b8`
- Card bg: `#252540`

## Sections

### 1. Sticky Nav
- Transparent, blurs on scroll
- Left: BuzzOff icon + name
- Right: section links (How It Works, Features, Download)
- Mobile: hamburger menu
- Bottom border: checkered flag pattern (thin, repeating black/white squares via CSS)

### 2. Hero
- Full viewport height
- Animated diagonal racing stripes in background (red/dark, subtle CSS animation)
- Checkered flag corner accents
- Headline: **"Never Get Flashed Again"** (Press Start 2P, large)
- Subtitle: "Speed camera alerts that ride with you. Silent. Offline. Always watching the road ahead."
- App icon (80px, rounded, glowing red shadow)
- Two CTA buttons styled as **boost pads** (bright colored, angled/skewed slightly, hover glow effect):
  - 🍎 App Store (red)
  - ▶️ Google Play (green)
- Floating animated elements: small pixel stars, speed lines on sides

### 3. How It Works — "Race Stages"
- Section title: "START YOUR ENGINE" with checkered flag emoji
- 3 steps displayed as **race track checkpoints/laps**:
  - **LAP 1** — 🏁 Pick Your Country (flag grid, choose your track)
  - **LAP 2** — 📦 Download Camera Pack (offline item box, grab your power-ups)
  - **LAP 3** — 🚗 Drive Safe (alerts activate automatically at speed)
- Each step: numbered circle (styled as track position marker: 1st, 2nd, 3rd), icon, title, description
- Connected by a dashed road/track line (animated dash-offset)
- Mobile: vertical stack; Desktop: horizontal row

### 4. Features — "Power-Ups"
- Section title: "POWER-UPS"
- Grid of feature cards (2 cols mobile, 3 cols desktop)
- Each card styled as a **Mario Kart item box** (rotating ? block border, or colored box with icon):
  - 📡 **Speed Camera Alerts** — "Detects fixed, mobile, and average speed cameras ahead"
  - 📳 **Vibration Warning** — "Silent haptic alerts. No distracting sounds needed"
  - 🔋 **Background Mode** — "Runs silently while you use Waze or Spotify"
  - 📴 **Offline Packs** — "All camera data stored locally. No internet needed while driving"
  - 🌍 **Multiple Countries** — "Israel, UK, and more. Pick your track"
  - 💤 **Smart Sleep** — "Configurable auto-sleep. Knows when you're at a red light"
- Cards have colored left borders (cycling through red/gold/green/blue) and hover lift effect

### 5. App Screenshots — "Race Replay"
- Section title: "RACE REPLAY"
- Horizontal scrollable carousel (mobile) / centered row (desktop)
- 5 phone mockups with dark frames:
  1. Country Picker — flag grid
  2. Download Pack — progress bar with camera count
  3. Map Alert — live map with red alert notification
  4. Map Idle — grey "waiting for driving" state
  5. Settings — configurable options
- Each frame has a small label below: "STAGE 1", "STAGE 2", etc.
- Phone frames have subtle racing stripe accents
- Implementation: CSS-drawn phone frames with embedded screenshots (describe what's shown, use colored placeholder blocks with text labels — actual screenshots can be added later)

### 6. Stats — "Leaderboard"
- Section title: "LEADERBOARD"
- Styled as a racing game results screen / time trial leaderboard
- Dark card with gold border, retro font
- Stats displayed as "records":
  - 🏆 184+ cameras mapped in Israel
  - 🗺️ 5 countries supported
  - ⚡ < 1 second alert time
  - 🔇 100% silent operation
  - 📦 < 5MB per country pack
- Each stat: large number (gold, Press Start 2P), label below

### 7. Final CTA
- Dark section with large "READY TO RACE?" headline
- Repeat the two download buttons (boost pad style)
- Small text: "Free. No account needed. No ads."

### 8. Footer
- Minimal, dark
- "© 2026 BuzzOff" centered
- Links: Privacy Policy | Terms | Contact
- Small: "Made with 🏎️ in Tel Aviv"

## Animations
- Hero racing stripes: infinite diagonal scroll (CSS keyframes)
- Track line between How It Works steps: animated dash-offset on scroll
- Feature cards: staggered fade-in on scroll (IntersectionObserver)
- Stats numbers: count-up animation on scroll into view
- Floating pixel stars in hero: gentle float/twinkle (CSS only)
- CTA buttons: pulse glow on hover

## Deployment
- Static site on Render or served from root domain
- Single HTML file, no build step
- All assets relative paths or CDN (Google Fonts, no other deps)
