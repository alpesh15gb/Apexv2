"""Employee Self Service (ESS) endpoints."""

import uuid
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_feature
from app.models.user import User
from app.models.employee import Employee
from app.models.attendance import Attendance, PunchLog
from app.models.leave import LeaveRequest, LeaveBalance, LeaveType
from app.models.payroll import PaySlip
from app.models.document import Document
from app.models.announcement import Announcement
from app.models.notification import Notification
from app.models.expense import ExpenseClaim

router = APIRouter(dependencies=[Depends(require_feature("ess")), Depends(require_permissions("ess.read"))])


class ProfileUpdate(BaseModel):
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None


class EssPasswordChange(BaseModel):
    old_password: str
    new_password: str


async def get_current_employee(db: AsyncSession, user: User) -> Employee:
    """Get the employee record for the current user."""
    stmt = select(Employee).where(
        Employee.tenant_id == user.tenant_id,
        (Employee.email == user.email) | (Employee.employee_code == user.email),
    )
    result = await db.execute(stmt)
    employee = result.scalar_one_or_none()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee profile not found")
    return employee


@router.get("/dashboard")
async def ess_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Employee self-service dashboard summary."""
    employee = await get_current_employee(db, current_user)
    today = date.today()

    today_attendance = (await db.execute(
        select(Attendance).where(
            Attendance.tenant_id == current_user.tenant_id,
            Attendance.employee_id == employee.id,
            Attendance.date == today,
        )
    )).scalar_one_or_none()

    pending_leaves = (await db.execute(
        select(func.count(LeaveRequest.id)).where(
            LeaveRequest.tenant_id == current_user.tenant_id,
            LeaveRequest.employee_id == employee.id,
            LeaveRequest.status == "pending",
        )
    )).scalar() or 0

    balance_stmt = (
        select(LeaveType.name, LeaveBalance.total_days, LeaveBalance.used_days)
        .join(LeaveType, LeaveType.id == LeaveBalance.leave_type_id)
        .where(
            LeaveBalance.tenant_id == current_user.tenant_id,
            LeaveBalance.employee_id == employee.id,
        )
    )
    balances = (await db.execute(balance_stmt)).all()

    unread_notifications = (await db.execute(
        select(func.count(Notification.id)).where(
            Notification.tenant_id == current_user.tenant_id,
            Notification.user_id == current_user.id,
            Notification.status != "read",
        )
    )).scalar() or 0

    return {
        "employee": {
            "id": str(employee.id),
            "name": f"{employee.first_name} {employee.last_name}",
            "code": employee.employee_code,
            "department": employee.department_id,
            "designation": employee.designation_id,
        },
        "today_attendance": {
            "status": today_attendance.status if today_attendance else "not_marked",
            "punch_in": str(today_attendance.punch_in) if today_attendance and today_attendance.punch_in else None,
            "punch_out": str(today_attendance.punch_out) if today_attendance and today_attendance.punch_out else None,
        } if today_attendance else None,
        "pending_leaves": pending_leaves,
        "leave_balances": [
            {"type": name, "total": balance, "used": used, "available": balance - used}
            for name, balance, used in balances
        ],
        "unread_notifications": unread_notifications,
    }


@router.get("/attendance")
async def my_attendance(
    from_date: Optional[date] = None,
    to_date: Optional[date] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my attendance records."""
    employee = await get_current_employee(db, current_user)
    if not from_date:
        from_date = date.today().replace(day=1)
    if not to_date:
        to_date = date.today()

    stmt = (
        select(Attendance)
        .where(
            Attendance.tenant_id == current_user.tenant_id,
            Attendance.employee_id == employee.id,
            Attendance.date >= from_date,
            Attendance.date <= to_date,
        )
        .order_by(Attendance.date.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(stmt)
    records = result.scalars().all()

    return [
        {
            "id": str(r.id),
            "date": str(r.date),
            "status": r.status,
            "punch_in": str(r.punch_in) if r.punch_in else None,
            "punch_out": str(r.punch_out) if r.punch_out else None,
            "total_hours": r.total_hours,
        }
        for r in records
    ]


@router.post("/attendance/clock-in")
async def clock_in(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Clock in for today."""
    employee = await get_current_employee(db, current_user)
    today = date.today()

    existing = (await db.execute(
        select(Attendance).where(
            Attendance.tenant_id == current_user.tenant_id,
            Attendance.employee_id == employee.id,
            Attendance.date == today,
        )
    )).scalar_one_or_none()

    if existing:
        raise HTTPException(status_code=400, detail="Already clocked in today")

    attendance = Attendance(
        tenant_id=current_user.tenant_id,
        employee_id=employee.id,
        date=today,
        punch_in=datetime.now(timezone.utc),
        status="present",
    )
    db.add(attendance)
    await db.commit()
    return {"message": "Clocked in successfully", "time": attendance.punch_in.isoformat()}


@router.post("/attendance/clock-out")
async def clock_out(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Clock out for today."""
    employee = await get_current_employee(db, current_user)
    today = date.today()

    attendance = (await db.execute(
        select(Attendance).where(
            Attendance.tenant_id == current_user.tenant_id,
            Attendance.employee_id == employee.id,
            Attendance.date == today,
        )
    )).scalar_one_or_none()

    if not attendance:
        raise HTTPException(status_code=400, detail="No clock-in record found")
    if attendance.punch_out:
        raise HTTPException(status_code=400, detail="Already clocked out")

    attendance.punch_out = datetime.now(timezone.utc)
    if attendance.punch_in:
        delta = attendance.punch_out - attendance.punch_in
        attendance.total_hours = round(delta.total_seconds() / 3600, 2)
    await db.commit()
    return {"message": "Clocked out successfully", "time": attendance.punch_out.isoformat()}


@router.get("/leaves")
async def my_leaves(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my leave requests."""
    employee = await get_current_employee(db, current_user)
    stmt = (
        select(LeaveRequest)
        .where(
            LeaveRequest.tenant_id == current_user.tenant_id,
            LeaveRequest.employee_id == employee.id,
        )
        .order_by(LeaveRequest.created_at.desc())
    )
    if status:
        stmt = stmt.where(LeaveRequest.status == status)

    result = await db.execute(stmt)
    requests = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "leave_type_id": str(r.leave_type_id),
            "start_date": str(r.start_date),
            "end_date": str(r.end_date),
            "reason": r.reason,
            "status": r.status,
            "created_at": r.created_at.isoformat() if r.created_at else None,
        }
        for r in requests
    ]


@router.get("/leaves/balance")
async def my_leave_balance(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my leave balance."""
    employee = await get_current_employee(db, current_user)
    stmt = (
        select(LeaveType.name, LeaveBalance.total_days, LeaveBalance.used_days)
        .join(LeaveType, LeaveType.id == LeaveBalance.leave_type_id)
        .where(
            LeaveBalance.tenant_id == current_user.tenant_id,
            LeaveBalance.employee_id == employee.id,
        )
    )
    result = await db.execute(stmt)
    balances = result.all()
    return [
        {"type": name, "total": balance, "used": used, "available": balance - used}
        for name, balance, used in balances
    ]


@router.get("/payslips")
async def my_payslips(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my payslips."""
    employee = await get_current_employee(db, current_user)
    stmt = (
        select(PaySlip)
        .where(
            PaySlip.tenant_id == current_user.tenant_id,
            PaySlip.employee_id == employee.id,
        )
        .order_by(PaySlip.year.desc(), PaySlip.month.desc())
    )
    result = await db.execute(stmt)
    slips = result.scalars().all()
    return [
        {
            "id": str(s.id),
            "month": s.month,
            "year": s.year,
            "net_pay": s.net_pay,
            "gross_earnings": s.gross_earnings,
            "total_deductions": s.total_deductions,
            "status": s.status,
        }
        for s in slips
    ]


@router.get("/documents")
async def my_documents(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my documents."""
    employee = await get_current_employee(db, current_user)
    stmt = (
        select(Document)
        .where(
            Document.tenant_id == current_user.tenant_id,
            Document.employee_id == employee.id,
        )
        .order_by(Document.created_at.desc())
    )
    result = await db.execute(stmt)
    docs = result.scalars().all()
    return [
        {
            "id": str(d.id),
            "title": d.title,
            "doc_type": d.doc_type,
            "file_name": d.file_name,
            "file_size": d.file_size,
            "created_at": d.created_at.isoformat() if d.created_at else None,
        }
        for d in docs
    ]


@router.get("/profile")
async def my_profile(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my employee profile."""
    employee = await get_current_employee(db, current_user)
    return {
        "id": str(employee.id),
        "employee_code": employee.employee_code,
        "first_name": employee.first_name,
        "last_name": employee.last_name,
        "email": employee.email,
        "phone": employee.phone,
        "gender": employee.gender,
        "date_of_birth": str(employee.date_of_birth) if employee.date_of_birth else None,
        "joining_date": str(employee.joining_date) if employee.joining_date else None,
        "address": employee.address,
        "city": employee.city,
        "state": employee.state,
        "pincode": employee.pincode,
        "emergency_contact_name": employee.emergency_contact_name,
        "emergency_contact_phone": employee.emergency_contact_phone,
        "blood_group": employee.blood_group,
        "status": employee.status,
    }


@router.put("/profile")
async def update_my_profile(
    data: ProfileUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Update my profile (limited fields)."""
    employee = await get_current_employee(db, current_user)
    for field, val in data.model_dump(exclude_unset=True).items():
        if val is not None:
            setattr(employee, field, val)
    await db.commit()
    return {"message": "Profile updated"}


@router.get("/announcements")
async def my_announcements(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get company announcements."""
    stmt = (
        select(Announcement)
        .where(
            Announcement.tenant_id == current_user.tenant_id,
            Announcement.is_active == True,
        )
        .order_by(Announcement.created_at.desc())
        .limit(20)
    )
    result = await db.execute(stmt)
    items = result.scalars().all()
    return [
        {
            "id": str(a.id),
            "title": a.title,
            "body": a.body,
            "priority": a.priority,
            "created_at": a.created_at.isoformat() if a.created_at else None,
        }
        for a in items
    ]


@router.get("/notifications")
async def my_notifications(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get my notifications."""
    stmt = (
        select(Notification)
        .where(
            Notification.tenant_id == current_user.tenant_id,
            Notification.user_id == current_user.id,
        )
        .order_by(Notification.created_at.desc())
        .limit(50)
    )
    result = await db.execute(stmt)
    items = result.scalars().all()
    return [
        {
            "id": str(n.id),
            "title": n.title,
            "message": n.message,
            "is_read": n.status == "read",
            "created_at": n.created_at.isoformat() if n.created_at else None,
        }
        for n in items
    ]


@router.post("/change-password")
async def change_my_password(
    data: EssPasswordChange,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Change my password."""
    from app.core.security import verify_password, hash_password

    if not verify_password(data.old_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Current password is incorrect")

    current_user.hashed_password = hash_password(data.new_password)
    current_user.must_change_password = False
    current_user.last_password_change = datetime.now(timezone.utc)
    await db.commit()
    return {"message": "Password changed successfully"}
