from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, Request, Response, status
from sqlalchemy import and_, func, or_, select
from sqlalchemy.orm import selectinload

from ..deps import CurrentUser, DbDep, LimiterDep, OptionalUser, SettingsDep
from ..models import Product, ProductStatus, Review, User
from ..schemas import ProductIn, ProductOut, ProductPage, ReviewIn, ReviewOut, check_image
from ..security import search_key
from ..services import product_out, public_name, rating_stats, review_out

router = APIRouter(prefix="/products", tags=["Ürünler"])

LIVE = (ProductStatus.approved, ProductStatus.pending)


def find_duplicate(db, name_key: str, brand_key: str, barcode: str | None, ignore_id: str | None = None):
    """Aynı ad+marka ya da aynı barkodla onaylı/bekleyen ürün (varsa)."""
    same = and_(Product.name_key == name_key, Product.brand_key == brand_key)
    if barcode:
        same = or_(same, Product.barcode == barcode)
    stmt = select(Product).where(same, Product.status.in_(LIVE))
    if ignore_id is not None:
        stmt = stmt.where(Product.id != ignore_id)
    return db.scalars(stmt.limit(1)).first()


def _visible(user: User | None, *, include_delisted: bool = False):
    """Onaylı ürünler herkese; bekleyen öneri yalnızca ekleyene.

    Yinelenen ya da silinen öneriler katalogda görünmez; öneren kararı
    /products/mine üzerinden öğrenir. Katalogdan kaldırılan ürün listede ve
    aramada yoktur ama doğrudan açılabilir: dolabında olanlar bilgisine ve
    yorumlarına ulaşmaya devam eder.
    """
    shown = [ProductStatus.approved]
    if include_delisted:
        shown.append(ProductStatus.delisted)
    public = Product.status.in_(shown)
    if user is None:
        return public
    return or_(public, and_(Product.status == ProductStatus.pending, Product.submitted_by == user.id))


def _get_visible(db, product_id: str, user: User | None) -> Product:
    p = db.scalar(select(Product).where(Product.id == product_id, _visible(user, include_delisted=True)))
    if p is None:
        # Başkasının bekleyen ürünü için de 404: varlığı sızmasın.
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ürün bulunamadı.")
    return p


@router.get("", response_model=ProductPage)
def list_products(
    db: DbDep,
    user: OptionalUser,
    q: Annotated[str, Query(max_length=80)] = "",
    category: Annotated[str | None, Query(max_length=40)] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    stmt = select(Product).where(_visible(user))
    if category:
        stmt = stmt.where(Product.category == category)
    if key := search_key(q):
        like = f"%{key.replace('%', '').replace('_', '')}%"
        stmt = stmt.where(or_(Product.name_key.like(like), Product.brand_key.like(like)))
    total = db.scalar(select(func.count()).select_from(stmt.subquery()))
    rows = db.scalars(stmt.order_by(Product.created_at.desc(), Product.id).limit(limit).offset(offset)).all()
    stats = rating_stats(db, [p.id for p in rows])
    return ProductPage(
        items=[
            product_out(p, stats.get(p.id), owner_view=user is not None and p.submitted_by == user.id) for p in rows
        ],
        total=total,
    )


@router.get("/mine", response_model=list[ProductOut])
def my_submissions(db: DbDep, user: CurrentUser):
    rows = db.scalars(select(Product).where(Product.submitted_by == user.id).order_by(Product.created_at.desc())).all()
    return [product_out(p, owner_view=True) for p in rows]


@router.get("/{product_id}", response_model=ProductOut)
def get_product(product_id: str, db: DbDep, user: OptionalUser):
    p = _get_visible(db, product_id, user)
    return product_out(p, rating_stats(db, [p.id]).get(p.id), owner_view=user is not None and p.submitted_by == user.id)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def withdraw_submission(product_id: str, db: DbDep, user: CurrentUser) -> Response:
    """Kullanıcı, ekip bakmadan önce kendi önerisini geri çeker."""
    p = db.get(Product, product_id)
    if p is None or p.submitted_by != user.id:
        # Başkasının önerisi için de 404: varlığı sızmasın.
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Öneri bulunamadı.")
    if p.status != ProductStatus.pending:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ekip bu öneriye karar verdi; geri çekilemez.")
    db.delete(p)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def submit_product(
    body: ProductIn, request: Request, db: DbDep, user: CurrentUser, settings: SettingsDep, limiter: LimiterDep
):
    limiter.hit(f"submit:{user.id}", limit=10, window_seconds=3600)
    try:
        image = check_image(body.image_url, settings.max_image_bytes)
    except ValueError as e:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(e)) from e
    name_key, brand_key = search_key(body.name), search_key(body.brand)
    if find_duplicate(db, name_key, brand_key, body.barcode) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Bu ürün zaten katalogda ya da onay bekliyor.")
    p = Product(
        name=body.name,
        brand=body.brand,
        name_key=name_key,
        brand_key=brand_key,
        category=body.category,
        skin_types=body.skin_types,
        ingredients=body.ingredients,
        description=body.description,
        barcode=body.barcode,
        image_url=image,
        status=ProductStatus.pending,
        submitted_by=user.id,
        added_by=public_name(user),
    )
    db.add(p)
    db.commit()
    return product_out(p, owner_view=True)


# ── Yorumlar ─────────────────────────────────────────────────────────


@router.get("/{product_id}/reviews", response_model=list[ReviewOut])
def list_reviews(
    product_id: str,
    db: DbDep,
    user: OptionalUser,
    limit: Annotated[int, Query(ge=1, le=100)] = 50,
    offset: Annotated[int, Query(ge=0)] = 0,
):
    _get_visible(db, product_id, user)
    rows = db.scalars(
        select(Review)
        .where(Review.product_id == product_id)
        .options(selectinload(Review.user), selectinload(Review.product))
        .order_by(Review.created_at.desc())
        .limit(limit)
        .offset(offset)
    ).all()
    return [review_out(r, user) for r in rows]


@router.put("/{product_id}/reviews/me", response_model=ReviewOut)
def upsert_review(product_id: str, body: ReviewIn, db: DbDep, user: CurrentUser, limiter: LimiterDep):
    limiter.hit(f"review:{user.id}", limit=30, window_seconds=3600)
    p = _get_visible(db, product_id, user)
    if p.status not in (ProductStatus.approved, ProductStatus.delisted):
        raise HTTPException(status.HTTP_409_CONFLICT, "Onaylanmamış ürüne yorum yazılamaz.")
    review = db.scalar(select(Review).where(Review.product_id == p.id, Review.user_id == user.id))
    if review is None:
        review = Review(product_id=p.id, user_id=user.id, rating=body.rating, comment=body.comment)
        db.add(review)
    else:
        review.rating = body.rating
        review.comment = body.comment
        review.updated_at = datetime.now(UTC)
    db.commit()
    db.refresh(review)
    return review_out(review, user)


@router.delete("/{product_id}/reviews/me", status_code=status.HTTP_204_NO_CONTENT)
def delete_review(product_id: str, db: DbDep, user: CurrentUser) -> Response:
    review = db.scalar(select(Review).where(Review.product_id == product_id, Review.user_id == user.id))
    if review is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Yorum bulunamadı.")
    db.delete(review)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
