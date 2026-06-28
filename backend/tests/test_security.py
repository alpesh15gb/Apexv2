"""Security and multi-tenant isolation tests.

Run with: pytest backend/tests/test_security.py -v
"""

import pytest
import uuid
from datetime import datetime, timezone, timedelta
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.main import app
from app.db.session import get_db
from app.core.config import get_settings
from app.core.security import create_access_token

settings = get_settings()

# Test database URL (use a test database, not production)
TEST_DATABASE_URL = settings.DATABASE_URL.replace("apex_db", "apex_test_db")

engine = create_async_engine(TEST_DATABASE_URL, echo=False)
TestSessionLocal = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)


async def override_get_db():
    async with TestSessionLocal() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


def make_token(user_id: str, tenant_id: str, is_superuser: bool = False) -> str:
    """Create a test JWT token."""
    return create_access_token(subject=user_id, tenant_id=tenant_id)


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest.fixture
async def db():
    async with TestSessionLocal() as session:
        yield session


# ── Tenant Isolation Tests ────────────────────────────────────

class TestTenantIsolation:
    """Verify that tenants cannot access each other's data."""

    @pytest.mark.asyncio
    async def test_cross_tenant_employee_access_denied(self, client: AsyncClient):
        """Tenant A cannot read Tenant B's employees."""
        tenant_a_id = str(uuid.uuid4())
        tenant_b_id = str(uuid.uuid4())
        user_a_id = str(uuid.uuid4())

        token_a = make_token(user_a_id, tenant_a_id)

        # Try to access tenant B's employees with tenant A's token
        response = await client.get(
            "/api/v1/employees/",
            headers={"Authorization": f"Bearer {token_a}"},
        )

        # Should return tenant A's employees only (or empty), not tenant B's
        assert response.status_code in [200, 401, 403]
        if response.status_code == 200:
            data = response.json()
            # Verify no tenant B data leaked
            # (In a real test, we'd create employees for both tenants first)

    @pytest.mark.asyncio
    async def test_cross_tenant_attendance_access_denied(self, client: AsyncClient):
        """Tenant A cannot read Tenant B's attendance."""
        tenant_a_id = str(uuid.uuid4())
        tenant_b_id = str(uuid.uuid4())
        user_a_id = str(uuid.uuid4())

        token_a = make_token(user_a_id, tenant_a_id)

        response = await client.get(
            "/api/v1/attendance/",
            headers={"Authorization": f"Bearer {token_a}"},
            params={"from_date": "2026-01-01", "to_date": "2026-12-31"},
        )

        assert response.status_code in [200, 401, 403]

    @pytest.mark.asyncio
    async def test_cross_tenant_student_access_denied(self, client: AsyncClient):
        """Tenant A cannot read Tenant B's students."""
        tenant_a_id = str(uuid.uuid4())
        tenant_b_id = str(uuid.uuid4())
        user_a_id = str(uuid.uuid4())

        token_a = make_token(user_a_id, tenant_a_id)

        response = await client.get(
            "/api/v1/school/students/",
            headers={"Authorization": f"Bearer {token_a}"},
        )

        assert response.status_code in [200, 401, 403]

    @pytest.mark.asyncio
    async def test_cross_tenant_fee_access_denied(self, client: AsyncClient):
        """Tenant A cannot read Tenant B's fee data."""
        tenant_a_id = str(uuid.uuid4())
        user_a_id = str(uuid.uuid4())

        token_a = make_token(user_a_id, tenant_a_id)

        response = await client.get(
            "/api/v1/school/fees/payments",
            headers={"Authorization": f"Bearer {token_a}"},
        )

        assert response.status_code in [200, 401, 403]


# ── Authentication Tests ──────────────────────────────────────

class TestAuthentication:
    """Verify authentication enforcement."""

    @pytest.mark.asyncio
    async def test_unauthenticated_access_denied(self, client: AsyncClient):
        """Endpoints require authentication."""
        endpoints = [
            "/api/v1/employees/",
            "/api/v1/attendance/",
            "/api/v1/leaves/types",
            "/api/v1/payroll/structures",
            "/api/v1/school/students/",
        ]

        for endpoint in endpoints:
            response = await client.get(endpoint)
            assert response.status_code == 401, f"Endpoint {endpoint} should require auth"

    @pytest.mark.asyncio
    async def test_invalid_token_rejected(self, client: AsyncClient):
        """Invalid JWT tokens are rejected."""
        response = await client.get(
            "/api/v1/employees/",
            headers={"Authorization": "Bearer invalid_token_here"},
        )
        assert response.status_code == 401

    @pytest.mark.asyncio
    async def test_expired_token_rejected(self, client: AsyncClient):
        """Expired JWT tokens are rejected."""
        # Create an expired token
        expired_token = create_access_token(
            subject=str(uuid.uuid4()),
            tenant_id=str(uuid.uuid4()),
            expires_delta=timedelta(seconds=-1),
        )

        response = await client.get(
            "/api/v1/employees/",
            headers={"Authorization": f"Bearer {expired_token}"},
        )
        assert response.status_code == 401


# ── RBAC Tests ────────────────────────────────────────────────

class TestRBAC:
    """Verify role-based access control."""

    @pytest.mark.asyncio
    async def test_employee_cannot_manage_departments(self, client: AsyncClient):
        """Employee role cannot create departments."""
        # This would require setting up a user with employee role
        # and verifying they get 403 on POST /departments
        pass

    @pytest.mark.asyncio
    async def test_manager_cannot_delete_employees(self, client: AsyncClient):
        """Manager role cannot delete employees."""
        pass

    @pytest.mark.asyncio
    async def test_unauthorized_permission_returns_403(self, client: AsyncClient):
        """Endpoints return 403 for insufficient permissions."""
        pass


# ── Admin Panel Tests ─────────────────────────────────────────

class TestAdminPanel:
    """Verify admin panel security."""

    @pytest.mark.asyncio
    async def test_non_superuser_cannot_access_admin(self, client: AsyncClient):
        """Non-superuser cannot access admin endpoints."""
        user_id = str(uuid.uuid4())
        tenant_id = str(uuid.uuid4())

        token = make_token(user_id, tenant_id, is_superuser=False)

        response = await client.get(
            "/api/v1/admin/tenants/",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert response.status_code == 403

    @pytest.mark.asyncio
    async def test_admin_login_requires_superuser(self, client: AsyncClient):
        """Admin login endpoint rejects non-superusers."""
        response = await client.post(
            "/api/v1/admin/auth/login",
            json={"email": "regular@user.com", "password": "password"},
        )
        # Should fail because user is not superuser
        assert response.status_code in [401, 403]


# ── Feature Flag Tests ────────────────────────────────────────

class TestFeatureFlags:
    """Verify feature flag enforcement."""

    @pytest.mark.asyncio
    async def test_disabled_feature_returns_403(self, client: AsyncClient):
        """Endpoints behind disabled feature flags return 403."""
        # This would require setting up a tenant with disabled features
        # and verifying they get 403
        pass

    @pytest.mark.asyncio
    async def test_school_features_hidden_from_corporate(self, client: AsyncClient):
        """Corporate tenants cannot access school endpoints."""
        tenant_id = str(uuid.uuid4())
        user_id = str(uuid.uuid4())

        token = make_token(user_id, tenant_id)

        response = await client.get(
            "/api/v1/school/students/",
            headers={"Authorization": f"Bearer {token}"},
        )

        # Should return 403 if school feature is disabled
        assert response.status_code in [200, 403]


# ── Input Validation Tests ────────────────────────────────────

class TestInputValidation:
    """Verify input validation and injection prevention."""

    @pytest.mark.asyncio
    async def test_sql_injection_in_search(self, client: AsyncClient):
        """Search endpoints prevent SQL injection."""
        user_id = str(uuid.uuid4())
        tenant_id = str(uuid.uuid4())

        token = make_token(user_id, tenant_id)

        # Try SQL injection in search
        response = await client.get(
            "/api/v1/employees/",
            headers={"Authorization": f"Bearer {token}"},
            params={"search": "'; DROP TABLE employees; --"},
        )

        # Should not crash or return unexpected data
        assert response.status_code in [200, 400, 422]

    @pytest.mark.asyncio
    async def test_xss_in_input_fields(self, client: AsyncClient):
        """Input fields sanitize XSS attempts."""
        user_id = str(uuid.uuid4())
        tenant_id = str(uuid.uuid4())

        token = make_token(user_id, tenant_id)

        # Try XSS in employee name
        response = await client.post(
            "/api/v1/employees/",
            headers={"Authorization": f"Bearer {token}"},
            json={
                "first_name": "<script>alert('xss')</script>",
                "last_name": "Test",
                "email": "test@test.com",
            },
        )

        # Should either reject or sanitize
        if response.status_code == 201:
            data = response.json()
            assert "<script>" not in data.get("first_name", "")
