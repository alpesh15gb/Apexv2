"""System Health & Monitoring API endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import select, func, text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions, require_permissions
from app.models.user import User
from app.models.tenant import Tenant
from app.models.employee import Employee
from app.models.attendance import Attendance
from app.models.leave import LeaveRequest
from app.models.notification import Notification

router = APIRouter(dependencies=[Depends(require_permissions("system.read"))])


@router.get("/health")
async def system_health(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """System health check with key metrics."""
    try:
        await db.execute(text("SELECT 1"))
        db_healthy = True
    except Exception:
        db_healthy = False

    return {
        "status": "healthy" if db_healthy else "degraded",
        "database": "connected" if db_healthy else "disconnected",
        "timestamp": __import__('datetime').datetime.now(__import__('datetime').timezone.utc).isoformat(),
    }


@router.get("/metrics")
async def system_metrics(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """System metrics for monitoring."""
    tid = current_user.tenant_id

    total_employees = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tid)
    )).scalar() or 0

    active_employees = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tid, Employee.status == "active")
    )).scalar() or 0

    today_attendance = (await db.execute(
        select(func.count(Attendance.id)).where(
            Attendance.tenant_id == tid,
            Attendance.date == __import__('datetime').date.today(),
        )
    )).scalar() or 0

    pending_leaves = (await db.execute(
        select(func.count(LeaveRequest.id)).where(
            LeaveRequest.tenant_id == tid,
            LeaveRequest.status == "pending",
        )
    )).scalar() or 0

    unread_notifications = (await db.execute(
        select(func.count(Notification.id)).where(
            Notification.tenant_id == tid,
            Notification.user_id == current_user.id,
            Notification.status != "read",
        )
    )).scalar() or 0

    return {
        "employees": {"total": total_employees, "active": active_employees},
        "attendance": {"today": today_attendance},
        "leaves": {"pending": pending_leaves},
        "notifications": {"unread": unread_notifications},
    }


@router.get("/tenant-usage")
async def tenant_usage(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Current tenant resource usage."""
    tid = current_user.tenant_id

    employees = (await db.execute(
        select(func.count(Employee.id)).where(Employee.tenant_id == tid)
    )).scalar() or 0

    users = (await db.execute(
        select(func.count(User.id)).where(User.tenant_id == tid)
    )).scalar() or 0

    return {
        "employees": employees,
        "users": users,
    }
