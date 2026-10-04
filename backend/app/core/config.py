"""Centralised, environment-based configuration.

All settings are read from environment variables (or a `.env` file) so the
same image can run in development, staging and production without code
changes. See `.env.example` for documentation of every variable.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

INSECURE_DEFAULT_SECRET = "change-me-in-production-please-use-a-long-random-value"


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    app_env: Literal["development", "staging", "production", "test"] = "development"
    app_name: str = "All in One News API"
    api_v1_prefix: str = "/api/v1"

    database_url: str = "sqlite:///./data/allinone.db"

    secret_key: str = INSECURE_DEFAULT_SECRET
    jwt_algorithm: str = "HS256"
    access_token_expire_minutes: int = 720

    public_base_url: str = "http://localhost:8000"
    cors_origins: str = "http://localhost:5173,http://localhost:8080"

    media_root: Path = Path("./uploads")
    max_upload_mb: int = 25

    first_admin_email: str | None = None
    first_admin_password: str | None = None
    seed_demo_data: bool = True
    # Apply migrations + create first admin when the server starts. Disable when
    # running several workers and use `python -m app.cli init` before start-up.
    auto_migrate: bool = True

    admin_static_dir: Path | None = None

    # Login brute-force protection.
    login_max_attempts: int = Field(default=5, ge=1)
    login_lockout_seconds: int = Field(default=300, ge=1)

    @field_validator("public_base_url")
    @classmethod
    def _strip_slash(cls, value: str) -> str:
        return value.rstrip("/")

    @model_validator(mode="after")
    def _check_production(self) -> "Settings":
        if self.app_env == "production":
            if self.secret_key == INSECURE_DEFAULT_SECRET or len(self.secret_key) < 32:
                raise ValueError("SECRET_KEY must be set to a random value of at least 32 characters in production")
            if self.database_url.startswith("sqlite"):
                # Allowed, but strongly discouraged; logged at start-up.
                pass
        return self

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]

    @property
    def max_upload_bytes(self) -> int:
        return self.max_upload_mb * 1024 * 1024

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


@lru_cache
def get_settings() -> Settings:
    return Settings()
