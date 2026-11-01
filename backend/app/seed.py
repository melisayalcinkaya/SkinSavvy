"""Demo kataloğu (uygulamayla aynı JSON), demo hesabı ve isteğe bağlı yönetici."""

import json
import secrets
from datetime import UTC, datetime
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from .config import Settings
from .models import Product, ProductStatus, Review, Role, User
from .security import hash_password, search_key

DATA = Path(__file__).parent / "data"
CATALOG_PATH = DATA / "demo_catalog.json"
REVIEWS_PATH = DATA / "demo_reviews.json"

DEMO_PROFILE = {
    "skinType": "Karma Cilt",
    "concerns": ["Leke / Renk Eşitsizliği", "Sivilce / Akne"],
    "allergens": ["Parfüm / Fragrance"],
    "intensity": "Orta (4-6 adım)",
}


def load_catalog() -> list[dict]:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


def load_reviews() -> list[dict]:
    return json.loads(REVIEWS_PATH.read_text(encoding="utf-8"))


def seed(db: Session, settings: Settings) -> None:
    if settings.seed_demo:
        for item in load_catalog():
            p = db.get(Product, item["id"]) or Product(id=item["id"])
            p.name = item["name"]
            p.brand = item["brand"]
            p.name_key = search_key(item["name"])
            p.brand_key = search_key(item["brand"])
            p.category = item["category"]
            p.image_url = item.get("imageUrl") or ""
            p.ingredients = item.get("ingredients") or []
            p.benefits = item.get("benefits") or []
            p.skin_types = item.get("skinTypes") or []
            p.description = item.get("description") or ""
            p.barcode = item.get("barcode")
            p.added_by = item.get("addedBy")
            p.status = ProductStatus.approved
            if approved := item.get("approvedAt"):
                p.reviewed_at = datetime.fromisoformat(approved).replace(tzinfo=UTC)
            db.add(p)
        db.flush()
        _seed_reviews(db)
        _ensure_user(db, settings.demo_email, settings.demo_password, "Ece Demir", Role.user, DEMO_PROFILE)

    if settings.admin_email and settings.admin_password:
        _ensure_user(db, settings.admin_email, settings.admin_password, "Yönetici", Role.admin, {})
    db.commit()


def _seed_reviews(db: Session) -> None:
    """Topluluk yorumları gerçek yorum kaydı olarak yüklenir; puanlar bunlardan
    hesaplanır. Yazarlar giriş yapılamayan demo hesaplarıdır (rastgele şifre)."""
    authors: dict[str, User] = {}
    for item in load_reviews():
        name = item["author"]
        if name not in authors:
            email = f"{search_key(name).replace(' ', '.').strip('.')}@topluluk.skinsavvy.app"
            authors[name] = _ensure_user(db, email, secrets.token_urlsafe(24), name, Role.user, {})
        user = authors[name]
        review = db.scalar(select(Review).where(Review.product_id == item["productId"], Review.user_id == user.id))
        if review is None:
            review = Review(product_id=item["productId"], user_id=user.id)
            db.add(review)
        review.rating = item["rating"]
        review.comment = item["comment"]
        review.created_at = datetime.fromisoformat(item["date"]).replace(tzinfo=UTC)


def _ensure_user(db: Session, email: str, password: str, name: str, role: Role, profile: dict) -> User:
    email = email.lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        user = User(
            email=email,
            name=name,
            password_hash=hash_password(password),
            role=role,
            skin_profile=profile,
            onboarded=True,
        )
        db.add(user)
        db.flush()
    elif user.role != role:
        user.role = role
    return user
