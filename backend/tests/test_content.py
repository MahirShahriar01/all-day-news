import io

from PIL import Image


def _png_bytes() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (32, 32), (120, 80, 255)).save(buf, format="PNG")
    return buf.getvalue()


def test_category_crud_and_reorder(client, auth):
    res = client.post("/api/v1/admin/categories", headers=auth, json={"name": "World Radio", "color": "#ff00ff"})
    assert res.status_code == 201, res.text
    cat = res.json()
    assert cat["slug"] == "world-radio"
    assert cat["color"] == "#FF00FF"

    dup = client.post("/api/v1/admin/categories", headers=auth, json={"name": "World Radio"}).json()
    assert dup["slug"] == "world-radio-2"

    res = client.patch(f"/api/v1/admin/categories/{cat['id']}", headers=auth, json={"is_enabled": False})
    assert res.json()["is_enabled"] is False
    public = client.get("/api/v1/config").json()
    assert cat["id"] not in {c["id"] for c in public["categories"]}

    all_ids = [c["id"] for c in client.get("/api/v1/admin/categories", headers=auth).json()]
    new_order = [dup["id"], *[i for i in all_ids if i != dup["id"]]]
    assert client.post("/api/v1/admin/categories/reorder", headers=auth, json={"ids": new_order}).status_code == 204
    assert client.get("/api/v1/admin/categories", headers=auth).json()[0]["id"] == dup["id"]

    assert client.delete(f"/api/v1/admin/categories/{dup['id']}", headers=auth).status_code == 204
    assert client.delete(f"/api/v1/admin/categories/{cat['id']}", headers=auth).status_code == 204


def test_site_validation(client, auth):
    bad = client.post("/api/v1/admin/sites", headers=auth, json={"title": "x", "url": "javascript:alert(1)"})
    assert bad.status_code == 422
    bad_color = client.post(
        "/api/v1/admin/sites", headers=auth, json={"title": "x", "url": "https://a.com", "accent_color": "red"}
    )
    assert bad_color.status_code == 422
    missing_cat = client.post(
        "/api/v1/admin/sites", headers=auth, json={"title": "x", "url": "https://a.com", "category_id": 99999}
    )
    assert missing_cat.status_code == 422


def test_site_lifecycle(client, auth):
    cats = client.get("/api/v1/admin/categories", headers=auth).json()
    res = client.post(
        "/api/v1/admin/sites",
        headers=auth,
        json={
            "title": "Example Live",
            "url": "https://example.com/live",
            "category_id": cats[0]["id"],
            "badge": "LIVE",
            "is_featured": True,
        },
    )
    assert res.status_code == 201, res.text
    site = res.json()

    public = client.get("/api/v1/config").json()
    assert site["id"] in public["featured"]
    assert public["featured"][-1] == site["id"]

    # Move it to the front of the featured list.
    order = [site["id"], *[i for i in public["featured"] if i != site["id"]]]
    client.post("/api/v1/admin/sites/featured/reorder", headers=auth, json={"ids": order})
    assert client.get("/api/v1/config").json()["featured"][0] == site["id"]

    # Disabling hides it from the app.
    client.patch(f"/api/v1/admin/sites/{site['id']}", headers=auth, json={"is_enabled": False})
    public = client.get("/api/v1/config").json()
    assert site["id"] not in {s["id"] for s in public["sites"]}

    # Uncategorise via explicit null.
    res = client.patch(f"/api/v1/admin/sites/{site['id']}", headers=auth, json={"category_id": None})
    assert res.json()["category_id"] is None

    res = client.post("/api/v1/admin/sites/bulk", headers=auth, json={"ids": [site["id"]], "action": "delete"})
    assert res.status_code == 204
    assert client.get(f"/api/v1/admin/sites/{site['id']}", headers=auth).status_code == 404


def test_media_upload_and_usage_protection(client, auth):
    res = client.post("/api/v1/admin/media", headers=auth, files={"file": ("logo.png", _png_bytes(), "image/png")})
    assert res.status_code == 201, res.text
    media = res.json()
    assert media["kind"] == "image" and media["width"] == 32
    assert media["absolute_url"].startswith("https://api.example.com/uploads/")

    served = client.get(media["url"])
    assert served.status_code == 200
    assert "immutable" in served.headers["cache-control"]

    site = client.post(
        "/api/v1/admin/sites",
        headers=auth,
        json={"title": "Logo test", "url": "https://example.org", "logo_url": media["url"]},
    ).json()
    public_site = next(s for s in client.get("/api/v1/config").json()["sites"] if s["id"] == site["id"])
    assert public_site["logo_url"] == media["absolute_url"]

    assert client.delete(f"/api/v1/admin/media/{media['id']}", headers=auth).status_code == 409
    assert client.delete(f"/api/v1/admin/media/{media['id']}?force=true", headers=auth).status_code == 204


def test_media_rejects_disguised_files(client, auth):
    res = client.post(
        "/api/v1/admin/media", headers=auth, files={"file": ("evil.png", b"<script>alert(1)</script>", "image/png")}
    )
    assert res.status_code == 422


def test_settings_update_reflected_in_config(client, auth):
    res = client.put(
        "/api/v1/admin/settings/branding", headers=auth, json={"app_name": "My News Hub", "tagline": "Hello"}
    )
    assert res.status_code == 200, res.text
    assert client.get("/api/v1/config").json()["settings"]["branding"]["app_name"] == "My News Hub"
    client.put("/api/v1/admin/settings/branding", headers=auth, json={})  # back to defaults

    bad = client.put("/api/v1/admin/settings/theme", headers=auth, json={"primary_color": "purple"})
    assert bad.status_code == 422
    assert client.put("/api/v1/admin/settings/nope", headers=auth, json={}).status_code == 404


def test_dashboard(client, auth):
    res = client.get("/api/v1/admin/dashboard", headers=auth)
    assert res.status_code == 200
    body = res.json()
    assert body["sites"] >= 1 and body["recent_activity"]
