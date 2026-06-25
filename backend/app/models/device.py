import enum
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class DeviceStatus(str, enum.Enum):
    ONLINE = "online"
    OFFLINE = "offline"
    INACTIVE = "inactive"
    ERROR = "error"


class DeviceType(str, enum.Enum):
    BIOMETRIC = "biometric"
    ACCESS_CONTROL = "access_control"
    BOTH = "both"


class CommunicationMode(str, enum.Enum):
    TCP_IP = "tcp/ip"
    WIFI = "wifi"
    FOUR_G = "4g"


class Device(TenantModel):
    __tablename__ = "devices"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    serial_number = Column(String(100), nullable=False)
    device_name = Column(String(255), nullable=False)
    model = Column(String(100), nullable=True)
    firmware_version = Column(String(100), nullable=True)
    ip_address = Column(String(45), nullable=True)
    port = Column(Integer, nullable=True)
    location = Column(String(255), nullable=True)
    branch_id = Column(
        UUID(as_uuid=True),
        ForeignKey("branches.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    last_ping = Column(DateTime(timezone=True), nullable=True)
    last_sync = Column(DateTime(timezone=True), nullable=True)
    status = Column(
        String(50),
        default=DeviceStatus.INACTIVE,
        nullable=False,
    )
    is_active = Column(Boolean, default=True, nullable=False)
    device_type = Column(
        String(50),
        default=DeviceType.BIOMETRIC,
        nullable=False,
    )
    communication_mode = Column(
        String(50),
        default=CommunicationMode.TCP_IP,
        nullable=False,
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="devices")
    branch = relationship("Branch", back_populates="devices")
    device_logs = relationship("DeviceLog", back_populates="device", cascade="all, delete-orphan")
    punch_logs = relationship("PunchLog", back_populates="device", cascade="all, delete-orphan")
    doors = relationship("Door", back_populates="device", cascade="all, delete-orphan")
    commands = relationship("DeviceCommand", back_populates="device", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("tenant_id", "serial_number", name="uq_devices_tenant_serial_number"),
    )


class DeviceLog(TenantModel):
    __tablename__ = "device_logs"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    log_type = Column(String(100), nullable=False)
    message = Column(Text, nullable=True)
    raw_data = Column(JSONB, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="device_logs")
    device = relationship("Device", back_populates="device_logs")
