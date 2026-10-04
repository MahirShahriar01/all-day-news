from fastapi import APIRouter, HTTPException
from sqlalchemy import func, select

from app.api.deps import DbSession, OwnerAdmin
from app.core.security import hash_password
from app.models import AdminUser
from app.schemas.auth import AdminCreate, AdminOut, AdminUpdate
from app.services import audit

router = APIRouter(prefix="/admins", tags=["admin: administrators"])


def _owner_count(db) -> int:
    return db.scalar(
        select(func.count(AdminUser.id)).where(AdminUser.role == "owner", AdminUser.is_active.is_(True))
    ) or 0


@router.get("", response_model=list[AdminOut])
def list_admins(db: DbSession, _: OwnerAdmin) -> list[AdminUser]:
    return list(db.scalars(select(AdminUser).order_by(AdminUser.id)))


@router.post("", response_model=AdminOut, status_code=201)
def create_admin(payload: AdminCreate, db: DbSession, owner: OwnerAdmin) -> AdminUser:
    email = payload.email.lower()
    if db.scalar(select(AdminUser.id).where(AdminUser.email == email)):
        raise HTTPException(status_code=409, detail="An administrator with this e-mail already exists")
    admin = AdminUser(
        email=email, full_name=payload.full_name, role=payload.role, password_hash=hash_password(payload.password)
    )
    db.add(admin)
    db.flush()
    audit.record(db, owner, "create", "admin", admin.id, f"Added administrator {email}")
    db.commit()
    return admin


@router.patch("/{admin_id}", response_model=AdminOut)
def update_admin(admin_id: int, payload: AdminUpdate, db: DbSession, owner: OwnerAdmin) -> AdminUser:
    admin = db.get(AdminUser, admin_id)
    if admin is None:
        raise HTTPException(status_code=404, detail="Administrator not found")
    demoting = (payload.role == "editor" or payload.is_active is False) and admin.role == "owner"
    if demoting and _owner_count(db) <= 1:
        raise HTTPException(status_code=400, detail="There must always be at least one active owner")
    if payload.full_name is not None:
        admin.full_name = payload.full_name
    if payload.role is not None:
        admin.role = payload.role
    if payload.is_active is not None:
        admin.is_active = payload.is_active
        if not payload.is_active:
            admin.token_version += 1
    if payload.password:
        admin.password_hash = hash_password(payload.password)
        admin.token_version += 1
    audit.record(db, owner, "update", "admin", admin.id, f"Updated administrator {admin.email}")
    db.commit()
    return admin


@router.delete("/{admin_id}", status_code=204)
def delete_admin(admin_id: int, db: DbSession, owner: OwnerAdmin) -> None:
    if admin_id == owner.id:
        raise HTTPException(status_code=400, detail="You cannot delete your own account")
    admin = db.get(AdminUser, admin_id)
    if admin is None:
        raise HTTPException(status_code=404, detail="Administrator not found")
    if admin.role == "owner" and _owner_count(db) <= 1:
        raise HTTPException(status_code=400, detail="There must always be at least one active owner")
    email = admin.email
    db.delete(admin)
    audit.record(db, owner, "delete", "admin", admin_id, f"Removed administrator {email}")
    db.commit()
