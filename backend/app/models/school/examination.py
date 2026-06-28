"""Examination, Marks, and Grading models."""

from sqlalchemy import Column, String, Boolean, Integer, Date, Time, Numeric, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class ExamType(TenantModel):
    __tablename__ = "exam_types"

    name = Column(String(100), nullable=False)
    code = Column(String(30), nullable=False)
    weightage = Column(Numeric(5, 2), default=0)
    exam_category = Column(String(30), default="internal")  # internal/external/practical/unit/final
    is_active = Column(Boolean, default=True)


class Exam(TenantModel):
    __tablename__ = "exams"

    exam_type_id = Column(UUID(as_uuid=True), ForeignKey("exam_types.id"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    academic_term_id = Column(UUID(as_uuid=True), ForeignKey("academic_terms.id"))
    name = Column(String(255), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    status = Column(String(20), default="draft")  # draft/scheduled/ongoing/completed/results_published


class ExamSchedule(TenantModel):
    __tablename__ = "exam_schedules"

    exam_id = Column(UUID(as_uuid=True), ForeignKey("exams.id", ondelete="CASCADE"), nullable=False, index=True)
    subject_id = Column(UUID(as_uuid=True), ForeignKey("subjects.id"), nullable=False, index=True)
    grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id"), nullable=False, index=True)
    exam_date = Column(Date, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    max_marks = Column(Integer, default=100)
    pass_marks = Column(Integer, default=33)
    room_ids = Column(JSONB, default=[])
    invigilator_ids = Column(JSONB, default=[])


class ExamMark(TenantModel):
    __tablename__ = "exam_marks"

    exam_schedule_id = Column(UUID(as_uuid=True), ForeignKey("exam_schedules.id", ondelete="CASCADE"), nullable=False, index=True)
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    marks_obtained = Column(Numeric(6, 2))
    practical_marks = Column(Numeric(6, 2))
    grade = Column(String(10))
    is_absent = Column(Boolean, default=False)
    is_exempted = Column(Boolean, default=False)
    remarks = Column(String(255))
    entered_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    verified_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))


class GradingScale(TenantModel):
    __tablename__ = "grading_scales"

    name = Column(String(100), nullable=False)
    scale_type = Column(String(20), default="percentage")  # percentage/grade/points
    is_default = Column(Boolean, default=False)


class GradingScaleDetail(TenantModel):
    __tablename__ = "grading_scale_details"

    grading_scale_id = Column(UUID(as_uuid=True), ForeignKey("grading_scales.id", ondelete="CASCADE"), nullable=False, index=True)
    grade = Column(String(10), nullable=False)
    min_percentage = Column(Numeric(5, 2), nullable=False)
    max_percentage = Column(Numeric(5, 2), nullable=False)
    gpa = Column(Numeric(3, 1))
    description = Column(String(50))
    sort_order = Column(Integer, default=0)
