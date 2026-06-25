import enum
from sqlalchemy import Column, String, Boolean, Date, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class EmployeeStatus(str, enum.Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    TERMINATED = "terminated"
    ON_NOTICE = "on_notice"


class Department(TenantModel):
    __tablename__ = "departments"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="departments")
    employees = relationship("Employee", back_populates="department")

    __table_args__ = (
        UniqueConstraint("tenant_id", "code", name="uq_departments_tenant_code"),
    )


class Designation(TenantModel):
    __tablename__ = "designations"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="designations")
    employees = relationship("Employee", back_populates="designation")

    __table_args__ = (
        UniqueConstraint("tenant_id", "code", name="uq_designations_tenant_code"),
    )


class Branch(TenantModel):
    __tablename__ = "branches"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    code = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="branches")
    employees = relationship("Employee", back_populates="branch")
    devices = relationship("Device", back_populates="branch")
    access_zones = relationship("AccessZone", back_populates="branch")

    __table_args__ = (
        UniqueConstraint("tenant_id", "code", name="uq_branches_tenant_code"),
    )


class Employee(TenantModel):
    __tablename__ = "employees"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_code = Column(String(100), nullable=False)
    first_name = Column(String(255), nullable=False)
    last_name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    photo_url = Column(String(512), nullable=True)

    department_id = Column(
        UUID(as_uuid=True),
        ForeignKey("departments.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    designation_id = Column(
        UUID(as_uuid=True),
        ForeignKey("designations.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    branch_id = Column(
        UUID(as_uuid=True),
        ForeignKey("branches.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    shift_id = Column(
        UUID(as_uuid=True),
        ForeignKey("shifts.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )

    joining_date = Column(Date, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    gender = Column(String(50), nullable=True)
    address = Column(String(512), nullable=True)
    city = Column(String(100), nullable=True)
    state = Column(String(100), nullable=True)
    pincode = Column(String(20), nullable=True)

    emergency_contact_name = Column(String(255), nullable=True)
    emergency_contact_phone = Column(String(50), nullable=True)
    blood_group = Column(String(20), nullable=True)
    status = Column(
        String(50),
        default=EmployeeStatus.ACTIVE,
        nullable=False,
    )
    device_user_id = Column(String(100), nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="employees")
    department = relationship("Department", back_populates="employees")
    designation = relationship("Designation", back_populates="employees")
    branch = relationship("Branch", back_populates="employees")
    shift = relationship("Shift", back_populates="employees")

    attendances = relationship("Attendance", foreign_keys="[Attendance.employee_id]", back_populates="employee", cascade="all, delete-orphan")
    approved_attendances = relationship("Attendance", foreign_keys="[Attendance.approved_by]", back_populates="approved_by_employee")

    punch_logs = relationship("PunchLog", back_populates="employee", cascade="all, delete-orphan")
    shift_schedules = relationship("ShiftSchedule", back_populates="employee", cascade="all, delete-orphan")
    leave_balances = relationship("LeaveBalance", back_populates="employee", cascade="all, delete-orphan")

    leave_requests = relationship("LeaveRequest", foreign_keys="[LeaveRequest.employee_id]", back_populates="employee", cascade="all, delete-orphan")
    approved_leave_requests = relationship("LeaveRequest", foreign_keys="[LeaveRequest.approved_by]", back_populates="approved_by_employee")

    visitor_passes = relationship("VisitorPass", back_populates="host_employee", cascade="all, delete-orphan")
    user_access_levels = relationship("UserAccessLevel", foreign_keys="[UserAccessLevel.employee_id]", back_populates="employee", cascade="all, delete-orphan")
    granted_access_levels = relationship("UserAccessLevel", foreign_keys="[UserAccessLevel.granted_by]", back_populates="granted_by_employee")
    access_logs = relationship("AccessLog", back_populates="employee", cascade="all, delete-orphan")

    __table_args__ = (
        UniqueConstraint("tenant_id", "employee_code", name="uq_employees_tenant_employee_code"),
        UniqueConstraint("tenant_id", "email", name="uq_employees_tenant_email"),
        UniqueConstraint("tenant_id", "device_user_id", name="uq_employees_tenant_device_user_id"),
    )
