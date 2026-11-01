from datetime import UTC, datetime, timedelta

import jwt
import pytest
from sqlalchemy import update

from app.models import RefreshToken
from app.security import password_problem, search_key, verify_password

from .conftest import PASSWORD


def test_register_returns_tokens_and_user(api):
    data = api.register()
    assert data["tokenType"] == "bearer"
    assert data["expiresIn"] == 15 * 60
    assert data["user"]["email"] == "ayse@test.dev"
    assert data["user"]["role"] == "user"
    assert data["user"]["onboarded"] is False
    assert "passwordHash" not in data["user"]


def test_email_is_case_insensitive_and_unique(api, client):
    api.register(email="Ayse@Test.dev")
    r = client.post("/auth/register", json={"name": "Başka", "email": "ayse@test.DEV", "password": PASSWORD})
    assert r.status_code == 409
    assert api.login("AYSE@test.dev", PASSWORD)["user"]["email"] == "ayse@test.dev"


@pytest.mark.parametrize(
    ("password", "message"),
    [
        ("kisa1", "en az 8"),
        ("sadeceharf", "harf ve bir rakam"),
        ("12345678", "harf ve bir rakam"),
        ("ayseyilmaz1", "e-posta"),
        ("x" * 129 + "1", "en fazla"),
    ],
)
def test_weak_passwords_rejected(client, password, message):
    r = client.post("/auth/register", json={"name": "Deniz", "email": "ayseyilmaz@test.dev", "password": password})
    assert r.status_code == 422
    assert message in str(r.json())


def test_password_must_not_contain_name():
    assert "adınızı" in password_problem("Merveguzel1", "x@y.z", "Merve Kaya")
    assert password_problem("Gizli-sifre-42", "ayse@test.dev", "Ayşe") is None


def test_name_is_cleaned(client):
    r = client.post(
        "/auth/register", json={"name": "  <b>Ali</b>   Veli ", "email": "ali@test.dev", "password": PASSWORD}
    )
    assert r.json()["user"]["name"] == "bAli/b Veli"


def test_wrong_password_and_unknown_email_get_same_answer(api, client):
    api.register()
    wrong = client.post("/auth/login", json={"email": "ayse@test.dev", "password": "Yanlis-sifre-1"})
    unknown = client.post("/auth/login", json={"email": "yok@test.dev", "password": "Yanlis-sifre-1"})
    assert wrong.status_code == unknown.status_code == 401
    assert wrong.json() == unknown.json()


def test_login_is_rate_limited_per_account(api, client):
    api.register()
    for _ in range(8):
        assert client.post("/auth/login", json={"email": "ayse@test.dev", "password": "Yanlis-1x"}).status_code == 401
    r = client.post("/auth/login", json={"email": "ayse@test.dev", "password": PASSWORD})
    assert r.status_code == 429
    assert int(r.headers["Retry-After"]) > 0


def test_register_is_rate_limited_per_ip(client):
    for i in range(5):
        r = client.post("/auth/register", json={"name": "Kişi", "email": f"k{i}@test.dev", "password": PASSWORD})
        assert r.status_code == 201
    r = client.post("/auth/register", json={"name": "Kişi", "email": "k9@test.dev", "password": PASSWORD})
    assert r.status_code == 429


def test_refresh_rotates_token(api, client):
    first = api.register()
    r = client.post("/auth/refresh", json={"refreshToken": first["refreshToken"]})
    assert r.status_code == 200
    second = r.json()
    assert second["refreshToken"] != first["refreshToken"]
    assert client.get("/me", headers=api.headers(second)).status_code == 200
    # Eski token artık geçmez.
    assert client.post("/auth/refresh", json={"refreshToken": first["refreshToken"]}).status_code == 401


def test_reusing_old_refresh_token_revokes_whole_family(api, client):
    first = api.register()
    second = client.post("/auth/refresh", json={"refreshToken": first["refreshToken"]}).json()
    # Saldırgan eski token'ı denerse kullanıcının yeni token'ı da iptal olur.
    client.post("/auth/refresh", json={"refreshToken": first["refreshToken"]})
    assert client.post("/auth/refresh", json={"refreshToken": second["refreshToken"]}).status_code == 401


def test_other_sessions_survive_family_revocation(api, client):
    phone = api.register()
    laptop = api.login("ayse@test.dev", PASSWORD)
    client.post("/auth/logout", json={"refreshToken": phone["refreshToken"]})
    assert client.post("/auth/refresh", json={"refreshToken": phone["refreshToken"]}).status_code == 401
    assert client.post("/auth/refresh", json={"refreshToken": laptop["refreshToken"]}).status_code == 200


def test_expired_refresh_token(api, client, app):
    tokens = api.register()
    with app.state.db.sessions() as s:
        s.execute(update(RefreshToken).values(expires_at=datetime.now(UTC) - timedelta(seconds=1)))
        s.commit()
    r = client.post("/auth/refresh", json={"refreshToken": tokens["refreshToken"]})
    assert r.status_code == 401
    assert "süresi" in r.json()["detail"]


def test_unknown_refresh_token_and_logout(client):
    assert client.post("/auth/refresh", json={"refreshToken": "x" * 43}).status_code == 401
    assert client.post("/auth/logout", json={"refreshToken": "x" * 43}).status_code == 204


def test_access_token_checks(api, client, app):
    tokens = api.register()
    secret = app.state.settings.secret_key
    payload = jwt.decode(tokens["accessToken"], secret, algorithms=["HS256"])

    expired = jwt.encode({**payload, "exp": datetime.now(UTC) - timedelta(seconds=5)}, secret, algorithm="HS256")
    forged = jwt.encode(payload, "baska-anahtar-" + "y" * 40, algorithm="HS256")
    wrong_type = jwt.encode({**payload, "typ": "refresh"}, secret, algorithm="HS256")
    ghost = jwt.encode({**payload, "sub": "yok"}, secret, algorithm="HS256")
    for token in (expired, forged, wrong_type, ghost, "bozuk"):
        r = client.get("/me", headers={"Authorization": f"Bearer {token}"})
        assert r.status_code == 401
        assert r.headers["WWW-Authenticate"] == "Bearer"
    assert client.get("/me").status_code == 401


def test_refresh_token_is_stored_hashed(api, app):
    tokens = api.register()
    with app.state.db.sessions() as s:
        stored = s.query(RefreshToken).one()
        assert stored.token_hash != tokens["refreshToken"]
        assert len(stored.token_hash) == 64


def test_verify_password_edge_cases():
    assert verify_password("herhangi", None) is False
    assert verify_password("herhangi", "bozuk-ozet") is False


def test_search_key_turkish():
    assert search_key("  Işıltı  ŞAMPUANI ") == search_key("isilti sampuani")
