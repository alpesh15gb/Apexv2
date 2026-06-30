"""Attendance Processor — converts raw eSSL punch logs into daily attendance records.

Pipeline: attendance_raw_logs → AttendanceProcessor → attendances table
NEVER reads from eSSL directly. Only processes local raw_logs.
"""

import uuid
from datetime import datetime, date, time, timezone, timedelta
from zoneinfo import ZoneInfo
from typing import Dict, List, Optional, Tuple
from app.models.tenant import Tenant

import structlog
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.attendance import Attendance, AttendanceRawLog, AttendanceStatus, PunchLog, PunchSource
from app.models.employee import Employee, EmployeeStatus
from app.models.shift import Shift, ShiftSchedule

logger = structlog.get_logger(__name__)


class AttendanceProcessor:
    """Processes raw attendance logs into daily attendance records.

    Pipeline: attendance_raw_logs → AttendanceProcessor → attendances table
    NEVER reads from eSSL directly. Only processes local raw_logs.
    """

    def __init__(self, db: AsyncSession):
        self.db = db

    async def process_raw_logs(self, tenant_id: uuid.UUID, target_date: Optional[date] = None) -> Dict:
        """Process all unprocessed raw logs.
        1. Query attendance_raw_logs WHERE processed=False
        2. Resolve employee_id from mappings if not already resolved
        3. Group punches by employee
        4. For each employee: calculate attendance using shift rules
        5. Upsert into attendances table
        6. Return summary
        """
        if target_date is None:
            target_date = date.today()

        # Get unprocessed raw logs
        raw_stmt = (
            select(AttendanceRawLog)
            .where(
                AttendanceRawLog.tenant_id == tenant_id,
                AttendanceRawLog.processed == False,
            )
            .order_by(AttendanceRawLog.employee_code, AttendanceRawLog.punch_time)
        )
        raw_result = await self.db.execute(raw_stmt)
        raw_logs = list(raw_result.scalars().all())

        return await self._process_logs(tenant_id, raw_logs)

    async def reprocess(
        self,
        tenant_id: uuid.UUID,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        employee_id: Optional[uuid.UUID] = None,
        department_id: Optional[uuid.UUID] = None,
    ) -> Dict:
        """Reprocess attendance by resetting raw logs and re-running calculation.

        Resets processed=False for matching raw logs, then runs the processor.
        Supports filtering by date range, employee, or department.
        """
        # Resolve tenant timezone to compute local day boundaries in UTC
        tenant_stmt = select(Tenant.timezone).where(Tenant.id == tenant_id)
        tenant_tz_res = await self.db.execute(tenant_stmt)
        tz_name = tenant_tz_res.scalar() or "Asia/Kolkata"
        local_tz = ZoneInfo(tz_name)

        if from_date:
            start_local = datetime.combine(from_date, datetime.min.time()).replace(tzinfo=local_tz)
            conditions.append(AttendanceRawLog.punch_time >= start_local.astimezone(timezone.utc))
        if to_date:
            end_local = datetime.combine(to_date, datetime.max.time()).replace(tzinfo=local_tz)
            conditions.append(AttendanceRawLog.punch_time <= end_local.astimezone(timezone.utc))
        employee_ids = None
        if employee_id:
            employee_ids = [employee_id]
        elif department_id:
            emp_stmt = select(Employee.id).where(
                Employee.tenant_id == tenant_id,
                Employee.department_id == department_id,
            )
            emp_result = await self.db.execute(emp_stmt)
            employee_ids = [row[0] for row in emp_result.all()]
            if not employee_ids:
                return {"processed": 0, "created": 0, "updated": 0, "errors": 0, "reset": 0}

        if employee_ids:
            conditions.append(AttendanceRawLog.employee_id.in_(employee_ids))

        # Reset matching raw logs to unprocessed
        reset_stmt = (
            select(AttendanceRawLog)
            .where(and_(*conditions))
            .order_by(AttendanceRawLog.employee_code, AttendanceRawLog.punch_time)
        )
        reset_result = await self.db.execute(reset_stmt)
        raw_logs = list(reset_result.scalars().all())

        reset_count = 0
        for log in raw_logs:
            if log.processed:
                log.processed = False
                log.processed_at = None
                log.processing_error = None
                reset_count += 1

        await self.db.flush()

        # Also delete existing attendance records for the date range + employees
        # so reprocessing creates clean records, preserving manual overrides & approved entries
        delete_conditions = [
            Attendance.tenant_id == tenant_id,
            Attendance.is_manual == False,
            Attendance.approved_by == None
        ]
        if from_date:
            delete_conditions.append(Attendance.date >= from_date)
        if to_date:
            delete_conditions.append(Attendance.date <= to_date)
        if employee_ids:
            delete_conditions.append(Attendance.employee_id.in_(employee_ids))
        from sqlalchemy import delete as sql_delete
        del_stmt = sql_delete(Attendance).where(and_(*delete_conditions))
        await self.db.execute(del_stmt)

        # Delete corresponding PunchLog records for the date range + employees where source = "biometric"
        delete_punch_conditions = [
            PunchLog.tenant_id == tenant_id,
            PunchLog.source == PunchSource.BIOMETRIC.value
        ]
        if from_date:
            start_local = datetime.combine(from_date, datetime.min.time()).replace(tzinfo=local_tz)
            delete_punch_conditions.append(PunchLog.punch_time >= start_local.astimezone(timezone.utc))
        if to_date:
            end_local = datetime.combine(to_date, datetime.max.time()).replace(tzinfo=local_tz)
            delete_punch_conditions.append(PunchLog.punch_time <= end_local.astimezone(timezone.utc))
        if employee_ids:
            delete_punch_conditions.append(PunchLog.employee_id.in_(employee_ids))
        
        del_punch_stmt = sql_delete(PunchLog).where(and_(*delete_punch_conditions))
        await self.db.execute(del_punch_stmt)
        await self.db.flush()

        # Now process the reset logs
        result = await self._process_logs(tenant_id, raw_logs)
        result["reset"] = reset_count

        # Backfill missing attendance records for the date range to prevent gaps (absent, holidays, week off)
        if from_date and to_date:
            from app.services.attendance import AttendanceService
            att_service = AttendanceService(self.db)
            
            # Get active employees
            emp_stmt = select(Employee).where(
                Employee.tenant_id == tenant_id,
                Employee.status == EmployeeStatus.ACTIVE.value
            )
            if employee_ids:
                emp_stmt = emp_stmt.where(Employee.id.in_(employee_ids))
            emp_res = await self.db.execute(emp_stmt)
            active_employees = list(emp_res.scalars().all())
            
            from datetime import timedelta
            current_date = from_date
            while current_date <= to_date:
                for emp in active_employees:
                    # Check if attendance record exists
                    exists_stmt = select(Attendance).where(
                        Attendance.employee_id == emp.id,
                        Attendance.tenant_id == tenant_id,
                        Attendance.date == current_date
                    )
                    exists_res = await self.db.execute(exists_stmt)
                    if not exists_res.scalar_one_or_none():
                        await att_service.calculate_attendance(tenant_id, emp.id, current_date)
                current_date += timedelta(days=1)
            
            await self.db.commit()

    async def _process_logs(self, tenant_id: uuid.UUID, raw_logs: List[AttendanceRawLog]) -> Dict:
        """Core processing logic shared by process_raw_logs and reprocess."""
        if not raw_logs:
            return {"processed": 0, "created": 0, "updated": 0, "errors": 0}

        # Resolve tenant timezone
        tenant_stmt = select(Tenant.timezone).where(Tenant.id == tenant_id)
        tenant_tz_res = await self.db.execute(tenant_stmt)
        tz_name = tenant_tz_res.scalar() or "Asia/Kolkata"

        # Group by employee
        employee_punches: Dict[str, List[AttendanceRawLog]] = {}
        for log in raw_logs:
            emp_id = str(log.employee_id) if log.employee_id else log.employee_code
            if emp_id not in employee_punches:
                employee_punches[emp_id] = []
            employee_punches[emp_id].append(log)

        created = 0
        updated = 0
        errors = 0

        for emp_key, punches in employee_punches.items():
            try:
                # Get the employee
                if punches[0].employee_id:
                    emp_stmt = select(Employee).where(Employee.id == punches[0].employee_id)
                else:
                    emp_stmt = select(Employee).where(
                        Employee.tenant_id == tenant_id,
                        Employee.employee_code == punches[0].employee_code,
                    )

                emp_result = await self.db.execute(emp_stmt)
                employee = emp_result.scalar_one_or_none()

                if not employee:
                    logger.warning("attendance_employee_not_found", employee_code=punches[0].employee_code, employee_id=str(punches[0].employee_id) if punches[0].employee_id else None, tenant_id=str(tenant_id))
                    for p in punches:
                        p.processed = False
                        p.processing_error = "Employee mapping missing"
                    errors += 1
                    continue

                # Process each date in the punches (convert UTC to tenant local date)
                local_tz = ZoneInfo(tz_name)
                dates = set()
                for p in punches:
                    if p.punch_time:
                        dates.add(p.punch_time.astimezone(local_tz).date())

                for punch_date in dates:
                    day_punches = [p for p in punches if p.punch_time and p.punch_time.astimezone(local_tz).date() == punch_date]
                    day_punches.sort(key=lambda p: p.punch_time)

                    result = await self._calculate_and_upsert(
                        tenant_id, employee, punch_date, day_punches, tz_name
                    )
                    if result == "created":
                        created += 1
                    elif result == "updated":
                        updated += 1
                    elif result == "skipped_manual_override":
                        pass
                    else:
                        errors += 1

                    # Sync biometric punches to PunchLog table so list_punch_logs and calculate_daily_attendance work
                    for dp in day_punches:
                        # Check if a PunchLog with same employee, time, and type exists
                        exists_stmt = select(PunchLog).where(
                            PunchLog.employee_id == employee.id,
                            PunchLog.punch_time == dp.punch_time,
                            PunchLog.punch_type == (dp.punch_type or "in")
                        )
                        exists_res = await self.db.execute(exists_stmt)
                        if not exists_res.scalar_one_or_none():
                            punch_log = PunchLog(
                                tenant_id=tenant_id,
                                employee_id=employee.id,
                                device_id=dp.device_id,
                                punch_time=dp.punch_time,
                                punch_type=dp.punch_type or "in",
                                source=PunchSource.BIOMETRIC.value,
                                raw_data=str(dp.raw_data) if dp.raw_data else f"Biometric punch from raw log {dp.id}"
                            )
                            self.db.add(punch_log)
                    # Mark raw logs as processed
                    for p in day_punches:
                        p.processed = True
                        p.processed_at = datetime.now(timezone.utc)

            except Exception as e:
                logger.error("attendance_processing_error", employee=emp_key, error=str(e))
                for p in punches:
                    p.processed = True
                    p.processing_error = str(e)
                errors += 1

        await self.db.commit()

        return {
            "processed": len(raw_logs),
            "created": created,
            "updated": updated,
            "errors": errors,
        }

    async def _calculate_and_upsert(
        self,
        tenant_id: uuid.UUID,
        employee: Employee,
        punch_date: date,
        day_punches: List[AttendanceRawLog],
        tz_name: str,
    ) -> str:
        """Calculate attendance for one employee on one date and upsert."""
        if not day_punches:
            return "error"

        # Deduplicate punches with same timestamp (within 5 seconds)
        unique_punches = []
        for p in day_punches:
            if not p.punch_time:
                continue
            is_dup = False
            for u in unique_punches:
                if abs((p.punch_time - u.punch_time).total_seconds()) < 5:
                    is_dup = True
                    break
            if not is_dup:
                unique_punches.append(p)
        
        if not unique_punches:
            return "error"

        # Sort by time
        unique_punches.sort(key=lambda p: p.punch_time)
        
        punch_in = unique_punches[0].punch_time
        punch_out = unique_punches[-1].punch_time if len(unique_punches) > 1 else None

        # If punch_in == punch_out (same timestamp for first and last), set punch_out to None
        if punch_out and punch_in == punch_out:
            punch_out = None

        # Find shift
        shift = await self._find_shift(tenant_id, employee, punch_date)

        total_hours = None
        overtime_hours = 0.0
        is_late = False
        late_minutes = 0
        is_early_out = False
        early_out_minutes = 0
        status = AttendanceStatus.ABSENT.value

        if punch_in and punch_out:
            total_seconds = (punch_out - punch_in).total_seconds()
            total_hours = total_seconds / 3600.0

            if shift:
                # Calculate lateness
                is_late, late_minutes = self._calculate_lateness(punch_in, shift, tz_name)
                # Calculate early out
                is_early_out, early_out_minutes = self._calculate_early_out(punch_out, shift, tz_name)
                # Calculate overtime
                overtime_hours = self._calculate_overtime(punch_in, punch_out, shift, tz_name)

            # Determine status
            if total_hours >= 8:
                status = AttendanceStatus.LATE.value if is_late else AttendanceStatus.PRESENT.value
            elif total_hours >= 4:
                status = AttendanceStatus.HALF_DAY.value
            else:
                status = AttendanceStatus.ABSENT.value
        elif punch_in:
            status = AttendanceStatus.HALF_DAY.value
            total_hours = 0.0

        # Upsert attendance
        existing_stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.employee_id == employee.id,
            Attendance.date == punch_date,
        )
        existing_result = await self.db.execute(existing_stmt)
        attendance = existing_result.scalar_one_or_none()

        if attendance:
            # Preserve manual overrides and approved records
            if attendance.is_manual or attendance.approved_by is not None:
                return "skipped_manual_override"
            
            attendance.punch_in = punch_in
            attendance.punch_out = punch_out
            attendance.total_hours = total_hours
            attendance.overtime_hours = overtime_hours
            attendance.status = status
            attendance.is_late = is_late
            attendance.late_minutes = late_minutes
            attendance.is_early_out = is_early_out
            attendance.early_out_minutes = early_out_minutes
            attendance.shift_id = shift.id if shift else None
            return "updated"
        else:
            attendance = Attendance(
                tenant_id=tenant_id,
                employee_id=employee.id,
                date=punch_date,
                punch_in=punch_in,
                punch_out=punch_out,
                total_hours=total_hours,
                overtime_hours=overtime_hours,
                status=status,
                is_late=is_late,
                late_minutes=late_minutes,
                is_early_out=is_early_out,
                early_out_minutes=early_out_minutes,
                shift_id=shift.id if shift else None,
                is_manual=False,
            )
            self.db.add(attendance)
            return "created"

    async def _find_shift(self, tenant_id: uuid.UUID, employee: Employee, punch_date: date) -> Optional[Shift]:
        """Find the shift for an employee on a given date."""
        weekday = punch_date.weekday()

        # Check shift schedule first
        sched_stmt = select(ShiftSchedule).where(
            ShiftSchedule.employee_id == employee.id,
            ShiftSchedule.tenant_id == tenant_id,
            ShiftSchedule.effective_from <= punch_date,
            (ShiftSchedule.effective_to == None) | (ShiftSchedule.effective_to >= punch_date),
        ).where(
            (ShiftSchedule.day_of_week == None) | (ShiftSchedule.day_of_week == weekday)
        ).order_by(ShiftSchedule.day_of_week.desc(), ShiftSchedule.effective_from.desc())

        sched_result = await self.db.execute(sched_stmt)
        schedule = sched_result.scalar_one_or_none()

        if schedule:
            shift_stmt = select(Shift).where(Shift.id == schedule.shift_id, Shift.tenant_id == tenant_id)
            shift_result = await self.db.execute(shift_stmt)
            return shift_result.scalar_one_or_none()

        # Fall back to employee's default shift
        if employee.shift_id:
            shift_stmt = select(Shift).where(Shift.id == employee.shift_id, Shift.tenant_id == tenant_id)
            shift_result = await self.db.execute(shift_stmt)
            return shift_result.scalar_one_or_none()

        return None

    @staticmethod
    def _calculate_lateness(punch_in: datetime, shift: Shift, tz_name: str) -> Tuple[bool, int]:
        """Calculate if punch_in is late relative to shift start."""
        if not shift.start_time:
            return False, 0

        local_tz = ZoneInfo(tz_name)
        punch_in_local = punch_in.astimezone(local_tz)
        shift_start_local = datetime.combine(punch_in_local.date(), shift.start_time).replace(tzinfo=local_tz)
        shift_start = shift_start_local.astimezone(timezone.utc)

        grace = shift.grace_period_minutes or 0
        threshold = shift_start + timedelta(minutes=grace)

        if punch_in > threshold:
            late = (punch_in - shift_start).total_seconds() / 60
            return True, int(late)
        return False, 0

    @staticmethod
    def _calculate_early_out(punch_out: datetime, shift: Shift, tz_name: str) -> Tuple[bool, int]:
        """Calculate if punch_out is early relative to shift end."""
        if not shift.end_time:
            return False, 0

        local_tz = ZoneInfo(tz_name)
        punch_out_local = punch_out.astimezone(local_tz)
        shift_end_local = datetime.combine(punch_out_local.date(), shift.end_time).replace(tzinfo=local_tz)
        shift_end = shift_end_local.astimezone(timezone.utc)

        early_rule = shift.early_rule_minutes or 0
        threshold = shift_end - timedelta(minutes=early_rule)

        if punch_out < threshold:
            early = (shift_end - punch_out).total_seconds() / 60
            return True, int(early)
        return False, 0

    @staticmethod
    def _calculate_overtime(punch_in: datetime, punch_out: datetime, shift: Shift, tz_name: str) -> float:
        """Calculate overtime hours beyond shift duration."""
        if not shift.start_time or not shift.end_time:
            return 0.0

        local_tz = ZoneInfo(tz_name)
        punch_in_local = punch_in.astimezone(local_tz)
        punch_out_local = punch_out.astimezone(local_tz)

        shift_start_local = datetime.combine(punch_in_local.date(), shift.start_time).replace(tzinfo=local_tz)
        shift_end_local = datetime.combine(punch_out_local.date(), shift.end_time).replace(tzinfo=local_tz)

        if shift_end_local <= shift_start_local:
            shift_end_local += timedelta(days=1)

        shift_start = shift_start_local.astimezone(timezone.utc)
        shift_end = shift_end_local.astimezone(timezone.utc)

        shift_duration = (shift_end - shift_start).total_seconds() / 3600.0
        actual_hours = (punch_out - punch_in).total_seconds() / 3600.0

        overtime_threshold = (shift.overtime_threshold_minutes or 0) / 60.0
        overtime = actual_hours - shift_duration

        if overtime > overtime_threshold:
            return overtime
        return 0.0
