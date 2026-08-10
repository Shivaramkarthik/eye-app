"""Initial Schema Migration for Specz.co V2

Revision ID: 001_initial_schema
Revises: 
Create Date: 2026-08-10 21:00:00

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = '001_initial_schema'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    # users
    op.create_table(
        'users',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('email', sa.String(), nullable=False),
        sa.Column('phone', sa.String(), nullable=True),
        sa.Column('password_hash', sa.String(), nullable=True),
        sa.Column('first_name', sa.String(), nullable=True),
        sa.Column('last_name', sa.String(), nullable=True),
        sa.Column('display_name', sa.String(), nullable=True),
        sa.Column('plan', sa.String(), nullable=False, server_default='free'),
        sa.Column('account_status', sa.String(), nullable=False, server_default='ACTIVE'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_users_id', 'users', ['id'], unique=False)
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # profiles
    op.create_table(
        'profiles',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('dob', sa.String(), nullable=False),
        sa.Column('gender', sa.String(), nullable=False),
        sa.Column('relationship', sa.String(), nullable=False, server_default='Self'),
        sa.Column('profile_type', sa.String(), nullable=False, server_default='Adult'),
        sa.Column('prescription_type', sa.String(), nullable=True),
        sa.Column('blurred_vision_type', sa.String(), nullable=True),
        sa.Column('archived', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('deleted_at', sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_profiles_id', 'profiles', ['id'], unique=False)
    op.create_index('ix_profiles_user_id', 'profiles', ['user_id'], unique=False)

    # profile_symptoms
    op.create_table(
        'profile_symptoms',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('profile_id', sa.String(), nullable=False),
        sa.Column('symptom', sa.String(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['profile_id'], ['profiles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # prescriptions
    op.create_table(
        'prescriptions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('profile_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('prescription_date', sa.String(), nullable=False),
        sa.Column('doctor_name', sa.String(), nullable=True),
        sa.Column('clinic_name', sa.String(), nullable=True),
        sa.Column('add_power', sa.Float(), nullable=True),
        sa.Column('pd', sa.Float(), nullable=True),
        sa.Column('notes', sa.String(), nullable=True),
        sa.Column('image_url', sa.String(), nullable=True),
        sa.Column('source', sa.String(), nullable=False, server_default='MANUAL'),
        sa.Column('ocr_confidence', sa.Float(), nullable=False, server_default='1.0'),
        sa.Column('confirmed_by_user', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('is_current', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['profile_id'], ['profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # prescription_eye_values
    op.create_table(
        'prescription_eye_values',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('prescription_id', sa.String(), nullable=False),
        sa.Column('eye', sa.String(), nullable=False),
        sa.Column('sph', sa.Float(), nullable=True),
        sa.Column('cyl', sa.Float(), nullable=True),
        sa.Column('axis', sa.Integer(), nullable=True),
        sa.Column('sph_status', sa.String(), nullable=False, server_default='CONFIRMED'),
        sa.Column('cyl_status', sa.String(), nullable=False, server_default='CONFIRMED'),
        sa.Column('axis_status', sa.String(), nullable=False, server_default='CONFIRMED'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['prescription_id'], ['prescriptions.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # medications
    op.create_table(
        'medications',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('profile_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('type', sa.String(), nullable=False, server_default='Drop'),
        sa.Column('dosage', sa.String(), nullable=False),
        sa.Column('start_date', sa.String(), nullable=False),
        sa.Column('end_date', sa.String(), nullable=True),
        sa.Column('active', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['profile_id'], ['profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # medication_schedules
    op.create_table(
        'medication_schedules',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('medication_id', sa.String(), nullable=False),
        sa.Column('time', sa.String(), nullable=False),
        sa.Column('tone', sa.String(), nullable=False, server_default='Soft Chime'),
        sa.Column('vibration_enabled', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('enabled', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['medication_id'], ['medications.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # medication_logs
    op.create_table(
        'medication_logs',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('medication_id', sa.String(), nullable=False),
        sa.Column('schedule_id', sa.String(), nullable=False),
        sa.Column('scheduled_at', sa.String(), nullable=False),
        sa.Column('actual_at', sa.String(), nullable=True),
        sa.Column('status', sa.String(), nullable=False, server_default='TAKEN'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['medication_id'], ['medications.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # eye_care_scores
    op.create_table(
        'eye_care_scores',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('profile_id', sa.String(), nullable=False),
        sa.Column('score', sa.Integer(), nullable=False),
        sa.Column('prescription_completeness_score', sa.Integer(), nullable=False, server_default='20'),
        sa.Column('prescription_stability_score', sa.Integer(), nullable=False, server_default='15'),
        sa.Column('medication_adherence_score', sa.Integer(), nullable=False, server_default='20'),
        sa.Column('followup_recency_score', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('record_completeness_score', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('care_routine_consistency_score', sa.Integer(), nullable=False, server_default='10'),
        sa.Column('history_quality_score', sa.Integer(), nullable=False, server_default='15'),
        sa.Column('explanation', sa.Text(), nullable=False),
        sa.Column('algorithm_version', sa.Integer(), nullable=False, server_default='2'),
        sa.Column('calculated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['profile_id'], ['profiles.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # reports
    op.create_table(
        'reports',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('profile_id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('report_date', sa.String(), nullable=False),
        sa.Column('title', sa.String(), nullable=False),
        sa.Column('clinic_name', sa.String(), nullable=True),
        sa.Column('file_path', sa.String(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('follow_up_date', sa.String(), nullable=True),
        sa.Column('score_snapshot', sa.Integer(), nullable=False, server_default='85'),
        sa.Column('score_explanation_snapshot', sa.Text(), nullable=True),
        sa.Column('ai_summary_snapshot', sa.Text(), nullable=True),
        sa.Column('doctor_questions_snapshot', sa.Text(), nullable=True),
        sa.Column('report_version', sa.Integer(), nullable=False, server_default='2'),
        sa.Column('language', sa.String(), nullable=False, server_default='en'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['profile_id'], ['profiles.id'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # subscriptions
    op.create_table(
        'subscriptions',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('provider', sa.String(), nullable=False, server_default='razorpay'),
        sa.Column('provider_customer_id', sa.String(), nullable=True),
        sa.Column('provider_order_id', sa.String(), nullable=True),
        sa.Column('provider_payment_id', sa.String(), nullable=True),
        sa.Column('provider_subscription_id', sa.String(), nullable=True),
        sa.Column('plan', sa.String(), nullable=False, server_default='free'),
        sa.Column('status', sa.String(), nullable=False, server_default='ACTIVE'),
        sa.Column('started_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('expires_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id')
    )

    # sync_records
    op.create_table(
        'sync_records',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=False),
        sa.Column('device_id', sa.String(), nullable=False),
        sa.Column('operation_id', sa.String(), nullable=False),
        sa.Column('entity_type', sa.String(), nullable=False),
        sa.Column('entity_id', sa.String(), nullable=False),
        sa.Column('operation', sa.String(), nullable=False),
        sa.Column('payload', sa.Text(), nullable=False),
        sa.Column('version', sa.Integer(), nullable=False, server_default='1'),
        sa.Column('status', sa.String(), nullable=False, server_default='PROCESSED'),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(['user_id'], ['users.id'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('operation_id')
    )

    # analytics_events
    op.create_table(
        'analytics_events',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('event_type', sa.String(), nullable=False),
        sa.Column('device_id', sa.String(), nullable=True),
        sa.Column('properties', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )

    # audit_logs
    op.create_table(
        'audit_logs',
        sa.Column('id', sa.String(), nullable=False),
        sa.Column('user_id', sa.String(), nullable=True),
        sa.Column('action', sa.String(), nullable=False),
        sa.Column('ip_address', sa.String(), nullable=True),
        sa.Column('user_agent', sa.String(), nullable=True),
        sa.Column('details', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint('id')
    )

def downgrade() -> None:
    op.drop_table('audit_logs')
    op.drop_table('analytics_events')
    op.drop_table('sync_records')
    op.drop_table('subscriptions')
    op.drop_table('reports')
    op.drop_table('eye_care_scores')
    op.drop_table('medication_logs')
    op.drop_table('medication_schedules')
    op.drop_table('medications')
    op.drop_table('prescription_eye_values')
    op.drop_table('prescriptions')
    op.drop_table('profile_symptoms')
    op.drop_table('profiles')
    op.drop_table('users')
