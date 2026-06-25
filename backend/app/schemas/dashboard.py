"""Dashboard schemas."""

from datetime import date
from typing import Optional, List
from pydantic import BaseModel


class DashboardStats(BaseModel):
    employees_present: int = 0
    employees_absent: int = 0
    late_today: int = 0
    visitors_inside: int = 0
    online_devices: int = 0
    offline_devices: int = 0
    total_employees: int = 0
    pending_leaves: int = 0
    attendance_percentage: float = 0.0
    missing_punches: int = 0


class AttendanceTrend(BaseModel):
    date: date
    present: int = 0
    absent: int = 0
    late: int = 0
    half_day: int = 0


class RecentActivity(BaseModel):
    id: str
    activity_type: str
    description: str
    timestamp: str
    user_name: Optional[str] = None


class AttendanceHeatmapItem(BaseModel):
    date: str
    present: int = 0
    absent: int = 0
    half_day: int = 0
    total: int = 0
    attendance_rate: float = 0.0


class LeaveCalendarItem(BaseModel):
    id: str
    employee_id: str
    start_date: str
    end_date: str
    status: str


class BirthdayItem(BaseModel):
    id: str
    name: str
    date_of_birth: str
    department: Optional[str] = None


class AnniversaryItem(BaseModel):
    id: str
    name: str
    joining_date: str
    years: int = 0


class AttendanceDistribution(BaseModel):
    present: int = 0
    absent: int = 0
    late: int = 0
    half_day: int = 0
    on_leave: int = 0


class DepartmentDistribution(BaseModel):
    department: str
    count: int


class MonthlyTrend(BaseModel):
    month: str
    present: int = 0
    absent: int = 0
    total: int = 0
    attendance_rate: float = 0.0


class SyncHealthStatus(BaseModel):
    total_servers: int = 0
    connected: int = 0
    error: int = 0
    recent_syncs: List[dict] = []
