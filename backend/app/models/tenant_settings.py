"""Tenant Settings model — master attendance configuration."""

from sqlalchemy import Column, String, Integer, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class TenantSettings(TenantModel):
    __tablename__ = "tenant_settings"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        unique=True,
        index=True,
    )
    attendance_year_start_month = Column(Integer, default=1, nullable=False)
    attendance_year_start_day = Column(Integer, default=1, nullable=False)
    min_punch_difference_minutes = Column(Integer, default=1, nullable=False)
    punch_begin_before_minutes = Column(Integer, default=60, nullable=False)
    auto_shift_if_no_schedule = Column(Boolean, default=True, nullable=False)
    fixed_shift_mode = Column(Boolean, default=False, nullable=False)
