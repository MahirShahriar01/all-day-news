from typing import TYPE_CHECKING

from sqlalchemy import Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.category import Category

# How a website opens on the device.
#   default    - follow the global setting in App Settings
#   in_app     - embedded WebView with the app's own browser chrome
#   custom_tab - Chrome Custom Tab (Android) / SFSafariViewController (iOS)
#   external   - the user's default browser / the site's own app
OPEN_MODES = ("default", "in_app", "custom_tab", "external")


class Site(TimestampMixin, Base):
    """A website / channel / service shown as a card in the app."""

    __tablename__ = "sites"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    category_id: Mapped[int | None] = mapped_column(
        ForeignKey("categories.id", ondelete="SET NULL"), index=True, nullable=True
    )
    title: Mapped[str] = mapped_column(String(120), nullable=False)
    url: Mapped[str] = mapped_column(String(2000), nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    logo_url: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    background_url: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    # Animated GIF / WebP / MP4 shown on featured cards.
    animation_url: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    accent_color: Mapped[str] = mapped_column(String(9), default="", nullable=False)
    # Small label on the card, e.g. "LIVE", "NEW", "24/7".
    badge: Mapped[str] = mapped_column(String(20), default="", nullable=False)
    tags: Mapped[str] = mapped_column(String(300), default="", nullable=False)  # comma separated, used by search
    open_mode: Mapped[str] = mapped_column(String(20), default="default", nullable=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False, index=True, nullable=False)
    featured_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, index=True, nullable=False)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    category: Mapped["Category | None"] = relationship(back_populates="sites")
