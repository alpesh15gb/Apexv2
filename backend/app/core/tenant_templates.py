"""Tenant templates for auto-enabling modules based on tenant type."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.tenant import Tenant, TenantType
from app.models.feature import FeatureFlag, TenantFeature


# Core features enabled for ALL tenant types
CORE_FEATURES = [
    "attendance", "leave", "shift", "overtime", "outdoor_duty",
    "payroll", "expense", "tax", "benefits", "loans",
    "travel", "assets", "documents", "onboarding", "exit_management",
    "announcements", "polls", "visitor", "access_control",
    "biometric", "device", "reports", "analytics",
    "ess", "notification_templates",
]

# Additional features for corporate tenants
CORPORATE_FEATURES = [
    "recruitment", "performance",
]

# Additional features for school tenants
SCHOOL_FEATURES = [
    "student_management", "admissions", "academic_year",
    "class_management", "subject_management", "school_timetable",
    "homework", "school_assignments", "lesson_planning",
    "student_attendance", "examinations", "report_cards",
    "grading_system", "fee_management", "scholarships",
    "school_transport", "school_hostel", "school_library",
    "school_events", "school_circulars", "parent_portal",
    "school_medical", "school_discipline", "school_certificates",
]


async def apply_tenant_template(db: AsyncSession, tenant: Tenant) -> int:
    """Auto-enable features based on tenant type.

    Returns the number of features enabled.
    """
    if tenant.tenant_type == TenantType.SCHOOL.value:
        enabled_codes = CORE_FEATURES + SCHOOL_FEATURES
    else:
        enabled_codes = CORE_FEATURES + CORPORATE_FEATURES

    # Fetch all feature flags
    stmt = select(FeatureFlag).where(FeatureFlag.code.in_(enabled_codes), FeatureFlag.is_active == True)
    result = await db.execute(stmt)
    features = result.scalars().all()

    count = 0
    for feature in features:
        # Check if already assigned
        existing_stmt = select(TenantFeature).where(
            TenantFeature.tenant_id == tenant.id,
            TenantFeature.feature_id == feature.id,
        )
        existing = (await db.execute(existing_stmt)).scalar_one_or_none()

        if existing:
            if not existing.is_enabled:
                existing.is_enabled = True
                from datetime import datetime, timezone
                existing.enabled_at = datetime.now(timezone.utc)
                count += 1
        else:
            from datetime import datetime, timezone
            db.add(TenantFeature(
                tenant_id=tenant.id,
                feature_id=feature.id,
                is_enabled=True,
                enabled_at=datetime.now(timezone.utc),
            ))
            count += 1

    await db.flush()
    return count


async def create_school_default_roles(db: AsyncSession, tenant_id):
    """Create default roles for school tenants."""
    from app.core.rbac import create_default_roles
    await create_default_roles(db, tenant_id)

    from app.models.role import Role, Permission, RolePermission

    ALL_SCHOOL_PERMS = [
        "student.create", "student.read", "student.update", "student.delete",
        "attendance.create", "attendance.read", "attendance.mark", "attendance.update",
        "exam.create", "exam.read", "exam.update", "exam.manage",
        "report.create", "report.read", "report.update",
        "class.create", "class.read", "class.update", "class.manage",
        "subject.create", "subject.read", "subject.update", "subject.manage",
        "timetable.create", "timetable.read", "timetable.update", "timetable.manage",
        "homework.create", "homework.read", "homework.update", "homework.delete",
        "marks.create", "marks.read", "marks.update", "marks.enter",
        "fee.create", "fee.read", "fee.update", "fee.manage", "fee.collect",
        "payroll.read",
        "library.create", "library.read", "library.update", "library.manage",
        "transport.create", "transport.read", "transport.update", "transport.manage",
        "hostel.create", "hostel.read", "hostel.update", "hostel.manage",
        "visitor.create", "visitor.read",
        "ess.read",
    ]

    school_roles = [
        {
            "name": "Principal",
            "codename": "principal",
            "description": "School principal with full academic access",
            "permissions": ALL_SCHOOL_PERMS,
        },
        {
            "name": "Vice Principal",
            "codename": "vice_principal",
            "description": "Vice principal with academic management",
            "permissions": [
                "student.read", "attendance.read", "exam.read", "report.read",
            ],
        },
        {
            "name": "Academic Coordinator",
            "codename": "academic_coordinator",
            "description": "Manages academics across grades",
            "permissions": [
                "class.manage", "subject.manage", "timetable.manage",
            ],
        },
        {
            "name": "Class Teacher",
            "codename": "class_teacher",
            "description": "Teacher assigned to a specific class",
            "permissions": [
                "student.read", "attendance.mark", "attendance.read",
                "homework.create", "homework.read",
            ],
        },
        {
            "name": "Subject Teacher",
            "codename": "subject_teacher",
            "description": "Teacher for specific subjects",
            "permissions": [
                "homework.create", "homework.read", "marks.enter", "marks.read",
            ],
        },
        {
            "name": "Accountant",
            "codename": "school_accountant",
            "description": "Manages fees and finances",
            "permissions": [
                "fee.manage", "fee.collect", "fee.read", "payroll.read",
            ],
        },
        {
            "name": "Librarian",
            "codename": "librarian",
            "description": "Manages library operations",
            "permissions": [
                "library.manage",
            ],
        },
        {
            "name": "Transport Manager",
            "codename": "transport_manager",
            "description": "Manages school transport",
            "permissions": [
                "transport.manage",
            ],
        },
        {
            "name": "Hostel Warden",
            "codename": "hostel_warden",
            "description": "Manages hostel operations",
            "permissions": [
                "hostel.manage",
            ],
        },
        {
            "name": "Receptionist",
            "codename": "receptionist",
            "description": "Front desk and visitor management",
            "permissions": [
                "visitor.create", "visitor.read",
            ],
        },
        {
            "name": "Parent",
            "codename": "parent",
            "description": "Parent portal access",
            "permissions": [
                "student.read_own", "attendance.read_own", "fee.read_own",
            ],
        },
        {
            "name": "Student",
            "codename": "student",
            "description": "Student portal access",
            "permissions": [
                "homework.read", "exam.read", "attendance.read_own",
            ],
        },
    ]

    all_perm_codenames = set()
    for role_def in school_roles:
        all_perm_codenames.update(role_def["permissions"])

    existing_perms_stmt = select(Permission.codename).where(
        Permission.tenant_id == tenant_id,
        Permission.codename.in_(all_perm_codenames),
    )
    existing_codenames = set((await db.execute(existing_perms_stmt)).scalars().all())

    perm_map = {}
    for codename in all_perm_codenames:
        if codename in existing_codenames:
            existing_perm = (await db.execute(
                select(Permission).where(Permission.tenant_id == tenant_id, Permission.codename == codename)
            )).scalar_one()
            perm_map[codename] = existing_perm
        else:
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

    for role_def in school_roles:
        existing = await db.execute(select(Role).where(Role.tenant_id == tenant_id, Role.name == role_def["name"]))
        if existing.scalar_one_or_none():
            continue

        role = Role(
            tenant_id=tenant_id,
            name=role_def["name"],
            codename=role_def["codename"],
            description=role_def["description"],
            is_system=False,
        )
        db.add(role)
        await db.flush()

        for perm_codename in role_def["permissions"]:
            if perm_codename in perm_map:
                rp = RolePermission(role_id=role.id, permission_id=perm_map[perm_codename].id, tenant_id=tenant_id)
                db.add(rp)

    await db.flush()
