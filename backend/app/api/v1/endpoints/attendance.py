"""Attendance API endpoints."""

import uuid
from datetime import date as date_type
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.attendance import (
    AttendanceCreate, AttendanceUpdate, AttendanceResponse,
    PunchLogResponse, AttendanceSummary, DailyAttendanceSummary,
)
from app.services.attendance import AttendanceService

router = APIRouter(dependencies=[Depends(require_permissions("attendance.read"))])


@router.get("/daily-summary", response_model=DailyAttendanceSummary)
async def daily_summary(
    date: date_type = Query(default=None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    if date is None:
        from sqlalchemy import func, select
        from app.models.attendance import Attendance
        latest = await db.execute(select(func.max(Attendance.date)).where(Attendance.tenant_id == current_user.tenant_id))
        date = latest.scalar() or date_type.today()
    return await service.get_daily_summary(current_user.tenant_id, date)


@router.get("/employee/{employee_id}", response_model=AttendanceSummary)
async def employee_attendance_summary(
    employee_id: uuid.UUID,
    from_date: date_type = Query(...),
    to_date: date_type = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    return await service.get_employee_attendance_summary(
        current_user.tenant_id, employee_id, from_date, to_date
    )


@router.get("/", response_model=PaginatedResponse[AttendanceResponse])
async def list_attendance(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    employee_id: uuid.UUID = Query(None),
    department_id: uuid.UUID = Query(None),
    status: str = Query(None),
    from_date: date_type = Query(None),
    to_date: date_type = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    items, total = await service.get_attendance(
        current_user.tenant_id, employee_id=employee_id,
        department_id=department_id, status_val=status,
        from_date=from_date, to_date=to_date,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=AttendanceResponse, status_code=201)
async def manual_mark_attendance(
    data: AttendanceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    return await service.manual_mark_attendance(current_user.tenant_id, data)


@router.post("/process", response_model=ResponseBase)
async def process_attendance(
    target_date: date_type = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    results = await service.calculate_daily_attendance(current_user.tenant_id, target_date)
    return ResponseBase(message=f"Processed attendance for {len(results)} employees")


@router.put("/{attendance_id}/approve", response_model=AttendanceResponse)
async def approve_attendance(
    attendance_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    return await service.approve_attendance(attendance_id, current_user.tenant_id, current_user.id)


@router.get("/punch-logs", response_model=PaginatedResponse[PunchLogResponse])
async def list_punch_logs(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    employee_id: uuid.UUID = Query(None),
    from_date: date_type = Query(None),
    to_date: date_type = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AttendanceService(db)
    items, total = await service.list_punch_logs(
        current_user.tenant_id,
        page=page,
        page_size=page_size,
        employee_id=employee_id,
        from_date=from_date,
        to_date=to_date,
    )
    return PaginatedResponse(
        items=items, total=total, page=page, page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )
