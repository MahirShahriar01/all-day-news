"""Password hashing, JWT handling and login throttling."""

from __future__ import annotations

import threading
import time
from datetime import UTC, datetime, timedelta

import bcrypt
import jwt

from app.core.config import get_settings

# bcrypt only uses the first 72 bytes of a password.
_BCRYPT_MAX_BYTES = 72


def hash_password(password: str) -> str:
    raw = password.encode("utf-8")[:_BCRYPT_MAX_BYTES]
    return bcrypt.hashpw(raw, bcrypt.gensalt(rounds=12)).decode("utf-8")


def verify_password(password: str, password_hash: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8")[:_BCRYPT_MAX_BYTES], password_hash.encode("utf-8"))
    except ValueError:
        return False


def create_access_token(subject: str, token_version: int, extra: dict | None = None) -> tuple[str, datetime]:
    settings = get_settings()
    expires_at = datetime.now(UTC) + timedelta(minutes=settings.access_token_expire_minutes)
    payload = {
        "sub": subject,
        "ver": token_version,
        "exp": expires_at,
        "iat": datetime.now(UTC),
        "type": "access",
        **(extra or {}),
    }
    token = jwt.encode(payload, settings.secret_key, algorithm=settings.jwt_algorithm)
    return token, expires_at


def decode_access_token(token: str) -> dict:
    settings = get_settings()
    payload = jwt.decode(token, settings.secret_key, algorithms=[settings.jwt_algorithm])
    if payload.get("type") != "access":
        raise jwt.InvalidTokenError("wrong token type")
    return payload


class LoginThrottle:
    """Simple in-process brute-force protection keyed by e-mail + client IP.

    For multi-instance deployments replace with a shared store (e.g. Redis);
    the interface is intentionally tiny to make that easy.
    """

    def __init__(self) -> None:
        self._lock = threading.Lock()
        self._failures: dict[str, list[float]] = {}

    def _prune(self, key: str, now: float, window: int) -> list[float]:
        entries = [t for t in self._failures.get(key, []) if now - t < window]
        self._failures[key] = entries
        return entries

    def is_locked(self, key: str) -> bool:
        settings = get_settings()
        with self._lock:
            entries = self._prune(key, time.monotonic(), settings.login_lockout_seconds)
            return len(entries) >= settings.login_max_attempts

    def register_failure(self, key: str) -> None:
        with self._lock:
            self._failures.setdefault(key, []).append(time.monotonic())

    def reset(self, key: str | None = None) -> None:
        with self._lock:
            if key is None:
                self._failures.clear()
            else:
                self._failures.pop(key, None)


login_throttle = LoginThrottle()
