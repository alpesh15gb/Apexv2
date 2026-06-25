import enum
from sqlalchemy import Column, String, Integer, Float, Boolean, DateTime, Date, Text, ForeignKey, UniqueConstraint, Index
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class AttendanceStatus(str, enum.Enum):
    PRESENT = "present"
    ABSENT = "absent"
    HALF_DAY = "half_day"
    LATE = "late"
    EARLY_OUT = "early_out"
    HOLIDAY = "holiday"
    WEEK_OFF = "week_off"


class PunchType(str, enum.Enum):
    IN = "in"
    OUT = "out"
    BREAK_IN = "break_in"
    BREAK_OUT = "break_out"


class PunchSource(str, enum.Enum):
    BIOMETRIC = "biometric"
    MANUAL = "manual"
    IMPORT = "import"


class Attendance(TenantModel):
    __tablename__ = "attendances"

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
    date = Column(Date, nullable=False)
    punch_in = Column(DateTime(timezone=True), nullable=True)
    punch_out = Column(DateTime(timezone=True), nullable=True)
    total_hours = Column(Float, nullable=True)
    overtime_hours = Column(Float, nullable=True)
    status = Column(
        String(50),
        default=AttendanceStatus.ABSENT,
        nullable=False,
    )
    is_late = Column(Boolean, default=False, nullable=False)
    late_minutes = Column(Integer, default=0, nullable=False)
    is_early_out = Column(Boolean, default=False, nullable=False)
    early_out_minutes = Column(Integer, default=0, nullable=False)
    shift_id = Column(
        UUID(as_uuid=True),
        ForeignKey("shifts.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    remarks = Column(Text, nullable=True)
    is_manual = Column(Boolean, default=False, nullable=False)
    approved_by = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="attendances")
    employee = relationship("Employee", foreign_keys=[employee_id], back_populates="attendances")
    approved_by_employee = relationship("Employee", foreign_keys=[approved_by], back_populates="approved_attendances")
    shift = relationship("Shift", back_populates="attendances")

    __table_args__ = (
        UniqueConstraint("tenant_id", "employee_id", "date", name="uq_attendances_tenant_employee_date"),
    )


class PunchLog(TenantModel):
    __tablename__ = "punch_logs"

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
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    punch_time = Column(DateTime(timezone=True), nullable=False)
    punch_type = Column(String(50), nullable=False)
    source = Column(String(50), nullable=False)
    raw_data = Column(Text, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="punch_logs")
    employee = relationship("Employee", back_populates="punch_logs")
    device = relationship("Device", back_populates="punch_logs")


class AttendanceRawLog(TenantModel):
    """Raw punch data from eSSL before processing.
    Pipeline: eSSL SOAP → attendance_raw_logs → AttendanceProcessor → attendances
    NEVER read directly from eSSL during attendance calculation.
    """

    __tablename__ = "attendance_raw_logs"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    employee_code = Column(String(100), nullable=False)
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    device_serial = Column(String(100), nullable=True)
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="SET NULL"),
        nullable=True,
    )
    punch_time = Column(DateTime(timezone=True), nullable=False)
    punch_type = Column(String(50), nullable=True)
    raw_data = Column(JSONB, nullable=True)
    processed = Column(Boolean, default=False, nullable=False, index=True)
    processed_at = Column(DateTime(timezone=True), nullable=True)
    processing_error = Column(Text, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="attendance_raw_logs")
    essl_server = relationship("EsslServer")
    employee = relationship("Employee")
    device = relationship("Device")

    __table_args__ = (
        UniqueConstraint(
            "essl_server_id",
            "employee_code",
            "punch_time",
            "punch_type",
            name="uq_raw_logs_server_code_time_type",
        ),
        Index("ix_raw_logs_unprocessed", "tenant_id", "processed"),
        Index("ix_raw_logs_dedup_check", "tenant_id", "employee_code", "punch_time"),
    )
