"""School dashboard and reports endpoints."""

import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.student import Student
from app.models.school.student_attendance import StudentAttendance
from app.models.school.fee import StudentFee, FeePayment
from app.models.school.grade import Grade, Section
from app.models.school.examination import Exam

router = APIRouter(dependencies=[Depends(require_feature("student_management")), Depends(require_permissions("student.read"))])


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

    grade_section_row = (await db.execute(
        select(
            func.count().filter(Grade.is_active == True).label("grades"),
            func.count().filter(Section.is_active == True).label("sections"),
        ).select_from(Grade.outerjoin(Section, Section.grade_id == Grade.id))
        .where(Grade.tenant_id == tid)
    )).one()
    total_grades, total_sections = grade_section_row

    att_row = (await db.execute(
        select(
            func.count().filter(StudentAttendance.status == "present").label("present"),
            func.count().filter(StudentAttendance.status == "absent").label("absent"),
        ).where(
            StudentAttendance.tenant_id == tid,
            StudentAttendance.date == today,
        )
    )).one()
    present_today, absent_today = att_row

    attendance_pct = round(present_today / (present_today + absent_today) * 100, 1) if (present_today + absent_today) > 0 else 0

    fee_row = (await db.execute(
        select(
            func.coalesce(func.sum(FeePayment.amount), 0).label("collected"),
            func.count().filter(StudentFee.status.in_(["pending", "partial", "overdue"])).label("pending"),
        ).select_from(
            StudentFee.outerjoin(FeePayment, FeePayment.student_fee_id == StudentFee.id)
        ).where(StudentFee.tenant_id == tid)
    )).one()
    total_fee_collected, pending_fees = fee_row

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
