from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.common import Color, MediaUrl, ORMModel, WebUrl

OpenMode = Literal["default", "in_app", "custom_tab", "external"]


class SiteBase(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    url: WebUrl
    category_id: int | None = None
    description: str = Field(default="", max_length=2000)
    logo_url: MediaUrl = ""
    background_url: MediaUrl = ""
    animation_url: MediaUrl = ""
    accent_color: Color = ""
    badge: str = Field(default="", max_length=20)
    tags: str = Field(default="", max_length=300)
    open_mode: OpenMode = "default"
    is_featured: bool = False
    is_enabled: bool = True


class SiteCreate(SiteBase):
    sort_order: int | None = None
    featured_order: int | None = None


class SiteUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    url: WebUrl | None = None
    category_id: int | None = None
    description: str | None = Field(default=None, max_length=2000)
    logo_url: MediaUrl | None = None
    background_url: MediaUrl | None = None
    animation_url: MediaUrl | None = None
    accent_color: Color | None = None
    badge: str | None = Field(default=None, max_length=20)
    tags: str | None = Field(default=None, max_length=300)
    open_mode: OpenMode | None = None
    is_featured: bool | None = None
    is_enabled: bool | None = None
    sort_order: int | None = None
    featured_order: int | None = None


class SiteOut(ORMModel):
    id: int
    title: str
    url: str
    category_id: int | None
    description: str
    logo_url: str
    background_url: str
    animation_url: str
    accent_color: str
    badge: str
    tags: str
    open_mode: str
    is_featured: bool
    featured_order: int
    sort_order: int
    is_enabled: bool
    created_at: datetime
    updated_at: datetime


class SiteBulkAction(BaseModel):
    ids: list[int] = Field(min_length=1, max_length=1000)
    action: Literal["enable", "disable", "feature", "unfeature", "delete", "move"]
    category_id: int | None = None  # for "move"
