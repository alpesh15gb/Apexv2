"""Communication endpoints - Circulars and Events."""

import uuid
from typing import Optional, List
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.communication_service import CommunicationService

router = APIRouter(dependencies=[Depends(require_permissions("circular.publish"))])


class CircularCreate(BaseModel):
    title: str = Field(..., max_length=255)
    content: str
    circular_type: str = "general"
    target_audience: List[str] = []
    attachment_urls: List[str] = []


class EventCreate(BaseModel):
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    event_type: str = "general"
    start_date: datetime
    end_date: Optional[datetime] = None
    venue: Optional[str] = None
    is_public: bool = False


# ── Circulars ────────────────────────────────────────

circular_router = APIRouter(dependencies=[Depends(require_feature("school_circulars")), Depends(require_permissions("circular.publish"))])


@circular_router.get("/")
async def list_circulars(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CommunicationService(db)
    return await svc.list_circulars(tenant_id=current_user.tenant_id)


@circular_router.post("/")
async def create_circular(
    data: CircularCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CommunicationService(db)
    circular = await svc.create_circular(
        tenant_id=current_user.tenant_id,
        published_by=current_user.id,
        data=data,
    )
    return {"id": str(circular.id)}


# ── Events ───────────────────────────────────────────

event_router = APIRouter(dependencies=[Depends(require_feature("school_events")), Depends(require_permissions("event.manage"))])


@event_router.get("/")
async def list_events(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CommunicationService(db)
    return await svc.list_events(tenant_id=current_user.tenant_id)


@event_router.post("/")
async def create_event(
    data: EventCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = CommunicationService(db)
    event = await svc.create_event(
        tenant_id=current_user.tenant_id,
        organizer_id=current_user.id,
        data=data,
    )
    return {"id": str(event.id)}
