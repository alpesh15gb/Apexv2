"""Admission management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.admission_service import AdmissionService

router = APIRouter(dependencies=[Depends(require_feature("admissions")), Depends(require_permissions("admission.manage"))])


class InquiryCreate(BaseModel):
    student_name: str = Field(..., max_length=255)
    parent_name: Optional[str] = None
    phone: str = Field(..., max_length=20)
    email: Optional[str] = None
    grade_applying: Optional[str] = None
    source: Optional[str] = None
    notes: Optional[str] = None


class ApplicationCreate(BaseModel):
    inquiry_id: Optional[uuid.UUID] = None
    student_name: str = Field(..., max_length=255)
    date_of_birth: date
    gender: str
    grade_applying: str
    parent_name: str
    parent_phone: str
    parent_email: Optional[str] = None
    previous_school: Optional[str] = None
    address: Optional[str] = None
    academic_year_id: uuid.UUID


@router.get("/inquiries")
async def list_inquiries(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    return await svc.list_inquiries(current_user.tenant_id, inquiry_status=status)


@router.post("/inquiries")
async def create_inquiry(
    data: InquiryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    inquiry = await svc.create_inquiry(current_user.tenant_id, data)
    return {"id": str(inquiry.id)}


@router.get("/applications")
async def list_applications(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    return await svc.list_applications(current_user.tenant_id, app_status=status)


@router.post("/applications")
async def create_application(
    data: ApplicationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    application = await svc.create_application(current_user.tenant_id, data)
    return {"id": str(application.id), "application_number": application.application_number}


@router.put("/applications/{app_id}/review")
async def review_application(
    app_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    app = await svc.review_application(
        app_id,
        current_user.tenant_id,
        reviewed_by=current_user.id,
        new_status=data.get("status", "under_review"),
        remarks=data.get("remarks"),
    )
    return {"id": str(app.id), "status": app.status}


@router.post("/applications/{app_id}/enroll")
async def enroll_student(
    app_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AdmissionService(db)
    student = await svc.enroll_student(
        app_id,
        current_user.tenant_id,
        grade_id=data.get("grade_id"),
        section_id=data.get("section_id"),
    )
    return {"id": str(student.id), "admission_number": student.admission_number}
