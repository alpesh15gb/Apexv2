"""Admission inquiry and application models."""

from sqlalchemy import Column, String, Boolean, Date, Text, Numeric, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class AdmissionInquiry(TenantModel):
    __tablename__ = "admission_inquiries"

    student_name = Column(String(255), nullable=False)
    parent_name = Column(String(255))
    phone = Column(String(20), nullable=False)
    email = Column(String(255))
    grade_applying = Column(String(50))
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"))
    source = Column(String(50))  # walk-in/website/referral/agent
    status = Column(String(20), default="new")  # new/contacted/visited/applied/admitted/rejected
    notes = Column(Text)
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("employees.id"))


class AdmissionApplication(TenantModel):
    __tablename__ = "admission_applications"

    inquiry_id = Column(UUID(as_uuid=True), ForeignKey("admission_inquiries.id"))
    application_number = Column(String(50), nullable=False)
    student_name = Column(String(255), nullable=False)
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String(10), nullable=False)
    grade_applying = Column(String(50), nullable=False)
    parent_name = Column(String(255), nullable=False)
    parent_phone = Column(String(20), nullable=False)
    parent_email = Column(String(255))
    previous_school = Column(String(255))
    previous_grade = Column(String(50))
    address = Column(Text)
    documents = Column(JSONB, default=[])
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    status = Column(String(20), default="submitted")  # submitted/under_review/interview_scheduled/selected/rejected/enrolled
    interview_date = Column(DateTime(timezone=True))
    interview_score = Column(Numeric(5, 2))
    remarks = Column(Text)
    reviewed_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    reviewed_at = Column(DateTime(timezone=True))
    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id"))
