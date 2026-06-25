import enum
from sqlalchemy import Column, String, Integer, Float, Boolean, Date, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class LeaveRequestStatus(str, enum.Enum):
    PENDING = "pending"
    APPROVED = "approved"
    REJECTED = "rejected"
    CANCELLED = "cancelled"


class LeaveType(TenantModel):
    __tablename__ = "leave_types"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False)
    default_days = Column(Integer, default=0, nullable=False)
    is_paid = Column(Boolean, default=True, nullable=False)
    carry_forward = Column(Boolean, default=False, nullable=False)
    max_consecutive = Column(Integer, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="leave_types")
    leave_balances = relationship("LeaveBalance", back_populates="leave_type", cascade="all, delete-orphan")
    leave_requests = relationship("LeaveRequest", back_populates="leave_type", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("tenant_id", "code", name="uq_leave_types_tenant_code"),
    )


class LeaveBalance(TenantModel):
    __tablename__ = "leave_balances"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    leave_type_id = Column(
        UUID(as_uuid=True),
        ForeignKey("leave_types.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    year = Column(Integer, nullable=False)
    total_days = Column(Float, default=0.0, nullable=False)
    used_days = Column(Float, default=0.0, nullable=False)
    pending_days = Column(Float, default=0.0, nullable=False)
    carried_forward = Column(Float, default=0.0, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="leave_balances")
    employee = relationship("Employee", back_populates="leave_balances")
    leave_type = relationship("LeaveType", back_populates="leave_balances")

    __table_args__ = (
        UniqueConstraint("tenant_id", "employee_id", "leave_type_id", "year", name="uq_leave_balances_tenant_employee_type_year"),
    )


class LeaveRequest(TenantModel):
    __tablename__ = "leave_requests"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    leave_type_id = Column(
        UUID(as_uuid=True),
        ForeignKey("leave_types.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    total_days = Column(Float, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(
        String(50),
        default=LeaveRequestStatus.PENDING,
        nullable=False,
    )
    approved_by = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    approved_at = Column(DateTime(timezone=True), nullable=True)
    rejection_reason = Column(Text, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="leave_requests")
    employee = relationship("Employee", foreign_keys=[employee_id], back_populates="leave_requests")
    approved_by_employee = relationship("Employee", foreign_keys=[approved_by], back_populates="approved_leave_requests")
    leave_type = relationship("LeaveType", back_populates="leave_requests")
