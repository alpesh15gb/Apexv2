"""Dashboard service — all dashboard queries consolidated here."""

import uuid
from datetime import date, timedelta, datetime, timezone
from typing import List, Optional, Dict, Any

import structlog
from sqlalchemy import select, func, and_, case, extract
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.employee import Employee, Department
from app.models.device import Device
from app.models.attendance import Attendance
from app.models.visitor import VisitorPass
from app.models.leave import LeaveRequest
from app.models.audit_log import AuditLog
from app.models.essl_server import EsslServer
from app.models.essl_sync import EsslSyncHistory, SyncStatus

logger = structlog.get_logger(__name__)


class DashboardService:
    """Consolidates all dashboard queries into a single service."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_stats(self, tenant_id: uuid.UUID, target_date: Optional[date] = None) -> dict:
        """Get dashboard statistics for a tenant."""
        if target_date is None:
            latest = await self.db.execute(
                select(func.max(Attendance.date)).where(Attendance.tenant_id == tenant_id)
            )
            target_date = latest.scalar() or date.today()

        total_emp = (await self.db.execute(
            select(func.count(Employee.id)).where(
                Employee.tenant_id == tenant_id,
                Employee.status == "active",
            )
        )).scalar() or 0

        att_row = (await self.db.execute(
            select(
                func.count().filter(Attendance.status.in_(["present", "late", "early_out"])).label("present"),
                func.count().filter(Attendance.status == "absent").label("absent"),
                func.count().filter(Attendance.is_late == True).label("late"),
                func.count().filter(
                    Attendance.punch_in.isnot(None),
                    Attendance.punch_out.is_(None),
                ).label("missing_punches"),
            ).where(
                Attendance.tenant_id == tenant_id,
                Attendance.date == target_date,
            )
        )).one()
        present, absent, late, missing_punches = att_row

        device_row = (await self.db.execute(
            select(
                func.count().filter(Device.status == "online").label("online"),
                func.count().filter(Device.status == "offline").label("offline"),
            ).where(Device.tenant_id == tenant_id)
        )).one()
        online_devices, offline_devices = device_row

        visitors_inside = (await self.db.execute(
            select(func.count(VisitorPass.id)).where(
                VisitorPass.tenant_id == tenant_id,
                VisitorPass.status == "checked_in",
            )
        )).scalar() or 0

        pending_leaves = (await self.db.execute(
            select(func.count(LeaveRequest.id)).where(
                LeaveRequest.tenant_id == tenant_id,
                LeaveRequest.status == "pending",
            )
        )).scalar() or 0

        attendance_pct = (present / total_emp * 100) if total_emp > 0 else 0.0

        return {
            "employees_present": present,
            "employees_absent": absent,
            "late_today": late,
            "visitors_inside": visitors_inside,
            "online_devices": online_devices,
            "offline_devices": offline_devices,
            "total_employees": total_emp,
            "pending_leaves": pending_leaves,
            "attendance_percentage": round(attendance_pct, 1),
            "missing_punches": missing_punches,
        }

    async def get_attendance_heatmap(self, tenant_id: uuid.UUID, days: int = 30) -> List[dict]:
        """Get attendance heatmap data for the last N days."""
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        stmt = (
            select(
                Attendance.date,
                func.count().filter(Attendance.status.in_(["present", "late"])).label("present"),
                func.count().filter(Attendance.status == "absent").label("absent"),
                func.count().filter(Attendance.status == "half_day").label("half_day"),
                func.count().label("total"),
            )
            .where(
                Attendance.tenant_id == tenant_id,
                Attendance.date >= start_date,
                Attendance.date <= end_date,
            )
            .group_by(Attendance.date)
            .order_by(Attendance.date)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {
                "date": r[0].isoformat(),
                "present": r[1],
                "absent": r[2],
                "half_day": r[3],
                "total": r[4],
                "attendance_rate": round(r[1] / r[4] * 100, 1) if r[4] > 0 else 0,
            }
            for r in rows
        ]

    async def get_leave_calendar(self, tenant_id: uuid.UUID, year: int, month: int) -> List[dict]:
        """Get approved leaves for a month."""
        start_date = date(year, month, 1)
        if month == 12:
            end_date = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            end_date = date(year, month + 1, 1) - timedelta(days=1)

        stmt = (
            select(
                LeaveRequest.id,
                LeaveRequest.employee_id,
                LeaveRequest.start_date,
                LeaveRequest.end_date,
                LeaveRequest.status,
            )
            .where(
                LeaveRequest.tenant_id == tenant_id,
                LeaveRequest.status == "approved",
                LeaveRequest.start_date <= end_date,
                LeaveRequest.end_date >= start_date,
            )
            .order_by(LeaveRequest.start_date)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {
                "id": str(r.id),
                "employee_id": str(r.employee_id),
                "start_date": r.start_date.isoformat(),
                "end_date": r.end_date.isoformat(),
                "status": r.status,
            }
            for r in rows
        ]

    async def get_birthdays(self, tenant_id: uuid.UUID) -> List[dict]:
        """Get employees with birthdays this month."""
        today = date.today()
        stmt = (
            select(
                Employee.id,
                Employee.first_name,
                Employee.last_name,
                Employee.date_of_birth,
                Employee.department_id,
            )
            .where(
                Employee.tenant_id == tenant_id,
                Employee.status == "active",
                Employee.date_of_birth.isnot(None),
                extract("month", Employee.date_of_birth) == today.month,
            )
            .order_by(
                extract("day", Employee.date_of_birth)
            )
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {
                "id": str(r.id),
                "name": f"{r.first_name} {r.last_name}",
                "date_of_birth": r.date_of_birth.isoformat(),
                "department": r.department_id,
            }
            for r in rows
        ]

    async def get_work_anniversaries(self, tenant_id: uuid.UUID) -> List[dict]:
        """Get employees with work anniversaries this month."""
        today = date.today()
        stmt = (
            select(
                Employee.id,
                Employee.first_name,
                Employee.last_name,
                Employee.joining_date,
            )
            .where(
                Employee.tenant_id == tenant_id,
                Employee.status == "active",
                Employee.joining_date.isnot(None),
                extract("month", Employee.joining_date) == today.month,
            )
            .order_by(
                extract("day", Employee.joining_date)
            )
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {
                "id": str(r.id),
                "name": f"{r.first_name} {r.last_name}",
                "joining_date": r.joining_date.isoformat(),
                "years": today.year - r.joining_date.year,
            }
            for r in rows
        ]

    async def get_attendance_distribution(self, tenant_id: uuid.UUID, target_date: Optional[date] = None) -> dict:
        """Get attendance status distribution for a date."""
        if target_date is None:
            target_date = date.today()

        stmt = (
            select(
                Attendance.status,
                func.count().label("count"),
            )
            .where(
                Attendance.tenant_id == tenant_id,
                Attendance.date == target_date,
            )
            .group_by(Attendance.status)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return {r[0]: r[1] for r in rows}

    async def get_department_distribution(self, tenant_id: uuid.UUID) -> List[dict]:
        """Get employee count by department."""
        stmt = (
            select(
                Department.name,
                func.count(Employee.id).label("count"),
            )
            .join(Employee, Employee.department_id == Department.id)
            .where(
                Department.tenant_id == tenant_id,
                Employee.status == "active",
            )
            .group_by(Department.name)
            .order_by(func.count(Employee.id).desc())
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [{"department": r[0], "count": r[1]} for r in rows]

    async def get_monthly_trend(self, tenant_id: uuid.UUID, months: int = 6) -> List[dict]:
        """Get monthly attendance trend."""
        end_date = date.today()
        start_date = date(end_date.year, end_date.month, 1) - timedelta(days=months * 31)

        stmt = (
            select(
                func.date_trunc("month", Attendance.date).label("month"),
                func.count().filter(Attendance.status.in_(["present", "late"])).label("present"),
                func.count().filter(Attendance.status == "absent").label("absent"),
                func.count().label("total"),
            )
            .where(
                Attendance.tenant_id == tenant_id,
                Attendance.date >= start_date,
                Attendance.date <= end_date,
            )
            .group_by("month")
            .order_by("month")
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {
                "month": r[0].strftime("%Y-%m"),
                "present": r[1],
                "absent": r[2],
                "total": r[3],
                "attendance_rate": round(r[1] / r[3] * 100, 1) if r[3] > 0 else 0,
            }
            for r in rows
        ]

    async def get_sync_health(self, tenant_id: uuid.UUID) -> dict:
        """Get eSSL sync health status."""
        server_rows = (await self.db.execute(
            select(EsslServer.id, EsslServer.status).where(
                EsslServer.tenant_id == tenant_id,
                EsslServer.is_active == True,
            )
        )).all()

        total = len(server_rows)
        connected = sum(1 for s in server_rows if s.status == "connected")
        error = sum(1 for s in server_rows if s.status == "error")
        server_ids = [s.id for s in server_rows]

        recent_syncs = []
        if server_ids:
            recent_syncs = (await self.db.execute(
                select(
                    EsslSyncHistory.id,
                    EsslSyncHistory.essl_server_id,
                    EsslSyncHistory.sync_type,
                    EsslSyncHistory.status,
                    EsslSyncHistory.started_at,
                    EsslSyncHistory.records_fetched,
                )
                .where(
                    EsslSyncHistory.essl_server_id.in_(server_ids),
                    EsslSyncHistory.started_at >= datetime.now(timezone.utc) - timedelta(hours=24),
                )
                .order_by(EsslSyncHistory.started_at.desc())
                .limit(5)
            )).all()

        return {
            "total_servers": total,
            "connected": connected,
            "error": error,
            "recent_syncs": [
                {
                    "id": str(s.id),
                    "server_id": str(s.essl_server_id),
                    "sync_type": s.sync_type,
                    "status": s.status,
                    "started_at": s.started_at.isoformat() if s.started_at else None,
                    "records_fetched": s.records_fetched,
                }
                for s in recent_syncs
            ],
        }

    async def get_attendance_trend(
        self, tenant_id: uuid.UUID, days: int = 30
    ) -> List[dict]:
        """Get attendance trend data for the chart."""
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        stmt = (
            select(
                Attendance.date,
                func.count().filter(Attendance.status.in_(["present", "late"])).label("present"),
                func.count().filter(Attendance.status == "absent").label("absent"),
                func.count().filter(Attendance.is_late == True).label("late"),
                func.count().filter(Attendance.status == "half_day").label("half_day"),
            )
            .where(
                Attendance.tenant_id == tenant_id,
                Attendance.date >= start_date,
                Attendance.date <= end_date,
            )
            .group_by(Attendance.date)
            .order_by(Attendance.date)
        )
        result = await self.db.execute(stmt)
        rows = result.all()

        return [
            {"date": r[0], "present": r[1], "absent": r[2], "late": r[3], "half_day": r[4]}
            for r in rows
        ]

    async def get_recent_activity(
        self, tenant_id: uuid.UUID, limit: int = 20
    ) -> List[dict]:
        """Get recent audit log entries."""
        stmt = (
            select(AuditLog)
            .where(AuditLog.tenant_id == tenant_id)
            .order_by(AuditLog.created_at.desc())
            .limit(limit)
        )
        result = await self.db.execute(stmt)
        logs = result.scalars().all()

        return [
            {
                "id": str(log.id),
                "activity_type": log.action,
                "description": f"{log.action} {log.resource_type}"
                + (f" {log.resource_id}" if log.resource_id else ""),
                "timestamp": log.created_at.isoformat(),
            }
            for log in logs
        ]
