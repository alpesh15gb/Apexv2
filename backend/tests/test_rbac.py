"""Tenant isolation and RBAC tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestTenantIsolation:
    """Test multi-tenant data isolation."""

    async def test_user_cannot_access_other_tenant_data(self, client: AsyncClient, auth_headers, tenant, db):
        """Test that a user cannot access another tenant's data."""
        from app.models.employee import Employee
        from app.core.security import hash_password
        from app.models.user import User

        # Create another tenant
        from app.models.tenant import Tenant
        other_tenant = Tenant(
            name="Other Company",
            slug="other-company",
            email="other@test.com",
            subscription_status="active",
            is_active=True,
        )
        db.add(other_tenant)
        await db.flush()

        # Create employee in other tenant
        other_emp = Employee(
            tenant_id=other_tenant.id,
            employee_code="OTH001",
            first_name="Other",
            last_name="Employee",
            status="active",
        )
        db.add(other_emp)
        await db.flush()

        # Try to access other tenant's employees
        response = await client.get("/api/v1/employees/", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        # Should not include other tenant's employee
        codes = [e["employee_code"] for e in data.get("items", [])]
        assert "OTH001" not in codes


@pytest.mark.asyncio
class TestRBAC:
    """Test role-based access control."""

    async def test_superuser_can_access_admin_endpoints(self, client: AsyncClient, super_auth_headers):
        """Test superuser can access admin endpoints."""
        response = await client.get("/api/v1/admin/dashboard/stats", headers=super_auth_headers)
        assert response.status_code == 200

    async def test_regular_user_cannot_access_admin_endpoints(self, client: AsyncClient, auth_headers):
        """Test regular user cannot access admin endpoints."""
        response = await client.get("/api/v1/admin/dashboard/stats", headers=auth_headers)
        assert response.status_code == 403

    async def test_unauthenticated_cannot_access_protected_endpoints(self, client: AsyncClient):
        """Test unauthenticated requests are rejected."""
        response = await client.get("/api/v1/employees/")
        assert response.status_code == 401

    async def test_health_endpoint_is_public(self, client: AsyncClient):
        """Test health endpoint is accessible without auth."""
        response = await client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] in ["healthy", "degraded"]
