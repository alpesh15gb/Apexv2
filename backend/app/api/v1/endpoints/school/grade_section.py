"""Grade, Section, and Subject management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.grade_section_service import GradeSectionService

router = APIRouter(dependencies=[Depends(require_feature("class_management")), Depends(require_permissions("school.settings"))])


class GradeCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    sort_order: int = 0


class SectionCreate(BaseModel):
    name: str = Field(..., max_length=50)
    capacity: int = 40
    room_id: Optional[uuid.UUID] = None
    class_teacher_id: Optional[uuid.UUID] = None
    academic_year_id: uuid.UUID


class SubjectCreate(BaseModel):
    name: str = Field(..., max_length=255)
    code: str = Field(..., max_length=50)
    subject_type: str = "core"
    department_id: Optional[uuid.UUID] = None
    credits: float = 0
    max_marks: int = 100
    pass_marks: int = 33
    has_practical: bool = False
    practical_max_marks: int = 0


class TeacherAllocationCreate(BaseModel):
    employee_id: uuid.UUID
    subject_id: uuid.UUID
    section_id: uuid.UUID
    academic_year_id: uuid.UUID
    periods_per_week: int = 0


# ── Grades ──────────────────────────────────────────

@router.get("/grades")
async def list_grades(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_grades(tenant_id=current_user.tenant_id)


@router.post("/grades")
async def create_grade(
    data: GradeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    grade = await svc.create_grade(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(grade.id)}


@router.put("/grades/{grade_id}")
async def update_grade(
    grade_id: uuid.UUID,
    data: GradeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    grade = await svc.update_grade(grade_id=grade_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(grade.id)}


# ── Sections ────────────────────────────────────────

@router.get("/grades/{grade_id}/sections")
async def list_sections(
    grade_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_sections(grade_id=grade_id, tenant_id=current_user.tenant_id, academic_year_id=academic_year_id)


@router.post("/grades/{grade_id}/sections")
async def create_section(
    grade_id: uuid.UUID,
    data: SectionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    section = await svc.create_section(grade_id=grade_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(section.id)}


@router.get("/sections/{section_id}/students")
async def list_section_students(
    section_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_section_students(section_id=section_id, tenant_id=current_user.tenant_id)


# ── Subjects ────────────────────────────────────────

subjects_router = APIRouter(dependencies=[Depends(require_feature("subject_management")), Depends(require_permissions("school.settings"))])


@subjects_router.get("/subjects")
async def list_subjects(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_subjects(tenant_id=current_user.tenant_id)


@subjects_router.post("/subjects")
async def create_subject(
    data: SubjectCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    subject = await svc.create_subject(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(subject.id)}


@subjects_router.put("/subjects/{subject_id}")
async def update_subject(
    subject_id: uuid.UUID,
    data: SubjectCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    subject = await svc.update_subject(subject_id=subject_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(subject.id)}


@subjects_router.get("/grades/{grade_id}/subjects")
async def list_grade_subjects(
    grade_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_grade_subjects(grade_id=grade_id, tenant_id=current_user.tenant_id, academic_year_id=academic_year_id)


@subjects_router.post("/grades/{grade_id}/subjects")
async def assign_subjects_to_grade(
    grade_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    count = await svc.assign_subjects_to_grade(
        grade_id=grade_id,
        tenant_id=current_user.tenant_id,
        subject_ids=data.get("subject_ids", []),
        academic_year_id=data.get("academic_year_id"),
    )
    return {"assigned": count}


# ── Teacher Allocation ──────────────────────────────

alloc_router = APIRouter(dependencies=[Depends(require_feature("class_management")), Depends(require_permissions("school.settings"))])


@alloc_router.get("/teacher-allocations")
async def list_teacher_allocations(
    section_id: Optional[uuid.UUID] = None,
    employee_id: Optional[uuid.UUID] = None,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    return await svc.list_teacher_allocations(
        tenant_id=current_user.tenant_id,
        section_id=section_id,
        employee_id=employee_id,
        academic_year_id=academic_year_id,
    )


@alloc_router.post("/teacher-allocations")
async def create_teacher_allocation(
    data: TeacherAllocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = GradeSectionService(db)
    alloc = await svc.create_teacher_allocation(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(alloc.id)}
