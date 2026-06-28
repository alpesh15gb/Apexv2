"""Lesson planning model."""

from sqlalchemy import Column, String, Boolean, Integer, Date, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class LessonPlan(TenantModel):
    __tablename__ = "lesson_plans"

    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False, index=True)
    section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    unit_number = Column(Integer)
    lesson_number = Column(Integer)
    planned_date = Column(Date)
    actual_date = Column(Date)
    duration_periods = Column(Integer, default=1)
    learning_objectives = Column(Text)
    teaching_methods = Column(Text)
    resources = Column(Text)
    homework = Column(Text)
    status = Column(String(20), default="planned")  # planned/in_progress/completed/cancelled
    completion_percentage = Column(Integer, default=0)
    remarks = Column(Text)
