"""Setup script: seed data and create super admin user. Run inside backend container."""

import asyncio
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app.db.session import async_session_factory
from app.core.security import hash_password
from app.core.seed import seed_all
from app.core.feature_gate import seed_feature_flags
from app.core.rbac import create_default_roles
from app.models.tenant import Tenant
from app.models.user import User
from app.models.role import Role, Permission, RolePermission, UserRole
from sqlalchemy import select


async def main():
    async with async_session_factory() as db:
        print("Seeding subscription plans and feature flags...")
        await seed_all(db)
        print("Done seeding.")

        # Check if super admin already exists
        existing = await db.execute(
            select(User).where(User.email == "admin@apexhrms.com")
        )
        if existing.scalar_one_or_none():
            print("Super admin user already exists: admin@apexhrms.com")
            return

        # Create or get platform tenant
        tenant_stmt = select(Tenant).where(Tenant.slug == "apex-platform")
        tenant_result = await db.execute(tenant_stmt)
        tenant = tenant_result.scalar_one_or_none()

        if not tenant:
            tenant = Tenant(
                name="Apex HRMS Platform",
                slug="apex-platform",
                email="admin@apexhrms.com",
                subscription_status="active",
                is_active=True,
            )
            db.add(tenant)
            await db.flush()
            print(f"Created platform tenant: {tenant.id}")

            # Create default roles for platform tenant
            await create_default_roles(db, tenant.id)

        # Create super admin user
        super_admin = User(
            tenant_id=tenant.id,
            email="admin@apexhrms.com",
            full_name="Platform Admin",
            hashed_password=hash_password("Admin@123"),
            is_active=True,
            is_superuser=True,
            must_change_password=True,
        )
        db.add(super_admin)
        await db.flush()

        # Assign super admin role
        role_stmt = select(Role).where(
            Role.tenant_id == tenant.id,
            Role.name == "Super Admin",
        )
        role_result = await db.execute(role_stmt)
        role = role_result.scalar_one_or_none()

        if role:
            user_role = UserRole(
                user_id=super_admin.id,
                role_id=role.id,
                tenant_id=tenant.id,
            )
            db.add(user_role)

        await db.commit()
        print(f"Super admin created:")
        print(f"  Email: admin@apexhrms.com")
        print(f"  Password: Admin@123")
        print(f"  Tenant: {tenant.name} ({tenant.id})")
        print(f"  User ID: {super_admin.id}")


if __name__ == "__main__":
    asyncio.run(main())
