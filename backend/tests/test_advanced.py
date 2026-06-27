"""Recruitment, Performance, Assets, Billing tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestRecruitment:
    """Test recruitment endpoints."""

    async def test_list_openings(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/recruitment/openings", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_opening(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/recruitment/openings",
            json={"title": "Test Developer", "employment_type": "permanent", "openings": 1},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_list_candidates(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/recruitment/candidates", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_candidate(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/recruitment/candidates",
            json={"first_name": "Test", "last_name": "Candidate", "email": "test@example.com"},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_recruitment_stats(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/recruitment/stats", headers=auth_headers)
        assert response.status_code == 200

    async def test_pipeline(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/recruitment/pipeline", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestPerformance:
    """Test performance endpoints."""

    async def test_list_cycles(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/performance/cycles", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_cycle(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/performance/cycles",
            json={
                "name": "Q1 2026 Review",
                "cycle_type": "quarterly",
                "start_date": "2026-01-01",
                "end_date": "2026-03-31",
            },
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_list_goals(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/performance/goals", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_goal(self, client: AsyncClient, auth_headers, db, tenant):
        from app.models.employee import Employee
        emp = Employee(tenant_id=tenant.id, employee_code="PERF01", first_name="Perf", last_name="Test", status="active")
        db.add(emp)
        await db.flush()

        response = await client.post("/api/v1/performance/goals",
            json={"employee_id": str(emp.id), "title": "Test Goal", "weightage": 50},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_performance_stats(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/performance/stats", headers=auth_headers)
        assert response.status_code == 200

    async def test_list_competencies(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/performance/competencies", headers=auth_headers)
        assert response.status_code == 200


@pytest.mark.asyncio
class TestAssets:
    """Test asset endpoints."""

    async def test_list_assets(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/assets/", headers=auth_headers)
        assert response.status_code == 200

    async def test_create_asset(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/assets/",
            json={"name": "Test Laptop", "asset_code": "ASSET001", "category": "laptop"},
            headers=auth_headers,
        )
        assert response.status_code in [200, 201]

    async def test_asset_stats(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/assets/stats", headers=auth_headers)
        assert response.status_code == 200

    async def test_assign_asset(self, client: AsyncClient, auth_headers, db, tenant):
        from app.models.company_asset import CompanyAsset
        from app.models.employee import Employee

        emp = Employee(tenant_id=tenant.id, employee_code="ASSET01", first_name="Asset", last_name="Test", status="active")
        db.add(emp)
        await db.flush()

        asset = CompanyAsset(tenant_id=tenant.id, name="Test Asset", asset_code="ASSIGN01", status="available")
        db.add(asset)
        await db.flush()

        response = await client.post(f"/api/v1/assets/{asset.id}/assign",
            json={"employee_id": str(emp.id)},
            headers=auth_headers,
        )
        assert response.status_code == 200


@pytest.mark.asyncio
class TestSuperAdmin:
    """Test super admin endpoints."""

    async def test_admin_stats(self, client: AsyncClient, super_auth_headers):
        response = await client.get("/api/v1/admin/dashboard/stats", headers=super_auth_headers)
        assert response.status_code == 200

    async def test_list_tenants(self, client: AsyncClient, super_auth_headers):
        response = await client.get("/api/v1/admin/tenants/", headers=super_auth_headers)
        assert response.status_code == 200

    async def test_list_plans(self, client: AsyncClient, super_auth_headers):
        response = await client.get("/api/v1/admin/plans/", headers=super_auth_headers)
        assert response.status_code == 200

    async def test_list_features(self, client: AsyncClient, super_auth_headers):
        response = await client.get("/api/v1/admin/features/", headers=super_auth_headers)
        assert response.status_code == 200

    async def test_regular_user_blocked_from_admin(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/admin/dashboard/stats", headers=auth_headers)
        assert response.status_code == 403


@pytest.mark.asyncio
class TestESS:
    """Test Employee Self Service endpoints."""

    async def test_ess_dashboard(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/ess/dashboard", headers=auth_headers)
        assert response.status_code in [200, 404]  # 404 if no employee linked

    async def test_ess_profile(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/ess/profile", headers=auth_headers)
        assert response.status_code in [200, 404]

    async def test_ess_attendance(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/ess/attendance", headers=auth_headers)
        assert response.status_code in [200, 404]

    async def test_ess_notifications(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/ess/notifications", headers=auth_headers)
        assert response.status_code in [200, 404]


@pytest.mark.asyncio
class TestSetup:
    """Test setup wizard endpoints."""

    async def test_setup_progress(self, client: AsyncClient, auth_headers):
        response = await client.get("/api/v1/setup/progress", headers=auth_headers)
        assert response.status_code == 200

    async def test_setup_company(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/setup/company",
            json={"name": "Test Company Updated", "currency": "INR"},
            headers=auth_headers,
        )
        assert response.status_code == 200

    async def test_setup_departments(self, client: AsyncClient, auth_headers):
        response = await client.post("/api/v1/setup/departments",
            json={"departments": [{"name": "Engineering", "code": "ENG"}]},
            headers=auth_headers,
        )
        assert response.status_code == 200
