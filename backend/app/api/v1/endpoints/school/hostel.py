"""Hostel management endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.hostel_service import HostelService

router = APIRouter(dependencies=[Depends(require_feature("school_hostel")), Depends(require_permissions("hostel.manage"))])


class HostelCreate(BaseModel):
    name: str = Field(..., max_length=255)
    hostel_type: str = "boys"
    warden_id: Optional[uuid.UUID] = None
    capacity: int = 100
    campus_id: Optional[uuid.UUID] = None


class RoomCreate(BaseModel):
    room_number: str = Field(..., max_length=50)
    floor: int = 0
    room_type: str = "dormitory"
    capacity: int = 4


class AllocationCreate(BaseModel):
    student_id: uuid.UUID
    hostel_id: uuid.UUID
    room_id: uuid.UUID
    bed_number: Optional[int] = None
    academic_year_id: uuid.UUID
    start_date: date


@router.get("/")
async def list_hostels(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    return await svc.list_hostels(tenant_id=current_user.tenant_id)


@router.post("/")
async def create_hostel(
    data: HostelCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    hostel = await svc.create_hostel(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(hostel.id)}


@router.get("/{hostel_id}/rooms")
async def list_rooms(
    hostel_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    return await svc.list_rooms(hostel_id=hostel_id, tenant_id=current_user.tenant_id)


@router.post("/{hostel_id}/rooms")
async def create_room(
    hostel_id: uuid.UUID,
    data: RoomCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    room = await svc.create_room(hostel_id=hostel_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(room.id)}


@router.post("/allocations")
async def allocate_student(
    data: AllocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    allocation = await svc.allocate_student(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(allocation.id)}


@router.get("/allocations")
async def list_allocations(
    hostel_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = HostelService(db)
    return await svc.list_allocations(tenant_id=current_user.tenant_id, hostel_id=hostel_id)
