"""Start-up tasks: database migrations, first administrator, demo data."""

from __future__ import annotations

import logging
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.core.security import hash_password
from app.models import AdminUser
from app.services.seed import seed_demo_content

log = logging.getLogger("allinone.bootstrap")
BACKEND_DIR = Path(__file__).resolve().parents[2]


def run_migrations() -> None:
    cfg = Config(str(BACKEND_DIR / "alembic.ini"))
    cfg.set_main_option("script_location", str(BACKEND_DIR / "alembic"))
    cfg.set_main_option("sqlalchemy.url", get_settings().database_url)
    cfg.attributes["skip_logging"] = True
    command.upgrade(cfg, "head")


def ensure_first_admin(db: Session) -> AdminUser | None:
    settings = get_settings()
    if db.query(AdminUser).count():
        return None
    if not settings.first_admin_email or not settings.first_admin_password:
        log.warning("No administrator exists. Set FIRST_ADMIN_EMAIL / FIRST_ADMIN_PASSWORD or run `python -m app.cli create-admin`.")
        return None
    admin = AdminUser(
        email=settings.first_admin_email.lower(),
        full_name="Administrator",
        password_hash=hash_password(settings.first_admin_password),
        role="owner",
    )
    db.add(admin)
    db.commit()
    log.info("Created first administrator %s", admin.email)
    return admin


def bootstrap(db: Session) -> None:
    ensure_first_admin(db)
    if get_settings().seed_demo_data:
        seed_demo_content(db)
