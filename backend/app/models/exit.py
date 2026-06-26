"""Exit model — employee exit/resignation workflow."""

import enum
from sqlalchemy import Column, String, Date, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ExitStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    COMPLETED = "completed"


class ExitRequest(TenantModel):
    __tablename__ = "exit_requests"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    resignation_date = Column(Date, nullable=False)
    last_working_date = Column(Date, nullable=True)
    reason = Column(Text, nullable=True)
    status = Column(String(50), default=ExitStatus.PENDING, nullable=False)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    exit_interview_notes = Column(Text, nullable=True)
    clearance_status = Column(String(50), default="pending", nullable=False)

    employee = relationship("Employee", foreign_keys=[employee_id])
    approver = relationship("Employee", foreign_keys=[approved_by])
