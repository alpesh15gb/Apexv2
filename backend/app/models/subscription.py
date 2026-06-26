"""Subscription and plan models for multi-tenant SaaS management."""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Date, Text, ForeignKey, UniqueConstraint, JSON
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel, Base


class SubscriptionPlan(Base):
    """Global subscription plans available for all tenants."""
    __tablename__ = "subscription_plans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=True)
    price_monthly = Column(Float, nullable=False, default=0)
    price_quarterly = Column(Float, nullable=False, default=0)
    price_half_yearly = Column(Float, nullable=False, default=0)
    price_annual = Column(Float, nullable=False, default=0)
    price_lifetime = Column(Float, nullable=False, default=0)
    max_employees = Column(Integer, nullable=False, default=50)
    max_branches = Column(Integer, nullable=False, default=5)
    max_departments = Column(Integer, nullable=False, default=10)
    max_devices = Column(Integer, nullable=False, default=5)
    max_admin_users = Column(Integer, nullable=False, default=2)
    max_hr_users = Column(Integer, nullable=False, default=5)
    max_storage_mb = Column(Integer, nullable=False, default=1024)
    max_api_calls = Column(Integer, nullable=False, default=10000)
    max_mobile_logins = Column(Integer, nullable=False, default=50)
    trial_days = Column(Integer, nullable=False, default=14)
    features = Column(JSON, nullable=False, default=list)
    is_active = Column(Boolean, nullable=False, default=True)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    subscriptions = relationship("TenantSubscription", back_populates="plan")


class TenantSubscription(TenantModel):
    """Active subscription for each tenant."""
    __tablename__ = "tenant_subscriptions"

    plan_id = Column(UUID(as_uuid=True), ForeignKey("subscription_plans.id"), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=True)
    renewal_date = Column(Date, nullable=True)
    status = Column(String(50), nullable=False, default="trial")
    billing_cycle = Column(String(50), nullable=False, default="monthly")
    payment_status = Column(String(50), nullable=False, default="pending")
    auto_renewal = Column(Boolean, nullable=False, default=False)
    last_payment_amount = Column(Float, nullable=True)
    last_payment_date = Column(Date, nullable=True)
    next_invoice_date = Column(Date, nullable=True)
    trial_ends_at = Column(DateTime(timezone=True), nullable=True)
    cancelled_at = Column(DateTime(timezone=True), nullable=True)
    cancel_reason = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    plan = relationship("SubscriptionPlan", back_populates="subscriptions")


class ResourceLimit(TenantModel):
    """Per-tenant configurable resource limits."""
    __tablename__ = "resource_limits"
    __table_args__ = (
        UniqueConstraint("tenant_id", "resource_key", name="uq_resource_limits_tenant_key"),
    )

    resource_key = Column(String(100), nullable=False)
    max_value = Column(Integer, nullable=False, default=0)
    current_value = Column(Integer, nullable=False, default=0)
    is_unlimited = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
