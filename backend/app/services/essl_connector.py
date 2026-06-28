"""eSSL Connector Service — per-tenant eSSL integration with bulk sync and cursors."""

import uuid
from datetime import datetime, date, time, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

import structlog
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.encryption import decrypt_value
from app.core.config import get_settings
from app.models.essl_server import EsslServer, EsslServerStatus, ConflictPolicy
from app.models.essl_sync import (
    EsslSyncHistory, EsslSyncJob, EsslSyncError, SyncStatus, SyncType,
)
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.essl_cursor import EsslSyncCursor
from app.models.essl_location import EsslLocation
from app.models.employee import Employee, Department, Designation, Branch
from app.models.device import Device, DeviceStatus
from app.models.attendance import AttendanceRawLog
from app.services.essl_soap import ESSLSoapService
from app.services.essl_client import ESSLClient

logger = structlog.get_logger(__name__)


class EsslConnectorService:
    """Per-tenant eSSL connector with bulk sync, cursors, and conflict resolution."""

    def __init__(self, db: AsyncSession, server: EsslServer):
        self.db = db
        self.server = server
        password = decrypt_value(server.password_encrypted)
        self.soap = ESSLSoapService(
            server_url=server.server_url,
            username=server.username,
            password=password,
            timeout=server.timeout_seconds,
        )
        settings = get_settings()
        self.client = ESSLClient(self.soap, redis_url=settings.REDIS_URL)

    async def _get_active_locations(self) -> List[str]:
        """Return list of active location codes for this server. Empty list = all locations."""
        stmt = select(EsslLocation.code).where(
            EsslLocation.essl_server_id == self.server.id,
            EsslLocation.is_active == True,
        )
        result = await self.db.execute(stmt)
        return [row[0] for row in result.all()]

    # ------------------------------------------------------------------
    # CONNECTION TESTING
    # ------------------------------------------------------------------

    async def test_connection(self) -> Dict[str, Any]:
        """Test eSSL server connectivity.
        Returns: {success, server_version, response_time_ms, error}
        """
        import time as time_mod

        self.server.status = EsslServerStatus.TESTING
        await self.db.commit()

        start = time_mod.monotonic()
        try:
            result = await self.client.get_devices(bypass_cache=True)
            elapsed_ms = int((time_mod.monotonic() - start) * 1000)

            if result.get("success"):
                self.server.status = EsslServerStatus.CONNECTED
                self.server.last_connected_at = datetime.now(timezone.utc)
                self.server.last_error = None
                self.server.server_version = result.get("data", {}).get("version", "unknown")
                await self.db.commit()
                return {
                    "success": True,
                    "server_version": self.server.server_version,
                    "response_time_ms": elapsed_ms,
                    "error": None,
                }
            else:
                error_msg = result.get("error", "Unknown error")
                self.server.status = EsslServerStatus.ERROR
                self.server.last_error = error_msg
                await self.db.commit()
                return {"success": False, "server_version": None, "response_time_ms": elapsed_ms, "error": error_msg}

        except Exception as e:
            elapsed_ms = int((time_mod.monotonic() - start) * 1000)
            error_msg = str(e)
            self.server.status = EsslServerStatus.ERROR
            self.server.last_error = error_msg
            await self.db.commit()
            return {"success": False, "server_version": None, "response_time_ms": elapsed_ms, "error": error_msg}

    # ------------------------------------------------------------------
    # OFFLINE RECOVERY
    # ------------------------------------------------------------------

    async def recover_from_offline(self) -> Dict[str, Any]:
        """Recover from offline period — incremental catch-up.
        
        1. Test connection
        2. If online: check cursor for last successful sync
        3. Calculate offline duration
        4. Run incremental sync from cursor position
        5. Process any unprocessed raw logs
        6. Recalculate attendance for affected dates
        
        Returns: {success, offline_duration_hours, records_synced, attendance_recalculated}
        """
        import time as time_mod

        # Step 1: Test connection
        test_result = await self.test_connection()
        if not test_result.get("success"):
            return {
                "success": False,
                "error": test_result.get("error", "Connection failed"),
                "offline_duration_hours": None,
                "records_synced": 0,
                "attendance_recalculated": False,
            }

        # Step 2: Check cursor for last successful sync
        cursor = await self._get_cursor("attendance")
        now = datetime.now(timezone.utc)

        if cursor and cursor.last_punch_time:
            offline_duration = (now - cursor.last_punch_time).total_seconds() / 3600
            from_date = cursor.last_punch_time.date()
        else:
            # No cursor — default to last 7 days
            offline_duration = 168  # 7 days in hours
            from_date = (now - timedelta(days=7)).date()

        to_date = now.date()

        # Step 3: Run incremental sync
        logger.info(
            "essl_offline_recovery_started",
            server_id=str(self.server.id),
            offline_duration_hours=round(offline_duration, 1),
            from_date=from_date.isoformat(),
            to_date=to_date.isoformat(),
        )

        sync_history = await self.sync_attendance(triggered_by="recovery")

        # Step 4: Process unprocessed raw logs
        from app.services.attendance_processor import AttendanceProcessor
        processor = AttendanceProcessor(self.db)
        processing_result = await processor.process_raw_logs(self.server.tenant_id)

        # Step 5: Track consecutive failures
        if sync_history.status == SyncStatus.FAILED:
            self.server.consecutive_failures = getattr(self.server, 'consecutive_failures', 0) + 1
        else:
            self.server.consecutive_failures = 0

        await self.db.commit()

        return {
            "success": sync_history.status in (SyncStatus.COMPLETED, SyncStatus.PARTIAL),
            "offline_duration_hours": round(offline_duration, 1),
            "records_synced": sync_history.records_created + sync_history.records_updated,
            "attendance_recalculated": True,
            "processing_result": processing_result,
            "consecutive_failures": getattr(self.server, 'consecutive_failures', 0),
        }

    async def validate_cursor_integrity(self) -> Dict[str, Any]:
        """Validate and repair cursor if corrupted.
        
        Checks:
        1. Cursor exists
        2. last_punch_time is not in the future
        3. last_punch_time is not too old (more than 90 days)
        
        Returns: {valid, repaired, cursor_state}
        """
        cursor = await self._get_cursor("attendance")
        now = datetime.now(timezone.utc)

        if not cursor:
            return {"valid": False, "repaired": False, "cursor_state": "missing"}

        issues = []

        # Check if cursor is in the future
        if cursor.last_punch_time and cursor.last_punch_time > now:
            issues.append("cursor_in_future")
            cursor.last_punch_time = now - timedelta(days=1)

        # Check if cursor is too old
        if cursor.last_punch_time and (now - cursor.last_punch_time).days > 90:
            issues.append("cursor_too_old")
            # Don't repair — let the sync handle it

        if issues:
            await self.db.commit()
            return {
                "valid": False,
                "repaired": True,
                "cursor_state": "repaired",
                "issues": issues,
            }

        return {"valid": True, "repaired": False, "cursor_state": "ok"}

    async def get_recovery_status(self) -> Dict[str, Any]:
        """Get current recovery status for monitoring."""
        cursor = await self._get_cursor("attendance")
        now = datetime.now(timezone.utc)

        offline_hours = 0
        if cursor and cursor.last_punch_time:
            offline_hours = (now - cursor.last_punch_time).total_seconds() / 3600

        # Count unprocessed raw logs
        from sqlalchemy import func
        unprocessed_stmt = select(func.count(AttendanceRawLog.id)).where(
            AttendanceRawLog.essl_server_id == self.server.id,
            AttendanceRawLog.processed == False,
        )
        unprocessed_count = (await self.db.execute(unprocessed_stmt)).scalar() or 0

        # Get last sync history
        last_sync_stmt = (
            select(EsslSyncHistory)
            .where(
                EsslSyncHistory.essl_server_id == self.server.id,
                EsslSyncHistory.status.in_([SyncStatus.COMPLETED, SyncStatus.PARTIAL]),
            )
            .order_by(EsslSyncHistory.completed_at.desc())
            .limit(1)
        )
        last_sync_result = await self.db.execute(last_sync_stmt)
        last_sync = last_sync_result.scalar_one_or_none()

        return {
            "server_id": str(self.server.id),
            "server_status": self.server.status,
            "offline_duration_hours": round(offline_hours, 1),
            "unprocessed_raw_logs": unprocessed_count,
            "last_successful_sync": last_sync.completed_at.isoformat() if last_sync and last_sync.completed_at else None,
            "last_sync_status": last_sync.status if last_sync else None,
            "consecutive_failures": getattr(self.server, 'consecutive_failures', 0),
            "cursor_valid": await self.validate_cursor_integrity(),
        }

    # ------------------------------------------------------------------
    # INITIAL SYNC (First-time import with date range)
    # ------------------------------------------------------------------

    async def initial_sync_attendance(
        self,
        from_date: date,
        to_date: date,
        triggered_by: str = "manual",
    ) -> EsslSyncHistory:
        """Initial attendance sync for a date range (first-time import).
        Supports progress tracking, pause, resume, and cancel.
        """
        history = EsslSyncHistory(
            tenant_id=self.server.tenant_id,
            essl_server_id=self.server.id,
            sync_type=SyncType.ATTENDANCE,
            status=SyncStatus.RUNNING,
            triggered_by=triggered_by,
            date_range_from=datetime.combine(from_date, time.min).replace(tzinfo=timezone.utc),
            date_range_to=datetime.combine(to_date, time.max).replace(tzinfo=timezone.utc),
            total_records_expected=0,
            progress_percent=0,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)

        try:
            # Load device mappings for bulk fetch
            dev_mappings_stmt = select(EsslDeviceMapping).where(
                EsslDeviceMapping.essl_server_id == self.server.id
            )
            dev_result = await self.db.execute(dev_mappings_stmt)
            device_mappings = {m.serial_number: m for m in dev_result.scalars().all()}

            # Load employee mappings
            emp_mappings_stmt = select(EsslEmployeeMapping).where(
                EsslEmployeeMapping.essl_server_id == self.server.id
            )
            emp_result = await self.db.execute(emp_mappings_stmt)
            employee_mappings = {m.employee_code: m for m in emp_result.scalars().all()}

            # Calculate total days for progress tracking
            total_days = (to_date - from_date).days + 1
            history.total_records_expected = total_days
            history.total_batches = total_days
            await self.db.commit()

            created = 0
            skipped = 0
            failed = 0
            current_day = 0

            # Process day by day for progress tracking
            current_date = from_date
            while current_date <= to_date:
                # Check for pause/cancel
                await self.db.refresh(history)
                if history.is_cancelled:
                    history.status = SyncStatus.CANCELLED
                    history.completed_at = datetime.now(timezone.utc)
                    history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
                    await self.db.commit()
                    return history

                while history.is_paused:
                    await self.db.commit()
                    import asyncio
                    await asyncio.sleep(2)
                    await self.db.refresh(history)
                    if history.is_cancelled:
                        history.status = SyncStatus.CANCELLED
                        history.completed_at = datetime.now(timezone.utc)
                        history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
                        await self.db.commit()
                        return history

                # Fetch punches for this day
                from_str = current_date.strftime("%Y-%m-%d")
                to_str = current_date.strftime("%Y-%m-%d")

                for serial, dev_mapping in device_mappings.items():
                    try:
                        logs_result = await self.client.soap.get_device_logs(serial, from_str, to_str)
                        if not logs_result.get("success"):
                            continue

                        raw_logs = logs_result.get("data", [])
                        if isinstance(raw_logs, dict):
                            raw_logs = [raw_logs]

                        for log in raw_logs:
                            if not isinstance(log, dict):
                                continue

                            emp_code = log.get("EmployeeCode") or log.get("employee_code") or log.get("EnrollNumber")
                            punch_time_str = log.get("PunchTime") or log.get("punch_time") or log.get("DateTime")
                            punch_type = log.get("PunchType") or log.get("punch_type") or log.get("Direction")

                            if not emp_code or not punch_time_str:
                                continue

                            emp_code = str(emp_code).strip()
                            punch_time = self._parse_datetime(str(punch_time_str), self.server.timezone)
                            if not punch_time:
                                continue

                            emp_mapping = employee_mappings.get(emp_code)

                            raw_log = AttendanceRawLog(
                                tenant_id=self.server.tenant_id,
                                essl_server_id=self.server.id,
                                employee_code=emp_code,
                                employee_id=emp_mapping.employee_id if emp_mapping else None,
                                device_serial=serial,
                                device_id=dev_mapping.device_id,
                                punch_time=punch_time,
                                punch_type=str(punch_type).lower() if punch_type else None,
                                raw_data=log,
                                processed=False,
                            )
                            self.db.add(raw_log)
                            try:
                                await self.db.flush()
                                created += 1
                            except Exception:
                                await self.db.rollback()
                                skipped += 1

                    except Exception as e:
                        self._log_error(history, "device_logs", serial, str(e))
                        failed += 1

                current_day += 1
                current_date += timedelta(days=1)

                # Update progress
                history.progress_percent = int((current_day / total_days) * 100)
                history.current_batch = current_day
                history.records_created = created
                history.records_skipped = skipped
                history.records_failed = failed
                await self.db.commit()

            # Finalize
            history.status = SyncStatus.COMPLETED if failed == 0 else SyncStatus.PARTIAL
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            history.progress_percent = 100
            history.records_fetched = created + skipped + failed
            await self.db.commit()

            # Update cursor
            if created > 0:
                await self._update_cursor("attendance", last_punch_time=datetime.combine(to_date, time.max).replace(tzinfo=timezone.utc))

        except Exception as e:
            history.status = SyncStatus.FAILED
            history.error_message = str(e)
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            await self.db.commit()
            logger.error("essl_initial_sync_failed", server_id=str(self.server.id), error=str(e))

        return history

    async def pause_sync(self, history_id: uuid.UUID) -> bool:
        """Pause a running sync."""
        stmt = select(EsslSyncHistory).where(
            EsslSyncHistory.id == history_id,
            EsslSyncHistory.essl_server_id == self.server.id,
            EsslSyncHistory.status == SyncStatus.RUNNING,
        )
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()
        if not history:
            return False
        history.is_paused = True
        await self.db.commit()
        return True

    async def resume_sync(self, history_id: uuid.UUID) -> bool:
        """Resume a paused sync."""
        stmt = select(EsslSyncHistory).where(
            EsslSyncHistory.id == history_id,
            EsslSyncHistory.essl_server_id == self.server.id,
            EsslSyncHistory.is_paused == True,
        )
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()
        if not history:
            return False
        history.is_paused = False
        await self.db.commit()
        return True

    async def cancel_sync(self, history_id: uuid.UUID) -> bool:
        """Cancel a running or paused sync."""
        stmt = select(EsslSyncHistory).where(
            EsslSyncHistory.id == history_id,
            EsslSyncHistory.essl_server_id == self.server.id,
        )
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()
        if not history or history.status not in (SyncStatus.RUNNING,):
            return False
        history.is_cancelled = True
        history.is_paused = False  # Unpause so the loop can exit
        await self.db.commit()
        return True

    async def get_sync_progress(self, history_id: uuid.UUID) -> Optional[Dict]:
        """Get current sync progress."""
        stmt = select(EsslSyncHistory).where(EsslSyncHistory.id == history_id)
        result = await self.db.execute(stmt)
        history = result.scalar_one_or_none()
        if not history:
            return None
        return {
            "id": str(history.id),
            "status": history.status,
            "progress_percent": history.progress_percent,
            "total_records_expected": history.total_records_expected,
            "current_batch": history.current_batch,
            "total_batches": history.total_batches,
            "records_fetched": history.records_fetched,
            "records_created": history.records_created,
            "records_updated": history.records_updated,
            "records_skipped": history.records_skipped,
            "records_failed": history.records_failed,
            "is_paused": history.is_paused,
            "is_cancelled": history.is_cancelled,
            "started_at": history.started_at.isoformat() if history.started_at else None,
            "duration_seconds": history.duration_seconds,
        }

    # ------------------------------------------------------------------
    # EMPLOYEE SYNC (Daily, bulk codes + per-new-employee details)
    # ------------------------------------------------------------------

    async def sync_employees(self, triggered_by: str = "auto") -> EsslSyncHistory:
        """Employee sync pipeline — MULTI-SERVER SAFE.
        1. Get all employee codes from eSSL
        2. For each code: check if employee exists across ALL servers for this tenant
        3. If exists: reuse existing employee, add mapping for this server
        4. If not: create new employee + mapping
        5. Apply conflict policy for local employees missing from eSSL
        """
        history = EsslSyncHistory(
            tenant_id=self.server.tenant_id,
            essl_server_id=self.server.id,
            sync_type=SyncType.EMPLOYEES,
            status=SyncStatus.RUNNING,
            triggered_by=triggered_by,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)

        try:
            # Step 1: Get all codes from eSSL (per location)
            locations = await self._get_active_locations()
            all_codes = set()

            for loc in (locations or [""]):
                codes_result = await self.client.get_employee_codes(location=loc)
                if not codes_result.get("success"):
                    raise Exception(f"GetEmployeeCodes failed for location '{loc}': {codes_result.get('error')}")
                raw_codes = codes_result.get("data", [])
                if isinstance(raw_codes, dict):
                    raw_codes = raw_codes.get("items", [])
                if isinstance(raw_codes, list):
                    for item in raw_codes:
                        if isinstance(item, dict):
                            code = item.get("employee_code") or item.get("EmployeeCode") or item.get("code")
                        else:
                            code = str(item)
                        if code:
                            all_codes.add(str(code).strip())

            essl_codes = all_codes

            history.records_fetched = len(essl_codes)

            # Step 2: Load ALL mappings for this tenant (not just this server)
            all_mappings_stmt = select(EsslEmployeeMapping).where(
                EsslEmployeeMapping.tenant_id == self.server.tenant_id
            )
            all_mappings_result = await self.db.execute(all_mappings_stmt)
            all_mappings = all_mappings_result.scalars().all()

            # Build lookup: employee_code -> employee_id (from any server)
            code_to_employee_id = {}
            this_server_mappings = {}
            for m in all_mappings:
                code_to_employee_id[m.employee_code] = m.employee_id
                if m.essl_server_id == self.server.id:
                    this_server_mappings[m.employee_code] = m

            # Step 3: Load all employees for this tenant by code
            existing_employees_stmt = select(Employee).where(
                Employee.tenant_id == self.server.tenant_id
            )
            existing_employees_result = await self.db.execute(existing_employees_stmt)
            employees_by_code = {e.employee_code: e for e in existing_employees_result.scalars().all()}

            created = 0
            updated = 0
            skipped = 0
            failed = 0

            # Step 4: Process each eSSL code
            for code in essl_codes:
                try:
                    details = await self.client.get_employee_details(code, bypass_cache=True)
                    if not details.get("success"):
                        self._log_error(history, "employee", code, details.get("error", "Details fetch failed"))
                        failed += 1
                        continue

                    emp_data = details.get("data", {})
                    if hasattr(emp_data, 'model_dump'):
                        emp_data = emp_data.model_dump()
                    name = emp_data.get("name", "")
                    name_parts = name.strip().split(" ", 1) if name else ["", ""]
                    first_name = name_parts[0] if len(name_parts) > 0 else ""
                    last_name = name_parts[1] if len(name_parts) > 1 else ""

                    if code in this_server_mappings:
                        # Already mapped to this server — update
                        mapping = this_server_mappings[code]
                        employee = employees_by_code.get(code)
                        if employee:
                            employee.first_name = first_name or employee.first_name
                            employee.last_name = last_name or employee.last_name
                            mapping.synced_at = datetime.now(timezone.utc)
                            updated += 1
                        else:
                            skipped += 1
                    elif code in code_to_employee_id:
                        # Employee exists on ANOTHER server — add mapping for this server
                        existing_employee_id = code_to_employee_id[code]
                        mapping = EsslEmployeeMapping(
                            tenant_id=self.server.tenant_id,
                            essl_server_id=self.server.id,
                            employee_code=code,
                            employee_id=existing_employee_id,
                        )
                        self.db.add(mapping)
                        updated += 1
                    elif code in employees_by_code:
                        # Employee exists locally but no mapping — add mapping
                        employee = employees_by_code[code]
                        mapping = EsslEmployeeMapping(
                            tenant_id=self.server.tenant_id,
                            essl_server_id=self.server.id,
                            employee_code=code,
                            employee_id=employee.id,
                        )
                        self.db.add(mapping)
                        updated += 1
                    else:
                        # New employee — create
                        employee = Employee(
                            tenant_id=self.server.tenant_id,
                            employee_code=code,
                            first_name=first_name,
                            last_name=last_name,
                            status="active",
                        )
                        self.db.add(employee)
                        await self.db.flush()

                        mapping = EsslEmployeeMapping(
                            tenant_id=self.server.tenant_id,
                            essl_server_id=self.server.id,
                            employee_code=code,
                            employee_id=employee.id,
                        )
                        self.db.add(mapping)
                        created += 1

                except Exception as e:
                    self._log_error(history, "employee", code, str(e))
                    failed += 1

            # Step 5: Apply conflict policy for local employees NOT in eSSL
            for code, mapping in this_server_mappings.items():
                if code not in essl_codes:
                    await self._resolve_conflict("employee", mapping.employee_id, history)

            # Finalize
            history.status = SyncStatus.COMPLETED if failed == 0 else SyncStatus.PARTIAL
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            history.records_created = created
            history.records_updated = updated
            history.records_skipped = skipped
            history.records_failed = failed
            await self.db.commit()

            # Update cursor
            await self._update_cursor("employees")

        except Exception as e:
            history.status = SyncStatus.FAILED
            history.error_message = str(e)
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            await self.db.commit()
            logger.error("essl_employee_sync_failed", server_id=str(self.server.id), error=str(e))

        return history

    # ------------------------------------------------------------------
    # ATTENDANCE SYNC (Bulk via GetDeviceLogs + cursor)
    # ------------------------------------------------------------------

    async def sync_attendance(self, triggered_by: str = "auto") -> EsslSyncHistory:
        """Attendance sync — bulk-first, cursor-based.
        
        Strategy: Use GetDeviceLogs for bulk fetching (one call per device).
        Only fall back to per-employee GetEmployeePunchLogs if bulk API fails.
        """
        history = EsslSyncHistory(
            tenant_id=self.server.tenant_id,
            essl_server_id=self.server.id,
            sync_type=SyncType.ATTENDANCE,
            status=SyncStatus.RUNNING,
            triggered_by=triggered_by,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)

        try:
            # Load cursor
            cursor = await self._get_cursor("attendance")
            from_time = cursor.last_punch_time if cursor else None

            # Load device mappings for bulk fetch
            dev_mappings_stmt = select(EsslDeviceMapping).where(
                EsslDeviceMapping.essl_server_id == self.server.id
            )
            dev_result = await self.db.execute(dev_mappings_stmt)
            device_mappings = {m.serial_number: m for m in dev_result.scalars().all()}

            # Load employee mappings
            emp_mappings_stmt = select(EsslEmployeeMapping).where(
                EsslEmployeeMapping.essl_server_id == self.server.id
            )
            emp_result = await self.db.execute(emp_mappings_stmt)
            employee_mappings = {m.employee_code: m for m in emp_result.scalars().all()}

            created = 0
            skipped = 0
            failed = 0
            max_punch_time = from_time

            # Strategy 1: Bulk fetch via GetDeviceLogs (one call per device)
            bulk_success = False
            if device_mappings:
                for serial, dev_mapping in device_mappings.items():
                    try:
                        from_str = from_time.strftime("%Y-%m-%d %H:%M:%S") if from_time else ""
                        to_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")

                        logs_result = await self.client.soap.get_device_logs(serial, from_str, to_str)
                        if not logs_result.get("success"):
                            continue

                        bulk_success = True
                        raw_logs = logs_result.get("data", [])
                        # Handle paginated response format: {"items": [...], "total": N}
                        if isinstance(raw_logs, dict) and "items" in raw_logs:
                            raw_logs = raw_logs["items"]
                        elif isinstance(raw_logs, dict):
                            raw_logs = [raw_logs]

                        for log in raw_logs:
                            if not isinstance(log, dict):
                                continue

                            emp_code = log.get("EmployeeCode") or log.get("employee_code") or log.get("EnrollNumber")
                            punch_time_str = log.get("PunchTime") or log.get("punch_time") or log.get("DateTime")
                            punch_type = log.get("PunchType") or log.get("punch_type") or log.get("Direction")

                            if not emp_code or not punch_time_str:
                                continue

                            emp_code = str(emp_code).strip()
                            punch_time = self._parse_datetime(str(punch_time_str), self.server.timezone)
                            if not punch_time:
                                continue

                            if max_punch_time is None or punch_time > max_punch_time:
                                max_punch_time = punch_time

                            emp_mapping = employee_mappings.get(emp_code)

                            raw_log = AttendanceRawLog(
                                tenant_id=self.server.tenant_id,
                                essl_server_id=self.server.id,
                                employee_code=emp_code,
                                employee_id=emp_mapping.employee_id if emp_mapping else None,
                                device_serial=serial,
                                device_id=dev_mapping.device_id,
                                punch_time=punch_time,
                                punch_type=str(punch_type).lower() if punch_type else None,
                                raw_data=log,
                                processed=False,
                            )
                            self.db.add(raw_log)
                            try:
                                await self.db.flush()
                                created += 1
                            except Exception:
                                await self.db.rollback()
                                skipped += 1

                    except Exception as e:
                        self._log_error(history, "device_logs", serial, str(e))
                        failed += 1

            # Strategy 2: Fallback to per-employee GetEmployeePunchLogs
            print(f"[SYNC] Strategy 2: bulk_success={bulk_success}, employee_mappings={len(employee_mappings)}, device_mappings={len(device_mappings)}")
            if not bulk_success:
                history.date_range_from = from_time or (datetime.now(timezone.utc) - timedelta(days=1))
                history.date_range_to = datetime.now(timezone.utc)

                for emp_code, emp_mapping in employee_mappings.items():
                    try:
                        print(f"[SYNC] Processing {emp_code}...")
                        from_str = (from_time or (datetime.now(timezone.utc) - timedelta(days=1))).strftime("%Y-%m-%d")
                        to_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")

                        punch_result = await self.client.get_employee_punch_logs(
                            emp_code, from_str, to_str, bypass_cache=True
                        )
                        print(f"[SYNC] {emp_code}: success={punch_result.get('success')}, data_type={type(punch_result.get('data')).__name__}, data={str(punch_result.get('data'))[:200]}")
                        if not punch_result.get("success"):
                            self._log_error(history, "punch_log", emp_code, punch_result.get("error", "Failed"))
                            failed += 1
                            continue

                        punches = punch_result.get("data", [])
                        # Handle paginated response format: {"items": [...], "total": N}
                        if isinstance(punches, dict) and "items" in punches:
                            punches = punches["items"]
                        elif isinstance(punches, dict):
                            punches = [punches]

                        print(f"[SYNC] {emp_code}: got {len(punches)} punches, type={type(punches[0]).__name__ if punches else 'empty'}")

                        for punch in punches:
                            # Convert Pydantic model to dict if needed
                            if hasattr(punch, 'model_dump'):
                                punch = punch.model_dump()
                            if not isinstance(punch, dict):
                                continue

                            pt_str = punch.get("punch_time") or punch.get("PunchTime") or punch.get("DateTime")
                            pt_type = punch.get("punch_type") or punch.get("PunchType") or punch.get("Direction")
                            dev_serial = punch.get("device_serial") or punch.get("DeviceSerialNumber")

                            if not pt_str:
                                logger.info("skipped_no_pt_str", emp_code=emp_code, punch_keys=list(punch.keys()))
                                continue

                            punch_time = self._parse_datetime(str(pt_str), self.server.timezone)
                            if not punch_time:
                                print(f"[SYNC] {emp_code}: parse failed for '{pt_str}'")
                                continue

                            if max_punch_time is None or punch_time > max_punch_time:
                                max_punch_time = punch_time

                            dev_mapping = device_mappings.get(str(dev_serial).strip()) if dev_serial else None

                            # Convert raw_data datetime objects to strings for JSONB
                            raw_data = {}
                            for k, v in punch.items():
                                if isinstance(v, datetime):
                                    raw_data[k] = v.isoformat()
                                else:
                                    raw_data[k] = v

                            raw_log = AttendanceRawLog(
                                tenant_id=self.server.tenant_id,
                                essl_server_id=self.server.id,
                                employee_code=emp_code,
                                employee_id=emp_mapping.employee_id if emp_mapping else None,
                                device_serial=str(dev_serial).strip() if dev_serial else None,
                                device_id=dev_mapping.device_id if dev_mapping else None,
                                punch_time=punch_time,
                                punch_type=str(pt_type).lower() if pt_type else None,
                                raw_data=raw_data,
                                processed=False,
                            )
                            self.db.add(raw_log)
                            try:
                                async with self.db.begin_nested():
                                    await self.db.flush()
                                created += 1
                            except Exception as flush_err:
                                print(f"[SYNC] {emp_code}: flush failed: {flush_err}")
                                skipped += 1

                    except Exception as e:
                        print(f"[SYNC] {emp_code}: EXCEPTION: {e}")
                        self._log_error(history, "punch_log", emp_code, str(e))
                        failed += 1

            # Update cursor
            if max_punch_time:
                await self._update_cursor("attendance", last_punch_time=max_punch_time)

            # Process raw logs into attendance records
            from app.services.attendance_processor import AttendanceProcessor
            processor = AttendanceProcessor(self.db)
            processing_result = await processor.process_raw_logs(self.server.tenant_id)
            attendance_created = processing_result.get("created", 0)
            attendance_updated = processing_result.get("updated", 0)
            processing_errors = processing_result.get("errors", 0)

            # Finalize
            history.status = SyncStatus.COMPLETED if (failed == 0 and processing_errors == 0) else SyncStatus.PARTIAL
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            history.records_fetched = created + skipped + failed
            history.records_created = attendance_created
            history.records_updated = attendance_updated
            history.records_skipped = skipped
            history.records_failed = failed + processing_errors
            await self.db.commit()

        except Exception as e:
            history.status = SyncStatus.FAILED
            history.error_message = str(e)
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            await self.db.commit()
            logger.error("essl_attendance_sync_failed", server_id=str(self.server.id), error=str(e))

        return history

    async def sync_attendance_incremental(self) -> EsslSyncHistory:
        """Incremental sync — uses cursor, only fetches new data."""
        return await self.sync_attendance(triggered_by="auto")

    # ------------------------------------------------------------------
    # DEVICE SYNC
    # ------------------------------------------------------------------

    async def sync_devices(self, triggered_by: str = "auto") -> EsslSyncHistory:
        """Device sync pipeline — MULTI-SERVER SAFE.
        Handles device migration between servers.
        """
        history = EsslSyncHistory(
            tenant_id=self.server.tenant_id,
            essl_server_id=self.server.id,
            sync_type=SyncType.DEVICES,
            status=SyncStatus.RUNNING,
            triggered_by=triggered_by,
        )
        self.db.add(history)
        await self.db.commit()
        await self.db.refresh(history)

        try:
            locations = await self._get_active_locations()
            all_essl_devices = []

            for loc in (locations or [""]):
                devices_result = await self.client.get_devices(bypass_cache=True, location=loc)
                if not devices_result.get("success"):
                    raise Exception(f"GetDeviceList failed for location '{loc}': {devices_result.get('error')}")
                batch = devices_result.get("data", [])
                # Handle paginated response format: {"items": [...], "total": N}
                if isinstance(batch, dict) and "items" in batch:
                    batch = batch["items"]
                elif isinstance(batch, dict):
                    batch = [batch]
                # Convert Pydantic models to dicts, skip strings
                for d in batch:
                    if isinstance(d, str):
                        continue
                    if hasattr(d, 'model_dump'):
                        all_essl_devices.append(d.model_dump())
                    elif isinstance(d, dict):
                        all_essl_devices.append(d)

            essl_devices = all_essl_devices
            logger.info("essl_devices_parsed", count=len(essl_devices), types=[type(d).__name__ for d in essl_devices[:3]])

            history.records_fetched = len(essl_devices)

            # Load ALL mappings for this tenant (not just this server)
            all_mappings_stmt = select(EsslDeviceMapping).where(
                EsslDeviceMapping.tenant_id == self.server.tenant_id
            )
            all_mappings_result = await self.db.execute(all_mappings_stmt)
            all_mappings = all_mappings_result.scalars().all()

            # Build lookup: serial_number -> device_id (from any server)
            serial_to_device_id = {}
            this_server_mappings = {}
            for m in all_mappings:
                serial_to_device_id[m.serial_number] = m.device_id
                if m.essl_server_id == self.server.id:
                    this_server_mappings[m.serial_number] = m

            # Load all devices for this tenant by serial
            existing_devices_stmt = select(Device).where(
                Device.tenant_id == self.server.tenant_id
            )
            existing_devices_result = await self.db.execute(existing_devices_stmt)
            devices_by_serial = {d.serial_number: d for d in existing_devices_result.scalars().all()}

            essl_serials = set()
            created = 0
            updated = 0

            for dev_data in essl_devices:
                if not isinstance(dev_data, dict):
                    continue

                serial = str(dev_data.get("serial_number", "")).strip()
                if not serial:
                    continue

                essl_serials.add(serial)

                # Get last ping
                ping_result = await self.client.get_device_last_ping(serial)
                last_ping = None
                if ping_result.get("success"):
                    ping_data = ping_result.get("data", {})
                    last_ping_str = ping_data.get("last_ping") or ping_data.get("LastPing")
                    if last_ping_str:
                        last_ping = self._parse_datetime(str(last_ping_str), self.server.timezone)

                status = DeviceStatus.ONLINE if last_ping and (datetime.now(timezone.utc) - last_ping).total_seconds() < 300 else DeviceStatus.OFFLINE

                if serial in this_server_mappings:
                    # Already mapped to this server — update
                    mapping = this_server_mappings[serial]
                    device = devices_by_serial.get(serial)
                    if device:
                        device.device_name = dev_data.get("device_name", device.device_name)
                        device.location = dev_data.get("location", device.location)
                        device.firmware_version = dev_data.get("firmware_version", device.firmware_version)
                        device.ip_address = dev_data.get("ip_address", device.ip_address)
                        device.last_ping = last_ping
                        device.last_sync = datetime.now(timezone.utc)
                        device.status = status.value
                        mapping.synced_at = datetime.now(timezone.utc)
                        updated += 1
                elif serial in serial_to_device_id:
                    # Device exists on ANOTHER server — add mapping for this server (migration)
                    existing_device_id = serial_to_device_id[serial]
                    mapping = EsslDeviceMapping(
                        tenant_id=self.server.tenant_id,
                        essl_server_id=self.server.id,
                        serial_number=serial,
                        device_id=existing_device_id,
                    )
                    self.db.add(mapping)
                    updated += 1
                elif serial in devices_by_serial:
                    # Device exists locally but no mapping — add mapping
                    device = devices_by_serial[serial]
                    mapping = EsslDeviceMapping(
                        tenant_id=self.server.tenant_id,
                        essl_server_id=self.server.id,
                        serial_number=serial,
                        device_id=device.id,
                    )
                    self.db.add(mapping)
                    updated += 1
                else:
                    # New device — create
                    device = Device(
                        tenant_id=self.server.tenant_id,
                        serial_number=serial,
                        device_name=dev_data.get("device_name", f"Device {serial}"),
                        model=dev_data.get("model"),
                        firmware_version=dev_data.get("firmware_version"),
                        ip_address=dev_data.get("ip_address"),
                        location=dev_data.get("location"),
                        status=status.value,
                        last_ping=last_ping,
                        last_sync=datetime.now(timezone.utc),
                        is_active=True,
                    )
                    self.db.add(device)
                    await self.db.flush()

                    mapping = EsslDeviceMapping(
                        tenant_id=self.server.tenant_id,
                        essl_server_id=self.server.id,
                        serial_number=serial,
                        device_id=device.id,
                    )
                    self.db.add(mapping)
                    created += 1

            # Apply conflict policy for local devices NOT in eSSL
            for serial, mapping in this_server_mappings.items():
                if serial not in essl_serials:
                    await self._resolve_conflict("device", mapping.device_id, history)

            history.status = SyncStatus.COMPLETED
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            history.records_created = created
            history.records_updated = updated
            await self.db.commit()

            await self._update_cursor("devices")

        except Exception as e:
            history.status = SyncStatus.FAILED
            history.error_message = str(e)
            history.completed_at = datetime.now(timezone.utc)
            history.duration_seconds = (history.completed_at - history.started_at).total_seconds()
            await self.db.commit()
            logger.error("essl_device_sync_failed", server_id=str(self.server.id), error=str(e))

        return history

    # ------------------------------------------------------------------
    # CONFLICT RESOLUTION
    # ------------------------------------------------------------------

    async def _resolve_conflict(self, entity_type: str, local_id: uuid.UUID, history: EsslSyncHistory):
        """Handle entity that exists locally but not in eSSL."""
        if entity_type == "employee":
            policy = self.server.employee_conflict_policy
            stmt = select(Employee).where(Employee.id == local_id)
        else:
            policy = self.server.device_conflict_policy
            stmt = select(Device).where(Device.id == local_id)

        result = await self.db.execute(stmt)
        entity = result.scalar_one_or_none()
        if not entity:
            return

        if policy == ConflictPolicy.IGNORE:
            pass
        elif policy == ConflictPolicy.DISABLE:
            entity.status = "inactive" if entity_type == "employee" else DeviceStatus.INACTIVE.value
            if hasattr(entity, "is_active"):
                entity.is_active = False
        elif policy == ConflictPolicy.SOFT_DELETE:
            entity.status = "terminated" if entity_type == "employee" else DeviceStatus.INACTIVE.value
            if hasattr(entity, "is_active"):
                entity.is_active = False
        elif policy == ConflictPolicy.HARD_DELETE:
            await self.db.delete(entity)

    # ------------------------------------------------------------------
    # CURSOR MANAGEMENT
    # ------------------------------------------------------------------

    async def _get_cursor(self, cursor_type: str) -> Optional[EsslSyncCursor]:
        stmt = select(EsslSyncCursor).where(
            EsslSyncCursor.essl_server_id == self.server.id,
            EsslSyncCursor.cursor_type == cursor_type,
        )
        result = await self.db.execute(stmt)
        return result.scalar_one_or_none()

    async def _update_cursor(self, cursor_type: str, last_punch_time: Optional[datetime] = None):
        cursor = await self._get_cursor(cursor_type)
        now = datetime.now(timezone.utc)

        if not cursor:
            cursor = EsslSyncCursor(
                tenant_id=self.server.tenant_id,
                essl_server_id=self.server.id,
                cursor_type=cursor_type,
            )
            self.db.add(cursor)

        if cursor_type == "attendance" and last_punch_time:
            cursor.last_punch_time = last_punch_time
        elif cursor_type == "employees":
            cursor.last_employee_sync = now
        elif cursor_type == "devices":
            cursor.last_device_sync = now

        cursor.updated_at = now
        await self.db.commit()

    # ------------------------------------------------------------------
    # CLOCK DRIFT DETECTION
    # ------------------------------------------------------------------

    async def detect_clock_drift(self) -> Dict[str, Any]:
        """Detect clock drift across devices by comparing punch times.

        Returns devices with suspicious time differences between consecutive
        punches that suggest clock skew (e.g., punches appearing in the future
        or large gaps inconsistent with shift patterns).
        """
        from app.models.essl_mapping import EsslDeviceMapping
        from app.models.attendance import AttendanceRawLog

        now = datetime.now(timezone.utc)
        threshold_minutes = 30

        # Get all devices mapped to this server
        dev_stmt = select(EsslDeviceMapping).where(
            EsslDeviceMapping.essl_server_id == self.server.id,
        )
        dev_result = await self.db.execute(dev_stmt)
        devices = list(dev_result.scalars().all())

        drift_report = []
        for dev_map in devices:
            # Get recent punches from this device
            punch_stmt = (
                select(AttendanceRawLog)
                .where(
                    AttendanceRawLog.essl_server_id == self.server.id,
                    AttendanceRawLog.device_serial == dev_map.serial_number,
                    AttendanceRawLog.punch_time >= now - timedelta(days=7),
                )
                .order_by(AttendanceRawLog.punch_time.desc())
                .limit(100)
            )
            punch_result = await self.db.execute(punch_stmt)
            punches = list(punch_result.scalars().all())

            if len(punches) < 2:
                continue

            # Check for future timestamps
            future_count = sum(1 for p in punches if p.punch_time > now + timedelta(minutes=5))

            # Check for large gaps between consecutive punches
            large_gaps = 0
            for i in range(len(punches) - 1):
                gap = abs((punches[i].punch_time - punches[i + 1].punch_time).total_seconds() / 60)
                if gap > 480:  # More than 8 hours between consecutive punches
                    large_gaps += 1

            # Check for time reversals (punch N+1 before punch N)
            reversals = 0
            sorted_punches = sorted(punches, key=lambda p: p.punch_time)
            for i in range(len(sorted_punches) - 1):
                if sorted_punches[i].punch_time > sorted_punches[i + 1].punch_time:
                    reversals += 1

            if future_count > 0 or large_gaps > 3 or reversals > 0:
                drift_report.append({
                    "device_serial": dev_map.serial_number,
                    "device_id": str(dev_map.device_id),
                    "future_punches": future_count,
                    "large_gaps": large_gaps,
                    "time_reversals": reversals,
                    "sample_count": len(punches),
                    "latest_punch": punches[0].punch_time.isoformat() if punches else None,
                })

        return {
            "server_id": str(self.server.id),
            "server_name": self.server.name,
            "server_timezone": self.server.timezone,
            "devices_checked": len(devices),
            "devices_with_drift": len(drift_report),
            "drift_details": drift_report,
        }

    # ------------------------------------------------------------------
    # HELPERS
    # ------------------------------------------------------------------

    def _log_error(self, history: EsslSyncHistory, entity_type: str, entity_id: str, error: str):
        err = EsslSyncError(
            tenant_id=self.server.tenant_id,
            sync_history_id=history.id,
            error_message=error,
            entity_type=entity_type,
            entity_identifier=entity_id,
        )
        self.db.add(err)

    @staticmethod
    def _parse_datetime(val: str, server_timezone: str = "UTC") -> Optional[datetime]:
        """Parse a datetime string from the eSSL device.
        
        Stores times as-is (naive) without timezone conversion.
        The eBioserver and VPS are in the same timezone (IST),
        so no conversion is needed.
        """
        if not val:
            return None

        # Try parsing as ISO 8601
        try:
            dt = datetime.fromisoformat(val.replace("Z", "+00:00"))
            # Strip timezone info to store as naive
            return dt.replace(tzinfo=None)
        except Exception:
            pass

        # Try common formats
        for fmt in ("%Y-%m-%d %H:%M:%S", "%Y-%m-%dT%H:%M:%S", "%Y-%m-%dT%H:%M:%S.%f", "%m/%d/%Y %H:%M:%S"):
            try:
                return datetime.strptime(val, fmt)
            except ValueError:
                continue
        return None
