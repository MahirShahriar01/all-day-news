import os
import tempfile
from pathlib import Path

import pytest

_tmp = Path(tempfile.mkdtemp(prefix="allinone-test-"))
os.environ.update(
    APP_ENV="test",
    DATABASE_URL=os.environ.get("TEST_DATABASE_URL", f"sqlite:///{_tmp / 'test.db'}"),
    MEDIA_ROOT=str(_tmp / "uploads"),
    SECRET_KEY="test-secret-key-that-is-long-enough-1234567890",
    FIRST_ADMIN_EMAIL="owner@example.com",
    FIRST_ADMIN_PASSWORD="OwnerPassword!1",
    SEED_DEMO_DATA="true",
    PUBLIC_BASE_URL="https://api.example.com",
)

from fastapi.testclient import TestClient  # noqa: E402

from app.core.security import login_throttle  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(scope="session")
def client():
    with TestClient(app) as c:
        yield c


@pytest.fixture(autouse=True)
def _reset_throttle():
    login_throttle.reset()
    yield


@pytest.fixture(scope="session")
def token(client) -> str:
    res = client.post("/api/v1/admin/auth/login", json={"email": "owner@example.com", "password": "OwnerPassword!1"})
    assert res.status_code == 200, res.text
    return res.json()["access_token"]


@pytest.fixture(scope="session")
def auth(token) -> dict:
    return {"Authorization": f"Bearer {token}"}
