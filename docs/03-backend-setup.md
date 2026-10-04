# 3. Backend Setup Guide

The backend is a single Python service (FastAPI). It needs a database (PostgreSQL in production) and a writable folder for uploaded media.

## 3.1 Environment variables

All settings come from environment variables; a `backend/.env` file is read too (real environment variables take precedence). Template: [`backend/.env.example`](../backend/.env.example).

| Variable | Default | Description |
|---|---|---|
| `APP_ENV` | `development` | `development`, `staging`, `production`, `test`. Production enables HSTS and enforces a strong `SECRET_KEY`. |
| `DATABASE_URL` | `sqlite:///./data/allinone.db` | SQLAlchemy URL. PostgreSQL: `postgresql+psycopg://USER:PASS@HOST:5432/DB` |
| `SECRET_KEY` | insecure placeholder | Signs admin login tokens. **Required in production**, ≥ 32 random characters (`openssl rand -hex 48`). Changing it signs everybody out. |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | `720` | Admin session length (12 h). |
| `PUBLIC_BASE_URL` | `http://localhost:8000` | Public URL of the API, used to build absolute media URLs for the app, e.g. `https://news.example.com`. |
| `CORS_ORIGINS` | `http://localhost:5173,http://localhost:8080` | Browser origins allowed to call the API (the admin panel's origin when it is on another domain). |
| `MEDIA_ROOT` | `./uploads` | Folder for uploaded files. Persist and back it up. |
| `MAX_UPLOAD_MB` | `25` | Upload size limit per file. |
| `FIRST_ADMIN_EMAIL` / `FIRST_ADMIN_PASSWORD` | empty | Creates the first **owner** when no administrator exists. Remove after first start. |
| `SEED_DEMO_DATA` | `true` | Insert demo categories/websites into an **empty** database. |
| `AUTO_MIGRATE` | `true` | Apply migrations + bootstrap on start-up. The Docker image sets `false` and runs `python -m app.cli init` once before starting workers. |
| `ADMIN_STATIC_DIR` | empty | Serve a built admin panel from the API at `/admin` (e.g. `../admin/dist`). |
| `LOGIN_MAX_ATTEMPTS` / `LOGIN_LOCKOUT_SECONDS` | `5` / `300` | Brute-force protection. |
| `WEB_CONCURRENCY` | `2` (Docker) | Number of Uvicorn worker processes. |

## 3.2 Run locally

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env
uvicorn app.main:app --reload
```

## 3.3 Command-line tools

```bash
python -m app.cli init                         # migrate + first admin + demo data (idempotent)
python -m app.cli migrate                      # apply database migrations only
python -m app.cli create-admin you@example.com --name "Your Name" --role owner
python -m app.cli reset-password you@example.com   # also unlocks/reactivates the account
python -m app.cli seed-demo                    # demo data (only if there is no content yet)
```

With Docker: `docker compose exec api python -m app.cli <command>`.

## 3.4 Run with PostgreSQL (without Docker)

```bash
sudo -u postgres psql -c "CREATE USER allinone WITH PASSWORD 'strong-password';"
sudo -u postgres psql -c "CREATE DATABASE allinone OWNER allinone;"
export DATABASE_URL=postgresql+psycopg://allinone:strong-password@localhost:5432/allinone
python -m app.cli init
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 2 --proxy-headers
```

## 3.5 Running in production

The recommended way is the Docker Compose stack in [`deploy/`](../deploy/) (PostgreSQL + API + Admin + Caddy HTTPS). See [09-deployment.md](09-deployment.md).

If you run it yourself:
* Put it behind a reverse proxy that terminates **HTTPS** (Caddy, Nginx, a cloud load balancer). Pass `X-Forwarded-*` headers (`--proxy-headers`).
* Set `APP_ENV=production`, a strong `SECRET_KEY`, `PUBLIC_BASE_URL=https://…`.
* Persist `MEDIA_ROOT` and the database; back both up ([12-maintenance-troubleshooting.md](12-maintenance-troubleshooting.md)).
* Run `python -m app.cli init` before starting multiple workers.
* The login throttle is per process. With many workers or servers, put a shared store behind `LoginThrottle` (e.g. Redis) or rate-limit `/api/v1/admin/auth/login` at the proxy.

## 3.6 Media storage

Uploaded files are stored by `LocalStorage` in `MEDIA_ROOT` and served at `/uploads/<random>.<ext>` with a one-year immutable cache header (names are never reused). To use S3, Cloudflare R2, Google Cloud Storage or a CDN, implement the two-method `Storage` protocol in `app/services/storage.py` (`save(data, extension) -> (key, public_url)`, `delete(key)`) and return it from `get_storage()`. Records store the public URL, so nothing else changes.

Accepted formats: **PNG, JPG, WebP, GIF** (including animated GIF/WebP) and **MP4, WebM** videos. SVG is intentionally not accepted.

## 3.7 Health checks and logs

* `GET /api/v1/health` → `{"status":"ok"}` (used by Docker health checks and uptime monitors).
* Logs go to stdout in the format `time LEVEL logger: message`. Unhandled errors are logged with a stack trace; clients receive a generic message.
* API docs: `/docs` (Swagger UI), `/redoc`, `/openapi.json`. These are public and contain no secrets. To hide them, set `docs_url=None` in `app/main.py` or block the paths at the proxy.
