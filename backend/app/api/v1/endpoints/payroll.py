"""Payroll CRUD endpoints."""

import uuid
from typing import List, Optional
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.payroll import SalaryStructure, PaySlip, Loan
from app.models.employee import Employee
from app.models.attendance import Attendance
from app.schemas.common import ResponseBase
from app.schemas.payroll import (
    SalaryStructureCreate, SalaryStructureUpdate, SalaryStructureResponse,
    PaySlipResponse, LoanCreate, LoanResponse,
)

router = APIRouter()


# ── Salary Structure ─────────────────────────────────────

@router.get("/salary-structure", response_model=List[SalaryStructureResponse])
async def list_salary_structures(
    employee_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(SalaryStructure).where(SalaryStructure.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(SalaryStructure.employee_id == employee_id)
    stmt = stmt.order_by(SalaryStructure.effective_from.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/salary-structure", response_model=SalaryStructureResponse, status_code=201)
async def create_salary_structure(data: SalaryStructureCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    ss = SalaryStructure(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(ss)
    await db.commit()
    await db.refresh(ss)
    return ss


@router.put("/salary-structure/{ss_id}", response_model=SalaryStructureResponse)
async def update_salary_structure(ss_id: uuid.UUID, data: SalaryStructureUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(SalaryStructure).where(SalaryStructure.id == ss_id, SalaryStructure.tenant_id == current_user.tenant_id)
    ss = (await db.execute(stmt)).scalar_one_or_none()
    if not ss:
        raise HTTPException(status_code=404, detail="Salary structure not found")
    for field, val in data.model_dump(exclude_unset=True).items():
        setattr(ss, field, val)
    await db.commit()
    await db.refresh(ss)
    return ss


# ── Pay Slip ─────────────────────────────────────────────

@router.get("/payslips", response_model=List[PaySlipResponse])
async def list_payslips(
    month: Optional[int] = Query(None, ge=1, le=12),
    year: Optional[int] = Query(None),
    employee_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(PaySlip).where(PaySlip.tenant_id == current_user.tenant_id)
    if month:
        stmt = stmt.where(PaySlip.month == month)
    if year:
        stmt = stmt.where(PaySlip.year == year)
    if employee_id:
        stmt = stmt.where(PaySlip.employee_id == employee_id)
    stmt = stmt.order_by(PaySlip.year.desc(), PaySlip.month.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/payslips/generate")
async def generate_payslips(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    department_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    import calendar as cal
    _, last_day = cal.monthrange(year, month)
    from_date = date(year, month, 1)
    to_date = date(year, month, last_day)

    emp_stmt = select(Employee).where(Employee.tenant_id == current_user.tenant_id, Employee.status == "active")
    if department_id:
        emp_stmt = emp_stmt.where(Employee.department_id == department_id)
    employees = list((await db.execute(emp_stmt)).scalars().all())

    generated = 0
    for emp in employees:
        existing = select(PaySlip).where(PaySlip.tenant_id == current_user.tenant_id, PaySlip.employee_id == emp.id, PaySlip.month == month, PaySlip.year == year)
        if (await db.execute(existing)).scalar_one_or_none():
            continue

        ss_stmt = select(SalaryStructure).where(SalaryStructure.employee_id == emp.id, SalaryStructure.is_active == True).order_by(SalaryStructure.effective_from.desc())
        ss = (await db.execute(ss_stmt)).scalar_one_or_none()
        if not ss:
            continue

        att_stmt = select(Attendance).where(Attendance.tenant_id == current_user.tenant_id, Attendance.employee_id == emp.id, Attendance.date >= from_date, Attendance.date <= to_date)
        attendances = list((await db.execute(att_stmt)).scalars().all())

        present = sum(1 for a in attendances if a.status in ("present", "late"))
        absent = sum(1 for a in attendances if a.status == "absent")
        half_days = sum(1 for a in attendances if a.status == "half_day")
        leave = sum(1 for a in attendances if a.status in ("on_leave",))
        ot_hours = sum(a.overtime_hours or 0 for a in attendances)

        working_days = last_day
        lop_days = absent + (half_days * 0.5)
        per_day = (ss.basic + ss.hra + ss.da + ss.conveyance + ss.medical + ss.special) / working_days if working_days > 0 else 0
        lop_amount = per_day * lop_days

        gross = ss.basic + ss.hra + ss.da + ss.conveyance + ss.medical + ss.special - lop_amount
        deductions = ss.pf_employee + ss.esi_employee + ss.professional_tax + ss.income_tax
        net = gross - deductions

        payslip = PaySlip(
            tenant_id=current_user.tenant_id, employee_id=emp.id, month=month, year=year,
            basic=ss.basic, hra=ss.hra, da=ss.da, conveyance=ss.conveyance, medical=ss.medical, special=ss.special,
            gross_earnings=gross, pf=ss.pf_employee, esi=ss.esi_employee, pt=ss.professional_tax, it=ss.income_tax,
            total_deductions=deductions, net_pay=net, working_days=working_days,
            present_days=present, absent_days=absent, leave_days=leave,
            ot_hours=ot_hours, ot_amount=0, lop_days=int(lop_days), lop_amount=lop_amount,
            status="calculated", generated_at=datetime.now(timezone.utc),
        )
        db.add(payslip)
        generated += 1

    await db.commit()
    return {"generated": generated, "month": month, "year": year}


@router.put("/payslips/{payslip_id}/freeze", response_model=PaySlipResponse)
async def freeze_payslip(payslip_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(PaySlip).where(PaySlip.id == payslip_id, PaySlip.tenant_id == current_user.tenant_id)
    ps = (await db.execute(stmt)).scalar_one_or_none()
    if not ps:
        raise HTTPException(status_code=404, detail="Payslip not found")
    ps.status = "frozen"
    await db.commit()
    await db.refresh(ps)
    return ps


# ── Loans ────────────────────────────────────────────────

@router.get("/loans", response_model=List[LoanResponse])
async def list_loans(
    employee_id: Optional[uuid.UUID] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Loan).where(Loan.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(Loan.employee_id == employee_id)
    return list((await db.execute(stmt)).scalars().all())


@router.post("/loans", response_model=LoanResponse, status_code=201)
async def create_loan(data: LoanCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    loan = Loan(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(loan)
    await db.commit()
    await db.refresh(loan)
    return loan
