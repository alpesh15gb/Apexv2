"""Dashboard API endpoints with real-time stats."""

from datetime import date
from typing import List

from fastapi import APIRouter, Depends, Query

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.schemas.dashboard import (
    DashboardStats, AttendanceTrend, RecentActivity,
    AttendanceHeatmapItem, LeaveCalendarItem, BirthdayItem,
    AnniversaryItem, DepartmentDistribution, MonthlyTrend,
    SyncHealthStatus,
)
from app.services.dashboard import DashboardService

router = APIRouter(dependencies=[Depends(require_permissions("dashboard.read"))])


@router.get("/stats", response_model=DashboardStats)
async def dashboard_stats(
    date: date = Query(default=None),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    data = await service.get_stats(current_user.tenant_id, date)
    return DashboardStats(**data)


@router.get("/attendance-heatmap", response_model=List[AttendanceHeatmapItem])
async def attendance_heatmap(
    days: int = Query(30, ge=7, le=90),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_attendance_heatmap(current_user.tenant_id, days)
    return [AttendanceHeatmapItem(**r) for r in rows]


@router.get("/leave-calendar", response_model=List[LeaveCalendarItem])
async def leave_calendar(
    year: int = Query(default=None),
    month: int = Query(default=None),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if year is None:
        year = date.today().year
    if month is None:
        month = date.today().month
    service = DashboardService(db)
    rows = await service.get_leave_calendar(current_user.tenant_id, year, month)
    return [LeaveCalendarItem(**r) for r in rows]


@router.get("/birthdays", response_model=List[BirthdayItem])
async def birthdays(
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_birthdays(current_user.tenant_id)
    return [BirthdayItem(**r) for r in rows]


@router.get("/anniversaries", response_model=List[AnniversaryItem])
async def work_anniversaries(
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_work_anniversaries(current_user.tenant_id)
    return [AnniversaryItem(**r) for r in rows]


@router.get("/department-distribution", response_model=List[DepartmentDistribution])
async def department_distribution(
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_department_distribution(current_user.tenant_id)
    return [DepartmentDistribution(**r) for r in rows]


@router.get("/monthly-trend", response_model=List[MonthlyTrend])
async def monthly_trend(
    months: int = Query(6, ge=1, le=12),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_monthly_trend(current_user.tenant_id, months)
    return [MonthlyTrend(**r) for r in rows]


@router.get("/sync-health", response_model=SyncHealthStatus)
async def sync_health(
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    data = await service.get_sync_health(current_user.tenant_id)
    return SyncHealthStatus(**data)


@router.get("/attendance-chart", response_model=List[AttendanceTrend])
async def attendance_chart(
    days: int = Query(30, ge=7, le=90),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    rows = await service.get_attendance_trend(current_user.tenant_id, days)
    return [AttendanceTrend(**r) for r in rows]


@router.get("/recent-activity", response_model=List[RecentActivity])
async def recent_activity(
    limit: int = Query(20, ge=1, le=50),
    db=Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DashboardService(db)
    items = await service.get_recent_activity(current_user.tenant_id, limit)
    return [RecentActivity(**a) for a in items]
