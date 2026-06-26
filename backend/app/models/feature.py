"""Feature flag models for per-tenant feature management."""

import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel, Base


class FeatureFlag(Base):
    """Global feature flag definitions. Not tenant-scoped."""
    __tablename__ = "feature_flags"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False, unique=True)
    description = Column(Text, nullable=True)
    module = Column(String(100), nullable=False, default="general")
    category = Column(String(100), nullable=False, default="core")
    is_active = Column(Boolean, nullable=False, default=True)
    sort_order = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    tenant_features = relationship("TenantFeature", back_populates="feature")


class TenantFeature(TenantModel):
    """Per-tenant feature enablement. Maps features to tenants."""
    __tablename__ = "tenant_features"
    __table_args__ = (
        UniqueConstraint("tenant_id", "feature_id", name="uq_tenant_features_tenant_feature"),
    )

    feature_id = Column(UUID(as_uuid=True), ForeignKey("feature_flags.id", ondelete="CASCADE"), nullable=False)
    is_enabled = Column(Boolean, nullable=False, default=False)
    enabled_at = Column(DateTime(timezone=True), nullable=True)
    enabled_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    config = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime(timezone=True), nullable=False, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    feature = relationship("FeatureFlag", back_populates="tenant_features")
