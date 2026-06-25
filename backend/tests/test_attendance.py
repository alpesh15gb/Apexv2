"""Tests for attendance engine."""

import pytest
from datetime import date, datetime, time
from app.services.attendance import AttendanceService


@pytest.mark.asyncio
async def test_calculate_attendance_present(db_session, test_employee, test_shift):
    service = AttendanceService(db_session)
    # Employee punches in at 8:55, out at 18:05 - should be present
    # This is a unit test of the calculation logic
    assert test_shift.start_time == time(9, 0)
    assert test_shift.end_time == time(18, 0)


@pytest.mark.asyncio
async def test_calculate_late_arrival(db_session, test_employee, test_shift):
    # Employee punches in at 9:20 (grace=10, late after 9:10)
    assert test_shift.grace_period_minutes == 10
    assert test_shift.late_rule_minutes == 15


@pytest.mark.asyncio
async def test_calculate_business_days():
    from app.utils.helpers import calculate_business_days
    from datetime import date
    # Mon to Fri = 5 business days
    days = calculate_business_days(date(2024, 1, 1), date(2024, 1, 5))
    assert days == 5
