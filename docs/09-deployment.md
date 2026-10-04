# 9. Deployment & Production Deployment Guide

This guide puts the backend and Admin Panel online with HTTPS, so the mobile app can use them.

## 9.1 What you need

* A Linux server (VPS) with **2 GB RAM**, 1–2 vCPU and 20 GB+ disk. Any provider works (Hetzner, DigitalOcean, AWS Lightsail, Linode, Vultr…); Ubuntu 24.04 LTS recommended.
* A **domain name**, e.g. `news.example.com`, with a DNS **A record** pointing to the server's IP (and AAAA for IPv6 if available).
* Ports **80** and **443** open.

## 9.2 Install Docker

```bash
ssh root@your-server
curl -fsSL https://get.docker.com | sh
# optional: a non-root user
adduser deploy && usermod -aG docker deploy && su - deploy
```

## 9.3 Get the code and configure

```bash
git clone https://github.com/<you>/all-day-news.git /opt/all-in-one-news
cd /opt/all-in-one-news/deploy
cp .env.example .env
nano .env
```

Set at least:

```ini
DOMAIN=news.example.com
ACME_EMAIL=you@example.com
POSTGRES_PASSWORD=<openssl rand -hex 24>
SECRET_KEY=<openssl rand -hex 48>
FIRST_ADMIN_EMAIL=you@example.com
FIRST_ADMIN_PASSWORD=<a strong temporary password>
SEED_DEMO_DATA=true          # false for an empty start
```

## 9.4 Start

```bash
docker compose up -d --build
docker compose ps            # all services "running"/"healthy"
docker compose logs -f api   # Ctrl+C to stop following
```

Caddy obtains a Let's Encrypt certificate automatically on first request (this takes a few seconds). Then check:

| URL | Expect |
|---|---|
| `https://news.example.com/api/v1/health` | `{"status":"ok"}` |
| `https://news.example.com/api/v1/config` | the JSON feed |
| `https://news.example.com/admin/` | the sign-in page |
| `https://news.example.com/privacy-policy` | the privacy policy |

Sign in, **change the password** (*My account*), then remove `FIRST_ADMIN_PASSWORD` from `.env`.

## 9.5 Architecture of the stack

```
Internet ─▶ Caddy :443 (TLS, HSTS, gzip/zstd, 30 MB upload limit)
              ├─ /api/*, /uploads/*, /privacy-policy, /docs ─▶ api:8000 (FastAPI, 2 workers)
              │                                                  ├─▶ db (PostgreSQL 16, volume db-data)
              │                                                  └─▶ volume uploads
              ├─ /admin* ─▶ admin:80 (Nginx serving the built React app)
              └─ /       ─▶ redirect to /admin/
```

The API container runs `python -m app.cli init` (migrations, first admin, demo data) and then starts Uvicorn as a non-root user. Data lives in Docker volumes `db-data`, `uploads`, `caddy-data`.

## 9.6 Build the app for this server

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://news.example.com
```

or set the GitHub repository variable `API_BASE_URL=https://news.example.com` and let CI build it ([BUILD_INSTRUCTIONS.md](../BUILD_INSTRUCTIONS.md)).

## 9.7 Updating to a new version

```bash
cd /opt/all-in-one-news
./deploy/backup.sh               # always back up first (run from deploy/)
git pull
cd deploy && docker compose up -d --build
docker compose logs --tail=50 api
```

Migrations run automatically. Rolling back: `git checkout <previous-tag>`, rebuild, and restore the backup if a migration changed data.

## 9.8 Backups

`deploy/backup.sh` writes `backups/<timestamp>/database.dump` and `uploads.tar.gz` and keeps the last 14. Schedule it daily:

```bash
crontab -e
0 3 * * * cd /opt/all-in-one-news/deploy && ./backup.sh >> backups/backup.log 2>&1
```

**Copy backups off the server** (e.g. `rclone` to S3/Backblaze/Google Drive). A backup on the same disk does not survive a server loss. Test a restore occasionally ([04-database.md](04-database.md#44-backup--restore)).

## 9.9 Security checklist

- [ ] Strong unique `SECRET_KEY` and `POSTGRES_PASSWORD`; `.env` readable only by you (`chmod 600 .env`).
- [ ] First admin password changed; every admin has their own account.
- [ ] Server: automatic security updates (`apt install unattended-upgrades`), SSH keys only, firewall allowing 22/80/443 (`ufw allow OpenSSH; ufw allow 80; ufw allow 443; ufw enable`).
- [ ] Optional: restrict `/admin` and `/api/v1/admin` to known IPs ([06-admin-panel.md](06-admin-panel.md#63-authentication-flow)).
- [ ] Daily off-site backups.
- [ ] Uptime monitor on `/api/v1/health` (UptimeRobot, Better Stack…).
- [ ] Keep images up to date: `docker compose pull && docker compose up -d --build` monthly.

## 9.10 Scaling

The app makes one cheap, cacheable request per launch, so a small server serves many users. When you grow:

1. **CDN in front** (Cloudflare or similar): cache `/uploads/*` (immutable) and `/api/v1/config` (respects `Cache-Control: max-age=60`).
2. **Object storage** for media (implement `Storage` for S3/R2, see [03-backend-setup.md](03-backend-setup.md#36-media-storage)).
3. **Managed PostgreSQL** (point `DATABASE_URL` at it).
4. **More API instances** behind a load balancer (the API is stateless apart from the per-process login throttle; move it to Redis).

## 9.11 Alternative hosting

* **Platform-as-a-Service** (Render, Railway, Fly.io, Google Cloud Run): deploy `backend/` with its Dockerfile, add a managed PostgreSQL, set the environment variables from [03-backend-setup.md](03-backend-setup.md), mount persistent storage (or use object storage) for `/app/uploads`, and serve the admin panel via `ADMIN_STATIC_DIR` or static hosting.
* **Without Docker:** see [03-backend-setup.md §3.4](03-backend-setup.md#34-run-with-postgresql-without-docker) and run Uvicorn under systemd behind Nginx/Caddy.
