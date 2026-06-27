"""Add indexes to all foreign key columns across all tables."""

import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import engine


INDEXES = [
    # users
    ("users", "tenant_id"),
    # employees
    ("employees", "tenant_id"),
    ("employees", "department_id"),
    ("employees", "designation_id"),
    ("employees", "branch_id"),
    ("employees", "shift_id"),
    ("employees", "category_id"),
    ("employees", "shift_group_id"),
    ("employees", "shift_roster_id"),
    # attendances
    ("attendances", "tenant_id"),
    ("attendances", "employee_id"),
    ("attendances", "shift_id"),
    ("attendances", "approved_by"),
    # punch_logs
    ("punch_logs", "tenant_id"),
    ("punch_logs", "employee_id"),
    ("punch_logs", "device_id"),
    # shifts
    ("shifts", "tenant_id"),
    # shift_schedules
    ("shift_schedules", "tenant_id"),
    ("shift_schedules", "employee_id"),
    ("shift_schedules", "shift_id"),
    # leave_types
    ("leave_types", "tenant_id"),
    # leave_balances
    ("leave_balances", "tenant_id"),
    ("leave_balances", "employee_id"),
    ("leave_balances", "leave_type_id"),
    # leave_requests
    ("leave_requests", "tenant_id"),
    ("leave_requests", "employee_id"),
    ("leave_requests", "leave_type_id"),
    ("leave_requests", "approved_by"),
    # visitors
    ("visitors", "tenant_id"),
    # visitor_passes
    ("visitor_passes", "tenant_id"),
    ("visitor_passes", "visitor_id"),
    ("visitor_passes", "host_employee_id"),
    # access_zones
    ("access_zones", "tenant_id"),
    # doors
    ("doors", "tenant_id"),
    ("doors", "zone_id"),
    # user_access_levels
    ("user_access_levels", "tenant_id"),
    ("user_access_levels", "employee_id"),
    ("user_access_levels", "zone_id"),
    ("user_access_levels", "granted_by"),
    # access_logs
    ("access_logs", "tenant_id"),
    ("access_logs", "employee_id"),
    ("access_logs", "door_id"),
    # device_commands
    ("device_commands", "tenant_id"),
    ("device_commands", "device_id"),
    ("device_commands", "requested_by"),
    # notifications
    ("notifications", "tenant_id"),
    ("notifications", "user_id"),
    # audit_logs
    ("audit_logs", "tenant_id"),
    ("audit_logs", "user_id"),
    # devices
    ("devices", "tenant_id"),
    ("devices", "branch_id"),
    # device_logs
    ("device_logs", "tenant_id"),
    ("device_logs", "device_id"),
    # departments
    ("departments", "tenant_id"),
    # designations
    ("designations", "tenant_id"),
    # branches
    ("branches", "tenant_id"),
    # roles
    ("roles", "tenant_id"),
    # permissions
    ("permissions", "tenant_id"),
    # role_permissions
    ("role_permissions", "role_id"),
    ("role_permissions", "permission_id"),
    # user_roles
    ("user_roles", "user_id"),
    ("user_roles", "role_id"),
    ("user_roles", "tenant_id"),
    # holidays
    ("holidays", "tenant_id"),
    # essl_servers
    ("essl_servers", "tenant_id"),
    # essl_sync_history
    ("essl_sync_history", "server_id"),
    # essl_sync_jobs
    ("essl_sync_jobs", "server_id"),
    # essl_sync_errors
    ("essl_sync_errors", "job_id"),
    # essl_employee_mappings
    ("essl_employee_mappings", "tenant_id"),
    ("essl_employee_mappings", "employee_id"),
    # essl_device_mappings
    ("essl_device_mappings", "tenant_id"),
    ("essl_device_mappings", "device_id"),
    # essl_sync_cursors
    ("essl_sync_cursors", "server_id"),
    # essl_locations
    ("essl_locations", "server_id"),
    # announcements
    ("announcements", "tenant_id"),
    # notification_templates
    ("notification_templates", "tenant_id"),
    # benefits
    ("benefits", "tenant_id"),
    # employee_benefits
    ("employee_benefits", "tenant_id"),
    ("employee_benefits", "employee_id"),
    ("employee_benefits", "benefit_id"),
    # expense_categories
    ("expense_categories", "tenant_id"),
    # expense_claims
    ("expense_claims", "tenant_id"),
    ("expense_claims", "employee_id"),
    ("expense_claims", "category_id"),
    ("expense_claims", "approved_by"),
    # tax_declarations
    ("tax_declarations", "tenant_id"),
    ("tax_declarations", "employee_id"),
    # documents
    ("documents", "tenant_id"),
    ("documents", "employee_id"),
    # exit_requests
    ("exit_requests", "tenant_id"),
    ("exit_requests", "employee_id"),
    ("exit_requests", "approved_by"),
    # onboarding_tasks
    ("onboarding_tasks", "tenant_id"),
    ("onboarding_tasks", "employee_id"),
    # ot_registers
    ("ot_registers", "tenant_id"),
    ("ot_registers", "employee_id"),
    # outdoor_duties
    ("outdoor_duties", "tenant_id"),
    ("outdoor_duties", "employee_id"),
    # salary_structures
    ("salary_structures", "tenant_id"),
    ("salary_structures", "employee_id"),
    # pay_slips
    ("pay_slips", "tenant_id"),
    ("pay_slips", "employee_id"),
    # loans
    ("loans", "tenant_id"),
    ("loans", "employee_id"),
    # review_cycles
    ("review_cycles", "tenant_id"),
    # goals
    ("goals", "tenant_id"),
    ("goals", "employee_id"),
    # performance_reviews
    ("performance_reviews", "tenant_id"),
    ("performance_reviews", "employee_id"),
    ("performance_reviews", "reviewer_id"),
    # competencies
    ("competencies", "tenant_id"),
    # performance_recommendations
    ("performance_recommendations", "tenant_id"),
    ("performance_recommendations", "review_id"),
    ("performance_recommendations", "recommended_by"),
    # job_requisitions
    ("job_requisitions", "tenant_id"),
    # job_openings
    ("job_openings", "tenant_id"),
    ("job_openings", "requisition_id"),
    # candidates
    ("candidates", "tenant_id"),
    ("candidates", "opening_id"),
    # interviews
    ("interviews", "tenant_id"),
    ("interviews", "candidate_id"),
    ("interviews", "interviewer_id"),
    # offers
    ("offers", "tenant_id"),
    ("offers", "candidate_id"),
    # shift_groups
    ("shift_groups", "tenant_id"),
    # shift_group_members
    ("shift_group_members", "group_id"),
    ("shift_group_members", "employee_id"),
    # shift_rosters
    ("shift_rosters", "tenant_id"),
    # shift_roster_entries
    ("shift_roster_entries", "roster_id"),
    ("shift_roster_entries", "employee_id"),
    ("shift_roster_entries", "shift_id"),
    # department_shifts
    ("department_shifts", "tenant_id"),
    ("department_shifts", "department_id"),
    ("department_shifts", "shift_id"),
    # company_assets
    ("company_assets", "tenant_id"),
    # travel_requests
    ("travel_requests", "tenant_id"),
    ("travel_requests", "employee_id"),
    # approval_workflows
    ("approval_workflows", "tenant_id"),
    # approval_steps
    ("approval_steps", "workflow_id"),
    # approval_requests
    ("approval_requests", "tenant_id"),
    ("approval_requests", "workflow_id"),
    ("approval_requests", "requester_id"),
    ("approval_requests", "current_step_id"),
    # approval_history
    ("approval_history", "request_id"),
    ("approval_history", "step_id"),
    ("approval_history", "approver_id"),
    # login_history
    ("login_history", "tenant_id"),
    ("login_history", "user_id"),
    # super_admin_logs
    ("super_admin_logs", "admin_user_id"),
    # tenant_subscriptions
    ("tenant_subscriptions", "tenant_id"),
    ("tenant_subscriptions", "plan_id"),
    # resource_limits
    ("resource_limits", "tenant_id"),
    # tenant_features
    ("tenant_features", "tenant_id"),
    ("tenant_features", "feature_id"),
    # employee_categories
    ("employee_categories", "tenant_id"),
    # tenant_settings
    ("tenant_settings", "tenant_id"),
    # work_codes
    ("work_codes", "tenant_id"),
    # attendance_raw_logs
    ("attendance_raw_logs", "tenant_id"),
]


async def migrate():
    for table, column in INDEXES:
        index_name = f"ix_{table}_{column}"
        sql = f"CREATE INDEX IF NOT EXISTS {index_name} ON {table} ({column})"
        try:
            async with engine.begin() as conn:
                await conn.execute(text(sql))
            print(f"  created: {index_name}")
        except Exception as e:
            if "already exists" in str(e):
                print(f"  exists: {index_name}")
            else:
                print(f"  error on {index_name}: {e}")
    print("Migration complete")


if __name__ == "__main__":
    asyncio.run(migrate())
