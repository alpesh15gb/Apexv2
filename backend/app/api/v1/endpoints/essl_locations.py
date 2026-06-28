"""eSSL Location CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_permissions, require_feature
from app.models.user import User
from app.models.essl_server import EsslServer
from app.models.essl_location import EsslLocation
from app.schemas.common import ResponseBase
from app.schemas.essl import EsslLocationCreate, EsslLocationUpdate, EsslLocationResponse

router = APIRouter(dependencies=[Depends(require_feature("biometric")), Depends(require_permissions("biometric.read"))])


async def _get_server(db: AsyncSession, server_id: uuid.UUID, tenant_id: uuid.UUID) -> EsslServer:
    stmt = select(EsslServer).where(EsslServer.id == server_id, EsslServer.tenant_id == tenant_id)
    result = await db.execute(stmt)
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="eSSL server not found")
    return server


@router.get("/{server_id}/locations", response_model=List[EsslLocationResponse])
async def list_locations(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_server(db, server_id, current_user.tenant_id)
    stmt = (
        select(EsslLocation)
        .where(EsslLocation.essl_server_id == server_id, EsslLocation.tenant_id == current_user.tenant_id)
        .order_by(EsslLocation.name)
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("/{server_id}/locations", response_model=EsslLocationResponse, status_code=201)
async def create_location(
    server_id: uuid.UUID,
    data: EsslLocationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_server(db, server_id, current_user.tenant_id)
    location = EsslLocation(
        tenant_id=current_user.tenant_id,
        essl_server_id=server_id,
        code=data.code,
        name=data.name,
        description=data.description,
        is_active=data.is_active,
    )
    db.add(location)
    await db.commit()
    await db.refresh(location)
    return location


@router.put("/{server_id}/locations/{location_id}", response_model=EsslLocationResponse)
async def update_location(
    server_id: uuid.UUID,
    location_id: uuid.UUID,
    data: EsslLocationUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_server(db, server_id, current_user.tenant_id)
    stmt = select(EsslLocation).where(
        EsslLocation.id == location_id,
        EsslLocation.essl_server_id == server_id,
        EsslLocation.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    location = result.scalar_one_or_none()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    update_data = data.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(location, field, val)

    await db.commit()
    await db.refresh(location)
    return location


@router.delete("/{server_id}/locations/{location_id}", response_model=ResponseBase)
async def delete_location(
    server_id: uuid.UUID,
    location_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    await _get_server(db, server_id, current_user.tenant_id)
    stmt = select(EsslLocation).where(
        EsslLocation.id == location_id,
        EsslLocation.essl_server_id == server_id,
        EsslLocation.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    location = result.scalar_one_or_none()
    if not location:
        raise HTTPException(status_code=404, detail="Location not found")

    await db.delete(location)
    await db.commit()
    return ResponseBase(message="Location deleted")
