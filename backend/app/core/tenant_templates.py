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

    # Add school-specific roles
    from app.models.role import Role, Permission, RolePermission

    school_roles = [
        {"name": "Principal", "codename": "principal", "description": "School principal with full academic access"},
        {"name": "Vice Principal", "codename": "vice_principal", "description": "Vice principal with academic management"},
        {"name": "Academic Coordinator", "codename": "academic_coordinator", "description": "Manages academics across grades"},
        {"name": "Class Teacher", "codename": "class_teacher", "description": "Teacher assigned to a specific class"},
        {"name": "Subject Teacher", "codename": "subject_teacher", "description": "Teacher for specific subjects"},
        {"name": "Accountant", "codename": "school_accountant", "description": "Manages fees and finances"},
        {"name": "Librarian", "codename": "librarian", "description": "Manages library operations"},
        {"name": "Transport Manager", "codename": "transport_manager", "description": "Manages school transport"},
        {"name": "Hostel Warden", "codename": "hostel_warden", "description": "Manages hostel operations"},
        {"name": "Receptionist", "codename": "receptionist", "description": "Front desk and visitor management"},
        {"name": "Parent", "codename": "parent", "description": "Parent portal access"},
        {"name": "Student", "codename": "student", "description": "Student portal access"},
    ]

    for role_def in school_roles:
        existing = await db.execute(select(Role).where(Role.tenant_id == tenant_id, Role.codename == role_def["codename"]))
        if not existing.scalar_one_or_none():
            db.add(Role(
                tenant_id=tenant_id,
                name=role_def["name"],
                codename=role_def["codename"],
                description=role_def["description"],
                is_system=False,
            ))

    await db.flush()
