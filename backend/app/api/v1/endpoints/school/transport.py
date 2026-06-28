"""Transport management endpoints."""

import uuid
from typing import Optional, List
from datetime import time

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.transport import TransportRoute, TransportStop, StudentTransport
from app.models.school.student import Student

router = APIRouter(dependencies=[Depends(require_feature("school_transport"))])


class RouteCreate(BaseModel):
    name: str = Field(..., max_length=255)
    code: Optional[str] = None
    vehicle_number: Optional[str] = None
    vehicle_type: Optional[str] = None
    capacity: int = 40
    driver_id: Optional[uuid.UUID] = None


class StopCreate(BaseModel):
    name: str = Field(..., max_length=255)
    sequence: int
    pickup_time: Optional[str] = None
    drop_time: Optional[str] = None


class StudentTransportAssign(BaseModel):
    student_id: uuid.UUID
    route_id: uuid.UUID
    stop_id: uuid.UUID
    academic_year_id: uuid.UUID
    pickup_type: str = "both"
    fee_amount: float = 0


@router.get("/routes")
async def list_routes(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TransportRoute).where(TransportRoute.tenant_id == current_user.tenant_id, TransportRoute.is_active == True)
    result = await db.execute(stmt)
    routes = result.scalars().all()
    return [{"id": str(r.id), "name": r.name, "code": r.code, "vehicle_number": r.vehicle_number, "vehicle_type": r.vehicle_type, "capacity": r.capacity} for r in routes]


@router.post("/routes")
async def create_route(
    data: RouteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    route = TransportRoute(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(route)
    await db.commit()
    return {"id": str(route.id)}


@router.get("/routes/{route_id}/stops")
async def list_stops(
    route_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TransportStop).where(TransportStop.route_id == route_id, TransportStop.tenant_id == current_user.tenant_id).order_by(TransportStop.sequence)
    result = await db.execute(stmt)
    stops = result.scalars().all()
    return [{"id": str(s.id), "name": s.name, "sequence": s.sequence, "pickup_time": str(s.pickup_time) if s.pickup_time else None, "drop_time": str(s.drop_time) if s.drop_time else None} for s in stops]


@router.post("/routes/{route_id}/stops")
async def create_stop(
    route_id: uuid.UUID,
    data: StopCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stop = TransportStop(
        tenant_id=current_user.tenant_id,
        route_id=route_id,
        name=data.name,
        sequence=data.sequence,
        pickup_time=time.fromisoformat(data.pickup_time) if data.pickup_time else None,
        drop_time=time.fromisoformat(data.drop_time) if data.drop_time else None,
    )
    db.add(stop)
    await db.commit()
    return {"id": str(stop.id)}


@router.post("/students/assign")
async def assign_student(
    data: StudentTransportAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    assignment = StudentTransport(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(assignment)
    student = await db.get(Student, data.student_id)
    if student:
        student.transport_route_id = data.route_id
    await db.commit()
    return {"id": str(assignment.id)}


@router.get("/students/{student_id}")
async def get_student_transport(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(StudentTransport, TransportRoute, TransportStop).join(
        TransportRoute, TransportRoute.id == StudentTransport.route_id
    ).outerjoin(
        TransportStop, TransportStop.id == StudentTransport.stop_id
    ).where(
        StudentTransport.student_id == student_id, StudentTransport.tenant_id == current_user.tenant_id, StudentTransport.is_active == True
    )
    result = await db.execute(stmt)
    row = result.first()
    if not row:
        return None
    st, route, stop = row
    return {
        "id": str(st.id), "route_name": route.name, "vehicle_number": route.vehicle_number,
        "stop_name": stop.name if stop else None, "pickup_time": str(stop.pickup_time) if stop and stop.pickup_time else None,
        "fee_amount": float(st.fee_amount), "pickup_type": st.pickup_type,
    }
