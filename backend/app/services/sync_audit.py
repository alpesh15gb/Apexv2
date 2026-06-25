"""Sync Audit Service — writes sync-specific entries to the audit_logs table."""

import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any

import structlog
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.audit_log import AuditLog

logger = structlog.get_logger(__name__)


class SyncAuditService:
    """Records sync lifecycle events in the audit_logs table."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def log_sync_started(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        server_name: str,
        sync_type: str,
        triggered_by: str,
        user_id: Optional[uuid.UUID] = None,
        date_range: Optional[Dict[str, str]] = None,
    ):
        new_values: Dict[str, Any] = {
            "server_id": str(server_id),
            "server_name": server_name,
            "sync_type": sync_type,
            "triggered_by": triggered_by,
        }
        if date_range:
            new_values["date_range"] = date_range

        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action="sync_started",
            resource_type="essl_sync",
            resource_id=str(server_id),
            new_values=new_values,
        )

    async def log_sync_completed(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        server_name: str,
        sync_type: str,
        status: str,
        records_fetched: int,
        records_created: int,
        records_updated: int,
        records_failed: int,
        duration_seconds: Optional[float] = None,
        user_id: Optional[uuid.UUID] = None,
        error_message: Optional[str] = None,
    ):
        new_values: Dict[str, Any] = {
            "server_id": str(server_id),
            "server_name": server_name,
            "sync_type": sync_type,
            "status": status,
            "records_fetched": records_fetched,
            "records_created": records_created,
            "records_updated": records_updated,
            "records_failed": records_failed,
        }
        if duration_seconds is not None:
            new_values["duration_seconds"] = round(duration_seconds, 2)
        if error_message:
            new_values["error_message"] = error_message

        action = "sync_completed" if status in ("completed", "partial") else "sync_failed"
        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action=action,
            resource_type="essl_sync",
            resource_id=str(server_id),
            new_values=new_values,
        )

    async def log_reprocess(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        result: Dict[str, Any],
        from_date: Optional[str] = None,
        to_date: Optional[str] = None,
        employee_id: Optional[uuid.UUID] = None,
        department_id: Optional[uuid.UUID] = None,
        user_id: Optional[uuid.UUID] = None,
    ):
        new_values: Dict[str, Any] = {
            "server_id": str(server_id),
            "result": result,
        }
        if from_date:
            new_values["from_date"] = from_date
        if to_date:
            new_values["to_date"] = to_date
        if employee_id:
            new_values["employee_id"] = str(employee_id)
        if department_id:
            new_values["department_id"] = str(department_id)

        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action="attendance_reprocess",
            resource_type="essl_sync",
            resource_id=str(server_id),
            new_values=new_values,
        )

    async def log_server_config_change(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        action: str,
        old_values: Optional[Dict[str, Any]] = None,
        new_values: Optional[Dict[str, Any]] = None,
        user_id: Optional[uuid.UUID] = None,
    ):
        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action=action,
            resource_type="essl_server",
            resource_id=str(server_id),
            old_values=old_values,
            new_values=new_values,
        )

    async def log_connection_test(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        success: bool,
        response_time_ms: Optional[int] = None,
        error: Optional[str] = None,
        user_id: Optional[uuid.UUID] = None,
    ):
        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action="connection_test",
            resource_type="essl_server",
            resource_id=str(server_id),
            new_values={
                "success": success,
                "response_time_ms": response_time_ms,
                "error": error,
            },
        )

    async def log_recovery(
        self,
        tenant_id: uuid.UUID,
        server_id: uuid.UUID,
        result: Dict[str, Any],
        user_id: Optional[uuid.UUID] = None,
    ):
        await self._write(
            tenant_id=tenant_id,
            user_id=user_id,
            action="offline_recovery",
            resource_type="essl_sync",
            resource_id=str(server_id),
            new_values=result,
        )

    async def _write(
        self,
        tenant_id: uuid.UUID,
        action: str,
        resource_type: str,
        resource_id: Optional[str] = None,
        user_id: Optional[uuid.UUID] = None,
        old_values: Optional[Dict[str, Any]] = None,
        new_values: Optional[Dict[str, Any]] = None,
    ):
        try:
            entry = AuditLog(
                tenant_id=tenant_id,
                user_id=user_id,
                action=action,
                resource_type=resource_type,
                resource_id=resource_id,
                old_values=old_values,
                new_values=new_values,
            )
            self.db.add(entry)
            await self.db.flush()
        except Exception as e:
            logger.error("sync_audit_write_failed", action=action, error=str(e))
