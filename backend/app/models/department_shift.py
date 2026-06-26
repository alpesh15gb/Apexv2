"""Department Shift model — assign default shifts to departments."""

from sqlalchemy import Column, Date, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class DepartmentShift(TenantModel):
    __tablename__ = "department_shifts"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    department_id = Column(UUID(as_uuid=True), ForeignKey("departments.id", ondelete="CASCADE"), nullable=False, index=True)
    shift_id = Column(UUID(as_uuid=True), ForeignKey("shifts.id", ondelete="CASCADE"), nullable=False, index=True)
    effective_from = Column(Date, nullable=False)
    effective_to = Column(Date, nullable=True)

    __table_args__ = (
        UniqueConstraint("tenant_id", "department_id", "shift_id", "effective_from", name="uq_dept_shifts_tenant_dept_shift_from"),
    )
