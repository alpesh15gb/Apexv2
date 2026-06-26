"""Holiday CRUD endpoints."""

import uuid
from typing import List, Optional
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, extract
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.holiday import Holiday
from app.schemas.common import ResponseBase
from app.schemas.holiday import HolidayCreate, HolidayUpdate, HolidayResponse

router = APIRouter()


@router.get("/", response_model=List[HolidayResponse])
async def list_holidays(
    year: Optional[int] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Holiday).where(Holiday.tenant_id == current_user.tenant_id)
    if year:
        stmt = stmt.where(extract('year', Holiday.date) == year)
    stmt = stmt.order_by(Holiday.date)
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("/", response_model=HolidayResponse, status_code=201)
async def create_holiday(
    data: HolidayCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    holiday = Holiday(
        tenant_id=current_user.tenant_id,
        name=data.name,
        date=data.date,
        type=data.type,
        description=data.description,
        is_active=data.is_active,
    )
    db.add(holiday)
    await db.commit()
    await db.refresh(holiday)
    return holiday


@router.put("/{holiday_id}", response_model=HolidayResponse)
async def update_holiday(
    holiday_id: uuid.UUID,
    data: HolidayUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Holiday).where(
        Holiday.id == holiday_id,
        Holiday.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    holiday = result.scalar_one_or_none()
    if not holiday:
        raise HTTPException(status_code=404, detail="Holiday not found")

    update_data = data.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(holiday, field, val)

    await db.commit()
    await db.refresh(holiday)
    return holiday


@router.delete("/{holiday_id}", response_model=ResponseBase)
async def delete_holiday(
    holiday_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Holiday).where(
        Holiday.id == holiday_id,
        Holiday.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    holiday = result.scalar_one_or_none()
    if not holiday:
        raise HTTPException(status_code=404, detail="Holiday not found")

    await db.delete(holiday)
    await db.commit()
    return ResponseBase(message="Holiday deleted")
