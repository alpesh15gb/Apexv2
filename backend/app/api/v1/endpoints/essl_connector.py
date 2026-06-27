"""eSSL Connector API endpoints."""

import uuid
from datetime import datetime, date, timezone, timedelta
from typing import Optional, List
from fastapi import APIRouter, Depends, HTTPException, Query, BackgroundTasks
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.core.encryption import encrypt_value, decrypt_value
from app.models.user import User
from app.models.essl_server import EsslServer
from app.models.essl_sync import EsslSyncHistory, EsslSyncError
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.essl_cursor import EsslSyncCursor
from app.models.attendance import AttendanceRawLog
from app.models.device import Device
from app.models.employee import Employee
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.essl import (
    EsslServerCreate, EsslServerUpdate, EsslServerResponse,
    EsslTestResult, EsslSyncHistoryResponse, EsslSyncErrorItem, EsslSyncDashboardStatus,
    AttendanceReprocessRequest, AttendanceReprocessResult,
    ServerSyncHealth, SyncThroughputPoint, EnterpriseSyncDashboard,
)
from app.services.essl_connector import EsslConnectorService

router = APIRouter()


# ------------------------------------------------------------------
# eSSL SERVER CRUD
# ------------------------------------------------------------------

@router.post("/", response_model=EsslServerResponse, status_code=201)
async def create_essl_server(
    data: EsslServerCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create a new eSSL server configuration for this tenant."""
    from app.services.sync_audit import SyncAuditService

    encrypted_pw = encrypt_value(data.password)
    server = EsslServer(
        tenant_id=current_user.tenant_id,
        name=data.name,
        server_url=data.server_url,
        username=data.username,
        password_encrypted=encrypted_pw,
        timeout_seconds=data.timeout_seconds,
        timezone=data.timezone,
        auto_sync_enabled=data.auto_sync_enabled,
        attendance_sync_interval_minutes=data.attendance_sync_interval_minutes,
        device_sync_interval_minutes=data.device_sync_interval_minutes,
        employee_sync_hour=data.employee_sync_hour,
        employee_conflict_policy=data.employee_conflict_policy,
        device_conflict_policy=data.device_conflict_policy,
    )
    db.add(server)
    await db.flush()

    audit = SyncAuditService(db)
    await audit.log_server_config_change(
        tenant_id=current_user.tenant_id,
        server_id=server.id,
        action="essl_server_created",
        new_values={"name": data.name, "server_url": data.server_url, "timezone": data.timezone},
        user_id=current_user.id,
    )
    await db.commit()
    await db.refresh(server)
    return server


@router.get("/", response_model=PaginatedResponse[EsslServerResponse])
async def list_essl_servers(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """List all eSSL servers for this tenant."""
    count_stmt = select(func.count(EsslServer.id)).where(
        EsslServer.tenant_id == current_user.tenant_id
    )
    total = (await db.execute(count_stmt)).scalar() or 0

    stmt = (
        select(EsslServer)
        .where(EsslServer.tenant_id == current_user.tenant_id)
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(stmt)
    servers = list(result.scalars().all())

    return PaginatedResponse(
        items=servers, total=total, page=page, page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/{server_id}", response_model=EsslServerResponse)
async def get_essl_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get a single eSSL server config."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    return server


@router.put("/{server_id}", response_model=EsslServerResponse)
async def update_essl_server(
    server_id: uuid.UUID,
    data: EsslServerUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Update an eSSL server configuration."""
    server = await _get_server(db, server_id, current_user.tenant_id)

    update_data = data.model_dump(exclude_unset=True)
    if "password" in update_data:
        update_data["password_encrypted"] = encrypt_value(update_data.pop("password"))

    for field, val in update_data.items():
        if hasattr(server, field):
            setattr(server, field, val)

    await db.commit()
    await db.refresh(server)
    return server


@router.delete("/{server_id}", response_model=ResponseBase)
async def delete_essl_server(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Delete an eSSL server and all associated data."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    server_name = server.name

    audit = SyncAuditService(db)
    await audit.log_server_config_change(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        action="essl_server_deleted",
        old_values={"name": server_name, "server_url": server.server_url},
        user_id=current_user.id,
    )

    await db.delete(server)
    await db.commit()
    return ResponseBase(message="eSSL server deleted")


# ------------------------------------------------------------------
# CONNECTION TESTING
# ------------------------------------------------------------------

@router.post("/{server_id}/test", response_model=EsslTestResult)
async def test_essl_connection(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Test connection to the eSSL server."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    result = await connector.test_connection()

    audit = SyncAuditService(db)
    await audit.log_connection_test(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        success=result.get("success", False),
        response_time_ms=result.get("response_time_ms"),
        error=result.get("error"),
        user_id=current_user.id,
    )
    await db.commit()

    return EsslTestResult(**result)


# ------------------------------------------------------------------
# MANUAL SYNC
# ------------------------------------------------------------------

@router.post("/{server_id}/sync/employees", response_model=EsslSyncHistoryResponse)
async def sync_employees(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Manually trigger employee sync."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)

    audit = SyncAuditService(db)
    await audit.log_sync_started(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="employees",
        triggered_by="manual",
        user_id=current_user.id,
    )

    history = await connector.sync_employees(triggered_by="manual")

    await audit.log_sync_completed(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="employees",
        status=history.status,
        records_fetched=history.records_fetched,
        records_created=history.records_created,
        records_updated=history.records_updated,
        records_failed=history.records_failed,
        duration_seconds=history.duration_seconds,
        user_id=current_user.id,
        error_message=history.error_message,
    )
    await db.commit()

    return history


@router.post("/{server_id}/sync/attendance", response_model=EsslSyncHistoryResponse)
async def sync_attendance(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Manually trigger attendance sync."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)

    audit = SyncAuditService(db)
    await audit.log_sync_started(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="attendance",
        triggered_by="manual",
        user_id=current_user.id,
    )

    history = await connector.sync_attendance(triggered_by="manual")

    from app.services.attendance_processor import AttendanceProcessor
    processor = AttendanceProcessor(db)
    processing_result = await processor.process_raw_logs(current_user.tenant_id)
    history.records_created = processing_result.get("created", 0)
    history.records_updated = processing_result.get("updated", 0)

    await audit.log_sync_completed(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="attendance",
        status=history.status,
        records_fetched=history.records_fetched,
        records_created=history.records_created,
        records_updated=history.records_updated,
        records_failed=history.records_failed,
        duration_seconds=history.duration_seconds,
        user_id=current_user.id,
        error_message=history.error_message,
    )
    await db.commit()

    return history


@router.post("/{server_id}/sync/devices", response_model=EsslSyncHistoryResponse)
async def sync_devices(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Manually trigger device sync."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)

    audit = SyncAuditService(db)
    await audit.log_sync_started(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="devices",
        triggered_by="manual",
        user_id=current_user.id,
    )

    history = await connector.sync_devices(triggered_by="manual")

    await audit.log_sync_completed(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        server_name=server.name,
        sync_type="devices",
        status=history.status,
        records_fetched=history.records_fetched,
        records_created=history.records_created,
        records_updated=history.records_updated,
        records_failed=history.records_failed,
        duration_seconds=history.duration_seconds,
        user_id=current_user.id,
        error_message=history.error_message,
    )
    await db.commit()

    return history


# ------------------------------------------------------------------
# INITIAL SYNC (First-time import)
# ------------------------------------------------------------------

@router.post("/{server_id}/sync/initial", response_model=EsslSyncHistoryResponse)
async def initial_sync_attendance(
    server_id: uuid.UUID,
    from_date: date = Query(..., description="Start date (YYYY-MM-DD)"),
    to_date: date = Query(..., description="End date (YYYY-MM-DD)"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Initial attendance sync for a date range (first-time import)."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    history = await connector.initial_sync_attendance(from_date, to_date, triggered_by="manual")
    return history


# ------------------------------------------------------------------
# ATTENDANCE REPROCESSING
# ------------------------------------------------------------------

@router.post("/{server_id}/reprocess", response_model=AttendanceReprocessResult)
async def reprocess_attendance(
    server_id: uuid.UUID,
    data: AttendanceReprocessRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Reprocess attendance records without re-downloading from eSSL.

    Resets raw logs to unprocessed and re-runs the attendance calculator.
    Supports filtering by date range, employee, or department.
    """
    from app.services.attendance_processor import AttendanceProcessor
    from app.services.sync_audit import SyncAuditService

    await _get_server(db, server_id, current_user.tenant_id)
    processor = AttendanceProcessor(db)
    result = await processor.reprocess(
        tenant_id=current_user.tenant_id,
        from_date=data.from_date,
        to_date=data.to_date,
        employee_id=data.employee_id,
        department_id=data.department_id,
    )

    audit = SyncAuditService(db)
    await audit.log_reprocess(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        result=result,
        from_date=str(data.from_date) if data.from_date else None,
        to_date=str(data.to_date) if data.to_date else None,
        employee_id=data.employee_id,
        department_id=data.department_id,
        user_id=current_user.id,
    )
    await db.commit()

    return AttendanceReprocessResult(**result)


# ------------------------------------------------------------------
# OFFLINE RECOVERY
# ------------------------------------------------------------------

@router.post("/{server_id}/recover")
async def recover_from_offline(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Recover from offline period — incremental catch-up."""
    from app.services.sync_audit import SyncAuditService

    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    result = await connector.recover_from_offline()

    audit = SyncAuditService(db)
    await audit.log_recovery(
        tenant_id=current_user.tenant_id,
        server_id=server_id,
        result=result,
        user_id=current_user.id,
    )
    await db.commit()

    return result


@router.get("/{server_id}/recovery-status")
async def get_recovery_status(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get current recovery status for monitoring."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    return await connector.get_recovery_status()


@router.get("/{server_id}/cursor-integrity")
async def validate_cursor_integrity(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Validate and repair cursor if corrupted."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    return await connector.validate_cursor_integrity()


@router.get("/{server_id}/clock-drift")
async def detect_clock_drift(
    server_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Detect clock drift across devices connected to this eSSL server."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    return await connector.detect_clock_drift()


@router.post("/{server_id}/sync/{history_id}/pause")
async def pause_sync(
    server_id: uuid.UUID,
    history_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Pause a running sync."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    success = await connector.pause_sync(history_id)
    if not success:
        raise HTTPException(status_code=404, detail="Sync not found or not running")
    return {"message": "Sync paused"}


@router.post("/{server_id}/sync/{history_id}/resume")
async def resume_sync(
    server_id: uuid.UUID,
    history_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Resume a paused sync."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    success = await connector.resume_sync(history_id)
    if not success:
        raise HTTPException(status_code=404, detail="Sync not found or not paused")
    return {"message": "Sync resumed"}


@router.post("/{server_id}/sync/{history_id}/cancel")
async def cancel_sync(
    server_id: uuid.UUID,
    history_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Cancel a running or paused sync."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    success = await connector.cancel_sync(history_id)
    if not success:
        raise HTTPException(status_code=404, detail="Sync not found or already completed")
    return {"message": "Sync cancelled"}


@router.get("/{server_id}/sync/{history_id}/progress")
async def get_sync_progress(
    server_id: uuid.UUID,
    history_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get current sync progress."""
    server = await _get_server(db, server_id, current_user.tenant_id)
    connector = EsslConnectorService(db, server)
    progress = await connector.get_sync_progress(history_id)
    if not progress:
        raise HTTPException(status_code=404, detail="Sync not found")
    return progress


# ------------------------------------------------------------------
# SYNC HISTORY & ERRORS
# ------------------------------------------------------------------

@router.get("/{server_id}/sync/history", response_model=PaginatedResponse[EsslSyncHistoryResponse])
async def get_sync_history(
    server_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get sync history for an eSSL server."""
    await _get_server(db, server_id, current_user.tenant_id)

    count_stmt = select(func.count(EsslSyncHistory.id)).where(
        EsslSyncHistory.essl_server_id == server_id
    )
    total = (await db.execute(count_stmt)).scalar() or 0

    stmt = (
        select(EsslSyncHistory)
        .where(EsslSyncHistory.essl_server_id == server_id)
        .order_by(EsslSyncHistory.started_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(stmt)
    history = list(result.scalars().all())

    return PaginatedResponse(
        items=history, total=total, page=page, page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/{server_id}/sync/errors", response_model=PaginatedResponse[EsslSyncErrorItem])
async def get_sync_errors(
    server_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get sync errors for an eSSL server."""
    await _get_server(db, server_id, current_user.tenant_id)

    count_stmt = select(func.count(EsslSyncError.id)).where(
        EsslSyncError.tenant_id == current_user.tenant_id,
    )
    total = (await db.execute(count_stmt)).scalar() or 0

    stmt = (
        select(EsslSyncError)
        .where(EsslSyncError.tenant_id == current_user.tenant_id)
        .order_by(EsslSyncError.occurred_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(stmt)
    errors = list(result.scalars().all())

    return PaginatedResponse(
        items=errors, total=total, page=page, page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


# ------------------------------------------------------------------
# DUPLICATE DETECTION
# ------------------------------------------------------------------

@router.get("/duplicates/stats")
async def get_duplicate_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get duplicate statistics for the tenant."""
    from app.services.duplicate_detector import DuplicateDetector
    detector = DuplicateDetector(db)
    return await detector.get_duplicate_stats(current_user.tenant_id)


@router.get("/duplicates/cross-server")
async def find_cross_server_duplicates(
    from_date: Optional[date] = Query(None),
    to_date: Optional[date] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Find punches that appear on multiple servers."""
    from app.services.duplicate_detector import DuplicateDetector
    detector = DuplicateDetector(db)
    return await detector.find_cross_server_duplicates(
        current_user.tenant_id, from_date, to_date
    )


@router.post("/duplicates/resolve")
async def resolve_duplicates(
    strategy: str = Query("keep_first", description="Strategy: keep_first, keep_all, mark_review"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Resolve cross-server duplicates."""
    from app.services.duplicate_detector import DuplicateDetector
    detector = DuplicateDetector(db)
    return await detector.resolve_duplicates(current_user.tenant_id, strategy)


# ------------------------------------------------------------------
# DASHBOARD
# ------------------------------------------------------------------

@router.get("/dashboard/sync-status", response_model=list[EsslSyncDashboardStatus])
async def get_sync_dashboard(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get comprehensive eSSL sync status for the dashboard."""
    from app.services.essl_dashboard import EsslDashboardService

    service = EsslDashboardService(db)
    items = await service.get_sync_dashboard(current_user.tenant_id)
    return [EsslSyncDashboardStatus(**item) for item in items]


@router.get("/dashboard/enterprise", response_model=EnterpriseSyncDashboard)
async def get_enterprise_sync_dashboard(
    throughput_days: int = Query(7, ge=1, le=30),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Enterprise sync dashboard with health scores, throughput, and alerts."""
    from app.services.essl_dashboard import EsslDashboardService

    service = EsslDashboardService(db)
    data = await service.get_enterprise_dashboard(current_user.tenant_id, throughput_days)

    servers = [ServerSyncHealth(**s) for s in data["servers"]]
    throughput = [SyncThroughputPoint(**t) for t in data["throughput_trend"]]

    return EnterpriseSyncDashboard(
        overall_health_score=data["overall_health_score"],
        total_servers=data["total_servers"],
        healthy_servers=data["healthy_servers"],
        degraded_servers=data["degraded_servers"],
        down_servers=data["down_servers"],
        total_pending_raw_logs=data["total_pending_raw_logs"],
        total_syncs_today=data["total_syncs_today"],
        total_errors_today=data["total_errors_today"],
        avg_processing_lag_minutes=data["avg_processing_lag_minutes"],
        servers=servers,
        throughput_trend=throughput,
    )


# ------------------------------------------------------------------
# HELPERS
# ------------------------------------------------------------------

async def _get_server(db: AsyncSession, server_id: uuid.UUID, tenant_id: uuid.UUID) -> EsslServer:
    stmt = select(EsslServer).where(
        EsslServer.id == server_id,
        EsslServer.tenant_id == tenant_id,
    )
    result = await db.execute(stmt)
    server = result.scalar_one_or_none()
    if not server:
        raise HTTPException(status_code=404, detail="eSSL server not found")
    return server
