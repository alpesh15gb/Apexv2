import uuid
from typing import Any, Dict, List, Optional, Tuple, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.student_attendance import StudentAttendance
from app.models.school.student import Student


class AttendanceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def mark_attendance(
        self,
        tenant_id: uuid.UUID,
        marked_by: uuid.UUID,
        student_id: uuid.UUID,
        attendance_date: date,
        attendance_status: str,
        attendance_type: str = "daily",
        remarks: Optional[str] = None,
        period_definition_id: Optional[uuid.UUID] = None,
    ) -> None:
        student = await self.db.get(Student, student_id)
        if not student or student.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        stmt = select(StudentAttendance).where(
            StudentAttendance.student_id == student_id,
            StudentAttendance.date == attendance_date,
            StudentAttendance.attendance_type == attendance_type,
            StudentAttendance.tenant_id == tenant_id,
        )
        if period_definition_id:
            stmt = stmt.where(StudentAttendance.period_definition_id == period_definition_id)
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.status = attendance_status
            existing.remarks = remarks
            existing.marked_by = marked_by
        else:
            attendance = StudentAttendance(
                tenant_id=tenant_id,
                student_id=student_id,
                date=attendance_date,
                status=attendance_status,
                remarks=remarks,
                marked_by=marked_by,
                attendance_type=attendance_type,
                period_definition_id=period_definition_id,
                academic_year_id=student.academic_year_id,
            )
            self.db.add(attendance)

        await self.db.commit()

    async def bulk_mark_attendance(
        self,
        tenant_id: uuid.UUID,
        marked_by: uuid.UUID,
        section_id: uuid.UUID,
        attendance_date: date,
        marks: List[Dict[str, Any]],
        attendance_type: str = "daily",
    ) -> int:
        count = 0
        for mark in marks:
            student_id = mark.get("student_id")
            attendance_status = mark.get("status")
            if not student_id or not attendance_status:
                continue

            sid = uuid.UUID(student_id) if isinstance(student_id, str) else student_id
            student = await self.db.get(Student, sid)
            if not student or student.tenant_id != tenant_id:
                continue

            stmt = select(StudentAttendance).where(
                StudentAttendance.student_id == sid,
                StudentAttendance.date == attendance_date,
                StudentAttendance.attendance_type == attendance_type,
                StudentAttendance.tenant_id == tenant_id,
            )
            result = await self.db.execute(stmt)
            existing = result.scalar_one_or_none()

            if existing:
                existing.status = attendance_status
                existing.marked_by = marked_by
            else:
                attendance = StudentAttendance(
                    tenant_id=tenant_id,
                    student_id=sid,
                    date=attendance_date,
                    status=attendance_status,
                    marked_by=marked_by,
                    attendance_type=attendance_type,
                    academic_year_id=student.academic_year_id,
                )
                self.db.add(attendance)
            count += 1

        await self.db.commit()
        return count

    async def get_attendance(
        self,
        tenant_id: uuid.UUID,
        date_from: date,
        date_to: date,
        section_id: Optional[uuid.UUID] = None,
        student_id: Optional[uuid.UUID] = None,
    ) -> List[Dict[str, Any]]:
        stmt = (
            select(StudentAttendance, Student)
            .join(Student, Student.id == StudentAttendance.student_id)
            .where(
                StudentAttendance.tenant_id == tenant_id,
                StudentAttendance.date >= date_from,
                StudentAttendance.date <= date_to,
            )
        )
        if student_id:
            stmt = stmt.where(StudentAttendance.student_id == student_id)
        if section_id:
            stmt = stmt.where(Student.current_section_id == section_id)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(a.id),
                "student_id": str(a.student_id),
                "student_name": f"{s.first_name} {s.last_name}",
                "date": str(a.date),
                "status": a.status,
                "attendance_type": a.attendance_type,
            }
            for a, s in rows
        ]

    async def daily_summary(
        self,
        tenant_id: uuid.UUID,
        summary_date: date,
        section_id: Optional[uuid.UUID] = None,
    ) -> Dict[str, int]:
        stmt = (
            select(StudentAttendance.status, func.count(StudentAttendance.id))
            .where(
                StudentAttendance.tenant_id == tenant_id,
                StudentAttendance.date == summary_date,
                StudentAttendance.attendance_type == "daily",
            )
        )
        if section_id:
            stmt = stmt.join(Student, Student.id == StudentAttendance.student_id).where(
                Student.current_section_id == section_id
            )
        stmt = stmt.group_by(StudentAttendance.status)
        result = await self.db.execute(stmt)
        rows = result.all()
        return {attendance_status: count for attendance_status, count in rows}
