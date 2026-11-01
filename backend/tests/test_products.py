import base64

from app.seed import load_catalog

from .conftest import PNG_1PX


def png_url(raw: bytes = PNG_1PX) -> str:
    return "data:image/png;base64," + base64.b64encode(raw).decode()


def test_catalog_is_public_and_matches_seed(client):
    data = client.get("/products").json()
    assert data["total"] == len(load_catalog()) == 12
    first = next(p for p in data["items"] if p["id"] == "p-temizleyici-lumen")
    # Katalogda sabit puan yok: iki topluluk yorumundan (5 ve 4).
    assert first["rating"] == 4.5
    assert first["reviewCount"] == 2
    assert first["addedBy"] == "Zeynep K."
    assert first["approvedAt"] == "2026-06-02"
    assert "price" not in first and "badge" not in first
    assert first["status"] == "approved"
    assert first["duplicateOf"] is None
    assert first["editedByTeam"] is False


def test_search_is_turkish_and_case_insensitive(client):
    ids = {p["id"] for p in client.get("/products", params={"q": "TEMİZLEYİCİ"}).json()["items"]}
    assert "p-temizleyici-lumen" in ids
    assert client.get("/products", params={"q": "%"}).json()["total"] == 12
    assert client.get("/products", params={"q": "boyle-bir-urun-yok"}).json()["total"] == 0


def test_category_filter_and_pagination(client):
    serums = client.get("/products", params={"category": "Serum"}).json()
    assert serums["total"] >= 3
    assert all(p["category"] == "Serum" for p in serums["items"])
    page = client.get("/products", params={"limit": 5, "offset": 10}).json()
    assert page["total"] == 12
    assert len(page["items"]) == 2
    assert client.get("/products", params={"limit": 500}).status_code == 422


def test_get_product_and_404(client):
    assert client.get("/products/p-temizleyici-lumen").json()["brand"] == "Lumen Lab"
    assert client.get("/products/yok").status_code == 404


def test_submit_requires_login(api):
    assert api.submit({}).status_code == 401


def test_submission_is_pending_and_visible_only_to_owner(api, client):
    owner = api.user()
    other = api.user(email="mehmet@test.dev", name="Mehmet Can")
    r = api.submit(owner)
    assert r.status_code == 201
    p = r.json()
    assert p["status"] == "pending"
    assert p["id"].startswith("p-")

    assert client.get(f"/products/{p['id']}", headers=owner).status_code == 200
    assert client.get(f"/products/{p['id']}", headers=other).status_code == 404
    assert client.get(f"/products/{p['id']}").status_code == 404
    assert client.get("/products", headers=owner).json()["total"] == 13
    assert client.get("/products", headers=other).json()["total"] == 12
    assert [x["id"] for x in client.get("/products/mine", headers=owner).json()] == [p["id"]]
    assert client.get("/products/mine", headers=other).json() == []


def test_duplicate_detection_ignores_case_and_turkish_letters(api):
    h = api.user()
    r = api.submit(h, name="NEM DENGESİ TEMİZLEYİCİ", brand="lumen lab", category="Temizleyici")
    assert r.status_code == 409
    assert api.submit(h).status_code == 201
    assert api.submit(h, name="papatya tonik", brand="BAHÇE KOZMETİK").status_code == 409


def test_duplicate_detection_also_matches_barcode(api):
    h = api.user()
    assert api.submit(h, barcode="8690000000031").status_code == 201
    assert api.submit(h, name="Bambaşka Ad", barcode="8690000000031").status_code == 409


def test_submission_validation(api):
    h = api.user()
    cases = [
        {"category": "Şampuan"},
        {"ingredients": ["Aqua"]},
        {"ingredients": ["Aqua", "x" * 101]},
        {"skinTypes": ["Mor Cilt"]},
        {"barcode": "12ab"},
        {"name": "A"},
        {"description": "x" * 501},
        {"unknownField": 1},
        # Fotoğraf zorunlu: ekip ürünü fotoğraftan doğrular.
        {"imageUrl": ""},
    ]
    for override in cases:
        assert api.submit(h, **override).status_code == 422, override


def test_submission_text_is_sanitised(api):
    h = api.user()
    p = api.submit(h, name="<script>Tonik</script>", ingredients=["  Aqua ", "Glycerin\x07"]).json()
    assert "<" not in p["name"]
    assert p["ingredients"] == ["Aqua", "Glycerin"]


def test_image_must_really_be_png_or_jpeg(api):
    h = api.user()
    assert api.submit(h, imageUrl=png_url()).status_code == 201
    fake = "data:image/png;base64," + base64.b64encode(b"<svg onload=alert(1)>").decode()
    r = api.submit(h, name="Sahte", imageUrl=fake)
    assert r.status_code == 422
    assert "uyuşmuyor" in r.json()["detail"]
    assert api.submit(h, name="Svg", imageUrl="data:image/svg+xml;base64,PHN2Zz4=").status_code == 422
    assert api.submit(h, name="Bozuk", imageUrl="data:image/png;base64,@@@").status_code == 422
    assert api.submit(h, name="Uzak", imageUrl="https://example.com/a.png").status_code == 422


def test_image_size_limit(api):
    h = api.user()
    big = png_url(PNG_1PX + b"\0" * (512 * 1024))
    r = api.submit(h, imageUrl=big)
    assert r.status_code == 422
    assert "KB" in r.json()["detail"]


def test_submissions_are_rate_limited(api):
    h = api.user()
    for i in range(10):
        assert api.submit(h, name=f"Ürün {i}").status_code == 201
    assert api.submit(h, name="Ürün 11").status_code == 429
