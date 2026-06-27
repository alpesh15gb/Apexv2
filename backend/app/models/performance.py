"""Performance Management models."""

import uuid
from datetime import datetime, timezone, date
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Date, Text, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ReviewCycle(TenantModel):
    __tablename__ = "review_cycles"

    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    cycle_type = Column(String(50), nullable=False, default="quarterly")
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    self_review_due = Column(Date, nullable=True)
    manager_review_due = Column(Date, nullable=True)
    hr_review_due = Column(Date, nullable=True)
    status = Column(String(50), nullable=False, default="draft")
    created_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Goal(TenantModel):
    __tablename__ = "goals"

    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False)
    cycle_id = Column(UUID(as_uuid=True), ForeignKey("review_cycles.id", ondelete="SET NULL"), nullable=True)
    title = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    goal_type = Column(String(50), nullable=False, default="individual")
    category = Column(String(100), nullable=True)
    weightage = Column(Float, nullable=False, default=0)
    target_value = Column(Float, nullable=True)
    current_value = Column(Float, nullable=True)
    progress = Column(Float, nullable=False, default=0)
    due_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=False, default="draft")
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class PerformanceReview(TenantModel):
    __tablename__ = "performance_reviews"

    cycle_id = Column(UUID(as_uuid=True), ForeignKey("review_cycles.id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False)
    reviewer_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    review_type = Column(String(50), nullable=False, default="self")
    status = Column(String(50), nullable=False, default="pending")
    rating = Column(Float, nullable=True)
    strengths = Column(Text, nullable=True)
    improvements = Column(Text, nullable=True)
    comments = Column(Text, nullable=True)
    goals_achievement = Column(Float, nullable=True)
    competency_scores = Column(Text, nullable=True)
    submitted_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class Competency(TenantModel):
    __tablename__ = "competencies"

    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(100), nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))


class PerformanceRecommendation(TenantModel):
    __tablename__ = "performance_recommendations"

    review_id = Column(UUID(as_uuid=True), ForeignKey("performance_reviews.id", ondelete="CASCADE"), nullable=False)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False)
    recommended_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    recommendation_type = Column(String(50), nullable=False)
    details = Column(Text, nullable=True)
    salary_increment = Column(Float, nullable=True)
    new_designation_id = Column(UUID(as_uuid=True), ForeignKey("designations.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(50), nullable=False, default="pending")
    approved_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
