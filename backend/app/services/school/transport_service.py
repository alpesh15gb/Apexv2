import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import time

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.transport import TransportRoute, TransportStop, StudentTransport
from app.models.school.student import Student


class TransportService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_routes(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(TransportRoute).where(TransportRoute.tenant_id == tenant_id, TransportRoute.is_active == True)
        result = await self.db.execute(stmt)
        routes = result.scalars().all()
        return [
            {
                "id": str(r.id), "name": r.name, "code": r.code, "vehicle_number": r.vehicle_number,
                "vehicle_type": r.vehicle_type, "capacity": r.capacity,
            }
            for r in routes
        ]

    async def create_route(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> TransportRoute:
        if not isinstance(data, dict):
            data = data.model_dump()
        route = TransportRoute(tenant_id=tenant_id, **data)
        self.db.add(route)
        await self.db.commit()
        await self.db.refresh(route)
        return route

    async def list_stops(self, route_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(TransportStop).where(
            TransportStop.route_id == route_id, TransportStop.tenant_id == tenant_id
        ).order_by(TransportStop.sequence)
        result = await self.db.execute(stmt)
        stops = result.scalars().all()
        return [
            {
                "id": str(s.id), "name": s.name, "sequence": s.sequence,
                "pickup_time": str(s.pickup_time) if s.pickup_time else None,
                "drop_time": str(s.drop_time) if s.drop_time else None,
            }
            for s in stops
        ]

    async def create_stop(self, route_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> TransportStop:
        if not isinstance(data, dict):
            data = data.model_dump()
        stop = TransportStop(
            tenant_id=tenant_id,
            route_id=route_id,
            name=data["name"],
            sequence=data["sequence"],
            pickup_time=time.fromisoformat(data["pickup_time"]) if data.get("pickup_time") else None,
            drop_time=time.fromisoformat(data["drop_time"]) if data.get("drop_time") else None,
        )
        self.db.add(stop)
        await self.db.commit()
        await self.db.refresh(stop)
        return stop

    async def assign_student(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> StudentTransport:
        if not isinstance(data, dict):
            data = data.model_dump()
        assignment = StudentTransport(tenant_id=tenant_id, **data)
        self.db.add(assignment)
        student_result = await self.db.execute(
            select(Student).where(Student.id == data["student_id"], Student.tenant_id == tenant_id)
        )
        student = student_result.scalar_one_or_none()
        if student:
            student.transport_route_id = data["route_id"]
        await self.db.commit()
        await self.db.refresh(assignment)
        return assignment

    async def get_student_transport(self, student_id: uuid.UUID, tenant_id: uuid.UUID) -> Optional[Dict[str, Any]]:
        stmt = select(StudentTransport, TransportRoute, TransportStop).join(
            TransportRoute, TransportRoute.id == StudentTransport.route_id
        ).outerjoin(
            TransportStop, TransportStop.id == StudentTransport.stop_id
        ).where(
            StudentTransport.student_id == student_id,
            StudentTransport.tenant_id == tenant_id,
            StudentTransport.is_active == True,
        )
        result = await self.db.execute(stmt)
        row = result.first()
        if not row:
            return None
        st, route, stop = row
        return {
            "id": str(st.id), "route_name": route.name, "vehicle_number": route.vehicle_number,
            "stop_name": stop.name if stop else None,
            "pickup_time": str(stop.pickup_time) if stop and stop.pickup_time else None,
            "fee_amount": float(st.fee_amount), "pickup_type": st.pickup_type,
        }
