"""Work Code model — project/task codes for time allocation."""

from sqlalchemy import Column, String, Boolean, Text, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class WorkCode(TenantModel):
    __tablename__ = "work_codes"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    code = Column(String(50), nullable=False)
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    tenant = relationship("Tenant", back_populates="work_codes")

    __table_args__ = (UniqueConstraint("tenant_id", "code", name="uq_work_codes_tenant_code"),)
