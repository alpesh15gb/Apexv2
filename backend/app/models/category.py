"""Employee Category model — attendance rules per category."""

import enum
from sqlalchemy import Column, String, Integer, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class OTFormula(str, enum.Enum):
    OUT_PUNCH = "out_punch"
    TOTAL_DURATION = "total_duration"
    EARLY_LATE_SUM = "early_late_sum"


class WeeklyOffWeek(str, enum.Enum):
    EVERY = "every"
    FIRST = "1st"
    SECOND = "2nd"
    THIRD = "3rd"
    FOURTH = "4th"
    FIFTH = "5th"
    ALT_1_3 = "alternate_1_3"
    ALT_2_4 = "alternate_2_4"


class EmployeeCategory(TenantModel):
    __tablename__ = "employee_categories"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # OT Rules
    ot_formula = Column(String(50), default=OTFormula.OUT_PUNCH, nullable=False)
    min_ot_minutes = Column(Integer, default=0, nullable=False)
    max_ot_minutes = Column(Integer, default=0, nullable=False)

    # Grace & Thresholds
    grace_minutes = Column(Integer, default=0, nullable=False)
    half_day_threshold_minutes = Column(Integer, default=240, nullable=False)
    absent_threshold_minutes = Column(Integer, default=0, nullable=False)
    late_absent_minutes = Column(Integer, default=0, nullable=False)
    late_occurrences_absent_count = Column(Integer, default=0, nullable=False)

    # Weekly Off
    weekly_off_1 = Column(Integer, default=6, nullable=False)  # 0=Mon, 6=Sun
    weekly_off_2 = Column(Integer, nullable=True)
    weekly_off_2_week = Column(String(50), default=WeeklyOffWeek.EVERY, nullable=False)

    # Punch Rules
    consider_first_last_punch = Column(Boolean, default=True, nullable=False)
    neglect_last_in_on_missed_out = Column(Boolean, default=False, nullable=False)
    consider_early_coming = Column(Boolean, default=True, nullable=False)
    consider_late_going = Column(Boolean, default=True, nullable=False)
    deduct_break_hours = Column(Boolean, default=True, nullable=False)

    # Holiday Rules
    mark_wo_holiday_absent_if_prefix_absent = Column(Boolean, default=False, nullable=False)

    __table_args__ = (
        UniqueConstraint("tenant_id", "code", name="uq_employee_categories_tenant_code"),
    )
