# Build Instructions: Android (APK / AAB) and Apple (iOS / App Store)

This guide builds **All in One News** from source. The same Flutter code in [`app/`](app/) produces the Android app (Google Play) and the iPhone/iPad app (Apple App Store).

| You want… | Command / place | Needs |
|---|---|---|
| An **APK** to install on a phone | `flutter build apk --release` | Linux, macOS or Windows |
| An **AAB** for Google Play | `flutter build appbundle --release` | Linux, macOS or Windows + upload key |
| An **IPA** for the App Store | Xcode → Product → Archive, or `flutter build ipa` | **A Mac** with Xcode + Apple Developer account |
| No local setup at all | GitHub → **Actions → Mobile app** → artifacts | A GitHub account |

---

## 0. Get a ready-made APK without installing anything

Every push to the repository runs the **Mobile app** workflow, which builds:

* `all-in-one-news.apk`: install directly on any Android 7.0+ phone
* `all-in-one-news.aab`: the bundle Google Play needs
* `SHA256SUMS.txt`: checksums

Download: GitHub → **Actions** → **Mobile app** → open the latest green run → **Artifacts** → `all-in-one-news-android` (a zip).
To start a build manually: **Actions → Mobile app → Run workflow**.
To publish a **GitHub Release** with the APK attached, push a tag:

```bash
git tag v1.0.0 && git push origin v1.0.0
```

> **Content source.** If the repository variable `API_BASE_URL` is not set (*Settings → Secrets and variables → Actions → Variables*), the APK runs on its **built-in demo content**. Set it to your server (e.g. `https://news.example.com`) and re-run to get an APK that follows your Admin Panel.
>
> **Signing.** Without keystore secrets the CI APK is signed with a *debug* key: installable for testing, **not** accepted by Google Play. See [§4](#4-release-signing-android) to add the secrets.

To install the APK on a phone: copy it to the phone, open it, and allow "Install unknown apps" for your file manager or browser when Android asks.

---

## 1. Choose your app ID

The placeholder ID is `com.allinonenews.app`. Use a reverse domain you control (e.g. `com.yourcompany.allinonenews`). **It can never change after the first store upload.**

| Platform | File | Setting |
|---|---|---|
| Android | `app/android/app/build.gradle.kts` | `namespace` **and** `applicationId` |
| Android | `app/android/app/src/main/kotlin/com/allinonenews/app/MainActivity.kt` | `package …` line, and move the file to the matching folders |
| iOS | Xcode → Runner target → *Signing & Capabilities* → **Bundle Identifier** (or `PRODUCT_BUNDLE_IDENTIFIER` in `app/ios/Runner.xcodeproj/project.pbxproj`) | |

The **name under the icon** is set in `android/app/src/main/AndroidManifest.xml` (`android:label`) and `ios/Runner/Info.plist` (`CFBundleDisplayName`). The name shown **inside** the app comes from the Admin Panel.

**Icons and splash:** replace `app/assets/images/app_icon.png` (1024×1024, no transparency), `app_icon_foreground.png` (adaptive icon foreground) and `splash_logo.png`, then run:

```bash
cd app
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 2. Install the tools

### All platforms
1. **Flutter 3.47.x stable**: https://docs.flutter.dev/get-started/install (CI uses 3.47.6).
2. Run `flutter doctor` and fix what it reports.

### Android (Windows, macOS or Linux)
1. **Android Studio** (includes the Android SDK). In *SDK Manager* install **Android SDK Platform 36**, **Build-Tools**, **Command-line tools** and the **NDK** version Flutter asks for.
2. **JDK 17** (bundled with Android Studio). Check with `flutter doctor -v`.
3. Accept licences: `flutter doctor --android-licenses`.

### iOS (macOS only)
1. A Mac with the latest **Xcode** from the Mac App Store. Open it once and install the iOS platform.
2. `sudo xcode-select -s /Applications/Xcode.app && sudo xcodebuild -runFirstLaunch`
3. **CocoaPods**: `sudo gem install cocoapods` (or `brew install cocoapods`). Newer Flutter versions may use Swift Package Manager instead; Flutter handles this automatically.
4. An **Apple Developer Program** membership (USD 99/year) to publish.

---

## 3. Point the app at your server

The app reads its content from your backend. Pass the URL at build time:

```bash
--dart-define=API_BASE_URL=https://news.example.com
```

or keep it in a file (copy `app/env/production.example.json` to `app/env/production.json`):

```bash
--dart-define-from-file=env/production.json
```

* Must be **https://** for release builds (Android blocks clear-text traffic; iOS App Transport Security requires TLS).
* Leave it out to build a **demo** app that shows the bundled sample content.
* Later content changes (websites, logos, colours…) need **no rebuild**. The app downloads them on start and when it returns to the foreground.

---

## 4. Release signing (Android)

Google Play requires an **upload key**. Create it **once** and keep it (and its passwords) safe. If you lose it, you have to ask Google support to reset it.

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 \
        -validity 10000 -alias upload
```

Create `app/android/key.properties` (already in `.gitignore`, **never commit it**):

```properties
storeFile=/Users/you/upload-keystore.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

`build.gradle.kts` picks this file up automatically. Without it, release builds are signed with the debug key and Gradle prints a warning.

**For GitHub Actions**, add these repository **secrets**:

| Secret | Value |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | output of `base64 -w0 upload-keystore.jks` (macOS: `base64 -i upload-keystore.jks`) |
| `ANDROID_KEYSTORE_PASSWORD` | store password |
| `ANDROID_KEY_ALIAS` | `upload` |
| `ANDROID_KEY_PASSWORD` | key password |

Enrol in **Play App Signing** when you create the app in Play Console (default). Google then holds the final app-signing key and your upload key only proves uploads come from you.

---

## 5. Build for Android

```bash
cd app
flutter clean && flutter pub get
flutter test                                  # optional but recommended

# Installable APK (one file that works on every phone)
flutter build apk --release --dart-define=API_BASE_URL=https://news.example.com
#   → build/app/outputs/flutter-apk/app-release.apk

# Smaller per-CPU APKs (optional, for sideloading)
flutter build apk --release --split-per-abi --dart-define=API_BASE_URL=https://news.example.com

# Google Play bundle
flutter build appbundle --release --dart-define=API_BASE_URL=https://news.example.com
#   → build/app/outputs/bundle/release/app-release.aab
```

**Versioning:** `version: 1.0.0+1` in `app/pubspec.yaml` means *versionName 1.0.0, versionCode 1*. **Increase the number after `+` for every Play upload** (or pass `--build-number=N`).

Test the release build on a real phone:

```bash
flutter install --release        # or: adb install build/app/outputs/flutter-apk/app-release.apk
```

Then upload the `.aab`: follow [docs/10-play-store-release.md](docs/10-play-store-release.md).

**Already configured for Google Play:** targetSdk/compileSdk 36, minSdk 24 (Android 7.0), only the `INTERNET` permission, HTTPS-only network security config, Android 11+ package-visibility queries, adaptive and monochrome icons, Android 12+ splash, predictive back gesture, edge-to-edge (Android 15+), R8 code shrinking.

---

## 6. Build for iOS / Apple App Store (on a Mac)

### 6.1 One-time setup
1. Apple Developer account → **Certificates, Identifiers & Profiles → Identifiers → +** → App ID with your bundle ID (e.g. `com.yourcompany.allinonenews`).
2. **App Store Connect → My Apps → +** → New App → choose that bundle ID, name *All in One News* (or yours), primary language, SKU.
3. Open the project in Xcode:
   ```bash
   cd app
   flutter pub get
   open ios/Runner.xcworkspace        # if it does not exist yet: open ios/Runner.xcodeproj
   ```
4. Select **Runner** → **Signing & Capabilities** → tick **Automatically manage signing** → choose your **Team** → set the **Bundle Identifier**.
5. Under **General**, check *Display Name* and the minimum iOS version (15.0).

### 6.2 Build and upload

**Option A: Flutter command line**

```bash
cd app
flutter build ipa --release --dart-define=API_BASE_URL=https://news.example.com
#   → build/ios/ipa/*.ipa  and  build/ios/archive/Runner.xcarchive
```
Upload with the **Transporter** app (Mac App Store) by dragging the `.ipa` in, or:
```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey KEY_ID --apiIssuer ISSUER_ID
```

**Option B: Xcode**
1. `flutter build ios --release --dart-define=API_BASE_URL=https://news.example.com` (this bakes the setting into the Xcode build).
2. In Xcode choose the device **Any iOS Device (arm64)** → **Product → Archive**.
3. In the Organizer: **Distribute App → App Store Connect → Upload**.

**Versioning:** the same `version: x.y.z+N` in `pubspec.yaml` becomes *CFBundleShortVersionString* (x.y.z) and *CFBundleVersion* (N). Every upload needs a higher N.

### 6.3 After upload
The build appears in App Store Connect after processing (5–30 min). Test it in **TestFlight**, then submit for review. See [docs/11-app-store-release.md](docs/11-app-store-release.md) for screenshots, App Privacy answers and review notes.

**Already configured for the App Store:** privacy manifest `PrivacyInfo.xcprivacy` (no tracking, no data collected, UserDefaults reason CA92.1), `ITSAppUsesNonExemptEncryption = NO` (only standard HTTPS), no ATS exceptions, `LSApplicationQueriesSchemes`, all icon sizes without alpha, launch screen, iPad orientations.

### 6.4 Building iOS without owning a Mac
* The CI job **Mobile app → ios** compiles the app on a GitHub macOS runner (unsigned) to prove it builds.
* For signed uploads without a Mac, use a cloud Mac (Codemagic, Bitrise, GitHub `macos-latest` with an App Store Connect API key and `fastlane match`). The steps are the same as above; see [docs/11-app-store-release.md §7](docs/11-app-store-release.md#7-automating-ios-builds-optional).

---

## 7. Common build problems

| Symptom | Fix |
|---|---|
| `Gradle task assembleRelease failed … SDK location not found` | Open `app/android` once in Android Studio, or create `app/android/local.properties` with `sdk.dir=/path/to/Android/sdk` and `flutter.sdk=/path/to/flutter`. |
| `NDK … not found` | Android Studio → SDK Manager → SDK Tools → NDK (Side by side), install the version in the error. |
| `Unsupported class file major version` | Use JDK 17: `flutter config --jdk-dir=/path/to/jdk17`. |
| Play Console: *"You uploaded an APK or Android App Bundle that was signed in debug mode"* | Create `key.properties` (§4) and rebuild. |
| Play Console: *"Version code 1 has already been used"* | Increase the `+N` in `pubspec.yaml`. |
| App shows demo content | It was built without `--dart-define=API_BASE_URL=…`. |
| App shows "offline" icon | Server unreachable or not HTTPS. Open `https://your-domain/api/v1/health` in the phone's browser. |
| Xcode: *"No profiles for … were found"* | Choose your Team in Signing & Capabilities with automatic signing on. |
| `pod install` errors | `cd app/ios && pod repo update && pod install`, or `flutter clean && flutter pub get`. |

More in [docs/12-maintenance-troubleshooting.md](docs/12-maintenance-troubleshooting.md).
