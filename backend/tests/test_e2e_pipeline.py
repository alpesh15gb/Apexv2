"""End-to-end integration tests for the eSSL connector pipeline.

Tests the full flow: raw logs → processing → attendance records,
including timezone handling, reprocessing, and audit logging.
"""

import uuid
from datetime import date, datetime, time, timezone, timedelta

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.models.employee import Employee, Department, Branch
from app.models.shift import Shift, ShiftSchedule
from app.models.attendance import Attendance, AttendanceRawLog
from app.models.audit_log import AuditLog
from app.models.essl_server import EsslServer
from app.services.attendance_processor import AttendanceProcessor
from app.services.sync_audit import SyncAuditService


@pytest_asyncio.fixture
async def essl_server(db_session: AsyncSession, test_tenant):
    """Create a test eSSL server."""
    server = EsslServer(
        tenant_id=test_tenant.id,
        name="Test eSSL Server",
        server_url="http://localhost:8080/essl",
        username="admin",
        password_encrypted="encrypted_test",
        timeout_seconds=30,
        timezone="Asia/Kolkata",
        auto_sync_enabled=True,
        attendance_sync_interval_minutes=5,
        device_sync_interval_minutes=60,
        employee_sync_hour=2,
        status="connected",
    )
    db_session.add(server)
    await db_session.flush()
    return server


@pytest_asyncio.fixture
async def setup_employees(db_session: AsyncSession, test_tenant, test_department, test_branch, test_shift):
    """Create a set of test employees with shift assignments."""
    employees = []
    for i in range(10):
        emp = Employee(
            tenant_id=test_tenant.id,
            employee_code=f"E2E{i:04d}",
            first_name=f"Test",
            last_name=f"Employee {i}",
            email=f"e2e{i}@test.com",
            department_id=test_department.id,
            branch_id=test_branch.id,
            shift_id=test_shift.id,
            joining_date=date(2024, 1, 1),
            status="active",
        )
        db_session.add(emp)
        employees.append(emp)
    await db_session.flush()

    for emp in employees:
        sched = ShiftSchedule(
            tenant_id=test_tenant.id,
            employee_id=emp.id,
            shift_id=test_shift.id,
            effective_from=date(2024, 1, 1),
        )
        db_session.add(sched)
    await db_session.flush()

    return employees


class TestFullPipelineE2E:
    """End-to-end tests for the attendance processing pipeline."""

    @pytest.mark.asyncio
    async def test_single_employee_full_day(
        self, db_session: AsyncSession, test_tenant, setup_employees, test_shift
    ):
        """Single employee: punch in at 9:00, punch out at 18:00 → PRESENT."""
        emp = setup_employees[0]
        target_date = date.today() - timedelta(days=1)

        # Create raw logs
        for ptype, ptime in [("in", time(9, 0)), ("out", time(18, 0))]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(target_date, ptime).replace(tzinfo=timezone.utc),
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        result = await processor.process_raw_logs(test_tenant.id, target_date)

        assert result["processed"] == 2
        assert result["created"] == 1
        assert result["errors"] == 0

        # Verify attendance record
        att = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one_or_none()

        assert att is not None
        assert att.status == "present"
        assert att.total_hours is not None
        assert att.total_hours >= 8.0
        assert att.punch_in is not None
        assert att.punch_out is not None

    @pytest.mark.asyncio
    async def test_late_arrival(
        self, db_session: AsyncSession, test_tenant, setup_employees, test_shift
    ):
        """Employee punches in at 9:20 (after grace period) → LATE."""
        emp = setup_employees[1]
        target_date = date.today() - timedelta(days=1)

        for ptype, ptime in [("in", time(9, 20)), ("out", time(18, 0))]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(target_date, ptime).replace(tzinfo=timezone.utc),
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        result = await processor.process_raw_logs(test_tenant.id, target_date)

        att = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one_or_none()

        assert att is not None
        assert att.is_late is True
        assert att.late_minutes > 0

    @pytest.mark.asyncio
    async def test_half_day(
        self, db_session: AsyncSession, test_tenant, setup_employees
    ):
        """Employee works only 5 hours → HALF_DAY."""
        emp = setup_employees[2]
        target_date = date.today() - timedelta(days=1)

        for ptype, ptime in [("in", time(9, 0)), ("out", time(14, 0))]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(target_date, ptime).replace(tzinfo=timezone.utc),
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        await processor.process_raw_logs(test_tenant.id, target_date)

        att = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one_or_none()

        assert att is not None
        assert att.status == "half_day"

    @pytest.mark.asyncio
    async def test_no_punch_out(
        self, db_session: AsyncSession, test_tenant, setup_employees
    ):
        """Employee only punches in → HALF_DAY with 0 hours."""
        emp = setup_employees[3]
        target_date = date.today() - timedelta(days=1)

        raw = AttendanceRawLog(
            tenant_id=test_tenant.id,
            employee_code=emp.employee_code,
            employee_id=emp.id,
            punch_time=datetime.combine(target_date, time(9, 0)).replace(tzinfo=timezone.utc),
            punch_type="in",
            processed=False,
        )
        db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        await processor.process_raw_logs(test_tenant.id, target_date)

        att = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one_or_none()

        assert att is not None
        assert att.status == "half_day"
        assert att.total_hours == 0.0

    @pytest.mark.asyncio
    async def test_multi_day_processing(
        self, db_session: AsyncSession, test_tenant, setup_employees
    ):
        """Process 5 days of raw logs for 10 employees."""
        employees = setup_employees
        base_date = date.today() - timedelta(days=5)

        for emp in employees:
            for day_offset in range(5):
                punch_date = base_date + timedelta(days=day_offset)
                for ptype, ptime in [("in", time(9, 0)), ("out", time(18, 0))]:
                    raw = AttendanceRawLog(
                        tenant_id=test_tenant.id,
                        employee_code=emp.employee_code,
                        employee_id=emp.id,
                        punch_time=datetime.combine(punch_date, ptime).replace(tzinfo=timezone.utc),
                        punch_type=ptype,
                        processed=False,
                    )
                    db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        result = await processor.process_raw_logs(test_tenant.id)

        assert result["processed"] == 200  # 10 employees × 5 days × 2 punches
        assert result["created"] == 50  # 10 employees × 5 days
        assert result["errors"] == 0

    @pytest.mark.asyncio
    async def test_reprocess_preserves_data_integrity(
        self, db_session: AsyncSession, test_tenant, setup_employees
    ):
        """Reprocessing should reset and recreate attendance records correctly."""
        emp = setup_employees[4]
        target_date = date.today() - timedelta(days=1)

        # Initial raw logs
        for ptype, ptime in [("in", time(9, 0)), ("out", time(18, 0))]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(target_date, ptime).replace(tzinfo=timezone.utc),
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        await processor.process_raw_logs(test_tenant.id, target_date)

        # Verify created
        att_before = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one()
        assert att_before.status == "present"

        # Add corrected punch times
        for ptype, ptime in [("in", time(8, 55)), ("out", time(18, 10))]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(target_date, ptime).replace(tzinfo=timezone.utc),
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        # Reprocess
        result = await processor.reprocess(
            tenant_id=test_tenant.id,
            from_date=target_date,
            to_date=target_date,
        )

        assert result["reset"] > 0
        assert result["processed"] > 0

        # Verify updated
        att_after = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one()
        assert att_after.status == "present"

        # Only one record should exist
        count = (await db_session.execute(
            select(func.count(Attendance.id)).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar()
        assert count == 1


class TestSyncAuditE2E:
    """End-to-end tests for sync audit logging."""

    @pytest.mark.asyncio
    async def test_sync_audit_lifecycle(
        self, db_session: AsyncSession, test_tenant, test_user, essl_server
    ):
        """Full audit lifecycle: start → complete → verify audit entries."""
        audit = SyncAuditService(db_session)

        # Log sync started
        await audit.log_sync_started(
            tenant_id=test_tenant.id,
            server_id=essl_server.id,
            server_name=essl_server.name,
            sync_type="attendance",
            triggered_by="manual",
            user_id=test_user.id,
        )

        # Log sync completed
        await audit.log_sync_completed(
            tenant_id=test_tenant.id,
            server_id=essl_server.id,
            server_name=essl_server.name,
            sync_type="attendance",
            status="completed",
            records_fetched=100,
            records_created=50,
            records_updated=30,
            records_failed=2,
            duration_seconds=15.5,
            user_id=test_user.id,
        )
        await db_session.flush()

        # Verify audit entries
        entries = (await db_session.execute(
            select(AuditLog).where(
                AuditLog.tenant_id == test_tenant.id,
                AuditLog.resource_type == "essl_sync",
            ).order_by(AuditLog.created_at)
        )).scalars().all()

        assert len(entries) == 2
        assert entries[0].action == "sync_started"
        assert entries[1].action == "sync_completed"
        assert entries[1].new_values["records_fetched"] == 100
        assert entries[1].new_values["records_created"] == 50

    @pytest.mark.asyncio
    async def test_reprocess_audit(
        self, db_session: AsyncSession, test_tenant, test_user, essl_server
    ):
        """Verify reprocess operations are audited."""
        audit = SyncAuditService(db_session)

        await audit.log_reprocess(
            tenant_id=test_tenant.id,
            server_id=essl_server.id,
            result={"processed": 100, "created": 50, "updated": 30, "errors": 0, "reset": 80},
            from_date="2024-06-01",
            to_date="2024-06-30",
            user_id=test_user.id,
        )
        await db_session.flush()

        entry = (await db_session.execute(
            select(AuditLog).where(
                AuditLog.tenant_id == test_tenant.id,
                AuditLog.action == "attendance_reprocess",
            )
        )).scalar_one_or_none()

        assert entry is not None
        assert entry.new_values["from_date"] == "2024-06-01"
        assert entry.new_values["result"]["processed"] == 100

    @pytest.mark.asyncio
    async def test_server_config_change_audit(
        self, db_session: AsyncSession, test_tenant, test_user, essl_server
    ):
        """Verify server config changes are audited."""
        audit = SyncAuditService(db_session)

        await audit.log_server_config_change(
            tenant_id=test_tenant.id,
            server_id=essl_server.id,
            action="essl_server_updated",
            old_values={"attendance_sync_interval_minutes": 5},
            new_values={"attendance_sync_interval_minutes": 10},
            user_id=test_user.id,
        )
        await db_session.flush()

        entry = (await db_session.execute(
            select(AuditLog).where(
                AuditLog.tenant_id == test_tenant.id,
                AuditLog.action == "essl_server_updated",
            )
        )).scalar_one_or_none()

        assert entry is not None
        assert entry.old_values["attendance_sync_interval_minutes"] == 5
        assert entry.new_values["attendance_sync_interval_minutes"] == 10


class TestTimezonePipelineE2E:
    """End-to-end tests for timezone-aware processing."""

    @pytest.mark.asyncio
    async def test_ist_punch_times_processed_correctly(
        self, db_session: AsyncSession, test_tenant, setup_employees, test_shift
    ):
        """Punch times stored as IST-converted UTC should produce correct attendance."""
        emp = setup_employees[5]
        target_date = date.today() - timedelta(days=1)

        # Simulate IST punch times converted to UTC
        # 09:00 IST = 03:30 UTC, 18:00 IST = 12:30 UTC
        punch_in_utc = datetime.combine(target_date, time(3, 30)).replace(tzinfo=timezone.utc)
        punch_out_utc = datetime.combine(target_date, time(12, 30)).replace(tzinfo=timezone.utc)

        for ptype, ptime in [("in", punch_in_utc), ("out", punch_out_utc)]:
            raw = AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=ptime,
                punch_type=ptype,
                processed=False,
            )
            db_session.add(raw)
        await db_session.flush()

        processor = AttendanceProcessor(db_session)
        result = await processor.process_raw_logs(test_tenant.id, target_date)

        assert result["created"] == 1

        att = (await db_session.execute(
            select(Attendance).where(
                Attendance.tenant_id == test_tenant.id,
                Attendance.employee_id == emp.id,
                Attendance.date == target_date,
            )
        )).scalar_one()

        assert att.total_hours is not None
        assert 8.0 <= att.total_hours <= 10.0
