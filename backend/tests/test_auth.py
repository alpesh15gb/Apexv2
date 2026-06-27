"""Authentication tests."""

import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
class TestAuthentication:
    """Test authentication endpoints."""

    async def test_login_success(self, client: AsyncClient, user):
        """Test successful login."""
        response = await client.post("/api/v1/auth/login", json={
            "email": "admin@test.com",
            "password": "TestPass123!",
        })
        assert response.status_code == 200
        data = response.json()
        assert "access_token" in data
        assert "refresh_token" in data
        assert data["user"]["email"] == "admin@test.com"

    async def test_login_wrong_password(self, client: AsyncClient, user):
        """Test login with wrong password."""
        response = await client.post("/api/v1/auth/login", json={
            "email": "admin@test.com",
            "password": "WrongPass123!",
        })
        assert response.status_code == 401

    async def test_login_nonexistent_user(self, client: AsyncClient):
        """Test login with nonexistent user."""
        response = await client.post("/api/v1/auth/login", json={
            "email": "nonexistent@test.com",
            "password": "TestPass123!",
        })
        assert response.status_code == 401

    async def test_get_me(self, client: AsyncClient, auth_headers):
        """Test getting current user profile."""
        response = await client.get("/api/v1/auth/me", headers=auth_headers)
        assert response.status_code == 200
        data = response.json()
        assert data["email"] == "admin@test.com"

    async def test_get_me_no_token(self, client: AsyncClient):
        """Test getting profile without token."""
        response = await client.get("/api/v1/auth/me")
        assert response.status_code == 401

    async def test_refresh_token(self, client: AsyncClient, user):
        """Test token refresh."""
        login_response = await client.post("/api/v1/auth/login", json={
            "email": "admin@test.com",
            "password": "TestPass123!",
        })
        refresh_token = login_response.json()["refresh_token"]

        response = await client.post("/api/v1/auth/refresh", json={
            "refresh_token": refresh_token,
        })
        assert response.status_code == 200
        assert "access_token" in response.json()

    async def test_logout(self, client: AsyncClient, user):
        """Test logout."""
        login_response = await client.post("/api/v1/auth/login", json={
            "email": "admin@test.com",
            "password": "TestPass123!",
        })
        refresh_token = login_response.json()["refresh_token"]

        response = await client.post("/api/v1/auth/logout", json={
            "refresh_token": refresh_token,
        })
        assert response.status_code == 200

    async def test_change_password(self, client: AsyncClient, auth_headers):
        """Test password change."""
        response = await client.post("/api/v1/auth/change-password",
            json={
                "old_password": "TestPass123!",
                "new_password": "NewPass456!",
            },
            headers=auth_headers,
        )
        assert response.status_code == 200


@pytest.mark.asyncio
class TestAccountLockout:
    """Test account lockout after failed attempts."""

    async def test_lockout_after_5_failures(self, client: AsyncClient, user):
        """Test account locks after 5 failed login attempts."""
        for i in range(5):
            await client.post("/api/v1/auth/login", json={
                "email": "admin@test.com",
                "password": f"WrongPass{i}!",
            })

        # 6th attempt should be locked
        response = await client.post("/api/v1/auth/login", json={
            "email": "admin@test.com",
            "password": "TestPass123!",
        })
        assert response.status_code == 423  # Locked
