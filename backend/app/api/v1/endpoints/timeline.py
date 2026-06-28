"""Employee Timeline CRUD endpoints."""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.timeline import EmployeeEvent
from app.schemas.common import ResponseBase
from app.schemas.timeline import EmployeeEventCreate, EmployeeEventResponse

router = APIRouter(dependencies=[Depends(require_permissions("employee.read"))])


@router.get("/", response_model=List[EmployeeEventResponse])
async def list_events(
    employee_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(EmployeeEvent).where(
        EmployeeEvent.tenant_id == current_user.tenant_id,
        EmployeeEvent.employee_id == employee_id,
    ).order_by(EmployeeEvent.event_date.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=EmployeeEventResponse, status_code=201)
async def create_event(data: EmployeeEventCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    event = EmployeeEvent(tenant_id=current_user.tenant_id, created_by=current_user.id, **data.model_dump())
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event


@router.delete("/{event_id}", response_model=ResponseBase)
async def delete_event(event_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(EmployeeEvent).where(EmployeeEvent.id == event_id, EmployeeEvent.tenant_id == current_user.tenant_id)
    event = (await db.execute(stmt)).scalar_one_or_none()
    if not event:
        raise HTTPException(status_code=404, detail="Event not found")
    await db.delete(event)
    await db.commit()
    return ResponseBase(message="Event deleted")
