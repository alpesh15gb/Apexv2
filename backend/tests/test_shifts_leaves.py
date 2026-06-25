"""Tests for shift and leave endpoints."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_shift(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/shifts/",
        headers=auth_headers,
        json={
            "name": "Night Shift",
            "start_time": "22:00:00",
            "end_time": "06:00:00",
            "grace_period_minutes": 10,
            "late_rule_minutes": 15,
            "early_rule_minutes": 15,
            "overtime_threshold_minutes": 30,
            "is_night_shift": True,
            "is_active": True,
        },
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert data["name"] == "Night Shift"
    assert data["is_night_shift"] is True


@pytest.mark.asyncio
async def test_list_shifts(client: AsyncClient, auth_headers, test_shift):
    response = await client.get("/api/v1/shifts/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1


@pytest.mark.asyncio
async def test_create_leave_type(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/leaves/types",
        headers=auth_headers,
        json={
            "name": "Casual Leave",
            "code": "CL",
            "default_days": 12,
            "is_paid": True,
            "carry_forward": False,
            "is_active": True,
        },
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert data["code"] == "CL"


@pytest.mark.asyncio
async def test_list_leave_types(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/leaves/types", headers=auth_headers)
    assert response.status_code == 200


@pytest.mark.asyncio
async def test_dashboard_stats(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/dashboard/stats", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "employees_present" in data
    assert "online_devices" in data
    assert "total_employees" in data


@pytest.mark.asyncio
async def test_unauthorized_no_token(client: AsyncClient):
    response = await client.get("/api/v1/dashboard/stats")
    assert response.status_code in (401, 403)


@pytest.mark.asyncio
async def test_visitor_registration(client: AsyncClient, auth_headers):
    response = await client.post(
        "/api/v1/visitors/",
        headers=auth_headers,
        json={
            "name": "Raj Kumar",
            "phone": "9876543210",
            "email": "raj@visitor.com",
            "company": "ABC Corp",
        },
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert data["name"] == "Raj Kumar"
