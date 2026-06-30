"""Test configuration and fixtures."""

import asyncio
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.main import app
from app.db.base import Base
from app.core.config import get_settings
from app.core.deps import get_db

settings = get_settings()

# Use a test database
TEST_DATABASE_URL = settings.DATABASE_URL.replace("apex_db", "apex_test_db")


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def engine():
    eng = create_async_engine(TEST_DATABASE_URL, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await eng.dispose()


@pytest_asyncio.fixture
async def db(engine):
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with async_session() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(db):
    def override_get_db():
        return db

    app.dependency_overrides[get_db] = override_get_db
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c
    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def tenant(db):
    """Create a test tenant."""
    from app.models.tenant import Tenant
    tenant = Tenant(
        name="Test Company",
        slug="test-company",
        email="test@test.com",
        subscription_status="active",
        is_active=True,
    )
    db.add(tenant)
    await db.flush()
    return tenant


@pytest_asyncio.fixture
async def user(db, tenant):
    """Create a test user."""
    from app.models.user import User
    from app.core.security import hash_password
    user = User(
        tenant_id=tenant.id,
        email="admin@test.com",
        full_name="Test Admin",
        hashed_password=hash_password("TestPass123!"),
        is_active=True,
        is_superuser=False,
    )
    db.add(user)
    await db.flush()
    return user


@pytest_asyncio.fixture
async def superuser(db, tenant):
    """Create a test superuser."""
    from app.models.user import User
    from app.core.security import hash_password
    user = User(
        tenant_id=tenant.id,
        email="super@test.com",
        full_name="Super Admin",
        hashed_password=hash_password("SuperPass123!"),
        is_active=True,
        is_superuser=True,
    )
    db.add(user)
    await db.flush()
    return user


@pytest_asyncio.fixture
async def auth_headers(client, user):
    """Get auth headers for test user."""
    response = await client.post("/api/v1/auth/login", json={
        "email": "admin@test.com",
        "password": "TestPass123!",
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def super_auth_headers(client, superuser):
    """Get auth headers for superuser."""
    response = await client.post("/api/v1/auth/login", json={
        "email": "super@test.com",
        "password": "SuperPass123!",
    })
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

@pytest_asyncio.fixture
async def db_session(db):
    return db

@pytest_asyncio.fixture
async def test_tenant(tenant):
    return tenant

@pytest_asyncio.fixture
async def test_department(db, tenant):
    from app.models.employee import Department
    dept = Department(
        tenant_id=tenant.id,
        name="Engineering",
        code="ENG",
        is_active=True,
    )
    db.add(dept)
    await db.flush()
    return dept

@pytest_asyncio.fixture
async def test_branch(db, tenant):
    from app.models.employee import Branch
    branch = Branch(
        tenant_id=tenant.id,
        name="Main Office",
        code="HQ",
        is_active=True,
    )
    db.add(branch)
    await db.flush()
    return branch

@pytest_asyncio.fixture
async def test_shift(db, tenant):
    from app.models.shift import Shift
    from datetime import time
    shift = Shift(
        tenant_id=tenant.id,
        name="General Shift",
        start_time=time(9, 0),
        end_time=time(18, 0),
        grace_period_minutes=10,
        late_rule_minutes=15,
        early_rule_minutes=10,
        overtime_threshold_minutes=30,
        is_night_shift=False,
        is_active=True,
    )
    db.add(shift)
    await db.flush()
    return shift

@pytest_asyncio.fixture
async def test_employee(db, tenant, test_department, test_branch, test_shift):
    from app.models.employee import Employee
    from datetime import date
    employee = Employee(
        tenant_id=tenant.id,
        employee_code="EMP00001",
        first_name="John",
        last_name="Doe",
        email="john@test.com",
        department_id=test_department.id,
        branch_id=test_branch.id,
        shift_id=test_shift.id,
        joining_date=date(2024, 1, 1),
        status="active",
    )
    db.add(employee)
    await db.flush()
    return employee
