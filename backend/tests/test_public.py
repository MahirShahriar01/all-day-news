def test_health(client):
    assert client.get("/api/v1/health").json() == {"status": "ok"}


def test_config_bundle_contains_seeded_content(client):
    res = client.get("/api/v1/config")
    assert res.status_code == 200
    body = res.json()
    assert body["schema_version"] == 1
    assert body["settings"]["branding"]["app_name"] == "All in One News"
    assert len(body["categories"]) >= 5
    assert len(body["sites"]) >= 10
    assert body["featured"], "demo data has featured sites"
    site_ids = {s["id"] for s in body["sites"]}
    assert set(body["featured"]) <= site_ids
    assert "privacy_policy_text" not in body["settings"]["legal"]
    assert body["settings"]["legal"]["privacy_policy_url"].endswith("/privacy-policy")


def test_config_etag_returns_304(client):
    first = client.get("/api/v1/config")
    etag = first.headers["etag"]
    second = client.get("/api/v1/config", headers={"If-None-Match": etag})
    assert second.status_code == 304


def test_public_sites_filter_by_category(client):
    res = client.get("/api/v1/sites", params={"category": "news"})
    assert res.status_code == 200
    assert res.json() and all(s["category_id"] for s in res.json())


def test_privacy_policy_page(client):
    res = client.get("/privacy-policy")
    assert res.status_code == 200
    assert "Privacy Policy" in res.text
    assert res.headers["content-type"].startswith("text/html")


def test_security_headers(client):
    res = client.get("/api/v1/health")
    assert res.headers["x-content-type-options"] == "nosniff"
