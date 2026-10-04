"""Public, read-only endpoints consumed by the mobile app."""

from fastapi import APIRouter, Query, Request, Response
from sqlalchemy import or_, select

from app.api.deps import DbSession
from app.models import Category, Site
from app.services.config_bundle import _public_category, _public_site, build_public_config

router = APIRouter(tags=["public"])


@router.get("/health")
def health() -> dict:
    return {"status": "ok"}


@router.get("/config")
def get_config(request: Request, response: Response, db: DbSession):
    """Everything the app needs in one call. Supports `If-None-Match`."""
    body = build_public_config(db)
    etag = f'"{body["version"]}"'
    cache = "public, max-age=60, stale-while-revalidate=600"
    if request.headers.get("if-none-match") == etag:
        return Response(status_code=304, headers={"ETag": etag, "Cache-Control": cache})
    response.headers["ETag"] = etag
    response.headers["Cache-Control"] = cache
    return body


@router.get("/categories")
def list_categories(db: DbSession) -> list[dict]:
    rows = db.scalars(
        select(Category).where(Category.is_enabled.is_(True)).order_by(Category.sort_order, Category.id)
    ).all()
    return [_public_category(c) for c in rows]


@router.get("/sites")
def list_sites(
    db: DbSession,
    category: str | None = Query(default=None, description="Category slug"),
    featured: bool | None = None,
    q: str | None = Query(default=None, max_length=100),
) -> list[dict]:
    stmt = (
        select(Site)
        .outerjoin(Category, Site.category_id == Category.id)
        .where(Site.is_enabled.is_(True))
        .where(or_(Site.category_id.is_(None), Category.is_enabled.is_(True)))
    )
    if category:
        stmt = stmt.where(Category.slug == category)
    if featured is not None:
        stmt = stmt.where(Site.is_featured.is_(featured))
    if q:
        like = f"%{q.strip()}%"
        stmt = stmt.where(or_(Site.title.ilike(like), Site.description.ilike(like), Site.tags.ilike(like)))
    order = (Site.featured_order, Site.id) if featured else (Site.sort_order, Site.id)
    return [_public_site(s) for s in db.scalars(stmt.order_by(*order)).all()]
