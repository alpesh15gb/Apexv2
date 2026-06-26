"""Outdoor Duty model — track employees working outside office."""

import enum
from sqlalchemy import Column, String, Date, Time, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ODStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"


class OutdoorDuty(TenantModel):
    __tablename__ = "outdoor_duties"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False)
    from_time = Column(Time, nullable=True)
    to_time = Column(Time, nullable=True)
    reason = Column(Text, nullable=True)
    location = Column(String(255), nullable=True)
    status = Column(String(50), default=ODStatus.PENDING, nullable=False)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)

    employee = relationship("Employee", foreign_keys=[employee_id])
    approver = relationship("Employee", foreign_keys=[approved_by])
