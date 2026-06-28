import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.hostel import Hostel, HostelRoom, HostelAllocation
from app.models.school.student import Student


class HostelService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_hostels(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(Hostel).where(Hostel.tenant_id == tenant_id, Hostel.is_active == True)
        result = await self.db.execute(stmt)
        hostels = result.scalars().all()
        return [
            {"id": str(h.id), "name": h.name, "hostel_type": h.hostel_type, "capacity": h.capacity}
            for h in hostels
        ]

    async def create_hostel(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Hostel:
        if not isinstance(data, dict):
            data = data.model_dump()
        hostel = Hostel(tenant_id=tenant_id, **data)
        self.db.add(hostel)
        await self.db.commit()
        await self.db.refresh(hostel)
        return hostel

    async def list_rooms(self, hostel_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(HostelRoom).where(
            HostelRoom.hostel_id == hostel_id, HostelRoom.tenant_id == tenant_id, HostelRoom.is_active == True
        )
        result = await self.db.execute(stmt)
        rooms = result.scalars().all()
        return [
            {
                "id": str(r.id), "room_number": r.room_number, "floor": r.floor,
                "room_type": r.room_type, "capacity": r.capacity,
            }
            for r in rooms
        ]

    async def create_room(self, hostel_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> HostelRoom:
        if not isinstance(data, dict):
            data = data.model_dump()
        room = HostelRoom(tenant_id=tenant_id, hostel_id=hostel_id, **data)
        self.db.add(room)
        await self.db.commit()
        await self.db.refresh(room)
        return room

    async def allocate_student(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> HostelAllocation:
        if not isinstance(data, dict):
            data = data.model_dump()
        allocation = HostelAllocation(tenant_id=tenant_id, status="active", **data)
        self.db.add(allocation)
        student_result = await self.db.execute(
            select(Student).where(Student.id == data["student_id"], Student.tenant_id == tenant_id)
        )
        student = student_result.scalar_one_or_none()
        if student:
            student.hostel_room_id = data["room_id"]
        await self.db.commit()
        await self.db.refresh(allocation)
        return allocation

    async def list_allocations(
        self, tenant_id: uuid.UUID, hostel_id: Optional[uuid.UUID] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(HostelAllocation, Student).join(Student, Student.id == HostelAllocation.student_id).where(
            HostelAllocation.tenant_id == tenant_id, HostelAllocation.status == "active"
        )
        if hostel_id:
            stmt = stmt.where(HostelAllocation.hostel_id == hostel_id)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(a.id), "student_name": f"{s.first_name} {s.last_name}",
                "hostel_id": str(a.hostel_id), "room_id": str(a.room_id), "bed_number": a.bed_number,
            }
            for a, s in rows
        ]
