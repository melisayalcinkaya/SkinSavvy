"""Router'lar arasında paylaşılan iş kuralları."""

from datetime import UTC, datetime, timedelta

from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from .config import Settings
from .models import Product, ProductStatus, RefreshToken, Review, User, new_id
from .schemas import ProductOut, ReviewOut, SkinProfile, TokensOut, UserOut
from .security import create_access_token, new_refresh_token, token_digest


def user_out(user: User) -> UserOut:
    return UserOut(
        id=user.id,
        name=user.name,
        email=user.email,
        bio=user.bio or "",
        avatar=user.avatar,
        role=user.role.value,
        skin_profile=SkinProfile.model_validate(user.skin_profile or {}),
        onboarded=user.onboarded,
        created_at=user.created_at,
    )


def issue_tokens(db: Session, settings: Settings, user: User, family: str | None = None) -> TokensOut:
    raw = new_refresh_token()
    db.add(
        RefreshToken(
            user_id=user.id,
            token_hash=token_digest(raw),
            family=family or new_id(),
            expires_at=datetime.now(UTC) + timedelta(days=settings.refresh_token_days),
        )
    )
    db.commit()
    return TokensOut(
        access_token=create_access_token(settings, user.id, user.role.value),
        refresh_token=raw,
        expires_in=settings.access_token_minutes * 60,
        user=user_out(user),
    )


def revoke_family(db: Session, family: str) -> None:
    db.execute(
        update(RefreshToken)
        .where(RefreshToken.family == family, RefreshToken.revoked_at.is_(None))
        .values(revoked_at=datetime.now(UTC))
    )
    db.commit()


def as_utc(dt: datetime) -> datetime:
    # SQLite saat dilimini saklamaz; okunan değeri UTC kabul et.
    return dt if dt.tzinfo else dt.replace(tzinfo=UTC)


def rating_stats(db: Session, product_ids: list[str]) -> dict[str, tuple[float, int]]:
    if not product_ids:
        return {}
    rows = db.execute(
        select(Review.product_id, func.sum(Review.rating), func.count(Review.id))
        .where(Review.product_id.in_(product_ids))
        .group_by(Review.product_id)
    ).all()
    return {pid: (float(total or 0), int(count)) for pid, total, count in rows}


def product_out(p: Product, stats: tuple[float, int] | None = None, *, owner_view: bool = False) -> ProductOut:
    # Puan yalnızca gerçek yorumlardan hesaplanır; katalogda sabit puan yok.
    total, count = stats or (0.0, 0)
    approved = p.status == ProductStatus.approved and p.reviewed_at is not None
    return ProductOut(
        id=p.id,
        name=p.name,
        brand=p.brand,
        category=p.category,
        image_url=p.image_url,
        rating=round(total / count, 1) if count else 0.0,
        review_count=count,
        ingredients=p.ingredients,
        benefits=p.benefits,
        skin_types=p.skin_types,
        description=p.description,
        barcode=p.barcode,
        status=p.status.value,
        duplicate_of=p.duplicate_of if owner_view else None,
        edited_by_team=p.edited_by_team if owner_view else False,
        added_by=p.added_by,
        approved_at=as_utc(p.reviewed_at).date().isoformat() if approved else None,
        created_at=as_utc(p.created_at).isoformat(),
    )


def public_name(user: User) -> str:
    """Ayşe Yılmaz → "Ayşe Y." (yorumlarda ve "Ekleyen" bilgisinde)."""
    parts = user.name.split()
    return parts[0] + (f" {parts[-1][0]}." if len(parts) > 1 else "")


def review_out(r: Review, me: User | None) -> ReviewOut:
    # Yorumlarda e-posta gösterilmez; yalnızca ad ve soyadın baş harfi.
    author = public_name(r.user)
    return ReviewOut(
        id=r.id,
        product_id=r.product_id,
        product_name=r.product.name,
        brand=r.product.brand,
        author=author,
        rating=r.rating,
        comment=r.comment,
        created_at=r.created_at,
        updated_at=r.updated_at,
        mine=me is not None and r.user_id == me.id,
    )
