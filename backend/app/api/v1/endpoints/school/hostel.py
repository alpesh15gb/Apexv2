"""Hostel management endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.hostel import Hostel, HostelRoom, HostelAllocation
from app.models.school.student import Student

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
    stmt = select(Hostel).where(Hostel.tenant_id == current_user.tenant_id, Hostel.is_active == True)
    result = await db.execute(stmt)
    hostels = result.scalars().all()
    return [{"id": str(h.id), "name": h.name, "hostel_type": h.hostel_type, "capacity": h.capacity} for h in hostels]


@router.post("/")
async def create_hostel(
    data: HostelCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    hostel = Hostel(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(hostel)
    await db.commit()
    return {"id": str(hostel.id)}


@router.get("/{hostel_id}/rooms")
async def list_rooms(
    hostel_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(HostelRoom).where(HostelRoom.hostel_id == hostel_id, HostelRoom.tenant_id == current_user.tenant_id, HostelRoom.is_active == True)
    result = await db.execute(stmt)
    rooms = result.scalars().all()
    return [{"id": str(r.id), "room_number": r.room_number, "floor": r.floor, "room_type": r.room_type, "capacity": r.capacity} for r in rooms]


@router.post("/{hostel_id}/rooms")
async def create_room(
    hostel_id: uuid.UUID,
    data: RoomCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    room = HostelRoom(tenant_id=current_user.tenant_id, hostel_id=hostel_id, **data.model_dump())
    db.add(room)
    await db.commit()
    return {"id": str(room.id)}


@router.post("/allocations")
async def allocate_student(
    data: AllocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    allocation = HostelAllocation(tenant_id=current_user.tenant_id, status="active", **data.model_dump())
    db.add(allocation)
    student = await db.get(Student, data.student_id)
    if student:
        student.hostel_room_id = data.room_id
    await db.commit()
    return {"id": str(allocation.id)}


@router.get("/allocations")
async def list_allocations(
    hostel_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(HostelAllocation, Student).join(Student, Student.id == HostelAllocation.student_id).where(
        HostelAllocation.tenant_id == current_user.tenant_id, HostelAllocation.status == "active"
    )
    if hostel_id:
        stmt = stmt.where(HostelAllocation.hostel_id == hostel_id)
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {"id": str(a.id), "student_name": f"{s.first_name} {s.last_name}", "hostel_id": str(a.hostel_id), "room_id": str(a.room_id), "bed_number": a.bed_number}
        for a, s in rows
    ]
