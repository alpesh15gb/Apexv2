"""Examination and marks endpoints."""

import uuid
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.examination import ExamType, Exam, ExamSchedule, ExamMark, GradingScale, GradingScaleDetail
from app.models.school.student import Student

router = APIRouter(dependencies=[Depends(require_feature("examinations")), Depends(require_permissions("exam.read"))])


class ExamTypeCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=30)
    weightage: float = 0
    exam_category: str = "internal"


class ExamCreate(BaseModel):
    exam_type_id: uuid.UUID
    academic_year_id: uuid.UUID
    academic_term_id: Optional[uuid.UUID] = None
    name: str = Field(..., max_length=255)
    start_date: date
    end_date: date


class ExamScheduleCreate(BaseModel):
    subject_id: uuid.UUID
    grade_id: uuid.UUID
    exam_date: date
    start_time: str
    end_time: str
    max_marks: int = 100
    pass_marks: int = 33


class MarkEntry(BaseModel):
    exam_schedule_id: uuid.UUID
    student_id: uuid.UUID
    marks_obtained: Optional[float] = None
    practical_marks: Optional[float] = None
    grade: Optional[str] = None
    is_absent: bool = False
    remarks: Optional[str] = None


@router.get("/exam-types")
async def list_exam_types(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ExamType).where(ExamType.tenant_id == current_user.tenant_id, ExamType.is_active == True)
    result = await db.execute(stmt)
    types = result.scalars().all()
    return [{"id": str(t.id), "name": t.name, "code": t.code, "weightage": float(t.weightage), "exam_category": t.exam_category} for t in types]


@router.post("/exam-types")
async def create_exam_type(
    data: ExamTypeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    exam_type = ExamType(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(exam_type)
    await db.commit()
    return {"id": str(exam_type.id)}


@router.get("/exams")
async def list_exams(
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Exam).where(Exam.tenant_id == current_user.tenant_id)
    if academic_year_id:
        stmt = stmt.where(Exam.academic_year_id == academic_year_id)
    stmt = stmt.order_by(Exam.start_date.desc())
    result = await db.execute(stmt)
    exams = result.scalars().all()
    return [{"id": str(e.id), "name": e.name, "start_date": str(e.start_date), "end_date": str(e.end_date), "status": e.status} for e in exams]


@router.post("/exams")
async def create_exam(
    data: ExamCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    exam = Exam(tenant_id=current_user.tenant_id, status="draft", **data.model_dump())
    db.add(exam)
    await db.commit()
    return {"id": str(exam.id)}


@router.get("/exams/{exam_id}/schedules")
async def list_exam_schedules(
    exam_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ExamSchedule).where(ExamSchedule.exam_id == exam_id, ExamSchedule.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    schedules = result.scalars().all()
    return [
        {
            "id": str(s.id), "subject_id": str(s.subject_id), "grade_id": str(s.grade_id),
            "exam_date": str(s.exam_date), "start_time": str(s.start_time), "end_time": str(s.end_time),
            "max_marks": s.max_marks, "pass_marks": s.pass_marks,
        }
        for s in schedules
    ]


@router.post("/exams/{exam_id}/schedules")
async def create_exam_schedule(
    exam_id: uuid.UUID,
    data: ExamScheduleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    from datetime import time as dt_time
    schedule = ExamSchedule(
        tenant_id=current_user.tenant_id,
        exam_id=exam_id,
        subject_id=data.subject_id,
        grade_id=data.grade_id,
        exam_date=data.exam_date,
        start_time=dt_time.fromisoformat(data.start_time),
        end_time=dt_time.fromisoformat(data.end_time),
        max_marks=data.max_marks,
        pass_marks=data.pass_marks,
    )
    db.add(schedule)
    await db.commit()
    return {"id": str(schedule.id)}


@router.post("/marks/enter")
async def enter_marks(
    data: MarkEntry,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ExamMark).where(ExamMark.exam_schedule_id == data.exam_schedule_id, ExamMark.student_id == data.student_id)
    result = await db.execute(stmt)
    existing = result.scalar_one_or_none()

    if existing:
        existing.marks_obtained = data.marks_obtained
        existing.practical_marks = data.practical_marks
        existing.grade = data.grade
        existing.is_absent = data.is_absent
        existing.remarks = data.remarks
        existing.entered_by = current_user.id
    else:
        mark = ExamMark(
            tenant_id=current_user.tenant_id,
            entered_by=current_user.id,
            **data.model_dump(),
        )
        db.add(mark)

    await db.commit()
    return {"status": "entered"}


@router.post("/marks/bulk-enter")
async def bulk_enter_marks(
    data: List[MarkEntry],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count = 0
    for entry in data:
        stmt = select(ExamMark).where(ExamMark.exam_schedule_id == entry.exam_schedule_id, ExamMark.student_id == entry.student_id)
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.marks_obtained = entry.marks_obtained
            existing.practical_marks = entry.practical_marks
            existing.grade = entry.grade
            existing.is_absent = entry.is_absent
            existing.entered_by = current_user.id
        else:
            mark = ExamMark(tenant_id=current_user.tenant_id, entered_by=current_user.id, **entry.model_dump())
            db.add(mark)
        count += 1

    await db.commit()
    return {"entered": count}


@router.get("/marks/{exam_schedule_id}")
async def get_marks_for_schedule(
    exam_schedule_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ExamMark, Student).join(Student, Student.id == ExamMark.student_id).where(
        ExamMark.exam_schedule_id == exam_schedule_id, ExamMark.tenant_id == current_user.tenant_id
    )
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(m.id), "student_id": str(m.student_id), "student_name": f"{s.first_name} {s.last_name}",
            "marks_obtained": float(m.marks_obtained) if m.marks_obtained else None,
            "practical_marks": float(m.practical_marks) if m.practical_marks else None,
            "grade": m.grade, "is_absent": m.is_absent,
        }
        for m, s in rows
    ]


@router.get("/grading-scales")
async def list_grading_scales(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(GradingScale).where(GradingScale.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    scales = result.scalars().all()
    return [{"id": str(s.id), "name": s.name, "scale_type": s.scale_type, "is_default": s.is_default} for s in scales]


@router.post("/grading-scales")
async def create_grading_scale(
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    scale = GradingScale(tenant_id=current_user.tenant_id, name=data["name"], scale_type=data.get("scale_type", "percentage"), is_default=data.get("is_default", False))
    db.add(scale)
    await db.flush()
    for detail in data.get("details", []):
        d = GradingScaleDetail(tenant_id=current_user.tenant_id, grading_scale_id=scale.id, **detail)
        db.add(d)
    await db.commit()
    return {"id": str(scale.id)}
