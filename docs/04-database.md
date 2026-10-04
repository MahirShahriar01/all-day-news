# 4. Database Documentation

**Engine:** PostgreSQL 16 in production (SQLite supported for development and tests).
**ORM:** SQLAlchemy 2 models in `backend/app/models/`.
**Migrations:** Alembic, `backend/alembic/versions/`. Applied automatically on start-up (`AUTO_MIGRATE=true`) or by `python -m app.cli migrate`.

## 4.1 Entity-relationship diagram

```
┌──────────────────┐ 1      n ┌─────────────────────┐
│ categories       │──────────│ sites               │
│──────────────────│          │─────────────────────│
│ id PK            │          │ id PK               │
│ name             │          │ category_id FK NULL │──▶ ON DELETE SET NULL
│ slug UNIQUE      │          │ title, url          │
│ description      │          │ description         │
│ icon_name        │          │ logo_url            │
│ icon_url         │          │ background_url      │
│ background_url   │          │ animation_url       │
│ color            │          │ accent_color, badge │
│ sort_order (idx) │          │ tags, open_mode     │
│ is_enabled       │          │ is_featured (idx)   │
│ created/updated  │          │ featured_order      │
└──────────────────┘          │ sort_order (idx)    │
                              │ is_enabled          │
                              │ created/updated     │
                              └─────────────────────┘

┌──────────────────┐ 1      n ┌─────────────────────┐        ┌──────────────────┐
│ admin_users      │──────────│ audit_logs          │        │ app_settings     │
│──────────────────│          │─────────────────────│        │──────────────────│
│ id PK            │          │ id PK               │        │ key PK           │
│ email UNIQUE     │          │ admin_id FK NULL    │        │ value JSON       │
│ full_name        │          │ admin_email         │        │ updated_at       │
│ password_hash    │          │ action, entity      │        └──────────────────┘
│ role             │          │ entity_id, summary  │
│ is_active        │          │ created_at (idx)    │
│ token_version    │          └─────────────────────┘
│ last_login_at    │ 1      n ┌─────────────────────┐
│ created/updated  │──────────│ media_assets        │
└──────────────────┘          │ id PK               │
                              │ kind, storage_key U │
                              │ url, mime_type      │
                              │ size_bytes, w, h    │
                              │ original_name       │
                              │ uploaded_by_id FK   │
                              │ created_at          │
                              └─────────────────────┘
```

## 4.2 Tables

### `categories`
| Column | Type | Notes |
|---|---|---|
| `id` | integer PK | |
| `name` | varchar(80) | shown in the app tabs |
| `slug` | varchar(100) UNIQUE | URL-friendly name, generated from `name`, de-duplicated (`news`, `news-2`) |
| `description` | text | optional |
| `icon_name` | varchar(60) | built-in icon (see `admin/src/lib/icons.ts`) |
| `icon_url`, `background_url` | varchar(500) | `/uploads/...` or absolute URL, may be empty |
| `color` | varchar(9) | `#AARRGGBB` or empty |
| `sort_order` | integer, indexed | ascending display order |
| `is_enabled` | boolean | disabled categories and their websites are hidden from the app |
| `created_at`, `updated_at` | timestamptz | UTC |

### `sites` (websites / channels / services)
| Column | Type | Notes |
|---|---|---|
| `id` | integer PK | |
| `category_id` | FK → categories.id, NULL, indexed | `ON DELETE SET NULL` (deleting a category never silently deletes websites) |
| `title` | varchar(120) | |
| `url` | varchar(2000) | validated `http(s)://` |
| `description` | text | |
| `logo_url`, `background_url`, `animation_url` | varchar(500) | images, GIF, or MP4/WebM for `animation_url` |
| `accent_color` | varchar(9) | `#AARRGGBB` |
| `badge` | varchar(20) | e.g. `LIVE`, `NEW` |
| `tags` | varchar(300) | comma-separated search keywords |
| `open_mode` | varchar(20) | `default`, `in_app`, `custom_tab`, `external` |
| `is_featured` | boolean, indexed | shown in the Featured section |
| `featured_order` | integer | order within Featured |
| `sort_order` | integer, indexed | order within its category |
| `is_enabled` | boolean | hidden from the app when false |

### `media_assets`
Uploaded files. `storage_key` is the random file name (unique); `url` is what other tables reference (`/uploads/<key>`). `kind` is `image`, `animation` (GIF/animated WebP) or `video`.

### `app_settings`
Key/value store. Each key holds one JSON document validated by a Pydantic model in `backend/app/schemas/settings.py`:

| key | Contents |
|---|---|
| `branding` | app_name, tagline, logo_url, splash_image_url |
| `theme` | mode, primary/secondary/accent/background/surface/text colours, gradient, corner_radius, card_style, enable_animations |
| `layout` | home background + opacity, featured settings, search, tabs, grid columns, descriptions, announcement |
| `browser` | default_open_mode, toolbar, external-browser and share permissions |
| `legal` | privacy/terms URLs, contact e-mail, publisher, about text, privacy policy text |

Missing keys or fields get defaults, so **new settings need no migration**.

### `admin_users`
`role` is `owner` or `editor`. `password_hash` is bcrypt. `token_version` increments on password change, deactivation or "sign out everywhere", which invalidates older tokens.

### `audit_logs`
One row per change or login, shown on the dashboard ("Recent activity"). `admin_email` is copied so the history survives deleting an administrator.

## 4.3 Migrations

```bash
cd backend
# after changing a model:
alembic revision --autogenerate -m "add sites.language"
# review the generated file in alembic/versions/, then:
alembic upgrade head          # or python -m app.cli migrate
alembic downgrade -1          # undo the last migration
alembic current / history     # inspect
```

Rules:
* Never edit a migration that has run in production; add a new one.
* `render_as_batch=True` is enabled, so migrations also work on SQLite.
* For new non-null columns, give a `server_default` so existing rows are valid.
* Keep the app's JSON (`/config`) backward compatible: add fields, don't rename or remove them (see [13-extending.md](13-extending.md)).

## 4.4 Backup & restore

```bash
# Backup (Docker stack): database + uploads → deploy/backups/<timestamp>/
cd deploy && ./backup.sh

# Restore database
docker compose exec -T db pg_restore -U allinone -d allinone --clean --if-exists < backups/<ts>/database.dump
# Restore uploads
docker compose exec -T api tar -C /app -xzf - < backups/<ts>/uploads.tar.gz
```

Plain PostgreSQL: `pg_dump -Fc allinone > db.dump` / `pg_restore -d allinone --clean db.dump`.

## 4.5 Useful queries

```sql
-- Websites per category
SELECT c.name, count(s.id) FROM categories c LEFT JOIN sites s ON s.category_id = c.id GROUP BY c.name ORDER BY 2 DESC;
-- Hidden websites
SELECT id, title, url FROM sites WHERE NOT is_enabled;
-- Media not referenced anywhere (candidates for clean-up)
SELECT m.id, m.url FROM media_assets m
WHERE NOT EXISTS (SELECT 1 FROM sites s WHERE m.url IN (s.logo_url, s.background_url, s.animation_url))
  AND NOT EXISTS (SELECT 1 FROM categories c WHERE m.url IN (c.icon_url, c.background_url));
```
