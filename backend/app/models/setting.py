from datetime import datetime

from sqlalchemy import JSON, DateTime, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db.session import Base
from app.models.mixins import utcnow


class AppSetting(Base):
    """Key/value store for app-wide configuration (branding, theme, layout...).

    Each key holds one JSON document validated by the matching Pydantic schema
    in ``app.schemas.settings``. New settings sections can be added without a
    database migration.
    """

    __tablename__ = "app_settings"

    key: Mapped[str] = mapped_column(String(60), primary_key=True)
    value: Mapped[dict] = mapped_column(JSON, nullable=False, default=dict)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)
