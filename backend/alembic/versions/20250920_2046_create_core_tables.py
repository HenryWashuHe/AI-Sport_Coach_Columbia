from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = '20250920_2046'
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS timescaledb")

    op.create_table(
        'users',
        sa.Column('id', sa.String(), primary_key=True)
    )

    op.create_table(
        'sessions',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('user_id', sa.String(), sa.ForeignKey('users.id'), nullable=False),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('ended_at', sa.DateTime(timezone=True), nullable=True)
    )

    op.create_table(
        'session_metrics',
        sa.Column('id', sa.String(), primary_key=True),
        sa.Column('session_id', sa.String(), sa.ForeignKey('sessions.id'), nullable=False),
        sa.Column('t', sa.DateTime(timezone=True), nullable=False),
        sa.Column('hr', sa.Float(), nullable=True),
        sa.Column('hrv', sa.Float(), nullable=True),
        sa.Column('rep', sa.Integer(), nullable=True),
        sa.Column('rom', sa.Float(), nullable=True),
        sa.Column('tempo', sa.Float(), nullable=True),
        sa.Column('error_flags', postgresql.JSON(astext_type=sa.Text()), nullable=True)
    )
    op.create_index('ix_session_metrics_t', 'session_metrics', ['t'])

    op.execute("SELECT create_hypertable('session_metrics', 't', if_not_exists => TRUE)")


def downgrade() -> None:
    op.drop_index('ix_session_metrics_t', table_name='session_metrics')
    op.drop_table('session_metrics')
    op.drop_table('sessions')
    op.drop_table('users')
