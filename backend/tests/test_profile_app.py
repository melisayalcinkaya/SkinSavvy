import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.config import Settings
from app.db import make_engine
from app.main import create_app
from app.models import Product, Review, User
from app.seed import seed

from .conftest import PASSWORD, make_settings


def test_bio_and_avatar(api, client):
    import base64

    from .conftest import PNG_1PX

    h = api.user()
    png = "data:image/png;base64," + base64.b64encode(PNG_1PX).decode()
    me = client.patch("/me", headers=h, json={"bio": "Hassas ciltliyim.", "avatar": png}).json()
    assert me["bio"] == "Hassas ciltliyim."
    assert me["avatar"] == png
    assert client.patch("/me", headers=h, json={"avatar": "data:image/png;base64,QUJD"}).status_code == 422
    assert client.patch("/me", headers=h, json={"bio": "x" * 161}).status_code == 422
    assert client.patch("/me", headers=h, json={"avatar": ""}).json()["avatar"] is None


def test_get_and_update_profile(api, client):
    h = api.user()
    r = client.patch(
        "/me",
        headers=h,
        json={
            "name": "Ayşe Kaya",
            "onboarded": True,
            "skinProfile": {
                "skinType": "Hassas Cilt",
                "concerns": ["Nemsizlik", "Gözenek", "Nemsizlik"],
                "allergens": ["Parfüm / Fragrance", "propolis", "propolis"],
                "intensity": "Basit (2-3 adım)",
            },
        },
    )
    assert r.status_code == 200
    me = client.get("/me", headers=h).json()
    assert me["name"] == "Ayşe Kaya"
    assert me["onboarded"] is True
    assert me["skinProfile"]["concerns"] == ["Gözenek", "Nemsizlik"]
    assert me["skinProfile"]["allergens"] == ["Parfüm / Fragrance", "propolis"]


@pytest.mark.parametrize(
    "profile",
    [
        {"skinType": "Mor Cilt"},
        {"concerns": ["Saç dökülmesi"]},
        {"intensity": "Çok"},
        {"allergens": ["x" * 41]},
    ],
)
def test_profile_validation(api, client, profile):
    h = api.user()
    assert client.patch("/me", headers=h, json={"skinProfile": profile}).status_code == 422


def test_delete_account_removes_private_data_keeps_approved_products(api, client, app):
    h = api.user()
    user_id = client.get("/me", headers=h).json()["id"]
    pending = api.submit(h).json()["id"]
    approved = api.submit(h, name="Onaylı Krem", category="Nemlendirici").json()["id"]
    client.post(f"/admin/submissions/{approved}/approve", headers=api.admin())
    client.put("/products/p-temizleyici-lumen/reviews/me", json={"rating": 5}, headers=h)

    assert client.delete("/me", headers=h).status_code == 204
    assert client.get("/me", headers=h).status_code == 401
    with app.state.db.sessions() as s:
        assert s.get(Product, pending) is None
        assert s.get(Product, approved).submitted_by is None
        assert s.query(Review).filter_by(user_id=user_id).count() == 0
        assert s.query(Review).count() == 12  # topluluk yorumları yerinde
        assert s.query(User).filter_by(email="ayse@test.dev").count() == 0
    assert client.post("/auth/login", json={"email": "ayse@test.dev", "password": PASSWORD}).status_code == 401


def test_demo_account_is_seeded(client):
    r = client.post("/auth/login", json={"email": "demo@skinsavvy.app", "password": "demo-sifre-2026"})
    assert r.status_code == 200
    user = r.json()["user"]
    assert user["onboarded"] is True
    assert user["skinProfile"]["allergens"] == ["Parfüm / Fragrance"]


def test_seed_is_idempotent_and_admin_optional():
    app = create_app(make_settings(admin_email="", admin_password=""))
    with TestClient(app) as c, app.state.db.sessions() as s:
        assert c.post("/auth/login", json={"email": "admin@test.dev", "password": "x" * 8}).status_code == 401
        seed(s, app.state.settings)
        seed(s, app.state.settings)
        assert s.query(Product).count() == 12
        # demo hesabı + 4 topluluk yazarı; ikinci yükleme çoğaltmaz
        assert s.query(User).count() == 5
        assert s.query(Review).count() == 12


def test_security_headers_and_cors(client):
    r = client.get("/health", headers={"Origin": "https://melisayalcinkaya.github.io"})
    assert r.json() == {"status": "ok"}
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert r.headers["X-Frame-Options"] == "DENY"
    assert "default-src 'none'" in r.headers["Content-Security-Policy"]
    assert r.headers["Access-Control-Allow-Origin"] == "https://melisayalcinkaya.github.io"
    assert "Strict-Transport-Security" not in r.headers

    evil = client.get("/health", headers={"Origin": "https://kotu-site.example"})
    assert "Access-Control-Allow-Origin" not in evil.headers
    # Swagger arayüzü çalışabilsin diye dokümanlarda CSP yok.
    assert "Content-Security-Policy" not in client.get("/docs").headers


def test_production_settings():
    with pytest.raises(ValidationError):
        Settings(environment="production", secret_key="")
    with pytest.raises(ValidationError):
        Settings(environment="production", secret_key="kisa")
    s = Settings(environment="production", secret_key="u" * 40, database_url="sqlite://")
    app = create_app(s)
    with TestClient(app) as c:
        assert "max-age" in c.get("/health").headers["Strict-Transport-Security"]


def test_dev_settings_generate_secret():
    assert len(Settings(environment="development", secret_key="").secret_key) >= 32


def test_forwarded_for_only_when_trusted(client, app):
    """Başlık güvenilmiyorsa sahte IP ile hız sınırı aşılamaz."""
    for i in range(5):
        client.post(
            "/auth/register",
            json={"name": "Kişi", "email": f"f{i}@test.dev", "password": PASSWORD},
            headers={"X-Forwarded-For": f"10.0.0.{i}"},
        )
    r = client.post(
        "/auth/register",
        json={"name": "Kişi", "email": "f9@test.dev", "password": PASSWORD},
        headers={"X-Forwarded-For": "10.0.0.99"},
    )
    assert r.status_code == 429


def test_trusted_forwarded_for_separates_clients():
    app = create_app(make_settings(trust_forwarded_for=True))
    with TestClient(app) as c:
        for i in range(6):
            r = c.post(
                "/auth/register",
                json={"name": "Kişi", "email": f"t{i}@test.dev", "password": PASSWORD},
                headers={"X-Forwarded-For": f"10.0.0.{i}, 172.16.0.1"},
            )
            assert r.status_code == 201


def test_postgres_url_normalisation():
    for url in ("postgres://u:p@h/db", "postgresql://u:p@h/db"):
        try:
            engine = make_engine(url)
        except ModuleNotFoundError:  # psycopg yalnızca üretim imajında kurulu
            pytest.skip("psycopg kurulu değil")
        assert engine.url.drivername == "postgresql+psycopg"
