"""add super admin tables

Revision ID: f7a8b9c0d1e2
Revises: 34d53d38e2ec
Create Date: 2026-06-27 00:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'f7a8b9c0d1e2'
down_revision: Union[str, None] = '34d53d38e2ec'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Subscription Plans (global, no tenant_id)
    op.create_table('subscription_plans',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(100), nullable=False, unique=True),
        sa.Column('description', sa.Text, nullable=True),
        sa.Column('price_monthly', sa.Float, nullable=False, server_default='0'),
        sa.Column('price_quarterly', sa.Float, nullable=False, server_default='0'),
        sa.Column('price_half_yearly', sa.Float, nullable=False, server_default='0'),
        sa.Column('price_annual', sa.Float, nullable=False, server_default='0'),
        sa.Column('price_lifetime', sa.Float, nullable=False, server_default='0'),
        sa.Column('max_employees', sa.Integer, nullable=False, server_default='50'),
        sa.Column('max_branches', sa.Integer, nullable=False, server_default='5'),
        sa.Column('max_departments', sa.Integer, nullable=False, server_default='10'),
        sa.Column('max_devices', sa.Integer, nullable=False, server_default='5'),
        sa.Column('max_admin_users', sa.Integer, nullable=False, server_default='2'),
        sa.Column('max_hr_users', sa.Integer, nullable=False, server_default='5'),
        sa.Column('max_storage_mb', sa.Integer, nullable=False, server_default='1024'),
        sa.Column('max_api_calls', sa.Integer, nullable=False, server_default='10000'),
        sa.Column('max_mobile_logins', sa.Integer, nullable=False, server_default='50'),
        sa.Column('trial_days', sa.Integer, nullable=False, server_default='14'),
        sa.Column('features', postgresql.JSON, nullable=False, server_default='[]'),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('sort_order', sa.Integer, nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Tenant Subscriptions
    op.create_table('tenant_subscriptions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('plan_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subscription_plans.id'), nullable=False),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('end_date', sa.Date, nullable=True),
        sa.Column('renewal_date', sa.Date, nullable=True),
        sa.Column('status', sa.String(50), nullable=False, server_default='trial'),
        sa.Column('billing_cycle', sa.String(50), nullable=False, server_default='monthly'),
        sa.Column('payment_status', sa.String(50), nullable=False, server_default='pending'),
        sa.Column('auto_renewal', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('last_payment_amount', sa.Float, nullable=True),
        sa.Column('last_payment_date', sa.Date, nullable=True),
        sa.Column('next_invoice_date', sa.Date, nullable=True),
        sa.Column('trial_ends_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('cancelled_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('cancel_reason', sa.Text, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Resource Limits
    op.create_table('resource_limits',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('resource_key', sa.String(100), nullable=False),
        sa.Column('max_value', sa.Integer, nullable=False, server_default='0'),
        sa.Column('current_value', sa.Integer, nullable=False, server_default='0'),
        sa.Column('is_unlimited', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'resource_key', name='uq_resource_limits_tenant_key'),
    )

    # Feature Flags (global)
    op.create_table('feature_flags',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(100), nullable=False, unique=True),
        sa.Column('description', sa.Text, nullable=True),
        sa.Column('module', sa.String(100), nullable=False, server_default='general'),
        sa.Column('category', sa.String(100), nullable=False, server_default='core'),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('sort_order', sa.Integer, nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Tenant Features
    op.create_table('tenant_features',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('feature_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('feature_flags.id', ondelete='CASCADE'), nullable=False),
        sa.Column('is_enabled', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('enabled_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('enabled_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('config', sa.Text, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint('tenant_id', 'feature_id', name='uq_tenant_features_tenant_feature'),
    )

    # Approval Workflows
    op.create_table('approval_workflows',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('entity_type', sa.String(100), nullable=False),
        sa.Column('description', sa.Text, nullable=True),
        sa.Column('is_active', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('auto_approve_hours', sa.Integer, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Approval Steps
    op.create_table('approval_steps',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('workflow_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('approval_workflows.id', ondelete='CASCADE'), nullable=False),
        sa.Column('step_order', sa.Integer, nullable=False),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('approver_type', sa.String(50), nullable=False, server_default='role'),
        sa.Column('approver_role_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('roles.id', ondelete='SET NULL'), nullable=True),
        sa.Column('approver_user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('is_parallel', sa.Boolean, nullable=False, server_default='false'),
        sa.Column('auto_approve_hours', sa.Integer, nullable=True),
        sa.Column('is_required', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Approval Requests
    op.create_table('approval_requests',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('workflow_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('approval_workflows.id', ondelete='SET NULL'), nullable=True),
        sa.Column('entity_type', sa.String(100), nullable=False),
        sa.Column('entity_id', postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column('requester_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('current_step', sa.Integer, nullable=False, server_default='1'),
        sa.Column('status', sa.String(50), nullable=False, server_default='pending'),
        sa.Column('remarks', sa.Text, nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Approval History
    op.create_table('approval_history',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('request_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('approval_requests.id', ondelete='CASCADE'), nullable=False),
        sa.Column('step_order', sa.Integer, nullable=False),
        sa.Column('approver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('action', sa.String(50), nullable=False),
        sa.Column('remarks', sa.Text, nullable=True),
        sa.Column('acted_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Login History
    op.create_table('login_history',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('email', sa.String(255), nullable=False),
        sa.Column('ip_address', sa.String(50), nullable=True),
        sa.Column('user_agent', sa.Text, nullable=True),
        sa.Column('device_type', sa.String(50), nullable=True),
        sa.Column('location', sa.String(255), nullable=True),
        sa.Column('login_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column('logout_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('is_successful', sa.Boolean, nullable=False, server_default='true'),
        sa.Column('failure_reason', sa.Text, nullable=True),
    )

    # Super Admin Logs (global, no tenant_id)
    op.create_table('super_admin_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('admin_user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('action', sa.String(255), nullable=False),
        sa.Column('target_type', sa.String(100), nullable=False),
        sa.Column('target_id', postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column('old_value', sa.Text, nullable=True),
        sa.Column('new_value', sa.Text, nullable=True),
        sa.Column('ip_address', sa.String(50), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    # Add must_change_password to users
    op.add_column('users', sa.Column('must_change_password', sa.Boolean(), nullable=False, server_default='false'))
    op.add_column('users', sa.Column('last_password_change', sa.DateTime(timezone=True), nullable=True))
    op.add_column('users', sa.Column('failed_login_attempts', sa.Integer(), nullable=False, server_default='0'))
    op.add_column('users', sa.Column('locked_until', sa.DateTime(timezone=True), nullable=True))

    # Add subscription fields to tenants
    op.add_column('tenants', sa.Column('subscription_status', sa.String(50), nullable=False, server_default='trial'))
    op.add_column('tenants', sa.Column('trial_ends_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('tenants', sa.Column('company_code', sa.String(50), nullable=True))
    op.add_column('tenants', sa.Column('gst_number', sa.String(20), nullable=True))
    op.add_column('tenants', sa.Column('pan_number', sa.String(20), nullable=True))
    op.add_column('tenants', sa.Column('contact_person', sa.String(255), nullable=True))
    op.add_column('tenants', sa.Column('currency', sa.String(10), nullable=False, server_default='INR'))
    op.add_column('tenants', sa.Column('financial_year_start', sa.String(10), nullable=False, server_default='04-01'))

    # Create indexes
    op.create_index('ix_approval_requests_entity', 'approval_requests', ['entity_type', 'entity_id'])
    op.create_index('ix_approval_requests_status', 'approval_requests', ['status'])
    op.create_index('ix_login_history_user', 'login_history', ['user_id'])
    op.create_index('ix_login_history_email', 'login_history', ['email'])


def downgrade() -> None:
    op.drop_table('super_admin_logs')
    op.drop_table('login_history')
    op.drop_table('approval_history')
    op.drop_table('approval_requests')
    op.drop_table('approval_steps')
    op.drop_table('approval_workflows')
    op.drop_table('tenant_features')
    op.drop_table('feature_flags')
    op.drop_table('resource_limits')
    op.drop_table('tenant_subscriptions')
    op.drop_table('subscription_plans')
    op.drop_column('users', 'must_change_password')
    op.drop_column('users', 'last_password_change')
    op.drop_column('users', 'failed_login_attempts')
    op.drop_column('users', 'locked_until')
    op.drop_column('tenants', 'subscription_status')
    op.drop_column('tenants', 'trial_ends_at')
    op.drop_column('tenants', 'company_code')
    op.drop_column('tenants', 'gst_number')
    op.drop_column('tenants', 'pan_number')
    op.drop_column('tenants', 'contact_person')
    op.drop_column('tenants', 'currency')
    op.drop_column('tenants', 'financial_year_start')
