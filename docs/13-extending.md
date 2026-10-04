# 13. Future Development & Extension Guide

The project is designed so new features can be added **without rewriting existing code**. This guide shows where each kind of change goes, with worked examples.

## 13.1 Design principles to keep

1. **Server-driven UI:** anything an administrator might want to change belongs in the database/settings, not in app code.
2. **Backward-compatible API:** within `/api/v1` only **add** fields and endpoints. Never rename/remove fields or change their meaning. Old app versions stay on phones for years.
3. **Tolerant clients:** the app ignores unknown fields and has defaults for missing ones. Keep it that way in every new model.
4. **Feature folders:** new app features go into `app/lib/features/<name>/` with their own screens/widgets; shared pieces into `core/`.
5. **Services over endpoints:** put backend logic in `app/services/` so it can be reused by the CLI, jobs and tests.
6. **Tests with every change:** `pytest`, `flutter test`, `npm run build` must stay green (CI enforces it).

## 13.2 Adding a field to websites (example: "language")

1. **Model** `backend/app/models/site.py`: `language: Mapped[str] = mapped_column(String(10), default="", server_default="", nullable=False)`
2. **Migration**: `cd backend && alembic revision --autogenerate -m "site language"`, review, `alembic upgrade head`.
3. **Schemas** `backend/app/schemas/site.py`: add to `SiteBase`, `SiteUpdate`, `SiteOut`.
4. **Public feed** `backend/app/services/config_bundle.py` → `_public_site`: `"language": site.language`.
5. **Admin**: `admin/src/api/types.ts` (`Site.language`), a field in `SiteEditor` (`pages/Sites.tsx`), include it in the save payload.
6. **App**: `Site` in `app/lib/data/models/app_config.dart`: `language: _str(j['language'])`, then use it (e.g. a filter chip).
7. **Tests**: extend `backend/tests/test_content.py` and `app/test/models_test.dart`.

Older apps simply ignore `language`; the new app treats it as empty when talking to an older server.

## 13.3 Adding a new settings option (example: "show recently opened")

No migration needed:
1. `backend/app/schemas/settings.py` → `LayoutSettings`: `show_recents: bool = True`
2. `admin/src/api/types.ts` + a `Toggle` in `pages/Settings.tsx` (layout section)
3. `app/lib/data/models/app_config.dart` → `LayoutSettings`: `showRecents: _bool(j['show_recents'], true)`
4. Use it in `features/home/home_screen.dart`.

## 13.4 Adding a new screen / feature to the app (example: "Live now")

1. Create `app/lib/features/live/live_screen.dart` (a `ConsumerWidget` reading `appConfigProvider`, e.g. sites whose badge is `LIVE`).
2. Register a route in `app/lib/router.dart`, either as a new tab (`StatefulShellBranch` + a `NavigationDestination` in `features/shell/main_shell.dart`) or as a pushed route.
3. Reuse `SiteCard`, `SiteGrid`, `FeaturedCard`, `StatusView` and `LinkOpener`.
4. Add a widget test in `app/test/`.

To make tabs **admin-configurable**, add a `navigation` settings section listing enabled tabs, and build the shell's destinations from it.

## 13.5 Adding a new API version

When a breaking change is unavoidable:
1. Copy `backend/app/api/v1` to `backend/app/api/v2` and change what's needed.
2. Mount it in `app/main.py`: `app.include_router(api_v2_router, prefix="/api/v2")`.
3. Point new app releases at `/api/v2` (`Env.apiUri`), keep v1 running until old app versions are gone (check store statistics).

## 13.6 Adding analytics or crash reporting

Options: Firebase Crashlytics/Analytics, Sentry. Steps:
1. Add the SDK to `app/pubspec.yaml` and initialise it in `app/lib/main.dart` (the `FlutterError.onError` / `PlatformDispatcher.onError` hooks are already there; forward errors to the SDK).
2. **Update privacy disclosures**: Google Play **Data safety** (crash logs, diagnostics, app interactions, device IDs), Apple **App Privacy** label and `ios/Runner/PrivacyInfo.xcprivacy` (collected data types, required-reason APIs of the SDK), and your privacy policy text (Admin → Privacy & legal).
3. Ask for consent where the law requires it (e.g. GDPR/UK for analytics).

## 13.7 Push notifications

1. Add Firebase Cloud Messaging (`firebase_messaging`), configure Android (`google-services.json`) and iOS (APNs key, Push capability).
2. Ask permission at a sensible moment (Android 13+ `POST_NOTIFICATIONS`, iOS prompt).
3. Backend: a `notifications` table, admin page "Send notification" (title, text, target site), and a service calling the FCM HTTP v1 API.
4. Update the Data safety and App Privacy answers (device/push token).

## 13.8 User accounts & cloud-synced favourites

1. Backend: `users` table, auth endpoints under `/api/v1/auth/*` (e-mail magic links, Sign in with Apple/Google). Keep admin auth separate.
2. App: an `auth` feature; sync `favoritesProvider` to `/api/v1/me/favorites`.
3. **Store rules:** apps with account creation **must offer account deletion in-app** (Apple 5.1.1(v), Google Play account deletion requirement) and a web deletion link for Play. Update privacy disclosures.

## 13.9 Multi-language content

* App UI: add `flutter_localizations` + ARB files (`l10n.yaml`) and replace string literals.
* Content: add a `translations` JSON column to categories/sites (`{"bn": {"name": "…"}}`) or a `locale` field, and send the device locale as `?lang=` to `/config`; the bundle builder picks the right text.
* Admin: language tabs in the editors.

## 13.10 Media on a CDN / object storage

Implement the `Storage` protocol in `backend/app/services/storage.py` (e.g. `S3Storage` using `boto3`, returning `https://cdn.example.com/<key>` URLs) and return it from `get_storage()` based on a new setting like `STORAGE_BACKEND=s3`. Existing `/uploads/...` records keep working; migrate old files with a one-off script if you like.

## 13.11 Scheduled content (start/end dates)

Add `visible_from` / `visible_until` (nullable timestamps) to `sites`, filter them in `build_public_config`, and lower the feed's `max-age` if minute-accurate scheduling matters. The app needs no change.

## 13.12 Admin roles and permissions

`AdminUser.role` is a string, so new roles (e.g. `viewer`) are additive: add a dependency like `require_role("owner","editor")` in `app/api/deps.py` and use it on write endpoints. Mirror the role in the admin UI navigation.

## 13.13 Where things live (cheat sheet)

| I want to change… | File(s) |
|---|---|
| App colours/layout defaults | `backend/app/schemas/settings.py` (+ admin panel) |
| Card look | `app/lib/features/home/widgets/site_card.dart` |
| Featured carousel | `app/lib/features/home/widgets/featured.dart` |
| How links open | `app/lib/features/browser/link_opener.dart` |
| Embedded browser UI | `app/lib/features/browser/browser_screen.dart` |
| Theme building | `app/lib/core/theme/app_theme.dart` |
| Category icon list | `app/lib/core/utils/icon_registry.dart` + `admin/src/lib/icons.ts` |
| Feed contents | `backend/app/services/config_bundle.py` |
| Upload rules | `backend/app/services/storage.py` |
| Privacy policy default text | `backend/app/web.py` |
| Admin navigation | `admin/src/App.tsx` |
| CI / builds | `.github/workflows/*.yml` |
