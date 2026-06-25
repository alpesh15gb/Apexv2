"""Test configuration and fixtures."""

import asyncio
import uuid
from datetime import date, datetime, time

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker

from app.db.base import Base
from app.db.session import get_db
from app.core.config import Settings
from app.core.security import hash_password


def get_test_settings() -> Settings:
    return Settings(
        DATABASE_URL="postgresql+asyncpg://apex:apex_secret@localhost:5432/apex_db_test",
        REDIS_URL="redis://localhost:6379/1",
        SECRET_KEY="test-secret-key-for-testing-only-32chars!",
        DEBUG=True,
    )


@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session")
async def engine():
    settings = get_test_settings()
    eng = create_async_engine(settings.DATABASE_URL, echo=False)
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield eng
    async with eng.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await eng.dispose()


@pytest_asyncio.fixture
async def db_session(engine):
    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with session_factory() as session:
        yield session
        await session.rollback()


@pytest_asyncio.fixture
async def client(engine):
    from app.main import app

    session_factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

    async def override_get_db():
        async with session_factory() as session:
            try:
                yield session
                await session.commit()
            except Exception:
                await session.rollback()
                raise

    app.dependency_overrides[get_db] = override_get_db

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest_asyncio.fixture
async def test_tenant(db_session: AsyncSession):
    from app.models.tenant import Tenant

    tenant = Tenant(
        name="Test Company",
        slug="test-company",
        is_active=True,
        max_employees=100,
        subscription_plan="pro",
    )
    db_session.add(tenant)
    await db_session.flush()
    return tenant


@pytest_asyncio.fixture
async def test_user(db_session: AsyncSession, test_tenant):
    from app.models.user import User

    user = User(
        tenant_id=test_tenant.id,
        email="admin@test.com",
        hashed_password=hash_password("TestPass123!"),
        full_name="Test Admin",
        is_active=True,
        is_superuser=True,
    )
    db_session.add(user)
    await db_session.flush()
    return user


@pytest_asyncio.fixture
async def auth_headers(test_user):
    from app.core.security import create_access_token

    token = create_access_token(
        subject=str(test_user.id),
        tenant_id=str(test_user.tenant_id),
    )
    return {"Authorization": f"Bearer {token}"}


@pytest_asyncio.fixture
async def test_department(db_session: AsyncSession, test_tenant):
    from app.models.employee import Department

    dept = Department(
        tenant_id=test_tenant.id,
        name="Engineering",
        code="ENG",
        is_active=True,
    )
    db_session.add(dept)
    await db_session.flush()
    return dept


@pytest_asyncio.fixture
async def test_branch(db_session: AsyncSession, test_tenant):
    from app.models.employee import Branch

    branch = Branch(
        tenant_id=test_tenant.id,
        name="Head Office",
        code="HO",
        address="123 Main St",
        is_active=True,
    )
    db_session.add(branch)
    await db_session.flush()
    return branch


@pytest_asyncio.fixture
async def test_shift(db_session: AsyncSession, test_tenant):
    from app.models.shift import Shift

    shift = Shift(
        tenant_id=test_tenant.id,
        name="General Shift",
        start_time=time(9, 0),
        end_time=time(18, 0),
        grace_period_minutes=10,
        late_rule_minutes=15,
        early_rule_minutes=15,
        overtime_threshold_minutes=30,
        is_night_shift=False,
        is_active=True,
    )
    db_session.add(shift)
    await db_session.flush()
    return shift


@pytest_asyncio.fixture
async def test_employee(db_session: AsyncSession, test_tenant, test_department, test_branch, test_shift):
    from app.models.employee import Employee

    emp = Employee(
        tenant_id=test_tenant.id,
        employee_code="EMP001",
        first_name="John",
        last_name="Doe",
        email="john@test.com",
        phone="1234567890",
        department_id=test_department.id,
        branch_id=test_branch.id,
        shift_id=test_shift.id,
        joining_date=date(2024, 1, 1),
        status="active",
    )
    db_session.add(emp)
    await db_session.flush()
    return emp
