from fastapi import APIRouter, HTTPException, Response, status
from sqlalchemy import delete, select

from ..deps import CurrentUser, DbDep, SettingsDep
from ..models import Product, ProductStatus, Review
from ..schemas import ReviewOut, UserOut, UserUpdate, check_image
from ..services import review_out, user_out

router = APIRouter(prefix="/me", tags=["Profil"])


@router.get("", response_model=UserOut)
def me(user: CurrentUser):
    return user_out(user)


@router.patch("", response_model=UserOut)
def update_me(body: UserUpdate, user: CurrentUser, db: DbDep, settings: SettingsDep):
    if body.name is not None:
        user.name = body.name
    if body.bio is not None:
        user.bio = body.bio
    if body.avatar is not None:
        try:
            # Profil fotoğrafı ürün görselinin yarısıyla sınırlı.
            user.avatar = check_image(body.avatar, settings.max_image_bytes // 2) or None
        except ValueError as e:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(e)) from e
    if body.skin_profile is not None:
        user.skin_profile = body.skin_profile.model_dump(by_alias=True)
    if body.onboarded is not None:
        user.onboarded = body.onboarded
    db.commit()
    return user_out(user)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
def delete_me(user: CurrentUser, db: DbDep) -> Response:
    # Bekleyen, yinelenen ve silinen önerileri sil. Katalog ürünleri (onaylı ya
    # da katalogdan kaldırılmış) başkalarının dolabında olabilir, kalır
    # (submitted_by veritabanında SET NULL olur).
    catalog = (ProductStatus.approved, ProductStatus.delisted)
    db.execute(delete(Product).where(Product.submitted_by == user.id, Product.status.not_in(catalog)))
    db.delete(user)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/reviews", response_model=list[ReviewOut])
def my_reviews(user: CurrentUser, db: DbDep):
    rows = db.scalars(select(Review).where(Review.user_id == user.id).order_by(Review.created_at.desc())).all()
    return [review_out(r, user) for r in rows]
