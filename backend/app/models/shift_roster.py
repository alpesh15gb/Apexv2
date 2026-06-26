"""Shift Roster model — rotation patterns for shifts."""

from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ShiftRoster(TenantModel):
    __tablename__ = "shift_rosters"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    description = Column(String(512), nullable=True)
    rotation_pattern = Column(String(50), default="weekly", nullable=False)  # daily, weekly, monthly, custom
    weekly_off_1 = Column(Integer, default=6, nullable=False)  # 0=Mon, 6=Sun
    weekly_off_2 = Column(Integer, nullable=True)
    weekly_off_2_week = Column(String(50), default="every", nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    entries = relationship("ShiftRosterEntry", back_populates="roster", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("tenant_id", "name", name="uq_shift_rosters_tenant_name"),)


class ShiftRosterEntry(TenantModel):
    __tablename__ = "shift_roster_entries"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    roster_id = Column(UUID(as_uuid=True), ForeignKey("shift_rosters.id", ondelete="CASCADE"), nullable=False, index=True)
    day_number = Column(Integer, nullable=False)  # 1-based day in rotation
    shift_id = Column(UUID(as_uuid=True), ForeignKey("shifts.id", ondelete="CASCADE"), nullable=True)  # null = weekly off

    roster = relationship("ShiftRoster", back_populates="entries")
    shift = relationship("Shift")

    __table_args__ = (UniqueConstraint("roster_id", "day_number", name="uq_shift_roster_entries_roster_day"),)
