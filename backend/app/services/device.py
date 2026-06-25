import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.device import Device, DeviceLog, DeviceStatus
from app.schemas.device import DeviceHealthResponse

class DeviceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_device(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Device:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        serial_number = data.get("serial_number")
        if not serial_number:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="serial_number is required")

        # Check unique constraint
        stmt = select(Device).where(Device.tenant_id == tenant_id, Device.serial_number == serial_number)
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Device with this serial number already exists in this tenant"
            )

        if "status" not in data:
            data["status"] = DeviceStatus.OFFLINE.value

        device = Device(tenant_id=tenant_id, **data)
        self.db.add(device)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def get_device(self, device_id: uuid.UUID, tenant_id: uuid.UUID) -> Device:
        stmt = select(Device).where(Device.id == device_id, Device.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        device = res.scalar_one_or_none()
        if not device:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")
        return device

    async def update_device(self, device_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Device:
        device = await self.get_device(device_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        serial_number = data.get("serial_number")
        if serial_number and serial_number != device.serial_number:
            stmt = select(Device).where(Device.tenant_id == tenant_id, Device.serial_number == serial_number)
            if (await self.db.execute(stmt)).scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Device with this serial number already exists in this tenant"
                )

        for field, val in data.items():
            if hasattr(device, field):
                setattr(device, field, val)

        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def delete_device(self, device_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        device = await self.get_device(device_id, tenant_id)
        await self.db.delete(device)
        await self.db.commit()

    async def list_devices(
        self,
        tenant_id: uuid.UUID,
        branch_id: Optional[uuid.UUID] = None,
        status: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Device], int]:
        count_stmt = select(func.count(Device.id)).where(Device.tenant_id == tenant_id)
        stmt = select(Device).where(Device.tenant_id == tenant_id)

        if branch_id:
            count_stmt = count_stmt.where(Device.branch_id == branch_id)
            stmt = stmt.where(Device.branch_id == branch_id)
        if status:
            count_stmt = count_stmt.where(Device.status == status)
            stmt = stmt.where(Device.status == status)
        if search:
            search_filter = or_(
                Device.serial_number.ilike(f"%{search}%"),
                Device.device_name.ilike(f"%{search}%"),
                Device.model.ilike(f"%{search}%")
            )
            count_stmt = count_stmt.where(search_filter)
            stmt = stmt.where(search_filter)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        devices = list(res.scalars().all())
        return devices, total

    async def update_device_status(
        self,
        device_id: uuid.UUID,
        tenant_id: uuid.UUID,
        status_val: str,
        last_ping: Optional[datetime] = None
    ) -> Device:
        device = await self.get_device(device_id, tenant_id)
        device.status = status_val
        if last_ping:
            device.last_ping = last_ping
        else:
            device.last_ping = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(device)
        return device

    async def get_device_health_summary(self, tenant_id: uuid.UUID) -> DeviceHealthResponse:
        stmt = select(Device.status, func.count(Device.id)).where(Device.tenant_id == tenant_id).group_by(Device.status)
        res = await self.db.execute(stmt)
        status_counts = dict(res.all())

        online = status_counts.get(DeviceStatus.ONLINE.value, 0)
        offline = status_counts.get(DeviceStatus.OFFLINE.value, 0)
        inactive = status_counts.get(DeviceStatus.INACTIVE.value, 0)
        error = status_counts.get(DeviceStatus.ERROR.value, 0)
        total = online + offline + inactive + error

        return DeviceHealthResponse(
            total_devices=total,
            online=online,
            offline=offline,
            inactive=inactive,
            error=error
        )

    async def get_device_logs(
        self,
        device_id: uuid.UUID,
        tenant_id: uuid.UUID,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[DeviceLog], int]:
        # verify device exists
        await self.get_device(device_id, tenant_id)

        count_stmt = select(func.count(DeviceLog.id)).where(
            DeviceLog.device_id == device_id,
            DeviceLog.tenant_id == tenant_id
        )
        stmt = select(DeviceLog).where(
            DeviceLog.device_id == device_id,
            DeviceLog.tenant_id == tenant_id
        ).order_by(DeviceLog.created_at.desc()).offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        logs = list(res.scalars().all())
        return logs, total
