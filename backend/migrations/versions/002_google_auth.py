"""Add Google OAuth fields and remove password auth columns

Revision ID: 002_google_auth
Revises: 001_initial_schema
Create Date: 2026-08-14

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = '002_google_auth'
down_revision: Union[str, None] = '001_initial_schema'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add Google identity columns
    op.add_column('users', sa.Column('google_sub', sa.String(), nullable=True))
    op.add_column('users', sa.Column('avatar_url', sa.String(), nullable=True))
    
    # Create unique index on google_sub for fast lookups and uniqueness
    op.create_index('ix_users_google_sub', 'users', ['google_sub'], unique=True)
    
    # Remove password and phone columns (no longer needed for Google-only auth)
    op.drop_column('users', 'password_hash')
    op.drop_column('users', 'phone')


def downgrade() -> None:
    # Re-add removed columns
    op.add_column('users', sa.Column('phone', sa.String(), nullable=True))
    op.add_column('users', sa.Column('password_hash', sa.String(), nullable=True))
    
    # Remove Google columns
    op.drop_index('ix_users_google_sub', table_name='users')
    op.drop_column('users', 'avatar_url')
    op.drop_column('users', 'google_sub')
