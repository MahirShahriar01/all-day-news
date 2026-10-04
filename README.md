# All in One News

**Every channel. One place.** A mobile app for Android and iOS that shows news channels, news websites, live streams, sports, technology, education and other information services as cards. A web **Admin Panel** controls everything in the app, and changes reach users' phones without an app update.

| Part | Folder | Technology |
|---|---|---|
| Mobile app (Android + iOS from one codebase) | [`app/`](app/) | Flutter 3.47 · Riverpod · go_router · WebView / Custom Tabs |
| Backend API (versioned, `/api/v1`) | [`backend/`](backend/) | Python 3.12 · FastAPI · SQLAlchemy · Alembic · PostgreSQL |
| Admin Panel | [`admin/`](admin/) | React 19 · TypeScript · Vite |
| Production deployment | [`deploy/`](deploy/) | Docker Compose · PostgreSQL · Caddy (automatic HTTPS) |
| CI and app builds | [`.github/workflows/`](.github/workflows/) | GitHub Actions (APK, AAB, iOS check) |
| Store graphics | [`store-assets/`](store-assets/) | Play icon 512×512, feature graphic 1024×500 |

```
          ┌──────────────────────┐   HTTPS JSON (ETag-cached)   ┌─────────────────────┐
 Phone ─▶ │ Flutter app          │ ───── GET /api/v1/config ───▶│ FastAPI backend     │──▶ PostgreSQL
          │ offline cache + demo │ ◀──── media /uploads/... ────│ /api/v1 + /uploads  │──▶ uploads volume
          └──────────────────────┘                              └─────────▲───────────┘
                                                                          │ /api/v1/admin/* (JWT)
                                                               ┌──────────┴──────────┐
                                                  Browser ───▶ │ Admin Panel (React) │
                                                               └─────────────────────┘
```

## Quick start (local, about 5 minutes)

```bash
# 1. Backend (http://localhost:8000)
cd backend
python3 -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
uvicorn app.main:app --reload

# 2. Admin Panel (http://localhost:5173/admin/, sign in with FIRST_ADMIN_* from backend/.env)
cd admin
npm install
npm run dev

# 3. Mobile app (Android emulator; 10.0.2.2 = your computer)
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Build the app

**→ See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)** for the APK, the Play Store `.aab`, and the iOS / App Store build.

Every push also builds a ready-to-install **APK** and an **AAB** in GitHub Actions (*Actions → Mobile app → latest run → Artifacts*).

## Documentation

| # | Document | For |
|---|---|---|
| 1 | [Architecture & source code](docs/01-architecture.md) | Developers |
| 2 | [Development environment & project setup](docs/02-development-setup.md) | Developers |
| 3 | [Backend setup](docs/03-backend-setup.md) | Developers / DevOps |
| 4 | [Database](docs/04-database.md) | Developers |
| 5 | [API reference](docs/05-api-reference.md) | Developers |
| 6 | [Admin Panel (technical)](docs/06-admin-panel.md) | Developers |
| 7 | [**User Manual**](docs/07-user-manual.md) | App users |
| 8 | [**Admin User Guide**](docs/08-admin-guide.md) | Administrators (non-technical) |
| 9 | [Deployment & production](docs/09-deployment.md) | DevOps |
| 10 | [Google Play release guide](docs/10-play-store-release.md) | Publisher |
| 11 | [Apple App Store release guide](docs/11-app-store-release.md) | Publisher |
| 12 | [Maintenance & troubleshooting](docs/12-maintenance-troubleshooting.md) | Everyone |
| 13 | [Extending the app (future development)](docs/13-extending.md) | Developers |

## Before you publish

1. Change the app ID `com.allinonenews.app` to your own (see [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md#1-choose-your-app-id)).
2. Deploy the backend over **HTTPS** and build the app with `API_BASE_URL` set to it.
3. Replace the demo websites with services you are allowed to feature, and read the **content policy** section of the [Play guide](docs/10-play-store-release.md#3-content--webview-policy-read-this-first).
4. Fill in *Privacy & legal* in the Admin Panel. Your privacy policy is served at `https://<your-domain>/privacy-policy`.

## Tests

```bash
cd backend && pytest                    # API: 19 tests (SQLite; set TEST_DATABASE_URL for PostgreSQL)
cd admin && npm run build               # type-check + production build
cd app && flutter analyze && flutter test   # 14 unit + widget tests
```
