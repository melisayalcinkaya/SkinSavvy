import base64

import pytest
from fastapi.testclient import TestClient

from app.config import Settings
from app.main import create_app

PASSWORD = "Gizli-sifre-42"
ADMIN = {"email": "admin@test.dev", "password": "Yonetici-sifre-77"}
PNG_1PX = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
)
PNG_URL = "data:image/png;base64," + base64.b64encode(PNG_1PX).decode()


def make_settings(**overrides) -> Settings:
    base = {
        "database_url": "sqlite://",
        "environment": "test",
        "secret_key": "test-anahtari-" + "x" * 40,
        "admin_email": ADMIN["email"],
        "admin_password": ADMIN["password"],
    }
    return Settings(**{**base, **overrides})


@pytest.fixture
def app():
    return create_app(make_settings())


@pytest.fixture
def client(app):
    with TestClient(app) as c:
        yield c


class Api:
    """Testleri kısaltan küçük yardımcı."""

    def __init__(self, client: TestClient):
        self.c = client

    def register(self, email="ayse@test.dev", name="Ayşe Yılmaz", password=PASSWORD):
        r = self.c.post("/auth/register", json={"name": name, "email": email, "password": password})
        assert r.status_code == 201, r.text
        return r.json()

    def login(self, email, password):
        r = self.c.post("/auth/login", json={"email": email, "password": password})
        assert r.status_code == 200, r.text
        return r.json()

    def headers(self, tokens) -> dict:
        return {"Authorization": f"Bearer {tokens['accessToken']}"}

    def user(self, email="ayse@test.dev", name="Ayşe Yılmaz") -> dict:
        return self.headers(self.register(email=email, name=name))

    def admin(self) -> dict:
        return self.headers(self.login(**ADMIN))

    def submit(self, headers, **overrides):
        body = {
            "name": "Papatya Tonik",
            "brand": "Bahçe Kozmetik",
            "category": "Tonik",
            "skinTypes": ["Hassas Cilt"],
            "ingredients": ["Aqua", "Chamomilla Recutita Flower Water", "Glycerin"],
            "description": "Yatıştırıcı tonik.",
            "imageUrl": PNG_URL,
            **overrides,
        }
        return self.c.post("/products", json=body, headers=headers)


@pytest.fixture
def api(client):
    return Api(client)
