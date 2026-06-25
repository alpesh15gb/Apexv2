"""eSSL sync history, job scheduling, and error tracking models."""

import enum
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Text, DateTime,
    ForeignKey, UniqueConstraint, func,
)
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class SyncStatus(str, enum.Enum):
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    PARTIAL = "partial"
    CANCELLED = "cancelled"


class SyncType(str, enum.Enum):
    EMPLOYEES = "employees"
    ATTENDANCE = "attendance"
    DEVICES = "devices"
    FULL = "full"


class EsslSyncHistory(TenantModel):
    __tablename__ = "essl_sync_history"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    sync_type = Column(String(50), nullable=False)
    status = Column(String(50), default=SyncStatus.RUNNING, nullable=False)
    started_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    completed_at = Column(DateTime(timezone=True))
    duration_seconds = Column(Float)
    records_fetched = Column(Integer, default=0, nullable=False)
    records_created = Column(Integer, default=0, nullable=False)
    records_updated = Column(Integer, default=0, nullable=False)
    records_skipped = Column(Integer, default=0, nullable=False)
    records_failed = Column(Integer, default=0, nullable=False)
    error_message = Column(Text)
    triggered_by = Column(String(50), default="auto", nullable=False)
    date_range_from = Column(DateTime(timezone=True))
    date_range_to = Column(DateTime(timezone=True))

    progress_percent = Column(Integer, default=0, nullable=False)
    total_records_expected = Column(Integer, default=0)
    current_batch = Column(Integer, default=0)
    total_batches = Column(Integer, default=0)
    is_paused = Column(Boolean, default=False, nullable=False)
    is_cancelled = Column(Boolean, default=False, nullable=False)
    last_checkpoint = Column(JSONB, nullable=True)

    essl_server = relationship("EsslServer", back_populates="sync_history")
    errors = relationship(
        "EsslSyncError", back_populates="sync_history", cascade="all, delete-orphan"
    )


class EsslSyncJob(TenantModel):
    __tablename__ = "essl_sync_jobs"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    job_type = Column(String(50), nullable=False)
    interval_minutes = Column(Integer, nullable=False)
    scheduled_hour = Column(Integer, nullable=True)
    is_enabled = Column(Boolean, default=True, nullable=False)
    last_run_at = Column(DateTime(timezone=True))
    next_run_at = Column(DateTime(timezone=True))
    last_status = Column(String(50))
    consecutive_failures = Column(Integer, default=0, nullable=False)

    essl_server = relationship("EsslServer", back_populates="sync_jobs")

    __table_args__ = (
        UniqueConstraint(
            "essl_server_id", "job_type", name="uq_essl_sync_jobs_server_type"
        ),
    )


class EsslSyncError(TenantModel):
    __tablename__ = "essl_sync_errors"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    sync_history_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_sync_history.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    error_code = Column(String(100))
    error_message = Column(Text)
    entity_type = Column(String(50))
    entity_identifier = Column(String(255))
    raw_data = Column(JSONB)
    occurred_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    sync_history = relationship("EsslSyncHistory", back_populates="errors")
