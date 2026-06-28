"""Fee management models."""

from sqlalchemy import Column, String, Boolean, Integer, Date, Numeric, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class FeeCategory(TenantModel):
    __tablename__ = "fee_categories"

    name = Column(String(100), nullable=False)
    code = Column(String(30), nullable=False)
    is_active = Column(Boolean, default=True)
    sort_order = Column(Integer, default=0)


class FeeStructure(TenantModel):
    __tablename__ = "fee_structures"

    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id"), nullable=False, index=True)
    fee_category_id = Column(UUID(as_uuid=True), ForeignKey("fee_categories.id"), nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    frequency = Column(String(20), default="monthly")  # monthly/quarterly/half-yearly/annual/one-time
    due_day = Column(Integer, default=10)
    is_mandatory = Column(Boolean, default=True)


class StudentFee(TenantModel):
    __tablename__ = "student_fees"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    fee_structure_id = Column(UUID(as_uuid=True), ForeignKey("fee_structures.id"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    discount_amount = Column(Numeric(12, 2), default=0)
    scholarship_amount = Column(Numeric(12, 2), default=0)
    final_amount = Column(Numeric(12, 2), nullable=False)
    due_date = Column(Date)
    status = Column(String(20), default="pending")  # pending/partial/paid/overdue/waived


class FeePayment(TenantModel):
    __tablename__ = "fee_payments"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    student_fee_id = Column(UUID(as_uuid=True), ForeignKey("student_fees.id"), nullable=False, index=True)
    amount = Column(Numeric(12, 2), nullable=False)
    payment_date = Column(Date, nullable=False)
    payment_method = Column(String(30), default="cash")  # cash/card/upi/cheque/neft/online
    reference_number = Column(String(100))
    receipt_number = Column(String(50))
    collected_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    remarks = Column(Text)
    status = Column(String(20), default="completed")  # completed/refunded/cancelled


class FeeFineRule(TenantModel):
    __tablename__ = "fee_fine_rules"

    fee_category_id = Column(UUID(as_uuid=True), ForeignKey("fee_categories.id"), nullable=False, index=True)
    days_after_due = Column(Integer, nullable=False)
    fine_type = Column(String(20), default="fixed")  # fixed/percentage
    fine_amount = Column(Numeric(10, 2), nullable=False)
    max_fine = Column(Numeric(10, 2))
    is_active = Column(Boolean, default=True)


class Scholarship(TenantModel):
    __tablename__ = "scholarships"

    name = Column(String(255), nullable=False)
    scholarship_type = Column(String(20), default="percentage")  # percentage/fixed
    value = Column(Numeric(10, 2), nullable=False)
    max_amount = Column(Numeric(12, 2))
    applicable_fee_categories = Column(JSONB, default=[])
    is_active = Column(Boolean, default=True)


class StudentScholarship(TenantModel):
    __tablename__ = "student_scholarships"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    scholarship_id = Column(UUID(as_uuid=True), ForeignKey("scholarships.id"), nullable=False, index=True)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    start_date = Column(Date)
    end_date = Column(Date)
    is_active = Column(Boolean, default=True)
