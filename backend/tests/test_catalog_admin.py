from .conftest import PNG_URL

PRODUCT = "p-temizleyici-lumen"


def _edit_body(**overrides):
    return {
        "name": "Nem Dengesi Temizleyici",
        "brand": "Lumen Lab",
        "category": "Temizleyici",
        "skinTypes": ["Tüm Cilt Tipleri"],
        "ingredients": ["Aqua", "Glycerin", "Ceramide NP"],
        "description": "Ekip düzeltti.",
        "imageUrl": PNG_URL,
        **overrides,
    }


def test_delist_hides_from_catalog_but_keeps_detail_and_reviews(api, client):
    admin, user = api.admin(), api.user()
    assert (
        client.put(
            f"/products/{PRODUCT}/reviews/me", json={"rating": 5, "comment": "Çok iyi."}, headers=user
        ).status_code
        == 200
    )

    r = client.post(f"/admin/products/{PRODUCT}/delist", headers=admin)
    assert r.status_code == 200
    assert r.json()["status"] == "delisted"

    # Listede ve aramada yok...
    ids = {p["id"] for p in client.get("/products", params={"limit": 100}).json()["items"]}
    assert PRODUCT not in ids
    assert client.get("/products", params={"q": "nem dengesi"}).json()["total"] == 0
    # ...ama dolabında olan için detay ve yorumlar açık; yorumunu güncelleyebilir.
    assert client.get(f"/products/{PRODUCT}").json()["status"] == "delisted"
    assert len(client.get(f"/products/{PRODUCT}/reviews").json()) >= 1
    assert (
        client.put(
            f"/products/{PRODUCT}/reviews/me", json={"rating": 4, "comment": "Hâlâ iyi."}, headers=user
        ).status_code
        == 200
    )

    listed = client.get("/admin/products", headers=admin).json()
    assert [p["id"] for p in listed] == [PRODUCT]
    assert client.post(f"/admin/products/{PRODUCT}/delist", headers=admin).status_code == 409

    assert client.post(f"/admin/products/{PRODUCT}/relist", headers=admin).json()["status"] == "approved"
    ids = {p["id"] for p in client.get("/products", params={"limit": 100}).json()["items"]}
    assert PRODUCT in ids
    assert client.post(f"/admin/products/{PRODUCT}/relist", headers=admin).status_code == 409


def test_delisted_product_can_be_suggested_again_but_not_relisted_twice(api, client):
    admin, user = api.admin(), api.user()
    lumen = client.get(f"/products/{PRODUCT}").json()
    client.post(f"/admin/products/{PRODUCT}/delist", headers=admin)
    # Kaldırılan ürün yinelenen kontrolüne takılmaz; yeniden önerilebilir.
    r = api.submit(user, name=lumen["name"], brand=lumen["brand"])
    assert r.status_code == 201
    client.post(f"/admin/submissions/{r.json()['id']}/approve", headers=admin)
    # Artık aynı ürün katalogda: eskisi geri alınırsa çift olur.
    assert client.post(f"/admin/products/{PRODUCT}/relist", headers=admin).status_code == 409


def test_admin_edits_catalog_product(api, client):
    admin = api.admin()
    r = client.put(f"/admin/products/{PRODUCT}", json=_edit_body(), headers=admin)
    assert r.status_code == 200, r.text
    body = client.get(f"/products/{PRODUCT}").json()
    assert body["ingredients"] == ["Aqua", "Glycerin", "Ceramide NP"]
    assert body["description"] == "Ekip düzeltti."

    other = client.get("/products", params={"limit": 100}).json()["items"]
    clash = next(p for p in other if p["id"] != PRODUCT)
    r = client.put(
        f"/admin/products/{PRODUCT}", json=_edit_body(name=clash["name"], brand=clash["brand"]), headers=admin
    )
    assert r.status_code == 409
    assert client.put(f"/admin/products/{PRODUCT}", json=_edit_body(imageUrl=""), headers=admin).status_code == 422
    fake = "data:image/png;base64,PHNjcmlwdD4="
    assert client.put(f"/admin/products/{PRODUCT}", json=_edit_body(imageUrl=fake), headers=admin).status_code == 422


def test_catalog_admin_endpoints_require_admin_and_catalog_products(api, client):
    admin, user = api.admin(), api.user()
    pid = api.submit(user).json()["id"]
    for method, path, kw in [
        ("get", "/admin/products", {}),
        ("put", f"/admin/products/{PRODUCT}", {"json": _edit_body()}),
        ("post", f"/admin/products/{PRODUCT}/delist", {}),
        ("post", f"/admin/products/{PRODUCT}/relist", {}),
    ]:
        assert getattr(client, method)(path, headers=user, **kw).status_code == 403
        assert getattr(client, method)(path, **kw).status_code == 401
    # Bekleyen öneri katalog işlemiyle değil, karar uç noktalarıyla yönetilir.
    assert client.post(f"/admin/products/{pid}/delist", headers=admin).status_code == 404
    assert client.put(f"/admin/products/{pid}", json=_edit_body(name="Başka"), headers=admin).status_code == 404
    assert client.get("/admin/products", params={"status": "pending"}, headers=admin).status_code == 422


def test_user_withdraws_own_pending_submission(api, client):
    owner, other, admin = api.user(), api.user(email="baska@test.dev", name="Can Demir"), api.admin()
    pid = api.submit(owner).json()["id"]
    # Başkası geri çekemez; varlığı da sızmaz.
    assert client.delete(f"/products/{pid}", headers=other).status_code == 404
    assert client.delete(f"/products/{pid}").status_code == 401
    assert client.delete(f"/products/{pid}", headers=owner).status_code == 204
    assert client.get("/products/mine", headers=owner).json() == []
    assert client.get("/admin/submissions", headers=admin).json() == []
    # Aynı ürün yeniden önerilebilir.
    pid = api.submit(owner).json()["id"]
    client.post(f"/admin/submissions/{pid}/approve", headers=admin)
    # Karar verilmiş öneri geri çekilemez; katalog ürünü kullanıcı silemez.
    assert client.delete(f"/products/{pid}", headers=owner).status_code == 409
    assert client.delete(f"/products/{PRODUCT}", headers=owner).status_code == 404


def test_account_deletion_keeps_delisted_catalog_products(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner).json()["id"]
    client.post(f"/admin/submissions/{pid}/approve", headers=admin)
    client.post(f"/admin/products/{pid}/delist", headers=admin)
    assert client.delete("/me", headers=owner).status_code == 204
    assert client.get(f"/products/{pid}").json()["status"] == "delisted"
