"""Super Admin Tenant Management endpoints."""

import uuid
from datetime import datetime, timezone, date, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, func, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.tenant import Tenant
from app.models.user import User
from app.models.employee import Employee
from app.models.subscription import TenantSubscription, ResourceLimit, SubscriptionPlan
from app.models.feature import TenantFeature, FeatureFlag

router = APIRouter()


class TenantCreateRequest(BaseModel):
    name: str = Field(..., max_length=255)
    slug: str = Field(..., max_length=255)
    email: Optional[str] = None
    mobile: Optional[str] = None
    contact_person: Optional[str] = None
    company_code: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None
    currency: str = "INR"
    timezone: str = "Asia/Kolkata"
    subscription_plan_code: Optional[str] = None
    tenant_type: str = "corporate"  # corporate/school


class TenantUpdateRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    mobile: Optional[str] = None
    contact_person: Optional[str] = None
    company_code: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None
    currency: Optional[str] = None
    timezone: Optional[str] = None
    is_active: Optional[bool] = None
    subscription_status: Optional[str] = None


class ResourceLimitUpdate(BaseModel):
    resource_key: str
    max_value: int
    is_unlimited: bool = False


class TenantFeatureUpdate(BaseModel):
    feature_codes: list[str] = []
    enabled: bool = True


@router.get("/")
async def list_tenants(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: Optional[str] = None,
    search: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List all tenants with filters."""
    count_stmt = select(func.count(Tenant.id))
    stmt = select(Tenant)

    if status:
        count_stmt = count_stmt.where(Tenant.subscription_status == status)
        stmt = stmt.where(Tenant.subscription_status == status)
    if search:
        escaped = search.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
        search_filter = or_(
            Tenant.name.ilike(f"%{escaped}%"),
            Tenant.slug.ilike(f"%{escaped}%"),
            Tenant.email.ilike(f"%{escaped}%"),
        )
        count_stmt = count_stmt.where(search_filter)
        stmt = stmt.where(search_filter)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(Tenant.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    tenants = result.scalars().all()

    items = []
    for t in tenants:
        emp_count = (await db.execute(
            select(func.count(Employee.id)).where(Employee.tenant_id == t.id)
        )).scalar() or 0
        user_count = (await db.execute(
            select(func.count(User.id)).where(User.tenant_id == t.id)
        )).scalar() or 0
        items.append({
            "id": str(t.id),
            "name": t.name,
            "slug": t.slug,
            "email": t.email,
            "mobile": t.mobile,
            "contact_person": t.contact_person,
            "company_code": t.company_code,
            "gst_number": t.gst_number,
            "pan_number": t.pan_number,
            "currency": t.currency,
            "timezone": t.timezone,
            "subscription_status": t.subscription_status,
            "is_active": t.is_active,
            "employee_count": emp_count,
            "user_count": user_count,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        })

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.get("/{tenant_id}")
async def get_tenant_detail(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get detailed tenant information."""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    emp_count = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tenant_id)
    )).scalar() or 0
    user_count = (await db.execute(
        select(func.count(User.id)).where(User.tenant_id == tenant_id)
    )).scalar() or 0

    sub_stmt = select(TenantSubscription).where(TenantSubscription.tenant_id == tenant_id)
    sub_result = await db.execute(sub_stmt)
    subscription = sub_result.scalar_one_or_none()

    limits_stmt = select(ResourceLimit).where(ResourceLimit.tenant_id == tenant_id)
    limits_result = await db.execute(limits_stmt)
    limits = limits_result.scalars().all()

    features = await db.execute(
        select(FeatureFlag.code, TenantFeature.is_enabled)
        .outerjoin(TenantFeature, (TenantFeature.feature_id == FeatureFlag.id) & (TenantFeature.tenant_id == tenant_id))
        .where(FeatureFlag.is_active == True)
    )
    feature_list = [{"code": code, "enabled": enabled or False} for code, enabled in features.all()]

    return {
        "id": str(tenant.id),
        "name": tenant.name,
        "slug": tenant.slug,
        "email": tenant.email,
        "mobile": tenant.mobile,
        "contact_person": tenant.contact_person,
        "company_code": tenant.company_code,
        "gst_number": tenant.gst_number,
        "pan_number": tenant.pan_number,
        "currency": tenant.currency,
        "timezone": tenant.timezone,
        "financial_year_start": tenant.financial_year_start,
        "subscription_status": tenant.subscription_status,
        "is_active": tenant.is_active,
        "employee_count": emp_count,
        "user_count": user_count,
        "subscription": {
            "status": subscription.status if subscription else None,
            "plan_id": str(subscription.plan_id) if subscription else None,
            "start_date": str(subscription.start_date) if subscription else None,
            "end_date": str(subscription.end_date) if subscription else None,
            "billing_cycle": subscription.billing_cycle if subscription else None,
        } if subscription else None,
        "limits": [
            {"key": l.resource_key, "max": l.max_value, "current": l.current_value, "unlimited": l.is_unlimited}
            for l in limits
        ],
        "features": feature_list,
        "created_at": tenant.created_at.isoformat() if tenant.created_at else None,
    }


@router.post("/")
async def create_tenant(
    data: TenantCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Create a new tenant."""
    existing = await db.execute(select(Tenant).where(Tenant.slug == data.slug))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Slug already exists")

    trial_end = datetime.now(timezone.utc) + timedelta(days=14)
    tenant = Tenant(
        name=data.name,
        slug=data.slug,
        email=data.email,
        mobile=data.mobile,
        contact_person=data.contact_person,
        company_code=data.company_code,
        gst_number=data.gst_number,
        pan_number=data.pan_number,
        currency=data.currency,
        timezone=data.timezone,
        tenant_type=data.tenant_type,
        subscription_status="trial",
        trial_ends_at=trial_end.replace(hour=23, minute=59, second=59),
        is_active=True,
    )
    db.add(tenant)
    await db.flush()

    from app.core.rbac import create_default_roles
    await create_default_roles(db, tenant.id)

    await db.commit()
    return {"id": str(tenant.id), "name": tenant.name, "slug": tenant.slug}


@router.put("/{tenant_id}")
async def update_tenant(
    tenant_id: uuid.UUID,
    data: TenantUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Update tenant information."""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(tenant, field, value)
    await db.commit()
    return {"id": str(tenant.id), "name": tenant.name}


@router.post("/{tenant_id}/suspend")
async def suspend_tenant(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Suspend a tenant."""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    tenant.subscription_status = "suspended"
    tenant.is_active = False
    await db.commit()
    return {"id": str(tenant.id), "status": "suspended"}


@router.post("/{tenant_id}/activate")
async def activate_tenant(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Activate a suspended tenant."""
    tenant = await db.get(Tenant, tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")
    tenant.subscription_status = "active"
    tenant.is_active = True
    await db.commit()
    return {"id": str(tenant.id), "status": "active"}


@router.get("/{tenant_id}/limits")
async def get_tenant_limits(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get resource limits for a tenant."""
    stmt = select(ResourceLimit).where(ResourceLimit.tenant_id == tenant_id)
    result = await db.execute(stmt)
    limits = result.scalars().all()
    return [
        {"key": l.resource_key, "max": l.max_value, "current": l.current_value, "unlimited": l.is_unlimited}
        for l in limits
    ]


@router.put("/{tenant_id}/limits")
async def update_tenant_limits(
    tenant_id: uuid.UUID,
    limits: list[ResourceLimitUpdate],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Update resource limits for a tenant."""
    for limit_data in limits:
        stmt = select(ResourceLimit).where(
            ResourceLimit.tenant_id == tenant_id,
            ResourceLimit.resource_key == limit_data.resource_key,
        )
        result = await db.execute(stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.max_value = limit_data.max_value
            existing.is_unlimited = limit_data.is_unlimited
        else:
            db.add(ResourceLimit(
                tenant_id=tenant_id,
                resource_key=limit_data.resource_key,
                max_value=limit_data.max_value,
                is_unlimited=limit_data.is_unlimited,
            ))

    await db.commit()
    return {"updated": len(limits)}


@router.get("/{tenant_id}/features")
async def get_tenant_features(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get feature flags for a tenant."""
    from app.core.feature_gate import FeatureGate
    return await FeatureGate.get_tenant_features(db, tenant_id)


@router.put("/{tenant_id}/features")
async def update_tenant_features(
    tenant_id: uuid.UUID,
    features: TenantFeatureUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Enable/disable features for a tenant."""
    from app.core.feature_gate import FeatureGate
    count = await FeatureGate.bulk_set_features(db, tenant_id, features.feature_codes, features.enabled, current_user.id)
    await db.commit()
    return {"updated": count}


@router.get("/{tenant_id}/users")
async def get_tenant_users(
    tenant_id: uuid.UUID,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List users for a specific tenant."""
    stmt = (
        select(User)
        .where(User.tenant_id == tenant_id)
        .order_by(User.created_at.desc())
        .offset((page - 1) * page_size)
        .limit(page_size)
    )
    result = await db.execute(stmt)
    users = result.scalars().all()

    count_stmt = select(func.count(User.id)).where(User.tenant_id == tenant_id)
    total = (await db.execute(count_stmt)).scalar() or 0

    return {
        "items": [
            {
                "id": str(u.id),
                "email": u.email,
                "full_name": u.full_name,
                "is_active": u.is_active,
                "is_superuser": u.is_superuser,
                "created_at": u.created_at.isoformat() if u.created_at else None,
            }
            for u in users
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }
