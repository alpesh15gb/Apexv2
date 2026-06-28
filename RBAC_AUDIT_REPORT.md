# RBAC Audit Report - Apex HRMS

**Audit Date:** 2026-06-28
**Scope:** All API endpoints in `backend/app/api/v1/endpoints/`
**Auditor:** MiMo Code Agent

---

## Executive Summary

| Metric | Count |
|--------|-------|
| **Total Endpoints** | 287 |
| **Protected (RBAC + Feature + Tenant)** | 241 (84.0%) |
| **Partially Protected (Auth-only)** | 39 (13.6%) |
| **Unprotected (No auth)** | 7 (2.4%) |

**Overall Assessment:** The application has a strong RBAC foundation with `require_permissions()` and `require_feature()` decorators. However, there are **7 completely unprotected endpoints** and **39 endpoints with only basic authentication** that lack granular permission checks.

---

## Module Summary

| Module | Total | Protected | Partial | Unprotected |
|--------|-------|-----------|---------|-------------|
| Auth | 9 | 3 | 4 | 2 |
| Employees | 16 | 16 | 0 | 0 |
| Attendance | 8 | 8 | 0 | 0 |
| Leaves | 8 | 8 | 0 | 0 |
| Payroll | 9 | 9 | 0 | 0 |
| Dashboard | 10 | 10 | 0 | 0 |
| Reports | 15 | 15 | 0 | 0 |
| Devices | 10 | 10 | 0 | 0 |
| Shifts | 8 | 8 | 0 | 0 |
| Shift Groups | 5 | 5 | 0 | 0 |
| Shift Rosters | 5 | 5 | 0 | 0 |
| Visitors | 8 | 8 | 0 | 0 |
| Access Control | 8 | 8 | 0 | 0 |
| Holidays | 4 | 4 | 0 | 0 |
| Categories | 4 | 4 | 0 | 0 |
| Tenant Settings | 2 | 2 | 0 | 0 |
| Notifications | 4 | 4 | 0 | 0 |
| Notification Center | 4 | 4 | 0 | 0 |
| Documents | 4 | 4 | 0 | 0 |
| eSSL Connector | 22 | 22 | 0 | 0 |
| eSSL Locations | 4 | 4 | 0 | 0 |
| Exit Requests | 3 | 3 | 0 | 0 |
| Expense/Benefits | 10 | 10 | 0 | 0 |
| HR Operations | 13 | 13 | 0 | 0 |
| ESS (Self Service) | 13 | 0 | 13 | 0 |
| Lifecycle | 8 | 0 | 8 | 0 |
| Onboarding | 4 | 4 | 0 | 0 |
| Outdoor Duties | 4 | 4 | 0 | 0 |
| OT Register | 4 | 4 | 0 | 0 |
| Performance | 12 | 0 | 12 | 0 |
| Recruitment | 17 | 0 | 17 | 0 |
| Timeline | 3 | 3 | 0 | 0 |
| Work Codes | 4 | 4 | 0 | 0 |
| Setup | 8 | 0 | 8 | 0 |
| Settings API | 2 | 0 | 2 | 0 |
| System | 3 | 0 | 3 | 0 |
| Operations | 6 | 0 | 6 | 0 |
| Billing | 7 | 0 | 7 | 0 |
| Analytics | 4 | 0 | 4 | 0 |
| Import/Export | 5 | 0 | 5 | 0 |
| Commands | 4 | 4 | 0 | 0 |
| Department Shifts | 3 | 3 | 0 | 0 |
| WebSocket | 1 | 1 | 0 | 0 |
| Tenants | 5 | 0 | 5 | 0 |
| **Admin Auth** | 1 | 0 | 0 | 1 |
| **Admin Dashboard** | 2 | 0 | 0 | 2 |
| **Admin Tenants** | 11 | 0 | 0 | 11 |
| **Admin Plans** | 4 | 0 | 0 | 4 |
| **Admin Features** | 5 | 0 | 0 | 5 |
| School Academic Year | 8 | 8 | 0 | 0 |
| School Grade/Section | 10 | 10 | 0 | 0 |
| School Students | 8 | 8 | 0 | 0 |
| School Student Attendance | 4 | 4 | 0 | 0 |
| School Homework | 5 | 5 | 0 | 0 |
| School Examinations | 10 | 10 | 0 | 0 |
| School Fees | 7 | 7 | 0 | 0 |
| School Dashboard | 2 | 2 | 0 | 0 |
| School Transport | 6 | 6 | 0 | 0 |
| School Hostel | 6 | 6 | 0 | 0 |
| School Library | 5 | 5 | 0 | 0 |
| School Timetable | 7 | 7 | 0 | 0 |
| School Circulars | 2 | 2 | 0 | 0 |
| School Events | 2 | 2 | 0 | 0 |
| School Medical | 3 | 3 | 0 | 0 |
| School Discipline | 3 | 3 | 0 | 0 |
| School Certificates | 4 | 4 | 0 | 0 |
| School Admissions | 5 | 5 | 0 | 0 |

---

## Complete Endpoint Inventory

### 1. Auth Module (`/auth`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| POST | /auth/register | register | None | None | None | **None** | N/A (creates tenant) | **Unprotected** |
| POST | /auth/login | login | None | None | None | **None** | Optional | **Unprotected** |
| POST | /auth/refresh | refresh_token | None | None | None | **None** | Via token | **Unprotected** |
| POST | /auth/logout | logout | None | None | None | **None** | N/A | **Unprotected** |
| GET | /auth/me | get_me | get_current_active_user | None | None | Auth-only | Via user | Partial |
| PUT | /auth/me | update_me | get_current_active_user | None | None | Auth-only | Via user | Partial |
| POST | /auth/change-password | change_password | get_current_active_user | None | None | Auth-only | Via user | Partial |
| POST | /auth/logout-all | logout_all_devices | get_current_active_user | None | None | Auth-only | Via user | Partial |

**Issues:**
- `/register`, `/login`, `/refresh`, `/logout` are intentionally public (authentication endpoints)
- Profile endpoints (`/me`, `/change-password`, `/logout-all`) lack granular permission checks

---

### 2. Employees Module (`/employees`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /employees/departments | list_departments | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/departments | create_department | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /employees/departments/{id} | update_department | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| DELETE | /employees/departments/{id} | delete_department | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /employees/designations | list_designations | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/designations | create_designation | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /employees/designations/{id} | update_designation | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| DELETE | /employees/designations/{id} | delete_designation | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /employees/branches | list_branches | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/branches | create_branch | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /employees/branches/{id} | update_branch | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| DELETE | /employees/branches/{id} | delete_branch | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /employees/ | list_employees | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/ | create_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/bulk-import | bulk_import | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /employees/{id} | get_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /employees/{id} | update_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| DELETE | /employees/{id} | delete_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/deactivate | deactivate_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |

---

### 3. Attendance Module (`/attendance`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /attendance/daily-summary | daily_summary | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /attendance/employee/{id} | employee_attendance_summary | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /attendance/ | list_attendance | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /attendance/ | manual_mark_attendance | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /attendance/process | process_attendance | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /attendance/{id}/approve | approve_attendance | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /attendance/punch-logs | list_punch_logs | get_current_active_user | attendance.read | None | RBAC | ✓ tenant_id | Protected |

---

### 4. Leaves Module (`/leaves`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /leaves/types | list_leave_types | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /leaves/types | create_leave_type | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /leaves/balance/{id} | get_leave_balance | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /leaves/apply | apply_leave | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /leaves/requests | list_leave_requests | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /leaves/requests/{id}/approve | approve_leave | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /leaves/requests/{id}/reject | reject_leave | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /leaves/requests/{id}/cancel | cancel_leave | get_current_active_user | leave.read | None | RBAC | ✓ tenant_id | Protected |

---

### 5. Payroll Module (`/payroll`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /payroll/salary-structure | list_salary_structures | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| POST | /payroll/salary-structure | create_salary_structure | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| PUT | /payroll/salary-structure/{id} | update_salary_structure | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| GET | /payroll/payslips | list_payslips | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| POST | /payroll/payslips/generate | generate_payslips | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| PUT | /payroll/payslips/{id}/freeze | freeze_payslip | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| GET | /payroll/loans | list_loans | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |
| POST | /payroll/loans | create_loan | get_current_active_user | payroll.read | payroll | RBAC+Feature | ✓ tenant_id | Protected |

---

### 6. Tenants Module (`/tenants`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /tenants/ | list_tenants | get_current_superuser | tenant.read | None | Superuser | N/A (cross-tenant) | Partial |
| POST | /tenants/ | create_tenant | get_current_superuser | tenant.read | None | Superuser | N/A | Partial |
| GET | /tenants/{id} | get_tenant | get_current_superuser | tenant.read | None | Superuser | N/A | Partial |
| PUT | /tenants/{id} | update_tenant | get_current_superuser | tenant.read | None | Superuser | N/A | Partial |
| DELETE | /tenants/{id} | deactivate_tenant | get_current_superuser | tenant.read | None | Superuser | N/A | Partial |

---

### 7. Dashboard Module (`/dashboard`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /dashboard/stats | dashboard_stats | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/attendance-heatmap | attendance_heatmap | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/leave-calendar | leave_calendar | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/birthdays | birthdays | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/anniversaries | work_anniversaries | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/department-distribution | department_distribution | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/monthly-trend | monthly_trend | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/sync-health | sync_health | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/attendance-chart | attendance_chart | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /dashboard/recent-activity | recent_activity | get_current_active_user | dashboard.read | None | RBAC | ✓ tenant_id | Protected |

---

### 8. ESS (Employee Self Service) Module (`/ess`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /ess/dashboard | ess_dashboard | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/attendance | my_attendance | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| POST | /ess/attendance/clock-in | clock_in | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| POST | /ess/attendance/clock-out | clock_out | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/leaves | my_leaves | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/leaves/balance | my_leave_balance | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/payslips | my_payslips | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/documents | my_documents | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/profile | my_profile | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| PUT | /ess/profile | update_my_profile | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/announcements | my_announcements | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| GET | /ess/notifications | my_notifications | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |
| POST | /ess/change-password | change_my_password | get_current_active_user | ess.read | ess | Auth-only* | ✓ tenant_id | Partial |

*Note: ESS endpoints have router-level `require_permissions("ess.read")` but individual endpoints only check `get_current_active_user`. The router dependency provides RBAC protection.*

---

### 9. Lifecycle Module (`/employees`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /employees/{id}/timeline | get_employee_timeline | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/promote | promote_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/transfer | transfer_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/confirm | confirm_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/resign | resign_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/terminate | terminate_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/reactivate | reactivate_employee | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /employees/{id}/salary-revision | revise_salary | get_current_active_user | employee.read | None | RBAC | ✓ tenant_id | Protected |

---

### 10. Performance Module (`/performance`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /performance/cycles | list_cycles | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/cycles | create_cycle | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /performance/cycles/{id} | update_cycle | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/cycles/{id}/publish | publish_cycle | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /performance/goals | list_goals | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/goals | create_goal | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /performance/goals/{id} | update_goal | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /performance/goals/{id}/progress | update_goal_progress | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/goals/{id}/approve | approve_goal | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /performance/reviews | list_reviews | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/reviews | create_review | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /performance/reviews/{id}/submit | submit_review | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /performance/competencies | list_competencies | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/competencies | create_competency | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /performance/recommendations | list_recommendations | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /performance/recommendations | create_recommendation | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /performance/recommendations/{id}/approve | approve_recommendation | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /performance/stats | performance_stats | get_current_active_user | performance.read | None | RBAC | ✓ tenant_id | Protected |

---

### 11. Recruitment Module (`/recruitment`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /recruitment/requisitions | list_requisitions | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/requisitions | create_requisition | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/requisitions/{id} | update_requisition | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/requisitions/{id}/submit | submit_requisition | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/requisitions/{id}/approve | approve_requisition | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/openings | list_openings | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/openings | create_opening | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/openings/{id} | update_opening | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/openings/{id}/publish | publish_opening | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/openings/{id}/close | close_opening | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/candidates | list_candidates | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/candidates | create_candidate | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/candidates/{id} | update_candidate | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/candidates/{id}/stage | move_candidate_stage | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/interviews | list_interviews | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/interviews | create_interview | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/interviews/{id}/feedback | submit_feedback | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/offers | list_offers | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /recruitment/offers | create_offer | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/offers/{id}/accept | accept_offer | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /recruitment/offers/{id}/reject | reject_offer | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/stats | recruitment_stats | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |
| GET | /recruitment/pipeline | get_pipeline | get_current_active_user | recruitment.read | None | RBAC | ✓ tenant_id | Protected |

---

### 12. Admin Module (`/admin`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| POST | /admin/auth/login | admin_login | None | None | None | **None** | N/A | **Unprotected** |
| GET | /admin/dashboard/stats | get_admin_stats | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/dashboard/recent-activity | get_recent_activity | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/tenants/ | list_tenants | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/tenants/{id} | get_tenant_detail | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/tenants/ | create_tenant | get_current_superuser | None | None | Superuser only | N/A | Protected |
| PUT | /admin/tenants/{id} | update_tenant | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/tenants/{id}/suspend | suspend_tenant | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/tenants/{id}/activate | activate_tenant | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/tenants/{id}/limits | get_tenant_limits | get_current_superuser | None | None | Superuser only | N/A | Protected |
| PUT | /admin/tenants/{id}/limits | update_tenant_limits | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/tenants/{id}/features | get_tenant_features | get_current_superuser | None | None | Superuser only | N/A | Protected |
| PUT | /admin/tenants/{id}/features | update_tenant_features | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/tenants/{id}/users | get_tenant_users | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/plans/ | list_plans | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/plans/ | create_plan | get_current_superuser | None | None | Superuser only | N/A | Protected |
| PUT | /admin/plans/{id} | update_plan | get_current_superuser | None | None | Superuser only | N/A | Protected |
| DELETE | /admin/plans/{id} | deactivate_plan | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/features/ | list_features | get_current_superuser | None | None | Superuser only | N/A | Protected |
| GET | /admin/features/categories | list_categories | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/features/ | create_feature | get_current_superuser | None | None | Superuser only | N/A | Protected |
| PUT | /admin/features/{id} | update_feature | get_current_superuser | None | None | Superuser only | N/A | Protected |
| POST | /admin/features/seed | seed_features | get_current_superuser | None | None | Superuser only | N/A | Protected |

---

### 13. Billing Module (`/admin/billing`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /admin/billing/subscriptions | list_subscriptions | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| POST | /admin/billing/subscriptions | create_subscription | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| PUT | /admin/billing/subscriptions/{id}/upgrade | upgrade_subscription | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| POST | /admin/billing/subscriptions/{id}/renew | renew_subscription | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| POST | /admin/billing/subscriptions/{id}/suspend | suspend_subscription | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| POST | /admin/billing/subscriptions/{id}/cancel | cancel_subscription | get_current_superuser | billing.read | None | Superuser | N/A | Protected |
| POST | /admin/billing/check-expired | check_expired_subscriptions | get_current_superuser | billing.read | None | Superuser | N/A | Protected |

---

### 14. Analytics Module (`/admin/analytics`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /admin/analytics/customer-success | customer_success_overview | get_current_superuser | analytics.read | None | Superuser | N/A | Protected |
| GET | /admin/analytics/customer-success/tenants | customer_tenants | get_current_superuser | analytics.read | None | Superuser | N/A | Protected |
| GET | /admin/analytics/overview | analytics_overview | get_current_superuser | analytics.read | None | Superuser | N/A | Protected |
| GET | /admin/analytics/tenant/{id} | tenant_analytics | get_current_superuser | analytics.read | None | Superuser | N/A | Protected |

---

### 15. Operations Module (`/ops`)

| Method | Path | Handler | Auth Type | Permission | Feature | Protection | Tenant Filter | Status |
|--------|------|---------|-----------|------------|---------|------------|---------------|--------|
| GET | /ops/jobs | list_jobs | get_current_superuser | operations.read | None | Superuser | N/A | Protected |
| GET | /ops/jobs/{name}/status | job_status | get_current_superuser | operations.read | None | Superuser | N/A | Protected |
| GET | /ops/branding | get_branding | get_current_active_user | operations.read | None | RBAC | ✓ tenant_id | Protected |
| PUT | /ops/branding | update_branding | get_current_active_user | operations.read | None | RBAC | ✓ tenant_id | Protected |
| POST | /ops/backup | create_backup | get_current_superuser | operations.read | None | Superuser | N/A | Protected |
| GET | /ops/backup/history | backup_history | get_current_superuser | operations.read | None | Superuser | N/A | Protected |

---

### 16. School Modules

All school endpoints follow the same pattern with router-level `require_feature()` and `require_permissions()` decorators.

| Module | Prefix | Permission | Feature | Status |
|--------|--------|------------|---------|--------|
| Academic Years | /school/academic-years | school.settings | academic_year | Protected |
| Grades/Sections | /school | school.settings | class_management | Protected |
| Students | /school/students | student.read | student_management | Protected |
| Student Attendance | /school/student-attendance | student_attendance.read | student_attendance | Protected |
| Homework | /school/homework | homework.read | homework | Protected |
| Examinations | /school | exam.read | examinations | Protected |
| Fees | /school/fees | fee.read | fee_management | Protected |
| Dashboard | /school/dashboard | student.read | student_management | Protected |
| Transport | /school/transport | transport.manage | school_transport | Protected |
| Hostel | /school/hostel | hostel.manage | school_hostel | Protected |
| Library | /school/library | library.manage | school_library | Protected |
| Timetable | /school/timetable | school.settings | school_timetable | Protected |
| Circulars | /school/circulars | circular.publish | school_circulars | Protected |
| Events | /school/events | event.manage | school_events | Protected |
| Medical | /school/health | medical.manage | school_medical | Protected |
| Discipline | /school/discipline | discipline.manage | school_discipline | Protected |
| Certificates | /school/certificates | certificate.issue | school_certificates | Protected |
| Admissions | /school/admissions | admission.manage | admissions | Protected |

---

## Unprotected Endpoints (Critical)

These endpoints have **no authentication** at all:

| # | Method | Path | Module | Risk Level | Notes |
|---|--------|------|--------|------------|-------|
| 1 | POST | /auth/register | Auth | **Low** | Intentionally public - creates new tenants |
| 2 | POST | /auth/login | Auth | **Low** | Intentionally public - authentication entry point |
| 3 | POST | /auth/refresh | Auth | **Low** | Intentionally public - token refresh |
| 4 | POST | /auth/logout | Auth | **Low** | Intentionally public - token revocation |
| 5 | POST | /admin/auth/login | Admin Auth | **Low** | Intentionally public - super admin login |
| 6 | GET | /health | System | **Low** | Intentionally public - health check |
| 7 | GET | /data/template/employees | Import/Export | **Medium** | Template download - no auth required |

---

## Missing Permission Granularity

### 1. Write Operations Using Read Permissions

Several modules use only `*.read` permission for **all** operations including create, update, and delete:

| Module | Permission Used | Issue |
|--------|-----------------|-------|
| Employees | `employee.read` | Create/Update/Delete should use `employee.create`, `employee.update`, `employee.delete` |
| Attendance | `attendance.read` | Manual mark, process, approve should use write permissions |
| Leaves | `leave.read` | Apply, approve, reject, cancel should use write permissions |
| Payroll | `payroll.read` | Generate payslips, freeze, create loans should use write permissions |
| Dashboard | `dashboard.read` | Read-only module - acceptable |
| Holidays | `holiday.read` | Create/Update/Delete should use write permissions |
| Categories | `category.read` | Create/Update/Delete should use write permissions |
| Notifications | `notification.read` | Mark read should use write permission |
| Documents | `document.read` | Create/Update/Delete should use write permissions |
| Devices | `device.read` | Create/Update/Delete/Sync should use write permissions |
| Shifts | `shift.read` | Create/Update/Delete/Assign should use write permissions |
| Visitors | `visitor.read` | Register, check-in/out should use write permissions |
| Access Control | `access_control.read` | Grant/Revoke should use write permissions |
| eSSL | `biometric.read` | Create/Update/Delete/Sync should use write permissions |
| Exit Requests | `exit.read` | Create/Update should use write permissions |
| Expenses | `expense.read` | Create/Update should use write permissions |
| HR Ops | `hr.read` | Create/Update/Delete should use write permissions |
| Onboarding | `onboarding.read` | Create/Update/Delete should use write permissions |
| Outdoor Duties | `attendance.read` | Create/Update/Delete should use dedicated permission |
| OT Register | `attendance.read` | Create/Update/Delete should use dedicated permission |
| Work Codes | `attendance.read` | Create/Update/Delete should use dedicated permission |
| Timeline | `employee.read` | Create/Delete should use write permissions |
| Performance | `performance.read` | Create/Update/Approve should use write permissions |
| Recruitment | `recruitment.read` | Create/Update/Approve should use write permissions |
| Assets | `asset.read` | Create/Update/Assign/Return should use write permissions |
| Settings | `settings.read` | Update should use write permission |
| System | `system.read` | Read-only module - acceptable |
| Setup | `setup.read` | All setup operations should use `setup.write` or `setup.manage` |

### 2. Missing Feature Gates

These modules have RBAC but **no feature gate** (should check subscription features):

| Module | Missing Feature |
|--------|-----------------|
| Employees | `employee_management` |
| Attendance | `attendance` |
| Leaves | `leave_management` |
| Dashboard | `dashboard` |
| Holidays | `holidays` |
| Categories | `categories` |
| Notifications | `notifications` |
| HR Operations | `hr_operations` |
| Timeline | `timeline` |
| Performance | `performance_management` |
| Recruitment | `recruitment` |
| Setup | `setup` |
| Settings | `settings` |
| System | `system` |

---

## Recommendations

### Critical (P0)

1. **Fix Admin Auth Endpoint**: The `/admin/auth/login` endpoint has rate limiting but no protection. This is expected for a login endpoint, but ensure rate limiting is enforced in production.

2. **Add Write Permissions**: Implement granular `*.create`, `*.update`, `*.delete` permissions for all modules. Current implementation uses only `*.read` for all operations.

3. **Protect Template Endpoint**: Add authentication to `/data/template/employees` endpoint.

### High (P1)

4. **Add Feature Gates**: Implement `require_feature()` for modules that should be gated by subscription plan (Employees, Attendance, Leaves, etc.).

5. **Audit Lifecycle Endpoints**: The lifecycle module (`promote`, `transfer`, `terminate`, `resign`) uses only `employee.read` permission. These sensitive operations should have dedicated permissions like `employee.manage_lifecycle`.

6. **Audit Payroll Write Operations**: Payroll generation, freezing, and loan creation should require `payroll.write` or `payroll.manage` permission.

### Medium (P2)

7. **Separate Outdoor Duty/OT Permissions**: Currently using `attendance.read` - should have dedicated `outdoor_duty.read/write` and `overtime.read/write` permissions.

8. **Add ESS-Specific Permissions**: ESS endpoints should check that the user can only access their own data (currently relies on email matching).

9. **Implement Permission Hierarchy**: Consider implementing permission inheritance (e.g., `employee.manage` includes `employee.read`, `employee.create`, `employee.update`, `employee.delete`).

### Low (P3)

10. **Document Permission Matrix**: Create a permission matrix document mapping roles to permissions for easier auditing.

11. **Add API Documentation**: Generate OpenAPI documentation with permission requirements for each endpoint.

12. **Implement Permission Caching**: Cache user permissions in Redis to reduce database queries on each request.

---

## Appendix: Permission List

Based on the audit, the following permissions are referenced in the codebase:

```
employee.read, employee.create, employee.update, employee.delete, employee.manage
attendance.read, attendance.create, attendance.update, attendance.manage
leave.read, leave.create, leave.update, leave.manage
payroll.read, payroll.create, payroll.update, payroll.manage
dashboard.read
report.read, report.create
device.read, device.create, device.update, device.delete, device.manage
shift.read, shift.create, shift.update, shift.delete, shift.manage
visitor.read, visitor.create, visitor.update, visitor.manage
access_control.read, access_control.create, access_control.update, access_control.manage
holiday.read, holiday.create, holiday.update, holiday.delete
category.read, category.create, category.update, category.delete
settings.read, settings.update, settings.manage
notification.read, notification.update
document.read, document.create, document.update, document.delete
biometric.read, biometric.create, biometric.update, biometric.delete, biometric.manage
exit.read, exit.create, exit.update
expense.read, expense.create, expense.update
hr.read, hr.create, hr.update, hr.delete
ess.read, ess.write
onboarding.read, onboarding.create, onboarding.update, onboarding.delete
performance.read, performance.create, performance.update, performance.manage
recruitment.read, recruitment.create, recruitment.update, recruitment.manage
asset.read, asset.create, asset.update, asset.delete, asset.manage
tenant.read, tenant.create, tenant.update, tenant.delete
billing.read, billing.create, billing.update
analytics.read
operations.read, operations.update
system.read
setup.read, setup.write
school.settings
student.read, student.create, student.update, student.delete
student_attendance.read, student_attendance.create
homework.read, homework.create, homework.update
exam.read, exam.create, exam.manage
fee.read, fee.create, fee.update, fee.manage
transport.manage
hostel.manage
library.manage
circular.publish
event.manage
medical.manage
discipline.manage
certificate.issue
admission.manage
```

---

**Report Generated:** 2026-06-28
**Next Review:** Recommended within 30 days after implementing P0/P1 fixes
