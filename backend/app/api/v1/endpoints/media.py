from fastapi import APIRouter, File, HTTPException, Query, UploadFile
from pydantic import BaseModel
from sqlalchemy import func, or_, select

from app.api.deps import CurrentAdmin, DbSession
from app.core.config import get_settings
from app.models import Category, MediaAsset, Site
from app.schemas.media import MediaOut
from app.services import audit
from app.services.storage import UploadRejected, get_storage, inspect_upload, read_limited
from app.services.urls import absolute_url

router = APIRouter(prefix="/media", tags=["admin: media"])


class MediaPage(BaseModel):
    items: list[MediaOut]
    total: int


def _out(asset: MediaAsset) -> MediaOut:
    return MediaOut.model_validate(asset).model_copy(update={"absolute_url": absolute_url(asset.url)})


@router.get("", response_model=MediaPage)
def list_media(
    db: DbSession,
    _: CurrentAdmin,
    kind: str | None = Query(default=None, pattern="^(image|animation|video)$"),
    limit: int = Query(default=60, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
) -> MediaPage:
    stmt = select(MediaAsset)
    if kind:
        stmt = stmt.where(MediaAsset.kind == kind)
    total = db.scalar(select(func.count()).select_from(stmt.subquery())) or 0
    rows = db.scalars(stmt.order_by(MediaAsset.created_at.desc(), MediaAsset.id.desc()).limit(limit).offset(offset))
    return MediaPage(items=[_out(a) for a in rows], total=total)


@router.post("", response_model=MediaOut, status_code=201)
def upload_media(db: DbSession, admin: CurrentAdmin, file: UploadFile = File(...)) -> MediaOut:
    """Upload PNG, JPG, WebP, GIF, MP4 or WebM. The type is checked from the
    file content, not its name."""
    try:
        data = read_limited(file.file, get_settings().max_upload_bytes)
        detected = inspect_upload(data)
    except UploadRejected as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from None
    key, url = get_storage().save(data, detected.extension)
    asset = MediaAsset(
        kind=detected.kind,
        storage_key=key,
        url=url,
        mime_type=detected.mime_type,
        size_bytes=len(data),
        width=detected.width,
        height=detected.height,
        original_name=(file.filename or "")[:255],
        uploaded_by_id=admin.id,
    )
    db.add(asset)
    db.flush()
    audit.record(db, admin, "create", "media", asset.id, f"Uploaded {asset.original_name or key}")
    db.commit()
    return _out(asset)


@router.delete("/{media_id}", status_code=204)
def delete_media(media_id: int, db: DbSession, admin: CurrentAdmin, force: bool = False) -> None:
    asset = db.get(MediaAsset, media_id)
    if asset is None:
        raise HTTPException(status_code=404, detail="File not found")
    in_use = db.scalar(
        select(func.count(Site.id)).where(
            or_(Site.logo_url == asset.url, Site.background_url == asset.url, Site.animation_url == asset.url)
        )
    ) or 0
    in_use += db.scalar(
        select(func.count(Category.id)).where(or_(Category.icon_url == asset.url, Category.background_url == asset.url))
    ) or 0
    if in_use and not force:
        raise HTTPException(
            status_code=409,
            detail=f"This file is used by {in_use} item(s). Remove it from them first, or delete anyway.",
        )
    get_storage().delete(asset.storage_key)
    db.delete(asset)
    audit.record(db, admin, "delete", "media", media_id, f"Deleted {asset.original_name or asset.storage_key}")
    db.commit()
