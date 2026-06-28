"""Homework and Assignment endpoints."""

import uuid
from typing import Optional, List
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.homework_service import HomeworkService

router = APIRouter(dependencies=[Depends(require_feature("homework")), Depends(require_permissions("homework.read"))])


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
    svc = HomeworkService(db)
    return await svc.list_homework(
        tenant_id=current_user.tenant_id,
        section_id=section_id,
        subject_id=subject_id,
    )


@router.post("/")
async def create_homework(
    data: HomeworkCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HomeworkService(db)
    homework = await svc.create_homework(
        tenant_id=current_user.tenant_id,
        employee_id=current_user.id,
        data=data,
    )
    return {"id": str(homework.id)}


@router.get("/{homework_id}/submissions")
async def list_submissions(
    homework_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HomeworkService(db)
    return await svc.list_submissions(homework_id=homework_id, tenant_id=current_user.tenant_id)


@router.post("/{homework_id}/submit")
async def submit_homework(
    homework_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HomeworkService(db)
    sub = await svc.submit_homework(
        homework_id=homework_id,
        tenant_id=current_user.tenant_id,
        student_id=data.get("student_id"),
        attachment_urls=data.get("attachment_urls", []),
    )
    return {"id": str(sub.id)}


@router.put("/submissions/{submission_id}/review")
async def review_submission(
    submission_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HomeworkService(db)
    sub = await svc.review_submission(
        submission_id=submission_id,
        tenant_id=current_user.tenant_id,
        reviewer_id=current_user.id,
        data=data,
    )
    return {"id": str(sub.id)}
