"""System Settings API endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.tenant import Tenant

router = APIRouter(dependencies=[Depends(require_permissions("settings.read"))])


@router.get("/")
async def get_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tenant = await db.get(Tenant, current_user.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    return {
        "company": {
            "name": tenant.name,
            "slug": tenant.slug,
            "email": tenant.email,
            "mobile": tenant.mobile,
            "timezone": tenant.timezone,
            "currency": tenant.currency,
            "financial_year_start": tenant.financial_year_start,
            "gst_number": tenant.gst_number,
            "pan_number": tenant.pan_number,
            "company_code": tenant.company_code,
            "contact_person": tenant.contact_person,
        },
        "subscription": {
            "status": tenant.subscription_status,
            "plan": tenant.subscription_plan,
        },
    }


class CompanySettingsUpdate(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    mobile: Optional[str] = None
    timezone: Optional[str] = None
    currency: Optional[str] = None
    financial_year_start: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None
    contact_person: Optional[str] = None


@router.put("/company")
async def update_company_settings(
    data: CompanySettingsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tenant = await db.get(Tenant, current_user.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        if value is not None:
            setattr(tenant, field, value)
    await db.commit()
    return {"message": "Company settings updated"}
