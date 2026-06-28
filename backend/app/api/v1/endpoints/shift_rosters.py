"""Shift Roster CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_feature
from app.models.user import User
from app.models.shift_roster import ShiftRoster, ShiftRosterEntry
from app.schemas.common import ResponseBase
from app.schemas.shift_roster import ShiftRosterCreate, ShiftRosterUpdate, ShiftRosterResponse

router = APIRouter(dependencies=[Depends(require_feature("shift")), Depends(require_permissions("shift.read"))])


@router.get("/", response_model=List[ShiftRosterResponse])
async def list_rosters(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftRoster).where(ShiftRoster.tenant_id == current_user.tenant_id).order_by(ShiftRoster.name)
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=ShiftRosterResponse, status_code=201)
async def create_roster(data: ShiftRosterCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    roster = ShiftRoster(tenant_id=current_user.tenant_id, name=data.name, description=data.description, rotation_pattern=data.rotation_pattern, weekly_off_1=data.weekly_off_1, weekly_off_2=data.weekly_off_2, weekly_off_2_week=data.weekly_off_2_week)
    db.add(roster)
    await db.flush()
    for entry in data.entries:
        db.add(ShiftRosterEntry(tenant_id=current_user.tenant_id, roster_id=roster.id, day_number=entry['day_number'], shift_id=entry.get('shift_id')))
    await db.commit()
    await db.refresh(roster)
    return roster


@router.put("/{roster_id}", response_model=ShiftRosterResponse)
async def update_roster(roster_id: uuid.UUID, data: ShiftRosterUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftRoster).where(ShiftRoster.id == roster_id, ShiftRoster.tenant_id == current_user.tenant_id)
    roster = (await db.execute(stmt)).scalar_one_or_none()
    if not roster:
        raise HTTPException(status_code=404, detail="Shift roster not found")
    for field, val in data.model_dump(exclude_unset=True, exclude={'entries'}).items():
        setattr(roster, field, val)
    if data.entries is not None:
        from sqlalchemy import delete as sql_del
        await db.execute(sql_del(ShiftRosterEntry).where(ShiftRosterEntry.roster_id == roster_id))
        for entry in data.entries:
            db.add(ShiftRosterEntry(tenant_id=current_user.tenant_id, roster_id=roster_id, day_number=entry['day_number'], shift_id=entry.get('shift_id')))
    await db.commit()
    await db.refresh(roster)
    return roster


@router.delete("/{roster_id}", response_model=ResponseBase)
async def delete_roster(roster_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftRoster).where(ShiftRoster.id == roster_id, ShiftRoster.tenant_id == current_user.tenant_id)
    roster = (await db.execute(stmt)).scalar_one_or_none()
    if not roster:
        raise HTTPException(status_code=404, detail="Shift roster not found")
    await db.delete(roster)
    await db.commit()
    return ResponseBase(message="Shift roster deleted")


@router.get("/{roster_id}/entries")
async def get_roster_entries(roster_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftRosterEntry).where(ShiftRosterEntry.roster_id == roster_id).order_by(ShiftRosterEntry.day_number)
    return list((await db.execute(stmt)).scalars().all())
