import uuid
import random
import string
from typing import Any, Dict, List, Optional, Union
from datetime import date, datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.admission import AdmissionInquiry, AdmissionApplication
from app.models.school.student import Student


class AdmissionService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_inquiries(
        self, tenant_id: uuid.UUID, inquiry_status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(AdmissionInquiry).where(AdmissionInquiry.tenant_id == tenant_id)
        if inquiry_status:
            stmt = stmt.where(AdmissionInquiry.status == inquiry_status)
        stmt = stmt.order_by(AdmissionInquiry.created_at.desc())
        result = await self.db.execute(stmt)
        inquiries = result.scalars().all()
        return [
            {
                "id": str(i.id),
                "student_name": i.student_name,
                "parent_name": i.parent_name,
                "phone": i.phone,
                "grade_applying": i.grade_applying,
                "source": i.source,
                "status": i.status,
            }
            for i in inquiries
        ]

    async def create_inquiry(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AdmissionInquiry:
        if not isinstance(data, dict):
            data = data.model_dump()
        inquiry = AdmissionInquiry(tenant_id=tenant_id, status="new", **data)
        self.db.add(inquiry)
        await self.db.commit()
        await self.db.refresh(inquiry)
        return inquiry

    async def list_applications(
        self, tenant_id: uuid.UUID, app_status: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(AdmissionApplication).where(AdmissionApplication.tenant_id == tenant_id)
        if app_status:
            stmt = stmt.where(AdmissionApplication.status == app_status)
        stmt = stmt.order_by(AdmissionApplication.created_at.desc())
        result = await self.db.execute(stmt)
        apps = result.scalars().all()
        return [
            {
                "id": str(a.id),
                "application_number": a.application_number,
                "student_name": a.student_name,
                "grade_applying": a.grade_applying,
                "parent_name": a.parent_name,
                "status": a.status,
            }
            for a in apps
        ]

    async def create_application(
        self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> AdmissionApplication:
        if not isinstance(data, dict):
            data = data.model_dump()

        app_number = f"APP-{date.today().strftime('%Y%m')}-{''.join(random.choices(string.digits, k=4))}"

        application = AdmissionApplication(
            tenant_id=tenant_id,
            application_number=app_number,
            status="submitted",
            **data,
        )
        self.db.add(application)
        await self.db.commit()
        await self.db.refresh(application)
        return application

    async def review_application(
        self,
        app_id: uuid.UUID,
        tenant_id: uuid.UUID,
        reviewed_by: uuid.UUID,
        new_status: str = "under_review",
        remarks: Optional[str] = None,
    ) -> AdmissionApplication:
        app = await self.db.get(AdmissionApplication, app_id)
        if not app or app.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
        app.status = new_status
        app.remarks = remarks
        app.reviewed_by = reviewed_by
        app.reviewed_at = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(app)
        return app

    async def enroll_student(
        self,
        app_id: uuid.UUID,
        tenant_id: uuid.UUID,
        grade_id: Optional[uuid.UUID] = None,
        section_id: Optional[uuid.UUID] = None,
    ) -> Student:
        app = await self.db.get(AdmissionApplication, app_id)
        if not app or app.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Application not found")
        if app.status not in ("selected", "submitted"):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Application not in enrollable state")

        adm_number = f"ADM-{date.today().strftime('%Y')}-{''.join(random.choices(string.digits, k=4))}"

        name_parts = app.student_name.split() if app.student_name else [""]
        first_name = name_parts[0]
        last_name = " ".join(name_parts[1:]) if len(name_parts) > 1 else ""

        student = Student(
            tenant_id=tenant_id,
            admission_number=adm_number,
            first_name=first_name,
            last_name=last_name,
            date_of_birth=app.date_of_birth,
            gender=app.gender,
            admission_date=date.today(),
            current_grade_id=grade_id,
            current_section_id=section_id,
            academic_year_id=app.academic_year_id,
            previous_school=app.previous_school,
            address=app.address,
            emergency_contact_name=app.parent_name,
            emergency_contact_phone=app.parent_phone,
            status="active",
        )
        self.db.add(student)
        await self.db.flush()

        app.status = "enrolled"
        app.student_id = student.id
        await self.db.commit()
        await self.db.refresh(student)
        return student
