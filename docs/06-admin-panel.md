# 6. Admin Panel: Technical Documentation

> Looking for how to *use* the panel? See the [Admin User Guide](08-admin-guide.md).

## 6.1 Overview

A single-page application (React 19 + TypeScript + Vite) served under the path **`/admin/`**. It talks only to `/api/v1/admin/*` and `/api/v1/config`. There is no server-side rendering and no stored data besides the login token.

## 6.2 Pages

| Route | Page | API used |
|---|---|---|
| `/admin/` | Dashboard: counts, quick start, recent activity | `GET /dashboard` |
| `/admin/categories` | list, drag to reorder, show/hide, create/edit/delete (with move/delete options) | categories endpoints |
| `/admin/sites` | filter by category, search, drag to reorder within a category, quick feature/show toggles, bulk actions, editor with live card preview | sites endpoints |
| `/admin/featured` | featured order (drag), add/remove | `GET /sites?featured=true`, `/sites/featured/reorder`, `/sites/bulk` |
| `/admin/media` | upload (multi-file, drag & drop), filter, preview, copy link, delete | media endpoints |
| `/admin/branding`, `/theme`, `/layout`, `/browser`, `/legal` | settings sections with live phone preview | `GET /settings`, `PUT /settings/{section}` |
| `/admin/admins` | owners only: add/edit/disable/remove administrators | admins endpoints |
| `/admin/account` | change password, sign out everywhere | auth endpoints |

## 6.3 Authentication flow

1. `POST /auth/login` returns a JWT and its expiry.
2. The token is kept in `localStorage` (`aion.admin.token`) with its expiry, so a page reload keeps you signed in until it expires (12 h by default).
3. Every request sends `Authorization: Bearer …`. A `401` clears the token and shows the login page.
4. Changing the password or "sign out on all devices" bumps the server-side `token_version`, so stolen tokens stop working.

**Hardening options:**
* Serve the panel only over HTTPS (the Caddy setup does this).
* Restrict `/admin` and `/api/v1/admin` by IP at the proxy if your admins have fixed addresses, e.g. in the Caddyfile:
  ```
  @blocked { path /admin* /api/v1/admin/*
             not remote_ip 203.0.113.0/24 }
  respond @blocked 403
  ```
* Reduce `ACCESS_TOKEN_EXPIRE_MINUTES` for shorter sessions.
* The page sends `noindex` so search engines don't list it.

## 6.4 Configuration

| Variable | Default | Purpose |
|---|---|---|
| `VITE_API_BASE_URL` | empty | API origin when the panel is on a **different** domain (then add the panel's origin to the API's `CORS_ORIGINS`). Empty = same domain (recommended). |

Build-time only (`admin/.env`, or the environment during `npm run build`).

## 6.5 Hosting options

1. **Docker / Caddy (recommended):** `admin/Dockerfile` builds the panel and serves it with Nginx; Caddy routes `/admin*` to it ([09-deployment.md](09-deployment.md)).
2. **From the API process:** `npm run build`, then set `ADMIN_STATIC_DIR=/path/to/admin/dist` on the API. The panel is then at `https://api-domain/admin/`.
3. **Static hosting** (Netlify, Vercel, S3/CloudFront, Cloudflare Pages): upload `dist/` under the `/admin/` path, set `VITE_API_BASE_URL` and the API's `CORS_ORIGINS`, and configure an SPA fallback of `/admin/*` → `/admin/index.html`.

## 6.6 Code structure and conventions

* `src/api/client.ts`: the only place that calls `fetch`. Add new endpoints there with types from `src/api/types.ts`.
* `src/components/ui.tsx`: form primitives (`TextField`, `Toggle`, `Segmented`, `ColorField`, `Modal`…). Every input has a label, and dialogs close with Esc.
* `src/components/Sortable.tsx`: drag & drop for mouse, touch **and keyboard** (focus ⠿, Space, arrows, Space).
* `src/components/PhonePreview.tsx`: approximates the app's home screen from the settings being edited. Keep it roughly in sync when you change the app's layout.
* `src/lib/icons.ts` must list the same icon names as `app/lib/core/utils/icon_registry.dart`.
* Styling: CSS variables in `src/styles/app.css` (dark and light via `prefers-color-scheme`), responsive down to phone width.

## 6.7 Adding a settings field (example)

1. Backend: add the field with a default to the section model in `backend/app/schemas/settings.py`.
2. Admin: add it to the interface in `src/api/types.ts` and a control in `src/pages/Settings.tsx`.
3. App: read it in `app/lib/data/models/app_config.dart` (with a default) and use it.

No database migration is needed for settings.
