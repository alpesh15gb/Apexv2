from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class AccessZone(TenantModel):
    __tablename__ = "access_zones"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    branch_id = Column(
        UUID(as_uuid=True),
        ForeignKey("branches.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    is_restricted = Column(Boolean, default=False, nullable=False)
    access_level_required = Column(Integer, default=0, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="access_zones")
    branch = relationship("Branch", back_populates="access_zones")
    doors = relationship("Door", back_populates="zone", cascade="all, delete-orphan")
    user_access_levels = relationship("UserAccessLevel", back_populates="zone", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("tenant_id", "branch_id", "name", name="uq_access_zones_tenant_branch_name"),
    )


class Door(TenantModel):
    __tablename__ = "doors"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    zone_id = Column(
        UUID(as_uuid=True),
        ForeignKey("access_zones.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="doors")
    zone = relationship("AccessZone", back_populates="doors")
    device = relationship("Device", back_populates="doors")
    access_logs = relationship("AccessLog", back_populates="door", cascade="all, delete-orphan")


class UserAccessLevel(TenantModel):
    __tablename__ = "user_access_levels"

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
    zone_id = Column(
        UUID(as_uuid=True),
        ForeignKey("access_zones.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    access_level = Column(Integer, default=1, nullable=False)
    granted_by = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    valid_from = Column(DateTime(timezone=True), nullable=True)
    valid_to = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="user_access_levels")
    employee = relationship("Employee", foreign_keys=[employee_id], back_populates="user_access_levels")
    zone = relationship("AccessZone", back_populates="user_access_levels")
    granted_by_employee = relationship("Employee", foreign_keys=[granted_by], back_populates="granted_access_levels")

    __table_args__ = (
        UniqueConstraint("tenant_id", "employee_id", "zone_id", name="uq_user_access_levels_tenant_employee_zone"),
    )


class AccessLog(TenantModel):
    __tablename__ = "access_logs"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    visitor_id = Column(
        UUID(as_uuid=True),
        ForeignKey("visitors.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    visitor_pass_id = Column(
        UUID(as_uuid=True),
        ForeignKey("visitor_passes.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    door_id = Column(
        UUID(as_uuid=True),
        ForeignKey("doors.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    access_time = Column(DateTime(timezone=True), nullable=False)
    access_type = Column(String(50), nullable=False)  # entry / exit
    granted = Column(Boolean, nullable=False)
    denial_reason = Column(String(255), nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="access_logs")
    employee = relationship("Employee", back_populates="access_logs")
    visitor_pass = relationship("VisitorPass", back_populates="access_logs")
    door = relationship("Door", back_populates="access_logs")
    visitor = relationship("Visitor")
