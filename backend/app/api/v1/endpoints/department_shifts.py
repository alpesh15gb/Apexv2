"""Department Shift CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.department_shift import DepartmentShift
from app.schemas.common import ResponseBase
from app.schemas.department_shift import DepartmentShiftCreate, DepartmentShiftResponse

router = APIRouter(dependencies=[Depends(require_feature("shift"))])


@router.get("/", response_model=List[DepartmentShiftResponse])
async def list_dept_shifts(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(DepartmentShift).where(DepartmentShift.tenant_id == current_user.tenant_id).order_by(DepartmentShift.effective_from.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=DepartmentShiftResponse, status_code=201)
async def create_dept_shift(data: DepartmentShiftCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    ds = DepartmentShift(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(ds)
    await db.commit()
    await db.refresh(ds)
    return ds


@router.delete("/{ds_id}", response_model=ResponseBase)
async def delete_dept_shift(ds_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(DepartmentShift).where(DepartmentShift.id == ds_id, DepartmentShift.tenant_id == current_user.tenant_id)
    ds = (await db.execute(stmt)).scalar_one_or_none()
    if not ds:
        raise HTTPException(status_code=404, detail="Department shift not found")
    await db.delete(ds)
    await db.commit()
    return ResponseBase(message="Department shift deleted")
