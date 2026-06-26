"""Payroll models — salary structure and payslips."""

import enum
from sqlalchemy import Column, String, Integer, Float, Boolean, Date, Text, ForeignKey, DateTime, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class PayslipStatus(str, enum.Enum):
    DRAFT = "draft"
    CALCULATED = "calculated"
    FROZEN = "frozen"
    PAID = "paid"


class SalaryStructure(TenantModel):
    __tablename__ = "salary_structures"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    basic = Column(Float, default=0, nullable=False)
    hra = Column(Float, default=0, nullable=False)
    da = Column(Float, default=0, nullable=False)
    conveyance = Column(Float, default=0, nullable=False)
    medical = Column(Float, default=0, nullable=False)
    special = Column(Float, default=0, nullable=False)
    pf_employee = Column(Float, default=0, nullable=False)
    pf_employer = Column(Float, default=0, nullable=False)
    esi_employee = Column(Float, default=0, nullable=False)
    esi_employer = Column(Float, default=0, nullable=False)
    professional_tax = Column(Float, default=0, nullable=False)
    income_tax = Column(Float, default=0, nullable=False)
    effective_from = Column(Date, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    employee = relationship("Employee")

    __table_args__ = (
        UniqueConstraint("employee_id", "effective_from", name="uq_salary_employee_effective"),
    )


class PaySlip(TenantModel):
    __tablename__ = "pay_slips"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    month = Column(Integer, nullable=False)
    year = Column(Integer, nullable=False)
    basic = Column(Float, default=0, nullable=False)
    hra = Column(Float, default=0, nullable=False)
    da = Column(Float, default=0, nullable=False)
    conveyance = Column(Float, default=0, nullable=False)
    medical = Column(Float, default=0, nullable=False)
    special = Column(Float, default=0, nullable=False)
    gross_earnings = Column(Float, default=0, nullable=False)
    pf = Column(Float, default=0, nullable=False)
    esi = Column(Float, default=0, nullable=False)
    pt = Column(Float, default=0, nullable=False)
    it = Column(Float, default=0, nullable=False)
    total_deductions = Column(Float, default=0, nullable=False)
    net_pay = Column(Float, default=0, nullable=False)
    working_days = Column(Integer, default=0, nullable=False)
    present_days = Column(Integer, default=0, nullable=False)
    absent_days = Column(Integer, default=0, nullable=False)
    leave_days = Column(Integer, default=0, nullable=False)
    ot_hours = Column(Float, default=0, nullable=False)
    ot_amount = Column(Float, default=0, nullable=False)
    lop_days = Column(Integer, default=0, nullable=False)
    lop_amount = Column(Float, default=0, nullable=False)
    status = Column(String(50), default=PayslipStatus.DRAFT, nullable=False)
    generated_at = Column(DateTime(timezone=True), nullable=True)

    employee = relationship("Employee")

    __table_args__ = (
        UniqueConstraint("tenant_id", "employee_id", "month", "year", name="uq_pay_slips_tenant_emp_month_year"),
    )


class Loan(TenantModel):
    __tablename__ = "loans"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=False, index=True)
    loan_type = Column(String(100), nullable=False)
    amount = Column(Float, nullable=False)
    emi_amount = Column(Float, nullable=False)
    start_date = Column(Date, nullable=False)
    total_installments = Column(Integer, nullable=False)
    paid_installments = Column(Integer, default=0, nullable=False)
    status = Column(String(50), default="active", nullable=False)

    employee = relationship("Employee")
