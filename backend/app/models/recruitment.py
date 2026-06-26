"""Recruitment models for Applicant Tracking System."""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Date, Text, Float, ForeignKey, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class JobRequisition(TenantModel):
    __tablename__ = "job_requisitions"

    title = Column(String(255), nullable=False)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True)
    branch_id = Column(UUID(as_uuid=True), ForeignKey("branches.id", ondelete="SET NULL"), nullable=True)
    hiring_manager_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    employment_type = Column(String(50), nullable=False, default="permanent")
    openings = Column(Integer, nullable=False, default=1)
    experience_min = Column(Integer, nullable=True)
    experience_max = Column(Integer, nullable=True)
    salary_min = Column(Float, nullable=True)
    salary_max = Column(Float, nullable=True)
    skills = Column(Text, nullable=True)
    description = Column(Text, nullable=True)
    status = Column(String(50), nullable=False, default="draft")
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class JobOpening(TenantModel):
    __tablename__ = "job_openings"

    requisition_id = Column(UUID(as_uuid=True), ForeignKey("job_requisitions.id", ondelete="SET NULL"), nullable=True)
    title = Column(String(255), nullable=False)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True)
    branch_id = Column(UUID(as_uuid=True), ForeignKey("branches.id", ondelete="SET NULL"), nullable=True)
    description = Column(Text, nullable=True)
    requirements = Column(Text, nullable=True)
    employment_type = Column(String(50), nullable=False, default="permanent")
    openings = Column(Integer, nullable=False, default=1)
    salary_min = Column(Float, nullable=True)
    salary_max = Column(Float, nullable=True)
    location = Column(String(255), nullable=True)
    status = Column(String(50), nullable=False, default="draft")
    published_at = Column(DateTime(timezone=True), nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Candidate(TenantModel):
    __tablename__ = "candidates"

    opening_id = Column(UUID(as_uuid=True), ForeignKey("job_openings.id", ondelete="SET NULL"), nullable=True)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    resume_path = Column(String(512), nullable=True)
    skills = Column(Text, nullable=True)
    experience_years = Column(Integer, nullable=True)
    education = Column(Text, nullable=True)
    current_company = Column(String(255), nullable=True)
    current_designation = Column(String(255), nullable=True)
    expected_salary = Column(Float, nullable=True)
    notice_period = Column(Integer, nullable=True)
    source = Column(String(100), nullable=True)
    stage = Column(String(100), nullable=False, default="applied")
    rating = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    tags = Column(Text, nullable=True)
    applied_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Interview(TenantModel):
    __tablename__ = "interviews"

    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id", ondelete="CASCADE"), nullable=False)
    opening_id = Column(UUID(as_uuid=True), ForeignKey("job_openings.id", ondelete="SET NULL"), nullable=True)
    interviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    scheduled_at = Column(DateTime(timezone=True), nullable=False)
    duration_minutes = Column(Integer, nullable=False, default=60)
    location = Column(String(255), nullable=True)
    meeting_link = Column(String(512), nullable=True)
    interview_type = Column(String(50), nullable=False, default="hr")
    status = Column(String(50), nullable=False, default="scheduled")
    feedback = Column(Text, nullable=True)
    rating = Column(Integer, nullable=True)
    recommendation = Column(String(50), nullable=True)
    conducted_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Offer(TenantModel):
    __tablename__ = "offers"

    candidate_id = Column(UUID(as_uuid=True), ForeignKey("candidates.id", ondelete="CASCADE"), nullable=False)
    opening_id = Column(UUID(as_uuid=True), ForeignKey("job_openings.id", ondelete="SET NULL"), nullable=True)
    offered_salary = Column(Float, nullable=False)
    offered_designation = Column(String(255), nullable=True)
    offered_department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id", ondelete="SET NULL"), nullable=True)
    joining_date = Column(Date, nullable=True)
    expiry_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=False, default="draft")
    offer_letter_path = Column(String(512), nullable=True)
    notes = Column(Text, nullable=True)
    accepted_at = Column(DateTime(timezone=True), nullable=True)
    rejected_at = Column(DateTime(timezone=True), nullable=True)
    rejection_reason = Column(Text, nullable=True)
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
