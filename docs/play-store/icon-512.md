# App icon 512×512 — BuzzOff

Google Play requires a **512×512 px PNG** (32-bit, no transparency for the store icon).

## Option 1: From existing asset

The app already has a high-res icon:

- **Path:** `app/assets/icon/buzzoff_icon.png`

If that file is at least 512×512, resize or export it to exactly **512×512** in an image editor (e.g. Figma, Photoshop, GIMP, or an online resizer). Save as PNG.

## Option 2: From SVG

If you have a vector version:

- **Path:** `app/assets/icon/buzzoff_icon.svg`

Open in a vector tool or browser, set artboard/canvas to 512×512, export as PNG at 512×512.

## Option 3: Flutter launcher icons

The project uses `flutter_launcher_icons`. The generated Android icons are under:

- `app/android/app/src/main/res/mipmap-*/ic_launcher.png`

The **xxxhdpi** asset is 192×192. For Play you need 512×512, so either:

- Export the SVG at 512×512, or  
- Upscale the largest mipmap (e.g. 192→512) and sharpen, or  
- Use the same source image as in `pubspec.yaml` (`assets/icon/buzzoff_icon.png`) and resize to 512×512.

## Upload

In Play Console → **Store presence** → **Main store listing** → **App icon**, upload the 512×512 PNG.
