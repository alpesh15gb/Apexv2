import uuid
from datetime import time as dt_time
from typing import Any, Dict, List, Optional, Tuple, Union

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.examination import ExamType, Exam, ExamSchedule, ExamMark, GradingScale, GradingScaleDetail
from app.models.school.student import Student


class ExamService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_exam_types(
        self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 50
    ) -> Tuple[List[Dict[str, Any]], int]:
        base = (ExamType.tenant_id == tenant_id, ExamType.is_active == True)
        total = (await self.db.execute(select(func.count(ExamType.id)).where(*base))).scalar() or 0
        stmt = select(ExamType).where(*base).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        types = result.scalars().all()
        items = [
            {
                "id": str(t.id),
                "name": t.name,
                "code": t.code,
                "weightage": float(t.weightage),
                "exam_category": t.exam_category,
            }
            for t in types
        ]
        return items, total

    async def create_exam_type(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> ExamType:
        if not isinstance(data, dict):
            data = data.model_dump()
        exam_type = ExamType(tenant_id=tenant_id, **data)
        self.db.add(exam_type)
        await self.db.commit()
        await self.db.refresh(exam_type)
        return exam_type

    async def list_exams(
        self,
        tenant_id: uuid.UUID,
        academic_year_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        count_stmt = select(func.count(Exam.id)).where(Exam.tenant_id == tenant_id)
        stmt = select(Exam).where(Exam.tenant_id == tenant_id)
        if academic_year_id:
            count_stmt = count_stmt.where(Exam.academic_year_id == academic_year_id)
            stmt = stmt.where(Exam.academic_year_id == academic_year_id)
        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.order_by(Exam.start_date.desc()).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        exams = result.scalars().all()
        items = [
            {
                "id": str(e.id),
                "name": e.name,
                "start_date": str(e.start_date),
                "end_date": str(e.end_date),
                "status": e.status,
            }
            for e in exams
        ]
        return items, total

    async def create_exam(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Exam:
        if not isinstance(data, dict):
            data = data.model_dump()
        exam = Exam(tenant_id=tenant_id, status="draft", **data)
        self.db.add(exam)
        await self.db.commit()
        await self.db.refresh(exam)
        return exam

    async def list_exam_schedules(
        self, exam_id: uuid.UUID, tenant_id: uuid.UUID, page: int = 1, page_size: int = 50
    ) -> Tuple[List[Dict[str, Any]], int]:
        base = (ExamSchedule.exam_id == exam_id, ExamSchedule.tenant_id == tenant_id)
        total = (await self.db.execute(select(func.count(ExamSchedule.id)).where(*base))).scalar() or 0
        stmt = select(ExamSchedule).where(*base).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        schedules = result.scalars().all()
        items = [
            {
                "id": str(s.id),
                "subject_id": str(s.subject_id),
                "grade_id": str(s.grade_id),
                "exam_date": str(s.exam_date),
                "start_time": str(s.start_time),
                "end_time": str(s.end_time),
                "max_marks": s.max_marks,
                "pass_marks": s.pass_marks,
            }
            for s in schedules
        ]
        return items, total

    async def create_exam_schedule(
        self, exam_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> ExamSchedule:
        if not isinstance(data, dict):
            data = data.model_dump()

        schedule = ExamSchedule(
            tenant_id=tenant_id,
            exam_id=exam_id,
            subject_id=data["subject_id"],
            grade_id=data["grade_id"],
            exam_date=data["exam_date"],
            start_time=dt_time.fromisoformat(data["start_time"]),
            end_time=dt_time.fromisoformat(data["end_time"]),
            max_marks=data.get("max_marks", 100),
            pass_marks=data.get("pass_marks", 33),
        )
        self.db.add(schedule)
        await self.db.commit()
        await self.db.refresh(schedule)
        return schedule

    async def enter_marks(
        self, tenant_id: uuid.UUID, entered_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> None:
        if not isinstance(data, dict):
            data = data.model_dump()

        stmt = select(ExamMark).where(
            ExamMark.exam_schedule_id == data["exam_schedule_id"],
            ExamMark.student_id == data["student_id"],
            ExamMark.tenant_id == tenant_id,
        )
        result = await self.db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.marks_obtained = data.get("marks_obtained")
            existing.practical_marks = data.get("practical_marks")
            existing.grade = data.get("grade")
            existing.is_absent = data.get("is_absent", False)
            existing.remarks = data.get("remarks")
            existing.entered_by = entered_by
        else:
            mark = ExamMark(
                tenant_id=tenant_id,
                entered_by=entered_by,
                **data,
            )
            self.db.add(mark)

        await self.db.commit()

    async def bulk_enter_marks(
        self, tenant_id: uuid.UUID, entered_by: uuid.UUID, entries: List[Dict[str, Any]]
    ) -> int:
        if not entries:
            return 0

        schedule_ids = list({e["exam_schedule_id"] for e in entries})
        student_ids = list({e["student_id"] for e in entries})

        existing_stmt = select(ExamMark).where(
            ExamMark.exam_schedule_id.in_(schedule_ids),
            ExamMark.student_id.in_(student_ids),
            ExamMark.tenant_id == tenant_id,
        )
        existing_rows = (await self.db.execute(existing_stmt)).scalars().all()
        existing_map = {(m.exam_schedule_id, m.student_id): m for m in existing_rows}

        count = 0
        for entry in entries:
            key = (entry["exam_schedule_id"], entry["student_id"])
            existing = existing_map.get(key)

            if existing:
                existing.marks_obtained = entry.get("marks_obtained")
                existing.practical_marks = entry.get("practical_marks")
                existing.grade = entry.get("grade")
                existing.is_absent = entry.get("is_absent", False)
                existing.entered_by = entered_by
            else:
                mark = ExamMark(tenant_id=tenant_id, entered_by=entered_by, **entry)
                self.db.add(mark)
            count += 1

        await self.db.commit()
        return count

    async def get_marks_for_schedule(
        self, exam_schedule_id: uuid.UUID, tenant_id: uuid.UUID
    ) -> List[Dict[str, Any]]:
        stmt = (
            select(ExamMark, Student)
            .join(Student, Student.id == ExamMark.student_id)
            .where(ExamMark.exam_schedule_id == exam_schedule_id, ExamMark.tenant_id == tenant_id)
        )
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(m.id),
                "student_id": str(m.student_id),
                "student_name": f"{s.first_name} {s.last_name}",
                "marks_obtained": float(m.marks_obtained) if m.marks_obtained else None,
                "practical_marks": float(m.practical_marks) if m.practical_marks else None,
                "grade": m.grade,
                "is_absent": m.is_absent,
            }
            for m, s in rows
        ]

    async def list_grading_scales(
        self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 50
    ) -> Tuple[List[Dict[str, Any]], int]:
        base = GradingScale.tenant_id == tenant_id
        total = (await self.db.execute(select(func.count(GradingScale.id)).where(base))).scalar() or 0
        stmt = select(GradingScale).where(base).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        scales = result.scalars().all()
        items = [
            {"id": str(s.id), "name": s.name, "scale_type": s.scale_type, "is_default": s.is_default}
            for s in scales
        ]
        return items, total

    async def create_grading_scale(self, tenant_id: uuid.UUID, data: Dict[str, Any]) -> GradingScale:
        scale = GradingScale(
            tenant_id=tenant_id,
            name=data["name"],
            scale_type=data.get("scale_type", "percentage"),
            is_default=data.get("is_default", False),
        )
        self.db.add(scale)
        await self.db.flush()
        for detail in data.get("details", []):
            d = GradingScaleDetail(tenant_id=tenant_id, grading_scale_id=scale.id, **detail)
            self.db.add(d)
        await self.db.commit()
        await self.db.refresh(scale)
        return scale
