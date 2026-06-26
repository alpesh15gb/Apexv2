"""add essl location

Revision ID: b1a2c3d4e5f6
Revises: a6dacfc268bc
Create Date: 2026-06-26 02:00:00.000000
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = 'b1a2c3d4e5f6'
down_revision: Union[str, None] = 'a6dacfc268bc'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('essl_servers', sa.Column('location', sa.String(255), nullable=False, server_default=''))


def downgrade() -> None:
    op.drop_column('essl_servers', 'location')
