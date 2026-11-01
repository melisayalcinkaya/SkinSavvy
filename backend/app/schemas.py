"""İstek/yanıt şemaları. Alan adları uygulamadaki JSON ile aynı (camelCase)."""

import base64
import re
from datetime import datetime
from typing import Annotated

from pydantic import (
    AfterValidator,
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    StringConstraints,
    field_validator,
)
from pydantic.alias_generators import to_camel

SKIN_TYPES = ("Karma Cilt", "Kuru Cilt", "Yağlı Cilt", "Normal Cilt", "Hassas Cilt")
CONCERNS = (
    "Sivilce / Akne",
    "Leke / Renk Eşitsizliği",
    "Kırışıklık / Anti-Aging",
    "Gözenek",
    "Nemsizlik",
)
INTENSITIES = ("Basit (2-3 adım)", "Orta (4-6 adım)", "Detaylı (7+ adım)")
CATEGORIES = (
    "Temizleyici",
    "Tonik",
    "Serum",
    "Nemlendirici",
    "Güneş Kremi",
    "Maske",
    "Peeling",
    "Göz Kremi",
    "Yağ",
    "Diğer",
)
PRODUCT_SKIN_TYPES = ("Tüm Cilt Tipleri", *SKIN_TYPES)

_CONTROL = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f<>]")


def clean(value: str) -> str:
    """Kontrol karakterlerini ve HTML açısını kaldırır, boşlukları sadeleştirir."""
    return " ".join(_CONTROL.sub("", value).split())


Clean = Annotated[str, AfterValidator(clean)]


def text(min_len: int, max_len: int):
    return Annotated[
        str,
        AfterValidator(clean),
        StringConstraints(min_length=min_len, max_length=max_len),
    ]


class Schema(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True, from_attributes=True, extra="forbid")


# ── Hesap ────────────────────────────────────────────────────────────


class SkinProfile(Schema):
    skin_type: str | None = None
    concerns: list[str] = Field(default_factory=list, max_length=len(CONCERNS))
    allergens: list[Annotated[str, AfterValidator(clean), StringConstraints(min_length=1, max_length=40)]] = Field(
        default_factory=list, max_length=30
    )
    intensity: str | None = None

    @field_validator("skin_type")
    @classmethod
    def _skin_type(cls, v: str | None) -> str | None:
        if v is not None and v not in SKIN_TYPES:
            raise ValueError("Geçersiz cilt tipi.")
        return v

    @field_validator("concerns")
    @classmethod
    def _concerns(cls, v: list[str]) -> list[str]:
        if any(c not in CONCERNS for c in v):
            raise ValueError("Geçersiz cilt endişesi.")
        return sorted(set(v))

    @field_validator("allergens")
    @classmethod
    def _allergens(cls, v: list[str]) -> list[str]:
        return sorted({a for a in v if a})

    @field_validator("intensity")
    @classmethod
    def _intensity(cls, v: str | None) -> str | None:
        if v is not None and v not in INTENSITIES:
            raise ValueError("Geçersiz rutin yoğunluğu.")
        return v


class RegisterIn(Schema):
    name: text(2, 60)  # type: ignore[valid-type]
    email: EmailStr
    # Asıl kurallar security.password_problem'da (Türkçe mesajla); burası yalnızca
    # aşırı uzun gövdelerle argon2'yi yormayı engeller.
    password: str = Field(max_length=1024)


class LoginIn(Schema):
    email: EmailStr
    password: str = Field(max_length=128)


class RefreshIn(Schema):
    refresh_token: str = Field(min_length=20, max_length=200)


class UserOut(Schema):
    id: str
    name: str
    email: str
    bio: str
    avatar: str | None
    role: str
    skin_profile: SkinProfile
    onboarded: bool
    created_at: datetime


class TokensOut(Schema):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"  # noqa: S105 - şifre değil, OAuth2 token türü
    expires_in: int
    user: UserOut


class UserUpdate(Schema):
    name: text(2, 60) | None = None  # type: ignore[valid-type]
    bio: text(0, 160) | None = None  # type: ignore[valid-type]
    # "" fotoğrafı kaldırır; boyut ve tür router'da doğrulanır.
    avatar: str | None = Field(default=None, max_length=400_000)
    skin_profile: SkinProfile | None = None
    onboarded: bool | None = None


# ── Ürünler ──────────────────────────────────────────────────────────

_DATA_URL = re.compile(r"^data:image/(png|jpeg);base64,([A-Za-z0-9+/=]+)$")
_SIGNATURES = {"png": b"\x89PNG\r\n\x1a\n", "jpeg": b"\xff\xd8\xff"}


def check_image(value: str, max_bytes: int) -> str:
    """Yalnızca içeriği gerçekten PNG/JPEG olan, boyutu sınırlı data URL kabul edilir."""
    if not value:
        return ""
    m = _DATA_URL.match(value)
    if not m:
        raise ValueError("Görsel PNG ya da JPEG data URL olmalı.")
    try:
        raw = base64.b64decode(m.group(2), validate=True)
    except ValueError as e:
        raise ValueError("Görsel çözülemedi.") from e
    if len(raw) > max_bytes:
        raise ValueError(f"Görsel en fazla {max_bytes // 1024} KB olabilir.")
    if not raw.startswith(_SIGNATURES[m.group(1)]):
        raise ValueError("Dosya içeriği bildirilen görsel türüyle uyuşmuyor.")
    return value


class ProductIn(Schema):
    name: text(2, 80)  # type: ignore[valid-type]
    brand: text(2, 60)  # type: ignore[valid-type]
    category: str
    skin_types: list[str] = Field(default_factory=list, max_length=6)
    ingredients: list[Annotated[str, AfterValidator(clean), StringConstraints(min_length=1, max_length=100)]] = Field(
        min_length=2, max_length=150
    )
    description: text(0, 500) = ""  # type: ignore[valid-type]
    barcode: str | None = Field(default=None, pattern=r"^\d{8,14}$")
    # Fotoğraf zorunlu: ekip ürünü fotoğraftan doğrular. İçerik ve boyut
    # router'da check_image ile denetlenir.
    image_url: str = Field(min_length=1, max_length=800_000)

    @field_validator("category")
    @classmethod
    def _category(cls, v: str) -> str:
        if v not in CATEGORIES:
            raise ValueError("Geçersiz kategori.")
        return v

    @field_validator("skin_types")
    @classmethod
    def _skin_types(cls, v: list[str]) -> list[str]:
        if any(s not in PRODUCT_SKIN_TYPES for s in v):
            raise ValueError("Geçersiz cilt tipi.")
        return list(dict.fromkeys(v))


class ProductOut(Schema):
    id: str
    name: str
    brand: str
    category: str
    image_url: str
    rating: float
    review_count: int
    ingredients: list[str]
    benefits: list[str]
    skin_types: list[str]
    description: str
    barcode: str | None
    status: str
    duplicate_of: str | None = None
    edited_by_team: bool = False
    added_by: str | None = None
    approved_at: str | None = None
    created_at: str | None = None


class ProductPage(Schema):
    items: list[ProductOut]
    total: int


class DuplicateIn(Schema):
    original_id: str = Field(min_length=1, max_length=64)


# ── Yorumlar ─────────────────────────────────────────────────────────


class ReviewIn(Schema):
    rating: int = Field(ge=1, le=5)
    comment: text(0, 1000) = ""  # type: ignore[valid-type]


class ReviewOut(Schema):
    id: str
    product_id: str
    product_name: str
    brand: str
    author: str
    rating: int
    comment: str
    created_at: datetime
    updated_at: datetime | None
    mine: bool = False
