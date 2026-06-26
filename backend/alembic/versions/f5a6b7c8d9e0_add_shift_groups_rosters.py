"""add shift groups rosters dept shifts

Revision ID: f5a6b7c8d9e0
Revises: e4f5a6b7c8d9
Create Date: 2026-06-26 06:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'f5a6b7c8d9e0'
down_revision: Union[str, None] = 'e4f5a6b7c8d9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('shift_groups',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.String(512), nullable=True),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'name', name='uq_shift_groups_tenant_name'),
    )

    op.create_table('shift_group_members',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('group_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shift_groups.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('shift_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shifts.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('group_id', 'shift_id', name='uq_shift_group_members_group_shift'),
    )

    op.create_table('shift_rosters',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.String(512), nullable=True),
        sa.Column('rotation_pattern', sa.String(50), nullable=False, server_default='weekly'),
        sa.Column('weekly_off_1', sa.Integer, nullable=False, server_default='6'),
        sa.Column('weekly_off_2', sa.Integer, nullable=True),
        sa.Column('weekly_off_2_week', sa.String(50), nullable=False, server_default='every'),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'name', name='uq_shift_rosters_tenant_name'),
    )

    op.create_table('shift_roster_entries',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('roster_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shift_rosters.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('day_number', sa.Integer, nullable=False),
        sa.Column('shift_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shifts.id', ondelete='CASCADE'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('roster_id', 'day_number', name='uq_shift_roster_entries_roster_day'),
    )

    op.create_table('department_shifts',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('department_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('departments.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('shift_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shifts.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('effective_from', sa.Date, nullable=False),
        sa.Column('effective_to', sa.Date, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'department_id', 'shift_id', 'effective_from', name='uq_dept_shifts_tenant_dept_shift_from'),
    )

    op.add_column('employees', sa.Column('shift_group_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shift_groups.id', ondelete='SET NULL'), nullable=True, index=True))
    op.add_column('employees', sa.Column('shift_roster_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('shift_rosters.id', ondelete='SET NULL'), nullable=True, index=True))


def downgrade() -> None:
    op.drop_column('employees', 'shift_roster_id')
    op.drop_column('employees', 'shift_group_id')
    op.drop_table('department_shifts')
    op.drop_table('shift_roster_entries')
    op.drop_table('shift_rosters')
    op.drop_table('shift_group_members')
    op.drop_table('shift_groups')
