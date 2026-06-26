"""Approval workflow models for configurable multi-level approvals."""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, JSON, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ApprovalWorkflow(TenantModel):
    """Configurable approval workflow definition per tenant."""
    __tablename__ = "approval_workflows"

    name = Column(String(255), nullable=False)
    entity_type = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, nullable=False, default=True)
    auto_approve_hours = Column(Integer, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    steps = relationship("ApprovalStep", back_populates="workflow", order_by="ApprovalStep.step_order")
    requests = relationship("ApprovalRequest", back_populates="workflow")


class ApprovalStep(TenantModel):
    """Individual step in an approval workflow."""
    __tablename__ = "approval_steps"

    workflow_id = Column(UUID(as_uuid=True), ForeignKey("approval_workflows.id", ondelete="CASCADE"), nullable=False)
    step_order = Column(Integer, nullable=False)
    name = Column(String(255), nullable=False)
    approver_type = Column(String(50), nullable=False, default="role")
    approver_role_id = Column(UUID(as_uuid=True), ForeignKey("roles.id", ondelete="SET NULL"), nullable=True)
    approver_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    is_parallel = Column(Boolean, nullable=False, default=False)
    auto_approve_hours = Column(Integer, nullable=True)
    is_required = Column(Boolean, nullable=False, default=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    workflow = relationship("ApprovalWorkflow", back_populates="steps")


class ApprovalRequest(TenantModel):
    """Individual approval request for an entity."""
    __tablename__ = "approval_requests"

    workflow_id = Column(UUID(as_uuid=True), ForeignKey("approval_workflows.id", ondelete="SET NULL"), nullable=True)
    entity_type = Column(String(100), nullable=False)
    entity_id = Column(UUID(as_uuid=True), nullable=False)
    requester_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    current_step = Column(Integer, nullable=False, default=1)
    status = Column(String(50), nullable=False, default="pending")
    remarks = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    workflow = relationship("ApprovalWorkflow", back_populates="requests")
    history = relationship("ApprovalHistory", back_populates="request", order_by="ApprovalHistory.acted_at")


class ApprovalHistory(TenantModel):
    """Audit trail for approval actions."""
    __tablename__ = "approval_history"

    request_id = Column(UUID(as_uuid=True), ForeignKey("approval_requests.id", ondelete="CASCADE"), nullable=False)
    step_order = Column(Integer, nullable=False)
    approver_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String(50), nullable=False)
    remarks = Column(Text, nullable=True)
    acted_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))

    request = relationship("ApprovalRequest", back_populates="history")


class LoginHistory(TenantModel):
    """Track all login attempts per tenant."""
    __tablename__ = "login_history"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    email = Column(String(255), nullable=False)
    ip_address = Column(String(50), nullable=True)
    user_agent = Column(Text, nullable=True)
    device_type = Column(String(50), nullable=True)
    location = Column(String(255), nullable=True)
    login_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    logout_at = Column(DateTime(timezone=True), nullable=True)
    is_successful = Column(Boolean, nullable=False, default=True)
    failure_reason = Column(Text, nullable=True)


class SuperAdminLog(Base):
    """Global audit log for super admin actions. NOT tenant-scoped."""
    __tablename__ = "super_admin_logs"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    admin_user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    action = Column(String(255), nullable=False)
    target_type = Column(String(100), nullable=False)
    target_id = Column(UUID(as_uuid=True), nullable=True)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text, nullable=True)
    ip_address = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
