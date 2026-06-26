"""add outdoor duty ot register work codes

Revision ID: a6b7c8d9e0f1
Revises: f5a6b7c8d9e0
Create Date: 2026-06-26 07:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'a6b7c8d9e0f1'
down_revision: Union[str, None] = 'f5a6b7c8d9e0'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('outdoor_duties',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('from_time', sa.Time, nullable=True),
        sa.Column('to_time', sa.Time, nullable=True),
        sa.Column('reason', sa.Text, nullable=True),
        sa.Column('location', sa.String(255), nullable=True),
        sa.Column('status', sa.String(50), nullable=False, server_default='pending'),
        sa.Column('approved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='SET NULL'), nullable=True),
        sa.Column('approved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table('ot_register',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('ot_hours', sa.Float, nullable=False),
        sa.Column('ot_type', sa.String(50), nullable=False, server_default='normal'),
        sa.Column('status', sa.String(50), nullable=False, server_default='pending'),
        sa.Column('approved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='SET NULL'), nullable=True),
        sa.Column('remarks', sa.Text, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.create_table('work_codes',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('code', sa.String(50), nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('description', sa.Text, nullable=True),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'code', name='uq_work_codes_tenant_code'),
    )


def downgrade() -> None:
    op.drop_table('work_codes')
    op.drop_table('ot_register')
    op.drop_table('outdoor_duties')
