"""Super Admin Dashboard endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.tenant import Tenant
from app.models.user import User
from app.models.employee import Employee
from app.models.subscription import TenantSubscription

router = APIRouter()


@router.get("/stats")
async def get_admin_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get super admin dashboard statistics."""
    tenant_count = (await db.execute(select(func.count(Tenant.id)))).scalar() or 0
    active_tenants = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.subscription_status == "active")
    )).scalar() or 0
    trial_tenants = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.subscription_status == "trial")
    )).scalar() or 0
    suspended_tenants = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.subscription_status == "suspended")
    )).scalar() or 0
    total_employees = (await db.execute(select(func.count(Employee.id)))).scalar() or 0
    total_users = (await db.execute(select(func.count(User.id)))).scalar() or 0
    active_users = (await db.execute(
        select(func.count(User.id)).where(User.is_active == True)
    )).scalar() or 0

    expired_subs = (await db.execute(
        select(func.count(TenantSubscription.id)).where(TenantSubscription.status == "expired")
    )).scalar() or 0

    return {
        "total_tenants": tenant_count,
        "active_tenants": active_tenants,
        "trial_tenants": trial_tenants,
        "suspended_tenants": suspended_tenants,
        "expired_subscriptions": expired_subs,
        "total_employees": total_employees,
        "total_users": total_users,
        "active_users": active_users,
    }


@router.get("/recent-activity")
async def get_recent_activity(
    tenant_id: Optional[uuid.UUID] = None,
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get recent login activity, optionally filtered by tenant."""
    from app.models.audit_log import AuditLog
    stmt = select(AuditLog)
    if tenant_id:
        stmt = stmt.where(AuditLog.tenant_id == tenant_id)
    stmt = stmt.order_by(AuditLog.created_at.desc()).limit(limit)
    result = await db.execute(stmt)
    logs = result.scalars().all()
    return [
        {
            "id": str(log.id),
            "tenant_id": str(log.tenant_id) if log.tenant_id else None,
            "user_id": str(log.user_id) if log.user_id else None,
            "action": log.action,
            "resource_type": log.resource_type,
            "resource_id": str(log.resource_id) if log.resource_id else None,
            "ip_address": log.ip_address,
            "timestamp": log.created_at.isoformat() if log.created_at else None,
        }
        for log in logs
    ]
