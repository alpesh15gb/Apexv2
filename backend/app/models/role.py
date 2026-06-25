from sqlalchemy import Column, String, Text, Boolean, ForeignKey, Table, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel, Base
from app.models.user import user_roles, UserRole

# Association table for Role and Permission
role_permissions = Table(
    "role_permissions",
    Base.metadata,
    Column(
        "role_id",
        UUID(as_uuid=True),
        ForeignKey("roles.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "permission_id",
        UUID(as_uuid=True),
        ForeignKey("permissions.id", ondelete="CASCADE"),
        primary_key=True,
    ),
    Column(
        "tenant_id",
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        primary_key=True,
        index=True,
    ),
)


class RolePermission(Base):
    __table__ = role_permissions


class Role(TenantModel):
    __tablename__ = "roles"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    description = Column(Text, nullable=True)
    is_system_role = Column(Boolean, default=False, nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="roles")
    users = relationship("User", secondary=user_roles, back_populates="roles")
    permissions = relationship(
        "Permission",
        secondary=role_permissions,
        back_populates="roles",
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "name", name="uq_roles_tenant_name"),
    )


class Permission(TenantModel):
    __tablename__ = "permissions"

    tenant_id = Column(
        UUID(as_uuid=True),
        ForeignKey("tenants.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )
    name = Column(String(255), nullable=False)
    codename = Column(String(255), nullable=False)
    module = Column(String(255), nullable=False)

    # Relationships
    tenant = relationship("Tenant", back_populates="permissions")
    roles = relationship(
        "Role",
        secondary=role_permissions,
        back_populates="permissions",
    )

    __table_args__ = (
        UniqueConstraint("tenant_id", "codename", name="uq_permissions_tenant_codename"),
    )
