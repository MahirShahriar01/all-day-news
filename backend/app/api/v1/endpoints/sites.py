from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.api.deps import CurrentAdmin, DbSession
from app.models import Category, Site
from app.schemas.category import ReorderRequest
from app.schemas.site import SiteBulkAction, SiteCreate, SiteOut, SiteUpdate
from app.services import audit
from app.services.ordering import apply_order, next_position

router = APIRouter(prefix="/sites", tags=["admin: websites"])

NULLABLE_FIELDS = {"category_id"}


class SitePage(BaseModel):
    items: list[SiteOut]
    total: int


def _get(db: Session, site_id: int) -> Site:
    site = db.get(Site, site_id)
    if site is None:
        raise HTTPException(status_code=404, detail="Website not found")
    return site


def _check_category(db: Session, category_id: int | None) -> None:
    if category_id is not None and db.get(Category, category_id) is None:
        raise HTTPException(status_code=422, detail="The selected category does not exist")


@router.get("", response_model=SitePage)
def list_sites(
    db: DbSession,
    _: CurrentAdmin,
    category_id: int | None = None,
    uncategorised: bool = False,
    featured: bool | None = None,
    enabled: bool | None = None,
    q: str | None = Query(default=None, max_length=100),
    limit: int = Query(default=200, ge=1, le=1000),
    offset: int = Query(default=0, ge=0),
) -> SitePage:
    stmt = select(Site)
    if uncategorised:
        stmt = stmt.where(Site.category_id.is_(None))
    elif category_id is not None:
        stmt = stmt.where(Site.category_id == category_id)
    if featured is not None:
        stmt = stmt.where(Site.is_featured.is_(featured))
    if enabled is not None:
        stmt = stmt.where(Site.is_enabled.is_(enabled))
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(or_(Site.title.ilike(like), Site.url.ilike(like), Site.tags.ilike(like)))
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    order = (Site.featured_order, Site.id) if featured else (Site.sort_order, Site.id)
    items = db.scalars(stmt.order_by(*order).limit(limit).offset(offset)).all()
    return SitePage(items=[SiteOut.model_validate(s) for s in items], total=total)


@router.post("", response_model=SiteOut, status_code=201)
def create_site(payload: SiteCreate, db: DbSession, admin: CurrentAdmin) -> Site:
    _check_category(db, payload.category_id)
    data = payload.model_dump()
    if data["sort_order"] is None:
        data["sort_order"] = next_position(db, Site.sort_order)
    if data["featured_order"] is None:
        data["featured_order"] = next_position(db, Site.featured_order) if payload.is_featured else 0
    site = Site(**data)
    db.add(site)
    db.flush()
    audit.record(db, admin, "create", "site", site.id, f"Added website “{site.title}”")
    db.commit()
    return site


@router.get("/{site_id}", response_model=SiteOut)
def get_site(site_id: int, db: DbSession, _: CurrentAdmin) -> Site:
    return _get(db, site_id)


@router.patch("/{site_id}", response_model=SiteOut)
def update_site(site_id: int, payload: SiteUpdate, db: DbSession, admin: CurrentAdmin) -> Site:
    site = _get(db, site_id)
    data = payload.model_dump(exclude_unset=True)
    if "category_id" in data:
        _check_category(db, data["category_id"])
    if data.get("is_featured") and not site.is_featured and "featured_order" not in data:
        data["featured_order"] = next_position(db, Site.featured_order)
    for key, value in data.items():
        if value is not None or key in NULLABLE_FIELDS:
            setattr(site, key, value)
    audit.record(db, admin, "update", "site", site.id, f"Updated website “{site.title}”")
    db.commit()
    return site


@router.delete("/{site_id}", status_code=204)
def delete_site(site_id: int, db: DbSession, admin: CurrentAdmin) -> None:
    site = _get(db, site_id)
    title = site.title
    db.delete(site)
    audit.record(db, admin, "delete", "site", site_id, f"Deleted website “{title}”")
    db.commit()


@router.post("/reorder", status_code=204)
def reorder_sites(payload: ReorderRequest, db: DbSession, admin: CurrentAdmin) -> None:
    """Order websites. Send the ids of one category (or all) in display order."""
    sites = {s.id: s for s in db.scalars(select(Site).where(Site.id.in_(payload.ids))).all()}
    for position, site_id in enumerate(i for i in payload.ids if i in sites):
        sites[site_id].sort_order = position
    audit.record(db, admin, "reorder", "site", None, "Reordered websites")
    db.commit()


@router.post("/featured/reorder", status_code=204)
def reorder_featured(payload: ReorderRequest, db: DbSession, admin: CurrentAdmin) -> None:
    featured = {s.id: s for s in db.scalars(select(Site).where(Site.is_featured.is_(True))).all()}
    apply_order(featured, payload.ids, attr="featured_order")
    audit.record(db, admin, "reorder", "site", None, "Reordered featured websites")
    db.commit()


@router.post("/bulk", status_code=204)
def bulk_action(payload: SiteBulkAction, db: DbSession, admin: CurrentAdmin) -> None:
    sites = db.scalars(select(Site).where(Site.id.in_(payload.ids))).all()
    if payload.action == "move":
        _check_category(db, payload.category_id)
    next_featured = next_position(db, Site.featured_order)
    for site in sites:
        match payload.action:
            case "enable":
                site.is_enabled = True
            case "disable":
                site.is_enabled = False
            case "feature":
                if not site.is_featured:
                    site.is_featured, site.featured_order = True, next_featured
                    next_featured += 1
            case "unfeature":
                site.is_featured = False
            case "move":
                site.category_id = payload.category_id
            case "delete":
                db.delete(site)
    audit.record(db, admin, payload.action, "site", None, f"Bulk {payload.action} on {len(sites)} website(s)")
    db.commit()
