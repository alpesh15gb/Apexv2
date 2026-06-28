"""Notification Center API endpoints."""

import uuid
from datetime import datetime, timezone
from typing import Optional, List

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.notification import Notification

router = APIRouter(dependencies=[Depends(require_permissions("notification.read"))])


@router.get("/")
async def list_notifications(
    is_read: Optional[bool] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Notification).where(
        Notification.tenant_id == current_user.tenant_id,
        Notification.user_id == current_user.id,
    )
    if is_read is not None:
        if is_read:
            stmt = stmt.where(Notification.status == "read")
        else:
            stmt = stmt.where(Notification.status != "read")

    count_stmt = select(func.count(Notification.id)).where(
        Notification.tenant_id == current_user.tenant_id,
        Notification.user_id == current_user.id,
    )
    if is_read is not None:
        if is_read:
            count_stmt = count_stmt.where(Notification.status == "read")
        else:
            count_stmt = count_stmt.where(Notification.status != "read")

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(Notification.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    return {
        "items": [
            {
                "id": str(n.id),
                "title": n.title,
                "message": n.message,
                "type": n.notification_type if hasattr(n, 'notification_type') else 'info',
                "is_read": n.status == "read",
                "created_at": n.created_at.isoformat() if n.created_at else None,
            }
            for n in items
        ],
        "total": total,
        "unread": (await db.execute(
            select(func.count(Notification.id)).where(
                Notification.tenant_id == current_user.tenant_id,
                Notification.user_id == current_user.id,
                Notification.status != "read",
            )
        )).scalar() or 0,
    }


@router.put("/{notification_id}/read")
async def mark_read(
    notification_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    notification = await db.get(Notification, notification_id)
    if not notification or notification.user_id != current_user.id:
        raise HTTPException(status_code=404, detail="Notification not found")
    notification.status = "read"
    notification.read_at = datetime.now(timezone.utc)
    await db.commit()
    return {"id": str(notification.id), "is_read": True}


@router.post("/read-all")
async def mark_all_read(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await db.execute(
        update(Notification)
        .where(
            Notification.tenant_id == current_user.tenant_id,
            Notification.user_id == current_user.id,
            Notification.status != "read",
        )
        .values(status="read")
    )
    await db.commit()
    return {"message": "All notifications marked as read"}


@router.get("/unread-count")
async def unread_count(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count = (await db.execute(
        select(func.count(Notification.id)).where(
            Notification.tenant_id == current_user.tenant_id,
            Notification.user_id == current_user.id,
            Notification.status != "read",
        )
    )).scalar() or 0
    return {"count": count}
