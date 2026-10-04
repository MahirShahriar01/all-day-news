from datetime import UTC, datetime

from fastapi import APIRouter, HTTPException, Request, status

from app.api.deps import CurrentAdmin, DbSession
from app.core.security import create_access_token, hash_password, login_throttle, verify_password
from app.models import AdminUser
from app.schemas.auth import AdminOut, ChangePasswordRequest, LoginRequest, TokenResponse
from app.services import audit

router = APIRouter(prefix="/auth", tags=["admin: auth"])

# Used to keep response time constant when the e-mail does not exist.
_DUMMY_HASH = hash_password("timing-safe-dummy-password")


@router.post("/login", response_model=TokenResponse)
def login(payload: LoginRequest, request: Request, db: DbSession) -> TokenResponse:
    email = payload.email.lower()
    client = request.client.host if request.client else "unknown"
    key = f"{email}|{client}"
    if login_throttle.is_locked(key):
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many failed attempts. Please wait a few minutes and try again.",
        )
    admin = db.query(AdminUser).filter(AdminUser.email == email).one_or_none()
    valid = verify_password(payload.password, admin.password_hash if admin else _DUMMY_HASH)
    if not admin or not valid or not admin.is_active:
        login_throttle.register_failure(key)
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect e-mail or password")
    login_throttle.reset(key)
    admin.last_login_at = datetime.now(UTC)
    audit.record(db, admin, "login", "admin", admin.id, f"{admin.email} signed in")
    db.commit()
    token, expires_at = create_access_token(str(admin.id), admin.token_version, {"role": admin.role})
    return TokenResponse(access_token=token, expires_at=expires_at, admin=AdminOut.model_validate(admin))


@router.get("/me", response_model=AdminOut)
def me(admin: CurrentAdmin) -> AdminUser:
    return admin


@router.post("/change-password", status_code=204)
def change_password(payload: ChangePasswordRequest, admin: CurrentAdmin, db: DbSession) -> None:
    if not verify_password(payload.current_password, admin.password_hash):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    admin.password_hash = hash_password(payload.new_password)
    admin.token_version += 1  # sign out every other session
    audit.record(db, admin, "update", "admin", admin.id, "Changed password")
    db.commit()


@router.post("/logout-all", status_code=204)
def logout_all(admin: CurrentAdmin, db: DbSession) -> None:
    admin.token_version += 1
    db.commit()
