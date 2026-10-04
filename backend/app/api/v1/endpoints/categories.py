from fastapi import APIRouter, HTTPException, Query
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.api.deps import CurrentAdmin, DbSession
from app.models import Category, Site
from app.schemas.category import CategoryCreate, CategoryOut, CategoryUpdate, ReorderRequest
from app.schemas.common import slugify
from app.services import audit
from app.services.ordering import apply_order, next_position

router = APIRouter(prefix="/categories", tags=["admin: categories"])


def _unique_slug(db: Session, base: str, exclude_id: int | None = None) -> str:
    slug, n = base, 2
    while True:
        stmt = select(Category.id).where(Category.slug == slug)
        if exclude_id is not None:
            stmt = stmt.where(Category.id != exclude_id)
        if db.scalar(stmt) is None:
            return slug
        slug, n = f"{base}-{n}", n + 1


def _out(db: Session, cat: Category) -> CategoryOut:
    count = db.scalar(select(func.count(Site.id)).where(Site.category_id == cat.id)) or 0
    return CategoryOut.model_validate(cat).model_copy(update={"site_count": count})


def _get(db: Session, category_id: int) -> Category:
    cat = db.get(Category, category_id)
    if cat is None:
        raise HTTPException(status_code=404, detail="Category not found")
    return cat


@router.get("", response_model=list[CategoryOut])
def list_categories(db: DbSession, _: CurrentAdmin) -> list[CategoryOut]:
    counts = dict(db.execute(select(Site.category_id, func.count(Site.id)).group_by(Site.category_id)).all())
    cats = db.scalars(select(Category).order_by(Category.sort_order, Category.id)).all()
    return [CategoryOut.model_validate(c).model_copy(update={"site_count": counts.get(c.id, 0)}) for c in cats]


@router.post("", response_model=CategoryOut, status_code=201)
def create_category(payload: CategoryCreate, db: DbSession, admin: CurrentAdmin) -> CategoryOut:
    data = payload.model_dump()
    data["slug"] = _unique_slug(db, data["slug"] or slugify(payload.name))
    if data["sort_order"] is None:
        data["sort_order"] = next_position(db, Category.sort_order)
    cat = Category(**data)
    db.add(cat)
    db.flush()
    audit.record(db, admin, "create", "category", cat.id, f"Created category “{cat.name}”")
    db.commit()
    return _out(db, cat)


@router.get("/{category_id}", response_model=CategoryOut)
def get_category(category_id: int, db: DbSession, _: CurrentAdmin) -> CategoryOut:
    return _out(db, _get(db, category_id))


@router.patch("/{category_id}", response_model=CategoryOut)
def update_category(category_id: int, payload: CategoryUpdate, db: DbSession, admin: CurrentAdmin) -> CategoryOut:
    cat = _get(db, category_id)
    data = payload.model_dump(exclude_unset=True)
    if "slug" in data and data["slug"]:
        data["slug"] = _unique_slug(db, data["slug"], exclude_id=cat.id)
    elif "slug" in data:
        data.pop("slug")
    for key, value in data.items():
        if value is not None:
            setattr(cat, key, value)
    audit.record(db, admin, "update", "category", cat.id, f"Updated category “{cat.name}”")
    db.commit()
    return _out(db, cat)


@router.delete("/{category_id}", status_code=204)
def delete_category(
    category_id: int,
    db: DbSession,
    admin: CurrentAdmin,
    move_sites_to: int | None = Query(default=None, description="Move websites to this category first"),
    delete_sites: bool = Query(default=False, description="Delete the websites in this category too"),
) -> None:
    cat = _get(db, category_id)
    sites = db.scalars(select(Site).where(Site.category_id == cat.id)).all()
    if move_sites_to is not None:
        if move_sites_to == cat.id:
            raise HTTPException(status_code=400, detail="Choose a different category")
        _get(db, move_sites_to)
        for site in sites:
            site.category_id = move_sites_to
    elif delete_sites:
        for site in sites:
            db.delete(site)
    # Otherwise websites become "uncategorised" (category_id = NULL).
    name = cat.name
    db.delete(cat)
    audit.record(db, admin, "delete", "category", category_id, f"Deleted category “{name}”")
    db.commit()


@router.post("/reorder", status_code=204)
def reorder_categories(payload: ReorderRequest, db: DbSession, admin: CurrentAdmin) -> None:
    cats = {c.id: c for c in db.scalars(select(Category)).all()}
    apply_order(cats, payload.ids)
    audit.record(db, admin, "reorder", "category", None, "Reordered categories")
    db.commit()
