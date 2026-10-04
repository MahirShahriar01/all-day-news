from fastapi import APIRouter, HTTPException
from pydantic import ValidationError

from app.api.deps import CurrentAdmin, DbSession
from app.schemas.settings import SECTION_MODELS, AppSettingsDoc
from app.services import audit
from app.services.config_bundle import build_public_config
from app.services.settings_service import load_settings, save_section

router = APIRouter(prefix="/settings", tags=["admin: settings"])


@router.get("", response_model=AppSettingsDoc)
def get_settings_doc(db: DbSession, _: CurrentAdmin) -> AppSettingsDoc:
    return load_settings(db)


@router.put("/{section}")
def update_section(section: str, payload: dict, db: DbSession, admin: CurrentAdmin) -> dict:
    """Replace one settings section: branding, theme, layout, browser or legal."""
    if section not in SECTION_MODELS:
        raise HTTPException(status_code=404, detail=f"Unknown settings section '{section}'")
    try:
        value = save_section(db, section, payload)
    except ValidationError as exc:
        raise HTTPException(status_code=422, detail=exc.errors(include_url=False, include_context=False)) from None
    audit.record(db, admin, "update", "settings", None, f"Updated {section} settings")
    db.commit()
    return value


@router.get("/preview")
def preview_public_config(db: DbSession, _: CurrentAdmin) -> dict:
    """Exactly what the mobile app receives from GET /api/v1/config."""
    return build_public_config(db)
