"""Shift Group model — bundle shifts into assignable groups."""

from sqlalchemy import Column, String, Boolean, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class ShiftGroup(TenantModel):
    __tablename__ = "shift_groups"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    description = Column(String(512), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)

    members = relationship("ShiftGroupMember", back_populates="group", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("tenant_id", "name", name="uq_shift_groups_tenant_name"),)


class ShiftGroupMember(TenantModel):
    __tablename__ = "shift_group_members"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    group_id = Column(UUID(as_uuid=True), ForeignKey("shift_groups.id", ondelete="CASCADE"), nullable=False, index=True)
    shift_id = Column(UUID(as_uuid=True), ForeignKey("shifts.id", ondelete="CASCADE"), nullable=False, index=True)

    group = relationship("ShiftGroup", back_populates="members")
    shift = relationship("Shift")

    __table_args__ = (UniqueConstraint("group_id", "shift_id", name="uq_shift_group_members_group_shift"),)
