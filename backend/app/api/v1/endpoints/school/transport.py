"""Transport management endpoints."""

import uuid
from typing import Optional, List
from datetime import time

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.transport_service import TransportService

router = APIRouter(dependencies=[Depends(require_feature("school_transport")), Depends(require_permissions("transport.manage"))])


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
    svc = TransportService(db)
    return await svc.list_routes(tenant_id=current_user.tenant_id)


@router.post("/routes")
async def create_route(
    data: RouteCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TransportService(db)
    route = await svc.create_route(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(route.id)}


@router.get("/routes/{route_id}/stops")
async def list_stops(
    route_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TransportService(db)
    return await svc.list_stops(route_id=route_id, tenant_id=current_user.tenant_id)


@router.post("/routes/{route_id}/stops")
async def create_stop(
    route_id: uuid.UUID,
    data: StopCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TransportService(db)
    stop = await svc.create_stop(route_id=route_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(stop.id)}


@router.post("/students/assign")
async def assign_student(
    data: StudentTransportAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TransportService(db)
    assignment = await svc.assign_student(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(assignment.id)}


@router.get("/students/{student_id}")
async def get_student_transport(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TransportService(db)
    return await svc.get_student_transport(student_id=student_id, tenant_id=current_user.tenant_id)
