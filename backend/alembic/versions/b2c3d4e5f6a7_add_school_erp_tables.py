"""add school erp tables

Revision ID: b2c3d4e5f6a7
Revises: a1b2c3d4e5f6
Create Date: 2026-06-28 10:00:00.000000
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = 'b2c3d4e5f6a7'
down_revision: Union[str, None] = 'a1b2c3d4e5f6'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tenant_cols():
    return [
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('tenant_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('tenants.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    ]


def upgrade() -> None:
    tc = _tenant_cols

    # ── Phase 1: No school FK dependencies ──────────────────────────────

    op.create_table('academic_years', *tc(),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('end_date', sa.Date, nullable=False),
        sa.Column('is_current', sa.Boolean, server_default='false'),
        sa.Column('promotion_date', sa.Date),
        sa.Column('status', sa.String(20), server_default='planning'),
    )

    op.create_table('grades', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('code', sa.String(20), nullable=False),
        sa.Column('sort_order', sa.Integer, server_default='0'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('campuses', *tc(),
        sa.Column('branch_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('branches.id')),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(50), nullable=False),
        sa.Column('address', sa.String),
        sa.Column('phone', sa.String(20)),
        sa.Column('email', sa.String(255)),
        sa.Column('latitude', sa.Numeric(10, 8)),
        sa.Column('longitude', sa.Numeric(11, 8)),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('fee_categories', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('code', sa.String(30), nullable=False),
        sa.Column('is_active', sa.Boolean, server_default='true'),
        sa.Column('sort_order', sa.Integer, server_default='0'),
    )

    op.create_table('exam_types', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('code', sa.String(30), nullable=False),
        sa.Column('weightage', sa.Numeric(5, 2), server_default='0'),
        sa.Column('exam_category', sa.String(30), server_default='internal'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('grading_scales', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('scale_type', sa.String(20), server_default='percentage'),
        sa.Column('is_default', sa.Boolean, server_default='false'),
    )

    op.create_table('scholarships', *tc(),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('scholarship_type', sa.String(20), server_default='percentage'),
        sa.Column('value', sa.Numeric(10, 2), nullable=False),
        sa.Column('max_amount', sa.Numeric(12, 2)),
        sa.Column('applicable_fee_categories', postgresql.JSONB, server_default='[]'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('transport_routes', *tc(),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(50)),
        sa.Column('vehicle_number', sa.String(20)),
        sa.Column('vehicle_type', sa.String(30)),
        sa.Column('capacity', sa.Integer, server_default='40'),
        sa.Column('driver_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('helper_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('period_definitions', *tc(),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('start_time', sa.Time, nullable=False),
        sa.Column('end_time', sa.Time, nullable=False),
        sa.Column('period_type', sa.String(20), server_default='period'),
        sa.Column('sort_order', sa.Integer, server_default='0'),
    )

    op.create_table('certificate_templates', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('template_type', sa.String(30), nullable=False),
        sa.Column('template_html', sa.Text),
        sa.Column('template_json', postgresql.JSONB),
        sa.Column('is_default', sa.Boolean, server_default='false'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('library_books', *tc(),
        sa.Column('isbn', sa.String(20)),
        sa.Column('title', sa.String(500), nullable=False),
        sa.Column('author', sa.String(255)),
        sa.Column('publisher', sa.String(255)),
        sa.Column('category', sa.String(100)),
        sa.Column('subject', sa.String(100)),
        sa.Column('edition', sa.String(50)),
        sa.Column('year_published', sa.Integer),
        sa.Column('total_copies', sa.Integer, server_default='1'),
        sa.Column('available_copies', sa.Integer, server_default='1'),
        sa.Column('shelf_location', sa.String(50)),
        sa.Column('barcode', sa.String(50)),
        sa.Column('price', sa.Numeric(10, 2)),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('guardians', *tc(),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id')),
        sa.Column('first_name', sa.String(100), nullable=False),
        sa.Column('last_name', sa.String(100), nullable=False),
        sa.Column('email', sa.String(255)),
        sa.Column('phone', sa.String(20), nullable=False),
        sa.Column('alternate_phone', sa.String(20)),
        sa.Column('occupation', sa.String(100)),
        sa.Column('workplace', sa.String(255)),
        sa.Column('annual_income', sa.Integer),
        sa.Column('education', sa.String(100)),
        sa.Column('address', sa.Text),
        sa.Column('photo_url', sa.String(512)),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    # ── Phase 2: Depend on Phase 1 ─────────────────────────────────────

    op.create_table('academic_terms', *tc(),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('end_date', sa.Date, nullable=False),
        sa.Column('sort_order', sa.Integer, server_default='0'),
    )

    op.create_table('school_holidays', *tc(),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('type', sa.String(30), server_default='holiday'),
    )

    op.create_table('buildings', *tc(),
        sa.Column('campus_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('campuses.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(50)),
        sa.Column('floors', sa.Integer, server_default='1'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('hostels', *tc(),
        sa.Column('campus_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('campuses.id')),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('hostel_type', sa.String(20), server_default='boys'),
        sa.Column('warden_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('capacity', sa.Integer, server_default='100'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('transport_stops', *tc(),
        sa.Column('route_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('transport_routes.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('sequence', sa.Integer, nullable=False),
        sa.Column('pickup_time', sa.Time),
        sa.Column('drop_time', sa.Time),
        sa.Column('latitude', sa.Numeric(10, 8)),
        sa.Column('longitude', sa.Numeric(11, 8)),
    )

    op.create_table('grading_scale_details', *tc(),
        sa.Column('grading_scale_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grading_scales.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('grade', sa.String(10), nullable=False),
        sa.Column('min_percentage', sa.Numeric(5, 2), nullable=False),
        sa.Column('max_percentage', sa.Numeric(5, 2), nullable=False),
        sa.Column('gpa', sa.Numeric(3, 1)),
        sa.Column('description', sa.String(50)),
        sa.Column('sort_order', sa.Integer, server_default='0'),
    )

    op.create_table('fee_fine_rules', *tc(),
        sa.Column('fee_category_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('fee_categories.id'), nullable=False, index=True),
        sa.Column('days_after_due', sa.Integer, nullable=False),
        sa.Column('fine_type', sa.String(20), server_default='fixed'),
        sa.Column('fine_amount', sa.Numeric(10, 2), nullable=False),
        sa.Column('max_fine', sa.Numeric(10, 2)),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('school_events', *tc(),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('event_type', sa.String(30), server_default='general'),
        sa.Column('start_date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('end_date', sa.DateTime(timezone=True)),
        sa.Column('venue', sa.String(255)),
        sa.Column('organizer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('target_audience', postgresql.JSONB, server_default='[]'),
        sa.Column('is_public', sa.Boolean, server_default='false'),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
    )

    op.create_table('circulars', *tc(),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('content', sa.Text, nullable=False),
        sa.Column('circular_type', sa.String(30), server_default='general'),
        sa.Column('target_audience', postgresql.JSONB, server_default='[]'),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('published_at', sa.DateTime(timezone=True)),
        sa.Column('published_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('admission_inquiries', *tc(),
        sa.Column('student_name', sa.String(255), nullable=False),
        sa.Column('parent_name', sa.String(255)),
        sa.Column('phone', sa.String(20), nullable=False),
        sa.Column('email', sa.String(255)),
        sa.Column('grade_applying', sa.String(50)),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id')),
        sa.Column('source', sa.String(50)),
        sa.Column('status', sa.String(20), server_default='new'),
        sa.Column('notes', sa.Text),
        sa.Column('assigned_to', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
    )

    op.create_table('subjects', *tc(),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('code', sa.String(50), nullable=False),
        sa.Column('subject_type', sa.String(30), server_default='core'),
        sa.Column('department_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('departments.id')),
        sa.Column('credits', sa.Numeric(4, 1), server_default='0'),
        sa.Column('max_marks', sa.Integer, server_default='100'),
        sa.Column('pass_marks', sa.Integer, server_default='33'),
        sa.Column('has_practical', sa.Boolean, server_default='false'),
        sa.Column('practical_max_marks', sa.Integer, server_default='0'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    # ── Phase 3: Depend on Phase 2 (sections, rooms, hostel_rooms) ──────

    op.create_table('rooms', *tc(),
        sa.Column('building_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('buildings.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('room_number', sa.String(50)),
        sa.Column('floor', sa.Integer, server_default='0'),
        sa.Column('room_type', sa.String(30), server_default='classroom'),
        sa.Column('capacity', sa.Integer, server_default='40'),
        sa.Column('has_projector', sa.Boolean, server_default='false'),
        sa.Column('has_ac', sa.Boolean, server_default='false'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('houses', *tc(),
        sa.Column('name', sa.String(100), nullable=False),
        sa.Column('code', sa.String(20)),
        sa.Column('color', sa.String(20)),
        sa.Column('house_master_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('hostel_rooms', *tc(),
        sa.Column('hostel_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('hostels.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('room_number', sa.String(50), nullable=False),
        sa.Column('floor', sa.Integer, server_default='0'),
        sa.Column('room_type', sa.String(20), server_default='dormitory'),
        sa.Column('capacity', sa.Integer, server_default='4'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('sections', *tc(),
        sa.Column('grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('name', sa.String(50), nullable=False),
        sa.Column('capacity', sa.Integer, server_default='40'),
        sa.Column('room_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('rooms.id')),
        sa.Column('class_teacher_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('fee_structures', *tc(),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id'), nullable=False, index=True),
        sa.Column('fee_category_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('fee_categories.id'), nullable=False, index=True),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('frequency', sa.String(20), server_default='monthly'),
        sa.Column('due_day', sa.Integer, server_default='10'),
        sa.Column('is_mandatory', sa.Boolean, server_default='true'),
    )

    op.create_table('grade_subjects', *tc(),
        sa.Column('grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('is_compulsory', sa.Boolean, server_default='true'),
        sa.Column('sort_order', sa.Integer, server_default='0'),
    )

    op.create_table('exams', *tc(),
        sa.Column('exam_type_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('exam_types.id'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('academic_term_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_terms.id')),
        sa.Column('name', sa.String(255), nullable=False),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('end_date', sa.Date, nullable=False),
        sa.Column('status', sa.String(20), server_default='draft'),
    )

    # ── Phase 4: Depend on students ─────────────────────────────────────

    op.create_table('students', *tc(),
        sa.Column('admission_number', sa.String(50), nullable=False),
        sa.Column('roll_number', sa.String(20)),
        sa.Column('first_name', sa.String(100), nullable=False),
        sa.Column('last_name', sa.String(100), nullable=False),
        sa.Column('middle_name', sa.String(100)),
        sa.Column('date_of_birth', sa.Date, nullable=False),
        sa.Column('gender', sa.String(10), nullable=False),
        sa.Column('blood_group', sa.String(5)),
        sa.Column('nationality', sa.String(50), server_default='Indian'),
        sa.Column('religion', sa.String(50)),
        sa.Column('caste', sa.String(50)),
        sa.Column('category', sa.String(20)),
        sa.Column('aadhaar_number', sa.String(12)),
        sa.Column('email', sa.String(255)),
        sa.Column('phone', sa.String(20)),
        sa.Column('address', sa.Text),
        sa.Column('city', sa.String(100)),
        sa.Column('state', sa.String(100)),
        sa.Column('pincode', sa.String(10)),
        sa.Column('photo_url', sa.String(512)),
        sa.Column('admission_date', sa.Date, nullable=False),
        sa.Column('admission_grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id')),
        sa.Column('current_grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id'), index=True),
        sa.Column('current_section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id'), index=True),
        sa.Column('house_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('houses.id')),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('status', sa.String(20), server_default='active'),
        sa.Column('previous_school', sa.String(255)),
        sa.Column('previous_grade', sa.String(50)),
        sa.Column('transfer_certificate_number', sa.String(100)),
        sa.Column('medical_conditions', sa.Text),
        sa.Column('allergies', sa.Text),
        sa.Column('emergency_contact_name', sa.String(255)),
        sa.Column('emergency_contact_phone', sa.String(20)),
        sa.Column('emergency_contact_relation', sa.String(50)),
        sa.Column('transport_route_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('transport_routes.id')),
        sa.Column('hostel_room_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('hostel_rooms.id')),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )
    op.create_index('ix_students_tenant_active', 'students', ['tenant_id', 'is_active'])
    op.create_index('ix_students_tenant_grade_section', 'students', ['tenant_id', 'current_grade_id', 'current_section_id'])

    # ── Phase 5: Depend on students + sections/subjects ─────────────────

    op.create_table('student_guardians', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('guardian_id', postgresql.UUID(as_uuid=True), nullable=False, index=True),
        sa.Column('relationship', sa.String(30), nullable=False),
        sa.Column('is_primary', sa.Boolean, server_default='false'),
        sa.Column('is_emergency_contact', sa.Boolean, server_default='false'),
        sa.Column('can_pickup', sa.Boolean, server_default='true'),
    )

    op.create_table('student_siblings', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('sibling_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
    )

    op.create_table('admission_applications', *tc(),
        sa.Column('inquiry_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('admission_inquiries.id')),
        sa.Column('application_number', sa.String(50), nullable=False),
        sa.Column('student_name', sa.String(255), nullable=False),
        sa.Column('date_of_birth', sa.Date, nullable=False),
        sa.Column('gender', sa.String(10), nullable=False),
        sa.Column('grade_applying', sa.String(50), nullable=False),
        sa.Column('parent_name', sa.String(255), nullable=False),
        sa.Column('parent_phone', sa.String(20), nullable=False),
        sa.Column('parent_email', sa.String(255)),
        sa.Column('previous_school', sa.String(255)),
        sa.Column('previous_grade', sa.String(50)),
        sa.Column('address', sa.Text),
        sa.Column('documents', postgresql.JSONB, server_default='[]'),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('status', sa.String(20), server_default='submitted'),
        sa.Column('interview_date', sa.DateTime(timezone=True)),
        sa.Column('interview_score', sa.Numeric(5, 2)),
        sa.Column('remarks', sa.Text),
        sa.Column('reviewed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('reviewed_at', sa.DateTime(timezone=True)),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id')),
    )

    op.create_table('issued_certificates', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('template_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('certificate_templates.id'), nullable=False),
        sa.Column('certificate_number', sa.String(50), nullable=False),
        sa.Column('issue_date', sa.Date, nullable=False),
        sa.Column('purpose', sa.String(255)),
        sa.Column('issued_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('pdf_url', sa.String(512)),
        sa.Column('qr_code', sa.String(255)),
    )

    op.create_table('health_records', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('record_type', sa.String(30), server_default='checkup'),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('doctor_name', sa.String(255)),
        sa.Column('medication', sa.Text),
        sa.Column('next_followup', sa.Date),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('recorded_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
    )

    op.create_table('discipline_incidents', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('incident_date', sa.Date, nullable=False),
        sa.Column('incident_type', sa.String(30), server_default='misconduct'),
        sa.Column('severity', sa.String(20), server_default='minor'),
        sa.Column('description', sa.Text, nullable=False),
        sa.Column('action_taken', sa.Text),
        sa.Column('reported_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('parent_informed', sa.Boolean, server_default='false'),
        sa.Column('parent_meeting_date', sa.Date),
        sa.Column('status', sa.String(20), server_default='open'),
        sa.Column('resolution', sa.Text),
        sa.Column('resolved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
    )

    op.create_table('student_fees', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('fee_structure_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('fee_structures.id'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('discount_amount', sa.Numeric(12, 2), server_default='0'),
        sa.Column('scholarship_amount', sa.Numeric(12, 2), server_default='0'),
        sa.Column('final_amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('due_date', sa.Date),
        sa.Column('status', sa.String(20), server_default='pending'),
    )
    op.create_index('ix_student_fees_tenant_status', 'student_fees', ['tenant_id', 'status'])

    op.create_table('fee_payments', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('student_fee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('student_fees.id'), nullable=False, index=True),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('payment_date', sa.Date, nullable=False),
        sa.Column('payment_method', sa.String(30), server_default='cash'),
        sa.Column('reference_number', sa.String(100)),
        sa.Column('receipt_number', sa.String(50)),
        sa.Column('collected_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('remarks', sa.Text),
        sa.Column('status', sa.String(20), server_default='completed'),
    )

    op.create_table('student_scholarships', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('scholarship_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('scholarships.id'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('start_date', sa.Date),
        sa.Column('end_date', sa.Date),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('hostel_allocations', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('hostel_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('hostels.id'), nullable=False, index=True),
        sa.Column('room_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('hostel_rooms.id'), nullable=False),
        sa.Column('bed_number', sa.Integer),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('start_date', sa.Date, nullable=False),
        sa.Column('end_date', sa.Date),
        sa.Column('status', sa.String(20), server_default='active'),
    )

    op.create_table('student_transport', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('route_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('transport_routes.id'), nullable=False, index=True),
        sa.Column('stop_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('transport_stops.id'), nullable=False),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('pickup_type', sa.String(10), server_default='pickup'),
        sa.Column('fee_amount', sa.Numeric(10, 2), server_default='0'),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('student_attendance', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('status', sa.String(20), nullable=False),
        sa.Column('check_in_time', sa.Time),
        sa.Column('check_out_time', sa.Time),
        sa.Column('remarks', sa.String(255)),
        sa.Column('marked_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('attendance_type', sa.String(20), server_default='daily'),
        sa.Column('period_definition_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('period_definitions.id')),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
    )
    op.create_index('ix_student_attendance_tenant_date_status', 'student_attendance', ['tenant_id', 'date', 'status'])

    op.create_table('student_attendance_summary', *tc(),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('month', sa.Integer, nullable=False),
        sa.Column('year', sa.Integer, nullable=False),
        sa.Column('total_days', sa.Integer, server_default='0'),
        sa.Column('present_days', sa.Integer, server_default='0'),
        sa.Column('absent_days', sa.Integer, server_default='0'),
        sa.Column('late_days', sa.Integer, server_default='0'),
        sa.Column('half_days', sa.Integer, server_default='0'),
        sa.Column('excused_days', sa.Integer, server_default='0'),
    )

    # ── Phase 6: Depend on sections/subjects/employees ──────────────────

    op.create_table('teacher_allocations', *tc(),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('periods_per_week', sa.Integer, server_default='0'),
    )

    op.create_table('timetable_entries', *tc(),
        sa.Column('section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id')),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('room_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('rooms.id')),
        sa.Column('period_definition_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('period_definitions.id'), nullable=False),
        sa.Column('day_of_week', sa.Integer, nullable=False),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('exam_schedules', *tc(),
        sa.Column('exam_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('exams.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id'), nullable=False, index=True),
        sa.Column('grade_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('grades.id'), nullable=False, index=True),
        sa.Column('exam_date', sa.Date, nullable=False),
        sa.Column('start_time', sa.Time, nullable=False),
        sa.Column('end_time', sa.Time, nullable=False),
        sa.Column('max_marks', sa.Integer, server_default='100'),
        sa.Column('pass_marks', sa.Integer, server_default='33'),
        sa.Column('room_ids', postgresql.JSONB, server_default='[]'),
        sa.Column('invigilator_ids', postgresql.JSONB, server_default='[]'),
    )

    op.create_table('exam_marks', *tc(),
        sa.Column('exam_schedule_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('exam_schedules.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('marks_obtained', sa.Numeric(6, 2)),
        sa.Column('practical_marks', sa.Numeric(6, 2)),
        sa.Column('grade', sa.String(10)),
        sa.Column('is_absent', sa.Boolean, server_default='false'),
        sa.Column('is_exempted', sa.Boolean, server_default='false'),
        sa.Column('remarks', sa.String(255)),
        sa.Column('entered_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('verified_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
    )

    op.create_table('homework', *tc(),
        sa.Column('section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id'), nullable=False, index=True),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('due_date', sa.Date, nullable=False),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('homework_submissions', *tc(),
        sa.Column('homework_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('homework.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('submitted_at', sa.DateTime(timezone=True)),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('remarks', sa.Text),
        sa.Column('marks', sa.Numeric(5, 2)),
        sa.Column('grade', sa.String(10)),
        sa.Column('status', sa.String(20), server_default='pending'),
        sa.Column('reviewed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('reviewed_at', sa.DateTime(timezone=True)),
    )

    op.create_table('assignments', *tc(),
        sa.Column('section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id'), nullable=False, index=True),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id'), nullable=False),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('assignment_type', sa.String(30), server_default='online'),
        sa.Column('max_marks', sa.Numeric(5, 2)),
        sa.Column('rubric', postgresql.JSONB),
        sa.Column('due_date', sa.Date, nullable=False),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('is_active', sa.Boolean, server_default='true'),
    )

    op.create_table('assignment_submissions', *tc(),
        sa.Column('assignment_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('assignments.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('student_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('students.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('submitted_at', sa.DateTime(timezone=True)),
        sa.Column('attachment_urls', postgresql.JSONB, server_default='[]'),
        sa.Column('marks', sa.Numeric(5, 2)),
        sa.Column('grade', sa.String(10)),
        sa.Column('feedback', sa.Text),
        sa.Column('status', sa.String(20), server_default='pending'),
        sa.Column('evaluated_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('evaluated_at', sa.DateTime(timezone=True)),
    )

    op.create_table('lesson_plans', *tc(),
        sa.Column('employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id'), nullable=False, index=True),
        sa.Column('section_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('sections.id'), nullable=False, index=True),
        sa.Column('subject_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('subjects.id'), nullable=False, index=True),
        sa.Column('academic_year_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('academic_years.id'), nullable=False, index=True),
        sa.Column('title', sa.String(255), nullable=False),
        sa.Column('description', sa.Text),
        sa.Column('unit_number', sa.Integer),
        sa.Column('lesson_number', sa.Integer),
        sa.Column('planned_date', sa.Date),
        sa.Column('actual_date', sa.Date),
        sa.Column('duration_periods', sa.Integer, server_default='1'),
        sa.Column('learning_objectives', sa.Text),
        sa.Column('teaching_methods', sa.Text),
        sa.Column('resources', sa.Text),
        sa.Column('homework', sa.Text),
        sa.Column('status', sa.String(20), server_default='planned'),
        sa.Column('completion_percentage', sa.Integer, server_default='0'),
        sa.Column('remarks', sa.Text),
    )

    op.create_table('library_transactions', *tc(),
        sa.Column('book_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('library_books.id', ondelete='CASCADE'), nullable=False, index=True),
        sa.Column('borrower_type', sa.String(20), server_default='student'),
        sa.Column('borrower_id', postgresql.UUID(as_uuid=True), nullable=False, index=True),
        sa.Column('issue_date', sa.Date, nullable=False),
        sa.Column('due_date', sa.Date, nullable=False),
        sa.Column('return_date', sa.Date),
        sa.Column('fine_amount', sa.Numeric(10, 2), server_default='0'),
        sa.Column('fine_paid', sa.Boolean, server_default='false'),
        sa.Column('issued_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('returned_to', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id')),
        sa.Column('status', sa.String(20), server_default='issued'),
    )

    op.create_table('substitutions', *tc(),
        sa.Column('original_employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id'), nullable=False, index=True),
        sa.Column('substitute_employee_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('employees.id'), nullable=False, index=True),
        sa.Column('timetable_entry_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('timetable_entries.id'), nullable=False),
        sa.Column('date', sa.Date, nullable=False),
        sa.Column('reason', sa.String(255)),
        sa.Column('status', sa.String(20), server_default='pending'),
        sa.Column('approved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id')),
    )


def downgrade() -> None:
    tables = [
        'substitutions', 'library_transactions', 'lesson_plans',
        'assignment_submissions', 'assignments', 'homework_submissions', 'homework',
        'exam_marks', 'exam_schedules', 'timetable_entries', 'teacher_allocations',
        'student_attendance_summary', 'student_attendance',
        'student_transport', 'hostel_allocations', 'student_scholarships',
        'fee_payments', 'student_fees', 'discipline_incidents', 'health_records',
        'issued_certificates', 'admission_applications',
        'student_siblings', 'student_guardians', 'students',
        'exams', 'grade_subjects', 'fee_structures', 'sections',
        'hostel_rooms', 'houses', 'rooms',
        'admission_inquiries', 'circulars', 'school_events',
        'fee_fine_rules', 'grading_scale_details', 'transport_stops',
        'hostels', 'buildings', 'school_holidays', 'academic_terms',
        'guardians', 'library_books', 'certificate_templates',
        'period_definitions', 'transport_routes', 'scholarships',
        'grading_scales', 'exam_types', 'fee_categories', 'subjects',
        'campuses', 'grades', 'academic_years',
    ]
    for t in tables:
        op.drop_table(t)
