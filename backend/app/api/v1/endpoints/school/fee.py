"""Fee management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.fee_service import FeeService

router = APIRouter(dependencies=[Depends(require_feature("fee_management")), Depends(require_permissions("fee.read"))])


class FeeCategoryCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=30)
    sort_order: int = 0


class FeeStructureCreate(BaseModel):
    academic_year_id: uuid.UUID
    grade_id: uuid.UUID
    fee_category_id: uuid.UUID
    amount: float
    frequency: str = "monthly"
    due_day: int = 10
    is_mandatory: bool = True


class FeePaymentCreate(BaseModel):
    student_id: uuid.UUID
    student_fee_id: uuid.UUID
    amount: float
    payment_date: date
    payment_method: str = "cash"
    reference_number: Optional[str] = None
    remarks: Optional[str] = None


@router.get("/categories")
async def list_fee_categories(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    items, total = await svc.list_categories(current_user.tenant_id, page, page_size)
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/categories")
async def create_fee_category(
    data: FeeCategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    cat = await svc.create_category(current_user.tenant_id, data)
    return {"id": str(cat.id)}


@router.get("/structures")
async def list_fee_structures(
    academic_year_id: Optional[uuid.UUID] = None,
    grade_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    items, total = await svc.list_structures(
        current_user.tenant_id,
        academic_year_id=academic_year_id,
        grade_id=grade_id,
        page=page,
        page_size=page_size,
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/structures")
async def create_fee_structure(
    data: FeeStructureCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    struct = await svc.create_structure(current_user.tenant_id, data)
    return {"id": str(struct.id)}


@router.post("/payments")
async def record_payment(
    data: FeePaymentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    payment = await svc.record_payment(current_user.tenant_id, current_user.id, data)
    return {"id": str(payment.id), "receipt_number": payment.receipt_number}


@router.get("/payments")
async def list_payments(
    student_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    items, total = await svc.list_payments(
        current_user.tenant_id, student_id=student_id, page=page, page_size=page_size
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.get("/students/{student_id}")
async def student_fee_summary(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    return await svc.student_fee_summary(student_id, current_user.tenant_id)


@router.get("/reports/dues")
async def fee_dues_report(
    academic_year_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = FeeService(db)
    items, total = await svc.fee_dues_report(
        current_user.tenant_id, academic_year_id=academic_year_id, page=page, page_size=page_size
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}
