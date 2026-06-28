"""Homework and Assignment endpoints."""

import uuid
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.homework import Homework, HomeworkSubmission

router = APIRouter(dependencies=[Depends(require_feature("homework"))])


class HomeworkCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: uuid.UUID
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    due_date: date
    attachment_urls: List[str] = []
    academic_year_id: uuid.UUID


@router.get("/")
async def list_homework(
    section_id: Optional[uuid.UUID] = None,
    subject_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Homework).where(Homework.tenant_id == current_user.tenant_id, Homework.is_active == True)
    if section_id:
        stmt = stmt.where(Homework.section_id == section_id)
    if subject_id:
        stmt = stmt.where(Homework.subject_id == subject_id)
    stmt = stmt.order_by(Homework.due_date.desc())
    result = await db.execute(stmt)
    items = result.scalars().all()
    return [
        {
            "id": str(h.id), "title": h.title, "description": h.description,
            "due_date": str(h.due_date), "section_id": str(h.section_id),
            "subject_id": str(h.subject_id), "employee_id": str(h.employee_id),
        }
        for h in items
    ]


@router.post("/")
async def create_homework(
    data: HomeworkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    homework = Homework(
        tenant_id=current_user.tenant_id,
        employee_id=current_user.id,
        **data.model_dump(),
    )
    db.add(homework)
    await db.commit()
    return {"id": str(homework.id)}


@router.get("/{homework_id}/submissions")
async def list_submissions(
    homework_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(HomeworkSubmission).where(HomeworkSubmission.homework_id == homework_id, HomeworkSubmission.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    subs = result.scalars().all()
    return [
        {
            "id": str(s.id), "student_id": str(s.student_id), "status": s.status,
            "marks": float(s.marks) if s.marks else None, "grade": s.grade,
            "submitted_at": s.submitted_at.isoformat() if s.submitted_at else None,
        }
        for s in subs
    ]


@router.post("/{homework_id}/submit")
async def submit_homework(
    homework_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    student_id = data.get("student_id")
    attachment_urls = data.get("attachment_urls", [])

    from datetime import datetime, timezone
    sub = HomeworkSubmission(
        tenant_id=current_user.tenant_id,
        homework_id=homework_id,
        student_id=student_id,
        submitted_at=datetime.now(timezone.utc),
        attachment_urls=attachment_urls,
        status="submitted",
    )
    db.add(sub)
    await db.commit()
    return {"id": str(sub.id)}


@router.put("/submissions/{submission_id}/review")
async def review_submission(
    submission_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    sub = await db.get(HomeworkSubmission, submission_id)
    if not sub or sub.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Submission not found")
    sub.marks = data.get("marks")
    sub.grade = data.get("grade")
    sub.remarks = data.get("remarks")
    sub.status = "reviewed"
    sub.reviewed_by = current_user.id
    from datetime import datetime, timezone
    sub.reviewed_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(sub.id)}
