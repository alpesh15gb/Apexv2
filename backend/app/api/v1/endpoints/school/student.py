"""Student management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.student_service import StudentService

router = APIRouter(dependencies=[Depends(require_feature("student_management")), Depends(require_permissions("student.read"))])


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
    svc = StudentService(db)
    items, total = await svc.list_students(
        tenant_id=current_user.tenant_id,
        grade_id=grade_id,
        section_id=section_id,
        student_status=status,
        search=search,
        page=page,
        page_size=page_size,
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/")
async def create_student(
    data: StudentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    student = await svc.create_student(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(student.id), "admission_number": student.admission_number}


@router.get("/{student_id}")
async def get_student(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    s = await svc.get_student(student_id, current_user.tenant_id)
    return {
        "id": str(s.id), "admission_number": s.admission_number, "roll_number": s.roll_number,
        "first_name": s.first_name, "last_name": s.last_name, "middle_name": s.middle_name,
        "date_of_birth": str(s.date_of_birth), "gender": s.gender, "blood_group": s.blood_group,
        "email": s.email, "phone": s.phone, "address": s.address,
        "current_grade_id": str(s.current_grade_id) if s.current_grade_id else None,
        "current_section_id": str(s.current_section_id) if s.current_section_id else None,
        "status": s.status, "admission_date": str(s.admission_date),
        "medical_conditions": s.medical_conditions, "allergies": s.allergies,
        "emergency_contact_name": s.emergency_contact_name,
        "emergency_contact_phone": s.emergency_contact_phone,
    }


@router.put("/{student_id}")
async def update_student(
    student_id: uuid.UUID,
    data: StudentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    student = await svc.update_student(student_id, current_user.tenant_id, data)
    return {"id": str(student.id)}


@router.post("/{student_id}/guardians")
async def add_guardian(
    student_id: uuid.UUID,
    data: GuardianCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    guardian = await svc.add_guardian(student_id, current_user.tenant_id, data)
    return {"id": str(guardian.id)}


@router.get("/{student_id}/guardians")
async def list_guardians(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    return await svc.list_guardians(student_id, current_user.tenant_id)


@router.post("/{student_id}/promote")
async def promote_student(
    student_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = StudentService(db)
    student = await svc.promote_student(
        student_id,
        current_user.tenant_id,
        new_grade_id=data.get("new_grade_id"),
        new_section_id=data.get("new_section_id"),
        new_academic_year_id=data.get("new_academic_year_id"),
    )
    return {"id": str(student.id), "status": "promoted"}
