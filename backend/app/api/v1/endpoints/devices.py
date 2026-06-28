"""Device API endpoints."""

import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions, require_permissions
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.device import DeviceCreate, DeviceUpdate, DeviceResponse, DeviceHealthResponse, DeviceLogResponse, DeviceCommandCreate, DeviceCommandResponse
from app.services.device import DeviceService
from app.services.command import CommandService

router = APIRouter(dependencies=[Depends(require_feature("device")), Depends(require_permissions("device.read"))])


@router.get("/health", response_model=DeviceHealthResponse)
async def device_health(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    return await service.get_device_health_summary(current_user.tenant_id)


@router.get("/", response_model=PaginatedResponse[DeviceResponse])
async def list_devices(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    branch_id: uuid.UUID = Query(None),
    status: str = Query(None),
    search: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    items, total = await service.list_devices(
        current_user.tenant_id, page=page, page_size=page_size,
        branch_id=branch_id, status=status, search=search,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=DeviceResponse, status_code=201)
async def create_device(
    data: DeviceCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    return await service.create_device(current_user.tenant_id, data)


@router.get("/{device_id}", response_model=DeviceResponse)
async def get_device(
    device_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    device = await service.get_device(device_id, current_user.tenant_id)
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")
    return device


@router.put("/{device_id}", response_model=DeviceResponse)
async def update_device(
    device_id: uuid.UUID,
    data: DeviceUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    return await service.update_device(device_id, current_user.tenant_id, data)


@router.delete("/{device_id}", response_model=ResponseBase)
async def delete_device(
    device_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    await service.delete_device(device_id, current_user.tenant_id)
    return ResponseBase(message="Device deleted")


@router.get("/{device_id}/logs", response_model=PaginatedResponse[DeviceLogResponse])
async def get_device_logs(
    device_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DeviceService(db)
    items, total = await service.get_device_logs(device_id, current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/{device_id}/sync", response_model=ResponseBase)
async def sync_device(
    device_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    from app.tasks.sync_tasks import sync_all_tenants_devices
    sync_all_tenants_devices.delay()
    return ResponseBase(message="Device sync triggered")


@router.get("/{device_id}/live-status")
async def get_device_live_status(
    device_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    from sqlalchemy import select
    from app.models.device import Device
    from app.models.essl_mapping import EsslDeviceMapping
    from app.models.essl_server import EsslServer
    from app.core.encryption import decrypt_value
    from app.services.essl_soap import ESSLSoapService
    from app.services.essl_client import ESSLClient

    stmt = select(Device).where(Device.id == device_id, Device.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    device = result.scalar_one_or_none()
    if not device:
        raise HTTPException(status_code=404, detail="Device not found")

    mapping_stmt = select(EsslDeviceMapping).where(EsslDeviceMapping.device_id == device_id)
    mapping_result = await db.execute(mapping_stmt)
    mapping = mapping_result.scalar_one_or_none()

    if not mapping:
        raise HTTPException(status_code=404, detail="Device not linked to any eSSL server")

    server_stmt = select(EsslServer).where(EsslServer.id == mapping.essl_server_id)
    server_result = await db.execute(server_stmt)
    server = server_result.scalar_one_or_none()

    if not server:
        raise HTTPException(status_code=404, detail="eSSL server not found")

    password = decrypt_value(server.password_encrypted)
    soap = ESSLSoapService(server_url=server.server_url, username=server.username, password=password, timeout=server.timeout_seconds)
    client = ESSLClient(soap)

    ping_result = await client.get_device_last_ping(mapping.serial_number)
    is_online = False
    last_ping = None

    if ping_result.get("success"):
        ping_data = ping_result.get("data", {})
        last_ping_str = ping_data.get("last_ping") if isinstance(ping_data, dict) else None
        if last_ping_str:
            from app.services.essl_connector import EsslConnectorService
            last_ping = EsslConnectorService._parse_datetime(str(last_ping_str), server.timezone)
            if last_ping:
                from datetime import datetime, timezone
                is_online = (datetime.now(timezone.utc) - last_ping).total_seconds() < 300

    return {
        "device_id": str(device_id),
        "serial_number": device.serial_number,
        "is_online": is_online,
        "last_ping": last_ping.isoformat() if last_ping else None,
        "status": "online" if is_online else "offline",
    }
