"""Examination and marks endpoints."""

import uuid
from typing import Optional, List

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.exam_service import ExamService

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
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    items, total = await svc.list_exam_types(current_user.tenant_id, page, page_size)
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/exam-types", dependencies=[Depends(require_permissions("exam.create"))])
async def create_exam_type(
    data: ExamTypeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    exam_type = await svc.create_exam_type(current_user.tenant_id, data)
    return {"id": str(exam_type.id)}


@router.get("/exams")
async def list_exams(
    academic_year_id: Optional[uuid.UUID] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    items, total = await svc.list_exams(
        current_user.tenant_id, academic_year_id=academic_year_id, page=page, page_size=page_size
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/exams", dependencies=[Depends(require_permissions("exam.create"))])
async def create_exam(
    data: ExamCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    exam = await svc.create_exam(current_user.tenant_id, data)
    return {"id": str(exam.id)}


@router.get("/exams/{exam_id}/schedules")
async def list_exam_schedules(
    exam_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    items, total = await svc.list_exam_schedules(exam_id, current_user.tenant_id, page, page_size)
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/exams/{exam_id}/schedules", dependencies=[Depends(require_permissions("exam.manage"))])
async def create_exam_schedule(
    exam_id: uuid.UUID,
    data: ExamScheduleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    schedule = await svc.create_exam_schedule(exam_id, current_user.tenant_id, data)
    return {"id": str(schedule.id)}


@router.post("/marks/enter", dependencies=[Depends(require_permissions("exam.manage"))])
async def enter_marks(
    data: MarkEntry,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    await svc.enter_marks(current_user.tenant_id, current_user.id, data)
    return {"status": "entered"}


@router.post("/marks/bulk-enter", dependencies=[Depends(require_permissions("exam.manage"))])
async def bulk_enter_marks(
    data: List[MarkEntry],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    entries = [e.model_dump() for e in data]
    count = await svc.bulk_enter_marks(current_user.tenant_id, current_user.id, entries)
    return {"entered": count}


@router.get("/marks/{exam_schedule_id}")
async def get_marks_for_schedule(
    exam_schedule_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    return await svc.get_marks_for_schedule(exam_schedule_id, current_user.tenant_id)


@router.get("/grading-scales")
async def list_grading_scales(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=200),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    items, total = await svc.list_grading_scales(current_user.tenant_id, page, page_size)
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/grading-scales", dependencies=[Depends(require_permissions("exam.manage"))])
async def create_grading_scale(
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = ExamService(db)
    scale = await svc.create_grading_scale(current_user.tenant_id, data)
    return {"id": str(scale.id)}
