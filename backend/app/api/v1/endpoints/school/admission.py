"""Admission management endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.admission import AdmissionInquiry, AdmissionApplication
from app.models.school.student import Student

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
    stmt = select(AdmissionInquiry).where(AdmissionInquiry.tenant_id == current_user.tenant_id)
    if status:
        stmt = stmt.where(AdmissionInquiry.status == status)
    stmt = stmt.order_by(AdmissionInquiry.created_at.desc())
    result = await db.execute(stmt)
    inquiries = result.scalars().all()
    return [
        {"id": str(i.id), "student_name": i.student_name, "parent_name": i.parent_name, "phone": i.phone, "grade_applying": i.grade_applying, "source": i.source, "status": i.status}
        for i in inquiries
    ]


@router.post("/inquiries")
async def create_inquiry(
    data: InquiryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    inquiry = AdmissionInquiry(tenant_id=current_user.tenant_id, status="new", **data.model_dump())
    db.add(inquiry)
    await db.commit()
    return {"id": str(inquiry.id)}


@router.get("/applications")
async def list_applications(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(AdmissionApplication).where(AdmissionApplication.tenant_id == current_user.tenant_id)
    if status:
        stmt = stmt.where(AdmissionApplication.status == status)
    stmt = stmt.order_by(AdmissionApplication.created_at.desc())
    result = await db.execute(stmt)
    apps = result.scalars().all()
    return [
        {
            "id": str(a.id), "application_number": a.application_number, "student_name": a.student_name,
            "grade_applying": a.grade_applying, "parent_name": a.parent_name, "status": a.status,
        }
        for a in apps
    ]


@router.post("/applications")
async def create_application(
    data: ApplicationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    import random, string
    app_number = f"APP-{date.today().strftime('%Y%m')}-{''.join(random.choices(string.digits, k=4))}"

    application = AdmissionApplication(
        tenant_id=current_user.tenant_id,
        application_number=app_number,
        status="submitted",
        **data.model_dump(),
    )
    db.add(application)
    await db.commit()
    return {"id": str(application.id), "application_number": app_number}


@router.put("/applications/{app_id}/review")
async def review_application(
    app_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    app = await db.get(AdmissionApplication, app_id)
    if not app or app.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Application not found")
    app.status = data.get("status", "under_review")
    app.remarks = data.get("remarks")
    app.reviewed_by = current_user.id
    from datetime import datetime, timezone
    app.reviewed_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(app.id), "status": app.status}


@router.post("/applications/{app_id}/enroll")
async def enroll_student(
    app_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    app = await db.get(AdmissionApplication, app_id)
    if not app or app.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Application not found")
    if app.status not in ("selected", "submitted"):
        raise HTTPException(status_code=400, detail="Application not in enrollable state")

    import random, string
    adm_number = f"ADM-{date.today().strftime('%Y')}-{''.join(random.choices(string.digits, k=4))}"

    student = Student(
        tenant_id=current_user.tenant_id,
        admission_number=adm_number,
        first_name=app.student_name.split()[0] if app.student_name else app.student_name,
        last_name=" ".join(app.student_name.split()[1:]) if len(app.student_name.split()) > 1 else "",
        date_of_birth=app.date_of_birth,
        gender=app.gender,
        admission_date=date.today(),
        current_grade_id=data.get("grade_id"),
        current_section_id=data.get("section_id"),
        academic_year_id=app.academic_year_id,
        previous_school=app.previous_school,
        address=app.address,
        emergency_contact_name=app.parent_name,
        emergency_contact_phone=app.parent_phone,
        status="active",
    )
    db.add(student)
    await db.flush()

    app.status = "enrolled"
    app.student_id = student.id
    await db.commit()
    return {"id": str(student.id), "admission_number": adm_number}
