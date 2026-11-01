"""Demo kataloğu (uygulamayla aynı JSON), demo hesabı ve isteğe bağlı yönetici."""

import json
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.orm import Session

from .config import Settings
from .models import Product, ProductStatus, Role, User
from .security import hash_password, search_key

CATALOG_PATH = Path(__file__).parent / "data" / "demo_catalog.json"

DEMO_PROFILE = {
    "skinType": "Karma Cilt",
    "concerns": ["Leke / Renk Eşitsizliği", "Sivilce / Akne"],
    "allergens": ["Parfüm / Fragrance"],
    "intensity": "Orta (4-6 adım)",
}


def load_catalog() -> list[dict]:
    return json.loads(CATALOG_PATH.read_text(encoding="utf-8"))


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
            p.price = item.get("price")
            p.badge = item.get("badge")
            p.ingredients = item.get("ingredients") or []
            p.benefits = item.get("benefits") or []
            p.skin_types = item.get("skinTypes") or []
            p.description = item.get("description") or ""
            p.barcode = item.get("barcode")
            p.seed_rating = item.get("rating") or 0
            p.seed_review_count = item.get("reviewCount") or 0
            p.status = ProductStatus.approved
            db.add(p)
        _ensure_user(db, settings.demo_email, settings.demo_password, "Ece Demir", Role.user, DEMO_PROFILE)

    if settings.admin_email and settings.admin_password:
        _ensure_user(db, settings.admin_email, settings.admin_password, "Yönetici", Role.admin, {})
    db.commit()


def _ensure_user(db: Session, email: str, password: str, name: str, role: Role, profile: dict) -> None:
    email = email.lower()
    user = db.scalar(select(User).where(User.email == email))
    if user is None:
        db.add(
            User(
                email=email,
                name=name,
                password_hash=hash_password(password),
                role=role,
                skin_profile=profile,
                onboarded=True,
            )
        )
    elif user.role != role:
        user.role = role
