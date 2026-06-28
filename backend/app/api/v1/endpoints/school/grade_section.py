"""Grade, Section, and Subject management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.grade import Grade, Section, House
from app.models.school.subject import Subject, GradeSubject, TeacherAllocation
from app.models.school.student import Student

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
    stmt = select(Grade).where(Grade.tenant_id == current_user.tenant_id, Grade.is_active == True).order_by(Grade.sort_order)
    result = await db.execute(stmt)
    grades = result.scalars().all()
    return [{"id": str(g.id), "name": g.name, "code": g.code, "sort_order": g.sort_order} for g in grades]


@router.post("/grades")
async def create_grade(
    data: GradeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    grade = Grade(tenant_id=current_user.tenant_id, name=data.name, code=data.code, sort_order=data.sort_order)
    db.add(grade)
    await db.commit()
    return {"id": str(grade.id)}


@router.put("/grades/{grade_id}")
async def update_grade(
    grade_id: uuid.UUID,
    data: GradeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    grade = await db.get(Grade, grade_id)
    if not grade or grade.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Grade not found")
    grade.name = data.name
    grade.code = data.code
    grade.sort_order = data.sort_order
    await db.commit()
    return {"id": str(grade.id)}


# ── Sections ────────────────────────────────────────

@router.get("/grades/{grade_id}/sections")
async def list_sections(
    grade_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Section).where(Section.grade_id == grade_id, Section.tenant_id == current_user.tenant_id, Section.is_active == True)
    if academic_year_id:
        stmt = stmt.where(Section.academic_year_id == academic_year_id)
    result = await db.execute(stmt)
    sections = result.scalars().all()
    return [{"id": str(s.id), "name": s.name, "capacity": s.capacity, "class_teacher_id": str(s.class_teacher_id) if s.class_teacher_id else None} for s in sections]


@router.post("/grades/{grade_id}/sections")
async def create_section(
    grade_id: uuid.UUID,
    data: SectionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    section = Section(
        tenant_id=current_user.tenant_id,
        grade_id=grade_id,
        name=data.name,
        capacity=data.capacity,
        room_id=data.room_id,
        class_teacher_id=data.class_teacher_id,
        academic_year_id=data.academic_year_id,
    )
    db.add(section)
    await db.commit()
    return {"id": str(section.id)}


@router.get("/sections/{section_id}/students")
async def list_section_students(
    section_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Student).where(
        Student.current_section_id == section_id,
        Student.tenant_id == current_user.tenant_id,
        Student.is_active == True,
    ).order_by(Student.roll_number, Student.first_name)
    result = await db.execute(stmt)
    students = result.scalars().all()
    return [
        {
            "id": str(s.id), "admission_number": s.admission_number, "roll_number": s.roll_number,
            "first_name": s.first_name, "last_name": s.last_name, "gender": s.gender, "status": s.status,
        }
        for s in students
    ]


# ── Subjects ────────────────────────────────────────

subjects_router = APIRouter(dependencies=[Depends(require_feature("subject_management")), Depends(require_permissions("school.settings"))])


@subjects_router.get("/subjects")
async def list_subjects(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Subject).where(Subject.tenant_id == current_user.tenant_id, Subject.is_active == True)
    result = await db.execute(stmt)
    subjects = result.scalars().all()
    return [{"id": str(s.id), "name": s.name, "code": s.code, "subject_type": s.subject_type, "max_marks": s.max_marks} for s in subjects]


@subjects_router.post("/subjects")
async def create_subject(
    data: SubjectCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    subject = Subject(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(subject)
    await db.commit()
    return {"id": str(subject.id)}


@subjects_router.put("/subjects/{subject_id}")
async def update_subject(
    subject_id: uuid.UUID,
    data: SubjectCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    subject = await db.get(Subject, subject_id)
    if not subject or subject.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Subject not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(subject, field, value)
    await db.commit()
    return {"id": str(subject.id)}


@subjects_router.get("/grades/{grade_id}/subjects")
async def list_grade_subjects(
    grade_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(GradeSubject, Subject).join(Subject, Subject.id == GradeSubject.subject_id).where(
        GradeSubject.grade_id == grade_id, GradeSubject.tenant_id == current_user.tenant_id
    )
    if academic_year_id:
        stmt = stmt.where(GradeSubject.academic_year_id == academic_year_id)
    result = await db.execute(stmt)
    rows = result.all()
    return [{"id": str(gs.id), "subject_id": str(gs.subject_id), "subject_name": s.name, "subject_code": s.code, "is_compulsory": gs.is_compulsory} for gs, s in rows]


@subjects_router.post("/grades/{grade_id}/subjects")
async def assign_subjects_to_grade(
    grade_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    subject_ids = data.get("subject_ids", [])
    academic_year_id = data.get("academic_year_id")
    for sid in subject_ids:
        gs = GradeSubject(
            tenant_id=current_user.tenant_id,
            grade_id=grade_id,
            subject_id=sid,
            academic_year_id=academic_year_id,
        )
        db.add(gs)
    await db.commit()
    return {"assigned": len(subject_ids)}


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
    stmt = select(TeacherAllocation).where(TeacherAllocation.tenant_id == current_user.tenant_id)
    if section_id:
        stmt = stmt.where(TeacherAllocation.section_id == section_id)
    if employee_id:
        stmt = stmt.where(TeacherAllocation.employee_id == employee_id)
    if academic_year_id:
        stmt = stmt.where(TeacherAllocation.academic_year_id == academic_year_id)
    result = await db.execute(stmt)
    allocs = result.scalars().all()
    return [
        {
            "id": str(a.id), "employee_id": str(a.employee_id), "subject_id": str(a.subject_id),
            "section_id": str(a.section_id), "academic_year_id": str(a.academic_year_id),
            "periods_per_week": a.periods_per_week,
        }
        for a in allocs
    ]


@alloc_router.post("/teacher-allocations")
async def create_teacher_allocation(
    data: TeacherAllocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    alloc = TeacherAllocation(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(alloc)
    await db.commit()
    return {"id": str(alloc.id)}
