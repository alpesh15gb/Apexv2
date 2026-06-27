"""Holiday model — company/national holidays."""

import enum
from sqlalchemy import Column, String, Boolean, Text, Date, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class HolidayType(str, enum.Enum):
    NATIONAL = "national"
    COMPANY = "company"
    RESTRICTED = "restricted"


class Holiday(TenantModel):
    __tablename__ = "holidays"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    date = Column(Date, nullable=False)
    type = Column(String(50), default=HolidayType.COMPANY, nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    tenant = relationship("Tenant", back_populates="holidays")

    __table_args__ = (
        UniqueConstraint("tenant_id", "date", name="uq_holidays_tenant_date"),
    )
