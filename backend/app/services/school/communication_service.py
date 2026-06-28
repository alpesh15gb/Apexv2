import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.communication import SchoolEvent, Circular


class CommunicationService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_circulars(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(Circular).where(
            Circular.tenant_id == tenant_id, Circular.is_active == True
        ).order_by(Circular.created_at.desc())
        result = await self.db.execute(stmt)
        circulars = result.scalars().all()
        return [
            {
                "id": str(c.id), "title": c.title, "content": c.content,
                "circular_type": c.circular_type,
                "published_at": c.published_at.isoformat() if c.published_at else None,
            }
            for c in circulars
        ]

    async def create_circular(
        self, tenant_id: uuid.UUID, published_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> Circular:
        if not isinstance(data, dict):
            data = data.model_dump()
        circular = Circular(
            tenant_id=tenant_id,
            published_by=published_by,
            published_at=datetime.now(timezone.utc),
            **data,
        )
        self.db.add(circular)
        await self.db.commit()
        await self.db.refresh(circular)
        return circular

    async def list_events(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(SchoolEvent).where(SchoolEvent.tenant_id == tenant_id).order_by(SchoolEvent.start_date.desc())
        result = await self.db.execute(stmt)
        events = result.scalars().all()
        return [
            {
                "id": str(e.id), "title": e.title, "event_type": e.event_type,
                "start_date": e.start_date.isoformat(),
                "end_date": e.end_date.isoformat() if e.end_date else None,
                "venue": e.venue,
            }
            for e in events
        ]

    async def create_event(
        self, tenant_id: uuid.UUID, organizer_id: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> SchoolEvent:
        if not isinstance(data, dict):
            data = data.model_dump()
        event = SchoolEvent(
            tenant_id=tenant_id,
            organizer_id=organizer_id,
            **data,
        )
        self.db.add(event)
        await self.db.commit()
        await self.db.refresh(event)
        return event
