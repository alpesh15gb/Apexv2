"""Employee CRUD tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestEmployeeCRUD:
    """Test employee CRUD operations."""

    async def test_create_employee(self, client: AsyncClient, auth_headers):
        """Test creating an employee."""
        response = await client.post("/api/v1/employees/",
            json={
                "employee_code": "EMP001",
                "first_name": "John",
                "last_name": "Doe",
                "email": "john@test.com",
                "status": "active",
            },
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]
        data = response.json()
        assert data["employee_code"] == "EMP001"

    async def test_list_employees(self, client: AsyncClient, auth_headers):
        """Test listing employees."""
        # Create employee first
        await client.post("/api/v1/employees/",
            json={"employee_code": "EMP002", "first_name": "Jane", "last_name": "Doe", "status": "active"},
            headers=auth_headers,
        )

        response = await client.get("/api/v1/employees/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert "items" in data
        assert data["total"] >= 1

    async def test_get_employee(self, client: AsyncClient, auth_headers):
        """Test getting a single employee."""
        create_response = await client.post("/api/v1/employees/",
            json={"employee_code": "EMP003", "first_name": "Test", "last_name": "User", "status": "active"},
            headers=auth_headers,
        )
        emp_id = create_response.json()["id"]

        response = await client.get(f"/api/v1/employees/{emp_id}", headers=auth_headers)
        assert response.status_code == 200
        assert response.json()["employee_code"] == "EMP003"

    async def test_update_employee(self, client: AsyncClient, auth_headers):
        """Test updating an employee."""
        create_response = await client.post("/api/v1/employees/",
            json={"employee_code": "EMP004", "first_name": "Update", "last_name": "Test", "status": "active"},
            headers=auth_headers,
        )
        emp_id = create_response.json()["id"]

        response = await client.put(f"/api/v1/employees/{emp_id}",
            json={"first_name": "Updated"},
            headers=auth_headers,
        )
        assert response.status_code == 200

    async def test_search_employees(self, client: AsyncClient, auth_headers):
        """Test searching employees."""
        await client.post("/api/v1/employees/",
            json={"employee_code": "SEARCH01", "first_name": "Searchable", "last_name": "Employee", "status": "active"},
            headers=auth_headers,
        )

        response = await client.get("/api/v1/employees/?search=Searchable", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["total"] >= 1


@pytest.mark.asyncio
class TestEmployeeLifecycle:
    """Test employee lifecycle operations."""

    async def test_promote_employee(self, client: AsyncClient, auth_headers):
        """Test promoting an employee."""
        create_response = await client.post("/api/v1/employees/",
            json={"employee_code": "PROMO01", "first_name": "Promote", "last_name": "Test", "status": "active"},
            headers=auth_headers,
        )
        emp_id = create_response.json()["id"]

        response = await client.post(f"/api/v1/employees/{emp_id}/promote",
            json={
                "event_type": "promotion",
                "title": "Promoted to Senior",
                "event_date": "2026-06-27",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200

    async def test_resign_employee(self, client: AsyncClient, auth_headers):
        """Test recording employee resignation."""
        create_response = await client.post("/api/v1/employees/",
            json={"employee_code": "RESIGN01", "first_name": "Resign", "last_name": "Test", "status": "active"},
            headers=auth_headers,
        )
        emp_id = create_response.json()["id"]

        response = await client.post(f"/api/v1/employees/{emp_id}/resign",
            json={
                "event_type": "resignation",
                "title": "Resignation submitted",
                "event_date": "2026-06-27",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200

    async def test_get_employee_timeline(self, client: AsyncClient, auth_headers):
        """Test getting employee timeline."""
        create_response = await client.post("/api/v1/employees/",
            json={"employee_code": "TIMELINE01", "first_name": "Timeline", "last_name": "Test", "status": "active"},
            headers=auth_headers,
        )
        emp_id = create_response.json()["id"]

        response = await client.get(f"/api/v1/employees/{emp_id}/timeline", headers=auth_headers)
        assert response.status_code == 200
