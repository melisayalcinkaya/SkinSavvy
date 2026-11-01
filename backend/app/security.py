import hashlib
import secrets
import unicodedata
from datetime import UTC, datetime, timedelta

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError

from .config import Settings

_hasher = PasswordHasher()
# Bilinmeyen e-postada da aynı sürede yanıt vermek için sahte özet.
_DUMMY_HASH = _hasher.hash("zamanlama-esitleme")

ALGORITHM = "HS256"


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password: str, password_hash: str | None) -> bool:
    try:
        return _hasher.verify(password_hash or _DUMMY_HASH, password) and password_hash is not None
    except (VerifyMismatchError, InvalidHashError):
        return False


def password_problem(password: str, email: str = "", name: str = "") -> str | None:
    """Şifre kuralları; uygunsa None."""
    if len(password) < 8:
        return "Şifre en az 8 karakter olmalı."
    if len(password) > 128:
        return "Şifre en fazla 128 karakter olabilir."
    if not any(c.isalpha() for c in password) or not any(c.isdigit() for c in password):
        return "Şifre en az bir harf ve bir rakam içermeli."
    lowered = password.casefold()
    local = email.split("@")[0].casefold()
    if len(local) >= 4 and local in lowered:
        return "Şifre e-posta adresini içermemeli."
    first = name.split(" ")[0].casefold() if name else ""
    if len(first) >= 4 and first in lowered:
        return "Şifre adınızı içermemeli."
    return None


def create_access_token(settings: Settings, user_id: str, role: str) -> str:
    now = datetime.now(UTC)
    payload = {
        "sub": user_id,
        "role": role,
        "typ": "access",
        "iat": now,
        "exp": now + timedelta(minutes=settings.access_token_minutes),
    }
    return jwt.encode(payload, settings.secret_key, algorithm=ALGORITHM)


def decode_access_token(settings: Settings, token: str) -> dict | None:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[ALGORITHM])
    except jwt.PyJWTError:
        return None
    return payload if payload.get("typ") == "access" else None


def new_refresh_token() -> str:
    return secrets.token_urlsafe(32)


def token_digest(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def search_key(text: str) -> str:
    """'Nem Dengesi  Temizleyici' ve 'nem dengesi temizleyıcı' aynı anahtarı versin."""
    tr = str.maketrans(
        {
            "ı": "i",
            "İ": "i",
            "I": "i",
            "ş": "s",
            "Ş": "s",
            "ğ": "g",
            "Ğ": "g",
            "ü": "u",
            "Ü": "u",
            "ö": "o",
            "Ö": "o",
            "ç": "c",
            "Ç": "c",
        }
    )
    text = unicodedata.normalize("NFKC", text).translate(tr).casefold()
    return " ".join(text.split())
