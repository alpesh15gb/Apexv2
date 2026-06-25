"""Stress and load tests for attendance processing and eSSL sync."""

import uuid
from datetime import date, datetime, time, timezone, timedelta

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.employee import Employee
from app.models.attendance import Attendance, AttendanceRawLog
from app.models.shift import Shift, ShiftSchedule
from app.services.attendance_processor import AttendanceProcessor


@pytest.fixture
def bulk_employees(test_tenant, test_department, test_branch, test_shift):
    """Generate 500 employee objects for stress testing."""
    employees = []
    for i in range(500):
        emp = Employee(
            tenant_id=test_tenant.id,
            employee_code=f"EMP{i:05d}",
            first_name=f"Employee",
            last_name=f"{i:05d}",
            email=f"emp{i}@test.com",
            department_id=test_department.id,
            branch_id=test_branch.id,
            shift_id=test_shift.id,
            joining_date=date(2024, 1, 1),
            status="active",
        )
        employees.append(emp)
    return employees


@pytest.mark.asyncio
async def test_bulk_raw_log_processing(db_session: AsyncSession, test_tenant, test_shift):
    """Process 10,000 raw logs across 500 employees — must complete in <30s."""
    # Create employees
    employees = []
    for i in range(500):
        emp = Employee(
            tenant_id=test_tenant.id,
            employee_code=f"BULK{i:05d}",
            first_name=f"Bulk",
            last_name=f"User {i}",
            email=f"bulk{i}@test.com",
            joining_date=date(2024, 1, 1),
            status="active",
        )
        db_session.add(emp)
        employees.append(emp)
    await db_session.flush()

    # Assign shift
    for emp in employees:
        sched = ShiftSchedule(
            tenant_id=test_tenant.id,
            employee_id=emp.id,
            shift_id=test_shift.id,
            effective_from=date(2024, 1, 1),
        )
        db_session.add(sched)
    await db_session.flush()

    # Create 10,000 raw logs (20 per employee — 10 days × 2 punches)
    target_date = date.today() - timedelta(days=10)
    raw_logs = []
    for emp in employees:
        for day_offset in range(10):
            punch_date = target_date + timedelta(days=day_offset)
            # Punch in
            raw_logs.append(AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(punch_date, time(9, 0)).replace(tzinfo=timezone.utc),
                punch_type="in",
                processed=False,
            ))
            # Punch out
            raw_logs.append(AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(punch_date, time(18, 0)).replace(tzinfo=timezone.utc),
                punch_type="out",
                processed=False,
            ))

    db_session.add_all(raw_logs)
    await db_session.flush()

    # Process
    import time as time_mod
    start = time_mod.monotonic()

    processor = AttendanceProcessor(db_session)
    result = await processor.process_raw_logs(test_tenant.id)

    elapsed = time_mod.monotonic() - start

    assert result["processed"] == 10000
    assert result["errors"] == 0
    assert elapsed < 30.0, f"Processing took {elapsed:.1f}s, expected <30s"


@pytest.mark.asyncio
async def test_bulk_raw_log_creation_performance(db_session: AsyncSession, test_tenant):
    """Create 5,000 raw logs in bulk — must complete in <5s."""
    import time as time_mod

    raw_logs = []
    for i in range(5000):
        raw_logs.append(AttendanceRawLog(
            tenant_id=test_tenant.id,
            employee_code=f"PERF{i:05d}",
            punch_time=datetime.now(timezone.utc) - timedelta(hours=i % 24),
            punch_type="in" if i % 2 == 0 else "out",
            processed=False,
        ))

    start = time_mod.monotonic()
    db_session.add_all(raw_logs)
    await db_session.flush()
    elapsed = time_mod.monotonic() - start

    assert elapsed < 5.0, f"Bulk insert took {elapsed:.1f}s, expected <5s"


@pytest.mark.asyncio
async def test_reprocess_with_large_dataset(db_session: AsyncSession, test_tenant, test_shift):
    """Reprocess 5,000 raw logs — must complete in <20s."""
    # Create employees
    employees = []
    for i in range(100):
        emp = Employee(
            tenant_id=test_tenant.id,
            employee_code=f"REPRO{i:05d}",
            first_name=f"Reprocess",
            last_name=f"User {i}",
            email=f"repro{i}@test.com",
            joining_date=date(2024, 1, 1),
            status="active",
        )
        db_session.add(emp)
        employees.append(emp)
    await db_session.flush()

    # Assign shifts
    for emp in employees:
        sched = ShiftSchedule(
            tenant_id=test_tenant.id,
            employee_id=emp.id,
            shift_id=test_shift.id,
            effective_from=date(2024, 1, 1),
        )
        db_session.add(sched)
    await db_session.flush()

    # Create 5000 raw logs (50 per employee)
    target_date = date.today() - timedelta(days=25)
    raw_logs = []
    for emp in employees:
        for day_offset in range(25):
            punch_date = target_date + timedelta(days=day_offset)
            raw_logs.append(AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(punch_date, time(9, 0)).replace(tzinfo=timezone.utc),
                punch_type="in",
                processed=True,
                processed_at=datetime.now(timezone.utc),
            ))
            raw_logs.append(AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=emp.employee_code,
                employee_id=emp.id,
                punch_time=datetime.combine(punch_date, time(18, 0)).replace(tzinfo=timezone.utc),
                punch_type="out",
                processed=True,
                processed_at=datetime.now(timezone.utc),
            ))

    db_session.add_all(raw_logs)
    await db_session.flush()

    # Reprocess
    import time as time_mod
    start = time_mod.monotonic()

    processor = AttendanceProcessor(db_session)
    result = await processor.reprocess(
        tenant_id=test_tenant.id,
        from_date=target_date,
        to_date=target_date + timedelta(days=25),
    )

    elapsed = time_mod.monotonic() - start

    assert result["reset"] > 0
    assert result["processed"] > 0
    assert elapsed < 20.0, f"Reprocessing took {elapsed:.1f}s, expected <20s"


@pytest.mark.asyncio
async def test_concurrent_raw_log_inserts(db_session: AsyncSession, test_tenant):
    """Simulate concurrent raw log inserts from multiple sync operations."""
    import asyncio

    async def insert_batch(batch_id: int, count: int):
        logs = []
        for i in range(count):
            logs.append(AttendanceRawLog(
                tenant_id=test_tenant.id,
                employee_code=f"CONC{batch_id:02d}{i:05d}",
                punch_time=datetime.now(timezone.utc) - timedelta(hours=i % 12),
                punch_type="in",
                processed=False,
            ))
        db_session.add_all(logs)
        await db_session.flush()

    # Simulate 5 concurrent sync batches of 1000 each
    await asyncio.gather(*[insert_batch(b, 1000) for b in range(5)])

    # Verify all inserted
    from sqlalchemy import func, select
    count = (await db_session.execute(
        select(func.count(AttendanceRawLog.id)).where(
            AttendanceRawLog.tenant_id == test_tenant.id,
            AttendanceRawLog.employee_code.like("CONC%"),
        )
    )).scalar()

    assert count == 5000


@pytest.mark.asyncio
async def test_attendance_upsert_idempotency(db_session: AsyncSession, test_tenant, test_employee, test_shift):
    """Processing the same raw logs twice must not create duplicate attendance records."""
    target_date = date.today() - timedelta(days=1)

    # Create raw logs
    for punch_type, punch_time in [("in", time(9, 0)), ("out", time(18, 0))]:
        raw = AttendanceRawLog(
            tenant_id=test_tenant.id,
            employee_code=test_employee.employee_code,
            employee_id=test_employee.id,
            punch_time=datetime.combine(target_date, punch_time).replace(tzinfo=timezone.utc),
            punch_type=punch_type,
            processed=False,
        )
        db_session.add(raw)
    await db_session.flush()

    processor = AttendanceProcessor(db_session)

    # First processing
    result1 = await processor.process_raw_logs(test_tenant.id, target_date)
    assert result1["created"] == 1

    # Create more raw logs for same employee/date
    for punch_type, punch_time in [("in", time(9, 5)), ("out", time(17, 55))]:
        raw = AttendanceRawLog(
            tenant_id=test_tenant.id,
            employee_code=test_employee.employee_code,
            employee_id=test_employee.id,
            punch_time=datetime.combine(target_date, punch_time).replace(tzinfo=timezone.utc),
            punch_type=punch_type,
            processed=False,
        )
        db_session.add(raw)
    await db_session.flush()

    # Second processing — should update, not create
    result2 = await processor.process_raw_logs(test_tenant.id, target_date)
    assert result2["updated"] == 1
    assert result2["created"] == 0

    # Verify only one attendance record exists
    from sqlalchemy import func, select
    count = (await db_session.execute(
        select(func.count(Attendance.id)).where(
            Attendance.tenant_id == test_tenant.id,
            Attendance.employee_id == test_employee.id,
            Attendance.date == target_date,
        )
    )).scalar()
    assert count == 1
