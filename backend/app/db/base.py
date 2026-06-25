"""Base model mixins and common columns."""

import uuid
from datetime import datetime
from sqlalchemy import Column, DateTime, func, text
from sqlalchemy.dialects.postgresql import UUID

from app.db.session import Base


class TimestampMixin:
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)


class TenantMixin:
    """Every business entity must have a tenant_id for isolation."""
    tenant_id = Column(
        UUID(as_uuid=True),
        nullable=False,
        index=True,
        server_default=text("gen_random_uuid()"),
    )


class UUIDPrimaryKeyMixin:
    id = Column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )


class BaseModel(Base, UUIDPrimaryKeyMixin, TimestampMixin):
    """Abstract base for all application models."""
    __abstract__ = True


class TenantModel(Base, UUIDPrimaryKeyMixin, TimestampMixin, TenantMixin):
    """Abstract base for all tenant-scoped business models."""
    __abstract__ = True
