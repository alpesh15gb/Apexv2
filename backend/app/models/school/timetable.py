"""Timetable and Substitution models."""

from sqlalchemy import Column, String, Boolean, Integer, Time, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class PeriodDefinition(TenantModel):
    __tablename__ = "period_definitions"

    name = Column(String(50), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    period_type = Column(String(20), default="period")  # period/break/assembly/lunch
    sort_order = Column(Integer, default=0)


class TimetableEntry(TenantModel):
    __tablename__ = "timetable_entries"

    section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"))
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    room_id = Column(UUID(as_uuid=True), ForeignKey("rooms.id"))
    period_definition_id = Column(UUID(as_uuid=True), ForeignKey("period_definitions.id"), nullable=False)
    day_of_week = Column(Integer, nullable=False)  # 1=Monday, 7=Sunday
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    is_active = Column(Boolean, default=True)


class Substitution(TenantModel):
    __tablename__ = "substitutions"

    original_employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False, index=True)
    substitute_employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False, index=True)
    timetable_entry_id = Column(UUID(as_uuid=True), ForeignKey("timetable_entries.id"), nullable=False)
    date = Column(Date, nullable=False)
    reason = Column(String(255))
    status = Column(String(20), default="pending")  # pending/approved/rejected
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id"))
