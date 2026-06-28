"""Communication endpoints - Circulars and Events."""

import uuid
from typing import Optional, List
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.communication import SchoolEvent, Circular

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
    stmt = select(Circular).where(Circular.tenant_id == current_user.tenant_id, Circular.is_active == True).order_by(Circular.created_at.desc())
    result = await db.execute(stmt)
    circulars = result.scalars().all()
    return [
        {"id": str(c.id), "title": c.title, "content": c.content, "circular_type": c.circular_type, "published_at": c.published_at.isoformat() if c.published_at else None}
        for c in circulars
    ]


@circular_router.post("/")
async def create_circular(
    data: CircularCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    from datetime import timezone
    circular = Circular(
        tenant_id=current_user.tenant_id,
        published_by=current_user.id,
        published_at=datetime.now(timezone.utc),
        **data.model_dump(),
    )
    db.add(circular)
    await db.commit()
    return {"id": str(circular.id)}


# ── Events ───────────────────────────────────────────

event_router = APIRouter(dependencies=[Depends(require_feature("school_events")), Depends(require_permissions("event.manage"))])


@event_router.get("/")
async def list_events(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(SchoolEvent).where(SchoolEvent.tenant_id == current_user.tenant_id).order_by(SchoolEvent.start_date.desc())
    result = await db.execute(stmt)
    events = result.scalars().all()
    return [
        {"id": str(e.id), "title": e.title, "event_type": e.event_type, "start_date": e.start_date.isoformat(), "end_date": e.end_date.isoformat() if e.end_date else None, "venue": e.venue}
        for e in events
    ]


@event_router.post("/")
async def create_event(
    data: EventCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    event = SchoolEvent(
        tenant_id=current_user.tenant_id,
        organizer_id=current_user.id,
        **data.model_dump(),
    )
    db.add(event)
    await db.commit()
    return {"id": str(event.id)}
