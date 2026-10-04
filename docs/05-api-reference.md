# 5. API Reference (v1)

Base URL: `https://<your-domain>/api/v1`. All bodies are JSON (UTF-8) except media upload (multipart). Interactive documentation with "Try it out" is at **`/docs`**; the machine-readable spec is at `/openapi.json`.

**Versioning:** breaking changes go into `/api/v2` while `/api/v1` keeps serving installed app versions. Additive changes (new fields, new endpoints) happen within v1. Clients must ignore unknown fields.

**Errors:** `{"detail": "Human readable message"}`, or for validation errors (`422`) `{"detail": [{"loc": ["body","url"], "msg": "...", "type": "..."}]}`.

| Status | Meaning |
|---|---|
| 200 / 201 / 204 | OK / created / done with no body |
| 304 | Not modified (config ETag matched) |
| 400 | Request not allowed (e.g. removing the last owner) |
| 401 | Missing, invalid or expired token |
| 403 | Signed in but not allowed (editor calling an owner endpoint) |
| 404 | Not found |
| 409 | Conflict (duplicate e-mail, media still in use) |
| 422 | Validation error |
| 429 | Too many failed login attempts |

---

## Public endpoints

No authentication. Read-only. Only **enabled** content is returned.

### `GET /health`
`{"status": "ok"}`

### `GET /config`
The complete document the mobile app needs. Send `If-None-Match: "<etag>"` to get `304` when nothing changed. Cache headers: `max-age=60, stale-while-revalidate=600`.

```json
{
  "schema_version": 1,
  "version": "3f1c9a0b7d2e4c11",
  "generated_at": "2026-10-04T12:00:00+00:00",
  "settings": {
    "branding": { "app_name": "All in One News", "tagline": "Every channel. One place.", "logo_url": "https://…/uploads/a1.png", "splash_image_url": "" },
    "theme": { "mode": "dark", "primary_color": "#FF7C4DFF", "secondary_color": "#FF00E5FF", "accent_color": "#FFFF4081",
               "background_color": "#FF0A0E1A", "surface_color": "#FF141A2E", "text_color": "#FFF5F7FF",
               "gradient_start": "#FF7C4DFF", "gradient_end": "#FF00E5FF", "corner_radius": 20,
               "card_style": "glass", "enable_animations": true },
    "layout": { "home_background_url": "", "home_background_opacity": 0.35, "show_featured": true,
                "featured_title": "Featured", "featured_style": "carousel", "show_search": true,
                "show_category_tabs": true, "grid_columns": 3, "show_descriptions": true,
                "announcement": { "enabled": false, "text": "", "url": "" } },
    "browser": { "default_open_mode": "custom_tab", "show_toolbar": true,
                 "allow_open_in_external_browser": true, "allow_share": true },
    "legal": { "privacy_policy_url": "https://…/privacy-policy", "terms_url": "", "contact_email": "",
               "publisher_name": "", "about_text": "…" }
  },
  "categories": [
    { "id": 1, "name": "News", "slug": "news", "description": "…", "icon_name": "newspaper",
      "icon_url": "", "background_url": "", "color": "#FF7C4DFF" }
  ],
  "sites": [
    { "id": 1, "category_id": 1, "title": "BBC News", "url": "https://www.bbc.com/news",
      "description": "…", "logo_url": "", "background_url": "", "animation_url": "",
      "accent_color": "#FFBB1919", "badge": "", "tags": ["news"], "open_mode": "default", "is_featured": true }
  ],
  "featured": [1, 2, 6, 9]
}
```

* Arrays are already in display order.
* Media URLs are absolute (built from `PUBLIC_BASE_URL`).
* Colours are `#AARRGGBB` (or `#RRGGBB`), or empty for "automatic".
* `featured` lists site ids in featured order.
* `legal.privacy_policy_url` falls back to the built-in `/privacy-policy` page.

### `GET /categories`
Enabled categories in order (same objects as in `/config`).

### `GET /sites?category=<slug>&featured=<bool>&q=<text>`
Enabled websites in visible categories. `q` searches title, description and tags.

### `GET /privacy-policy` (outside `/api/v1`)
HTML privacy policy page, from *Privacy & legal → Privacy policy text* or a built-in default.

---

## Admin endpoints

Prefix `/api/v1/admin`. Header: `Authorization: Bearer <access_token>`.

### Authentication

| Method & path | Body | Response |
|---|---|---|
| `POST /auth/login` | `{"email","password"}` | `{"access_token","token_type":"bearer","expires_at","admin":{…}}` |
| `GET /auth/me` | | admin object |
| `POST /auth/change-password` | `{"current_password","new_password"}` (≥10 chars) | 204; signs out other sessions |
| `POST /auth/logout-all` | | 204; invalidates all tokens of this admin |

Admin object: `{id, email, full_name, role: "owner"|"editor", is_active, last_login_at, created_at}`.

### Dashboard
`GET /dashboard` → counts (`categories`, `categories_enabled`, `sites`, `sites_enabled`, `sites_featured`, `sites_uncategorised`, `media_files`, `media_bytes`) and `recent_activity[]`.

### Categories

| Method & path | Notes |
|---|---|
| `GET /categories` | all categories incl. disabled, with `site_count` |
| `POST /categories` | `{name, slug?, description?, icon_name?, icon_url?, background_url?, color?, is_enabled?, sort_order?}`; slug auto-generated and de-duplicated; appended at the end |
| `GET /categories/{id}` | |
| `PATCH /categories/{id}` | any subset of the fields |
| `DELETE /categories/{id}?move_sites_to=<id>` | move websites to another category first |
| `DELETE /categories/{id}?delete_sites=true` | delete its websites too |
| `DELETE /categories/{id}` | websites become uncategorised |
| `POST /categories/reorder` | `{"ids":[3,1,2]}`: new display order |

### Websites (sites)

| Method & path | Notes |
|---|---|
| `GET /sites?category_id=&uncategorised=&featured=&enabled=&q=&limit=&offset=` | `{items:[…], total}`; ordered by `sort_order` (or `featured_order` when `featured=true`) |
| `POST /sites` | `{title, url, category_id?, description?, logo_url?, background_url?, animation_url?, accent_color?, badge?, tags?, open_mode?, is_featured?, is_enabled?}` |
| `GET /sites/{id}` | |
| `PATCH /sites/{id}` | subset; `"category_id": null` removes the category |
| `DELETE /sites/{id}` | |
| `POST /sites/reorder` | `{"ids":[…]}`: order within a category (send the ids of one category) |
| `POST /sites/featured/reorder` | `{"ids":[…]}`: order of the Featured section |
| `POST /sites/bulk` | `{"ids":[…], "action":"enable"|"disable"|"feature"|"unfeature"|"delete"|"move", "category_id":…}` |

Validation: `url` must be `http://` or `https://`; colours `#RRGGBB`/`#AARRGGBB`; media fields must be empty, `/uploads/…` or `http(s)://…`; `category_id` must exist.

### Media library

| Method & path | Notes |
|---|---|
| `GET /media?kind=image|animation|video&limit=&offset=` | newest first, `{items, total}` |
| `POST /media` | multipart field `file`. PNG, JPG, WebP, GIF, MP4, WebM up to `MAX_UPLOAD_MB`. Returns `{id, kind, url, absolute_url, mime_type, size_bytes, width, height, original_name, created_at}` |
| `DELETE /media/{id}` | `409` if still referenced; add `?force=true` to delete anyway |

Use the returned `url` (`/uploads/…`) in category/website/settings fields.

### Settings

| Method & path | Notes |
|---|---|
| `GET /settings` | all sections with current values |
| `PUT /settings/{section}` | replace one section: `branding`, `theme`, `layout`, `browser`, `legal`. Omitted fields reset to defaults. |
| `GET /settings/preview` | exactly what `/config` returns |

### Administrators (owner only)

| Method & path | Notes |
|---|---|
| `GET /admins` | |
| `POST /admins` | `{email, full_name?, password, role}` |
| `PATCH /admins/{id}` | `{full_name?, role?, is_active?, password?}` |
| `DELETE /admins/{id}` | not yourself; never the last active owner |

---

## Examples

```bash
API=https://news.example.com/api/v1
TOKEN=$(curl -s -X POST $API/admin/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"admin@example.com","password":"…"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')

# Upload a logo
curl -s -H "Authorization: Bearer $TOKEN" -F file=@logo.png $API/admin/media

# Add a website
curl -s -X POST $API/admin/sites -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"title":"My Channel","url":"https://example.com/live","category_id":2,"badge":"LIVE","is_featured":true}'

# What the app sees
curl -s $API/config | head -c 400
```
