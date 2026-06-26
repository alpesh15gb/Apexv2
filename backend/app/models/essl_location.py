"""eSSL Location model — per-server location mapping for eBioserverNew."""

from sqlalchemy import Column, String, Boolean, Text, DateTime, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, timezone

from app.db.base import TenantModel


class EsslLocation(TenantModel):
    __tablename__ = "essl_locations"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    code = Column(String(100), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    synced_at = Column(DateTime(timezone=True))

    essl_server = relationship("EsslServer", back_populates="locations")

    __table_args__ = (
        UniqueConstraint("essl_server_id", "code", name="uq_essl_locations_server_code"),
    )
