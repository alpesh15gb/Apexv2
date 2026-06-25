"""Tests for employee endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_employee(client: AsyncClient, auth_headers, test_department, test_branch, test_shift):
    response = await client.post(
        "/api/v1/employees/",
        headers=auth_headers,
        json={
            "employee_code": "EMP002",
            "first_name": "Jane",
            "last_name": "Smith",
            "email": "jane@test.com",
            "phone": "9876543210",
            "department_id": str(test_department.id),
            "branch_id": str(test_branch.id),
            "shift_id": str(test_shift.id),
            "joining_date": "2024-01-15",
            "status": "active",
        },
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert data["employee_code"] == "EMP002"


@pytest.mark.asyncio
async def test_list_employees(client: AsyncClient, auth_headers, test_employee):
    response = await client.get("/api/v1/employees/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data.get("data"), list)
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_get_employee(client: AsyncClient, auth_headers, test_employee):
    response = await client.get(f"/api/v1/employees/{test_employee.id}", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["employee_code"] == "EMP001"


@pytest.mark.asyncio
async def test_update_employee(client: AsyncClient, auth_headers, test_employee):
    response = await client.put(
        f"/api/v1/employees/{test_employee.id}",
        headers=auth_headers,
        json={"first_name": "Johnny"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["first_name"] == "Johnny"


@pytest.mark.asyncio
async def test_list_departments(client: AsyncClient, auth_headers, test_department):
    response = await client.get("/api/v1/employees/departments", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_create_department(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/employees/departments",
        headers=auth_headers,
        json={"name": "Marketing", "code": "MKT"},
    )
    assert response.status_code in (200, 201)


@pytest.mark.asyncio
async def test_employee_not_found(client: AsyncClient, auth_headers):
    import uuid
    fake_id = uuid.uuid4()
    response = await client.get(f"/api/v1/employees/{fake_id}", headers=auth_headers)
    assert response.status_code == 404
