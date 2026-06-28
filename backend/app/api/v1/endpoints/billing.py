"""Billing & Subscription API endpoints."""

import uuid
from datetime import datetime, timezone, date, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.user import User
from app.models.tenant import Tenant
from app.models.subscription import SubscriptionPlan, TenantSubscription

router = APIRouter()


class SubscriptionCancel(BaseModel):
    reason: Optional[str] = ""


class SubscriptionCreate(BaseModel):
    tenant_id: uuid.UUID
    plan_id: uuid.UUID
    billing_cycle: str = "monthly"
    auto_renewal: bool = True


class PlanUpgrade(BaseModel):
    new_plan_id: uuid.UUID
    billing_cycle: Optional[str] = None
    prorate: bool = True


@router.get("/subscriptions")
async def list_subscriptions(
    status: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List all subscriptions across tenants."""
    stmt = select(TenantSubscription, Tenant.name, SubscriptionPlan.name).join(
        Tenant, Tenant.id == TenantSubscription.tenant_id
    ).join(
        SubscriptionPlan, SubscriptionPlan.id == TenantSubscription.plan_id
    )
    if status:
        stmt = stmt.where(TenantSubscription.status == status)
    stmt = stmt.order_by(TenantSubscription.created_at.desc())

    result = await db.execute(stmt)
    rows = result.all()

    return [
        {
            "id": str(sub.id),
            "tenant_id": str(sub.tenant_id),
            "tenant_name": tenant_name,
            "plan_name": plan_name,
            "status": sub.status,
            "billing_cycle": sub.billing_cycle,
            "start_date": str(sub.start_date),
            "end_date": str(sub.end_date) if sub.end_date else None,
            "auto_renewal": sub.auto_renewal,
            "last_payment_amount": sub.last_payment_amount,
            "last_payment_date": str(sub.last_payment_date) if sub.last_payment_date else None,
        }
        for sub, tenant_name, plan_name in rows
    ]


@router.post("/subscriptions")
async def create_subscription(
    data: SubscriptionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Create a new subscription for a tenant."""
    plan = await db.get(SubscriptionPlan, data.plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    today = date.today()
    if data.billing_cycle == "monthly":
        end = today + timedelta(days=30)
    elif data.billing_cycle == "quarterly":
        end = today + timedelta(days=90)
    elif data.billing_cycle == "annual":
        end = today + timedelta(days=365)
    elif data.billing_cycle == "lifetime":
        end = None
    else:
        end = today + timedelta(days=30)

    sub = TenantSubscription(
        tenant_id=data.tenant_id,
        plan_id=data.plan_id,
        start_date=today,
        end_date=end,
        renewal_date=end,
        status="active",
        billing_cycle=data.billing_cycle,
        payment_status="paid",
        auto_renewal=data.auto_renewal,
        last_payment_amount=0,
        last_payment_date=today,
    )
    db.add(sub)

    tenant = await db.get(Tenant, data.tenant_id)
    if tenant:
        tenant.subscription_status = "active"

    await db.commit()
    return {"id": str(sub.id), "status": "active"}


@router.put("/subscriptions/{sub_id}/upgrade")
async def upgrade_subscription(
    sub_id: uuid.UUID,
    data: PlanUpgrade,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Upgrade a subscription to a new plan."""
    sub = await db.get(TenantSubscription, sub_id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    new_plan = await db.get(SubscriptionPlan, data.new_plan_id)
    if not new_plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    sub.plan_id = data.new_plan_id
    if data.billing_cycle:
        sub.billing_cycle = data.billing_cycle
    await db.commit()
    return {"id": str(sub.id), "new_plan": new_plan.name, "status": "active"}


@router.post("/subscriptions/{sub_id}/renew")
async def renew_subscription(
    sub_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Renew a subscription."""
    sub = await db.get(TenantSubscription, sub_id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    today = date.today()
    if sub.billing_cycle == "monthly":
        new_end = today + timedelta(days=30)
    elif sub.billing_cycle == "quarterly":
        new_end = today + timedelta(days=90)
    elif sub.billing_cycle == "annual":
        new_end = today + timedelta(days=365)
    else:
        new_end = today + timedelta(days=30)

    sub.start_date = today
    sub.end_date = new_end
    sub.renewal_date = new_end
    sub.status = "active"
    sub.payment_status = "paid"
    sub.last_payment_date = today

    tenant = await db.get(Tenant, sub.tenant_id)
    if tenant:
        tenant.subscription_status = "active"

    await db.commit()
    return {"id": str(sub.id), "status": "active", "end_date": str(new_end)}


@router.post("/subscriptions/{sub_id}/suspend")
async def suspend_subscription(
    sub_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Suspend a subscription."""
    sub = await db.get(TenantSubscription, sub_id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    sub.status = "suspended"
    tenant = await db.get(Tenant, sub.tenant_id)
    if tenant:
        tenant.subscription_status = "suspended"
    await db.commit()
    return {"id": str(sub.id), "status": "suspended"}


@router.post("/subscriptions/{sub_id}/cancel")
async def cancel_subscription(
    sub_id: uuid.UUID,
    data: SubscriptionCancel,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Cancel a subscription."""
    sub = await db.get(TenantSubscription, sub_id)
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    sub.status = "cancelled"
    sub.cancelled_at = datetime.now(timezone.utc)
    sub.cancel_reason = data.reason

    tenant = await db.get(Tenant, sub.tenant_id)
    if tenant:
        tenant.subscription_status = "expired"
    await db.commit()
    return {"id": str(sub.id), "status": "cancelled"}


@router.post("/check-expired")
async def check_expired_subscriptions(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Check and mark expired subscriptions. Run as scheduled job."""
    today = date.today()
    expired = await db.execute(
        select(TenantSubscription).where(
            TenantSubscription.status == "active",
            TenantSubscription.end_date.isnot(None),
            TenantSubscription.end_date < today,
        )
    )
    expired_subs = expired.scalars().all()
    count = 0
    for sub in expired_subs:
        grace_end = sub.end_date + timedelta(days=7) if sub.end_date else None
        if grace_end and today > grace_end:
            sub.status = "expired"
            tenant = await db.get(Tenant, sub.tenant_id)
            if tenant:
                tenant.subscription_status = "expired"
            count += 1
        else:
            sub.status = "grace_period"
            count += 1

    await db.commit()
    return {"processed": count}
