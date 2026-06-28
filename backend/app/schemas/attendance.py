"""Attendance schemas."""

import uuid
from datetime import date, datetime, time
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class AttendanceBase(BaseModel):
    employee_id: uuid.UUID
    date: date
    punch_in: Optional[datetime] = None
    punch_out: Optional[datetime] = None
    total_hours: Optional[float] = None
    overtime_hours: Optional[float] = None
    status: str = "present"
    is_late: bool = False
    late_minutes: int = 0
    is_early_out: bool = False
    early_out_minutes: int = 0
    shift_id: Optional[uuid.UUID] = None
    remarks: Optional[str] = None


class AttendanceCreate(AttendanceBase):
    is_manual: bool = False


class AttendanceUpdate(BaseModel):
    punch_in: Optional[datetime] = None
    punch_out: Optional[datetime] = None
    status: Optional[str] = None
    remarks: Optional[str] = None
    is_manual: bool = True


class AttendanceResponse(AttendanceBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    is_manual: bool
    approved_by: Optional[uuid.UUID] = None
    created_at: datetime
    updated_at: datetime
    employee_name: Optional[str] = None
    employee_code: Optional[str] = None


class AttendanceFilter(BaseModel):
    employee_id: Optional[uuid.UUID] = None
    department_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    status: Optional[str] = None
    from_date: Optional[date] = None
    to_date: Optional[date] = None
    is_late: Optional[bool] = None


class PunchLogCreate(BaseModel):
    employee_id: uuid.UUID
    device_id: Optional[uuid.UUID] = None
    punch_time: datetime
    punch_type: str = "in"
    source: str = "biometric"


class PunchLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    device_id: Optional[uuid.UUID] = None
    punch_time: datetime
    punch_type: str
    source: str
    created_at: datetime


class AttendanceSummary(BaseModel):
    employee_id: uuid.UUID
    employee_name: str
    employee_code: str
    total_days: int = 0
    present: int = 0
    absent: int = 0
    half_day: int = 0
    late: int = 0
    early_out: int = 0
    holiday: int = 0
    week_off: int = 0
    total_hours: float = 0.0
    total_overtime_hours: float = 0.0


class DailyAttendanceSummary(BaseModel):
    date: date
    total_employees: int = 0
    present: int = 0
    absent: int = 0
    half_day: int = 0
    late: int = 0
    on_leave: int = 0
