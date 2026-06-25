"""Celery tasks for per-tenant eSSL synchronization."""

import asyncio
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db.session import async_session_factory
from app.models.essl_server import EsslServer
from app.services.essl_connector import EsslConnectorService
from app.services.attendance_processor import AttendanceProcessor
from app.tasks.celery_app import celery_app


def _run_async(coro):
    """Bridge async code to sync Celery task."""
    return asyncio.get_event_loop().run_until_complete(coro)


# ------------------------------------------------------------------
# ATTENDANCE SYNC (every 5 minutes)
# ------------------------------------------------------------------

@celery_app.task(name="app.tasks.sync_tasks.sync_all_tenants_attendance")
def sync_all_tenants_attendance():
    """For each tenant with auto_sync_enabled servers: sync attendance."""

    async def _do():
        async with async_session_factory() as db:
            stmt = select(EsslServer).where(
                EsslServer.is_active == True,
                EsslServer.auto_sync_enabled == True,
            )
            result = await db.execute(stmt)
            servers = list(result.scalars().all())

            for server in servers:
                try:
                    connector = EsslConnectorService(db, server)
                    await connector.sync_attendance(triggered_by="auto")
                except Exception as e:
                    print(f"Attendance sync failed for server {server.id}: {e}")

    _run_async(_do())


# ------------------------------------------------------------------
# DEVICE SYNC (every 60 minutes)
# ------------------------------------------------------------------

@celery_app.task(name="app.tasks.sync_tasks.sync_all_tenants_devices")
def sync_all_tenants_devices():
    """For each tenant with auto_sync_enabled servers: sync devices."""

    async def _do():
        async with async_session_factory() as db:
            stmt = select(EsslServer).where(
                EsslServer.is_active == True,
                EsslServer.auto_sync_enabled == True,
            )
            result = await db.execute(stmt)
            servers = list(result.scalars().all())

            for server in servers:
                try:
                    connector = EsslConnectorService(db, server)
                    await connector.sync_devices(triggered_by="auto")
                except Exception as e:
                    print(f"Device sync failed for server {server.id}: {e}")

    _run_async(_do())


# ------------------------------------------------------------------
# EMPLOYEE SYNC (daily at 2 AM)
# ------------------------------------------------------------------

@celery_app.task(name="app.tasks.sync_tasks.sync_all_tenants_employees")
def sync_all_tenants_employees():
    """For each tenant with auto_sync_enabled servers: sync employees."""

    async def _do():
        async with async_session_factory() as db:
            stmt = select(EsslServer).where(
                EsslServer.is_active == True,
                EsslServer.auto_sync_enabled == True,
            )
            result = await db.execute(stmt)
            servers = list(result.scalars().all())

            for server in servers:
                try:
                    connector = EsslConnectorService(db, server)
                    await connector.sync_employees(triggered_by="auto")
                except Exception as e:
                    print(f"Employee sync failed for server {server.id}: {e}")

    _run_async(_do())


# ------------------------------------------------------------------
# PROCESS RAW ATTENDANCE (every 5 minutes)
# ------------------------------------------------------------------

@celery_app.task(name="app.tasks.sync_tasks.process_all_unprocessed_attendance")
def process_all_unprocessed_attendance():
    """For each tenant: run AttendanceProcessor on unprocessed raw logs."""

    async def _do():
        async with async_session_factory() as db:
            stmt = select(EsslServer.tenant_id).distinct().where(
                EsslServer.is_active == True,
            )
            result = await db.execute(stmt)
            tenant_ids = [row[0] for row in result.all()]

            for tenant_id in tenant_ids:
                try:
                    processor = AttendanceProcessor(db)
                    await processor.process_raw_logs(tenant_id)
                except Exception as e:
                    print(f"Attendance processing failed for tenant {tenant_id}: {e}")

    _run_async(_do())
