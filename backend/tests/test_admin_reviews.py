import base64

from .conftest import PNG_URL

PRODUCT = "p-temizleyici-lumen"


def test_admin_endpoints_need_admin_role(api, client):
    user = api.user()
    assert client.get("/admin/submissions").status_code == 401
    assert client.get("/admin/submissions", headers=user).status_code == 403
    assert client.post("/admin/submissions/x/approve", headers=user).status_code == 403


def test_approve_makes_product_public(api, client):
    owner = api.user()
    pid = api.submit(owner).json()["id"]
    admin = api.admin()

    pending = client.get("/admin/submissions", headers=admin).json()
    assert [p["id"] for p in pending] == [pid]

    r = client.post(f"/admin/submissions/{pid}/approve", headers=admin)
    assert r.status_code == 200
    assert r.json()["status"] == "approved"
    assert client.get(f"/products/{pid}").status_code == 200
    assert client.get("/admin/submissions", headers=admin).json() == []
    assert client.post(f"/admin/submissions/{pid}/approve", headers=admin).status_code == 409


def _decide(client, admin, pid, action, json=None):
    return client.post(f"/admin/submissions/{pid}/{action}", json=json, headers=admin)


def test_reject_endpoint_no_longer_exists(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner).json()["id"]
    assert _decide(client, admin, pid, "reject", {"reason": "Eksik"}).status_code == 404


def test_approve_with_edits_updates_fields_and_flags_owner(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner, name="papatya tnik").json()["id"]
    edited = {
        "name": "Papatya Tonik",
        "brand": "Bahçe Kozmetik",
        "category": "Tonik",
        "skinTypes": ["Hassas Cilt", "Kuru Cilt"],
        "ingredients": ["Aqua", "Chamomilla Recutita Flower Water", "Glycerin", "Allantoin"],
        "description": "Ekip düzeltti.",
        "barcode": "8690000000017",
        "imageUrl": PNG_URL,
    }
    r = _decide(client, admin, pid, "approve", edited)
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["status"] == "approved"
    assert body["name"] == "Papatya Tonik"
    assert body["editedByTeam"] is True
    assert body["barcode"] == "8690000000017"
    # Herkes düzeltilmiş hâli görür; "ekip düzenledi" bilgisi yalnızca önerene.
    public = client.get(f"/products/{pid}").json()
    assert public["ingredients"][-1] == "Allantoin"
    assert public["editedByTeam"] is False
    assert client.get("/products/mine", headers=owner).json()[0]["editedByTeam"] is True
    # Yeni ad/barkod başkasına çarpmasın diye aranır.
    assert client.get("/products", params={"q": "papatya tonik"}).json()["total"] == 1


def test_approve_edit_is_validated(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner).json()["id"]
    lumen = client.get(f"/products/{PRODUCT}").json()
    clash = {
        "name": lumen["name"],
        "brand": lumen["brand"],
        "category": "Tonik",
        "skinTypes": [],
        "ingredients": ["Aqua", "Glycerin"],
        "imageUrl": PNG_URL,
    }
    # Katalogdaki ürünle aynı ada çevrilemez: yinelenen olarak işaretlenmeli.
    assert _decide(client, admin, pid, "approve", clash).status_code == 409
    # Fotoğraf zorunlu ve gerçekten görsel olmalı.
    assert _decide(client, admin, pid, "approve", {**clash, "name": "Yeni Ad", "imageUrl": ""}).status_code == 422
    fake = "data:image/png;base64," + base64.b64encode(b"<script>").decode()
    assert _decide(client, admin, pid, "approve", {**clash, "name": "Yeni Ad", "imageUrl": fake}).status_code == 422
    assert client.get("/products/mine", headers=owner).json()[0]["status"] == "pending"


def test_duplicate_links_to_original_and_hides_submission(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner, name="Lumen Temizleyici").json()["id"]

    assert _decide(client, admin, pid, "duplicate", {"originalId": "yok"}).status_code == 422
    assert _decide(client, admin, pid, "duplicate", {"originalId": pid}).status_code == 422
    other = api.submit(owner, name="Başka Ürün").json()["id"]
    # Asıl ürün bekleyen bir öneri olamaz.
    assert _decide(client, admin, pid, "duplicate", {"originalId": other}).status_code == 422

    r = _decide(client, admin, pid, "duplicate", {"originalId": PRODUCT})
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "duplicate"
    assert r.json()["duplicateOf"] == PRODUCT
    assert r.json()["imageUrl"] == ""

    mine = {p["id"]: p for p in client.get("/products/mine", headers=owner).json()}
    assert mine[pid]["duplicateOf"] == PRODUCT
    # Yinelenen öneri katalogda görünmez, önerene bile.
    assert client.get(f"/products/{pid}", headers=owner).status_code == 404
    listed = {p["id"] for p in client.get("/products", headers=owner).json()["items"]}
    assert pid not in listed and other in listed
    dup = client.get("/admin/submissions", params={"status": "duplicate"}, headers=admin).json()
    assert [p["id"] for p in dup] == [pid]
    assert _decide(client, admin, pid, "remove").status_code == 409


def test_remove_deletes_content_and_frees_the_name(api, client):
    owner, admin = api.user(), api.admin()
    pid = api.submit(owner, barcode="8690000000024").json()["id"]
    r = _decide(client, admin, pid, "remove")
    assert r.status_code == 200
    body = r.json()
    assert body["status"] == "removed"
    assert body["imageUrl"] == "" and body["ingredients"] == [] and body["barcode"] is None

    mine = client.get("/products/mine", headers=owner).json()
    assert [p["status"] for p in mine] == ["removed"]
    assert client.get(f"/products/{pid}", headers=owner).status_code == 404
    # Silinen öneri yinelenen kontrolüne takılmaz; gerçek ürün yeniden önerilebilir.
    assert api.submit(owner, barcode="8690000000024").status_code == 201


def test_seed_products_cannot_be_moderated(api, client):
    admin = api.admin()
    assert client.post(f"/admin/submissions/{PRODUCT}/approve", headers=admin).status_code == 404
    for action in ("duplicate", "remove"):
        r = client.post(f"/admin/submissions/{PRODUCT}/{action}", json={"originalId": PRODUCT}, headers=admin)
        assert r.status_code == 404
    assert client.post("/admin/submissions/yok/remove", headers=admin).status_code == 404


def test_review_upsert_and_rating(api, client):
    h = api.user()
    r = client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 1, "comment": "Bana uymadı."}, headers=h)
    assert r.status_code == 200
    review = r.json()
    assert review["author"] == "Ayşe Y."
    assert review["mine"] is True
    assert review["updatedAt"] is None

    # Puan yalnızca gerçek yorumlardan: topluluktan 5 ve 4, Ayşe'den 1.
    product = client.get(f"/products/{PRODUCT}").json()
    assert product["reviewCount"] == 3
    assert product["rating"] == round((5 + 4 + 1) / 3, 1)

    # Aynı kullanıcı ikinci kez yazarsa yorum güncellenir, yeni kayıt açılmaz.
    r = client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 5, "comment": "Fikrim değişti"}, headers=h)
    assert r.json()["id"] == review["id"]
    assert r.json()["updatedAt"] is not None
    assert client.get(f"/products/{PRODUCT}").json()["reviewCount"] == 3


def test_reviews_list_hides_email_and_marks_mine(api, client):
    a = api.user()
    b = api.user(email="mehmet@test.dev", name="Mehmet")
    client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 4}, headers=a)
    client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 3}, headers=b)

    listed = client.get(f"/products/{PRODUCT}/reviews", headers=b).json()
    assert {"Ayşe Y.", "Mehmet", "Zeynep K.", "Mert Y."} == {r["author"] for r in listed}
    assert [r["mine"] for r in listed if r["author"] == "Mehmet"] == [True]
    assert "test.dev" not in str(listed)
    assert client.get("/products/yok/reviews").status_code == 404


def test_review_validation_and_pending_products(api, client):
    h = api.user()
    for body in ({"rating": 0}, {"rating": 6}, {"rating": 3, "comment": "x" * 1001}):
        assert client.put(f"/products/{PRODUCT}/reviews/me", json=body, headers=h).status_code == 422
    pid = api.submit(h).json()["id"]
    r = client.put(f"/products/{pid}/reviews/me", json={"rating": 5}, headers=h)
    assert r.status_code == 409
    assert client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 5}).status_code == 401


def test_delete_review_and_my_reviews(api, client):
    h = api.user()
    client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 4, "comment": "İyi"}, headers=h)
    mine = client.get("/me/reviews", headers=h).json()
    assert [r["productName"] for r in mine] == ["Nem Dengesi Temizleyici"]
    assert client.delete(f"/products/{PRODUCT}/reviews/me", headers=h).status_code == 204
    assert client.delete(f"/products/{PRODUCT}/reviews/me", headers=h).status_code == 404
    assert client.get("/me/reviews", headers=h).json() == []


def test_approved_submission_shows_adder_and_date(api, client):
    owner = api.user()
    pid = api.submit(owner).json()["id"]
    assert api.submit(owner, name="Başka Tonik").json()["approvedAt"] is None
    client.post(f"/admin/submissions/{pid}/approve", headers=api.admin())
    p = client.get(f"/products/{pid}").json()
    assert p["addedBy"] == "Ayşe Y."
    assert p["approvedAt"] is not None
    assert p["rating"] == 0
    assert p["reviewCount"] == 0
    assert "price" not in p
    assert "test.dev" not in str(p)


def test_admin_role_is_visible_to_client(api, client):
    assert client.get("/me", headers=api.admin()).json()["role"] == "admin"
    assert client.get("/me", headers=api.user()).json()["role"] == "user"
