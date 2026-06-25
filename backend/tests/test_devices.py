"""Tests for device endpoints."""

import pytest
import uuid
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_create_device(client: AsyncClient, auth_headers, test_branch):
    response = await client.post(
        "/api/v1/devices/",
        headers=auth_headers,
        json={
            "serial_number": "ESSL-001",
            "device_name": "Main Gate Scanner",
            "model": "eBio A100",
            "ip_address": "192.168.1.100",
            "branch_id": str(test_branch.id),
            "device_type": "biometric",
            "communication_mode": "tcp/ip",
        },
    )
    assert response.status_code in (200, 201)
    data = response.json()
    assert data["serial_number"] == "ESSL-001"


@pytest.mark.asyncio
async def test_list_devices(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/devices/", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data.get("data"), list)


@pytest.mark.asyncio
async def test_device_health(client: AsyncClient, auth_headers):
    response = await client.get("/api/v1/devices/health", headers=auth_headers)
    assert response.status_code == 200
    data = response.json()
    assert "total_devices" in data
    assert "online" in data
    assert "offline" in data


@pytest.mark.asyncio
async def test_device_not_found(client: AsyncClient, auth_headers):
    fake_id = uuid.uuid4()
    response = await client.get(f"/api/v1/devices/{fake_id}", headers=auth_headers)
    assert response.status_code == 404
