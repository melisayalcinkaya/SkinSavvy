from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ..deps import AdminUser, DbDep, SettingsDep
from ..models import Product, ProductStatus
from ..schemas import DuplicateIn, ProductIn, ProductOut, check_image
from ..security import search_key
from ..services import product_out
from .products import find_duplicate

router = APIRouter(prefix="/admin", tags=["Yönetici"])

# Reddetme yok. Ekip her öneri için şu kararlardan birini verir:
#   approve   → (gerekirse bilgileri düzeltip) onaylar, ürün herkese açılır;
#   duplicate → ürün katalogda zaten var, öneri asıl ürüne bağlanır;
#   remove    → spam/sahte öneri silinir, içeriği saklanmaz.
# Uygulama kararı /products/mine üzerinden görüp önerenin dolabına yansıtır.
#
# Onaylı ürünler için ekip bilgileri düzeltebilir ve ürünü katalogdan
# kaldırabilir (delist) ya da geri alabilir (relist). Kaldırma silme değildir:
# ürünü dolabına eklemiş olanların kaydı ve yorumu durur.


@router.get("/submissions", response_model=list[ProductOut])
def submissions(
    db: DbDep,
    _: AdminUser,
    status_: Annotated[ProductStatus, Query(alias="status")] = ProductStatus.pending,
):
    rows = db.scalars(
        select(Product).where(Product.status == status_, Product.submitted_by.is_not(None)).order_by(Product.created_at)
    ).all()
    return [product_out(p, owner_view=True) for p in rows]


def _pending(db, product_id: str) -> Product:
    p = db.get(Product, product_id)
    if p is None or p.submitted_by is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Öneri bulunamadı.")
    if p.status != ProductStatus.pending:
        raise HTTPException(status.HTTP_409_CONFLICT, "Bu öneri zaten değerlendirildi.")
    return p


def _decided(p: Product, new_status: ProductStatus) -> None:
    p.status = new_status
    p.reviewed_at = datetime.now(UTC)


@router.post("/submissions/{product_id}/approve", response_model=ProductOut)
def approve(product_id: str, db: DbDep, _: AdminUser, settings: SettingsDep, body: ProductIn | None = None):
    """Öneriyi onaylar. Gövde gönderilirse ekip bilgileri düzeltmiştir."""
    p = _pending(db, product_id)
    if body is not None:
        try:
            image = check_image(body.image_url, settings.max_image_bytes)
        except ValueError as e:
            raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(e)) from e
        name_key, brand_key = search_key(body.name), search_key(body.brand)
        if find_duplicate(db, name_key, brand_key, body.barcode, ignore_id=p.id) is not None:
            raise HTTPException(
                status.HTTP_409_CONFLICT, "Bu ad/marka ya da barkodla başka bir ürün var; yinelenen olarak işaretleyin."
            )
        p.name, p.brand, p.name_key, p.brand_key = body.name, body.brand, name_key, brand_key
        p.category, p.skin_types, p.ingredients = body.category, body.skin_types, body.ingredients
        p.description, p.barcode, p.image_url = body.description, body.barcode, image
        p.edited_by_team = True
    _decided(p, ProductStatus.approved)
    db.commit()
    return product_out(p, owner_view=True)


@router.post("/submissions/{product_id}/duplicate", response_model=ProductOut)
def duplicate(product_id: str, body: DuplicateIn, db: DbDep, _: AdminUser):
    """Öneri katalogdaki onaylı bir ürünle aynı: asıl ürüne bağlanır."""
    p = _pending(db, product_id)
    original = db.get(Product, body.original_id)
    if original is None or original.id == p.id or original.status != ProductStatus.approved:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Asıl ürün onaylı bir katalog ürünü olmalı.")
    p.duplicate_of = original.id
    # Öneri katalogda görünmeyecek; büyük görseli saklamaya gerek yok.
    p.image_url = ""
    _decided(p, ProductStatus.duplicate)
    db.commit()
    return product_out(p, owner_view=True)


@router.post("/submissions/{product_id}/remove", response_model=ProductOut)
def remove(product_id: str, db: DbDep, _: AdminUser):
    """Spam/sahte öneriyi siler. Kayıt yalnızca önerene bildirim gitsin diye
    ad ve markayla kalır; fotoğraf, içerik ve açıklama silinir."""
    p = _pending(db, product_id)
    p.image_url, p.ingredients, p.benefits, p.skin_types = "", [], [], []
    p.description, p.barcode = "", None
    _decided(p, ProductStatus.removed)
    db.commit()
    return product_out(p, owner_view=True)


# ── Katalogdaki ürünler ─────────────────────────────────────────────


def _catalog_product(db, product_id: str, *allowed: ProductStatus) -> Product:
    p = db.get(Product, product_id)
    if p is None or p.status not in (ProductStatus.approved, ProductStatus.delisted):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Ürün bulunamadı.")
    if p.status not in allowed:
        raise HTTPException(status.HTTP_409_CONFLICT, "Ürün bu işlem için uygun durumda değil.")
    return p


@router.get("/products", response_model=list[ProductOut])
def catalog_products(
    db: DbDep,
    _: AdminUser,
    status_: Annotated[ProductStatus, Query(alias="status")] = ProductStatus.delisted,
):
    """Ekibin geri alabilmesi için katalogdan kaldırılan ürünler."""
    if status_ not in (ProductStatus.approved, ProductStatus.delisted):
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, "Öneriler için /admin/submissions kullanın.")
    rows = db.scalars(select(Product).where(Product.status == status_).order_by(Product.name_key)).all()
    return [product_out(p) for p in rows]


@router.put("/products/{product_id}", response_model=ProductOut)
def edit_product(product_id: str, body: ProductIn, db: DbDep, _: AdminUser, settings: SettingsDep):
    """Onaylı (ya da kaldırılmış) ürünün bilgilerini düzeltir."""
    p = _catalog_product(db, product_id, ProductStatus.approved, ProductStatus.delisted)
    try:
        image = check_image(body.image_url, settings.max_image_bytes)
    except ValueError as e:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_CONTENT, str(e)) from e
    name_key, brand_key = search_key(body.name), search_key(body.brand)
    if find_duplicate(db, name_key, brand_key, body.barcode, ignore_id=p.id) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Bu ad/marka ya da barkodla başka bir ürün var.")
    p.name, p.brand, p.name_key, p.brand_key = body.name, body.brand, name_key, brand_key
    p.category, p.skin_types, p.ingredients = body.category, body.skin_types, body.ingredients
    p.description, p.barcode, p.image_url = body.description, body.barcode, image
    db.commit()
    return product_out(p)


@router.post("/products/{product_id}/delist", response_model=ProductOut)
def delist(product_id: str, db: DbDep, _: AdminUser):
    """Ürünü katalogdan kaldırır: aramada görünmez, yeni kullanıcı ekleyemez."""
    p = _catalog_product(db, product_id, ProductStatus.approved)
    p.status = ProductStatus.delisted
    db.commit()
    return product_out(p)


@router.post("/products/{product_id}/relist", response_model=ProductOut)
def relist(product_id: str, db: DbDep, _: AdminUser):
    """Kaldırılan ürünü kataloğa geri alır."""
    p = _catalog_product(db, product_id, ProductStatus.delisted)
    # Kaldırılmışken aynı ürün yeniden önerilip onaylandıysa ikisi birden
    # katalogda olmasın.
    if find_duplicate(db, p.name_key, p.brand_key, p.barcode, ignore_id=p.id) is not None:
        raise HTTPException(status.HTTP_409_CONFLICT, "Katalogda aynı ürün var; geri alınamaz.")
    p.status = ProductStatus.approved
    db.commit()
    return product_out(p)
