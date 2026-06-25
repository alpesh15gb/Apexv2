import enum
from sqlalchemy import Column, String, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class CommandType(str, enum.Enum):
    REBOOT = "reboot"
    CLEAR_LOGS = "clear_logs"
    ENROLL_FP = "enroll_fp"
    ENROLL_FACE = "enroll_face"
    UNLOCK_DOOR = "unlock_door"
    BLOCK_USER = "block_user"
    UNBLOCK_USER = "unblock_user"
    RESET_OP_STAMP = "reset_op_stamp"
    RESET_TRANSACTION_STAMP = "reset_transaction_stamp"


class CommandStatus(str, enum.Enum):
    PENDING = "pending"
    SENT = "sent"
    SUCCESS = "success"
    FAILED = "failed"
    TIMEOUT = "timeout"


class DeviceCommand(TenantModel):
    __tablename__ = "device_commands"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    device_id = Column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    command_type = Column(
        String(100),
        nullable=False,
    )
    parameters = Column(JSONB, nullable=True)
    status = Column(
        String(50),
        default=CommandStatus.PENDING,
        nullable=False,
    )
    requested_by = Column(
        UUID(as_uuid=True),
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    requested_at = Column(DateTime(timezone=True), nullable=False)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    completed_at = Column(DateTime(timezone=True), nullable=True)
    response_data = Column(JSONB, nullable=True)
    error_message = Column(Text, nullable=True)

    # Relationships
    tenant = relationship("Tenant", back_populates="device_commands")
    device = relationship("Device", back_populates="commands")
    requested_by_user = relationship("User", back_populates="device_commands")
