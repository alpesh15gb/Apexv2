"""add payroll tables

Revision ID: b7c8d9e0f1a2
Revises: a6b7c8d9e0f1
Create Date: 2026-06-26 08:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'b7c8d9e0f1a2'
down_revision: Union[str, None] = 'a6b7c8d9e0f1'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('salary_structures',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('basic', sa.Float, nullable=False, server_default='0'),
        sa.Column('hra', sa.Float, nullable=False, server_default='0'),
        sa.Column('da', sa.Float, nullable=False, server_default='0'),
        sa.Column('conveyance', sa.Float, nullable=False, server_default='0'),
        sa.Column('medical', sa.Float, nullable=False, server_default='0'),
        sa.Column('special', sa.Float, nullable=False, server_default='0'),
        sa.Column('pf_employee', sa.Float, nullable=False, server_default='0'),
        sa.Column('pf_employer', sa.Float, nullable=False, server_default='0'),
        sa.Column('esi_employee', sa.Float, nullable=False, server_default='0'),
        sa.Column('esi_employer', sa.Float, nullable=False, server_default='0'),
        sa.Column('professional_tax', sa.Float, nullable=False, server_default='0'),
        sa.Column('income_tax', sa.Float, nullable=False, server_default='0'),
        sa.Column('effective_from', sa.Date, nullable=False),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('employee_id', 'effective_from', name='uq_salary_employee_effective'),
    )

    op.create_table('pay_slips',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('month', sa.Integer, nullable=False),
        sa.Column('year', sa.Integer, nullable=False),
        sa.Column('basic', sa.Float, nullable=False, server_default='0'),
        sa.Column('hra', sa.Float, nullable=False, server_default='0'),
        sa.Column('da', sa.Float, nullable=False, server_default='0'),
        sa.Column('conveyance', sa.Float, nullable=False, server_default='0'),
        sa.Column('medical', sa.Float, nullable=False, server_default='0'),
        sa.Column('special', sa.Float, nullable=False, server_default='0'),
        sa.Column('gross_earnings', sa.Float, nullable=False, server_default='0'),
        sa.Column('pf', sa.Float, nullable=False, server_default='0'),
        sa.Column('esi', sa.Float, nullable=False, server_default='0'),
        sa.Column('pt', sa.Float, nullable=False, server_default='0'),
        sa.Column('it', sa.Float, nullable=False, server_default='0'),
        sa.Column('total_deductions', sa.Float, nullable=False, server_default='0'),
        sa.Column('net_pay', sa.Float, nullable=False, server_default='0'),
        sa.Column('working_days', sa.Integer, nullable=False, server_default='0'),
        sa.Column('present_days', sa.Integer, nullable=False, server_default='0'),
        sa.Column('absent_days', sa.Integer, nullable=False, server_default='0'),
        sa.Column('leave_days', sa.Integer, nullable=False, server_default='0'),
        sa.Column('ot_hours', sa.Float, nullable=False, server_default='0'),
        sa.Column('ot_amount', sa.Float, nullable=False, server_default='0'),
        sa.Column('lop_days', sa.Integer, nullable=False, server_default='0'),
        sa.Column('lop_amount', sa.Float, nullable=False, server_default='0'),
        sa.Column('status', sa.String(50), nullable=False, server_default='draft'),
        sa.Column('generated_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'employee_id', 'month', 'year', name='uq_pay_slips_tenant_emp_month_year'),
    )

    op.create_table('loans',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('loan_type', sa.String(100), nullable=False),
        sa.Column('amount', sa.Float, nullable=False),
        sa.Column('emi_amount', sa.Float, nullable=False),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('total_installments', sa.Integer, nullable=False),
        sa.Column('paid_installments', sa.Integer, nullable=False, server_default='0'),
        sa.Column('status', sa.String(50), nullable=False, server_default='active'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table('loans')
    op.drop_table('pay_slips')
    op.drop_table('salary_structures')
