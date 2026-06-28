"""School dashboard and reports endpoints."""

import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.student import Student
from app.models.school.student_attendance import StudentAttendance
from app.models.school.fee import StudentFee, FeePayment
from app.models.school.grade import Grade, Section
from app.models.school.examination import Exam

router = APIRouter(dependencies=[Depends(require_feature("student_management"))])


@router.get("/stats")
async def school_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tid = current_user.tenant_id
    today = date.today()

    total_students = (await db.execute(
        select(func.count(Student.id)).where(Student.tenant_id == tid, Student.is_active == True)
    )).scalar() or 0

    total_grades = (await db.execute(
        select(func.count(Grade.id)).where(Grade.tenant_id == tid, Grade.is_active == True)
    )).scalar() or 0

    total_sections = (await db.execute(
        select(func.count(Section.id)).where(Section.tenant_id == tid, Section.is_active == True)
    )).scalar() or 0

    # Today's attendance
    present_today = (await db.execute(
        select(func.count(StudentAttendance.id)).where(
            StudentAttendance.tenant_id == tid, StudentAttendance.date == today, StudentAttendance.status == "present"
        )
    )).scalar() or 0

    absent_today = (await db.execute(
        select(func.count(StudentAttendance.id)).where(
            StudentAttendance.tenant_id == tid, StudentAttendance.date == today, StudentAttendance.status == "absent"
        )
    )).scalar() or 0

    attendance_pct = round(present_today / (present_today + absent_today) * 100, 1) if (present_today + absent_today) > 0 else 0

    # Fee collection
    total_fee_collected = (await db.execute(
        select(func.coalesce(func.sum(FeePayment.amount), 0)).where(FeePayment.tenant_id == tid)
    )).scalar() or 0

    pending_fees = (await db.execute(
        select(func.count(StudentFee.id)).where(StudentFee.tenant_id == tid, StudentFee.status.in_(["pending", "partial", "overdue"]))
    )).scalar() or 0

    return {
        "total_students": total_students,
        "total_grades": total_grades,
        "total_sections": total_sections,
        "present_today": present_today,
        "absent_today": absent_today,
        "attendance_percentage": attendance_pct,
        "total_fee_collected": float(total_fee_collected),
        "pending_fee_count": pending_fees,
    }


@router.get("/attendance-overview")
async def attendance_overview(
    days: int = Query(7, ge=1, le=30),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tid = current_user.tenant_id
    start_date = date.today() - timedelta(days=days)

    stmt = select(
        StudentAttendance.date,
        StudentAttendance.status,
        func.count(StudentAttendance.id),
    ).where(
        StudentAttendance.tenant_id == tid,
        StudentAttendance.date >= start_date,
        StudentAttendance.attendance_type == "daily",
    ).group_by(StudentAttendance.date, StudentAttendance.status).order_by(StudentAttendance.date)

    result = await db.execute(stmt)
    rows = result.all()

    daily = {}
    for d, status, count in rows:
        day_str = str(d)
        if day_str not in daily:
            daily[day_str] = {"date": day_str, "present": 0, "absent": 0, "late": 0}
        daily[day_str][status] = count

    return list(daily.values())
