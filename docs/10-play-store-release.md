# 10. Google Play Store Release Guide

Follow this guide to publish **All in One News** on Google Play with the lowest risk of rejection. The building part is in [BUILD_INSTRUCTIONS.md](../BUILD_INSTRUCTIONS.md).

> Google's policies change. Check the current [Developer Program Policies](https://play.google.com/about/developer-content-policy/) and the [target API requirements](https://developer.android.com/google/play/requirements/target-sdk) before each release.

## 10.1 Pre-flight checklist

| ✔ | Item | Where |
|---|---|---|
| ☐ | Own app ID (not `com.allinonenews.app`) | `android/app/build.gradle.kts` |
| ☐ | Upload keystore created and backed up; `key.properties` configured | BUILD_INSTRUCTIONS §4 |
| ☐ | Backend online over HTTPS; app built with `API_BASE_URL` | [09-deployment.md](09-deployment.md) |
| ☐ | Demo content replaced with websites you may feature | Admin Panel |
| ☐ | Privacy & legal filled in (publisher, support e-mail, policy) | Admin → Privacy & legal |
| ☐ | Privacy policy URL opens in a browser | `https://<domain>/privacy-policy` |
| ☐ | `version: x.y.z+N` increased | `app/pubspec.yaml` |
| ☐ | Tested a **release** build on a real phone | `flutter install --release` |
| ☐ | `flutter analyze` and `flutter test` are clean | |

Already done in the code: targetSdk 36, minSdk 24, 64-bit native code (Flutter default), only the `INTERNET` permission, HTTPS-only network config, adaptive and monochrome launcher icons, Android 12+ splash screen, predictive back, edge-to-edge, crash-safe error handlers, offline mode, accessibility semantics.

## 10.2 Developer account

1. Register at https://play.google.com/console (one-time USD 25 fee) and complete identity verification.
2. **New personal developer accounts** must run a **closed test with at least 12 testers for 14 continuous days** before they can apply for production access. Plan for this.

## 10.3 Content & WebView policy (read this first)

This is the most important section for an app that shows other people's websites.

**Google Play "Spam and Minimum Functionality / Webviews"** prohibits apps *"whose primary purpose is to … provide a webview of a website without permission from the website owner or administrator."* **Intellectual property** and **Impersonation** policies prohibit using other organisations' logos or names in a way that suggests endorsement.

How this project reduces the risk:

1. **Default open mode is "In-app browser tab"** (Chrome Custom Tabs). The page is shown by the user's own browser, not embedded in a WebView, which is the approach Google recommends for third-party links.
2. The **embedded browser** (`in_app`) is opt-in per website. **Use it only for sites you own or have written permission to embed.**
3. The app adds its own value: curation into categories, search, favourites, recent history, featured items, offline cache and accessibility. It is a directory/launcher, not a thin wrapper of one website.
4. Every opened site keeps its own branding and address bar.

What **you** must do:

* **Only list services you are allowed to link to**, and only use their **logos with permission** (or use the app's coloured initials instead).
* For **live TV/streams**, link only to **official, legal** sources. Never link to pirated streams; that leads to removal and account termination.
* Don't name or brand the app after a third party (e.g. "BBC App"), and don't claim affiliation.
* Mention in the store description that the app links to third-party websites.
* Keep the demo data out of production (it uses well-known sites purely as examples).
* Keep evidence of permissions (e-mails, agreements) in case Google asks.

**App access for reviewers:** the app has no login, so in *App content → App access* choose **"All functionality is available without special access."**

## 10.4 Create the app in Play Console

1. **Create app**: name *All in One News* (or yours, ≤ 30 chars), default language, **App**, **Free**, accept the declarations.
2. **Set up your app** checklist (Dashboard). Complete every item:

### Privacy policy
`https://<your-domain>/privacy-policy` (built-in page, editable in Admin → Privacy & legal) or your own URL.

### App access
"All functionality is available without special access."

### Ads
**No, my app does not contain ads** (unless you add an ad SDK later; then update this and the Data Safety form).

### Content rating (IARC questionnaire)
Category: **Reference, News, or Educational** (or *All other app types*). Answer honestly. The app itself has no violence, sexuality, gambling or user-to-user chat, but answer **Yes** to questions about **unrestricted web access / users can view web content**, since users can open websites. This usually yields a teen-level rating such as *Teen / PEGI 12* (varies by region).

### Target audience and content
Select **18 and over** or **13+** age groups. Do **not** target children: it opens news/web content, and choosing under-13 brings the Families policy requirements.

### News apps declaration
If you declare the app as a **News** app (*App content → News apps*), Google requires transparency about the publisher, contact details and sources. Either complete those requirements (publisher name, contact e-mail and the list of sources on your website/About text), or categorise the app as **News & Magazines** without declaring it a news *publisher* if it is a directory of links. Answer according to what your app really is.

### Data safety
Answers for this codebase **as shipped** (re-check if you add analytics, crash reporting, ads or accounts):

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (HTTPS only) |
| Do you provide a way for users to request that their data is deleted? | Not applicable (no data collected); favourites/history are deleted by clearing app data or uninstalling |

Why "No": favourites, history and the cached feed are stored **on the device only** and never sent. The config request carries no identifiers. Server access logs (IP address for security, short retention) fall under Google's exemption for data needed to operate the service; mention them in your privacy policy (the default policy does). Websites the user opens are third parties with their own policies.

### Government apps / Financial features / Health
**No / None** for all.

## 10.5 Store listing

**Main store listing**
* **App name** (≤ 30): `All in One News`
* **Short description** (≤ 80): `News channels, live streams and useful sites, all in one place.`
* **Full description** (≤ 4000), example:

```
All in One News brings your favourite news channels, live streams, sports, technology,
entertainment, education and information services together in one beautiful, fast app.

• Browse by category: News, Live Streaming, Sports, Technology and more
• Featured channels and live events at a glance
• Instant search across every channel and website
• Save favourites and reorder them your way
• Recently opened list for quick access
• Opens websites securely in your browser tab, no account needed
• Works offline with the last downloaded list
• Dark and light designs, large-text and screen-reader friendly

All in One News is a directory of links to third-party websites and services. Each website
belongs to its owner and is subject to its own terms and privacy policy.
```

* **App icon**: 512×512 PNG → `store-assets/play-store-icon-512.png`
* **Feature graphic**: 1024×500 → `store-assets/play-feature-graphic-1024x500.png`
* **Phone screenshots**: 2–8, 16:9 or 9:16, min 320 px, max 3840 px. Take them from a release build (Home, a category, Featured, Search, Favourites, browser). Use your **own** content, not third-party logos you are not allowed to show.
* **7" and 10" tablet screenshots**: recommended (the app adapts its grid).
* **App category**: **News & Magazines** (or *Tools/Productivity* for a general launcher).
* **Contact details**: e-mail (required), website, phone (optional).

## 10.6 Upload and release

1. **Testing → Internal testing → Create new release.** Let Google manage the app signing key (Play App Signing) and upload `app-release.aab`.
2. Release notes: e.g. "First release."
3. Add testers (e-mail list), share the opt-in link, install via the Play Store and test.
4. **Closed testing** with ≥ 12 testers for 14 days if your account requires it (§10.2).
5. **Production → Create new release** → promote the tested build → choose countries → **Review release → Start rollout**. Consider a **staged rollout** (e.g. 20%).
6. Review usually takes from a few hours to several days. Watch the **Inbox** and **Policy status** pages.

## 10.7 Pre-launch report and vitals

Play runs the app on real devices automatically. Check *Testing → Pre-launch report* for crashes, accessibility suggestions (contrast, touch target sizes) and security warnings. After launch watch **Android vitals** (crash rate < 1.09%, ANR rate < 0.47%).

## 10.8 Updating the app

* **Content changes:** Admin Panel only, no update needed.
* **Code changes:** bump `version` (`1.0.1+2`), build the AAB, create a release on the same track.
* Each year Google raises the minimum **target API level** (usually by 31 August). Update Flutter, raise `targetSdk`/`compileSdk` in `build.gradle.kts`, test and publish before the deadline, or updates get blocked.

## 10.9 Common rejection reasons and fixes

| Rejection | Fix |
|---|---|
| *Webview spam / Minimum functionality* | Use Custom Tab mode (default) for sites you don't own; show the app's curation and search features in screenshots; get permissions; add a clear directory-style description. |
| *Intellectual property / Impersonation* | Remove logos and names you have no permission for; don't imply official affiliation. |
| *Privacy policy missing or invalid* | The URL must be public, HTTPS, and mention the app name and data practices. |
| *Data safety inconsistent* | Your form must match the SDKs you actually include. Update both when you add analytics, ads or crash reporting. |
| *Broken functionality* | The app must work during review: backend online, demo or real content present. |
| *Target API too low* | Raise `targetSdk` to the current requirement. |
| *Metadata policy* | No keyword stuffing, no other apps' names, no "#1"/"best" claims in the title. |
