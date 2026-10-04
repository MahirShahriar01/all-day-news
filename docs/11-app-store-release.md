# 11. Apple App Store Release Guide (iOS version)

The iOS version is built from **the same Flutter code** as Android ([`app/`](../app/)). Everything users see (content, branding, colours) is shared and managed in the same Admin Panel. This guide covers what is specific to Apple. Build steps: [BUILD_INSTRUCTIONS.md §6](../BUILD_INSTRUCTIONS.md#6-build-for-ios--apple-app-store-on-a-mac).

> Check Apple's current [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) before each submission.

## 11.1 What is already prepared in the iOS project

| Item | Where | Status |
|---|---|---|
| Bundle ID placeholder `com.allinonenews.app` | Xcode → Runner → Signing | **change to yours** |
| Display name "All in One News" | `ios/Runner/Info.plist` → `CFBundleDisplayName` | ✓ |
| App icons, all sizes, no alpha | `ios/Runner/Assets.xcassets/AppIcon.appiconset` | ✓ (regenerate after changing artwork) |
| Launch screen (splash) | `LaunchScreen.storyboard` + `LaunchImage` | ✓ |
| Privacy manifest | `ios/Runner/PrivacyInfo.xcprivacy` | ✓ no tracking, no collected data, UserDefaults reason `CA92.1` |
| Export compliance | `ITSAppUsesNonExemptEncryption = false` | ✓ (standard HTTPS only) |
| App Transport Security | default (HTTPS only, no exceptions) | ✓ |
| URL schemes queried | `LSApplicationQueriesSchemes`: https, http, mailto, tel | ✓ |
| Minimum iOS | 15.0 | ✓ |
| iPhone + iPad, all orientations on iPad | Info.plist | ✓ |
| In-app browser | SFSafariViewController (`custom_tab` mode) and WKWebView (`in_app`) with inline video | ✓ |
| Dark mode, Dynamic Type, VoiceOver, Reduce Motion | Flutter app | ✓ |

## 11.2 Accounts and identifiers

1. Join the **Apple Developer Program** (https://developer.apple.com/programs/, USD 99/year). Organisations need a D-U-N-S number.
2. **Identifiers → App IDs → +** → *App* → Bundle ID `com.yourcompany.allinonenews`. No special capabilities are needed.
3. **App Store Connect → Apps → +** → New App: platform iOS, name, language, bundle ID, SKU (any unique text, e.g. `allinonenews-ios`), access *Full Access*.

## 11.3 Signing (Xcode)

`open app/ios/Runner.xcworkspace` → **Runner** target → **Signing & Capabilities**:
* ✔ Automatically manage signing
* Team: your developer team
* Bundle Identifier: the one from §11.2

Xcode creates the distribution certificate and provisioning profile for you.

## 11.4 App Review Guidelines: what matters for this app

**4.2 Minimum Functionality.** Apple rejects apps that are *"a repackaged website"* or mainly web content. This app is a native directory with categories, search, favourites, recents, featured carousel, offline cache and native settings. Make sure that value is visible:
* Keep the default **In-app browser tab** mode (SFSafariViewController) for third-party sites.
* Show native features in your screenshots and review notes.
* Have enough real content at review time (dozens of curated entries, not three links).

**5.2 Intellectual Property.** Don't use third-party names, logos or streams without permission, and don't suggest an affiliation. Only link to **legal, official** live streams.

**5.1.1 Privacy.** A privacy policy URL is required in App Store Connect **and** must be reachable in the app (*About → Privacy policy*). Both are provided.

**1.4 / 1.1 objectionable content & web access.** Because users can reach the open web, answer the age-rating question about **"Unrestricted Web Access"** with **Yes**. This sets the rating to **18+** under Apple's rating system (or the equivalent in the current age categories). If you need a lower rating, use `custom_tab`/`external` only and curate strictly, but Apple may still consider web access unrestricted.

**2.1 App Completeness.** The backend must be online during review and the app must not show the demo content (or show clearly curated real content).

**2.3 Accurate Metadata.** Screenshots must show the real app; no other platforms' device frames or "Android" mentions.

## 11.5 App Store Connect: App Information & Privacy

**App Privacy ("nutrition label")**, for the app as shipped:
* *Do you or your third-party partners collect data from this app?* → **No, we do not collect data from this app.**

(The feed request carries no identifiers; favourites, history and cache stay on the device. Server security logs are not "collected" in Apple's sense when not linked to identity and kept briefly. Describe them in the privacy policy, which the default policy does. If you add analytics, crash reporting or ads, update this answer and `PrivacyInfo.xcprivacy`.)

**Other fields**
* Category: **News** (primary), **Reference** or **Utilities** (secondary).
* Content rights: confirm you have the rights to third-party content you show (logos etc.) or that you don't show any.
* Age rating questionnaire: see §11.4.
* Pricing: Free; availability: choose countries.

## 11.6 Version page

| Field | Example / requirement |
|---|---|
| Screenshots | **6.9" iPhone** (1320×2868 or 1290×2796), and **13" iPad** (2064×2752) if you support iPad. Take them in the Simulator (`⌘S`) from a release build. |
| Promotional text (170) | "All your news channels, live streams and useful websites, beautifully organised." |
| Description | Reuse the Play description ([10-play-store-release.md §10.5](10-play-store-release.md#105-store-listing)). |
| Keywords (100 chars, comma separated) | `news,live,tv,channels,streaming,sports,headlines,world,technology,radio` (no competitors' names) |
| Support URL | a page with contact details (your website, or `mailto:` via a simple page) |
| Marketing URL | optional |
| Privacy Policy URL | `https://<your-domain>/privacy-policy` |
| Copyright | `2026 Your Company` |
| Build | choose the uploaded build |

**App Review Information**
* Sign-in required: **No**.
* Notes (suggested):
  > All in One News is a curated directory of news, live-streaming and information services managed by our editorial team. Native features: category browsing, instant search, favourites with reordering, recently opened list, featured carousel, offline cache and VoiceOver support. Third-party websites open in SFSafariViewController. We link only to official sources we are permitted to feature.
* Contact name, phone, e-mail.

## 11.7 Automating iOS builds (optional)

The CI job `ios` compiles the app unsigned on every push. To produce **signed uploads** in CI:

1. App Store Connect → Users and Access → **Integrations → App Store Connect API** → generate a key (*App Manager*). Save the `.p8`, Key ID and Issuer ID as GitHub secrets.
2. Store the distribution certificate (`.p12` + password) and the App Store provisioning profile as base64 secrets (or use **fastlane match**).
3. In a macOS job: import the certificate into a temporary keychain, install the profile, then
   ```bash
   flutter build ipa --release --export-options-plist=ios/ExportOptions.plist \
     --dart-define=API_BASE_URL=${{ vars.API_BASE_URL }} --build-number=${{ github.run_number }}
   xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios --apiKey "$KEY_ID" --apiIssuer "$ISSUER_ID"
   ```
   with an `ExportOptions.plist` containing `method = app-store-connect`, your `teamID` and the profile mapping.

Hosted alternatives that handle signing for you: **Codemagic**, **Bitrise**, **Xcode Cloud**.

## 11.8 TestFlight and submission

1. Upload the build (Transporter, Xcode Organizer or `altool`).
2. Wait for processing, then answer the export-compliance question (already answered by `ITSAppUsesNonExemptEncryption`).
3. **TestFlight → Internal testing**: add up to 100 team members and test on real iPhones and iPads.
4. External TestFlight (optional) needs a short beta review.
5. **App Store → version → Add for Review → Submit.** Review typically takes 24–48 h.
6. Choose manual or automatic release after approval; consider **phased release** (7 days).

## 11.9 Updates

* Content changes: Admin Panel only, no review needed.
* Code changes: bump `version: x.y.z+N` in `pubspec.yaml` (N must increase), build, upload, submit.
* Each spring Apple requires building with the latest Xcode/iOS SDK. Update Flutter and Xcode, rebuild and resubmit when announced.

## 11.10 Common rejections and fixes

| Guideline | Typical message | Fix |
|---|---|---|
| 4.2 | "Your app provides a limited user experience as it is not sufficiently different from a mobile browsing experience" | Emphasise native features, more curated content, Custom Tab mode, explain in review notes; consider adding more native functionality ([13-extending.md](13-extending.md)). |
| 5.2.1 | "Your app includes content or features from third parties without the necessary authorization" | Provide written permission in review notes, or remove those logos/names. |
| 2.1 | "We were unable to load content" | Backend must be HTTPS, online and filled with content. |
| 5.1.1 | Privacy policy missing or inaccessible | Check the URL in App Store Connect and in the About screen. |
| 1.4.1 / age rating | Web access not declared | Set "Unrestricted Web Access" = Yes. |
| 2.3.10 | Screenshots show other platforms | Use iOS screenshots only. |
