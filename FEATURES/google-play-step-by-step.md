# Google Play Publishing — Step by Step Guide

> Follow these steps in order. Each step tells you exactly what to click, what to type, and where.

---

## STEP 1: Verify Your Developer Account

**Where:** [Play Console → Account Details](https://play.google.com/console/developers/account)

1. Open the link above
2. If you see a banner asking for **identity verification**, click it
3. Upload a government-issued ID (Israeli Teudat Zehut works)
4. Fill in your legal name and address
5. Submit and wait for approval (usually 1–3 business days)

> ⚠️ **This is the #1 blocker.** You cannot publish until verification is complete. Start this NOW and continue with the other steps while waiting.

---

## STEP 2: Create the App in Play Console

**Where:** [Play Console → Create App](https://play.google.com/console/developers/app/create)

Fill in:
| Field | Value |
|-------|-------|
| App name | `BuzzOff - Speed Camera Alerts` |
| Default language | English (United States) |
| App or game | App |
| Free or paid | Free |

Check both declaration boxes and click **Create app**.

---

## STEP 3: Set Up App Signing & Generate Upload Keystore

**On your Mac terminal, run these commands:**

```bash
cd /Users/itays/dev/buzzoff.me/app/android

# Generate the upload keystore
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 \
  -validity 10000 \
  -alias upload
```

It will ask you for:
- **Keystore password** — choose a strong password, write it down somewhere safe
- **Key password** — use the same password
- **First and last name** — your name
- **Organization** — BuzzOff
- **City/State/Country** — Tel Aviv / Israel / IL

Then create the key.properties file:

```bash
cat > /Users/itays/dev/buzzoff.me/app/android/key.properties << 'EOF'
storePassword=YOUR_PASSWORD_HERE
keyPassword=YOUR_PASSWORD_HERE
keyAlias=upload
storeFile=../android/upload-keystore.jks
EOF
```

Replace `YOUR_PASSWORD_HERE` with the password you chose.

> ⚠️ **NEVER commit `upload-keystore.jks` or `key.properties` to git.** Back them up somewhere safe (Google Drive, 1Password, etc). If you lose the keystore, you lose the ability to update your app.

---

## STEP 4: Store Listing — Main Details

**Where:** Play Console → Your app → **Grow** → **Store presence** → [**Main store listing**](https://play.google.com/console/developers/app/main-store-listing)

### 4a. App Details

| Field | What to type |
|-------|-------------|
| **App name** | `BuzzOff - Speed Camera Alerts` |
| **Short description** | `Silent speed camera alerts. Offline. Background mode. Never get flashed again.` |
| **Full description** | *(paste the full text below)* |

Full description to paste:
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

### 4b. Graphics — Upload these files

| Asset | File to upload |
|-------|---------------|
| **App icon** (512x512) | `app/assets/icon/play-store-512.png` |
| **Feature graphic** (1024x500) | `app/assets/store/feature-graphic.png` |
| **Phone screenshots** (drag all 4) | `app/assets/store/screenshot-1-alert.png` |
| | `app/assets/store/screenshot-2-idle.png` |
| | `app/assets/store/screenshot-3-settings.png` |
| | `app/assets/store/screenshot-4-countries.png` |

Click **Save** at the bottom.

---

## STEP 5: Content Rating

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content) → **Content rating** → **Start questionnaire**

1. Enter your **email address**
2. Select category: **Utility, Productivity, Communication, or Other**
3. Answer all violence/sexual content/etc questions: **No** to everything
4. Click **Save** → **Next** → **Submit**

Expected result: **Rated for Everyone**

---

## STEP 6: App Access

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content) → **App access**

Select: **All functionality is available without special access**

Click **Save**.

---

## STEP 7: Ads Declaration

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content) → **Ads**

Select: **No, my app does not contain ads**

Click **Save**.

---

## STEP 8: Target Audience

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content) → **Target audience**

1. Target age group: Select **18 and over** only
2. Confirm the app is NOT designed for children

Click **Next** → **Save**.

---

## STEP 9: Data Safety

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content) → **Data safety** → **Start**

Answer the wizard:

| Question | Answer |
|----------|--------|
| Does your app collect or share any user data? | **Yes** |
| Does your app share any user data with third parties? | **No** |
| Does your app collect any user data? | **Yes** |

Then on the data types page:
- Check **Location** → **Approximate location** ✅ and **Precise location** ✅
- Leave everything else unchecked

For Location details:
| Question | Answer |
|----------|--------|
| Is this data collected, shared, or both? | **Collected** |
| Is this data processed ephemerally? | **Yes** |
| Is this data required or optional? | **Required** |
| Why is this data collected? | **App functionality** |

Data handling:
| Question | Answer |
|----------|--------|
| Is data encrypted in transit? | **Yes** (location is never transmitted, so N/A, but select Yes) |
| Can users request data deletion? | **Not applicable** (no data stored on servers) |

Privacy policy URL: `https://buzzoff.me/privacy`

Click **Save** → **Submit**.

---

## STEP 10: Government Apps & Financial Features & Health

**Where:** Play Console → Your app → **Policy** → [**App content**](https://play.google.com/console/developers/app/app-content)

For each of these sections (if they appear):
- **Government apps** → Select **No**
- **Financial features** → Select **No** / Not applicable
- **Health apps** → Select **No** / Not applicable

Click **Save** on each.

---

## STEP 11: App Category & Contact Details

**Where:** Play Console → Your app → **Grow** → **Store presence** → [**Store settings**](https://play.google.com/console/developers/app/store-settings)

| Field | Value |
|-------|-------|
| **App category** | Maps & Navigation |
| **Email address** | `privacy@buzzoff.me` (or your actual email) |
| **Website** | `https://buzzoff.me` |
| **Phone** | *(optional, can leave empty)* |

Click **Save**.

---

## STEP 12: Build the Signed AAB

> ⚠️ Requires Step 3 to be done (keystore generated).

**On your Mac terminal:**

```bash
cd /Users/itays/dev/buzzoff.me/app

# Clean and build release AAB
flutter clean
flutter build appbundle --release
```

The output AAB file will be at:
```
app/build/app/outputs/bundle/release/app-release.aab
```

Verify it was created:
```bash
ls -lh build/app/outputs/bundle/release/app-release.aab
```

---

## STEP 13: Upload AAB to Play Console

**Where:** Play Console → Your app → **Release** → [**Production**](https://play.google.com/console/developers/app/releases/production)

> 💡 **Alternative:** If you want to test first, use **Closed testing** → **Internal testing** instead. This lets you install from Play Store without public visibility.

1. Click **Create new release**
2. **App signing:** If prompted about Google Play App Signing, click **Continue** (recommended — Google manages your signing key)
3. **Upload:** Drag `app/build/app/outputs/bundle/release/app-release.aab` into the upload area
4. Wait for upload and processing
5. **Release name:** `1.0.0`
6. **Release notes:** Paste this:

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

7. Click **Save**
8. Click **Review release**
9. Review any warnings/errors
10. Click **Start rollout to Production** (or **Start internal testing** if using closed testing)

---

## STEP 14: Submit for Review

After clicking "Start rollout", your app enters **Pending review**.

- Review typically takes **1–7 days** for new apps
- You'll get an email when approved or if there are issues
- Check status at: Play Console → Your app → [**Publishing overview**](https://play.google.com/console/developers/app/publishing)

---

## STEP 15: After Approval — Update Website

Once your app is live, you'll get a Play Store URL like:
```
https://play.google.com/store/apps/details?id=me.buzzoff.app
```

Then update the website download button to point to this URL instead of the APK.

---

## Quick Reference: File Locations

| Asset | Path |
|-------|------|
| App icon 512px | `app/assets/icon/play-store-512.png` |
| Feature graphic | `app/assets/store/feature-graphic.png` |
| Screenshot 1 | `app/assets/store/screenshot-1-alert.png` |
| Screenshot 2 | `app/assets/store/screenshot-2-idle.png` |
| Screenshot 3 | `app/assets/store/screenshot-3-settings.png` |
| Screenshot 4 | `app/assets/store/screenshot-4-countries.png` |
| Privacy policy | `https://buzzoff.me/privacy` |
| Full description | `FEATURES/google-play-publish.md` (Detailed Specs section) |
| Release AAB | `app/build/app/outputs/bundle/release/app-release.aab` |

---

## Checklist

- [x] Step 1 — Developer account verified
- [x] Step 2 — App created in Play Console
- [x] Step 3 — Keystore generated, key.properties created
- [x] Step 4 — Store listing filled (text + graphics uploaded)
- [x] Step 5 — Content rating submitted
- [x] Step 6 — App access set
- [x] Step 7 — Ads declaration set
- [x] Step 8 — Target audience set
- [x] Step 9 — Data safety submitted
- [x] Step 10 — Government/Financial/Health set
- [x] Step 11 — Category and contact details set
- [ ] Step 12 — AAB built successfully
- [ ] Step 13 — AAB uploaded to Play Console
- [ ] Step 14 — Submitted for review
- [ ] Step 15 — Website updated after approval
