"""add missing indexes for performance

Revision ID: a1b2c3d4e5f6
Revises: f7a8b9c0d1e2
Create Date: 2026-06-27 12:00:00.000000
"""
from typing import Sequence, Union
from alembic import op

revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, None] = 'f7a8b9c0d1e2'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


INDEXES = [
    # Employee table - high traffic
    ("ix_employees_status", "employees", ["status"]),
    ("ix_employees_department_id", "employees", ["department_id"]),
    ("ix_employees_designation_id", "employees", ["designation_id"]),
    ("ix_employees_branch_id", "employees", ["branch_id"]),
    ("ix_employees_shift_id", "employees", ["shift_id"]),
    ("ix_employees_category_id", "employees", ["category_id"]),
    ("ix_employees_shift_group_id", "employees", ["shift_group_id"]),
    ("ix_employees_shift_roster_id", "employees", ["shift_roster_id"]),

    # Attendance table
    ("ix_attendances_date", "attendances", ["date"]),
    ("ix_attendances_status", "attendances", ["status"]),
    ("ix_attendances_employee_date", "attendances", ["employee_id", "date"]),

    # Punch logs
    ("ix_punch_logs_punch_time", "punch_logs", ["punch_time"]),

    # Attendance raw logs
    ("ix_attendance_raw_logs_device_id", "attendance_raw_logs", ["device_id"]),

    # Leave requests
    ("ix_leave_requests_status", "leave_requests", ["status"]),
    ("ix_leave_requests_start_date", "leave_requests", ["start_date"]),
    ("ix_leave_requests_end_date", "leave_requests", ["end_date"]),

    # Exit requests
    ("ix_exit_requests_status", "exit_requests", ["status"]),
    ("ix_exit_requests_approved_by", "exit_requests", ["approved_by"]),

    # Onboarding tasks
    ("ix_onboarding_tasks_status", "onboarding_tasks", ["status"]),
    ("ix_onboarding_tasks_assigned_to", "onboarding_tasks", ["assigned_to"]),

    # Documents
    ("ix_documents_uploaded_by", "documents", ["uploaded_by"]),
    ("ix_documents_employee_id", "documents", ["employee_id"]),

    # Timeline events
    ("ix_employee_events_created_by", "employee_events", ["created_by"]),

    # OT Register
    ("ix_ot_register_approved_by", "ot_register", ["approved_by"]),

    # Outdoor duties
    ("ix_outdoor_duties_approved_by", "outdoor_duties", ["approved_by"]),

    # Expense claims
    ("ix_expense_claims_category_id", "expense_claims", ["category_id"]),
    ("ix_expense_claims_approved_by", "expense_claims", ["approved_by"]),

    # Company assets
    ("ix_company_assets_assigned_to", "company_assets", ["assigned_to"]),

    # Benefits
    ("ix_employee_benefits_benefit_id", "employee_benefits", ["benefit_id"]),

    # Announcements
    ("ix_announcements_created_by", "announcements", ["created_by"]),
    ("ix_polls_created_by", "polls", ["created_by"]),
    ("ix_poll_responses_poll_id", "poll_responses", ["poll_id"]),

    # Approval system
    ("ix_approval_steps_workflow_id", "approval_steps", ["workflow_id"]),
    ("ix_approval_steps_approver_role_id", "approval_steps", ["approver_role_id"]),
    ("ix_approval_steps_approver_user_id", "approval_steps", ["approver_user_id"]),
    ("ix_approval_requests_workflow_id", "approval_requests", ["workflow_id"]),
    ("ix_approval_requests_requester_id", "approval_requests", ["requester_id"]),
    ("ix_approval_history_request_id", "approval_history", ["request_id"]),
    ("ix_approval_history_approver_id", "approval_history", ["approver_id"]),
    ("ix_login_history_user_id", "login_history", ["user_id"]),

    # Features
    ("ix_tenant_features_enabled_by", "tenant_features", ["enabled_by"]),

    # Subscriptions
    ("ix_tenant_subscriptions_plan_id", "tenant_subscriptions", ["plan_id"]),

    # Recruitment
    ("ix_job_requisitions_department_id", "job_requisitions", ["department_id"]),
    ("ix_job_requisitions_branch_id", "job_requisitions", ["branch_id"]),
    ("ix_job_requisitions_hiring_manager_id", "job_requisitions", ["hiring_manager_id"]),
    ("ix_job_requisitions_approved_by", "job_requisitions", ["approved_by"]),
    ("ix_job_openings_requisition_id", "job_openings", ["requisition_id"]),
    ("ix_job_openings_department_id", "job_openings", ["department_id"]),
    ("ix_job_openings_created_by", "job_openings", ["created_by"]),
    ("ix_candidates_opening_id", "candidates", ["opening_id"]),
    ("ix_interviews_opening_id", "interviews", ["opening_id"]),
    ("ix_interviews_interviewer_id", "interviews", ["interviewer_id"]),
    ("ix_offers_opening_id", "offers", ["opening_id"]),
    ("ix_offers_offered_department_id", "offers", ["offered_department_id"]),
    ("ix_offers_created_by", "offers", ["created_by"]),

    # Performance
    ("ix_review_cycles_created_by", "review_cycles", ["created_by"]),
    ("ix_goals_cycle_id", "goals", ["cycle_id"]),
    ("ix_goals_approved_by", "goals", ["approved_by"]),
    ("ix_performance_reviews_reviewer_id", "performance_reviews", ["reviewer_id"]),
    ("ix_performance_recommendations_review_id", "performance_recommendations", ["review_id"]),
    ("ix_performance_recommendations_recommended_by", "performance_recommendations", ["recommended_by"]),
    ("ix_performance_recommendations_approved_by", "performance_recommendations", ["approved_by"]),
    ("ix_performance_recommendations_new_designation_id", "performance_recommendations", ["new_designation_id"]),

    # Shift rosters
    ("ix_shift_roster_entries_shift_id", "shift_roster_entries", ["shift_id"]),

    # Role permissions
    ("ix_role_permissions_permission_id", "role_permissions", ["permission_id"]),

    # Super admin logs
    ("ix_super_admin_logs_admin_user_id", "super_admin_logs", ["admin_user_id"]),
]


def upgrade() -> None:
    for idx_name, table, columns in INDEXES:
        try:
            op.create_index(idx_name, table, columns)
        except Exception:
            pass  # Index may already exist


def downgrade() -> None:
    for idx_name, table, columns in INDEXES:
        try:
            op.drop_index(idx_name, table_name=table)
        except Exception:
            pass
