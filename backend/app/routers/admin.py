from datetime import UTC, datetime
from typing import Annotated

from fastapi import APIRouter, HTTPException, Query, status
from sqlalchemy import select

from ..deps import AdminUser, DbDep
from ..models import Product, ProductStatus
from ..schemas import ProductOut, RejectIn
from ..services import product_out

router = APIRouter(prefix="/admin", tags=["Yönetici"])


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


@router.post("/submissions/{product_id}/approve", response_model=ProductOut)
def approve(product_id: str, db: DbDep, _: AdminUser):
    p = _pending(db, product_id)
    p.status = ProductStatus.approved
    p.reviewed_at = datetime.now(UTC)
    db.commit()
    return product_out(p, owner_view=True)


@router.post("/submissions/{product_id}/reject", response_model=ProductOut)
def reject(product_id: str, body: RejectIn, db: DbDep, _: AdminUser):
    p = _pending(db, product_id)
    p.status = ProductStatus.rejected
    p.reject_reason = body.reason
    p.reviewed_at = datetime.now(UTC)
    db.commit()
    return product_out(p, owner_view=True)
