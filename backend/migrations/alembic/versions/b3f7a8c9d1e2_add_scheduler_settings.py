"""add_scheduler_settings

Revision ID: b3f7a8c9d1e2
Revises: a1b2c3d4e5f6
Create Date: 2026-03-12 18:00:00.000000

"""
from typing import Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'b3f7a8c9d1e2'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('scheduler_settings',
        sa.Column('id', sa.UUID(), nullable=False, default=uuid.uuid4),
        sa.Column('enabled', sa.Boolean(), nullable=False),
        sa.Column('interval_hours', sa.Integer(), nullable=False),
        sa.Column('last_run_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('next_run_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )
    # Seed default row
    op.execute(
        f"INSERT INTO scheduler_settings (id, enabled, interval_hours) "
        f"VALUES ('{uuid.uuid4()}', true, 6)"
    )


def downgrade() -> None:
    op.drop_table('scheduler_settings')
