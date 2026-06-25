import enum
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Index
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship

from app.db.base import BaseModel


class SubscriptionPlan(str, enum.Enum):
    FREE = "free"
    BASIC = "basic"
    PRO = "pro"
    ENTERPRISE = "enterprise"


class Tenant(BaseModel):
    __tablename__ = "tenants"

    name = Column(String(255), nullable=False)
    slug = Column(String(255), unique=True, nullable=False, index=True)
    domain = Column(String(255), nullable=True)
    logo_url = Column(String(512), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    max_employees = Column(Integer, nullable=True)
    subscription_plan = Column(
        String(50),
        default=SubscriptionPlan.FREE,
        nullable=False,
    )
    subscription_expires_at = Column(DateTime(timezone=True), nullable=True)
    settings = Column(JSONB, default=dict, server_default="{}", nullable=False)

    # Relationships
    users = relationship("User", back_populates="tenant", cascade="all, delete-orphan")
    roles = relationship("Role", back_populates="tenant", cascade="all, delete-orphan")
    permissions = relationship("Permission", back_populates="tenant", cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="tenant", cascade="all, delete-orphan")
    employees = relationship("Employee", back_populates="tenant", cascade="all, delete-orphan")
    departments = relationship("Department", back_populates="tenant", cascade="all, delete-orphan")
    designations = relationship("Designation", back_populates="tenant", cascade="all, delete-orphan")
    branches = relationship("Branch", back_populates="tenant", cascade="all, delete-orphan")
    devices = relationship("Device", back_populates="tenant", cascade="all, delete-orphan")
    device_logs = relationship("DeviceLog", back_populates="tenant", cascade="all, delete-orphan")
    attendances = relationship("Attendance", back_populates="tenant", cascade="all, delete-orphan")
    punch_logs = relationship("PunchLog", back_populates="tenant", cascade="all, delete-orphan")
    shifts = relationship("Shift", back_populates="tenant", cascade="all, delete-orphan")
    shift_schedules = relationship("ShiftSchedule", back_populates="tenant", cascade="all, delete-orphan")
    leave_types = relationship("LeaveType", back_populates="tenant", cascade="all, delete-orphan")
    leave_balances = relationship("LeaveBalance", back_populates="tenant", cascade="all, delete-orphan")
    leave_requests = relationship("LeaveRequest", back_populates="tenant", cascade="all, delete-orphan")
    visitors = relationship("Visitor", back_populates="tenant", cascade="all, delete-orphan")
    visitor_passes = relationship("VisitorPass", back_populates="tenant", cascade="all, delete-orphan")
    access_zones = relationship("AccessZone", back_populates="tenant", cascade="all, delete-orphan")
    doors = relationship("Door", back_populates="tenant", cascade="all, delete-orphan")
    user_access_levels = relationship("UserAccessLevel", back_populates="tenant", cascade="all, delete-orphan")
    access_logs = relationship("AccessLog", back_populates="tenant", cascade="all, delete-orphan")
    device_commands = relationship("DeviceCommand", back_populates="tenant", cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="tenant", cascade="all, delete-orphan")
    essl_servers = relationship("EsslServer", back_populates="tenant", cascade="all, delete-orphan")
    attendance_raw_logs = relationship("AttendanceRawLog", back_populates="tenant", cascade="all, delete-orphan")

    __table_args__ = (
        Index("ix_tenants_slug_unique", "slug", unique=True),
    )
