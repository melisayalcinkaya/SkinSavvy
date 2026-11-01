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


def test_reject_reason_is_shown_only_to_owner(api, client):
    owner = api.user()
    pid = api.submit(owner).json()["id"]
    admin = api.admin()

    assert client.post(f"/admin/submissions/{pid}/reject", json={"reason": ""}, headers=admin).status_code == 422
    r = client.post(f"/admin/submissions/{pid}/reject", json={"reason": "İçerik listesi eksik."}, headers=admin)
    assert r.json()["status"] == "rejected"

    mine = client.get("/products/mine", headers=owner).json()[0]
    assert mine["rejectReason"] == "İçerik listesi eksik."
    rejected = client.get("/admin/submissions", params={"status": "rejected"}, headers=admin).json()
    assert [p["id"] for p in rejected] == [pid]
    # Reddedilen ürün düzeltilip yeniden önerilebilir.
    assert api.submit(owner).status_code == 201


def test_seed_products_cannot_be_moderated(api, client):
    admin = api.admin()
    assert client.post(f"/admin/submissions/{PRODUCT}/approve", headers=admin).status_code == 404
    assert client.post("/admin/submissions/yok/reject", json={"reason": "Yok"}, headers=admin).status_code == 404


def test_review_upsert_and_rating(api, client):
    h = api.user()
    r = client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 1, "comment": "Bana uymadı."}, headers=h)
    assert r.status_code == 200
    review = r.json()
    assert review["author"] == "Ayşe Y."
    assert review["mine"] is True
    assert review["updatedAt"] is None

    product = client.get(f"/products/{PRODUCT}").json()
    assert product["reviewCount"] == 1241
    assert product["rating"] == round((4.8 * 1240 + 1) / 1241, 1)

    # Aynı kullanıcı ikinci kez yazarsa yorum güncellenir, yeni kayıt açılmaz.
    r = client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 5, "comment": "Fikrim değişti"}, headers=h)
    assert r.json()["id"] == review["id"]
    assert r.json()["updatedAt"] is not None
    assert client.get(f"/products/{PRODUCT}").json()["reviewCount"] == 1241


def test_reviews_list_hides_email_and_marks_mine(api, client):
    a = api.user()
    b = api.user(email="mehmet@test.dev", name="Mehmet")
    client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 4}, headers=a)
    client.put(f"/products/{PRODUCT}/reviews/me", json={"rating": 3}, headers=b)

    listed = client.get(f"/products/{PRODUCT}/reviews", headers=b).json()
    assert {r["author"] for r in listed} == {"Ayşe Y.", "Mehmet"}
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
