"""Student attendance endpoints."""

import uuid
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.student_attendance import StudentAttendance
from app.models.school.student import Student

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
    student = await db.get(Student, data.student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")

    stmt = select(StudentAttendance).where(
        StudentAttendance.student_id == data.student_id,
        StudentAttendance.date == data.date,
        StudentAttendance.attendance_type == data.attendance_type,
    )
    if data.period_definition_id:
        stmt = stmt.where(StudentAttendance.period_definition_id == data.period_definition_id)
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        existing.status = data.status
        existing.remarks = data.remarks
        existing.marked_by = current_user.id
    else:
        attendance = StudentAttendance(
            tenant_id=current_user.tenant_id,
            student_id=data.student_id,
            date=data.date,
            status=data.status,
            remarks=data.remarks,
            marked_by=current_user.id,
            attendance_type=data.attendance_type,
            period_definition_id=data.period_definition_id,
            academic_year_id=student.academic_year_id,
        )
        db.add(attendance)

    await db.commit()
    return {"status": "marked"}


@router.post("/bulk-mark")
async def bulk_mark_attendance(
    data: BulkAttendanceMark,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count = 0
    for mark in data.marks:
        student_id = mark.get("student_id")
        status = mark.get("status")
        if not student_id or not status:
            continue

        student = await db.get(Student, uuid.UUID(student_id))
        if not student or student.tenant_id != current_user.tenant_id:
            continue

        stmt = select(StudentAttendance).where(
            StudentAttendance.student_id == student_id,
            StudentAttendance.date == data.date,
            StudentAttendance.attendance_type == data.attendance_type,
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.status = status
            existing.marked_by = current_user.id
        else:
            attendance = StudentAttendance(
                tenant_id=current_user.tenant_id,
                student_id=uuid.UUID(student_id),
                date=data.date,
                status=status,
                marked_by=current_user.id,
                attendance_type=data.attendance_type,
                academic_year_id=student.academic_year_id,
            )
            db.add(attendance)
        count += 1

    await db.commit()
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
    stmt = select(StudentAttendance, Student).join(Student, Student.id == StudentAttendance.student_id).where(
        StudentAttendance.tenant_id == current_user.tenant_id,
        StudentAttendance.date >= date_from,
        StudentAttendance.date <= date_to,
    )
    if student_id:
        stmt = stmt.where(StudentAttendance.student_id == student_id)
    if section_id:
        stmt = stmt.where(Student.current_section_id == section_id)
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(a.id), "student_id": str(a.student_id), "student_name": f"{s.first_name} {s.last_name}",
            "date": str(a.date), "status": a.status, "attendance_type": a.attendance_type,
        }
        for a, s in rows
    ]


@router.get("/daily-summary")
async def daily_summary(
    date: date = Query(...),
    section_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(
        StudentAttendance.status, func.count(StudentAttendance.id)
    ).where(
        StudentAttendance.tenant_id == current_user.tenant_id,
        StudentAttendance.date == date,
        StudentAttendance.attendance_type == "daily",
    )
    if section_id:
        stmt = stmt.join(Student, Student.id == StudentAttendance.student_id).where(Student.current_section_id == section_id)
    stmt = stmt.group_by(StudentAttendance.status)
    result = await db.execute(stmt)
    rows = result.all()
    return {status: count for status, count in rows}
