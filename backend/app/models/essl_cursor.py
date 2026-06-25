"""eSSL sync cursor — persistent state for incremental sync."""

from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class EsslSyncCursor(TenantModel):
    """Tracks the last successful sync position per server per type.
    Enables 'fetch after cursor' instead of 'download everything again'.
    """

    __tablename__ = "essl_sync_cursor"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    cursor_type = Column(String(50), nullable=False)
    last_transaction_id = Column(String(255))
    last_punch_time = Column(DateTime(timezone=True))
    last_employee_sync = Column(DateTime(timezone=True))
    last_device_sync = Column(DateTime(timezone=True))
    updated_at = Column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False
    )

    essl_server = relationship("EsslServer", back_populates="sync_cursors")

    __table_args__ = (
        UniqueConstraint(
            "essl_server_id", "cursor_type", name="uq_essl_cursor_server_type"
        ),
    )
