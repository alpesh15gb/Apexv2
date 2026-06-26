"""Asset and Travel models."""
from sqlalchemy import Column, String, Float, Boolean, Date, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from app.db.base import TenantModel


class CompanyAsset(TenantModel):
    __tablename__ = "company_assets"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    asset_code = Column(String(100), nullable=False)
    category = Column(String(100), default="other", nullable=False)
    serial_number = Column(String(255), nullable=True)
    purchase_date = Column(Date, nullable=True)
    warranty_expiry = Column(Date, nullable=True)
    assigned_to = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    status = Column(String(50), default="available", nullable=False)
    description = Column(Text, nullable=True)
    employee = relationship("Employee")


class TravelRequest(TenantModel):
    __tablename__ = "travel_requests"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    destination = Column(String(255), nullable=False)
    purpose = Column(Text, nullable=True)
    from_date = Column(Date, nullable=False)
    to_date = Column(Date, nullable=False)
    estimated_cost = Column(Float, default=0)
    status = Column(String(50), default="pending", nullable=False)
    approved_by = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)
    employee = relationship("Employee", foreign_keys=[employee_id])
    approver = relationship("Employee", foreign_keys=[approved_by])
