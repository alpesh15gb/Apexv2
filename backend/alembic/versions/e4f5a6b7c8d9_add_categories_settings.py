"""add categories and tenant_settings

Revision ID: e4f5a6b7c8d9
Revises: d3e4f5a6b7c8
Create Date: 2026-06-26 05:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'e4f5a6b7c8d9'
down_revision: Union[str, None] = 'd3e4f5a6b7c8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        'employee_categories',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(100), nullable=False),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('ot_formula', sa.String(50), nullable=False, server_default='out_punch'),
        sa.Column('min_ot_minutes', sa.Integer, nullable=False, server_default='0'),
        sa.Column('max_ot_minutes', sa.Integer, nullable=False, server_default='0'),
        sa.Column('grace_minutes', sa.Integer, nullable=False, server_default='0'),
        sa.Column('half_day_threshold_minutes', sa.Integer, nullable=False, server_default='240'),
        sa.Column('absent_threshold_minutes', sa.Integer, nullable=False, server_default='0'),
        sa.Column('late_absent_minutes', sa.Integer, nullable=False, server_default='0'),
        sa.Column('late_occurrences_absent_count', sa.Integer, nullable=False, server_default='0'),
        sa.Column('weekly_off_1', sa.Integer, nullable=False, server_default='6'),
        sa.Column('weekly_off_2', sa.Integer, nullable=True),
        sa.Column('weekly_off_2_week', sa.String(50), nullable=False, server_default='every'),
        sa.Column('consider_first_last_punch', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('neglect_last_in_on_missed_out', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('consider_early_coming', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('consider_late_going', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('deduct_break_hours', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('mark_wo_holiday_absent_if_prefix_absent', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'code', name='uq_employee_categories_tenant_code'),
    )

    op.create_table(
        'tenant_settings',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, unique=True, index=True),
        sa.Column('attendance_year_start_month', sa.Integer, nullable=False, server_default='1'),
        sa.Column('attendance_year_start_day', sa.Integer, nullable=False, server_default='1'),
        sa.Column('min_punch_difference_minutes', sa.Integer, nullable=False, server_default='1'),
        sa.Column('punch_begin_before_minutes', sa.Integer, nullable=False, server_default='60'),
        sa.Column('auto_shift_if_no_schedule', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('fixed_shift_mode', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )

    op.add_column('employees', sa.Column('category_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employee_categories.id', ondelete='SET NULL'), nullable=True, index=True))


def downgrade() -> None:
    op.drop_column('employees', 'category_id')
    op.drop_table('tenant_settings')
    op.drop_table('employee_categories')
