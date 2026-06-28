"""Shift API endpoints."""

import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.shift import ShiftCreate, ShiftUpdate, ShiftResponse, ShiftScheduleCreate, ShiftScheduleResponse
from app.services.shift import ShiftService

router = APIRouter(dependencies=[Depends(require_feature("shift")), Depends(require_permissions("shift.read"))])


@router.get("/", response_model=PaginatedResponse[ShiftResponse])
async def list_shifts(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ShiftService(db)
    items, total = await service.list_shifts(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=ShiftResponse, status_code=201)
async def create_shift(
    data: ShiftCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("shift.manage")),
):
    service = ShiftService(db)
    return await service.create_shift(current_user.tenant_id, data)


@router.get("/{shift_id}", response_model=ShiftResponse)
async def get_shift(
    shift_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ShiftService(db)
    shift = await service.get_shift(shift_id, current_user.tenant_id)
    if not shift:
        raise HTTPException(status_code=404, detail="Shift not found")
    return shift


@router.put("/{shift_id}", response_model=ShiftResponse)
async def update_shift(
    shift_id: uuid.UUID,
    data: ShiftUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("shift.manage")),
):
    service = ShiftService(db)
    return await service.update_shift(shift_id, current_user.tenant_id, data)


@router.delete("/{shift_id}", response_model=ResponseBase)
async def delete_shift(
    shift_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("shift.manage")),
):
    service = ShiftService(db)
    await service.delete_shift(shift_id, current_user.tenant_id)
    return ResponseBase(message="Shift deleted")


@router.post("/assign", response_model=ShiftScheduleResponse, status_code=201)
async def assign_shift(
    data: ShiftScheduleCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("shift.manage")),
):
    service = ShiftService(db)
    return await service.assign_shift(current_user.tenant_id, data)


@router.get("/schedules/", response_model=PaginatedResponse[ShiftScheduleResponse])
async def list_schedules(
    employee_id: uuid.UUID = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ShiftService(db)
    items, total = await service.list_shift_schedules(current_user.tenant_id, employee_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)
