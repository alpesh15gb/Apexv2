"""Duplicate Detection Service — identifies cross-server punch duplicates."""

import uuid
from datetime import datetime, date, timedelta, timezone
from zoneinfo import ZoneInfo
from typing import Dict, List, Optional, Tuple
from app.models.tenant import Tenant

import structlog
from sqlalchemy import select, func, and_, or_, String
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.attendance import AttendanceRawLog

logger = structlog.get_logger(__name__)


class DuplicateDetector:
    """Identifies and handles cross-server punch duplicates.
    
    When multiple eSSL servers report the same punch event, this service
    determines if they are true duplicates or legitimate separate events.
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def find_cross_server_duplicates(
        self,
        tenant_id: uuid.UUID,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> List[Dict]:
        """Find punches that appear on multiple servers for the same employee at the same time.
        
        Returns list of duplicate groups:
        [
            {
                "employee_code": "1001",
                "punch_time": "2024-01-15T09:00:00Z",
                "punch_type": "in",
                "count": 2,
                "raw_log_ids": ["uuid1", "uuid2"],
                "server_ids": ["server1", "server2"],
                "device_serials": ["DEV001", "DEV002"],
            }
        ]
        """
        # Resolve tenant timezone
        tenant_stmt = select(Tenant.timezone).where(Tenant.id == tenant_id)
        tenant_tz_res = await self.db.execute(tenant_stmt)
        tz_name = tenant_tz_res.scalar() or "Asia/Kolkata"
        local_tz = ZoneInfo(tz_name)

        if from_date is None:
            from_date = datetime.now(local_tz).date() - timedelta(days=30)
        if to_date is None:
            to_date = datetime.now(local_tz).date()

        from_dt = datetime.combine(from_date, datetime.min.time()).replace(tzinfo=local_tz).astimezone(timezone.utc)
        to_dt = datetime.combine(to_date, datetime.max.time()).replace(tzinfo=local_tz).astimezone(timezone.utc)

        stmt = (
            select(
                AttendanceRawLog.employee_code,
                AttendanceRawLog.punch_time,
                AttendanceRawLog.punch_type,
                func.count(AttendanceRawLog.id).label("count"),
                func.array_agg(AttendanceRawLog.id).label("raw_log_ids"),
                func.array_agg(AttendanceRawLog.essl_server_id).label("server_ids"),
                func.array_agg(AttendanceRawLog.device_serial).label("device_serials"),
            )
            .where(
                AttendanceRawLog.tenant_id == tenant_id,
                AttendanceRawLog.punch_time >= from_dt,
                AttendanceRawLog.punch_time <= to_dt,
            )
            .group_by(
                AttendanceRawLog.employee_code,
                AttendanceRawLog.punch_time,
                AttendanceRawLog.punch_type,
            )
            .having(func.count(AttendanceRawLog.id) > 1)
        )

        result = await self.db.execute(stmt)
        duplicates = []

        for row in result.all():
            # Check if they're from different servers
            server_ids = [str(sid) for sid in row.server_ids if sid is not None]
            unique_servers = set(server_ids)

            if len(unique_servers) > 1:
                duplicates.append({
                    "employee_code": row.employee_code,
                    "punch_time": row.punch_time.isoformat(),
                    "punch_type": row.punch_type,
                    "count": row.count,
                    "raw_log_ids": [str(rid) for rid in row.raw_log_ids],
                    "server_ids": server_ids,
                    "device_serials": [str(ds) for ds in row.device_serials if ds is not None],
                })

        return duplicates

    async def resolve_duplicates(
        self,
        tenant_id: uuid.UUID,
        strategy: str = "keep_first",
    ) -> Dict:
        """Resolve cross-server duplicates.
        
        Strategies:
        - keep_first: Keep the first punch, mark others as processed with note
        - keep_all: Keep all (let attendance processor handle merging)
        - mark_review: Mark all for manual review
        
        Returns: {resolved: int, strategy: str}
        """
        duplicates = await self.find_cross_server_duplicates(tenant_id)
        resolved = 0

        for dup in duplicates:
            if strategy == "keep_first":
                # Keep the first raw_log, mark others as processed
                raw_log_ids = dup["raw_log_ids"]
                if len(raw_log_ids) > 1:
                    for rid in raw_log_ids[1:]:
                        stmt = select(AttendanceRawLog).where(AttendanceRawLog.id == uuid.UUID(rid))
                        result = await self.db.execute(stmt)
                        log = result.scalar_one_or_none()
                        if log:
                            log.processed = True
                            log.processed_at = datetime.now(timezone.utc)
                            log.processing_error = f"Duplicate of {raw_log_ids[0]} from different server"
                            resolved += 1

            elif strategy == "mark_review":
                # Mark all for review
                for rid in dup["raw_log_ids"]:
                    stmt = select(AttendanceRawLog).where(AttendanceRawLog.id == uuid.UUID(rid))
                    result = await self.db.execute(stmt)
                    log = result.scalar_one_or_none()
                    if log:
                        log.processing_error = f"Cross-server duplicate - needs review"
                        resolved += 1

        await self.db.commit()

        return {
            "resolved": resolved,
            "strategy": strategy,
            "total_duplicates_found": len(duplicates),
        }

    async def get_duplicate_stats(self, tenant_id: uuid.UUID) -> Dict:
        """Get duplicate statistics for a tenant."""
        # Count total raw logs
        total_stmt = select(func.count(AttendanceRawLog.id)).where(
            AttendanceRawLog.tenant_id == tenant_id
        )
        total = (await self.db.execute(total_stmt)).scalar() or 0

        # Count unique punches (by employee_code + punch_time + punch_type)
        unique_stmt = (
            select(func.count(func.distinct(
                func.concat(
                    AttendanceRawLog.employee_code,
                    AttendanceRawLog.punch_time.cast(String),
                    AttendanceRawLog.punch_type,
                )
            )))
            .where(AttendanceRawLog.tenant_id == tenant_id)
        )
        unique = (await self.db.execute(unique_stmt)).scalar() or 0

        # Count cross-server duplicates
        duplicates = await self.find_cross_server_duplicates(tenant_id)

        return {
            "total_raw_logs": total,
            "unique_punches": unique,
            "potential_duplicates": total - unique,
            "cross_server_duplicates": len(duplicates),
        }
