"""Shift Group CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_feature
from app.models.user import User
from app.models.shift_group import ShiftGroup, ShiftGroupMember
from app.schemas.common import ResponseBase
from app.schemas.shift_group import ShiftGroupCreate, ShiftGroupUpdate, ShiftGroupResponse

router = APIRouter(dependencies=[Depends(require_feature("shift")), Depends(require_permissions("shift.read"))])


@router.get("/", response_model=List[ShiftGroupResponse])
async def list_groups(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftGroup).where(ShiftGroup.tenant_id == current_user.tenant_id).order_by(ShiftGroup.name)
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=ShiftGroupResponse, status_code=201)
async def create_group(data: ShiftGroupCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    group = ShiftGroup(tenant_id=current_user.tenant_id, name=data.name, description=data.description)
    db.add(group)
    await db.flush()
    for sid in data.shift_ids:
        db.add(ShiftGroupMember(tenant_id=current_user.tenant_id, group_id=group.id, shift_id=sid))
    await db.commit()
    await db.refresh(group)
    return group


@router.put("/{group_id}", response_model=ShiftGroupResponse)
async def update_group(group_id: uuid.UUID, data: ShiftGroupUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftGroup).where(ShiftGroup.id == group_id, ShiftGroup.tenant_id == current_user.tenant_id)
    group = (await db.execute(stmt)).scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Shift group not found")
    for field, val in data.model_dump(exclude_unset=True, exclude={'shift_ids'}).items():
        setattr(group, field, val)
    if data.shift_ids is not None:
        from sqlalchemy import delete as sql_del
        await db.execute(sql_del(ShiftGroupMember).where(ShiftGroupMember.group_id == group_id, ShiftGroupMember.tenant_id == current_user.tenant_id))
        for sid in data.shift_ids:
            db.add(ShiftGroupMember(tenant_id=current_user.tenant_id, group_id=group_id, shift_id=sid))
    await db.commit()
    await db.refresh(group)
    return group


@router.delete("/{group_id}", response_model=ResponseBase)
async def delete_group(group_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ShiftGroup).where(ShiftGroup.id == group_id, ShiftGroup.tenant_id == current_user.tenant_id)
    group = (await db.execute(stmt)).scalar_one_or_none()
    if not group:
        raise HTTPException(status_code=404, detail="Shift group not found")
    await db.delete(group)
    await db.commit()
    return ResponseBase(message="Shift group deleted")


@router.get("/{group_id}/shifts")
async def get_group_shifts(group_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    from app.models.shift import Shift
    stmt = select(Shift).join(ShiftGroupMember, ShiftGroupMember.shift_id == Shift.id).where(ShiftGroupMember.group_id == group_id, ShiftGroupMember.tenant_id == current_user.tenant_id)
    return list((await db.execute(stmt)).scalars().all())
