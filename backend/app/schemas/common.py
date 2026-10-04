"""Reusable field types and validators."""

from __future__ import annotations

import re
from typing import Annotated
from urllib.parse import urlparse

from pydantic import AfterValidator, BaseModel, ConfigDict

_COLOR_RE = re.compile(r"^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$")


def _validate_color(value: str) -> str:
    value = (value or "").strip()
    if value and not _COLOR_RE.match(value):
        raise ValueError("colour must look like #RRGGBB or #AARRGGBB")
    return value.upper()


def _validate_web_url(value: str) -> str:
    value = (value or "").strip()
    parsed = urlparse(value)
    if parsed.scheme not in ("http", "https") or not parsed.netloc:
        raise ValueError("must be a full web address starting with https:// or http://")
    return value


def _validate_media_url(value: str) -> str:
    """Empty, a server-relative upload path, or an absolute http(s) URL."""
    value = (value or "").strip()
    if not value:
        return ""
    if value.startswith("/uploads/") and ".." not in value:
        return value
    return _validate_web_url(value)


Color = Annotated[str, AfterValidator(_validate_color)]
WebUrl = Annotated[str, AfterValidator(_validate_web_url)]
MediaUrl = Annotated[str, AfterValidator(_validate_media_url)]


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


def slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return slug or "item"
