"""Homework and Assignment models."""

from sqlalchemy import Column, String, Boolean, Date, Text, Numeric, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class Homework(TenantModel):
    __tablename__ = "homework"

    section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    due_date = Column(Date, nullable=False)
    attachment_urls = Column(JSONB, default=[])
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    is_active = Column(Boolean, default=True)


class HomeworkSubmission(TenantModel):
    __tablename__ = "homework_submissions"

    homework_id = Column(UUID(as_uuid=True), ForeignKey("homework.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    submitted_at = Column(DateTime(timezone=True))
    attachment_urls = Column(JSONB, default=[])
    remarks = Column(Text)
    marks = Column(Numeric(5, 2))
    grade = Column(String(10))
    status = Column(String(20), default="pending")  # pending/submitted/reviewed/late
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    reviewed_at = Column(DateTime(timezone=True))


class Assignment(TenantModel):
    __tablename__ = "assignments"

    section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"), nullable=False)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    assignment_type = Column(String(30), default="online")  # online/offline/project
    max_marks = Column(Numeric(5, 2))
    rubric = Column(JSONB)
    due_date = Column(Date, nullable=False)
    attachment_urls = Column(JSONB, default=[])
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    is_active = Column(Boolean, default=True)


class AssignmentSubmission(TenantModel):
    __tablename__ = "assignment_submissions"

    assignment_id = Column(UUID(as_uuid=True), ForeignKey("assignments.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    submitted_at = Column(DateTime(timezone=True))
    attachment_urls = Column(JSONB, default=[])
    marks = Column(Numeric(5, 2))
    grade = Column(String(10))
    feedback = Column(Text)
    status = Column(String(20), default="pending")
    evaluated_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    evaluated_at = Column(DateTime(timezone=True))
