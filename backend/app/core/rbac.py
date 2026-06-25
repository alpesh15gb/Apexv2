"""RBAC utility: permission checking and role management."""

import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

# These will be importable once models are created
# from app.models.user import User
# from app.models.role import Role, Permission


async def get_user_permissions(db: AsyncSession, user_id: uuid.UUID) -> set[str]:
    """Fetch all permission codenames for a user via their roles."""
    from app.models.user import User
    from app.models.role import Role, Permission, RolePermission, UserRole

    stmt = (
        select(Permission.codename)
        .join(RolePermission, RolePermission.permission_id == Permission.id)
        .join(UserRole, UserRole.role_id == RolePermission.role_id)
        .where(UserRole.user_id == user_id)
    )
    result = await db.execute(stmt)
    return set(result.scalars().all())


async def user_has_permission(db: AsyncSession, user_id: uuid.UUID, codename: str) -> bool:
    """Check if user has a specific permission."""
    perms = await get_user_permissions(db, user_id)
    return codename in perms or "super_admin" in perms


async def user_has_all_permissions(db: AsyncSession, user_id: uuid.UUID, codenames: list[str]) -> bool:
    """Check if user has ALL listed permissions."""
    perms = await get_user_permissions(db, user_id)
    if "super_admin" in perms:
        return True
    return all(c in perms for c in codenames)


async def assign_role_to_user(db: AsyncSession, user_id: uuid.UUID, role_id: uuid.UUID) -> None:
    """Assign a role to a user."""
    from app.models.user import UserRole
    from app.models.role import Role

    role = await db.get(Role, role_id)
    tenant_id = role.tenant_id if role else None

    association = UserRole(user_id=user_id, role_id=role_id, tenant_id=tenant_id)
    db.add(association)


async def create_default_roles(db: AsyncSession, tenant_id: uuid.UUID) -> list:
    """Create default roles for a new tenant."""
    from app.models.role import Role, Permission, RolePermission

    default_roles = [
        {
            "name": "Super Admin",
            "codename": "super_admin",
            "permissions": ["*"],
        },
        {
            "name": "HR Admin",
            "codename": "hr_admin",
            "permissions": [
                "employee.create", "employee.read", "employee.update", "employee.delete",
                "attendance.read", "attendance.manage",
                "leave.approve", "leave.read",
                "shift.manage", "shift.read",
                "report.read",
                "visitor.manage", "visitor.read",
            ],
        },
        {
            "name": "Manager",
            "codename": "manager",
            "permissions": [
                "employee.read",
                "attendance.read", "attendance.approve",
                "leave.approve", "leave.read",
                "report.read",
                "visitor.read",
            ],
        },
        {
            "name": "Employee",
            "codename": "employee",
            "permissions": [
                "attendance.read_own",
                "leave.apply", "leave.read_own",
                "visitor.create",
            ],
        },
    ]

    # First ensure all permissions exist
    all_perm_codenames = set()
    for role_def in default_roles:
        all_perm_codenames.update(role_def["permissions"])

    perm_map = {}
    for codename in all_perm_codenames:
        module = codename.split(".")[0] if "." in codename else "system"
        perm = Permission(
            tenant_id=tenant_id,
            name=codename.replace("_", " ").replace(".", " ").title(),
            codename=codename,
            module=module,
        )
        db.add(perm)
        perm_map[codename] = perm

    await db.flush()

    roles = []
    for role_def in default_roles:
        role = Role(
            tenant_id=tenant_id,
            name=role_def["name"],
            description=f"Default {role_def['name']} role",
            is_system_role=True,
        )
        db.add(role)
        await db.flush()

        for perm_codename in role_def["permissions"]:
            if perm_codename in perm_map:
                rp = RolePermission(role_id=role.id, permission_id=perm_map[perm_codename].id, tenant_id=tenant_id)
                db.add(rp)
        roles.append(role)

    await db.flush()
    return roles
