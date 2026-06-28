"""School dashboard and reports endpoints."""

import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.school_dashboard_service import SchoolDashboardService

router = APIRouter(dependencies=[Depends(require_feature("student_management")), Depends(require_permissions("student.read"))])


@router.get("/stats")
async def school_dashboard_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = SchoolDashboardService(db)
    return await svc.get_stats(tenant_id=current_user.tenant_id)


@router.get("/attendance-overview")
async def attendance_overview(
    days: int = Query(7, ge=1, le=30),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = SchoolDashboardService(db)
    return await svc.attendance_overview(tenant_id=current_user.tenant_id, days=days)
