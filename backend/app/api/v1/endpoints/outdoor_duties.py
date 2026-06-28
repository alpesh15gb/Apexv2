"""Outdoor Duty CRUD endpoints."""

import uuid
from typing import List, Optional
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.outdoor_duty import OutdoorDuty
from app.models.employee import Employee
from app.schemas.common import ResponseBase
from app.schemas.outdoor_duty import OutdoorDutyCreate, OutdoorDutyUpdate, OutdoorDutyResponse

router = APIRouter(dependencies=[Depends(require_feature("outdoor_duty"))])


@router.get("/", response_model=List[OutdoorDutyResponse])
async def list_od(
    employee_id: Optional[uuid.UUID] = Query(None),
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(OutdoorDuty).where(OutdoorDuty.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(OutdoorDuty.employee_id == employee_id)
    if from_date:
        stmt = stmt.where(OutdoorDuty.date >= from_date)
    if to_date:
        stmt = stmt.where(OutdoorDuty.date <= to_date)
    if status:
        stmt = stmt.where(OutdoorDuty.status == status)
    stmt = stmt.order_by(OutdoorDuty.date.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=OutdoorDutyResponse, status_code=201)
async def create_od(data: OutdoorDutyCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    od = OutdoorDuty(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(od)
    await db.commit()
    await db.refresh(od)
    return od


@router.put("/{od_id}", response_model=OutdoorDutyResponse)
async def update_od(od_id: uuid.UUID, data: OutdoorDutyUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OutdoorDuty).where(OutdoorDuty.id == od_id, OutdoorDuty.tenant_id == current_user.tenant_id)
    od = (await db.execute(stmt)).scalar_one_or_none()
    if not od:
        raise HTTPException(status_code=404, detail="Outdoor duty not found")
    update_data = data.model_dump(exclude_unset=True)
    if 'status' in update_data and update_data['status'] == 'approved':
        update_data['approved_at'] = datetime.now(timezone.utc)
    for field, val in update_data.items():
        setattr(od, field, val)
    await db.commit()
    await db.refresh(od)
    return od


@router.delete("/{od_id}", response_model=ResponseBase)
async def delete_od(od_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(OutdoorDuty).where(OutdoorDuty.id == od_id, OutdoorDuty.tenant_id == current_user.tenant_id)
    od = (await db.execute(stmt)).scalar_one_or_none()
    if not od:
        raise HTTPException(status_code=404, detail="Outdoor duty not found")
    await db.delete(od)
    await db.commit()
    return ResponseBase(message="Outdoor duty deleted")
