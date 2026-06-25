"""eSSL Server configuration model — per-tenant eBioserverNew connection settings."""

import enum
from sqlalchemy import Column, String, Integer, Boolean, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class EsslServerStatus(str, enum.Enum):
    CONNECTED = "connected"
    DISCONNECTED = "disconnected"
    TESTING = "testing"
    ERROR = "error"


class ConflictPolicy(str, enum.Enum):
    IGNORE = "ignore"
    DISABLE = "disable"
    SOFT_DELETE = "soft_delete"
    HARD_DELETE = "hard_delete"


class EsslServer(TenantModel):
    __tablename__ = "essl_servers"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    server_url = Column(String(512), nullable=False)
    username = Column(String(255), nullable=False)
    password_encrypted = Column(Text, nullable=False)
    timeout_seconds = Column(Integer, default=30, nullable=False)
    timezone = Column(String(50), default="Asia/Kolkata", nullable=False)
    auto_sync_enabled = Column(Boolean, default=True, nullable=False)

    attendance_sync_interval_minutes = Column(Integer, default=5, nullable=False)
    device_sync_interval_minutes = Column(Integer, default=60, nullable=False)
    employee_sync_hour = Column(Integer, default=2, nullable=False)

    employee_conflict_policy = Column(
        String(50), default=ConflictPolicy.DISABLE, nullable=False
    )
    device_conflict_policy = Column(
        String(50), default=ConflictPolicy.DISABLE, nullable=False
    )

    status = Column(
        String(50), default=EsslServerStatus.DISCONNECTED, nullable=False
    )
    last_connected_at = Column(DateTime(timezone=True))
    last_error = Column(Text)
    server_version = Column(String(100))
    is_active = Column(Boolean, default=True, nullable=False)

    tenant = relationship("Tenant", back_populates="essl_servers")
    sync_history = relationship(
        "EsslSyncHistory", back_populates="essl_server", cascade="all, delete-orphan"
    )
    sync_jobs = relationship(
        "EsslSyncJob", back_populates="essl_server", cascade="all, delete-orphan"
    )
    sync_cursors = relationship(
        "EsslSyncCursor", back_populates="essl_server", cascade="all, delete-orphan"
    )
    employee_mappings = relationship(
        "EsslEmployeeMapping", back_populates="essl_server", cascade="all, delete-orphan"
    )
    device_mappings = relationship(
        "EsslDeviceMapping", back_populates="essl_server", cascade="all, delete-orphan"
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "name", name="uq_essl_servers_tenant_name"),
    )
