"""Onboarding CRUD endpoints."""
import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.onboarding import OnboardingTask
from app.schemas.common import ResponseBase
from app.schemas.onboarding import OnboardingTaskCreate, OnboardingTaskUpdate, OnboardingTaskResponse

router = APIRouter()


@router.get("/", response_model=List[OnboardingTaskResponse])
async def list_tasks(
    employee_id: Optional[uuid.UUID] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(OnboardingTask).where(OnboardingTask.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(OnboardingTask.employee_id == employee_id)
    if status:
        stmt = stmt.where(OnboardingTask.status == status)
    stmt = stmt.order_by(OnboardingTask.order_index)
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=OnboardingTaskResponse, status_code=201)
async def create_task(data: OnboardingTaskCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    task = OnboardingTask(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(task)
    await db.commit()
    await db.refresh(task)
    return task


@router.put("/{task_id}", response_model=OnboardingTaskResponse)
async def update_task(task_id: uuid.UUID, data: OnboardingTaskUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OnboardingTask).where(OnboardingTask.id == task_id, OnboardingTask.tenant_id == current_user.tenant_id)
    task = (await db.execute(stmt)).scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    update_data = data.model_dump(exclude_unset=True)
    if 'status' in update_data and update_data['status'] == 'completed':
        update_data['completed_at'] = datetime.now(timezone.utc)
    for field, val in update_data.items():
        setattr(task, field, val)
    await db.commit()
    await db.refresh(task)
    return task


@router.delete("/{task_id}", response_model=ResponseBase)
async def delete_task(task_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OnboardingTask).where(OnboardingTask.id == task_id, OnboardingTask.tenant_id == current_user.tenant_id)
    task = (await db.execute(stmt)).scalar_one_or_none()
    if not task:
        raise HTTPException(status_code=404, detail="Task not found")
    await db.delete(task)
    await db.commit()
    return ResponseBase(message="Task deleted")
