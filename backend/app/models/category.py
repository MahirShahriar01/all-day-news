from typing import TYPE_CHECKING

from sqlalchemy import Boolean, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.session import Base
from app.models.mixins import TimestampMixin

if TYPE_CHECKING:
    from app.models.site import Site


class Category(TimestampMixin, Base):
    """A group of websites, e.g. "News", "Live Streaming", "Sports"."""

    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(80), nullable=False)
    slug: Mapped[str] = mapped_column(String(100), unique=True, index=True, nullable=False)
    description: Mapped[str] = mapped_column(Text, default="", nullable=False)
    # Material icon name (e.g. "newspaper") used when no icon image is uploaded.
    icon_name: Mapped[str] = mapped_column(String(60), default="", nullable=False)
    icon_url: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    background_url: Mapped[str] = mapped_column(String(500), default="", nullable=False)
    color: Mapped[str] = mapped_column(String(9), default="", nullable=False)  # #RRGGBB or #AARRGGBB
    sort_order: Mapped[int] = mapped_column(Integer, default=0, index=True, nullable=False)
    is_enabled: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    sites: Mapped[list["Site"]] = relationship(back_populates="category", passive_deletes=True)
