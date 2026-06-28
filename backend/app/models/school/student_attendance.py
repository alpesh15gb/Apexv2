"""Student attendance models."""

from sqlalchemy import Column, String, Date, Time, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class StudentAttendance(TenantModel):
    __tablename__ = "student_attendance"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False)
    status = Column(String(20), nullable=False)  # present/absent/late/half-day/excused
    check_in_time = Column(Time)
    check_out_time = Column(Time)
    remarks = Column(String(255))
    marked_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    attendance_type = Column(String(20), default="daily")  # daily/period/bus
    period_definition_id = Column(UUID(as_uuid=True), ForeignKey("period_definitions.id"))
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)


class StudentAttendanceSummary(TenantModel):
    __tablename__ = "student_attendance_summary"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    month = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    total_days = Column(Integer, default=0)
    present_days = Column(Integer, default=0)
    absent_days = Column(Integer, default=0)
    late_days = Column(Integer, default=0)
    half_days = Column(Integer, default=0)
    excused_days = Column(Integer, default=0)
