from sqlalchemy import Column, String, Integer, Boolean, Time, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class Shift(TenantModel):
    __tablename__ = "shifts"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    grace_period_minutes = Column(Integer, default=0, nullable=False)
    late_rule_minutes = Column(Integer, default=0, nullable=False)
    early_rule_minutes = Column(Integer, default=0, nullable=False)
    overtime_threshold_minutes = Column(Integer, default=0, nullable=False)
    is_night_shift = Column(Boolean, default=False, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="shifts")
    employees = relationship("Employee", back_populates="shift")
    shift_schedules = relationship("ShiftSchedule", back_populates="shift", cascade="all, delete-orphan")
    attendances = relationship("Attendance", back_populates="shift")


class ShiftSchedule(TenantModel):
    __tablename__ = "shift_schedules"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    shift_id = Column(
        UUID(as_uuid=True),
        ForeignKey("shifts.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    effective_from = Column(Date, nullable=False)
    effective_to = Column(Date, nullable=True)
    day_of_week = Column(Integer, nullable=True)  # 0-6, e.g. 0=Monday, 6=Sunday

    # Relationships
    tenant = relationship("Tenant", back_populates="shift_schedules")
    employee = relationship("Employee", back_populates="shift_schedules")
    shift = relationship("Shift", back_populates="shift_schedules")
