import uuid
import random
import string
from typing import Any, Dict, List, Optional, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.certificate import CertificateTemplate, IssuedCertificate
from app.models.school.student import Student


class CertificateService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_templates(
        self, tenant_id: uuid.UUID, template_type: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(CertificateTemplate).where(
            CertificateTemplate.tenant_id == tenant_id, CertificateTemplate.is_active == True
        )
        if template_type:
            stmt = stmt.where(CertificateTemplate.template_type == template_type)
        result = await self.db.execute(stmt)
        templates = result.scalars().all()
        return [
            {"id": str(t.id), "name": t.name, "template_type": t.template_type, "is_default": t.is_default}
            for t in templates
        ]

    async def create_template(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> CertificateTemplate:
        if not isinstance(data, dict):
            data = data.model_dump()
        template = CertificateTemplate(tenant_id=tenant_id, **data)
        self.db.add(template)
        await self.db.commit()
        await self.db.refresh(template)
        return template

    async def issue_certificate(
        self, tenant_id: uuid.UUID, issued_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> IssuedCertificate:
        if not isinstance(data, dict):
            data = data.model_dump()
        student = await self.db.get(Student, data["student_id"])
        if not student or student.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")

        cert_number = f"CERT-{date.today().strftime('%Y%m%d')}-{''.join(random.choices(string.digits, k=4))}"

        certificate = IssuedCertificate(
            tenant_id=tenant_id,
            certificate_number=cert_number,
            issued_by=issued_by,
            **data,
        )
        self.db.add(certificate)
        await self.db.commit()
        await self.db.refresh(certificate)
        return certificate

    async def list_student_certificates(
        self, student_id: uuid.UUID, tenant_id: uuid.UUID
    ) -> List[Dict[str, Any]]:
        stmt = select(IssuedCertificate, CertificateTemplate).join(
            CertificateTemplate, CertificateTemplate.id == IssuedCertificate.template_id
        ).where(
            IssuedCertificate.student_id == student_id, IssuedCertificate.tenant_id == tenant_id
        )
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(c.id), "certificate_number": c.certificate_number,
                "template_name": t.name, "template_type": t.template_type,
                "issue_date": str(c.issue_date), "purpose": c.purpose,
            }
            for c, t in rows
        ]
