import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.homework import Homework, HomeworkSubmission


class HomeworkService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_homework(
        self,
        tenant_id: uuid.UUID,
        section_id: Optional[uuid.UUID] = None,
        subject_id: Optional[uuid.UUID] = None,
    ) -> List[Dict[str, Any]]:
        stmt = select(Homework).where(Homework.tenant_id == tenant_id, Homework.is_active == True)
        if section_id:
            stmt = stmt.where(Homework.section_id == section_id)
        if subject_id:
            stmt = stmt.where(Homework.subject_id == subject_id)
        stmt = stmt.order_by(Homework.due_date.desc())
        result = await self.db.execute(stmt)
        items = result.scalars().all()
        return [
            {
                "id": str(h.id), "title": h.title, "description": h.description,
                "due_date": str(h.due_date), "section_id": str(h.section_id),
                "subject_id": str(h.subject_id), "employee_id": str(h.employee_id),
            }
            for h in items
        ]

    async def create_homework(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Homework:
        if not isinstance(data, dict):
            data = data.model_dump()
        homework = Homework(
            tenant_id=tenant_id,
            employee_id=employee_id,
            **data,
        )
        self.db.add(homework)
        await self.db.commit()
        await self.db.refresh(homework)
        return homework

    async def list_submissions(self, homework_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(HomeworkSubmission).where(
            HomeworkSubmission.homework_id == homework_id, HomeworkSubmission.tenant_id == tenant_id
        )
        result = await self.db.execute(stmt)
        subs = result.scalars().all()
        return [
            {
                "id": str(s.id), "student_id": str(s.student_id), "status": s.status,
                "marks": float(s.marks) if s.marks else None, "grade": s.grade,
                "submitted_at": s.submitted_at.isoformat() if s.submitted_at else None,
            }
            for s in subs
        ]

    async def submit_homework(
        self, homework_id: uuid.UUID, tenant_id: uuid.UUID, student_id: uuid.UUID, attachment_urls: List[str] = None
    ) -> HomeworkSubmission:
        sub = HomeworkSubmission(
            tenant_id=tenant_id,
            homework_id=homework_id,
            student_id=student_id,
            submitted_at=datetime.now(timezone.utc),
            attachment_urls=attachment_urls or [],
            status="submitted",
        )
        self.db.add(sub)
        await self.db.commit()
        await self.db.refresh(sub)
        return sub

    async def review_submission(
        self, submission_id: uuid.UUID, tenant_id: uuid.UUID, reviewer_id: uuid.UUID, data: Dict[str, Any]
    ) -> HomeworkSubmission:
        sub = await self.db.get(HomeworkSubmission, submission_id)
        if not sub or sub.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found")
        sub.marks = data.get("marks")
        sub.grade = data.get("grade")
        sub.remarks = data.get("remarks")
        sub.status = "reviewed"
        sub.reviewed_by = reviewer_id
        sub.reviewed_at = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(sub)
        return sub
