from sqlalchemy.orm import Session

from app.models import AdminUser, AuditLog


def record(
    db: Session,
    admin: AdminUser | None,
    action: str,
    entity: str,
    entity_id: int | None = None,
    summary: str = "",
) -> None:
    """Add an audit entry to the current transaction (committed by the caller)."""
    db.add(
        AuditLog(
            admin_id=admin.id if admin else None,
            admin_email=admin.email if admin else "",
            action=action,
            entity=entity,
            entity_id=entity_id,
            summary=summary[:500],
        )
    )
