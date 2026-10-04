# 1. Architecture & Source Code Documentation

## 1.1 System overview

All in One News has three applications that share one data model:

1. **Backend API** (`backend/`): the single source of truth. Stores categories, websites, media and settings in a relational database and serves them through a **versioned REST API** (`/api/v1`).
2. **Admin Panel** (`admin/`): a web app used by administrators. It calls the protected `/api/v1/admin/*` endpoints.
3. **Mobile app** (`app/`): a Flutter app for Android and iOS. It downloads **one configuration document** (`GET /api/v1/config`) that contains everything it needs to render the UI.

### Why one configuration document?
* **One request** on start-up: fast on slow mobile networks.
* **ETag caching**: when nothing changed the server answers `304 Not Modified` with an empty body.
* **Offline-first**: the app stores the last document and shows it immediately on the next start, then refreshes in the background.
* **No app update needed**: branding, colours, layout, categories, websites, images and links are all data.
* **Forward/backward compatible**: unknown fields are ignored by the app; missing fields get defaults. The document carries `schema_version` for breaking changes.

### Request flow

```
App start
  ├─ LocalStore has cached config?  ── yes ─▶ render it (source = cache)
  │                                   no  ─▶ render bundled demo JSON (source = bundled)
  └─ API_BASE_URL set? ─ yes ─▶ GET /api/v1/config  (If-None-Match: <etag>)
                                   ├─ 200 → validate → cache → re-render (source = network)
                                   ├─ 304 → keep current
                                   └─ error → keep current, show offline icon
App resumes from background and data older than 5 min → refresh again
Pull-to-refresh → forced refresh
```

## 1.2 Repository layout

```
all-day-news/
├── app/                      Flutter app (Android + iOS)
├── backend/                  FastAPI service
├── admin/                    React admin panel
├── deploy/                   docker-compose, Caddy, backup script
├── docs/                     this documentation
├── store-assets/             Play Store icon & feature graphic
├── .github/workflows/        CI: backend, admin, mobile (APK/AAB/iOS)
├── BUILD_INSTRUCTIONS.md     how to build APK / AAB / IPA
└── README.md
```

## 1.3 Backend (`backend/`)

**Stack:** Python 3.12, FastAPI, SQLAlchemy 2 (typed ORM), Alembic migrations, Pydantic v2 validation, PyJWT, bcrypt, Pillow, Uvicorn. PostgreSQL in production, SQLite for development and tests.

```
backend/
├── app/
│   ├── main.py                 create_app(): middleware, routers, static files, start-up tasks
│   ├── web.py                  /privacy-policy HTML page and / index
│   ├── cli.py                  python -m app.cli init|migrate|create-admin|reset-password|seed-demo
│   ├── core/
│   │   ├── config.py           Settings from environment (.env); production safety checks
│   │   └── security.py         bcrypt hashing, JWT create/verify, LoginThrottle
│   ├── db/session.py           engine, SessionLocal, Base, get_db dependency
│   ├── models/                 ORM tables (one file per table)
│   ├── schemas/                Pydantic request/response models and validators
│   │   ├── common.py           Color, WebUrl, MediaUrl types, slugify
│   │   └── settings.py         all admin-editable app settings with defaults
│   ├── services/               business logic, independent of HTTP
│   │   ├── config_bundle.py    builds the public /config document + version hash
│   │   ├── storage.py          upload validation (magic bytes, Pillow) + Storage protocol
│   │   ├── settings_service.py load/save settings sections
│   │   ├── ordering.py         display-order helpers
│   │   ├── audit.py            activity log
│   │   ├── seed.py             demo content
│   │   └── bootstrap.py        migrations, first admin, demo data
│   └── api/
│       ├── deps.py             DbSession, CurrentAdmin, OwnerAdmin dependencies
│       └── v1/
│           ├── router.py       mounts public + /admin routers
│           └── endpoints/      public, auth, dashboard, categories, sites, media, settings, admins
├── alembic/versions/           database migrations
└── tests/                      pytest suite (runs on SQLite and PostgreSQL)
```

**Layering rule:** endpoints validate input (schemas), call services or the ORM, record an audit entry and commit. Services never import FastAPI. This keeps logic reusable from the CLI, tests and future background jobs.

**Security features:**
* bcrypt (cost 12) password hashes; constant-time login (dummy hash for unknown e-mails).
* Short JWT access tokens with a per-user `token_version`: changing a password, disabling a user or "sign out everywhere" invalidates every existing token.
* Login throttling: 5 failures per e-mail+IP, then a 5-minute lock (`LOGIN_MAX_ATTEMPTS`, `LOGIN_LOCKOUT_SECONDS`).
* Roles: `owner` (everything) and `editor` (content); the last active owner cannot be removed or demoted.
* Uploads: size limit, type detected from **file content** (not name), images fully decoded with Pillow, decompression-bomb guard, random file names, served with `nosniff` and a sandboxing CSP. SVG is rejected (it can carry scripts).
* URL validation: websites must be `http(s)://`; `javascript:` and other schemes are rejected.
* Security headers (`X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, HSTS in production), strict CORS allow-list, generic 500 responses (details only in server logs).
* Production refuses to start with the default or a short `SECRET_KEY`.

## 1.4 Admin Panel (`admin/`)

**Stack:** React 19, TypeScript (strict), Vite, React Router, dnd-kit (accessible drag and drop). No UI framework; a small design system lives in `src/styles/app.css` (CSS variables, dark and light).

```
admin/src/
├── main.tsx / App.tsx        router, navigation shell, auth gate
├── api/client.ts             typed fetch wrapper, token storage, error formatting
├── api/types.ts              TypeScript mirror of the API schemas
├── lib/auth.tsx              AuthProvider (login/logout/me)
├── lib/color.ts              #AARRGGBB ↔ CSS helpers, formatting
├── lib/icons.ts              category icon list (mirrors the Flutter icon registry)
├── components/               ui.tsx (fields, toggles, modal…), Media.tsx (upload, library, picker),
│                             Sortable.tsx (drag & drop), PhonePreview.tsx (live app mock-up), toast.tsx
└── pages/                    Dashboard, Categories, Sites, Featured, MediaLibrary, Settings (5 sections),
                              Admins, Account, Login
```

## 1.5 Mobile app (`app/`)

**Stack:** Flutter 3.47 / Dart 3.13, Riverpod 3 (state), go_router (navigation), http, shared_preferences (local storage), cached_network_image (images and animated GIF/WebP), video_player (MP4/WebM animations), webview_flutter (embedded browser), url_launcher (Custom Tabs / Safari View / external), share_plus, package_info_plus.

```
app/lib/
├── main.dart                 bootstrap: error handlers, edge-to-edge, SharedPreferences, ProviderScope
├── app.dart                  MaterialApp.router; theme built from admin settings
├── router.dart               all routes (bottom-nav shell + category + browser)
├── core/
│   ├── config/env.dart       --dart-define values (API_BASE_URL, APP_FLAVOR), timeouts
│   ├── network/              ApiClient (timeouts, ETag, error mapping), ApiException
│   ├── theme/                AppTheme (ThemeData + AppVisuals extension), colour parsing
│   ├── utils/                icon registry, text helpers
│   └── widgets/              reusable UI: NetMedia, SiteLogo, Pressable, FadeIn, AppBackground,
│                             BadgeChip, StatusView
├── data/
│   ├── models/app_config.dart   tolerant models: AppConfig, AppSettings (+sections), Category, Site
│   ├── repositories/config_repository.dart  offline-first config loading
│   ├── local/local_store.dart   cache, favourites, recents (on-device only)
│   └── providers.dart           Riverpod providers & controllers
└── features/
    ├── shell/                bottom navigation (Home, Search, Favourites, About)
    ├── home/                 home screen + widgets (featured carousel/grid, tabs, site cards, actions)
    ├── category/             full category list
    ├── search/               instant local search
    ├── favorites/            user bookmarks (reorder, swipe to delete)
    ├── browser/              LinkOpener (open-mode logic) + BrowserScreen (WebView)
    └── about/                about, privacy/terms/contact links, refresh, licences
```

**Feature-first structure:** each feature folder owns its screens and widgets. Shared code lives in `core/` (no business logic) and `data/` (models, repositories, providers). A new feature is a new folder plus a route.

**State management:**
* `configProvider` (`AsyncNotifier<ConfigSnapshot>`): the configuration plus its source and the last error.
* `appConfigProvider`: convenience read-only `AppConfig?`.
* `favoritesProvider`, `recentsProvider`: lists of site ids persisted in `LocalStore`.
* The `MaterialApp` watches the config, so admin theme changes re-theme the whole app instantly.

**Open modes** (`features/browser/link_opener.dart`):

| Mode | Android | iOS | Notes |
|---|---|---|---|
| `custom_tab` (default) | Chrome Custom Tab | SFSafariViewController | Browser-grade security and sign-ins, store-review friendly |
| `in_app` | WebView screen | WKWebView screen | Own toolbar, back/forward, share, favourites, inline/full-screen video. HTTPS only |
| `external` | default browser / app | Safari / app | Leaves the app |
| `default` | uses *Browser → default open mode* from settings | | |

**Accessibility:** semantic labels on every card and button, header semantics, large-font support (layouts measure text scale; capped at 160%), "remove animations" respected, contrast-aware text on coloured backgrounds, minimum 48 dp touch targets on controls, screen-reader friendly navigation bar.

## 1.6 Data contract: `GET /api/v1/config`

See [05-api-reference.md](05-api-reference.md#public-endpoints). The Flutter models in `app/lib/data/models/app_config.dart`, the TypeScript types in `admin/src/api/types.ts` and the Pydantic schemas in `backend/app/schemas/` describe the same shapes. When you add a field, update all three (see [13-extending.md](13-extending.md)).

## 1.7 Configuration principles

| Concern | Where |
|---|---|
| Backend environment (DB, secrets, URLs) | Environment variables / `backend/.env` ([03-backend-setup.md](03-backend-setup.md)) |
| App build-time settings | `--dart-define` / `app/env/*.json` (`API_BASE_URL`, `APP_FLAVOR`) |
| Admin panel API location | `VITE_API_BASE_URL` (empty = same domain) |
| Everything users see (branding, theme, layout, content) | Admin Panel → database |
| Secrets (keystore, passwords) | Never in git: `.env`, `key.properties`, CI secrets |
