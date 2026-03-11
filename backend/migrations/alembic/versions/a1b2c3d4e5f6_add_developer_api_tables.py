"""add_developer_api_tables

Revision ID: a1b2c3d4e5f6
Revises: 73c615fe37d8
Create Date: 2026-03-11 20:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = '73c615fe37d8'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table('developer_keys',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('name', sa.String(length=200), nullable=False),
        sa.Column('email', sa.String(length=320), nullable=False),
        sa.Column('api_key_hash', sa.String(length=64), nullable=False),
        sa.Column('key_prefix', sa.String(length=8), nullable=False),
        sa.Column('scopes', JSONB(), nullable=False),
        sa.Column('enabled', sa.Boolean(), nullable=False),
        sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('api_key_hash'),
    )

    op.create_table('developer_submissions',
        sa.Column('id', sa.UUID(), nullable=False),
        sa.Column('developer_key_id', sa.UUID(), nullable=False),
        sa.Column('country_code', sa.String(length=2), nullable=False),
        sa.Column('status', sa.String(length=20), nullable=False),
        sa.Column('camera_count', sa.Integer(), nullable=False),
        sa.Column('cameras_json', JSONB(), nullable=False),
        sa.Column('submitted_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('reviewed_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('review_note', sa.Text(), nullable=True),
        sa.Column('reviewer', sa.String(length=100), nullable=True),
        sa.ForeignKeyConstraint(['developer_key_id'], ['developer_keys.id']),
        sa.ForeignKeyConstraint(['country_code'], ['countries.code']),
        sa.PrimaryKeyConstraint('id'),
    )
    op.create_index(op.f('ix_developer_submissions_developer_key_id'), 'developer_submissions', ['developer_key_id'], unique=False)
    op.create_index(op.f('ix_developer_submissions_country_code'), 'developer_submissions', ['country_code'], unique=False)
    op.create_index('ix_developer_submissions_key_status', 'developer_submissions', ['developer_key_id', 'status'], unique=False)


def downgrade() -> None:
    op.drop_index('ix_developer_submissions_key_status', table_name='developer_submissions')
    op.drop_index(op.f('ix_developer_submissions_country_code'), table_name='developer_submissions')
    op.drop_index(op.f('ix_developer_submissions_developer_key_id'), table_name='developer_submissions')
    op.drop_table('developer_submissions')
    op.drop_table('developer_keys')
