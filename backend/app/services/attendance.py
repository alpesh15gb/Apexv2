import uuid
from datetime import datetime, date, time, timedelta, timezone
from zoneinfo import ZoneInfo
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.attendance import Attendance, PunchLog, AttendanceStatus, PunchType, PunchSource
from app.models.employee import Employee, EmployeeStatus
from app.models.shift import Shift, ShiftSchedule
from app.models.leave import LeaveRequest
from app.models.tenant import Tenant
from app.schemas.attendance import AttendanceSummary, DailyAttendanceSummary

class AttendanceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def process_punch_log(
        self,
        tenant_id: uuid.UUID,
        employee_id: uuid.UUID,
        device_id: Optional[uuid.UUID],
        punch_time: datetime,
        punch_type: str
    ) -> PunchLog:
        # Create the PunchLog record
        punch_log = PunchLog(
            tenant_id=tenant_id,
            employee_id=employee_id,
            device_id=device_id,
            punch_time=punch_time,
            punch_type=punch_type,
            source=PunchSource.BIOMETRIC.value,
            raw_data=f"Punch processed from device {device_id} at {punch_time}"
        )
        self.db.add(punch_log)
        await self.db.commit()
        await self.db.refresh(punch_log)

        # Trigger attendance calculation for that date
        await self.calculate_attendance(tenant_id, employee_id, punch_time.date())

        return punch_log

    async def calculate_attendance(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, attendance_date: date) -> Attendance:
        # 1. Fetch employee to ensure they exist
        emp_stmt = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        emp_res = await self.db.execute(emp_stmt)
        employee = emp_res.scalar_one_or_none()
        if not employee:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        # 2. Find shift schedule or default employee shift
        weekday = attendance_date.weekday()  # 0 = Monday, 6 = Sunday
        sched_stmt = select(ShiftSchedule).where(
            ShiftSchedule.employee_id == employee_id,
            ShiftSchedule.tenant_id == tenant_id,
            ShiftSchedule.effective_from <= attendance_date,
            (ShiftSchedule.effective_to == None) | (ShiftSchedule.effective_to >= attendance_date)
        ).where(
            (ShiftSchedule.day_of_week == None) | (ShiftSchedule.day_of_week == weekday)
        ).order_by(ShiftSchedule.day_of_week.desc(), ShiftSchedule.effective_from.desc())
        
        sched_res = await self.db.execute(sched_stmt)
        schedule = sched_res.scalar_one_or_none()

        shift = None
        if schedule:
            shift_stmt = select(Shift).where(Shift.id == schedule.shift_id, Shift.tenant_id == tenant_id)
            shift = (await self.db.execute(shift_stmt)).scalar_one_or_none()
        elif employee.shift_id:
            shift_stmt = select(Shift).where(Shift.id == employee.shift_id, Shift.tenant_id == tenant_id)
            shift = (await self.db.execute(shift_stmt)).scalar_one_or_none()

        # 3. Get all punches for the day
        # Resolve tenant timezone
        tenant_stmt = select(Tenant.timezone).where(Tenant.id == tenant_id)
        tenant_tz_res = await self.db.execute(tenant_stmt)
        tz_name = tenant_tz_res.scalar() or "Asia/Kolkata"
        local_tz = ZoneInfo(tz_name)

        # Setup day bounds in local timezone, then convert to UTC
        start_dt_local = datetime.combine(attendance_date, time.min).replace(tzinfo=local_tz)
        end_dt_local = datetime.combine(attendance_date, time.max).replace(tzinfo=local_tz)
        
        start_dt = start_dt_local.astimezone(timezone.utc)
        end_dt = end_dt_local.astimezone(timezone.utc)
        
        # If it's a night shift, extend end_dt to the next day's end to capture night shift out punches
        if shift and (shift.is_night_shift or shift.end_time < shift.start_time):
            end_dt_local_extended = datetime.combine(attendance_date + timedelta(days=1), shift.end_time).replace(tzinfo=local_tz) + timedelta(hours=4)
            end_dt = end_dt_local_extended.astimezone(timezone.utc)
        punch_stmt = select(PunchLog).where(
            PunchLog.employee_id == employee_id,
            PunchLog.tenant_id == tenant_id,
            PunchLog.punch_time >= start_dt,
            PunchLog.punch_time <= end_dt
        ).order_by(PunchLog.punch_time.asc())
        
        punches_res = await self.db.execute(punch_stmt)
        punches = list(punches_res.scalars().all())

        # 4. Check if attendance record exists
        att_stmt = select(Attendance).where(
            Attendance.employee_id == employee_id,
            Attendance.tenant_id == tenant_id,
            Attendance.date == attendance_date
        )
        att_res = await self.db.execute(att_stmt)
        attendance = att_res.scalar_one_or_none()

        if not attendance:
            attendance = Attendance(
                tenant_id=tenant_id,
                employee_id=employee_id,
                date=attendance_date
            )
            self.db.add(attendance)

        # 5. Populate attendance based on punches
        if not punches:
            # Check if they are on leave
            leave_stmt = select(LeaveRequest).where(
                LeaveRequest.employee_id == employee_id,
                LeaveRequest.tenant_id == tenant_id,
                LeaveRequest.status == "approved",
                LeaveRequest.start_date <= attendance_date,
                LeaveRequest.end_date >= attendance_date
            )
            leave_res = await self.db.execute(leave_stmt)
            leave_req = leave_res.scalar_one_or_none()

            if leave_req:
                attendance.status = AttendanceStatus.ABSENT.value  # or on leave, but status has ABSENT / HOLIDAY / WEEK_OFF
                attendance.remarks = f"On Leave (Request: {leave_req.id})"
            else:
                # If weekend and no punches, check if it's week off
                if weekday in [5, 6] and not shift:  # Sat, Sun default week off
                    attendance.status = AttendanceStatus.WEEK_OFF.value
                else:
                    attendance.status = AttendanceStatus.ABSENT.value
            
            attendance.punch_in = None
            attendance.punch_out = None
            attendance.total_hours = 0.0
            attendance.overtime_hours = 0.0
            attendance.is_late = False
            attendance.late_minutes = 0
            attendance.is_early_out = False
            attendance.early_out_minutes = 0
            if shift:
                attendance.shift_id = shift.id
        else:
            punch_in_time = punches[0].punch_time
            punch_out_time = punches[-1].punch_time if len(punches) > 1 else None

            attendance.punch_in = punch_in_time
            attendance.punch_out = punch_out_time

            if punch_out_time:
                attendance.total_hours = (punch_out_time - punch_in_time).total_seconds() / 3600.0
            else:
                attendance.total_hours = 0.0
                attendance.status = AttendanceStatus.HALF_DAY.value
                attendance.remarks = "Single punch recorded"

            attendance.overtime_hours = 0.0
            attendance.is_late = False
            attendance.late_minutes = 0
            attendance.is_early_out = False
            attendance.early_out_minutes = 0

            if shift:
                attendance.shift_id = shift.id
                
                # Align shift times to punch date in local timezone, then convert to UTC
                shift_start_local = datetime.combine(attendance_date, shift.start_time).replace(tzinfo=local_tz)
                if shift.is_night_shift or shift.end_time < shift.start_time:
                    shift_end_local = datetime.combine(attendance_date + timedelta(days=1), shift.end_time).replace(tzinfo=local_tz)
                else:
                    shift_end_local = datetime.combine(attendance_date, shift.end_time).replace(tzinfo=local_tz)
                
                shift_start = shift_start_local.astimezone(timezone.utc)
                shift_end = shift_end_local.astimezone(timezone.utc)

                # Late check
                if punch_in_time > shift_start:
                    late_diff = (punch_in_time - shift_start).total_seconds() / 60.0
                    if late_diff > shift.grace_period_minutes:
                        attendance.is_late = True
                        attendance.late_minutes = int(late_diff)

                # Early check (only if punch_out exists)
                if punch_out_time and punch_out_time < shift_end:
                    early_diff = (shift_end - punch_out_time).total_seconds() / 60.0
                    # Check if there is early out rule or check
                    attendance.is_early_out = True
                    attendance.early_out_minutes = int(early_diff)

                # OT check
                if punch_out_time and punch_out_time > shift_end:
                    ot_diff = (punch_out_time - shift_end).total_seconds() / 60.0
                    if ot_diff > shift.overtime_threshold_minutes:
                        attendance.overtime_hours = ot_diff / 60.0

                # Status assignment
                if attendance.total_hours > 0.0:
                    if attendance.is_late:
                        attendance.status = AttendanceStatus.LATE.value
                    elif attendance.is_early_out:
                        attendance.status = AttendanceStatus.EARLY_OUT.value
                    else:
                        attendance.status = AttendanceStatus.PRESENT.value
            else:
                if attendance.total_hours > 0.0:
                    attendance.status = AttendanceStatus.PRESENT.value

        await self.db.commit()
        await self.db.refresh(attendance)
        return attendance

    async def calculate_daily_attendance(self, tenant_id: uuid.UUID, attendance_date: date) -> List[Attendance]:
        stmt = select(Employee.id).where(Employee.tenant_id == tenant_id, Employee.status == EmployeeStatus.ACTIVE.value)
        res = await self.db.execute(stmt)
        employee_ids = res.scalars().all()

        attendances = []
        for emp_id in employee_ids:
            try:
                att = await self.calculate_attendance(tenant_id, emp_id, attendance_date)
                attendances.append(att)
            except Exception:
                # Log or handle exceptions for individual employees to avoid crashing the whole daily run
                continue
        return attendances

    async def get_attendance(
        self,
        tenant_id: uuid.UUID,
        employee_id: Optional[uuid.UUID] = None,
        department_id: Optional[uuid.UUID] = None,
        branch_id: Optional[uuid.UUID] = None,
        status_val: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Attendance], int]:
        count_stmt = select(func.count(Attendance.id)).join(Employee, Attendance.employee_id == Employee.id).where(Attendance.tenant_id == tenant_id)
        stmt = select(Attendance).join(Employee, Attendance.employee_id == Employee.id).where(Attendance.tenant_id == tenant_id).options(
            selectinload(Attendance.employee),
            selectinload(Attendance.shift)
        )

        if employee_id:
            count_stmt = count_stmt.where(Attendance.employee_id == employee_id)
            stmt = stmt.where(Attendance.employee_id == employee_id)
        if department_id:
            count_stmt = count_stmt.where(Employee.department_id == department_id)
            stmt = stmt.where(Employee.department_id == department_id)
        if branch_id:
            count_stmt = count_stmt.where(Employee.branch_id == branch_id)
            stmt = stmt.where(Employee.branch_id == branch_id)
        if status_val:
            count_stmt = count_stmt.where(Attendance.status == status_val)
            stmt = stmt.where(Attendance.status == status_val)
        if from_date:
            count_stmt = count_stmt.where(Attendance.date >= from_date)
            stmt = stmt.where(Attendance.date >= from_date)
        if to_date:
            count_stmt = count_stmt.where(Attendance.date <= to_date)
            stmt = stmt.where(Attendance.date <= to_date)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        records = list(res.scalars().all())
        return records, total

    async def get_employee_attendance_summary(
        self,
        tenant_id: uuid.UUID,
        employee_id: uuid.UUID,
        from_date: date,
        to_date: date
    ) -> AttendanceSummary:
        # verify employee
        emp_stmt = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        emp_result = await self.db.execute(emp_stmt)
        employee = emp_result.scalar_one_or_none()
        if not employee:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        stmt = select(Attendance).where(
            Attendance.employee_id == employee_id,
            Attendance.tenant_id == tenant_id,
            Attendance.date >= from_date,
            Attendance.date <= to_date
        )
        res = await self.db.execute(stmt)
        records = res.scalars().all()

        total_days = len(records)
        present_days = sum(1 for r in records if r.status in [AttendanceStatus.PRESENT.value, AttendanceStatus.LATE.value, AttendanceStatus.EARLY_OUT.value])
        absent_days = sum(1 for r in records if r.status == AttendanceStatus.ABSENT.value)
        late_days = sum(1 for r in records if r.is_late)
        early_out_days = sum(1 for r in records if r.is_early_out)
        half_days = sum(1 for r in records if r.status == AttendanceStatus.HALF_DAY.value)
        total_hours = sum(r.total_hours or 0.0 for r in records)
        total_overtime_hours = sum(r.overtime_hours or 0.0 for r in records)

        return AttendanceSummary(
            employee_id=employee_id,
            employee_name=f"{employee.first_name} {employee.last_name}",
            employee_code=employee.employee_code,
            total_days=total_days,
            present=present_days,
            absent=absent_days,
            late=late_days,
            early_out=early_out_days,
            half_day=half_days,
            total_hours=total_hours,
            total_overtime_hours=total_overtime_hours
        )

    async def get_daily_summary(self, tenant_id: uuid.UUID, summary_date: date) -> DailyAttendanceSummary:
        # Total employees
        emp_stmt = select(func.count(Employee.id)).where(Employee.tenant_id == tenant_id, Employee.status == EmployeeStatus.ACTIVE.value)
        total_employees = (await self.db.execute(emp_stmt)).scalar() or 0

        # Attendance counts
        att_stmt = select(Attendance.status, func.count(Attendance.id)).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date == summary_date
        ).group_by(Attendance.status)
        res = await self.db.execute(att_stmt)
        att_counts = dict(res.all())

        present = att_counts.get(AttendanceStatus.PRESENT.value, 0) + \
                  att_counts.get(AttendanceStatus.LATE.value, 0) + \
                  att_counts.get(AttendanceStatus.EARLY_OUT.value, 0)
        absent = att_counts.get(AttendanceStatus.ABSENT.value, 0)
        half_day = att_counts.get(AttendanceStatus.HALF_DAY.value, 0)

        # Count late
        late_stmt = select(func.count(Attendance.id)).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date == summary_date,
            Attendance.is_late == True
        )
        late = (await self.db.execute(late_stmt)).scalar() or 0

        # Count on leave
        leave_stmt = select(func.count(LeaveRequest.id)).where(
            LeaveRequest.tenant_id == tenant_id,
            LeaveRequest.status == "approved",
            LeaveRequest.start_date <= summary_date,
            LeaveRequest.end_date >= summary_date
        )
        on_leave = (await self.db.execute(leave_stmt)).scalar() or 0

        return DailyAttendanceSummary(
            date=summary_date,
            total_employees=total_employees,
            present=present,
            absent=absent,
            half_day=half_day,
            late=late,
            on_leave=on_leave
        )

    async def manual_mark_attendance(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Attendance:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        employee_id = data.get("employee_id")
        attendance_date = data.get("date")

        if not employee_id or not attendance_date:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="employee_id and date are required")

        # Parse date if passed as string
        if isinstance(attendance_date, str):
            attendance_date = datetime.strptime(attendance_date, "%Y-%m-%d").date()

        # Validate employee exists
        emp_stmt = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        if not (await self.db.execute(emp_stmt)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        # Check if exists
        stmt = select(Attendance).where(
            Attendance.employee_id == employee_id,
            Attendance.tenant_id == tenant_id,
            Attendance.date == attendance_date
        )
        res = await self.db.execute(stmt)
        attendance = res.scalar_one_or_none()

        if not attendance:
            attendance = Attendance(
                tenant_id=tenant_id,
                employee_id=employee_id,
                date=attendance_date
            )
            self.db.add(attendance)

        # Update manual fields
        attendance.is_manual = True
        for field, val in data.items():
            if hasattr(attendance, field):
                # parse datetimes if passed as strings
                if field in ["punch_in", "punch_out"] and isinstance(val, str):
                    val = datetime.fromisoformat(val.replace("Z", "+00:00"))
                setattr(attendance, field, val)

        # Recalculate duration
        if attendance.punch_in and attendance.punch_out:
            attendance.total_hours = (attendance.punch_out - attendance.punch_in).total_seconds() / 3600.0
        else:
            attendance.total_hours = 0.0

        await self.db.commit()
        await self.db.refresh(attendance)
        return attendance

    async def approve_attendance(self, attendance_id: uuid.UUID, tenant_id: uuid.UUID, approved_by: uuid.UUID) -> Attendance:
        stmt = select(Attendance).where(Attendance.id == attendance_id, Attendance.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        attendance = res.scalar_one_or_none()
        if not attendance:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attendance record not found")

        attendance.approved_by = approved_by
        await self.db.commit()
        await self.db.refresh(attendance)
        return attendance

    async def list_punch_logs(
        self,
        tenant_id: uuid.UUID,
        page: int = 1,
        page_size: int = 20,
        employee_id: Optional[uuid.UUID] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
    ) -> Tuple[List[PunchLog], int]:
        """List punch logs with pagination and filters."""
        stmt = select(PunchLog).where(PunchLog.tenant_id == tenant_id)
        count_stmt = select(func.count(PunchLog.id)).where(PunchLog.tenant_id == tenant_id)

        if employee_id:
            stmt = stmt.where(PunchLog.employee_id == employee_id)
            count_stmt = count_stmt.where(PunchLog.employee_id == employee_id)
        # Resolve tenant timezone
        tenant_stmt = select(Tenant.timezone).where(Tenant.id == tenant_id)
        tenant_tz_res = await self.db.execute(tenant_stmt)
        tz_name = tenant_tz_res.scalar() or "Asia/Kolkata"
        local_tz = ZoneInfo(tz_name)

        if from_date:
            from_dt = datetime.combine(from_date, datetime.min.time()).replace(tzinfo=local_tz).astimezone(timezone.utc)
            stmt = stmt.where(PunchLog.punch_time >= from_dt)
            count_stmt = count_stmt.where(PunchLog.punch_time >= from_dt)
        if to_date:
            to_dt = datetime.combine(to_date, datetime.max.time()).replace(tzinfo=local_tz).astimezone(timezone.utc)
            stmt = stmt.where(PunchLog.punch_time <= to_dt)
            count_stmt = count_stmt.where(PunchLog.punch_time <= to_dt)

        total = (await self.db.execute(count_stmt)).scalar() or 0
        offset = (page - 1) * page_size
        result = await self.db.execute(stmt.order_by(PunchLog.punch_time.desc()).offset(offset).limit(page_size))
        items = list(result.scalars().all())

        return items, total
