from datetime import datetime

from pydantic import BaseModel, Field

from app.schemas.common import Color, MediaUrl, ORMModel


class CategoryBase(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    slug: str | None = Field(default=None, max_length=100, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    description: str = Field(default="", max_length=2000)
    icon_name: str = Field(default="", max_length=60)
    icon_url: MediaUrl = ""
    background_url: MediaUrl = ""
    color: Color = ""
    is_enabled: bool = True


class CategoryCreate(CategoryBase):
    sort_order: int | None = None


class CategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=1, max_length=80)
    slug: str | None = Field(default=None, max_length=100, pattern=r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
    description: str | None = Field(default=None, max_length=2000)
    icon_name: str | None = Field(default=None, max_length=60)
    icon_url: MediaUrl | None = None
    background_url: MediaUrl | None = None
    color: Color | None = None
    is_enabled: bool | None = None
    sort_order: int | None = None


class CategoryOut(ORMModel):
    id: int
    name: str
    slug: str
    description: str
    icon_name: str
    icon_url: str
    background_url: str
    color: str
    sort_order: int
    is_enabled: bool
    site_count: int = 0
    created_at: datetime
    updated_at: datetime


class ReorderRequest(BaseModel):
    """Ids in the desired display order (first = shown first)."""

    ids: list[int] = Field(min_length=1, max_length=5000)
