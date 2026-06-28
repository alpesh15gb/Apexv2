"""Work Code CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.work_code import WorkCode
from app.schemas.common import ResponseBase
from app.schemas.work_code import WorkCodeCreate, WorkCodeUpdate, WorkCodeResponse

router = APIRouter(dependencies=[Depends(require_permissions("attendance.read"))])


@router.get("/", response_model=List[WorkCodeResponse])
async def list_work_codes(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(WorkCode).where(WorkCode.tenant_id == current_user.tenant_id).order_by(WorkCode.code)
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=WorkCodeResponse, status_code=201)
async def create_work_code(data: WorkCodeCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    existing = select(WorkCode).where(WorkCode.tenant_id == current_user.tenant_id, WorkCode.code == data.code)
    if (await db.execute(existing)).scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Work code already exists")
    wc = WorkCode(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(wc)
    await db.commit()
    await db.refresh(wc)
    return wc


@router.put("/{wc_id}", response_model=WorkCodeResponse)
async def update_work_code(wc_id: uuid.UUID, data: WorkCodeUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(WorkCode).where(WorkCode.id == wc_id, WorkCode.tenant_id == current_user.tenant_id)
    wc = (await db.execute(stmt)).scalar_one_or_none()
    if not wc:
        raise HTTPException(status_code=404, detail="Work code not found")
    for field, val in data.model_dump(exclude_unset=True).items():
        setattr(wc, field, val)
    await db.commit()
    await db.refresh(wc)
    return wc


@router.delete("/{wc_id}", response_model=ResponseBase)
async def delete_work_code(wc_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(WorkCode).where(WorkCode.id == wc_id, WorkCode.tenant_id == current_user.tenant_id)
    wc = (await db.execute(stmt)).scalar_one_or_none()
    if not wc:
        raise HTTPException(status_code=404, detail="Work code not found")
    await db.delete(wc)
    await db.commit()
    return ResponseBase(message="Work code deleted")
