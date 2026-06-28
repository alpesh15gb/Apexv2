"""OT Register CRUD endpoints."""

import uuid
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.ot_register import OTRegister
from app.schemas.common import ResponseBase
from app.schemas.ot_register import OTRegisterCreate, OTRegisterUpdate, OTRegisterResponse

router = APIRouter(dependencies=[Depends(require_feature("overtime"))])


@router.get("/", response_model=List[OTRegisterResponse])
async def list_ot(
    employee_id: Optional[uuid.UUID] = Query(None),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(OTRegister).where(OTRegister.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(OTRegister.employee_id == employee_id)
    if from_date:
        stmt = stmt.where(OTRegister.date >= from_date)
    if to_date:
        stmt = stmt.where(OTRegister.date <= to_date)
    if status:
        stmt = stmt.where(OTRegister.status == status)
    stmt = stmt.order_by(OTRegister.date.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=OTRegisterResponse, status_code=201)
async def create_ot(data: OTRegisterCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    ot = OTRegister(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(ot)
    await db.commit()
    await db.refresh(ot)
    return ot


@router.put("/{ot_id}", response_model=OTRegisterResponse)
async def update_ot(ot_id: uuid.UUID, data: OTRegisterUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OTRegister).where(OTRegister.id == ot_id, OTRegister.tenant_id == current_user.tenant_id)
    ot = (await db.execute(stmt)).scalar_one_or_none()
    if not ot:
        raise HTTPException(status_code=404, detail="OT record not found")
    for field, val in data.model_dump(exclude_unset=True).items():
        setattr(ot, field, val)
    await db.commit()
    await db.refresh(ot)
    return ot


@router.delete("/{ot_id}", response_model=ResponseBase)
async def delete_ot(ot_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OTRegister).where(OTRegister.id == ot_id, OTRegister.tenant_id == current_user.tenant_id)
    ot = (await db.execute(stmt)).scalar_one_or_none()
    if not ot:
        raise HTTPException(status_code=404, detail="OT record not found")
    await db.delete(ot)
    await db.commit()
    return ResponseBase(message="OT record deleted")
