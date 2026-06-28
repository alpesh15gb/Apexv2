"""Fee management endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.fee import FeeCategory, FeeStructure, StudentFee, FeePayment

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
    base = (FeeCategory.tenant_id == current_user.tenant_id, FeeCategory.is_active == True)
    total = (await db.execute(select(func.count(FeeCategory.id)).where(*base))).scalar() or 0
    stmt = select(FeeCategory).where(*base).order_by(FeeCategory.sort_order).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    cats = result.scalars().all()
    return {
        "items": [{"id": str(c.id), "name": c.name, "code": c.code} for c in cats],
        "total": total, "page": page, "page_size": page_size,
    }


@router.post("/categories")
async def create_fee_category(
    data: FeeCategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    cat = FeeCategory(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(cat)
    await db.commit()
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
    count_stmt = select(func.count(FeeStructure.id)).where(FeeStructure.tenant_id == current_user.tenant_id)
    stmt = select(FeeStructure).where(FeeStructure.tenant_id == current_user.tenant_id)
    if academic_year_id:
        count_stmt = count_stmt.where(FeeStructure.academic_year_id == academic_year_id)
        stmt = stmt.where(FeeStructure.academic_year_id == academic_year_id)
    if grade_id:
        count_stmt = count_stmt.where(FeeStructure.grade_id == grade_id)
        stmt = stmt.where(FeeStructure.grade_id == grade_id)
    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    structs = result.scalars().all()
    return {
        "items": [
            {
                "id": str(f.id), "academic_year_id": str(f.academic_year_id), "grade_id": str(f.grade_id),
                "fee_category_id": str(f.fee_category_id), "amount": float(f.amount), "frequency": f.frequency,
            }
            for f in structs
        ],
        "total": total, "page": page, "page_size": page_size,
    }


@router.post("/structures")
async def create_fee_structure(
    data: FeeStructureCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    struct = FeeStructure(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(struct)
    await db.commit()
    return {"id": str(struct.id)}


@router.post("/payments")
async def record_payment(
    data: FeePaymentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    import random, string
    receipt_number = f"RCP-{date.today().strftime('%Y%m%d')}-{''.join(random.choices(string.digits, k=4))}"

    payment = FeePayment(
        tenant_id=current_user.tenant_id,
        receipt_number=receipt_number,
        collected_by=current_user.id,
        **data.model_dump(),
    )
    db.add(payment)

    student_fee = await db.get(StudentFee, data.student_fee_id)
    if student_fee:
        total_paid = (await db.execute(
            select(func.coalesce(func.sum(FeePayment.amount), 0)).where(FeePayment.student_fee_id == data.student_fee_id)
        )).scalar()
        if total_paid + data.amount >= float(student_fee.final_amount):
            student_fee.status = "paid"
        else:
            student_fee.status = "partial"

    await db.commit()
    return {"id": str(payment.id), "receipt_number": receipt_number}


@router.get("/payments")
async def list_payments(
    student_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count_stmt = select(func.count(FeePayment.id)).where(FeePayment.tenant_id == current_user.tenant_id)
    stmt = select(FeePayment).where(FeePayment.tenant_id == current_user.tenant_id)
    if student_id:
        count_stmt = count_stmt.where(FeePayment.student_id == student_id)
        stmt = stmt.where(FeePayment.student_id == student_id)
    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(FeePayment.payment_date.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    payments = result.scalars().all()
    return {
        "items": [
            {
                "id": str(p.id), "student_id": str(p.student_id), "amount": float(p.amount),
                "payment_date": str(p.payment_date), "payment_method": p.payment_method,
                "receipt_number": p.receipt_number, "status": p.status,
            }
            for p in payments
        ],
        "total": total, "page": page, "page_size": page_size,
    }


@router.get("/students/{student_id}")
async def student_fee_summary(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(StudentFee).where(StudentFee.student_id == student_id, StudentFee.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    fees = result.scalars().all()
    return [
        {
            "id": str(f.id), "fee_structure_id": str(f.fee_structure_id), "amount": float(f.amount),
            "discount_amount": float(f.discount_amount), "scholarship_amount": float(f.scholarship_amount),
            "final_amount": float(f.final_amount), "due_date": str(f.due_date) if f.due_date else None, "status": f.status,
        }
        for f in fees
    ]


@router.get("/reports/dues")
async def fee_dues_report(
    academic_year_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count_stmt = select(func.count(StudentFee.id)).where(
        StudentFee.tenant_id == current_user.tenant_id,
        StudentFee.status.in_(["pending", "partial", "overdue"]),
    )
    stmt = select(StudentFee, Student).join(Student, Student.id == StudentFee.student_id).where(
        StudentFee.tenant_id == current_user.tenant_id,
        StudentFee.status.in_(["pending", "partial", "overdue"]),
    )
    if academic_year_id:
        count_stmt = count_stmt.where(StudentFee.academic_year_id == academic_year_id)
        stmt = stmt.where(StudentFee.academic_year_id == academic_year_id)
    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    rows = result.all()
    return {
        "items": [
            {
                "student_id": str(f.student_id), "student_name": f"{s.first_name} {s.last_name}",
                "admission_number": s.admission_number, "final_amount": float(f.final_amount), "status": f.status,
            }
            for f, s in rows
        ],
        "total": total, "page": page, "page_size": page_size,
    }
