# 2. Development Environment & Project Setup

## 2.1 Required software

| Tool | Version | Used for | Install |
|---|---|---|---|
| Git | any recent | source control | https://git-scm.com |
| Python | 3.11 or 3.12 | backend | https://python.org |
| Node.js | 22 LTS | admin panel | https://nodejs.org |
| Flutter SDK | 3.47.x stable | mobile app | https://docs.flutter.dev/get-started/install |
| Android Studio | latest | Android SDK, emulator | https://developer.android.com/studio |
| JDK | 17 | Android builds (bundled with Android Studio) | |
| Xcode (macOS only) | latest | iOS builds, simulator | Mac App Store |
| CocoaPods (macOS only) | latest | iOS dependencies | `brew install cocoapods` |
| Docker Desktop (optional) | latest | running the production stack locally | https://docker.com |
| PostgreSQL (optional) | 16 | production-like database | or use SQLite in development |

Recommended editors: **VS Code** (extensions: Flutter, Dart, Python, ESLint) or **Android Studio** (Flutter plugin).

After installing Flutter run:

```bash
flutter doctor            # fix every item it reports for the platforms you need
flutter doctor --android-licenses
```

## 2.2 Get the code

```bash
git clone https://github.com/<you>/all-day-news.git
cd all-day-news
```

## 2.3 Backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate              # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env                   # defaults work for local development
uvicorn app.main:app --reload --port 8000
```

On first start the server:
1. creates `data/allinone.db` (SQLite) and applies migrations,
2. creates the administrator from `FIRST_ADMIN_EMAIL` / `FIRST_ADMIN_PASSWORD`,
3. inserts demo categories and websites (`SEED_DEMO_DATA=true`).

Check: http://localhost:8000/api/v1/config (app feed) and http://localhost:8000/docs (interactive API docs).

Run tests: `pytest` (or `TEST_DATABASE_URL=postgresql+psycopg://user:pw@localhost/db_test pytest`).

## 2.4 Admin Panel

```bash
cd admin
npm install
npm run dev                            # http://localhost:5173/admin/
```

The dev server proxies `/api`, `/uploads` and `/privacy-policy` to `http://localhost:8000`, so no CORS setup is needed. Sign in with the `FIRST_ADMIN_*` credentials.

Other commands: `npm run build` (type-check + production build into `dist/`), `npm run typecheck`, `npm run preview`.

To serve the built panel **from the API** (single process, handy for small servers): set `ADMIN_STATIC_DIR=../admin/dist` in `backend/.env`, run `npm run build`, restart the API and open http://localhost:8000/admin/.

## 2.5 Mobile app

```bash
cd app
flutter pub get
```

### Android emulator
Create one in Android Studio (*Device Manager → Create device*, e.g. Pixel 8, API 36) and start it. `10.0.2.2` is your computer from inside the emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
# or: cp env/development.example.json env/development.json
#     flutter run --dart-define-from-file=env/development.json
```

Plain `http://` is allowed **only in debug builds** and only for `10.0.2.2`/`localhost` (`android/app/src/debug/res/xml/network_security_config.xml`).

### Real Android phone
Enable *Developer options → USB debugging*, connect via USB, and use your computer's LAN address. HTTP to LAN addresses is blocked, so either use a tunnel with HTTPS (e.g. `cloudflared tunnel --url http://localhost:8000`, `ngrok http 8000`) or a deployed server:

```bash
flutter run --dart-define=API_BASE_URL=https://<your-tunnel>.trycloudflare.com
```

### iOS simulator (macOS)
```bash
open -a Simulator
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```
iOS blocks plain HTTP by default (ATS). For local development use an HTTPS tunnel as above, or temporarily add an ATS exception for `localhost` in a **debug-only** copy of Info.plist. Never ship it.

### Without a backend
`flutter run` with no `API_BASE_URL` shows the bundled demo content (`assets/config/fallback_config.json`).

### Useful commands

```bash
flutter analyze                      # static analysis (must be clean)
flutter test                         # unit + widget tests
dart format -l 120 lib test          # formatting used in this project
flutter run --release                # test release performance
dart run flutter_launcher_icons      # regenerate icons
dart run flutter_native_splash:create
```

## 2.6 Regenerating the bundled demo config

When you change the demo data or the config format, regenerate the offline fallback the app ships with:

```bash
cd backend
DATABASE_URL=sqlite:////tmp/gen.db PUBLIC_BASE_URL= python - <<'EOF'
import json
from app.db.session import SessionLocal
from app.services.bootstrap import run_migrations
from app.services.seed import seed_demo_content
from app.services.config_bundle import build_public_config
run_migrations()
with SessionLocal() as db:
    seed_demo_content(db); cfg = build_public_config(db)
cfg.pop("generated_at"); cfg["version"] = "bundled-demo"
cfg["settings"]["legal"]["privacy_policy_url"] = ""
open("../app/assets/config/fallback_config.json", "w").write(json.dumps(cfg, indent=1, ensure_ascii=False))
EOF
```

Tip: for your own release you can instead download your production feed (`curl https://your-domain/api/v1/config > app/assets/config/fallback_config.json`) so first-time offline users see your real content.

## 2.7 Coding conventions

* **Python:** type hints everywhere, one model per file, business logic in `services/`, 120-column lines.
* **TypeScript:** `strict` mode, no `any`, components small and typed, API types in `api/types.ts`.
* **Dart:** `flutter_lints` (analysis must be clean), `dart format -l 120`, feature-first folders, widgets `const` where possible, no business logic in widgets beyond presentation.
* **Commits:** small, descriptive messages; CI must be green.
