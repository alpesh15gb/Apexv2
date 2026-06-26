"""Benefits model."""
from sqlalchemy import Column, String, Float, Boolean, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import TenantModel


class Benefit(TenantModel):
    __tablename__ = "benefits"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    type = Column(String(50), default="allowance", nullable=False)
    amount = Column(Float, default=0)
    frequency = Column(String(50), default="monthly", nullable=False)
    is_taxable = Column(Boolean, default=True)
    is_active = Column(Boolean, default=True)


class EmployeeBenefit(TenantModel):
    __tablename__ = "employee_benefits"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    benefit_id = Column(UUID(as_uuid=True), ForeignKey("benefits.id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Float, default=0)
    effective_from = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True)
    employee = relationship("Employee")
    benefit = relationship("Benefit")
