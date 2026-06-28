import uuid
from typing import Any, Dict, List
from datetime import date, timedelta

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.student import Student
from app.models.school.student_attendance import StudentAttendance
from app.models.school.fee import StudentFee, FeePayment
from app.models.school.grade import Grade, Section
from app.models.school.examination import Exam


class SchoolDashboardService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_stats(self, tenant_id: uuid.UUID) -> Dict[str, Any]:
        today = date.today()

        total_students = (await self.db.execute(
            select(func.count(Student.id)).where(Student.tenant_id == tenant_id, Student.is_active == True)
        )).scalar() or 0

        grade_section_row = (await self.db.execute(
            select(
                func.count().filter(Grade.is_active == True).label("grades"),
                func.count().filter(Section.is_active == True).label("sections"),
            ).select_from(Grade.outerjoin(Section, Section.grade_id == Grade.id))
            .where(Grade.tenant_id == tenant_id)
        )).one()
        total_grades, total_sections = grade_section_row

        att_row = (await self.db.execute(
            select(
                func.count().filter(StudentAttendance.status == "present").label("present"),
                func.count().filter(StudentAttendance.status == "absent").label("absent"),
            ).where(
                StudentAttendance.tenant_id == tenant_id,
                StudentAttendance.date == today,
            )
        )).one()
        present_today, absent_today = att_row

        attendance_pct = round(present_today / (present_today + absent_today) * 100, 1) if (present_today + absent_today) > 0 else 0

        fee_row = (await self.db.execute(
            select(
                func.coalesce(func.sum(FeePayment.amount), 0).label("collected"),
                func.count().filter(StudentFee.status.in_(["pending", "partial", "overdue"])).label("pending"),
            ).select_from(
                StudentFee.outerjoin(FeePayment, FeePayment.student_fee_id == StudentFee.id)
            ).where(StudentFee.tenant_id == tenant_id)
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

    async def attendance_overview(self, tenant_id: uuid.UUID, days: int = 7) -> List[Dict[str, Any]]:
        start_date = date.today() - timedelta(days=days)

        stmt = select(
            StudentAttendance.date,
            StudentAttendance.status,
            func.count(StudentAttendance.id),
        ).where(
            StudentAttendance.tenant_id == tenant_id,
            StudentAttendance.date >= start_date,
            StudentAttendance.attendance_type == "daily",
        ).group_by(StudentAttendance.date, StudentAttendance.status).order_by(StudentAttendance.date)

        result = await self.db.execute(stmt)
        rows = result.all()

        daily = {}
        for d, status, count in rows:
            day_str = str(d)
            if day_str not in daily:
                daily[day_str] = {"date": day_str, "present": 0, "absent": 0, "late": 0}
            daily[day_str][status] = count

        return list(daily.values())
