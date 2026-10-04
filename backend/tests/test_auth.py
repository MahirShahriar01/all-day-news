def test_login_rejects_wrong_password(client):
    res = client.post("/api/v1/admin/auth/login", json={"email": "owner@example.com", "password": "nope"})
    assert res.status_code == 401


def test_login_throttles_after_repeated_failures(client):
    for _ in range(5):
        client.post("/api/v1/admin/auth/login", json={"email": "owner@example.com", "password": "bad"})
    res = client.post("/api/v1/admin/auth/login", json={"email": "owner@example.com", "password": "OwnerPassword!1"})
    assert res.status_code == 429


def test_admin_endpoints_require_token(client):
    assert client.get("/api/v1/admin/categories").status_code == 401
    assert client.get("/api/v1/admin/categories", headers={"Authorization": "Bearer junk"}).status_code == 401


def test_me(client, auth):
    res = client.get("/api/v1/admin/auth/me", headers=auth)
    assert res.status_code == 200
    assert res.json()["role"] == "owner"


def test_editor_cannot_manage_admins(client, auth):
    res = client.post(
        "/api/v1/admin/admins",
        headers=auth,
        json={"email": "editor@example.com", "password": "EditorPassword1", "role": "editor"},
    )
    assert res.status_code == 201
    login = client.post("/api/v1/admin/auth/login", json={"email": "editor@example.com", "password": "EditorPassword1"})
    editor = {"Authorization": f"Bearer {login.json()['access_token']}"}
    assert client.get("/api/v1/admin/admins", headers=editor).status_code == 403
    assert client.get("/api/v1/admin/categories", headers=editor).status_code == 200


def test_cannot_remove_last_owner(client, auth):
    me = client.get("/api/v1/admin/auth/me", headers=auth).json()
    res = client.patch(f"/api/v1/admin/admins/{me['id']}", headers=auth, json={"role": "editor"})
    assert res.status_code == 400
