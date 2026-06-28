"""Device Command API endpoints."""

import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.device import DeviceCommandCreate, DeviceCommandResponse
from app.services.command import CommandService

router = APIRouter(dependencies=[Depends(require_permissions("device.read"))])


@router.get("/", response_model=PaginatedResponse[DeviceCommandResponse])
async def list_commands(
    device_id: uuid.UUID = Query(None),
    status: str = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = CommandService(db)
    items, total = await service.list_commands(
        current_user.tenant_id, device_id=device_id, status_val=status,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=DeviceCommandResponse, status_code=201)
async def create_command(
    data: DeviceCommandCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = CommandService(db)
    return await service.create_command(
        current_user.tenant_id, data.device_id, data.command_type,
        data.parameters, current_user.id,
    )


@router.post("/{command_id}/execute", response_model=DeviceCommandResponse)
async def execute_command(
    command_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = CommandService(db)
    return await service.execute_command(command_id, current_user.tenant_id)


@router.get("/{command_id}", response_model=DeviceCommandResponse)
async def get_command(
    command_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = CommandService(db)
    cmd = await service.get_command_status(command_id, current_user.tenant_id)
    if not cmd:
        raise HTTPException(status_code=404, detail="Command not found")
    return cmd
