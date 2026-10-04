"""App-wide configuration managed from the admin panel.

Every section is stored as one JSON document in ``app_settings``. Defaults
live here, so adding a new option is a one-line change: add the field with a
default, and both the admin panel (which renders what the API returns) and
older app versions (which ignore unknown keys) keep working.
"""

from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field

from app.schemas.common import Color, MediaUrl


class BrandingSettings(BaseModel):
    app_name: str = Field(default="All in One News", min_length=1, max_length=60)
    tagline: str = Field(default="Every channel. One place.", max_length=120)
    logo_url: MediaUrl = ""
    splash_image_url: MediaUrl = ""


class ThemeSettings(BaseModel):
    mode: Literal["dark", "light", "system"] = "dark"
    primary_color: Color = "#FF7C4DFF"
    secondary_color: Color = "#FF00E5FF"
    accent_color: Color = "#FFFF4081"
    background_color: Color = "#FF0A0E1A"
    surface_color: Color = "#FF141A2E"
    text_color: Color = "#FFF5F7FF"
    gradient_start: Color = "#FF7C4DFF"
    gradient_end: Color = "#FF00E5FF"
    corner_radius: int = Field(default=20, ge=0, le=40)
    card_style: Literal["glass", "solid", "image"] = "glass"
    enable_animations: bool = True


class AnnouncementSettings(BaseModel):
    enabled: bool = False
    text: str = Field(default="", max_length=240)
    url: str = Field(default="", max_length=2000)


class LayoutSettings(BaseModel):
    home_background_url: MediaUrl = ""
    home_background_opacity: float = Field(default=0.35, ge=0, le=1)
    show_featured: bool = True
    featured_title: str = Field(default="Featured", max_length=40)
    featured_style: Literal["carousel", "grid"] = "carousel"
    show_search: bool = True
    show_category_tabs: bool = True
    grid_columns: int = Field(default=3, ge=2, le=4)
    show_descriptions: bool = True
    announcement: AnnouncementSettings = AnnouncementSettings()


class BrowserSettings(BaseModel):
    default_open_mode: Literal["in_app", "custom_tab", "external"] = "custom_tab"
    show_toolbar: bool = True
    allow_open_in_external_browser: bool = True
    allow_share: bool = True


class LegalSettings(BaseModel):
    privacy_policy_url: str = Field(default="", max_length=2000)
    terms_url: str = Field(default="", max_length=2000)
    contact_email: str = Field(default="", max_length=255)
    publisher_name: str = Field(default="", max_length=120)
    about_text: str = Field(
        default="All in One News brings your favourite news, live streams and information services together.",
        max_length=4000,
    )
    privacy_policy_text: str = Field(default="", max_length=50000)


class AppSettingsDoc(BaseModel):
    branding: BrandingSettings = BrandingSettings()
    theme: ThemeSettings = ThemeSettings()
    layout: LayoutSettings = LayoutSettings()
    browser: BrowserSettings = BrowserSettings()
    legal: LegalSettings = LegalSettings()


SECTION_MODELS: dict[str, type[BaseModel]] = {
    "branding": BrandingSettings,
    "theme": ThemeSettings,
    "layout": LayoutSettings,
    "browser": BrowserSettings,
    "legal": LegalSettings,
}
