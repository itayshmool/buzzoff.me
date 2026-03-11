# Publishing BuzzOff to Google Play

This guide walks you through publishing the BuzzOff Android app to the Google Play Store.

## Prerequisites

- **Google Play Developer account** — [Register](https://play.google.com/console/signup) (one-time $25 fee).
- **Flutter & Android SDK** — You already have these if you can run `flutter build appbundle`.
- **App content** — Store listing text, screenshots, privacy policy URL, and (optionally) a feature graphic.

---

## 1. Create an upload keystore (one-time)

You need a keystore to sign release builds. **Keep the keystore and passwords safe; you cannot publish updates without them.**

From the repo root:

```bash
cd app/android
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- Use a strong **store password** and **key password** (you’ll need both again).
- Fill in name/organization as you want (they can be generic).
- **Do not commit** `upload-keystore.jks` or share it. It’s in `.gitignore`.

---

## 2. Configure signing in the project

Copy the example key properties and edit with your values:

```bash
cd app/android
cp key.properties.example key.properties
```

Edit `key.properties` (paths relative to the `android/` directory):

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=upload-keystore.jks
```

If the keystore is in another folder, use a path relative to `android/`, e.g. `storeFile=../keys/upload-keystore.jks`.

**Do not commit** `key.properties`; it’s in `.gitignore`.

---

## 3. Bump version (optional)

In `app/pubspec.yaml`:

- **version:** e.g. `1.0.0+1` → `1.0.0+2` for the next release.  
  Format is `name+build`; the part after `+` is the Android `versionCode` and must increase for each Play Store upload.

---

## 4. Build the release App Bundle (AAB)

Google Play requires an **Android App Bundle** (`.aab`), not an APK.

From the **app** directory:

```bash
cd app
flutter build appbundle --release
```

Optional (recommended for production):

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
```

Output:

`build/app/outputs/bundle/release/app-release.aab`

---

## 5. Create the app in Play Console

1. Go to [Google Play Console](https://play.google.com/console).
2. **Create app** → enter **BuzzOff** (or your chosen name), set default language, choose app or game, and confirm declarations.
3. Complete **Dashboard** tasks:
   - **App access** — If the app or any part of it is restricted, provide access (e.g. test credentials or “No login”).
   - **Ads** — Declare if the app contains ads (BuzzOff does not).
   - **Content rating** — Complete the questionnaire (e.g. utility, no sensitive content).
   - **Target audience** — Set age groups.
   - **News app** — Declare if it’s a news app (No).
   - **COVID-19 contact tracing / status** — Answer as applicable.
   - **Data safety** — Declare what data you collect (e.g. location, approximate location). Be accurate; the app uses location and activity recognition.
   - **Government apps** — Answer as applicable.

---

## 6. Store listing

In **Grow** → **Store presence** → **Main store listing**:

- **Short description** (max 80 chars) and **Full description** (max 4000 chars) — **`play-store-materials/store-listing.txt`**.
- **App icon** — 512×512 PNG. **`play-store-materials/icon-512.md`**.
- **Feature graphic** — 1024×500. Open **`play-store-materials/feature-graphic.html`** in a browser, resize to 1024×500, screenshot, upload.
- **Screenshots** — At least 2 (phone). **`play-store-materials/screenshots-guide.md`**; [Play specs](https://support.google.com/googleplay/android-developer/answer/9866151).
- **Privacy policy** — **Required**. Host **`play-store-materials/privacy-policy.html`** at `https://buzzoff.me/privacy` and paste that URL in the listing.

All of the above files are in the **`play-store-materials/`** folder at the repo root.

---

## 7. Upload the AAB and release

1. In Play Console go to **Release** → **Production** (or **Testing** → **Internal testing** to try first).
2. **Create new release**.
3. **Upload** `app-release.aab` from `app/build/app/outputs/bundle/release/`.
4. Add **Release name** (e.g. `1.0.0 (1)`) and **Release notes**.
5. **Review release** → **Start rollout to Production** (or save for Internal testing).

---

## 8. After the first upload (Play App Signing)

- When you upload the first AAB, Google will ask you to enroll in **Play App Signing**.
- Choose **Continue** and use the **upload key** you created above. Google will hold the **app signing key**; you keep the upload keystore for all future updates.
- If you already have an app signing key from Google, follow the prompts to use your existing upload key.

---

## Checklist (first release)

- [ ] Google Play Developer account created
- [ ] Upload keystore created and stored safely
- [ ] `app/android/key.properties` configured (not committed)
- [ ] Version in `pubspec.yaml` set (e.g. `1.0.0+1`)
- [ ] Privacy policy URL live and linked in Store listing
- [ ] Store listing: short + full description, icon, screenshots
- [ ] Content rating, target audience, Data safety, and other Dashboard tasks completed
- [ ] AAB built: `flutter build appbundle --release`
- [ ] AAB uploaded to a release (Internal testing or Production)
- [ ] Play App Signing enrollment completed with your upload key

---

## Troubleshooting

- **“Android resource linking failed”** — Ensure all drawables and resources referenced in `android/app/src/main/res` exist (e.g. `launch_background.xml`).
- **“Upload key not accepted”** — Confirm the first AAB you upload is signed with the same upload keystore you register with Play App Signing.
- **Rejected for permissions** — In **Data safety**, declare location and any other permissions the app uses; in **Policy** → **App content**, complete any declarations related to location or background usage.

For official details: [Publish your app (Play Console)](https://support.google.com/googleplay/android-developer/answer/9859152) and [Flutter: Build and release an Android app](https://docs.flutter.dev/deployment/android).
