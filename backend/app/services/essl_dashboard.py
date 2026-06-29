"""eSSL Dashboard Service — consolidates all eSSL dashboard queries."""

import uuid
from datetime import datetime, date, timezone, timedelta, time
from zoneinfo import ZoneInfo
from typing import List, Dict, Any, Optional

import structlog
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.essl_server import EsslServer
from app.models.essl_sync import EsslSyncHistory, EsslSyncError, SyncStatus
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.essl_cursor import EsslSyncCursor
from app.models.attendance import AttendanceRawLog
from app.services.duplicate_detector import DuplicateDetector

logger = structlog.get_logger(__name__)


class EsslDashboardService:
    """Consolidates all eSSL dashboard queries."""

    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_sync_dashboard(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        """Get comprehensive eSSL sync status for the dashboard."""
        servers_stmt = select(EsslServer).where(
            EsslServer.tenant_id == tenant_id,
            EsslServer.is_active == True,
        )
        servers_result = await self.db.execute(servers_stmt)
        servers = list(servers_result.scalars().all())

        dashboard = []
        for server in servers:
            try:
                server_tz = ZoneInfo(server.timezone or "Asia/Kolkata")
            except Exception:
                server_tz = ZoneInfo("Asia/Kolkata")
            local_now = datetime.now(timezone.utc).astimezone(server_tz)
            today_start_local = datetime.combine(local_now.date(), time.min).replace(tzinfo=server_tz)
            today_start = today_start_local.astimezone(timezone.utc)
            # Get cursors
            cursor_stmt = select(EsslSyncCursor).where(
                EsslSyncCursor.essl_server_id == server.id
            )
            cursor_result = await self.db.execute(cursor_stmt)
            cursors = {c.cursor_type: c for c in cursor_result.scalars().all()}

            # Count devices and employees
            dev_count = (await self.db.execute(
                select(func.count(EsslDeviceMapping.id)).where(
                    EsslDeviceMapping.essl_server_id == server.id
                )
            )).scalar() or 0

            emp_count = (await self.db.execute(
                select(func.count(EsslEmployeeMapping.id)).where(
                    EsslEmployeeMapping.essl_server_id == server.id
                )
            )).scalar() or 0

            # Pending raw logs
            pending = (await self.db.execute(
                select(func.count(AttendanceRawLog.id)).where(
                    AttendanceRawLog.essl_server_id == server.id,
                    AttendanceRawLog.processed == False,
                )
            )).scalar() or 0

            # Recent errors
            recent_errors = (await self.db.execute(
                select(func.count(EsslSyncError.id)).where(
                    EsslSyncError.tenant_id == tenant_id
                )
            )).scalar() or 0

            # Current running sync
            running_sync_stmt = select(EsslSyncHistory).where(
                EsslSyncHistory.essl_server_id == server.id,
                EsslSyncHistory.status == SyncStatus.RUNNING,
            ).order_by(EsslSyncHistory.started_at.desc()).limit(1)
            running_sync = (await self.db.execute(running_sync_stmt)).scalar_one_or_none()

            current_sync_state = None
            current_progress = 0
            if running_sync:
                if running_sync.is_paused:
                    current_sync_state = "paused"
                elif running_sync.is_cancelled:
                    current_sync_state = "cancelled"
                else:
                    current_sync_state = "running"
                current_progress = running_sync.progress_percent

            # Last sync duration
            last_completed_stmt = select(EsslSyncHistory).where(
                EsslSyncHistory.essl_server_id == server.id,
                EsslSyncHistory.status.in_([SyncStatus.COMPLETED, SyncStatus.PARTIAL]),
            ).order_by(EsslSyncHistory.completed_at.desc()).limit(1)
            last_completed = (await self.db.execute(last_completed_stmt)).scalar_one_or_none()
            last_duration = last_completed.duration_seconds if last_completed else None

            # Records downloaded today
            today_records = (await self.db.execute(
                select(func.count(AttendanceRawLog.id)).where(
                    AttendanceRawLog.essl_server_id == server.id,
                    AttendanceRawLog.created_at >= today_start,
                )
            )).scalar() or 0

            # Duplicate stats
            dup_detector = DuplicateDetector(self.db)
            dup_stats = await dup_detector.get_duplicate_stats(tenant_id)

            # Failed sync attempts
            failed_count = (await self.db.execute(
                select(func.count(EsslSyncHistory.id)).where(
                    EsslSyncHistory.essl_server_id == server.id,
                    EsslSyncHistory.status == SyncStatus.FAILED,
                )
            )).scalar() or 0

            # Next scheduled sync
            next_sync = None
            if server.auto_sync_enabled and last_completed and last_completed.completed_at:
                next_sync = last_completed.completed_at + timedelta(
                    minutes=server.attendance_sync_interval_minutes
                )

            # Cursor position
            cursor_pos = (
                cursors.get("attendance").last_punch_time
                if cursors.get("attendance")
                else None
            )

            # Recovery status
            recovery_status = "ok"
            if server.status == "error":
                recovery_status = "offline"
            elif pending > 1000:
                recovery_status = "backlog"

            dashboard.append({
                "server_id": server.id,
                "server_name": server.name,
                "connection_status": server.status,
                "last_connected_at": server.last_connected_at,
                "last_attendance_sync": cursors.get("attendance").last_punch_time if cursors.get("attendance") else None,
                "last_employee_sync": cursors.get("employees").last_employee_sync if cursors.get("employees") else None,
                "last_device_sync": cursors.get("devices").last_device_sync if cursors.get("devices") else None,
                "total_devices": dev_count,
                "total_employees_synced": emp_count,
                "pending_raw_logs": pending,
                "recent_errors": recent_errors,
                "current_sync_state": current_sync_state,
                "current_progress_percent": current_progress,
                "last_sync_duration_seconds": last_duration,
                "records_downloaded_today": today_records,
                "duplicate_punches_detected": dup_stats.get("cross_server_duplicates", 0),
                "duplicate_punches_resolved": 0,
                "failed_sync_attempts": failed_count,
                "consecutive_failures": getattr(server, "consecutive_failures", 0),
                "next_scheduled_sync": next_sync,
                "current_cursor_position": cursor_pos,
                "recovery_status": recovery_status,
                "soap_response_time_ms": None,
            })

        return dashboard

    async def get_enterprise_dashboard(
        self, tenant_id: uuid.UUID, throughput_days: int = 7
    ) -> Dict[str, Any]:
        """Enterprise sync dashboard with health scores, throughput, and alerts."""
        servers_stmt = select(EsslServer).where(
            EsslServer.tenant_id == tenant_id,
            EsslServer.is_active == True,
        )
        servers_result = await self.db.execute(servers_stmt)
        servers = list(servers_result.scalars().all())

        now = datetime.now(timezone.utc)
        week_ago = now - timedelta(days=throughput_days)

        server_health_list = []
        total_pending = 0
        total_syncs_today = 0
        total_errors_today = 0
        processing_lags = []

        for server in servers:
            try:
                server_tz = ZoneInfo(server.timezone or "Asia/Kolkata")
            except Exception:
                server_tz = ZoneInfo("Asia/Kolkata")
            local_now = now.astimezone(server_tz)
            today_start_local = datetime.combine(local_now.date(), time.min).replace(tzinfo=server_tz)
            today_start = today_start_local.astimezone(timezone.utc)
            alerts = []
            score = 100

            # Connection status scoring
            if server.status == "error":
                score -= 40
                alerts.append("Connection error")
            elif server.status == "testing":
                score -= 10

            # Get cursor
            cursor_stmt = select(EsslSyncCursor).where(
                EsslSyncCursor.essl_server_id == server.id,
                EsslSyncCursor.cursor_type == "attendance",
            )
            cursor = (await self.db.execute(cursor_stmt)).scalar_one_or_none()
            cursor_freshness = None
            if cursor and cursor.last_punch_time:
                last_punch = cursor.last_punch_time.replace(tzinfo=timezone.utc) if cursor.last_punch_time.tzinfo is None else cursor.last_punch_time.astimezone(timezone.utc)
                cursor_freshness = (now - last_punch).total_seconds() / 60
                if cursor_freshness > 60:
                    score -= 15
                    alerts.append(f"Cursor stale ({cursor_freshness:.0f}min)")
                elif cursor_freshness > 30:
                    score -= 5

            # Pending raw logs
            pending = (await self.db.execute(
                select(func.count(AttendanceRawLog.id)).where(
                    AttendanceRawLog.essl_server_id == server.id,
                    AttendanceRawLog.processed == False,
                )
            )).scalar() or 0
            total_pending += pending

            if pending > 5000:
                score -= 25
                alerts.append(f"Large backlog ({pending} logs)")
            elif pending > 1000:
                score -= 10
                alerts.append(f"Backlog ({pending} logs)")

            # Processing lag
            latest_raw_stmt = select(func.max(AttendanceRawLog.punch_time)).where(
                AttendanceRawLog.essl_server_id == server.id,
            )
            latest_raw = (await self.db.execute(latest_raw_stmt)).scalar()
            processing_lag = None
            if latest_raw:
                latest_processed_stmt = select(func.max(AttendanceRawLog.punch_time)).where(
                    AttendanceRawLog.essl_server_id == server.id,
                    AttendanceRawLog.processed == True,
                )
                latest_processed = (await self.db.execute(latest_processed_stmt)).scalar()
                if latest_processed and latest_raw:
                    lag_seconds = (latest_raw - latest_processed).total_seconds()
                    processing_lag = lag_seconds / 60
                    if processing_lag > 60:
                        score -= 15
                        alerts.append(f"Processing lag ({processing_lag:.0f}min)")
                    elif processing_lag > 15:
                        score -= 5
                    processing_lags.append(processing_lag)

            # Error rate
            recent_syncs_stmt = select(EsslSyncHistory).where(
                EsslSyncHistory.essl_server_id == server.id,
                EsslSyncHistory.started_at >= week_ago,
            )
            recent_syncs = list((await self.db.execute(recent_syncs_stmt)).scalars().all())
            total_records = sum(s.records_fetched for s in recent_syncs)
            total_errors = sum(s.records_failed for s in recent_syncs)
            error_rate = (total_errors / total_records * 100) if total_records > 0 else 0.0

            if error_rate > 10:
                score -= 20
                alerts.append(f"High error rate ({error_rate:.1f}%)")
            elif error_rate > 2:
                score -= 5

            # Throughput
            total_duration = sum(s.duration_seconds or 0 for s in recent_syncs)
            throughput = (total_records / (total_duration / 3600)) if total_duration > 0 else 0.0

            # Consecutive failures
            consecutive = getattr(server, "consecutive_failures", 0)
            if consecutive > 3:
                score -= 20
                alerts.append(f"{consecutive} consecutive failures")
            elif consecutive > 0:
                score -= 5 * consecutive

            # Last sync age
            last_sync_age = None
            if recent_syncs:
                last_completed = max(
                    (s.completed_at for s in recent_syncs if s.completed_at),
                    default=None,
                )
                if last_completed:
                    last_comp_dt = last_completed.replace(tzinfo=timezone.utc) if last_completed.tzinfo is None else last_completed.astimezone(timezone.utc)
                    last_sync_age = (now - last_comp_dt).total_seconds() / 60
                    if last_sync_age > 30:
                        score -= 10
                        alerts.append(f"Last sync {last_sync_age:.0f}min ago")

            # Count syncs and errors today
            today_syncs = [s for s in recent_syncs if s.started_at >= today_start]
            total_syncs_today += len(today_syncs)
            total_errors_today += sum(1 for s in today_syncs if s.status == SyncStatus.FAILED)

            score = max(0, min(100, score))

            server_health_list.append({
                "server_id": server.id,
                "server_name": server.name,
                "health_score": score,
                "connection_status": server.status,
                "last_sync_age_minutes": last_sync_age,
                "processing_lag_minutes": processing_lag,
                "raw_log_backlog": pending,
                "error_rate": error_rate,
                "throughput_per_hour": throughput,
                "consecutive_failures": consecutive,
                "cursor_freshness_minutes": cursor_freshness,
                "alerts": alerts,
            })

        # Throughput trend
        server_ids = [s.id for s in servers]
        throughput_stmt = (
            select(
                func.date_trunc("day", EsslSyncHistory.started_at).label("day"),
                func.sum(EsslSyncHistory.records_fetched).label("records"),
                func.sum(EsslSyncHistory.records_failed).label("errors"),
                func.sum(EsslSyncHistory.duration_seconds).label("duration"),
            )
            .where(
                EsslSyncHistory.started_at >= week_ago,
                EsslSyncHistory.essl_server_id.in_(server_ids) if server_ids else False,
            )
            .group_by("day")
            .order_by("day")
        )
        throughput_rows = (await self.db.execute(throughput_stmt)).all()
        throughput_trend = [
            {
                "timestamp": r[0],
                "records_synced": r[1] or 0,
                "errors": r[2] or 0,
                "duration_seconds": r[3],
            }
            for r in throughput_rows
        ]

        # Aggregate scores
        healthy = sum(1 for s in server_health_list if s["health_score"] >= 80)
        degraded = sum(1 for s in server_health_list if 50 <= s["health_score"] < 80)
        down = sum(1 for s in server_health_list if s["health_score"] < 50)
        overall = (
            sum(s["health_score"] for s in server_health_list) // len(server_health_list)
            if server_health_list
            else 100
        )
        avg_lag = sum(processing_lags) / len(processing_lags) if processing_lags else None

        return {
            "overall_health_score": overall,
            "total_servers": len(servers),
            "healthy_servers": healthy,
            "degraded_servers": degraded,
            "down_servers": down,
            "total_pending_raw_logs": total_pending,
            "total_syncs_today": total_syncs_today,
            "total_errors_today": total_errors_today,
            "avg_processing_lag_minutes": avg_lag,
            "servers": server_health_list,
            "throughput_trend": throughput_trend,
        }
