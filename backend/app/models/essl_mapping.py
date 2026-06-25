"""eSSL entity mapping tables — bridge between eSSL codes and local UUIDs."""

from sqlalchemy import Column, String, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class EsslEmployeeMapping(TenantModel):
    __tablename__ = "essl_employee_mapping"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    employee_code = Column(String(100), nullable=False)
    employee_id = Column(
        UUID(as_uuid=True),
        ForeignKey("employees.id", ondelete="CASCADE"),
        nullable=False,
    )
    synced_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    essl_server = relationship("EsslServer", back_populates="employee_mappings")
    employee = relationship("Employee")

    __table_args__ = (
        UniqueConstraint(
            "essl_server_id", "employee_code", name="uq_essl_emp_mapping_server_code"
        ),
        UniqueConstraint(
            "essl_server_id", "employee_id", name="uq_essl_emp_mapping_server_emp"
        ),
    )


class EsslDeviceMapping(TenantModel):
    __tablename__ = "essl_device_mapping"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    essl_server_id = Column(
        UUID(as_uuid=True),
        ForeignKey("essl_servers.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    serial_number = Column(String(100), nullable=False)
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=False,
    )
    synced_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    essl_server = relationship("EsslServer", back_populates="device_mappings")
    device = relationship("Device")

    __table_args__ = (
        UniqueConstraint(
            "essl_server_id", "serial_number", name="uq_essl_dev_mapping_server_serial"
        ),
        UniqueConstraint(
            "essl_server_id", "device_id", name="uq_essl_dev_mapping_server_dev"
        ),
    )
