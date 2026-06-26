"""Super Admin Subscription Plans endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.user import User
from app.models.subscription import SubscriptionPlan

router = APIRouter()


class PlanCreateRequest(BaseModel):
    name: str = Field(..., max_length=255)
    code: str = Field(..., max_length=100)
    description: Optional[str] = None
    price_monthly: float = 0
    price_quarterly: float = 0
    price_half_yearly: float = 0
    price_annual: float = 0
    price_lifetime: float = 0
    max_employees: int = 50
    max_branches: int = 5
    max_departments: int = 10
    max_devices: int = 5
    max_admin_users: int = 2
    max_hr_users: int = 5
    max_storage_mb: int = 1024
    max_api_calls: int = 10000
    max_mobile_logins: int = 50
    trial_days: int = 14
    features: list[str] = []
    is_active: bool = True
    sort_order: int = 0


class PlanUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_monthly: Optional[float] = None
    price_quarterly: Optional[float] = None
    price_half_yearly: Optional[float] = None
    price_annual: Optional[float] = None
    price_lifetime: Optional[float] = None
    max_employees: Optional[int] = None
    max_branches: Optional[int] = None
    max_departments: Optional[int] = None
    max_devices: Optional[int] = None
    max_admin_users: Optional[int] = None
    max_hr_users: Optional[int] = None
    max_storage_mb: Optional[int] = None
    max_api_calls: Optional[int] = None
    max_mobile_logins: Optional[int] = None
    trial_days: Optional[int] = None
    features: Optional[list[str]] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


@router.get("/")
async def list_plans(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List all subscription plans."""
    stmt = select(SubscriptionPlan).order_by(SubscriptionPlan.sort_order, SubscriptionPlan.name)
    result = await db.execute(stmt)
    plans = result.scalars().all()
    return [
        {
            "id": str(p.id),
            "name": p.name,
            "code": p.code,
            "description": p.description,
            "price_monthly": p.price_monthly,
            "price_quarterly": p.price_quarterly,
            "price_half_yearly": p.price_half_yearly,
            "price_annual": p.price_annual,
            "price_lifetime": p.price_lifetime,
            "max_employees": p.max_employees,
            "max_branches": p.max_branches,
            "max_departments": p.max_departments,
            "max_devices": p.max_devices,
            "max_admin_users": p.max_admin_users,
            "max_hr_users": p.max_hr_users,
            "trial_days": p.trial_days,
            "features": p.features,
            "is_active": p.is_active,
            "sort_order": p.sort_order,
        }
        for p in plans
    ]


@router.post("/")
async def create_plan(
    data: PlanCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Create a subscription plan."""
    existing = await db.execute(select(SubscriptionPlan).where(SubscriptionPlan.code == data.code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Plan code already exists")

    plan = SubscriptionPlan(**data.model_dump())
    db.add(plan)
    await db.commit()
    return {"id": str(plan.id), "code": plan.code}


@router.put("/{plan_id}")
async def update_plan(
    plan_id: uuid.UUID,
    data: PlanUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Update a subscription plan."""
    plan = await db.get(SubscriptionPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(plan, field, value)
    await db.commit()
    return {"id": str(plan.id), "code": plan.code}


@router.delete("/{plan_id}")
async def deactivate_plan(
    plan_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Deactivate a subscription plan."""
    plan = await db.get(SubscriptionPlan, plan_id)
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    plan.is_active = False
    await db.commit()
    return {"id": str(plan.id), "status": "deactivated"}
