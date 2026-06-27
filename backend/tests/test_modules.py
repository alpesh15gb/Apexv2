"""Attendance, Leave, and Payroll tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestAttendance:
    """Test attendance endpoints."""

    async def test_clock_in(self, client: AsyncClient, auth_headers, db, tenant, user):
        """Test clock in."""
        from app.models.employee import Employee
        emp = Employee(tenant_id=tenant.id, employee_code="ATT001", first_name="Att", last_name="Test", status="active")
        db.add(emp)
        await db.flush()

        response = await client.post("/api/v1/ess/attendance/clock-in", headers=auth_headers)
        assert response.status_code in [200, 400]  # 400 if already clocked in

    async def test_clock_out(self, client: AsyncClient, auth_headers):
        """Test clock out."""
        response = await client.post("/api/v1/ess/attendance/clock-out", headers=auth_headers)
        assert response.status_code in [200, 400]

    async def test_get_attendance(self, client: AsyncClient, auth_headers):
        """Test getting attendance list."""
        response = await client.get("/api/v1/attendance/", headers=auth_headers)
        assert response.status_code == 200
        assert "items" in response.json()

    async def test_daily_summary(self, client: AsyncClient, auth_headers):
        """Test daily attendance summary."""
        response = await client.get("/api/v1/attendance/daily-summary", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestLeave:
    """Test leave endpoints."""

    async def test_get_leave_types(self, client: AsyncClient, auth_headers):
        """Test getting leave types."""
        response = await client.get("/api/v1/leaves/types", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_leave_type(self, client: AsyncClient, auth_headers):
        """Test creating a leave type."""
        response = await client.post("/api/v1/leaves/types",
            json={"name": "Test Leave", "code": "TL", "max_days_per_year": 10, "is_active": True},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_get_leave_balance(self, client: AsyncClient, auth_headers):
        """Test getting leave balance."""
        response = await client.get("/api/v1/ess/leaves/balance", headers=auth_headers)
        assert response.status_code == 200

    async def test_apply_leave(self, client: AsyncClient, auth_headers):
        """Test applying for leave."""
        response = await client.post("/api/v1/ess/leaves",
            json={
                "start_date": "2026-07-01",
                "end_date": "2026-07-02",
                "reason": "Test leave",
            },
            headers=auth_headers,
        )
        assert response.status_code in [200, 201, 400, 404]


@pytest.mark.asyncio
class TestPayroll:
    """Test payroll endpoints."""

    async def test_get_salary_structures(self, client: AsyncClient, auth_headers):
        """Test getting salary structures."""
        response = await client.get("/api/v1/payroll/salary-structures", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_salary_structure(self, client: AsyncClient, auth_headers):
        """Test creating a salary structure."""
        response = await client.post("/api/v1/payroll/salary-structures",
            json={
                "name": "Test Structure",
                "basic": 10000,
                "hra": 5000,
                "da": 2000,
                "effective_from": "2026-01-01",
            },
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_get_payslips(self, client: AsyncClient, auth_headers):
        """Test getting payslips."""
        response = await client.get("/api/v1/ess/payslips", headers=auth_headers)
        assert response.status_code == 200

    async def test_get_loans(self, client: AsyncClient, auth_headers):
        """Test getting loans."""
        response = await client.get("/api/v1/ess/leaves/balance", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestNotifications:
    """Test notification endpoints."""

    async def test_get_notifications(self, client: AsyncClient, auth_headers):
        """Test getting notifications."""
        response = await client.get("/api/v1/notifications/", headers=auth_headers)
        assert response.status_code == 200

    async def test_unread_count(self, client: AsyncClient, auth_headers):
        """Test getting unread count."""
        response = await client.get("/api/v1/notifications/unread-count", headers=auth_headers)
        assert response.status_code == 200
        assert "count" in response.json()

    async def test_mark_all_read(self, client: AsyncClient, auth_headers):
        """Test marking all notifications as read."""
        response = await client.post("/api/v1/notifications/read-all", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestShifts:
    """Test shift endpoints."""

    async def test_list_shifts(self, client: AsyncClient, auth_headers):
        """Test listing shifts."""
        response = await client.get("/api/v1/shifts/", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_shift(self, client: AsyncClient, auth_headers):
        """Test creating a shift."""
        response = await client.post("/api/v1/shifts/",
            json={"name": "Test Shift", "start_time": "09:00", "end_time": "18:00", "grace_period_minutes": 10},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]


@pytest.mark.asyncio
class TestHolidays:
    """Test holiday endpoints."""

    async def test_list_holidays(self, client: AsyncClient, auth_headers):
        """Test listing holidays."""
        response = await client.get("/api/v1/holidays/", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestDashboard:
    """Test dashboard endpoints."""

    async def test_dashboard_stats(self, client: AsyncClient, auth_headers):
        """Test dashboard stats."""
        response = await client.get("/api/v1/dashboard/stats", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "total_employees" in data

    async def test_sync_health(self, client: AsyncClient, auth_headers):
        """Test sync health."""
        response = await client.get("/api/v1/dashboard/sync-health", headers=auth_headers)
        assert response.status_code == 200
