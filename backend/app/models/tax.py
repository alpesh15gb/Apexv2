"""Tax Declaration model."""
from sqlalchemy import Column, String, Float, Integer, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import TenantModel


class TaxDeclaration(TenantModel):
    __tablename__ = "tax_declarations"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    financial_year = Column(String(10), nullable=False)
    hra_received = Column(Float, default=0)
    rent_paid = Column(Float, default=0)
    section_80c = Column(Float, default=0)
    section_80d = Column(Float, default=0)
    home_loan_interest = Column(Float, default=0)
    other_exemptions = Column(Float, default=0)
    status = Column(String(50), default="draft", nullable=False)
    remarks = Column(Text, nullable=True)
