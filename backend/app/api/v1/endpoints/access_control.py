"""Access Control API endpoints."""

import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_permissions, require_feature
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.access_control import (
    AccessZoneCreate, AccessZoneResponse,
    DoorCreate, DoorResponse,
    UserAccessLevelCreate, UserAccessLevelResponse,
    AccessLogResponse,
)
from app.services.access_control import AccessControlService

router = APIRouter(dependencies=[Depends(require_feature("access_control")), Depends(require_permissions("access_control.read"))])


# ── Zones ────────────────────────────────────────────
@router.get("/zones", response_model=PaginatedResponse[AccessZoneResponse])
async def list_zones(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    items, total = await service.list_access_zones(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/zones", response_model=AccessZoneResponse, status_code=201)
async def create_zone(
    data: AccessZoneCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    return await service.create_access_zone(current_user.tenant_id, data)


# ── Doors ────────────────────────────────────────────
@router.get("/doors", response_model=PaginatedResponse[DoorResponse])
async def list_doors(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    zone_id: uuid.UUID = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    items, total = await service.list_doors(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/doors", response_model=DoorResponse, status_code=201)
async def create_door(
    data: DoorCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    return await service.create_door(current_user.tenant_id, data)


# ── Access Grants ────────────────────────────────────
@router.post("/grant", response_model=UserAccessLevelResponse, status_code=201)
async def grant_access(
    data: UserAccessLevelCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    return await service.grant_access(
        current_user.tenant_id, data.employee_id, data.zone_id,
        data.access_level, current_user.id, data.valid_from, data.valid_to,
    )


@router.delete("/grant/{access_level_id}", response_model=ResponseBase)
async def revoke_access(
    access_level_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    await service.revoke_access(access_level_id, current_user.tenant_id)
    return ResponseBase(message="Access revoked")


@router.get("/check")
async def check_access(
    employee_id: uuid.UUID = Query(...),
    door_id: uuid.UUID = Query(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    granted, reason = await service.check_access(current_user.tenant_id, employee_id, door_id)
    return {"granted": granted, "reason": reason}


# ── Access Logs ──────────────────────────────────────
@router.get("/logs", response_model=PaginatedResponse[AccessLogResponse])
async def list_access_logs(
    from_date: date = Query(None),
    to_date: date = Query(None),
    employee_id: uuid.UUID = Query(None),
    door_id: uuid.UUID = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = AccessControlService(db)
    items, total = await service.list_access_logs(
        current_user.tenant_id, from_date=from_date, to_date=to_date,
        employee_id=employee_id, door_id=door_id,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)
