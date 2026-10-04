from sqlalchemy.orm import Session

from app.models import AppSetting
from app.schemas.settings import SECTION_MODELS, AppSettingsDoc


def load_settings(db: Session) -> AppSettingsDoc:
    rows = {row.key: row.value for row in db.query(AppSetting).all()}
    data = {key: rows.get(key, {}) for key in SECTION_MODELS}
    return AppSettingsDoc.model_validate(data)


def save_section(db: Session, section: str, payload: dict) -> dict:
    model = SECTION_MODELS[section]
    value = model.model_validate(payload).model_dump(mode="json")
    row = db.get(AppSetting, section)
    if row is None:
        db.add(AppSetting(key=section, value=value))
    else:
        row.value = value
    return value
