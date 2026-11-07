import enum
import uuid
from datetime import UTC, datetime

from sqlalchemy import JSON, Enum, ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


def utcnow() -> datetime:
    return datetime.now(UTC)


def new_id() -> str:
    return uuid.uuid4().hex


class Role(enum.StrEnum):
    user = "user"
    admin = "admin"


class ProductStatus(enum.StrEnum):
    # Reddetme yok: ekip eksik bilgiyi düzeltip onaylar, aynısı varsa asıl
    # ürüne bağlar (duplicate) ya da spam/sahte öneriyi siler (removed).
    approved = "approved"
    pending = "pending"
    duplicate = "duplicate"
    removed = "removed"
    # Onaylı ürün katalogdan kaldırıldı (ör. üretimden kalktı): aramada
    # görünmez, yeni kullanıcı ekleyemez; dolabında olanlarda durur.
    delisted = "delisted"


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    email: Mapped[str] = mapped_column(String(254), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(60))
    bio: Mapped[str] = mapped_column(String(160), default="")
    # Küçültülmüş profil fotoğrafı (PNG/JPEG data URL).
    avatar: Mapped[str | None] = mapped_column(Text, default=None)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[Role] = mapped_column(Enum(Role, native_enum=False), default=Role.user)
    # {"skinType": ..., "concerns": [...], "allergens": [...], "intensity": ...}
    skin_profile: Mapped[dict] = mapped_column(JSON, default=dict)
    onboarded: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)

    reviews: Mapped[list["Review"]] = relationship(
        back_populates="user", cascade="all, delete-orphan", passive_deletes=True
    )


class RefreshToken(Base):
    """Dönen (rotating) refresh token. Yalnızca SHA-256 özeti saklanır.

    Aynı girişten türeyen token'lar bir `family` paylaşır; iptal edilmiş bir
    token tekrar kullanılırsa (çalınmış olabilir) bütün aile iptal edilir.
    """

    __tablename__ = "refresh_tokens"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token_hash: Mapped[str] = mapped_column(String(64), unique=True)
    family: Mapped[str] = mapped_column(String(32), index=True)
    expires_at: Mapped[datetime]
    revoked_at: Mapped[datetime | None] = mapped_column(default=None)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (Index("ix_products_dedupe", "name_key", "brand_key"),)

    id: Mapped[str] = mapped_column(String(64), primary_key=True, default=lambda: "p-" + new_id())
    name: Mapped[str] = mapped_column(String(80))
    brand: Mapped[str] = mapped_column(String(60))
    # Yinelenen ürün kontrolü için büyük/küçük harf ve Türkçe karakter duyarsız anahtarlar.
    name_key: Mapped[str] = mapped_column(String(80))
    brand_key: Mapped[str] = mapped_column(String(60))
    category: Mapped[str] = mapped_column(String(40))
    image_url: Mapped[str] = mapped_column(Text, default="")
    ingredients: Mapped[list] = mapped_column(JSON, default=list)
    benefits: Mapped[list] = mapped_column(JSON, default=list)
    skin_types: Mapped[list] = mapped_column(JSON, default=list)
    description: Mapped[str] = mapped_column(Text, default="")
    barcode: Mapped[str | None] = mapped_column(String(14), default=None)
    status: Mapped[ProductStatus] = mapped_column(
        Enum(ProductStatus, native_enum=False), default=ProductStatus.pending, index=True
    )
    # Katalogda "Ekleyen: Zeynep K." olarak görünen ad. Öneri anında
    # yazılır; e-posta asla saklanmaz/gösterilmez.
    added_by: Mapped[str | None] = mapped_column(String(60), default=None)

    submitted_by: Mapped[str | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), index=True, default=None
    )
    # Yinelenen öneride katalogdaki asıl ürün.
    duplicate_of: Mapped[str | None] = mapped_column(ForeignKey("products.id", ondelete="SET NULL"), default=None)
    # Ekip onaylamadan önce bilgileri düzeltti mi (önerene bildirilir)?
    edited_by_team: Mapped[bool] = mapped_column(default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    reviewed_at: Mapped[datetime | None] = mapped_column(default=None)

    reviews: Mapped[list["Review"]] = relationship(
        back_populates="product", cascade="all, delete-orphan", passive_deletes=True
    )


class Review(Base):
    __tablename__ = "reviews"
    __table_args__ = (UniqueConstraint("product_id", "user_id", name="uq_review_once"),)

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    product_id: Mapped[str] = mapped_column(ForeignKey("products.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    rating: Mapped[int]
    comment: Mapped[str] = mapped_column(String(1000), default="")
    created_at: Mapped[datetime] = mapped_column(default=utcnow)
    updated_at: Mapped[datetime | None] = mapped_column(default=None)

    product: Mapped[Product] = relationship(back_populates="reviews")
    user: Mapped[User] = relationship(back_populates="reviews")
