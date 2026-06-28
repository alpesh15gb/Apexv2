"""Student management endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.student import Student, Guardian, StudentGuardian
from app.models.school.grade import Section

router = APIRouter(dependencies=[Depends(require_feature("student_management"))])


class StudentCreate(BaseModel):
    admission_number: str = Field(..., max_length=50)
    first_name: str = Field(..., max_length=100)
    last_name: str = Field(..., max_length=100)
    middle_name: Optional[str] = None
    date_of_birth: date
    gender: str
    blood_group: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    admission_date: date
    current_grade_id: Optional[uuid.UUID] = None
    current_section_id: Optional[uuid.UUID] = None
    academic_year_id: uuid.UUID
    previous_school: Optional[str] = None
    medical_conditions: Optional[str] = None
    allergies: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    emergency_contact_relation: Optional[str] = None


class StudentUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    roll_number: Optional[str] = None
    email: Optional[str] = None
    phone: Optional[str] = None
    address: Optional[str] = None
    current_grade_id: Optional[uuid.UUID] = None
    current_section_id: Optional[uuid.UUID] = None
    house_id: Optional[uuid.UUID] = None
    medical_conditions: Optional[str] = None
    allergies: Optional[str] = None


class GuardianCreate(BaseModel):
    first_name: str = Field(..., max_length=100)
    last_name: str = Field(..., max_length=100)
    email: Optional[str] = None
    phone: str = Field(..., max_length=20)
    occupation: Optional[str] = None
    relationship: str = "guardian"
    is_primary: bool = False


@router.get("/")
async def list_students(
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    grade_id: Optional[uuid.UUID] = None,
    section_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Student).where(Student.tenant_id == current_user.tenant_id, Student.is_active == True)
    count_stmt = select(func.count(Student.id)).where(Student.tenant_id == current_user.tenant_id, Student.is_active == True)

    if grade_id:
        stmt = stmt.where(Student.current_grade_id == grade_id)
        count_stmt = count_stmt.where(Student.current_grade_id == grade_id)
    if section_id:
        stmt = stmt.where(Student.current_section_id == section_id)
        count_stmt = count_stmt.where(Student.current_section_id == section_id)
    if status:
        stmt = stmt.where(Student.status == status)
        count_stmt = count_stmt.where(Student.status == status)
    if search:
        search_filter = Student.first_name.ilike(f"%{search}%") | Student.last_name.ilike(f"%{search}%") | Student.admission_number.ilike(f"%{search}%")
        stmt = stmt.where(search_filter)
        count_stmt = count_stmt.where(search_filter)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(Student.admission_number).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    students = result.scalars().all()

    return {
        "items": [
            {
                "id": str(s.id), "admission_number": s.admission_number, "roll_number": s.roll_number,
                "first_name": s.first_name, "last_name": s.last_name, "gender": s.gender,
                "current_grade_id": str(s.current_grade_id) if s.current_grade_id else None,
                "current_section_id": str(s.current_section_id) if s.current_section_id else None,
                "status": s.status, "admission_date": str(s.admission_date),
            }
            for s in students
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.post("/")
async def create_student(
    data: StudentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    existing = await db.execute(select(Student).where(Student.tenant_id == current_user.tenant_id, Student.admission_number == data.admission_number))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Admission number already exists")

    student = Student(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(student)
    await db.commit()
    return {"id": str(student.id), "admission_number": student.admission_number}


@router.get("/{student_id}")
async def get_student(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    student = await db.get(Student, student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")
    return {
        "id": str(student.id), "admission_number": student.admission_number, "roll_number": student.roll_number,
        "first_name": student.first_name, "last_name": student.last_name, "middle_name": student.middle_name,
        "date_of_birth": str(student.date_of_birth), "gender": student.gender, "blood_group": student.blood_group,
        "email": student.email, "phone": student.phone, "address": student.address,
        "current_grade_id": str(student.current_grade_id) if student.current_grade_id else None,
        "current_section_id": str(student.current_section_id) if student.current_section_id else None,
        "status": student.status, "admission_date": str(student.admission_date),
        "medical_conditions": student.medical_conditions, "allergies": student.allergies,
        "emergency_contact_name": student.emergency_contact_name,
        "emergency_contact_phone": student.emergency_contact_phone,
    }


@router.put("/{student_id}")
async def update_student(
    student_id: uuid.UUID,
    data: StudentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    student = await db.get(Student, student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(student, field, value)
    await db.commit()
    return {"id": str(student.id)}


@router.post("/{student_id}/guardians")
async def add_guardian(
    student_id: uuid.UUID,
    data: GuardianCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    student = await db.get(Student, student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")

    guardian = Guardian(
        tenant_id=current_user.tenant_id,
        first_name=data.first_name,
        last_name=data.last_name,
        email=data.email,
        phone=data.phone,
        occupation=data.occupation,
    )
    db.add(guardian)
    await db.flush()

    link = StudentGuardian(
        tenant_id=current_user.tenant_id,
        student_id=student_id,
        guardian_id=guardian.id,
        relationship=data.relationship,
        is_primary=data.is_primary,
    )
    db.add(link)
    await db.commit()
    return {"id": str(guardian.id)}


@router.get("/{student_id}/guardians")
async def list_guardians(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(StudentGuardian, Guardian).join(Guardian, Guardian.id == StudentGuardian.guardian_id).where(
        StudentGuardian.student_id == student_id, StudentGuardian.tenant_id == current_user.tenant_id
    )
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(g.id), "first_name": g.first_name, "last_name": g.last_name,
            "phone": g.phone, "email": g.email, "relationship": sg.relationship,
            "is_primary": sg.is_primary,
        }
        for sg, g in rows
    ]


@router.post("/{student_id}/promote")
async def promote_student(
    student_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    new_grade_id = data.get("new_grade_id")
    new_section_id = data.get("new_section_id")
    new_academic_year_id = data.get("new_academic_year_id")

    student = await db.get(Student, student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")

    student.current_grade_id = new_grade_id
    student.current_section_id = new_section_id
    student.academic_year_id = new_academic_year_id
    await db.commit()
    return {"id": str(student.id), "status": "promoted"}
