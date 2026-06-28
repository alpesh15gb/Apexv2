"""Certificate endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.certificate_service import CertificateService

router = APIRouter(dependencies=[Depends(require_feature("school_certificates")), Depends(require_permissions("certificate.issue"))])


class TemplateCreate(BaseModel):
    name: str = Field(..., max_length=100)
    template_type: str
    template_html: Optional[str] = None
    is_default: bool = False


class IssueCertificate(BaseModel):
    student_id: uuid.UUID
    template_id: uuid.UUID
    issue_date: date
    purpose: Optional[str] = None


@router.get("/templates")
async def list_templates(
    template_type: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CertificateService(db)
    return await svc.list_templates(tenant_id=current_user.tenant_id, template_type=template_type)


@router.post("/templates")
async def create_template(
    data: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CertificateService(db)
    template = await svc.create_template(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(template.id)}


@router.post("/issue")
async def issue_certificate(
    data: IssueCertificate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CertificateService(db)
    certificate = await svc.issue_certificate(
        tenant_id=current_user.tenant_id,
        issued_by=current_user.id,
        data=data,
    )
    return {"id": str(certificate.id), "certificate_number": certificate.certificate_number}


@router.get("/student/{student_id}")
async def list_student_certificates(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CertificateService(db)
    return await svc.list_student_certificates(student_id=student_id, tenant_id=current_user.tenant_id)
