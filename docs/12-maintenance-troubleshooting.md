# 12. Maintenance & Troubleshooting Guide

## 12.1 Routine maintenance

| How often | Task |
|---|---|
| Daily (automatic) | `deploy/backup.sh` via cron; copy backups off the server |
| Weekly | Check the dashboard's recent activity; open a few channels to catch broken links |
| Monthly | `docker compose pull && docker compose up -d --build`; OS updates; test-restore a backup |
| Each release | Update Flutter (`flutter upgrade`), `flutter pub upgrade --major-versions`, run tests, rebuild |
| Yearly (before 31 Aug) | Raise Android `targetSdk` to Google's new requirement |
| Yearly (spring) | Rebuild iOS with the latest Xcode as Apple requires |
| As needed | Rotate `SECRET_KEY` (signs everyone out), remove departed administrators |

### Dependency updates

```bash
# Backend
cd backend && pip list --outdated
#   edit versions in requirements.txt → pip install -r requirements-dev.txt → pytest
# Admin
cd admin && npm outdated && npm update && npm run build
# App
cd app && flutter upgrade && flutter pub outdated && flutter pub upgrade --major-versions
flutter analyze && flutter test
```

Update `FLUTTER_VERSION` in `.github/workflows/mobile.yml` when you move to a new Flutter release.

### Finding broken links

```bash
curl -s https://news.example.com/api/v1/config | python3 -c '
import json,sys,urllib.request
for s in json.load(sys.stdin)["sites"]:
    try:
        code = urllib.request.urlopen(urllib.request.Request(s["url"], method="HEAD", headers={"User-Agent":"Mozilla/5.0"}), timeout=10).status
    except Exception as e:
        code = e
    print(code, s["title"], s["url"])'
```

## 12.2 Logs

```bash
cd deploy
docker compose logs -f api          # API (requests, errors with stack traces)
docker compose logs -f caddy        # HTTPS / certificates / proxy
docker compose logs -f db           # database
docker compose ps                   # health status
```

## 12.3 Troubleshooting: server

| Problem | Cause & fix |
|---|---|
| `docker compose up` fails: "set SECRET_KEY in .env" | Fill in `deploy/.env` (§9.3). |
| API exits: "SECRET_KEY must be set…" | Production needs a random key of ≥ 32 characters. |
| HTTPS certificate not issued | DNS A record must point to the server; ports 80/443 open; check `docker compose logs caddy`. Let's Encrypt rate-limits repeated failures, so fix DNS first. |
| 502 Bad Gateway | API not running or unhealthy: `docker compose logs api`. Often the database password changed after the DB volume was created (it keeps the first one). Use the old password, or reset with `docker compose down -v` (**deletes data**). |
| Admin login: "Incorrect e-mail or password" | `docker compose exec api python -m app.cli reset-password you@example.com` |
| "Too many failed attempts" | Wait 5 minutes, or restart the API (`docker compose restart api`). |
| No administrator exists | `docker compose exec api python -m app.cli create-admin you@example.com --role owner` |
| Upload fails: "File is too large" | Raise `MAX_UPLOAD_MB` in `.env` **and** `request_body max_size` in the Caddyfile, then `docker compose up -d`. |
| Upload fails: "Unsupported file type" | Only PNG, JPG, WebP, GIF, MP4, WebM. Convert SVG/HEIC/AVIF to PNG/JPG first. |
| Images in the app point to `localhost` | `PUBLIC_BASE_URL` is wrong; set it to `https://your-domain` and restart. |
| Admin panel on another domain shows "Cannot reach the server" | Add the panel's origin to `CORS_ORIGINS`. |
| Disk full | `docker system prune` (unused images), delete unused media, move old backups off the server. |
| Migration error after an update | Restore the backup, report the error, or run `docker compose exec api alembic current` / `alembic upgrade head` manually to see details. |

## 12.4 Troubleshooting: mobile app

| Problem | Cause & fix |
|---|---|
| App shows demo content | Built without `--dart-define=API_BASE_URL=…`. Rebuild with it, or set the CI variable. |
| Offline (cloud) icon although online | API URL wrong, server down, or not HTTPS. Open `https://domain/api/v1/health` on the phone. Release builds block plain HTTP. |
| Changes in the admin panel don't appear | The app refreshes on start, on returning after 5 min, or on pull-to-refresh. Check `/api/v1/config` shows the change (is the item **enabled**? is its **category enabled**?). |
| Website opens in an external browser instead of inside the app | Plain `http://` sites can't be embedded (security); use `https://`. Or the open mode is *External*. |
| Embedded page is blank or says it can't be shown | Some sites forbid embedding (X-Frame/CSP) or block WebViews (e.g. Google sign-in). Use *In-app browser tab* for those. |
| Video won't play in the embedded browser | Some streams require their own app or DRM. Use *External* open mode for that site. |
| Logo not shown | URL unreachable, wrong format (SVG isn't supported), or very large file. Re-upload a PNG/WebP. |
| Text overflowing on small phones | Shorten titles (≤ 25 characters works best) or use fewer cards per row. |
| Android build errors | See [BUILD_INSTRUCTIONS.md §7](../BUILD_INSTRUCTIONS.md#7-common-build-problems). |
| Play Console: debug-signed | Configure `key.properties` / CI secrets. |
| Crash reports | Play Console → Android vitals; App Store Connect → TestFlight/Analytics crashes. For detailed reports add a crash reporter ([13-extending.md](13-extending.md#136-adding-analytics-or-crash-reporting)). |

## 12.5 Troubleshooting: development

| Problem | Fix |
|---|---|
| `ModuleNotFoundError: app` when running alembic | Run it from the `backend/` folder. |
| Emulator can't reach `localhost:8000` | Use `http://10.0.2.2:8000` (Android emulator) and run a **debug** build. |
| iOS simulator can't load `http://localhost` | ATS blocks HTTP; use an HTTPS tunnel. |
| Admin dev server 404 at `/` | Open `http://localhost:5173/admin/`. |
| `flutter test` widget tests hang on asset loading | Keep `setUp(rootBundle.clear)` in the test file. |

## 12.6 Getting help

Collect: what you did, what you expected, what happened, the time, screenshots, `docker compose logs --tail=200 api`, app version (*About*), phone model and OS version.
