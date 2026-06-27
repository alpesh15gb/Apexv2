import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.command import DeviceCommand, CommandType, CommandStatus
from app.models.device import Device
from app.services.essl_soap import ESSLSoapService

class CommandService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_command(
        self,
        tenant_id: uuid.UUID,
        device_id: uuid.UUID,
        command_type: str,
        parameters: Optional[Dict[str, Any]],
        requested_by: Optional[uuid.UUID]
    ) -> DeviceCommand:
        # Check if device exists and belongs to tenant
        stmt_dev = select(Device).where(Device.id == device_id, Device.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_dev)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Device not found")

        cmd = DeviceCommand(
            tenant_id=tenant_id,
            device_id=device_id,
            command_type=command_type,
            parameters=parameters,
            status=CommandStatus.PENDING.value,
            requested_by=requested_by,
            requested_at=datetime.now(timezone.utc)
        )
        self.db.add(cmd)
        await self.db.commit()
        await self.db.refresh(cmd)
        return cmd

    async def execute_command(self, command_id: uuid.UUID, tenant_id: uuid.UUID) -> DeviceCommand:
        # Get command with device joined
        stmt = select(DeviceCommand).where(
            DeviceCommand.id == command_id,
            DeviceCommand.tenant_id == tenant_id
        ).options(selectinload(DeviceCommand.device))
        
        res = await self.db.execute(stmt)
        cmd = res.scalar_one_or_none()
        
        if not cmd:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Command not found")

        cmd.sent_at = datetime.now(timezone.utc)
        cmd.status = CommandStatus.SENT.value
        await self.db.commit()

        from app.models.essl_server import EsslServer
        stmt_server = select(EsslServer).where(EsslServer.tenant_id == tenant_id, EsslServer.is_active == True)
        server_result = await self.db.execute(stmt_server)
        server = server_result.scalar_one_or_none()
        if not server:
            raise HTTPException(status_code=400, detail="No active eSSL server configured")
        soap_service = ESSLSoapService(server.server_url, server.username, server.password_encrypted)
        serial = cmd.device.serial_number
        t = cmd.command_type
        params = cmd.parameters or {}

        try:
            if t == CommandType.REBOOT.value:
                soap_res = await soap_service.device_command_reboot(serial)
            elif t == CommandType.CLEAR_LOGS.value:
                soap_res = await soap_service.device_command_clear_logs(serial)
            elif t == CommandType.ENROLL_FP.value:
                employee_code = params.get("employee_code")
                if not employee_code:
                    raise ValueError("employee_code is required in parameters for enroll_fp")
                soap_res = await soap_service.device_command_enroll_fp(serial, employee_code)
            elif t == CommandType.ENROLL_FACE.value:
                employee_code = params.get("employee_code")
                if not employee_code:
                    raise ValueError("employee_code is required in parameters for enroll_face")
                soap_res = await soap_service.device_command_enroll_face(serial, employee_code)
            elif t == CommandType.UNLOCK_DOOR.value:
                soap_res = await soap_service.device_command_unlock_door(serial)
            elif t == CommandType.BLOCK_USER.value:
                employee_code = params.get("employee_code")
                if not employee_code:
                    raise ValueError("employee_code is required in parameters for block_user")
                soap_res = await soap_service.device_command_block_unblock_user(serial, employee_code, block=True)
            elif t == CommandType.UNBLOCK_USER.value:
                employee_code = params.get("employee_code")
                if not employee_code:
                    raise ValueError("employee_code is required in parameters for unblock_user")
                soap_res = await soap_service.device_command_block_unblock_user(serial, employee_code, block=False)
            elif t == CommandType.RESET_OP_STAMP.value:
                soap_res = await soap_service.device_command_reset_op_stamp(serial)
            elif t == CommandType.RESET_TRANSACTION_STAMP.value:
                soap_res = await soap_service.device_command_reset_transaction_stamp(serial)
            else:
                raise ValueError(f"Unsupported command type: {t}")

            if soap_res.get("success"):
                cmd.status = CommandStatus.SUCCESS.value
                cmd.response_data = soap_res.get("data")
            else:
                cmd.status = CommandStatus.FAILED.value
                cmd.error_message = soap_res.get("error")
        except Exception as e:
            cmd.status = CommandStatus.FAILED.value
            cmd.error_message = str(e)

        cmd.completed_at = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(cmd)
        return cmd

    async def list_commands(
        self,
        tenant_id: uuid.UUID,
        device_id: Optional[uuid.UUID] = None,
        status_val: Optional[str] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[DeviceCommand], int]:
        count_stmt = select(func.count(DeviceCommand.id)).where(DeviceCommand.tenant_id == tenant_id)
        stmt = select(DeviceCommand).where(DeviceCommand.tenant_id == tenant_id).options(
            selectinload(DeviceCommand.device)
        ).order_by(DeviceCommand.requested_at.desc())

        if device_id:
            count_stmt = count_stmt.where(DeviceCommand.device_id == device_id)
            stmt = stmt.where(DeviceCommand.device_id == device_id)
        if status_val:
            count_stmt = count_stmt.where(DeviceCommand.status == status_val)
            stmt = stmt.where(DeviceCommand.status == status_val)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        commands = list(res.scalars().all())
        return commands, total

    async def get_command_status(self, command_id: uuid.UUID, tenant_id: uuid.UUID) -> str:
        stmt = select(DeviceCommand.status).where(
            DeviceCommand.id == command_id,
            DeviceCommand.tenant_id == tenant_id
        )
        res = await self.db.execute(stmt)
        status_val = res.scalar_one_or_none()
        if not status_val:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Command not found")
        return status_val
