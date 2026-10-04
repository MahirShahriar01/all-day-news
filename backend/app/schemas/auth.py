from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.schemas.common import ORMModel


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=1, max_length=256)


class AdminOut(ORMModel):
    id: int
    email: str
    full_name: str
    role: str
    is_active: bool
    last_login_at: datetime | None
    created_at: datetime


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    admin: AdminOut


class ChangePasswordRequest(BaseModel):
    current_password: str = Field(min_length=1, max_length=256)
    new_password: str = Field(min_length=10, max_length=128)


class AdminCreate(BaseModel):
    email: EmailStr
    full_name: str = Field(default="", max_length=120)
    password: str = Field(min_length=10, max_length=128)
    role: str = Field(default="editor", pattern="^(owner|editor)$")


class AdminUpdate(BaseModel):
    full_name: str | None = Field(default=None, max_length=120)
    role: str | None = Field(default=None, pattern="^(owner|editor)$")
    is_active: bool | None = None
    password: str | None = Field(default=None, min_length=10, max_length=128)
