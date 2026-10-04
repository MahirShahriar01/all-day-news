from datetime import datetime

from fastapi import APIRouter
from pydantic import BaseModel
from sqlalchemy import func, select

from app.api.deps import CurrentAdmin, DbSession
from app.models import AuditLog, Category, MediaAsset, Site
from app.schemas.common import ORMModel


class ActivityOut(ORMModel):
    id: int
    admin_email: str
    action: str
    entity: str
    entity_id: int | None
    summary: str
    created_at: datetime


class DashboardOut(BaseModel):
    categories: int
    categories_enabled: int
    sites: int
    sites_enabled: int
    sites_featured: int
    sites_uncategorised: int
    media_files: int
    media_bytes: int
    recent_activity: list[ActivityOut]


router = APIRouter(prefix="/dashboard", tags=["admin: dashboard"])


@router.get("", response_model=DashboardOut)
def dashboard(db: DbSession, _: CurrentAdmin) -> DashboardOut:
    def count(stmt) -> int:
        return db.scalar(stmt) or 0

    return DashboardOut(
        categories=count(select(func.count(Category.id))),
        categories_enabled=count(select(func.count(Category.id)).where(Category.is_enabled.is_(True))),
        sites=count(select(func.count(Site.id))),
        sites_enabled=count(select(func.count(Site.id)).where(Site.is_enabled.is_(True))),
        sites_featured=count(select(func.count(Site.id)).where(Site.is_featured.is_(True))),
        sites_uncategorised=count(select(func.count(Site.id)).where(Site.category_id.is_(None))),
        media_files=count(select(func.count(MediaAsset.id))),
        media_bytes=count(select(func.coalesce(func.sum(MediaAsset.size_bytes), 0))),
        recent_activity=[
            ActivityOut.model_validate(a)
            for a in db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc(), AuditLog.id.desc()).limit(15))
        ],
    )
