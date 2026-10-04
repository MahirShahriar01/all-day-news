"""Builds the single JSON document the mobile app downloads on start-up.

One request gives the app everything it needs (branding, theme, layout,
categories, websites, featured list). The response carries a content hash
(`version`) that doubles as an HTTP ETag, so unchanged configs cost a 304.
"""

from __future__ import annotations

import hashlib
import json
from datetime import UTC, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.models import Category, Site
from app.services.settings_service import load_settings
from app.services.urls import absolute_url

SCHEMA_VERSION = 1


def _public_site(site: Site) -> dict:
    return {
        "id": site.id,
        "category_id": site.category_id,
        "title": site.title,
        "url": site.url,
        "description": site.description,
        "logo_url": absolute_url(site.logo_url),
        "background_url": absolute_url(site.background_url),
        "animation_url": absolute_url(site.animation_url),
        "accent_color": site.accent_color,
        "badge": site.badge,
        "tags": [t.strip() for t in site.tags.split(",") if t.strip()],
        "open_mode": site.open_mode,
        "is_featured": site.is_featured,
    }


def _public_category(cat: Category) -> dict:
    return {
        "id": cat.id,
        "name": cat.name,
        "slug": cat.slug,
        "description": cat.description,
        "icon_name": cat.icon_name,
        "icon_url": absolute_url(cat.icon_url),
        "background_url": absolute_url(cat.background_url),
        "color": cat.color,
    }


def build_public_config(db: Session) -> dict:
    settings_doc = load_settings(db).model_dump(mode="json")
    for section in ("branding", "layout"):
        for key, value in list(settings_doc[section].items()):
            if key.endswith("_url") and isinstance(value, str):
                settings_doc[section][key] = absolute_url(value)

    legal = settings_doc["legal"]
    if not legal["privacy_policy_url"]:
        legal["privacy_policy_url"] = f"{get_settings().public_base_url}/privacy-policy"
    legal.pop("privacy_policy_text", None)

    categories = db.scalars(
        select(Category).where(Category.is_enabled.is_(True)).order_by(Category.sort_order, Category.id)
    ).all()
    enabled_ids = {c.id for c in categories}

    sites = db.scalars(
        select(Site).where(Site.is_enabled.is_(True)).order_by(Site.sort_order, Site.id)
    ).all()
    visible = [s for s in sites if s.category_id is None or s.category_id in enabled_ids]
    featured = sorted((s for s in visible if s.is_featured), key=lambda s: (s.featured_order, s.id))

    body = {
        "schema_version": SCHEMA_VERSION,
        "settings": settings_doc,
        "categories": [_public_category(c) for c in categories],
        "sites": [_public_site(s) for s in visible],
        "featured": [s.id for s in featured],
    }
    digest = hashlib.sha256(json.dumps(body, sort_keys=True, default=str).encode()).hexdigest()[:16]
    body["version"] = digest
    body["generated_at"] = datetime.now(UTC).isoformat()
    return body
