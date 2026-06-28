import uuid
import random
import string
from typing import Any, Dict, List, Optional, Tuple, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.fee import FeeCategory, FeeStructure, StudentFee, FeePayment
from app.models.school.student import Student


class FeeService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_categories(
        self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 50
    ) -> Tuple[List[Dict[str, Any]], int]:
        base = (FeeCategory.tenant_id == tenant_id, FeeCategory.is_active == True)
        total = (await self.db.execute(select(func.count(FeeCategory.id)).where(*base))).scalar() or 0
        stmt = (
            select(FeeCategory)
            .where(*base)
            .order_by(FeeCategory.sort_order)
            .offset((page - 1) * page_size)
            .limit(page_size)
        )
        result = await self.db.execute(stmt)
        cats = result.scalars().all()
        items = [{"id": str(c.id), "name": c.name, "code": c.code} for c in cats]
        return items, total

    async def create_category(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> FeeCategory:
        if not isinstance(data, dict):
            data = data.model_dump()
        cat = FeeCategory(tenant_id=tenant_id, **data)
        self.db.add(cat)
        await self.db.commit()
        await self.db.refresh(cat)
        return cat

    async def list_structures(
        self,
        tenant_id: uuid.UUID,
        academic_year_id: Optional[uuid.UUID] = None,
        grade_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        count_stmt = select(func.count(FeeStructure.id)).where(FeeStructure.tenant_id == tenant_id)
        stmt = select(FeeStructure).where(FeeStructure.tenant_id == tenant_id)
        if academic_year_id:
            count_stmt = count_stmt.where(FeeStructure.academic_year_id == academic_year_id)
            stmt = stmt.where(FeeStructure.academic_year_id == academic_year_id)
        if grade_id:
            count_stmt = count_stmt.where(FeeStructure.grade_id == grade_id)
            stmt = stmt.where(FeeStructure.grade_id == grade_id)
        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        structs = result.scalars().all()
        items = [
            {
                "id": str(f.id),
                "academic_year_id": str(f.academic_year_id),
                "grade_id": str(f.grade_id),
                "fee_category_id": str(f.fee_category_id),
                "amount": float(f.amount),
                "frequency": f.frequency,
            }
            for f in structs
        ]
        return items, total

    async def create_structure(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> FeeStructure:
        if not isinstance(data, dict):
            data = data.model_dump()
        struct = FeeStructure(tenant_id=tenant_id, **data)
        self.db.add(struct)
        await self.db.commit()
        await self.db.refresh(struct)
        return struct

    async def record_payment(
        self, tenant_id: uuid.UUID, collected_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> FeePayment:
        if not isinstance(data, dict):
            data = data.model_dump()

        receipt_number = f"RCP-{date.today().strftime('%Y%m%d')}-{''.join(random.choices(string.digits, k=4))}"

        payment = FeePayment(
            tenant_id=tenant_id,
            receipt_number=receipt_number,
            collected_by=collected_by,
            **data,
        )
        self.db.add(payment)

        student_fee = await self.db.execute(
            select(StudentFee).where(
                StudentFee.id == data["student_fee_id"], StudentFee.tenant_id == tenant_id
            )
        )
        student_fee = student_fee.scalar_one_or_none()
        if student_fee:
            total_paid = (
                await self.db.execute(
                    select(func.coalesce(func.sum(FeePayment.amount), 0)).where(
                        FeePayment.student_fee_id == data["student_fee_id"],
                        FeePayment.tenant_id == tenant_id,
                    )
                )
            ).scalar()
            if total_paid + data["amount"] >= float(student_fee.final_amount):
                student_fee.status = "paid"
            else:
                student_fee.status = "partial"

        await self.db.commit()
        await self.db.refresh(payment)
        return payment

    async def list_payments(
        self,
        tenant_id: uuid.UUID,
        student_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        count_stmt = select(func.count(FeePayment.id)).where(FeePayment.tenant_id == tenant_id)
        stmt = select(FeePayment).where(FeePayment.tenant_id == tenant_id)
        if student_id:
            count_stmt = count_stmt.where(FeePayment.student_id == student_id)
            stmt = stmt.where(FeePayment.student_id == student_id)
        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.order_by(FeePayment.payment_date.desc()).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        payments = result.scalars().all()
        items = [
            {
                "id": str(p.id),
                "student_id": str(p.student_id),
                "amount": float(p.amount),
                "payment_date": str(p.payment_date),
                "payment_method": p.payment_method,
                "receipt_number": p.receipt_number,
                "status": p.status,
            }
            for p in payments
        ]
        return items, total

    async def student_fee_summary(self, student_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(StudentFee).where(
            StudentFee.student_id == student_id, StudentFee.tenant_id == tenant_id
        )
        result = await self.db.execute(stmt)
        fees = result.scalars().all()
        return [
            {
                "id": str(f.id),
                "fee_structure_id": str(f.fee_structure_id),
                "amount": float(f.amount),
                "discount_amount": float(f.discount_amount),
                "scholarship_amount": float(f.scholarship_amount),
                "final_amount": float(f.final_amount),
                "due_date": str(f.due_date) if f.due_date else None,
                "status": f.status,
            }
            for f in fees
        ]

    async def fee_dues_report(
        self,
        tenant_id: uuid.UUID,
        academic_year_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        count_stmt = select(func.count(StudentFee.id)).where(
            StudentFee.tenant_id == tenant_id,
            StudentFee.status.in_(["pending", "partial", "overdue"]),
        )
        stmt = (
            select(StudentFee, Student)
            .join(Student, Student.id == StudentFee.student_id)
            .where(
                StudentFee.tenant_id == tenant_id,
                StudentFee.status.in_(["pending", "partial", "overdue"]),
            )
        )
        if academic_year_id:
            count_stmt = count_stmt.where(StudentFee.academic_year_id == academic_year_id)
            stmt = stmt.where(StudentFee.academic_year_id == academic_year_id)
        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        rows = result.all()
        items = [
            {
                "student_id": str(f.student_id),
                "student_name": f"{s.first_name} {s.last_name}",
                "admission_number": s.admission_number,
                "final_amount": float(f.final_amount),
                "status": f.status,
            }
            for f, s in rows
        ]
        return items, total
