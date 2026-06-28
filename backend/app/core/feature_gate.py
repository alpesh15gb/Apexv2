"""Feature flag engine for per-tenant feature gating."""

import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.feature import FeatureFlag, TenantFeature


class FeatureGate:
    """Check and manage feature flags per tenant."""

    @staticmethod
    async def is_enabled(db: AsyncSession, tenant_id: uuid.UUID, feature_code: str) -> bool:
        """Check if a feature is enabled for a tenant."""
        stmt = (
            select(TenantFeature.is_enabled)
            .join(FeatureFlag, FeatureFlag.id == TenantFeature.feature_id)
            .where(
                TenantFeature.tenant_id == tenant_id,
                FeatureFlag.code == feature_code,
                FeatureFlag.is_active == True,
            )
        )
        result = await db.execute(stmt)
        row = result.scalar_one_or_none()
        return row is True

    @staticmethod
    async def enable_feature(db: AsyncSession, tenant_id: uuid.UUID, feature_code: str, enabled_by: uuid.UUID = None) -> bool:
        """Enable a feature for a tenant."""
        feat_stmt = select(FeatureFlag).where(FeatureFlag.code == feature_code, FeatureFlag.is_active == True)
        feat_result = await db.execute(feat_stmt)
        feature = feat_result.scalar_one_or_none()
        if not feature:
            return False

        existing_stmt = select(TenantFeature).where(
            TenantFeature.tenant_id == tenant_id,
            TenantFeature.feature_id == feature.id,
        )
        existing_result = await db.execute(existing_stmt)
        tf = existing_result.scalar_one_or_none()

        if tf:
            tf.is_enabled = True
            tf.enabled_by = enabled_by
            from datetime import datetime, timezone
            tf.enabled_at = datetime.now(timezone.utc)
        else:
            from datetime import datetime, timezone
            tf = TenantFeature(
                tenant_id=tenant_id,
                feature_id=feature.id,
                is_enabled=True,
                enabled_at=datetime.now(timezone.utc),
                enabled_by=enabled_by,
            )
            db.add(tf)

        await db.flush()
        return True

    @staticmethod
    async def disable_feature(db: AsyncSession, tenant_id: uuid.UUID, feature_code: str) -> bool:
        """Disable a feature for a tenant."""
        stmt = (
            select(TenantFeature)
            .join(FeatureFlag, FeatureFlag.id == TenantFeature.feature_id)
            .where(
                TenantFeature.tenant_id == tenant_id,
                FeatureFlag.code == feature_code,
            )
        )
        result = await db.execute(stmt)
        tf = result.scalar_one_or_none()
        if tf:
            tf.is_enabled = False
            tf.enabled_at = None
            tf.enabled_by = None
            await db.flush()
            return True
        return False

    @staticmethod
    async def get_tenant_features(db: AsyncSession, tenant_id: uuid.UUID) -> list[dict]:
        """Get all features with their enabled status for a tenant."""
        stmt = (
            select(FeatureFlag, TenantFeature.is_enabled)
            .outerjoin(
                TenantFeature,
                (TenantFeature.feature_id == FeatureFlag.id) & (TenantFeature.tenant_id == tenant_id),
            )
            .where(FeatureFlag.is_active == True)
            .order_by(FeatureFlag.category, FeatureFlag.sort_order, FeatureFlag.name)
        )
        result = await db.execute(stmt)
        rows = result.all()

        features = []
        for feat, is_enabled in rows:
            features.append({
                "id": str(feat.id),
                "name": feat.name,
                "code": feat.code,
                "description": feat.description,
                "module": feat.module,
                "category": feat.category,
                "is_enabled": is_enabled or False,
            })
        return features

    @staticmethod
    async def bulk_set_features(db: AsyncSession, tenant_id: uuid.UUID, feature_codes: list[str], enabled: bool, enabled_by: uuid.UUID = None) -> int:
        """Enable or disable multiple features at once."""
        count = 0
        for code in feature_codes:
            if enabled:
                ok = await FeatureGate.enable_feature(db, tenant_id, code, enabled_by)
            else:
                ok = await FeatureGate.disable_feature(db, tenant_id, code)
            if ok:
                count += 1
        return count


# All available features - seeded on first run
DEFAULT_FEATURES = [
    {"name": "Attendance", "code": "attendance", "module": "attendance", "category": "Core HR", "sort_order": 1},
    {"name": "Leave Management", "code": "leave", "module": "leave", "category": "Core HR", "sort_order": 2},
    {"name": "Shift Management", "code": "shift", "module": "shift", "category": "Core HR", "sort_order": 3},
    {"name": "Overtime", "code": "overtime", "module": "attendance", "category": "Core HR", "sort_order": 4},
    {"name": "Outdoor Duty", "code": "outdoor_duty", "module": "attendance", "category": "Core HR", "sort_order": 5},
    {"name": "Payroll", "code": "payroll", "module": "payroll", "category": "Finance", "sort_order": 10},
    {"name": "Expense Claims", "code": "expense", "module": "finance", "category": "Finance", "sort_order": 11},
    {"name": "Tax Declarations", "code": "tax", "module": "finance", "category": "Finance", "sort_order": 12},
    {"name": "Benefits", "code": "benefits", "module": "finance", "category": "Finance", "sort_order": 13},
    {"name": "Loans", "code": "loans", "module": "finance", "category": "Finance", "sort_order": 14},
    {"name": "Travel Requests", "code": "travel", "module": "hr", "category": "HR Operations", "sort_order": 20},
    {"name": "Company Assets", "code": "assets", "module": "hr", "category": "HR Operations", "sort_order": 21},
    {"name": "Documents", "code": "documents", "module": "hr", "category": "HR Operations", "sort_order": 22},
    {"name": "Onboarding", "code": "onboarding", "module": "hr", "category": "HR Operations", "sort_order": 23},
    {"name": "Exit Management", "code": "exit_management", "module": "hr", "category": "HR Operations", "sort_order": 24},
    {"name": "Announcements", "code": "announcements", "module": "hr", "category": "HR Operations", "sort_order": 25},
    {"name": "Polls", "code": "polls", "module": "hr", "category": "HR Operations", "sort_order": 26},
    {"name": "Visitor Management", "code": "visitor", "module": "visitor", "category": "Security", "sort_order": 30},
    {"name": "Access Control", "code": "access_control", "module": "access", "category": "Security", "sort_order": 31},
    {"name": "Biometric Integration", "code": "biometric", "module": "essl", "category": "Integration", "sort_order": 40},
    {"name": "Device Management", "code": "device", "module": "device", "category": "Integration", "sort_order": 41},
    {"name": "GPS Attendance", "code": "gps_attendance", "module": "attendance", "category": "Advanced", "sort_order": 50},
    {"name": "Face Recognition", "code": "face_recognition", "module": "attendance", "category": "Advanced", "sort_order": 51},
    {"name": "Geo Fencing", "code": "geo_fencing", "module": "attendance", "category": "Advanced", "sort_order": 52},
    {"name": "Reports", "code": "reports", "module": "reports", "category": "Analytics", "sort_order": 60},
    {"name": "Analytics", "code": "analytics", "module": "reports", "category": "Analytics", "sort_order": 61},
    {"name": "API Access", "code": "api_access", "module": "system", "category": "Platform", "sort_order": 70},
    {"name": "Webhooks", "code": "webhooks", "module": "system", "category": "Platform", "sort_order": 71},
    {"name": "Custom Branding", "code": "custom_branding", "module": "system", "category": "Platform", "sort_order": 72},
    {"name": "White Label", "code": "white_label", "module": "system", "category": "Platform", "sort_order": 73},
    {"name": "Employee Self Service", "code": "ess", "module": "ess", "category": "Employee", "sort_order": 80},
    {"name": "Chat", "code": "chat", "module": "communication", "category": "Communication", "sort_order": 90},
    {"name": "Helpdesk", "code": "helpdesk", "module": "support", "category": "Communication", "sort_order": 91},
    {"name": "Notification Templates", "code": "notification_templates", "module": "notification", "category": "Communication", "sort_order": 92},
    # School ERP Features
    {"name": "Student Management", "code": "student_management", "module": "school", "category": "School Core", "sort_order": 100},
    {"name": "Admissions", "code": "admissions", "module": "school", "category": "School Core", "sort_order": 101},
    {"name": "Academic Year", "code": "academic_year", "module": "school", "category": "School Core", "sort_order": 102},
    {"name": "Class Management", "code": "class_management", "module": "school", "category": "School Core", "sort_order": 103},
    {"name": "Subject Management", "code": "subject_management", "module": "school", "category": "School Core", "sort_order": 104},
    {"name": "Timetable", "code": "school_timetable", "module": "school", "category": "Academics", "sort_order": 110},
    {"name": "Homework", "code": "homework", "module": "school", "category": "Academics", "sort_order": 111},
    {"name": "Assignments", "code": "school_assignments", "module": "school", "category": "Academics", "sort_order": 112},
    {"name": "Lesson Planning", "code": "lesson_planning", "module": "school", "category": "Academics", "sort_order": 113},
    {"name": "Student Attendance", "code": "student_attendance", "module": "school", "category": "Academics", "sort_order": 114},
    {"name": "Examinations", "code": "examinations", "module": "school", "category": "Assessment", "sort_order": 120},
    {"name": "Report Cards", "code": "report_cards", "module": "school", "category": "Assessment", "sort_order": 121},
    {"name": "Grading System", "code": "grading_system", "module": "school", "category": "Assessment", "sort_order": 122},
    {"name": "Fee Management", "code": "fee_management", "module": "school", "category": "Finance", "sort_order": 130},
    {"name": "Scholarships", "code": "scholarships", "module": "school", "category": "Finance", "sort_order": 131},
    {"name": "Transport", "code": "school_transport", "module": "school", "category": "Operations", "sort_order": 140},
    {"name": "Hostel", "code": "school_hostel", "module": "school", "category": "Operations", "sort_order": 141},
    {"name": "Library", "code": "school_library", "module": "school", "category": "Operations", "sort_order": 142},
    {"name": "School Events", "code": "school_events", "module": "school", "category": "Communication", "sort_order": 150},
    {"name": "Circulars", "code": "school_circulars", "module": "school", "category": "Communication", "sort_order": 151},
    {"name": "Parent Portal", "code": "parent_portal", "module": "school", "category": "Communication", "sort_order": 152},
    {"name": "Medical Records", "code": "school_medical", "module": "school", "category": "Student Welfare", "sort_order": 160},
    {"name": "Discipline", "code": "school_discipline", "module": "school", "category": "Student Welfare", "sort_order": 161},
    {"name": "Certificates", "code": "school_certificates", "module": "school", "category": "Administration", "sort_order": 170},
]


async def seed_feature_flags(db: AsyncSession):
    """Seed default feature flags if they don't exist."""
    for feat_def in DEFAULT_FEATURES:
        existing = await db.execute(select(FeatureFlag).where(FeatureFlag.code == feat_def["code"]))
        if not existing.scalar_one_or_none():
            db.add(FeatureFlag(**feat_def))
    await db.commit()
