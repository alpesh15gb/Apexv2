"""Certificate endpoints."""

import uuid
import random
import string
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.certificate import CertificateTemplate, IssuedCertificate
from app.models.school.student import Student

router = APIRouter(dependencies=[Depends(require_feature("school_certificates"))])


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
    stmt = select(CertificateTemplate).where(CertificateTemplate.tenant_id == current_user.tenant_id, CertificateTemplate.is_active == True)
    if template_type:
        stmt = stmt.where(CertificateTemplate.template_type == template_type)
    result = await db.execute(stmt)
    templates = result.scalars().all()
    return [{"id": str(t.id), "name": t.name, "template_type": t.template_type, "is_default": t.is_default} for t in templates]


@router.post("/templates")
async def create_template(
    data: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    template = CertificateTemplate(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(template)
    await db.commit()
    return {"id": str(template.id)}


@router.post("/issue")
async def issue_certificate(
    data: IssueCertificate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    student = await db.get(Student, data.student_id)
    if not student or student.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Student not found")

    cert_number = f"CERT-{date.today().strftime('%Y%m%d')}-{''.join(random.choices(string.digits, k=4))}"

    certificate = IssuedCertificate(
        tenant_id=current_user.tenant_id,
        certificate_number=cert_number,
        issued_by=current_user.id,
        **data.model_dump(),
    )
    db.add(certificate)
    await db.commit()
    return {"id": str(certificate.id), "certificate_number": cert_number}


@router.get("/student/{student_id}")
async def list_student_certificates(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(IssuedCertificate, CertificateTemplate).join(
        CertificateTemplate, CertificateTemplate.id == IssuedCertificate.template_id
    ).where(
        IssuedCertificate.student_id == student_id, IssuedCertificate.tenant_id == current_user.tenant_id
    )
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {"id": str(c.id), "certificate_number": c.certificate_number, "template_name": t.name, "template_type": t.template_type, "issue_date": str(c.issue_date), "purpose": c.purpose}
        for c, t in rows
    ]
