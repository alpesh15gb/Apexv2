# Apex HRMS — Database Module Map

> **Audit Date**: 2026-06-28
> **Total Tables**: 142
> **Database**: PostgreSQL (UUID primary keys, JSONB columns)
> **Tenant Isolation**: Shared-database, shared-schema with `tenant_id` FK on every business table

---

## Architecture Overview

### Base Classes (`app/db/base.py`)

| Mixin | Purpose |
|-------|---------|
| `UUIDPrimaryKeyMixin` | `id UUID PK` with `gen_random_uuid()` default |
| `TimestampMixin` | `created_at`, `updated_at` with auto-update |
| `TenantMixin` | `tenant_id UUID FK → tenants.id CASCADE` |
| `BaseModel` | Abstract: UUID + Timestamps (for global tables) |
| `TenantModel` | Abstract: UUID + Timestamps + TenantMixin (for tenant-scoped tables) |

### Tenant Types
- `corporate` — HRMS features (employees, attendance, payroll, recruitment, etc.)
- `school` — School ERP features (students, fees, exams, timetable, etc.)

### Global Tables (NOT tenant-scoped)
- `feature_flags` — Global feature definitions
- `subscription_plans` — Global plan catalog
- `super_admin_logs` — Platform-wide audit trail

---

## 1. Core Tables (15 tables)

Shared infrastructure used by both corporate and school tenants.

### 1.1 Tenant Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 1 | `tenants` | `Tenant` | name, slug, domain, tenant_type, subscription_plan, subscription_status, is_active, max_employees, settings (JSONB), company_code, gst_number, pan_number, currency, timezone | — | ✗ (root) |
| 2 | `tenant_settings` | `TenantSettings` | attendance_year_start_month/day, min_punch_difference_minutes, punch_begin_before_minutes, auto_shift_if_no_schedule, fixed_shift_mode | tenant_id → tenants | ✓ |

### 1.2 User & Access Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 3 | `users` | `User` | email, hashed_password, full_name, phone, is_active, is_superuser, last_login_at, must_change_password, failed_login_attempts, locked_until | tenant_id → tenants | ✓ |
| 4 | `roles` | `Role` | name, description, is_system_role | tenant_id → tenants | ✓ |
| 5 | `permissions` | `Permission` | name, codename, module | tenant_id → tenants | ✓ |
| 6 | `user_roles` | `UserRole` (assoc) | user_id, role_id, tenant_id | user_id → users, role_id → roles, tenant_id → tenants | ✓ |
| 7 | `role_permissions` | `RolePermission` (assoc) | role_id, permission_id, tenant_id | role_id → roles, permission_id → permissions, tenant_id → tenants | ✓ |

### 1.3 Subscription & Feature Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 8 | `subscription_plans` | `SubscriptionPlan` | name, code, price_monthly/quarterly/annual, max_employees/branches/devices, features (JSONB), is_active | — | ✗ (global) |
| 9 | `tenant_subscriptions` | `TenantSubscription` | plan_id, start_date, end_date, status, billing_cycle, payment_status, auto_renewal | tenant_id → tenants, plan_id → subscription_plans | ✓ |
| 10 | `resource_limits` | `ResourceLimit` | resource_key, max_value, current_value, is_unlimited | tenant_id → tenants | ✓ |
| 11 | `feature_flags` | `FeatureFlag` | name, code, module, category, is_active | — | ✗ (global) |
| 12 | `tenant_features` | `TenantFeature` | feature_id, is_enabled, enabled_at, config | tenant_id → tenants, feature_id → feature_flags | ✓ |

### 1.4 Audit & History

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 13 | `audit_logs` | `AuditLog` | action, resource_type, resource_id, old_values (JSONB), new_values (JSONB), ip_address | tenant_id → tenants, user_id → users | ✓ |
| 14 | `login_history` | `LoginHistory` | email, ip_address, user_agent, device_type, location, login_at, is_successful, failure_reason | tenant_id → tenants, user_id → users | ✓ |
| 15 | `super_admin_logs` | `SuperAdminLog` | admin_user_id, action, target_type, target_id, old_value, new_value, ip_address | admin_user_id → users | ✗ (global) |

---

## 2. Corporate Tables (72 tables)

HRMS-specific tables for corporate tenants.

### 2.1 Organization Structure

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 16 | `departments` | `Department` | name, code, is_active | tenant_id → tenants | ✓ |
| 17 | `designations` | `Designation` | name, code, is_active | tenant_id → tenants | ✓ |
| 18 | `branches` | `Branch` | name, code, is_active | tenant_id → tenants | ✓ |
| 19 | `employees` | `Employee` | employee_code, first_name, last_name, email, phone, joining_date, date_of_birth, gender, status, device_user_id | tenant_id → tenants, department_id → departments, designation_id → designations, branch_id → branches, shift_id → shifts, category_id → employee_categories, shift_group_id → shift_groups, shift_roster_id → shift_rosters | ✓ |
| 20 | `employee_categories` | `EmployeeCategory` | name, code, ot_formula, min/max_ot_minutes, grace_minutes, half_day_threshold_minutes, weekly_off_1/2 | tenant_id → tenants | ✓ |

### 2.2 Shift Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 21 | `shifts` | `Shift` | name, start_time, end_time, grace_period_minutes, late_rule_minutes, early_rule_minutes, overtime_threshold_minutes, is_night_shift | tenant_id → tenants | ✓ |
| 22 | `shift_schedules` | `ShiftSchedule` | employee_id, shift_id, effective_from, effective_to, day_of_week | tenant_id → tenants, employee_id → employees, shift_id → shifts | ✓ |
| 23 | `shift_groups` | `ShiftGroup` | name, description, is_active | tenant_id → tenants | ✓ |
| 24 | `shift_group_members` | `ShiftGroupMember` | group_id, shift_id | tenant_id → tenants, group_id → shift_groups, shift_id → shifts | ✓ |
| 25 | `shift_rosters` | `ShiftRoster` | name, rotation_pattern, weekly_off_1/2, is_active | tenant_id → tenants | ✓ |
| 26 | `shift_roster_entries` | `ShiftRosterEntry` | roster_id, day_number, shift_id | tenant_id → tenants, roster_id → shift_rosters, shift_id → shifts | ✓ |
| 27 | `department_shifts` | `DepartmentShift` | department_id, shift_id, effective_from, effective_to | tenant_id → tenants, department_id → departments, shift_id → shifts | ✓ |

### 2.3 Device Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 28 | `devices` | `Device` | serial_number, device_name, model, firmware_version, ip_address, port, location, status, device_type, communication_mode | tenant_id → tenants, branch_id → branches | ✓ |
| 29 | `device_logs` | `DeviceLog` | device_id, log_type, message, raw_data (JSONB) | tenant_id → tenants, device_id → devices | ✓ |
| 30 | `device_commands` | `DeviceCommand` | device_id, command_type, parameters (JSONB), status, requested_at, response_data (JSONB) | tenant_id → tenants, device_id → devices, requested_by → users | ✓ |

### 2.4 Attendance Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 31 | `attendances` | `Attendance` | employee_id, date, punch_in, punch_out, total_hours, overtime_hours, status, is_late, late_minutes, is_early_out, early_out_minutes, is_manual | tenant_id → tenants, employee_id → employees, shift_id → shifts, approved_by → employees | ✓ |
| 32 | `punch_logs` | `PunchLog` | employee_id, device_id, punch_time, punch_type, source, raw_data | tenant_id → tenants, employee_id → employees, device_id → devices | ✓ |
| 33 | `attendance_raw_logs` | `AttendanceRawLog` | essl_server_id, employee_code, employee_id, device_serial, device_id, punch_time, punch_type, raw_data (JSONB), processed, processed_at | tenant_id → tenants, essl_server_id → essl_servers, employee_id → employees, device_id → devices | ✓ |

### 2.5 Leave Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 34 | `leave_types` | `LeaveType` | name, code, default_days, is_paid, carry_forward, max_consecutive | tenant_id → tenants | ✓ |
| 35 | `leave_balances` | `LeaveBalance` | employee_id, leave_type_id, year, total_days, used_days, pending_days, carried_forward | tenant_id → tenants, employee_id → employees, leave_type_id → leave_types | ✓ |
| 36 | `leave_requests` | `LeaveRequest` | employee_id, leave_type_id, start_date, end_date, total_days, reason, status, approved_at | tenant_id → tenants, employee_id → employees, leave_type_id → leave_types, approved_by → employees | ✓ |

### 2.6 Holiday Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 37 | `holidays` | `Holiday` | name, date, type, description, is_active | tenant_id → tenants | ✓ |

### 2.7 Visitor Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 38 | `visitors` | `Visitor` | name, phone, email, id_proof_type, id_proof_number, company | tenant_id → tenants | ✓ |
| 39 | `visitor_passes` | `VisitorPass` | visitor_id, host_employee_id, purpose, expected_date, check_in_time, check_out_time, pass_number, status, badge_number, zone_access (JSONB) | tenant_id → tenants, visitor_id → visitors, host_employee_id → employees | ✓ |

### 2.8 Access Control

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 40 | `access_zones` | `AccessZone` | name, description, branch_id, is_restricted, access_level_required | tenant_id → tenants, branch_id → branches | ✓ |
| 41 | `doors` | `Door` | name, zone_id, device_id, is_active | tenant_id → tenants, zone_id → access_zones, device_id → devices | ✓ |
| 42 | `user_access_levels` | `UserAccessLevel` | employee_id, zone_id, access_level, granted_by, valid_from, valid_to | tenant_id → tenants, employee_id → employees, zone_id → access_zones, granted_by → employees | ✓ |
| 43 | `access_logs` | `AccessLog` | employee_id, visitor_id, visitor_pass_id, door_id, access_time, access_type, granted, denial_reason | tenant_id → tenants, employee_id → employees, visitor_id → visitors, visitor_pass_id → visitor_passes, door_id → doors | ✓ |

### 2.9 Notification System

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 44 | `notifications` | `Notification` | user_id, title, message, notification_type, channel, status, sent_at, read_at, metadata_ (JSONB) | tenant_id → tenants, user_id → users | ✓ |
| 45 | `notification_templates` | `NotificationTemplate` | name, event_type, channel, subject_template, body_template, is_active | tenant_id → tenants | ✓ |

### 2.10 Approval Workflows

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 46 | `approval_workflows` | `ApprovalWorkflow` | name, entity_type, description, is_active, auto_approve_hours | tenant_id → tenants | ✓ |
| 47 | `approval_steps` | `ApprovalStep` | workflow_id, step_order, name, approver_type, approver_role_id, approver_user_id, is_parallel, is_required | tenant_id → tenants, workflow_id → approval_workflows, approver_role_id → roles, approver_user_id → users | ✓ |
| 48 | `approval_requests` | `ApprovalRequest` | workflow_id, entity_type, entity_id, requester_id, current_step, status, remarks | tenant_id → tenants, workflow_id → approval_workflows, requester_id → users | ✓ |
| 49 | `approval_history` | `ApprovalHistory` | request_id, step_order, approver_id, action, remarks, acted_at | tenant_id → tenants, request_id → approval_requests, approver_id → users | ✓ |

### 2.11 Announcements & Polls

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 50 | `announcements` | `Announcement` | title, body, priority, publish_at, expires_at, is_active, created_by | tenant_id → tenants, created_by → users | ✓ |
| 51 | `polls` | `Poll` | question, options (JSONB), expires_at, is_anonymous, is_active, created_by | tenant_id → tenants, created_by → users | ✓ |
| 52 | `poll_responses` | `PollResponse` | poll_id, employee_id, selected_option | tenant_id → tenants, poll_id → polls, employee_id → employees | ✓ |

### 2.12 Benefits & Compensation

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 53 | `benefits` | `Benefit` | name, type, amount, frequency, is_taxable, is_active | tenant_id → tenants | ✓ |
| 54 | `employee_benefits` | `EmployeeBenefit` | employee_id, benefit_id, amount, effective_from, is_active | tenant_id → tenants, employee_id → employees, benefit_id → benefits | ✓ |

### 2.13 Document Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 55 | `documents` | `Document` | employee_id, doc_type, title, file_path, file_name, file_size, mime_type, uploaded_by, is_confidential, expiry_date | tenant_id → tenants, employee_id → employees, uploaded_by → users | ✓ |

### 2.14 Exit Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 56 | `exit_requests` | `ExitRequest` | employee_id, resignation_date, last_working_date, reason, status, approved_by, exit_interview_notes, clearance_status | tenant_id → tenants, employee_id → employees, approved_by → employees | ✓ |

### 2.15 Expense Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 57 | `expense_categories` | `ExpenseCategory` | name, code, description, is_active | tenant_id → tenants | ✓ |
| 58 | `expense_claims` | `ExpenseClaim` | employee_id, category_id, amount, date, description, receipt_path, status, approved_by | tenant_id → tenants, employee_id → employees, category_id → expense_categories, approved_by → employees | ✓ |

### 2.16 Onboarding

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 59 | `onboarding_tasks` | `OnboardingTask` | employee_id, title, description, assigned_to, due_date, status, completed_at, order_index | tenant_id → tenants, employee_id → employees, assigned_to → employees | ✓ |

### 2.17 Overtime & Outdoor Duty

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 60 | `ot_register` | `OTRegister` | employee_id, date, ot_hours, ot_type, status, approved_by, remarks | tenant_id → tenants, employee_id → employees, approved_by → employees | ✓ |
| 61 | `outdoor_duties` | `OutdoorDuty` | employee_id, date, from_time, to_time, reason, location, status, approved_by | tenant_id → tenants, employee_id → employees, approved_by → employees | ✓ |

### 2.18 Payroll

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 62 | `salary_structures` | `SalaryStructure` | employee_id, basic, hra, da, conveyance, medical, special, pf_employee, pf_employer, esi_employee, esi_employer, professional_tax, income_tax, effective_from | tenant_id → tenants, employee_id → employees | ✓ |
| 63 | `pay_slips` | `PaySlip` | employee_id, month, year, basic, hra, da, gross_earnings, pf, esi, pt, it, total_deductions, net_pay, working_days, present_days, absent_days, leave_days, ot_hours, lop_days, status | tenant_id → tenants, employee_id → employees | ✓ |
| 64 | `loans` | `Loan` | employee_id, loan_type, amount, emi_amount, start_date, total_installments, paid_installments, status | tenant_id → tenants, employee_id → employees | ✓ |

### 2.19 Performance Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 65 | `review_cycles` | `ReviewCycle` | name, cycle_type, start_date, end_date, self/manager/hr_review_due, status, created_by | tenant_id → tenants, created_by → users | ✓ |
| 66 | `goals` | `Goal` | employee_id, cycle_id, title, goal_type, category, weightage, target_value, current_value, progress, due_date, status | tenant_id → tenants, employee_id → employees, cycle_id → review_cycles, approved_by → users | ✓ |
| 67 | `performance_reviews` | `PerformanceReview` | cycle_id, employee_id, reviewer_id, review_type, status, rating, strengths, improvements, comments, goals_achievement | tenant_id → tenants, cycle_id → review_cycles, employee_id → employees, reviewer_id → users | ✓ |
| 68 | `competencies` | `Competency` | name, description, category, is_active, sort_order | tenant_id → tenants | ✓ |
| 69 | `performance_recommendations` | `PerformanceRecommendation` | review_id, employee_id, recommended_by, recommendation_type, details, salary_increment, new_designation_id, status | tenant_id → tenants, review_id → performance_reviews, employee_id → employees, recommended_by → users, new_designation_id → designations | ✓ |

### 2.20 Recruitment (ATS)

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 70 | `job_requisitions` | `JobRequisition` | title, department_id, branch_id, hiring_manager_id, employment_type, openings, experience_min/max, salary_min/max, skills, status | tenant_id → tenants, department_id → departments, branch_id → branches, hiring_manager_id → users, approved_by → users | ✓ |
| 71 | `job_openings` | `JobOpening` | requisition_id, title, department_id, branch_id, description, requirements, employment_type, openings, salary_min/max, location, status | tenant_id → tenants, requisition_id → job_requisitions, department_id → departments, branch_id → branches, created_by → users | ✓ |
| 72 | `candidates` | `Candidate` | opening_id, first_name, last_name, email, phone, resume_path, skills, experience_years, education, current_company, expected_salary, notice_period, source, stage, rating | tenant_id → tenants, opening_id → job_openings | ✓ |
| 73 | `interviews` | `Interview` | candidate_id, opening_id, interviewer_id, scheduled_at, duration_minutes, location, meeting_link, interview_type, status, feedback, rating, recommendation | tenant_id → tenants, candidate_id → candidates, opening_id → job_openings, interviewer_id → users | ✓ |
| 74 | `offers` | `Offer` | candidate_id, opening_id, offered_salary, offered_designation, offered_department_id, joining_date, expiry_date, status, offer_letter_path | tenant_id → tenants, candidate_id → candidates, opening_id → job_openings, offered_department_id → departments, created_by → users | ✓ |

### 2.21 Tax

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 75 | `tax_declarations` | `TaxDeclaration` | employee_id, financial_year, hra_received, rent_paid, section_80c, section_80d, home_loan_interest, other_exemptions, status | tenant_id → tenants, employee_id → employees | ✓ |

### 2.22 Timeline & Assets

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 76 | `employee_events` | `EmployeeEvent` | employee_id, event_type, title, description, event_date, created_by | tenant_id → tenants, employee_id → employees, created_by → users | ✓ |
| 77 | `work_codes` | `WorkCode` | code, name, description, is_active | tenant_id → tenants | ✓ |
| 78 | `company_assets` | `CompanyAsset` | name, asset_code, category, serial_number, purchase_date, warranty_expiry, assigned_to, status | tenant_id → tenants, assigned_to → employees | ✓ |
| 79 | `travel_requests` | `TravelRequest` | employee_id, destination, purpose, from_date, to_date, estimated_cost, status, approved_by | tenant_id → tenants, employee_id → employees, approved_by → employees | ✓ |

### 2.23 eSSL Biometric Integration

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 80 | `essl_servers` | `EsslServer` | name, server_url, username, password_encrypted, timeout_seconds, timezone, auto_sync_enabled, attendance/device/employee_sync intervals, employee/device_conflict_policy, status | tenant_id → tenants | ✓ |
| 81 | `essl_sync_history` | `EsslSyncHistory` | essl_server_id, sync_type, status, started_at, completed_at, duration_seconds, records_fetched/created/updated/skipped/failed, progress_percent | tenant_id → tenants, essl_server_id → essl_servers | ✓ |
| 82 | `essl_sync_jobs` | `EsslSyncJob` | essl_server_id, job_type, interval_minutes, scheduled_hour, is_enabled, last_run_at, next_run_at, last_status, consecutive_failures | tenant_id → tenants, essl_server_id → essl_servers | ✓ |
| 83 | `essl_sync_errors` | `EsslSyncError` | sync_history_id, error_code, error_message, entity_type, entity_identifier, raw_data (JSONB) | tenant_id → tenants, sync_history_id → essl_sync_history | ✓ |
| 84 | `essl_employee_mapping` | `EsslEmployeeMapping` | essl_server_id, employee_code, employee_id | tenant_id → tenants, essl_server_id → essl_servers, employee_id → employees | ✓ |
| 85 | `essl_device_mapping` | `EsslDeviceMapping` | essl_server_id, serial_number, device_id | tenant_id → tenants, essl_server_id → essl_servers, device_id → devices | ✓ |
| 86 | `essl_sync_cursor` | `EsslSyncCursor` | essl_server_id, cursor_type, last_transaction_id, last_punch_time, last_employee_sync, last_device_sync | tenant_id → tenants, essl_server_id → essl_servers | ✓ |
| 87 | `essl_locations` | `EsslLocation` | essl_server_id, code, name, description, is_active | tenant_id → tenants, essl_server_id → essl_servers | ✓ |

---

## 3. School Tables (55 tables)

School ERP-specific tables for school tenants.

### 3.1 Academic Structure

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 88 | `academic_years` | `AcademicYear` | name, start_date, end_date, is_current, promotion_date, status | tenant_id → tenants | ✓ |
| 89 | `academic_terms` | `AcademicTerm` | academic_year_id, name, start_date, end_date, sort_order | tenant_id → tenants, academic_year_id → academic_years | ✓ |
| 90 | `school_holidays` | `SchoolHoliday` | academic_year_id, name, date, type | tenant_id → tenants, academic_year_id → academic_years | ✓ |

### 3.2 Campus & Infrastructure

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 91 | `campuses` | `Campus` | branch_id, name, code, address, phone, email, latitude, longitude | tenant_id → tenants, branch_id → branches | ✓ |
| 92 | `buildings` | `Building` | campus_id, name, code, floors | tenant_id → tenants, campus_id → campuses | ✓ |
| 93 | `rooms` | `Room` | building_id, name, room_number, floor, room_type, capacity, has_projector, has_ac | tenant_id → tenants, building_id → buildings | ✓ |

### 3.3 Grade & Section

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 94 | `grades` | `Grade` | name, code, sort_order, is_active | tenant_id → tenants | ✓ |
| 95 | `sections` | `Section` | grade_id, name, capacity, room_id, class_teacher_id, academic_year_id | tenant_id → tenants, grade_id → grades, room_id → rooms, class_teacher_id → employees, academic_year_id → academic_years | ✓ |
| 96 | `houses` | `House` | name, code, color, house_master_id | tenant_id → tenants, house_master_id → employees | ✓ |

### 3.4 Student Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 97 | `students` | `Student` | admission_number, roll_number, first_name, last_name, date_of_birth, gender, blood_group, nationality, aadhaar_number, email, phone, address, admission_date, status, medical_conditions, allergies | tenant_id → tenants, admission_grade_id → grades, current_grade_id → grades, current_section_id → sections, house_id → houses, academic_year_id → academic_years, transport_route_id → transport_routes, hostel_room_id → hostel_rooms | ✓ |
| 98 | `guardians` | `Guardian` | user_id, first_name, last_name, email, phone, occupation, workplace, annual_income | tenant_id → tenants, user_id → users | ✓ |
| 99 | `student_guardians` | `StudentGuardian` | student_id, guardian_id, relationship, is_primary, is_emergency_contact, can_pickup | tenant_id → tenants, student_id → students | ✓ |
| 100 | `student_siblings` | `StudentSibling` | student_id, sibling_id | tenant_id → tenants, student_id → students, sibling_id → students | ✓ |

### 3.5 Subject & Teaching

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 101 | `subjects` | `Subject` | name, code, subject_type, department_id, credits, max_marks, pass_marks, has_practical | tenant_id → tenants, department_id → departments | ✓ |
| 102 | `grade_subjects` | `GradeSubject` | grade_id, subject_id, academic_year_id, is_compulsory, sort_order | tenant_id → tenants, grade_id → grades, subject_id → subjects, academic_year_id → academic_years | ✓ |
| 103 | `teacher_allocations` | `TeacherAllocation` | employee_id, subject_id, section_id, academic_year_id, periods_per_week | tenant_id → tenants, employee_id → employees, subject_id → subjects, section_id → sections, academic_year_id → academic_years | ✓ |

### 3.6 Timetable

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 104 | `period_definitions` | `PeriodDefinition` | name, start_time, end_time, period_type, sort_order | tenant_id → tenants | ✓ |
| 105 | `timetable_entries` | `TimetableEntry` | section_id, subject_id, employee_id, room_id, period_definition_id, day_of_week, academic_year_id | tenant_id → tenants, section_id → sections, subject_id → subjects, employee_id → employees, room_id → rooms, period_definition_id → period_definitions, academic_year_id → academic_years | ✓ |
| 106 | `substitutions` | `Substitution` | original_employee_id, substitute_employee_id, timetable_entry_id, date, reason, status | tenant_id → tenants, original_employee_id → employees, substitute_employee_id → employees, timetable_entry_id → timetable_entries, approved_by → users | ✓ |

### 3.7 Student Attendance

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 107 | `student_attendance` | `StudentAttendance` | student_id, date, status, check_in_time, check_out_time, remarks, marked_by, attendance_type, period_definition_id, academic_year_id | tenant_id → tenants, student_id → students, marked_by → employees, period_definition_id → period_definitions, academic_year_id → academic_years | ✓ |
| 108 | `student_attendance_summary` | `StudentAttendanceSummary` | student_id, academic_year_id, month, year, total_days, present_days, absent_days, late_days, half_days, excused_days | tenant_id → tenants, student_id → students, academic_year_id → academic_years | ✓ |

### 3.8 Homework & Assignments

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 109 | `homework` | `Homework` | section_id, subject_id, employee_id, title, description, due_date, attachment_urls (JSONB), academic_year_id | tenant_id → tenants, section_id → sections, subject_id → subjects, employee_id → employees, academic_year_id → academic_years | ✓ |
| 110 | `homework_submissions` | `HomeworkSubmission` | homework_id, student_id, submitted_at, attachment_urls (JSONB), remarks, marks, grade, status, reviewed_by | tenant_id → tenants, homework_id → homework, student_id → students, reviewed_by → employees | ✓ |
| 111 | `assignments` | `Assignment` | section_id, subject_id, employee_id, title, description, assignment_type, max_marks, rubric (JSONB), due_date, academic_year_id | tenant_id → tenants, section_id → sections, subject_id → subjects, employee_id → employees, academic_year_id → academic_years | ✓ |
| 112 | `assignment_submissions` | `AssignmentSubmission` | assignment_id, student_id, submitted_at, attachment_urls (JSONB), marks, grade, feedback, status, evaluated_by | tenant_id → tenants, assignment_id → assignments, student_id → students, evaluated_by → employees | ✓ |

### 3.9 Examinations

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 113 | `exam_types` | `ExamType` | name, code, weightage, exam_category | tenant_id → tenants | ✓ |
| 114 | `exams` | `Exam` | exam_type_id, academic_year_id, academic_term_id, name, start_date, end_date, status | tenant_id → tenants, exam_type_id → exam_types, academic_year_id → academic_years, academic_term_id → academic_terms | ✓ |
| 115 | `exam_schedules` | `ExamSchedule` | exam_id, subject_id, grade_id, exam_date, start_time, end_time, max_marks, pass_marks, room_ids (JSONB), invigilator_ids (JSONB) | tenant_id → tenants, exam_id → exams, subject_id → subjects, grade_id → grades | ✓ |
| 116 | `exam_marks` | `ExamMark` | exam_schedule_id, student_id, marks_obtained, practical_marks, grade, is_absent, is_exempted, entered_by, verified_by | tenant_id → tenants, exam_schedule_id → exam_schedules, student_id → students, entered_by → employees, verified_by → employees | ✓ |
| 117 | `grading_scales` | `GradingScale` | name, scale_type, is_default | tenant_id → tenants | ✓ |
| 118 | `grading_scale_details` | `GradingScaleDetail` | grading_scale_id, grade, min_percentage, max_percentage, gpa, description, sort_order | tenant_id → tenants, grading_scale_id → grading_scales | ✓ |

### 3.10 Fee Management

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 119 | `fee_categories` | `FeeCategory` | name, code, is_active, sort_order | tenant_id → tenants | ✓ |
| 120 | `fee_structures` | `FeeStructure` | academic_year_id, grade_id, fee_category_id, amount, frequency, due_day, is_mandatory | tenant_id → tenants, academic_year_id → academic_years, grade_id → grades, fee_category_id → fee_categories | ✓ |
| 121 | `student_fees` | `StudentFee` | student_id, fee_structure_id, academic_year_id, amount, discount_amount, scholarship_amount, final_amount, due_date, status | tenant_id → tenants, student_id → students, fee_structure_id → fee_structures, academic_year_id → academic_years | ✓ |
| 122 | `fee_payments` | `FeePayment` | student_id, student_fee_id, amount, payment_date, payment_method, reference_number, receipt_number, collected_by | tenant_id → tenants, student_id → students, student_fee_id → student_fees, collected_by → employees | ✓ |
| 123 | `fee_fine_rules` | `FeeFineRule` | fee_category_id, days_after_due, fine_type, fine_amount, max_fine | tenant_id → tenants, fee_category_id → fee_categories | ✓ |
| 124 | `scholarships` | `Scholarship` | name, scholarship_type, value, max_amount, applicable_fee_categories (JSONB) | tenant_id → tenants | ✓ |
| 125 | `student_scholarships` | `StudentScholarship` | student_id, scholarship_id, academic_year_id, start_date, end_date | tenant_id → tenants, student_id → students, scholarship_id → scholarships, academic_year_id → academic_years | ✓ |

### 3.11 Transport

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 126 | `transport_routes` | `TransportRoute` | name, code, vehicle_number, vehicle_type, capacity, driver_id, helper_id | tenant_id → tenants, driver_id → employees, helper_id → employees | ✓ |
| 127 | `transport_stops` | `TransportStop` | route_id, name, sequence, pickup_time, drop_time, latitude, longitude | tenant_id → tenants, route_id → transport_routes | ✓ |
| 128 | `student_transport` | `StudentTransport` | student_id, route_id, stop_id, academic_year_id, pickup_type, fee_amount | tenant_id → tenants, student_id → students, route_id → transport_routes, stop_id → transport_stops, academic_year_id → academic_years | ✓ |

### 3.12 Hostel

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 129 | `hostels` | `Hostel` | campus_id, name, hostel_type, warden_id, capacity | tenant_id → tenants, campus_id → campuses, warden_id → employees | ✓ |
| 130 | `hostel_rooms` | `HostelRoom` | hostel_id, room_number, floor, room_type, capacity | tenant_id → tenants, hostel_id → hostels | ✓ |
| 131 | `hostel_allocations` | `HostelAllocation` | student_id, hostel_id, room_id, bed_number, academic_year_id, start_date, end_date, status | tenant_id → tenants, student_id → students, hostel_id → hostels, room_id → hostel_rooms, academic_year_id → academic_years | ✓ |

### 3.13 Library

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 132 | `library_books` | `LibraryBook` | isbn, title, author, publisher, category, subject, edition, total_copies, available_copies, shelf_location, barcode, price | tenant_id → tenants | ✓ |
| 133 | `library_transactions` | `LibraryTransaction` | book_id, borrower_type, borrower_id, issue_date, due_date, return_date, fine_amount, fine_paid, issued_by, returned_to, status | tenant_id → tenants, book_id → library_books, issued_by → employees, returned_to → employees | ✓ |

### 3.14 Lesson Planning

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 134 | `lesson_plans` | `LessonPlan` | employee_id, section_id, subject_id, academic_year_id, title, description, unit_number, lesson_number, planned_date, actual_date, duration_periods, learning_objectives, teaching_methods, status, completion_percentage | tenant_id → tenants, employee_id → employees, section_id → sections, subject_id → subjects, academic_year_id → academic_years | ✓ |

### 3.15 Communication

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 135 | `school_events` | `SchoolEvent` | title, description, event_type, start_date, end_date, venue, organizer_id, target_audience (JSONB), is_public | tenant_id → tenants, organizer_id → employees | ✓ |
| 136 | `circulars` | `Circular` | title, content, circular_type, target_audience (JSONB), published_at, published_by | tenant_id → tenants, published_by → employees | ✓ |

### 3.16 Medical & Discipline

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 137 | `health_records` | `HealthRecord` | student_id, record_type, date, description, doctor_name, medication, next_followup, recorded_by | tenant_id → tenants, student_id → students, recorded_by → employees | ✓ |
| 138 | `discipline_incidents` | `DisciplineIncident` | student_id, incident_date, incident_type, severity, description, action_taken, reported_by, parent_informed, status, resolution, resolved_by | tenant_id → tenants, student_id → students, reported_by → employees, resolved_by → employees | ✓ |

### 3.17 Certificates

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 139 | `certificate_templates` | `CertificateTemplate` | name, template_type, template_html, template_json (JSONB), is_default | tenant_id → tenants | ✓ |
| 140 | `issued_certificates` | `IssuedCertificate` | student_id, template_id, certificate_number, issue_date, purpose, issued_by, pdf_url, qr_code | tenant_id → tenants, student_id → students, template_id → certificate_templates, issued_by → employees | ✓ |

### 3.18 Admission

| # | Table | Model | Key Columns | FK Relationships | tenant_id |
|---|-------|-------|-------------|------------------|-----------|
| 141 | `admission_inquiries` | `AdmissionInquiry` | student_name, parent_name, phone, email, grade_applying, academic_year_id, source, status, assigned_to | tenant_id → tenants, academic_year_id → academic_years, assigned_to → employees | ✓ |
| 142 | `admission_applications` | `AdmissionApplication` | inquiry_id, application_number, student_name, date_of_birth, gender, grade_applying, parent_name, parent_phone, documents (JSONB), academic_year_id, status, interview_date, interview_score, student_id | tenant_id → tenants, inquiry_id → admission_inquiries, academic_year_id → academic_years, reviewed_by → employees, student_id → students | ✓ |

---

## 4. Cross-Module Relationships

### 4.1 Core → Corporate Dependencies

| Relationship | Description |
|-------------|-------------|
| `employees.tenant_id` → `tenants.id` | All employees belong to a tenant |
| `employees.department_id` → `departments.id` | Employee → Department |
| `employees.designation_id` → `designations.id` | Employee → Designation |
| `employees.branch_id` → `branches.id` | Employee → Branch |
| `employees.shift_id` → `shifts.id` | Employee → Default Shift |
| `employees.category_id` → `employee_categories.id` | Employee → Attendance Category |
| `users.tenant_id` → `tenants.id` | All users belong to a tenant |
| `user_roles.user_id` → `users.id` | User ↔ Role (M2M) |
| `user_roles.role_id` → `roles.id` | User ↔ Role (M2M) |
| `role_permissions.role_id` → `roles.id` | Role ↔ Permission (M2M) |
| `tenant_features.feature_id` → `feature_flags.id` | Tenant feature enablement |
| `tenant_subscriptions.plan_id` → `subscription_plans.id` | Tenant subscription plan |

### 4.2 Core → School Dependencies

| Relationship | Description |
|-------------|-------------|
| `students.tenant_id` → `tenants.id` | All students belong to a tenant |
| `students.current_grade_id` → `grades.id` | Student → Current Grade |
| `students.current_section_id` → `sections.id` | Student → Current Section |
| `students.house_id` → `houses.id` | Student → House |
| `students.academic_year_id` → `academic_years.id` | Student → Academic Year |
| `campuses.branch_id` → `branches.id` | Campus → Branch (shared with corporate) |
| `sections.class_teacher_id` → `employees.id` | Section → Class Teacher |
| `subjects.department_id` → `departments.id` | Subject → Department (shared with corporate) |

### 4.3 Corporate ↔ School Shared Tables

| Table | Used By | Purpose |
|-------|---------|---------|
| `tenants` | Both | Tenant root record |
| `users` | Both | Authentication & authorization |
| `roles` / `permissions` | Both | RBAC |
| `employees` | Both | Teachers are employees in school context |
| `departments` | Both | Academic departments in school context |
| `branches` | Both | Campus mapping via `campuses.branch_id` |
| `audit_logs` | Both | Shared audit trail |
| `notifications` | Both | Shared notification system |
| `documents` | Both | Shared document storage |

### 4.4 Key FK Chains (Dependency Depth)

```
tenants
├── users → user_roles → roles → role_permissions → permissions
├── employees
│   ├── attendances → shifts
│   ├── punch_logs → devices
│   ├── leave_requests → leave_types
│   ├── salary_structures, pay_slips, loans
│   ├── performance_reviews → review_cycles
│   ├── goals → review_cycles
│   ├── candidates → job_openings → job_requisitions
│   └── exit_requests
├── students
│   ├── student_attendance → academic_years
│   ├── exam_marks → exam_schedules → exams → exam_types
│   ├── student_fees → fee_structures → fee_categories
│   ├── fee_payments → student_fees
│   ├── homework_submissions → homework → subjects
│   ├── student_transport → transport_routes → transport_stops
│   ├── hostel_allocations → hostels, hostel_rooms
│   ├── health_records, discipline_incidents
│   └── issued_certificates → certificate_templates
├── essl_servers
│   ├── essl_sync_history → essl_sync_errors
│   ├── essl_sync_jobs
│   ├── essl_employee_mapping → employees
│   ├── essl_device_mapping → devices
│   ├── essl_sync_cursor
│   └── essl_locations
└── approval_workflows → approval_steps, approval_requests → approval_history
```

---

## 5. Table Count Summary

| Module Group | Table Count | Description |
|-------------|-------------|-------------|
| **Core** | 15 | Tenant, User, RBAC, Subscription, Feature Flags, Audit |
| **Corporate** | 72 | HRMS: Organization, Attendance, Leave, Payroll, Recruitment, Performance, Access Control, eSSL, etc. |
| **School** | 55 | School ERP: Academic, Student, Exam, Fee, Transport, Hostel, Library, Admission, etc. |
| **Total** | **142** | |

---

## 6. Tenant Isolation Summary

| Isolation Pattern | Tables |
|------------------|--------|
| **Has `tenant_id` FK** | 139 tables (all TenantModel subclasses + association tables) |
| **Global (no tenant_id)** | 3 tables: `feature_flags`, `subscription_plans`, `super_admin_logs` |

All 139 tenant-scoped tables use `ON DELETE CASCADE` on the `tenant_id` foreign key, ensuring complete data cleanup when a tenant is deleted.

---

## 7. Unique Constraints (Tenant Scoping Pattern)

Most tenant-scoped tables enforce uniqueness within tenant boundaries:

| Table | Constraint | Columns |
|-------|-----------|---------|
| `users` | `uq_users_tenant_email` | (tenant_id, email) |
| `departments` | `uq_departments_tenant_code` | (tenant_id, code) |
| `designations` | `uq_designations_tenant_code` | (tenant_id, code) |
| `branches` | `uq_branches_tenant_code` | (tenant_id, code) |
| `employees` | `uq_employees_tenant_employee_code` | (tenant_id, employee_code) |
| `employees` | `uq_employees_tenant_email` | (tenant_id, email) |
| `employees` | `uq_employees_tenant_device_user_id` | (tenant_id, device_user_id) |
| `shifts` | `uq_shift_groups_tenant_name` | (tenant_id, name) |
| `devices` | `uq_devices_tenant_serial_number` | (tenant_id, serial_number) |
| `attendances` | `uq_attendances_tenant_employee_date` | (tenant_id, employee_id, date) |
| `leave_types` | `uq_leave_types_tenant_code` | (tenant_id, code) |
| `holidays` | `uq_holidays_tenant_date` | (tenant_id, date) |
| `roles` | `uq_roles_tenant_name` | (tenant_id, name) |
| `permissions` | `uq_permissions_tenant_codename` | (tenant_id, codename) |
| `employee_categories` | `uq_employee_categories_tenant_code` | (tenant_id, code) |
| `work_codes` | `uq_work_codes_tenant_code` | (tenant_id, code) |
| `essl_servers` | `uq_essl_servers_tenant_name` | (tenant_id, name) |

---

## 8. Key Architectural Observations

1. **Shared Database, Shared Schema**: All tenants share the same PostgreSQL database and tables. Row-level isolation via `tenant_id` FK with CASCADE delete.

2. **Employee-Teacher Duality**: In school tenants, teachers are stored in the shared `employees` table. School-specific tables reference `employees.id` for teacher assignments (class_teacher, warden, driver, etc.).

3. **Branch-Campus Bridge**: Corporate uses `branches`; school uses `campuses` which reference `branches.id`. This enables shared location data across tenant types.

4. **Department Sharing**: Corporate departments and school academic departments share the same `departments` table. School subjects reference `departments.id` for departmental grouping.

5. **eSSL Integration Layer**: 8 dedicated tables handle biometric device synchronization with incremental sync cursors, conflict policies, and error tracking.

6. **Approval Engine**: A generic 4-table approval workflow system (`approval_workflows → approval_steps → approval_requests → approval_history`) can be attached to any entity type via `entity_type` + `entity_id` polymorphic pattern.

7. **JSONB Usage**: Strategic use of JSONB for flexible/configurable data (settings, options, room_ids, invigilator_ids, attachment_urls, rubric, target_audience, raw_data).

8. **Audit Trail**: Three levels of audit: `audit_logs` (tenant-scoped), `login_history` (tenant-scoped), `super_admin_logs` (platform-wide).
