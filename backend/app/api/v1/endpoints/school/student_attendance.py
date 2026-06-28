"""Student attendance endpoints."""

import uuid
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.attendance_service import AttendanceService

router = APIRouter(dependencies=[Depends(require_feature("student_attendance")), Depends(require_permissions("student_attendance.read"))])


class AttendanceMark(BaseModel):
    student_id: uuid.UUID
    date: date
    status: str  # present/absent/late/half-day/excused
    remarks: Optional[str] = None
    attendance_type: str = "daily"
    period_definition_id: Optional[uuid.UUID] = None


class BulkAttendanceMark(BaseModel):
    section_id: uuid.UUID
    date: date
    attendance_type: str = "daily"
    marks: List[dict]  # [{"student_id": "...", "status": "present"}, ...]


@router.post("/mark")
async def mark_attendance(
    data: AttendanceMark,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AttendanceService(db)
    await svc.mark_attendance(
        tenant_id=current_user.tenant_id,
        marked_by=current_user.id,
        student_id=data.student_id,
        attendance_date=data.date,
        attendance_status=data.status,
        attendance_type=data.attendance_type,
        remarks=data.remarks,
        period_definition_id=data.period_definition_id,
    )
    return {"status": "marked"}


@router.post("/bulk-mark")
async def bulk_mark_attendance(
    data: BulkAttendanceMark,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AttendanceService(db)
    count = await svc.bulk_mark_attendance(
        tenant_id=current_user.tenant_id,
        marked_by=current_user.id,
        section_id=data.section_id,
        attendance_date=data.date,
        marks=data.marks,
        attendance_type=data.attendance_type,
    )
    return {"marked": count}


@router.get("/")
async def get_attendance(
    date_from: date = Query(...),
    date_to: date = Query(...),
    section_id: Optional[uuid.UUID] = None,
    student_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AttendanceService(db)
    return await svc.get_attendance(
        tenant_id=current_user.tenant_id,
        date_from=date_from,
        date_to=date_to,
        section_id=section_id,
        student_id=student_id,
    )


@router.get("/daily-summary")
async def daily_summary(
    date: date = Query(...),
    section_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AttendanceService(db)
    return await svc.daily_summary(
        tenant_id=current_user.tenant_id,
        summary_date=date,
        section_id=section_id,
    )
