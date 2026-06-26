"""Seed default data: subscription plans and feature flags."""

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.models.subscription import SubscriptionPlan
from app.models.feature import FeatureFlag
from app.core.feature_gate import DEFAULT_FEATURES


DEFAULT_PLANS = [
    {
        "name": "Starter",
        "code": "starter",
        "description": "For small businesses getting started with HRMS",
        "price_monthly": 999,
        "price_quarterly": 2499,
        "price_half_yearly": 4499,
        "price_annual": 7999,
        "price_lifetime": 49999,
        "max_employees": 25,
        "max_branches": 2,
        "max_departments": 5,
        "max_devices": 2,
        "max_admin_users": 1,
        "max_hr_users": 2,
        "max_storage_mb": 512,
        "max_api_calls": 5000,
        "max_mobile_logins": 25,
        "trial_days": 14,
        "features": ["attendance", "leave", "shift", "employee", "reports", "announcements", "ess"],
        "sort_order": 1,
    },
    {
        "name": "Professional",
        "code": "professional",
        "description": "For growing companies with advanced HR needs",
        "price_monthly": 2999,
        "price_quarterly": 7499,
        "price_half_yearly": 13499,
        "price_annual": 23999,
        "price_lifetime": 149999,
        "max_employees": 100,
        "max_branches": 5,
        "max_departments": 15,
        "max_devices": 10,
        "max_admin_users": 3,
        "max_hr_users": 10,
        "max_storage_mb": 2048,
        "max_api_calls": 20000,
        "max_mobile_logins": 100,
        "trial_days": 14,
        "features": [
            "attendance", "leave", "shift", "overtime", "outdoor_duty",
            "payroll", "expense", "loans", "travel", "assets", "documents",
            "onboarding", "exit_management", "announcements", "polls",
            "visitor", "biometric", "device", "reports", "ess",
            "notification_templates",
        ],
        "sort_order": 2,
    },
    {
        "name": "Enterprise",
        "code": "enterprise",
        "description": "Full-featured plan for large organizations",
        "price_monthly": 5999,
        "price_quarterly": 14999,
        "price_half_yearly": 26999,
        "price_annual": 47999,
        "price_lifetime": 299999,
        "max_employees": 500,
        "max_branches": 20,
        "max_departments": 50,
        "max_devices": 50,
        "max_admin_users": 10,
        "max_hr_users": 50,
        "max_storage_mb": 10240,
        "max_api_calls": 100000,
        "max_mobile_logins": 500,
        "trial_days": 30,
        "features": [
            "attendance", "leave", "shift", "overtime", "outdoor_duty",
            "payroll", "expense", "tax", "benefits", "loans", "travel",
            "assets", "documents", "onboarding", "exit_management",
            "announcements", "polls", "visitor", "access_control",
            "biometric", "device", "gps_attendance", "geo_fencing",
            "reports", "analytics", "ess", "api_access", "webhooks",
            "custom_branding", "notification_templates", "helpdesk",
        ],
        "sort_order": 3,
    },
    {
        "name": "Unlimited",
        "code": "unlimited",
        "description": "No limits. Everything included.",
        "price_monthly": 9999,
        "price_quarterly": 24999,
        "price_half_yearly": 44999,
        "price_annual": 79999,
        "price_lifetime": 499999,
        "max_employees": 99999,
        "max_branches": 99999,
        "max_departments": 99999,
        "max_devices": 99999,
        "max_admin_users": 99999,
        "max_hr_users": 99999,
        "max_storage_mb": 102400,
        "max_api_calls": 1000000,
        "max_mobile_logins": 99999,
        "trial_days": 30,
        "features": [f["code"] for f in DEFAULT_FEATURES],
        "sort_order": 4,
    },
]


async def seed_subscription_plans(db: AsyncSession):
    """Seed default subscription plans."""
    for plan_def in DEFAULT_PLANS:
        existing = await db.execute(
            select(SubscriptionPlan).where(SubscriptionPlan.code == plan_def["code"])
        )
        if not existing.scalar_one_or_none():
            db.add(SubscriptionPlan(**plan_def))
    await db.commit()


async def seed_all(db: AsyncSession):
    """Seed all default data."""
    await seed_subscription_plans(db)
    from app.core.feature_gate import seed_feature_flags
    await seed_feature_flags(db)
