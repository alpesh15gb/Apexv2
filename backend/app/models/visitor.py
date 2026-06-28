import enum
from sqlalchemy import Column, String, Boolean, Date, DateTime, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class VisitorPassStatus(str, enum.Enum):
    PENDING = "pending"
    CHECKED_IN = "checked_in"
    CHECKED_OUT = "checked_out"
    EXPIRED = "expired"
    CANCELLED = "cancelled"


class Visitor(TenantModel):
    __tablename__ = "visitors"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=False)
    email = Column(String(255), nullable=True)
    photo_url = Column(String(512), nullable=True)
    id_proof_type = Column(String(100), nullable=True)
    id_proof_number = Column(String(100), nullable=True)
    company = Column(String(255), nullable=True)
    address = Column(String(512), nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="visitors")
    visitor_passes = relationship("VisitorPass", back_populates="visitor", cascade="all, delete-orphan")


class VisitorPass(TenantModel):
    __tablename__ = "visitor_passes"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    visitor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("visitors.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    host_employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    purpose = Column(String(255), nullable=False)
    expected_date = Column(Date, nullable=False)
    check_in_time = Column(DateTime(timezone=True), nullable=True)
    check_out_time = Column(DateTime(timezone=True), nullable=True)
    pass_number = Column(String(100), nullable=False)
    status = Column(
        String(50),
        default=VisitorPassStatus.PENDING,
        nullable=False,
    )
    badge_number = Column(String(100), nullable=True)
    zone_access = Column(JSONB, nullable=True)
    visitor_desk_validated = Column(Boolean, default=False, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="visitor_passes")
    visitor = relationship("Visitor", back_populates="visitor_passes")
    host_employee = relationship("Employee", back_populates="visitor_passes")
    access_logs = relationship("AccessLog", back_populates="visitor_pass", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("tenant_id", "pass_number", name="uq_visitor_passes_tenant_pass_number"),
        Index("ix_visitor_passes_tenant_status", "tenant_id", "status"),
    )
