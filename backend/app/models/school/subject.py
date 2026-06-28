"""Subject, Grade Subject, and Teacher Allocation models."""

from sqlalchemy import Column, String, Boolean, Integer, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class Subject(TenantModel):
    __tablename__ = "subjects"

    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=False)
    subject_type = Column(String(30), default="core")  # core/elective/practical/language/extracurricular
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id"))
    credits = Column(Numeric(4, 1), default=0)
    max_marks = Column(Integer, default=100)
    pass_marks = Column(Integer, default=33)
    has_practical = Column(Boolean, default=False)
    practical_max_marks = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)


class GradeSubject(TenantModel):
    __tablename__ = "grade_subjects"

    grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    is_compulsory = Column(Boolean, default=True)
    sort_order = Column(Integer, default=0)


class TeacherAllocation(TenantModel):
    __tablename__ = "teacher_allocations"

    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id", ondelete="CASCADE"), nullable=False, index=True)
    section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id", ondelete="CASCADE"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    periods_per_week = Column(Integer, default=0)
