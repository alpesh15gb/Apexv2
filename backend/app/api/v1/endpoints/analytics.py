"""Customer Success & Analytics API endpoints for Super Admin."""

from datetime import datetime, timezone, date, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, and_, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser, require_permissions, require_permissions
from app.models.user import User
from app.models.tenant import Tenant
from app.models.employee import Employee
from app.models.subscription import TenantSubscription
from app.models.approval import LoginHistory

router = APIRouter(dependencies=[Depends(require_permissions("analytics.read"))])


@router.get("/customer-success")
async def customer_success_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Customer success dashboard overview."""
    today = date.today()

    active_tenants = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.subscription_status == "active")
    )).scalar() or 0

    trial_tenants = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.subscription_status == "trial")
    )).scalar() or 0

    expiring_soon = (await db.execute(
        select(func.count(TenantSubscription.id)).where(
            TenantSubscription.status == "active",
            TenantSubscription.end_date.isnot(None),
            TenantSubscription.end_date <= today + timedelta(days=7),
        )
    )).scalar() or 0

    churn_risk = (await db.execute(
        select(func.count(TenantSubscription.id)).where(
            TenantSubscription.status == "grace_period",
        )
    )).scalar() or 0

    total_employees = (await db.execute(
        select(func.count(Employee.id))
    )).scalar() or 0

    total_users = (await db.execute(
        select(func.count(User.id))
    )).scalar() or 0

    return {
        "active_customers": active_tenants,
        "trial_customers": trial_tenants,
        "expiring_soon": expiring_soon,
        "churn_risk": churn_risk,
        "total_employees": total_employees,
        "total_users": total_users,
    }


@router.get("/customer-success/tenants")
async def customer_tenants(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List tenants with customer success metrics."""
    stmt = select(Tenant)
    if status:
        stmt = stmt.where(Tenant.subscription_status == status)
    stmt = stmt.order_by(Tenant.created_at.desc())

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

        last_login = (await db.execute(
            select(func.max(User.last_login_at)).where(User.tenant_id == t.id)
        )).scalar()

        sub = (await db.execute(
            select(TenantSubscription).where(TenantSubscription.tenant_id == t.id)
            .order_by(TenantSubscription.created_at.desc()).limit(1)
        )).scalar_one_or_none()

        items.append({
            "id": str(t.id),
            "name": t.name,
            "slug": t.slug,
            "subscription_status": t.subscription_status,
            "employee_count": emp_count,
            "user_count": user_count,
            "last_login": last_login.isoformat() if last_login else None,
            "subscription_end": str(sub.end_date) if sub else None,
            "created_at": t.created_at.isoformat() if t.created_at else None,
        })

    return items


@router.get("/overview")
async def analytics_overview(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Platform-wide analytics."""
    today = date.today()
    thirty_days_ago = today - timedelta(days=30)

    total_tenants = (await db.execute(select(func.count(Tenant.id)))).scalar() or 0

    new_tenants_30d = (await db.execute(
        select(func.count(Tenant.id)).where(Tenant.created_at >= thirty_days_ago)
    )).scalar() or 0

    total_employees = (await db.execute(select(func.count(Employee.id)))).scalar() or 0

    new_employees_30d = (await db.execute(
        select(func.count(Employee.id)).where(Employee.created_at >= thirty_days_ago)
    )).scalar() or 0

    total_users = (await db.execute(select(func.count(User.id)))).scalar() or 0

    # Login activity
    logins_30d = (await db.execute(
        select(func.count(User.id)).where(User.last_login_at >= thirty_days_ago)
    )).scalar() or 0

    return {
        "tenants": {"total": total_tenants, "new_30d": new_tenants_30d},
        "employees": {"total": total_employees, "new_30d": new_employees_30d},
        "users": {"total": total_users, "active_30d": logins_30d},
    }


@router.get("/tenant/{tenant_id}")
async def tenant_analytics(
    tenant_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Analytics for a specific tenant."""
    from app.models.attendance import Attendance
    from app.models.leave import LeaveRequest
    from app.models.payroll import PaySlip

    today = date.today()
    thirty_days_ago = today - timedelta(days=30)

    try:
        tid = __import__('uuid').UUID(tenant_id)
    except ValueError:
        return {"error": "Invalid tenant ID"}

    employees = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tid)
    )).scalar() or 0

    active_employees = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tid, Employee.status == "active")
    )).scalar() or 0

    attendance_30d = (await db.execute(
        select(func.count(Attendance.id)).where(
            Attendance.tenant_id == tid,
            Attendance.date >= thirty_days_ago,
        )
    )).scalar() or 0

    leave_requests_30d = (await db.execute(
        select(func.count(LeaveRequest.id)).where(
            LeaveRequest.tenant_id == tid,
            LeaveRequest.created_at >= thirty_days_ago,
        )
    )).scalar() or 0

    payslips = (await db.execute(
        select(func.count(PaySlip.id)).where(PaySlip.tenant_id == tid)
    )).scalar() or 0

    return {
        "employees": {"total": employees, "active": active_employees},
        "attendance": {"records_30d": attendance_30d},
        "leaves": {"requests_30d": leave_requests_30d},
        "payroll": {"payslips": payslips},
    }
