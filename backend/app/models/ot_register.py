"""OT Register model — overtime tracking and approval."""

import enum
from sqlalchemy import Column, String, Date, Float, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class OTStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    PRESERVED = "preserved"


class OTType(str, enum.Enum):
    NORMAL = "normal"
    HOLIDAY = "holiday"
    WEEKLY_OFF = "weekly_off"


class OTRegister(TenantModel):
    __tablename__ = "ot_register"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False)
    ot_hours = Column(Float, nullable=False)
    ot_type = Column(String(50), default=OTType.NORMAL, nullable=False)
    status = Column(String(50), default=OTStatus.PENDING, nullable=False)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    remarks = Column(Text, nullable=True)

    employee = relationship("Employee", foreign_keys=[employee_id])
    approver = relationship("Employee", foreign_keys=[approved_by])
