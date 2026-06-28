# Database Architecture Validation Report

**Project:** Apex HRMS  
**Date:** 2026-06-28  
**Auditor:** MiMoCode Automated Audit  
**Scope:** All model files in `backend/app/models/*.py` and `backend/app/models/school/*.py`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Total model files audited | 60 |
| Total tables identified | ~131 |
| Tables with proper indexes | 38 (29%) |
| FK columns missing index | ~58 |
| FKs missing ondelete rule | ~80 |
| Missing unique constraints | ~20 |
| Missing ORM relationships | ~40 models |
| Money columns using Float | 12 |
| School models with NO migrations | ~55 |

**Overall Risk: HIGH** — Systemic issues in index coverage, cascade rules, and school module maturity.

---

## 1. Base Model Architecture

**File:** `backend/app/db/base.py`

| Base Class | Inherits | Provides |
|------------|----------|----------|
| `BaseModel` | `Base + UUIDPrimaryKeyMixin + TimestampMixin` | `id` (UUID PK), `created_at`, `updated_at` |
| `TenantModel` | `Base + UUIDPrimaryKeyMixin + TimestampMixin + TenantMixin` | All above + `tenant_id` (FK→tenants, CASCADE, indexed) |

- `id` uses `server_default=gen_random_uuid()` + Python `default=uuid.uuid4` (redundant but safe)
- `tenant_id` is properly indexed and has `ondelete="CASCADE"` — good
- Naming convention in MetaData: `%(table_name)s_%(constraint_name)s` — good

---

## 2. Tables Validated

### 2.1 Core HR Models (47 tables)

| # | Table | Model File | Inherits |
|---|-------|------------|----------|
| 1 | `tenants` | tenant.py | BaseModel |
| 2 | `users` | user.py | TenantModel |
| 3 | `user_roles` | user.py | — (assoc) |
| 4 | `roles` | role.py | TenantModel |
| 5 | `permissions` | role.py | TenantModel |
| 6 | `role_permissions` | role.py | — (assoc) |
| 7 | `departments` | employee.py | TenantModel |
| 8 | `designations` | employee.py | TenantModel |
| 9 | `branches` | employee.py | TenantModel |
| 10 | `employees` | employee.py | TenantModel |
| 11 | `devices` | device.py | TenantModel |
| 12 | `device_logs` | device.py | TenantModel |
| 13 | `attendances` | attendance.py | TenantModel |
| 14 | `punch_logs` | attendance.py | TenantModel |
| 15 | `attendance_raw_logs` | attendance.py | TenantModel |
| 16 | `shifts` | shift.py | TenantModel |
| 17 | `shift_schedules` | shift.py | TenantModel |
| 18 | `leave_types` | leave.py | TenantModel |
| 19 | `leave_balances` | leave.py | TenantModel |
| 20 | `leave_requests` | leave.py | TenantModel |
| 21 | `visitors` | visitor.py | TenantModel |
| 22 | `visitor_passes` | visitor.py | TenantModel |
| 23 | `access_zones` | access_control.py | TenantModel |
| 24 | `doors` | access_control.py | TenantModel |
| 25 | `user_access_levels` | access_control.py | TenantModel |
| 26 | `access_logs` | access_control.py | TenantModel |
| 27 | `device_commands` | command.py | TenantModel |
| 28 | `notifications` | notification.py | TenantModel |
| 29 | `audit_logs` | audit_log.py | BaseModel |
| 30 | `holidays` | holiday.py | TenantModel |
| 31 | `employee_categories` | category.py | TenantModel |
| 32 | `department_shifts` | department_shift.py | TenantModel |
| 33 | `shift_groups` | shift_group.py | TenantModel |
| 34 | `shift_group_members` | shift_group.py | TenantModel |
| 35 | `shift_rosters` | shift_roster.py | TenantModel |
| 36 | `shift_roster_entries` | shift_roster.py | TenantModel |
| 37 | `work_codes` | work_code.py | TenantModel |
| 38 | `documents` | document.py | TenantModel |
| 39 | `onboarding_tasks` | onboarding.py | TenantModel |
| 40 | `exit_requests` | exit.py | TenantModel |
| 41 | `timeline` / `employee_events` | timeline.py | TenantModel |
| 42 | `notification_templates` | notification_template.py | TenantModel |
| 43 | `tenant_settings` | tenant_settings.py | TenantModel |

### 2.2 Admin/Platform Models (38 tables)

| # | Table | Model File |
|---|-------|------------|
| 44 | `subscription_plans` | subscription.py |
| 45 | `tenant_subscriptions` | subscription.py |
| 46 | `resource_limits` | subscription.py |
| 47 | `feature_flags` | feature.py |
| 48 | `tenant_features` | feature.py |
| 49 | `approval_workflows` | approval.py |
| 50 | `approval_steps` | approval.py |
| 51 | `approval_requests` | approval.py |
| 52 | `approval_history` | approval.py |
| 53 | `login_history` | approval.py |
| 54 | `super_admin_logs` | approval.py |
| 55 | `announcements` | announcement.py |
| 56 | `polls` | announcement.py |
| 57 | `poll_responses` | announcement.py |
| 58 | `benefits` | benefit.py |
| 59 | `employee_benefits` | benefit.py |
| 60 | `expense_categories` | expense.py |
| 61 | `expense_claims` | expense.py |
| 62 | `salary_structures` | payroll.py |
| 63 | `pay_slips` | payroll.py |
| 64 | `loans` | payroll.py |
| 65 | `tax_declarations` | tax.py |
| 66 | `review_cycles` | performance.py |
| 67 | `goals` | performance.py |
| 68 | `performance_reviews` | performance.py |
| 69 | `competencies` | performance.py |
| 70 | `performance_recommendations` | performance.py |
| 71 | `job_requisitions` | recruitment.py |
| 72 | `job_openings` | recruitment.py |
| 73 | `candidates` | recruitment.py |
| 74 | `interviews` | recruitment.py |
| 75 | `offers` | recruitment.py |
| 76 | `company_assets` | asset_travel.py |
| 77 | `travel_requests` | asset_travel.py |
| 78 | `ot_register` | ot_register.py |
| 79 | `outdoor_duty` | outdoor_duty.py |

### 2.3 eSSL Integration Models (8 tables)

| # | Table | Model File |
|---|-------|------------|
| 80 | `essl_servers` | essl_server.py |
| 81 | `essl_sync_history` | essl_sync.py |
| 82 | `essl_sync_jobs` | essl_sync.py |
| 83 | `essl_sync_errors` | essl_sync.py |
| 84 | `essl_employee_mappings` | essl_mapping.py |
| 85 | `essl_device_mappings` | essl_mapping.py |
| 86 | `essl_sync_cursors` | essl_cursor.py |
| 87 | `essl_locations` | essl_location.py |

### 2.4 School ERP Models (55 tables) — **NOT YET MIGRATED**

| # | Table | Model File |
|---|-------|------------|
| 88 | `academic_years` | school/academic_year.py |
| 89 | `academic_terms` | school/academic_year.py |
| 90 | `school_holidays` | school/academic_year.py |
| 91 | `campuses` | school/campus.py |
| 92 | `buildings` | school/campus.py |
| 93 | `rooms` | school/campus.py |
| 94 | `grades` | school/grade.py |
| 95 | `sections` | school/grade.py |
| 96 | `houses` | school/grade.py |
| 97 | `students` | school/student.py |
| 98 | `guardians` | school/student.py |
| 99 | `student_guardians` | school/student.py |
| 100 | `student_siblings` | school/student.py |
| 101 | `subjects` | school/subject.py |
| 102 | `grade_subjects` | school/subject.py |
| 103 | `teacher_allocations` | school/subject.py |
| 104 | `period_definitions` | school/timetable.py |
| 105 | `timetable_entries` | school/timetable.py |
| 106 | `substitutions` | school/timetable.py |
| 107 | `student_attendances` | school/student_attendance.py |
| 108 | `student_attendance_summaries` | school/student_attendance.py |
| 109 | `homeworks` | school/homework.py |
| 110 | `homework_submissions` | school/homework.py |
| 111 | `assignments` | school/homework.py |
| 112 | `assignment_submissions` | school/homework.py |
| 113 | `exam_types` | school/examination.py |
| 114 | `exams` | school/examination.py |
| 115 | `exam_schedules` | school/examination.py |
| 116 | `exam_marks` | school/examination.py |
| 117 | `grading_scales` | school/examination.py |
| 118 | `grading_scale_details` | school/examination.py |
| 119 | `fee_categories` | school/fee.py |
| 120 | `fee_structures` | school/fee.py |
| 121 | `student_fees` | school/fee.py |
| 122 | `fee_payments` | school/fee.py |
| 123 | `fee_fine_rules` | school/fee.py |
| 124 | `scholarships` | school/fee.py |
| 125 | `student_scholarships` | school/fee.py |
| 126 | `transport_routes` | school/transport.py |
| 127 | `transport_stops` | school/transport.py |
| 128 | `student_transports` | school/transport.py |
| 129 | `hostels` | school/hostel.py |
| 130 | `hostel_rooms` | school/hostel.py |
| 131 | `hostel_allocations` | school/hostel.py |
| 132 | `library_books` | school/library.py |
| 133 | `library_transactions` | school/library.py |
| 134 | `lesson_plans` | school/lesson_plan.py |
| 135 | `school_events` | school/communication.py |
| 136 | `circulars` | school/communication.py |
| 137 | `health_records` | school/medical.py |
| 138 | `discipline_incidents` | school/medical.py |
| 139 | `certificate_templates` | school/certificate.py |
| 140 | `issued_certificates` | school/certificate.py |
| 141 | `admission_inquiries` | school/admission.py |
| 142 | `admission_applications` | school/admission.py |

---

## 3. Index Verification

### 3.1 Well-Indexed Tables (GOOD)

| Table | Indexes |
|-------|---------|
| `employees` | `tenant_id`, `department_id`, `designation_id`, `branch_id`, `shift_id`, `category_id`, `shift_group_id`, `shift_roster_id` — all indexed |
| `attendances` | `employee_id`, `tenant_id+attendance_date` composite |
| `leave_balances` | `employee_id`, `tenant_id+leave_type_id+year` composite |
| `leave_requests` | `employee_id`, `tenant_id+status` composite |
| `students` | `current_grade_id`, `current_section_id`, `academic_year_id`, `tenant_id+is_active`, `tenant_id+current_grade_id+current_section_id` |
| `fee_structures` | `academic_year_id`, `grade_id`, `fee_category_id` |
| `student_fees` | `student_id`, `fee_structure_id`, `academic_year_id`, `tenant_id+status` |
| `exam_schedules` | `exam_id`, `subject_id`, `grade_id` |
| `exam_marks` | `exam_schedule_id`, `student_id` |
| All eSSL tables | Properly indexed on all FK columns |

### 3.2 Tables Missing FK Indexes (CRITICAL)

**~58 FK columns lack `index=True`**, causing slow JOINs and filtered queries.

#### performance.py — ALL FK columns unindexed (5 tables, 15 FKs)

| Table | Unindexed FK Columns |
|-------|---------------------|
| `review_cycles` | `created_by` |
| `goals` | `employee_id`, `cycle_id`, `approved_by` |
| `performance_reviews` | `cycle_id`, `employee_id`, `reviewer_id` |
| `competencies` | (no FKs — OK) |
| `performance_recommendations` | `review_id`, `employee_id`, `recommended_by`, `new_designation_id`, `approved_by` |

#### recruitment.py — ALL FK columns unindexed (5 tables, 17 FKs)

| Table | Unindexed FK Columns |
|-------|---------------------|
| `job_requisitions` | `department_id`, `branch_id`, `hiring_manager_id`, `approved_by` |
| `job_openings` | `requisition_id`, `department_id`, `branch_id`, `created_by` |
| `candidates` | `opening_id` |
| `interviews` | `candidate_id`, `opening_id`, `interviewer_id` |
| `offers` | `candidate_id`, `opening_id`, `approved_by` |

#### Other scattered unindexed FKs

| Table | Unindexed FK Columns |
|-------|---------------------|
| `approval_steps` | `workflow_id` |
| `approval_requests` | `workflow_id`, `step_id`, `requester_id` |
| `approval_history` | `request_id`, `actor_id` |
| `expense_claims` | `employee_id`, `category_id` |
| `asset_travel.py` tables | Multiple FK columns |
| `ot_register` | `employee_id` |
| `outdoor_duty` | `employee_id` |
| `goals` | `employee_id`, `cycle_id` |
| `announcements` | `created_by` |
| `poll_responses` | `poll_id`, `user_id` |
| `documents` | `employee_id` |
| `onboarding_tasks` | `employee_id` |
| `exit_requests` | `employee_id` |
| `employee_benefits` | `employee_id`, `benefit_id` |
| `tax_declarations` | `employee_id` |
| `salary_structures` | `employee_id` |
| `pay_slips` | `employee_id` |
| `loans` | `employee_id` |

#### School models — partially indexed

| Table | Indexed FKs | Unindexed FKs |
|-------|-------------|---------------|
| `students` | `current_grade_id`, `current_section_id`, `academic_year_id` | `admission_grade_id`, `house_id`, `transport_route_id`, `hostel_room_id` |
| `timetable_entries` | `section_id`, `academic_year_id` | `subject_id`, `employee_id`, `room_id`, `period_definition_id` |
| `guardians` | — | `user_id` |
| `sections` | `grade_id`, `academic_year_id` | `room_id`, `class_teacher_id` |
| `houses` | — | `house_master_id` |
| `fee_payments` | `student_id`, `student_fee_id` | `collected_by` |
| `exam_marks` | `exam_schedule_id`, `student_id` | `entered_by`, `verified_by` |
| `substitutions` | `original_employee_id`, `substitute_employee_id` | `timetable_entry_id`, `approved_by` |

---

## 4. Foreign Key Constraint Verification

### 4.1 Properly Defined Cascades (GOOD)

| Pattern | Tables |
|---------|--------|
| `ondelete="CASCADE"` on parent→child | `student_guardians.student_id`, `student_fees.student_id`, `fee_payments.student_id`, `exam_schedules.exam_id`, `exam_marks.exam_schedule_id`, `grading_scale_details.grading_scale_id`, `leave_balances.employee_id`, `punch_logs.employee_id`, all eSSL mapping tables |
| `ondelete="SET NULL"` on optional refs | `employees.department_id`, `employees.designation_id`, `employees.branch_id`, `employees.shift_id`, `performance_reviews.reviewer_id`, `job_requisitions.department_id` |
| `tenant_id` → `CASCADE` | All TenantModel subclasses (via TenantMixin) |

### 4.2 Missing ondelete Rules (HIGH RISK)

**~80 FKs have no `ondelete` specified**, defaulting to `RESTRICT` in PostgreSQL. This blocks parent row deletion and can cause runtime errors.

#### School models — systematically missing ondelete

Nearly ALL school model FKs lack `ondelete`. Examples:

| Table.Column | References | Expected ondelete |
|--------------|------------|-------------------|
| `academic_terms.academic_year_id` | `academic_years.id` | CASCADE |
| `buildings.campus_id` | `campuses.id` | CASCADE |
| `rooms.building_id` | `buildings.id` | CASCADE |
| `sections.grade_id` | `grades.id` | CASCADE |
| `students.admission_grade_id` | `grades.id` | SET NULL |
| `students.house_id` | `houses.id` | SET NULL |
| `students.transport_route_id` | `transport_routes.id` | SET NULL |
| `students.hostel_room_id` | `hostel_rooms.id` | SET NULL |
| `student_guardians.guardian_id` | `guardians.id` | CASCADE |
| `grade_subjects.grade_id` | `grades.id` | CASCADE |
| `grade_subjects.subject_id` | `subjects.id` | CASCADE |
| `teacher_allocations.employee_id` | `employees.id` | CASCADE |
| `timetable_entries.subject_id` | `subjects.id` | SET NULL |
| `timetable_entries.employee_id` | `employees.id` | SET NULL |
| `timetable_entries.period_definition_id` | `period_definitions.id` | CASCADE |
| `homeworks.employee_id` | `employees.id` | CASCADE |
| `homework_submissions.homework_id` | `homeworks.id` | CASCADE |
| `homework_submissions.student_id` | `students.id` | CASCADE |
| `fee_structures.academic_year_id` | `academic_years.id` | CASCADE |
| `fee_fine_rules.fee_category_id` | `fee_categories.id` | CASCADE |
| `scholarships` (no FKs) | — | — |
| `transport_stops.route_id` | `transport_routes.id` | CASCADE |
| `student_transports.student_id` | `students.id` | CASCADE |
| `student_transports.route_id` | `transport_routes.id` | CASCADE |
| `hostel_rooms.hostel_id` | `hostels.id` | CASCADE |
| `hostel_allocations.student_id` | `students.id` | CASCADE |
| `hostel_allocations.room_id` | `hostel_rooms.id` | CASCADE |
| `library_transactions.book_id` | `library_books.id` | CASCADE |
| `library_transactions.student_id` | `students.id` | CASCADE |
| `lesson_plans.employee_id` | `employees.id` | CASCADE |
| `lesson_plans.subject_id` | `subjects.id` | CASCADE |
| `health_records.student_id` | `students.id` | CASCADE |
| `discipline_incidents.student_id` | `students.id` | CASCADE |
| `issued_certificates.student_id` | `students.id` | CASCADE |
| `admission_applications.inquiry_id` | `admission_inquiries.id` | CASCADE |

#### Core/Platform models missing ondelete

| Table.Column | References | Current | Expected |
|--------------|------------|---------|----------|
| `tenant_subscriptions.plan_id` | `subscription_plans.id` | RESTRICT (default) | SET NULL |
| `approval_steps.workflow_id` | `approval_workflows.id` | RESTRICT | CASCADE |
| `approval_requests.workflow_id` | `approval_workflows.id` | RESTRICT | CASCADE |
| `approval_requests.step_id` | `approval_steps.id` | RESTRICT | CASCADE |
| `approval_history.request_id` | `approval_requests.id` | RESTRICT | CASCADE |
| `poll_responses.poll_id` | `polls.id` | RESTRICT | CASCADE |
| `student_guardians.guardian_id` | `guardians.id` | RESTRICT | CASCADE |

### 4.3 Broken FK Constraint (BUG)

| Table.Column | Issue |
|--------------|-------|
| `student_guardians.guardian_id` | Has `index=True` but **NO `ForeignKey('guardians.id')` constraint**. Column is UUID type but not actually constrained at DB level. |

---

## 5. Unique Constraint Verification

### 5.1 Properly Defined Uniques (GOOD)

| Table | Constraint |
|-------|------------|
| `departments` | `uq_departments_tenant_code` (tenant_id, code) |
| `designations` | `uq_designations_tenant_code` (tenant_id, code) |
| `branches` | `uq_branches_tenant_code` (tenant_id, code) |
| `employees` | `uq_employees_tenant_employee_code`, `uq_employees_tenant_email`, `uq_employees_tenant_device_user_id` |
| `tenants` | `slug` (column-level unique) |
| `shifts` | (none — see issues) |

### 5.2 Missing Unique Constraints (MEDIUM RISK)

| Table | Column(s) | Why Needed |
|-------|-----------|------------|
| `shifts` | `(tenant_id, name)` | Prevent duplicate shift names per tenant |
| `notification_templates` | `(tenant_id, event_key)` | Prevent duplicate templates per event |
| `approval_workflows` | `(tenant_id, name)` | Prevent duplicate workflow names |
| `fee_categories` | `(tenant_id, code)` | Prevent duplicate fee category codes |
| `exam_types` | `(tenant_id, code)` | Prevent duplicate exam type codes |
| `grading_scales` | `(tenant_id, name)` | Prevent duplicate grading scale names |
| `fee_structures` | `(tenant_id, academic_year_id, grade_id, fee_category_id)` | Prevent duplicate fee structures |
| `exam_marks` | `(exam_schedule_id, student_id)` | Prevent duplicate marks entry |
| `homework_submissions` | `(homework_id, student_id)` | Prevent duplicate submissions |
| `assignment_submissions` | `(assignment_id, student_id)` | Prevent duplicate submissions |
| `student_attendance_summaries` | `(student_id, date)` or `(student_id, month, year)` | Prevent duplicate summaries |
| `grade_subjects` | `(tenant_id, grade_id, subject_id)` | Prevent duplicate allocations |
| `timetable_entries` | `(section_id, day_of_week, period_definition_id, academic_year_id)` | Prevent timetable conflicts |
| `teacher_allocations` | `(tenant_id, employee_id, subject_id, grade_id, section_id, academic_year_id)` | Prevent duplicate allocations |
| `hostel_allocations` | `(student_id, academic_year_id)` | Prevent double allocation |
| `library_transactions` | `(book_id, student_id, status)` | Prevent duplicate active borrows |
| `expense_categories` | `(tenant_id, code)` | Prevent duplicate codes |
| `benefits` | `(tenant_id, name)` | Prevent duplicate benefit names |
| `tax_declarations` | `(employee_id, financial_year)` | Prevent duplicate declarations |
| `shift_roster_entries` | `(roster_id, employee_id, date)` | Prevent duplicate roster entries |

---

## 6. Relationship Verification

### 6.1 Well-Defined Relationships (GOOD)

**Core HR models** have comprehensive bidirectional relationships:

- `Employee` → `Department`, `Designation`, `Branch`, `Shift` (back_populates on both sides)
- `Employee` → `Attendance`, `PunchLog`, `LeaveBalance`, `LeaveRequest` (cascade="all, delete-orphan")
- `Employee` → `VisitorPass`, `UserAccessLevel`, `AccessLog` (cascade="all, delete-orphan")
- `Tenant` → `Employee`, `Department`, `Designation`, `Branch`, `Device`, `AccessZone` (back_populates)
- All eSSL models have clean bidirectional relationships

### 6.2 Missing Relationships (MEDIUM RISK)

| Model | Missing Relationship |
|-------|---------------------|
| `Employee` | No `relationship()` to `EmployeeCategory`, `ShiftGroup`, `ShiftRoster` despite having FK columns |
| `Employee` | No relationship to `SalaryStructure`, `PaySlip`, `Loan`, `Document`, `OnboardingTask`, `ExitRequest` |
| `Employee` | No relationship to `Goal`, `PerformanceReview`, `TaxDeclaration`, `ExpenseClaim`, `OTRegister`, `OutdoorDuty` |
| `Department` | No relationship to `DepartmentShift` |
| `ShiftGroup` | No back-reference from `ShiftGroupMember` (one-directional) |
| `ShiftRoster` | No back-reference from `ShiftRosterEntry` (one-directional) |
| All 55 school models | **Zero `relationship()` definitions** — no ORM navigation possible |
| `Tenant` | No relationship to approval, subscription, feature tables |

### 6.3 Redundant Definitions

| Issue | Location |
|-------|----------|
| `Employee.tenant_id` redefined | Employee model explicitly defines `tenant_id` column + FK, but `TenantModel` base already provides it. Redundant (harmless — SQLAlchemy merges). Same for `Department`, `Designation`, `Branch`. |
| `tenants.slug` double-constrained | Has both `unique=True` column attribute AND a separate `UniqueConstraint` in `__table_args__` |
| `created_at`/`updated_at` redefined | `ReviewCycle`, `Goal`, `PerformanceReview`, `Competency`, `PerformanceRecommendation`, all recruitment models — re-define timestamps with Python defaults instead of using `TenantModel`'s `server_default=func.now()` |

---

## 7. Data Type Issues

### 7.1 Money Columns Using Float (HIGH RISK)

Float precision causes rounding errors in financial calculations. Should use `Numeric(12, 2)`.

| Table.Column | Current Type | Recommended |
|--------------|-------------|-------------|
| `subscription_plans.price` | `Float` | `Numeric(12, 2)` |
| `subscription_plans.monthly_price` | `Float` | `Numeric(12, 2)` |
| `job_requisitions.salary_min` | `Float` | `Numeric(12, 2)` |
| `job_requisitions.salary_max` | `Float` | `Numeric(12, 2)` |
| `job_openings.salary_min` | `Float` | `Numeric(12, 2)` |
| `job_openings.salary_max` | `Float` | `Numeric(12, 2)` |
| `candidates.expected_salary` | `Float` | `Numeric(12, 2)` |
| `offers.salary_offered` | `Float` | `Numeric(12, 2)` |
| `expense_claims.amount` | `Float` | `Numeric(12, 2)` |
| `PerformanceRecommendation.salary_increment` | `Float` | `Numeric(12, 2)` |
| `goals.weightage/target_value/current_value/progress` | `Float` | `Numeric(5, 2)` / `Numeric(12, 2)` |
| `performance_reviews.rating` | `Float` | `Numeric(3, 1)` |

**Note:** School fee models correctly use `Numeric(12, 2)` — good.

### 7.2 Inconsistent PK Defaults

| Pattern | Tables |
|---------|--------|
| `server_default=text("gen_random_uuid()")` (DB-side) | All `TenantModel`/`BaseModel` subclasses (via mixin) |
| `default=uuid.uuid4` (Python-side only, no server_default) | `feature_flags`, `subscription_plans`, `resource_limits` |

The Python-only default works but fails if raw SQL inserts are used without providing an ID.

---

## 8. Migration Status

### 8.1 Migration History

17 Alembic migrations from `initial_schema` to `add_missing_indexes`. All linear, no branches.

### 8.2 Unmigrated Models (CRITICAL)

**~55 school ERP models have NO Alembic migration.** They exist as SQLAlchemy definitions but their tables do not exist in the database. The `school/__init__.py` imports them for autogenerate, but no migration has been generated.

Models affected: All tables in §2.4 (academic_years through admission_applications).

---

## 9. Issues Summary

### Critical (Must Fix)

| # | Issue | Impact | Scope |
|---|-------|--------|-------|
| C1 | ~58 FK columns missing indexes | Slow JOINs, full table scans on filtered queries | performance.py, recruitment.py, approval.py, school models |
| C2 | ~80 FKs missing ondelete rules | RESTRICT default blocks parent deletion, runtime errors | All school models, approval.py, subscription.py |
| C3 | `student_guardians.guardian_id` missing ForeignKey constraint | No DB-level referential integrity | school/student.py:79 |
| C4 | ~55 school tables not migrated | Tables don't exist in database | All school models |
| C5 | Money columns using Float | Rounding errors in financial calculations | performance.py, recruitment.py, expense.py, subscription.py |

### High (Should Fix)

| # | Issue | Impact | Scope |
|---|-------|--------|-------|
| H1 | ~20 missing unique constraints | Duplicate data possible | Shifts, notification templates, fee structures, exam marks, etc. |
| H2 | ~40 models missing relationship() definitions | No ORM navigation, manual joins required | performance.py, recruitment.py, all school models |
| H3 | Redundant `created_at`/`updated_at` redefinitions | Bypasses server_default, inconsistent behavior | performance.py, recruitment.py (10 models) |
| H4 | Redundant `tenant_id` redefinitions | Code duplication, merge confusion | employee.py (Department, Designation, Branch, Employee) |

### Low (Nice to Fix)

| # | Issue | Impact | Scope |
|---|-------|--------|--------|
| L1 | `tenants.slug` double unique constraint | Minor DDL redundancy | tenant.py |
| L2 | Inconsistent PK default strategy | Raw SQL inserts may fail | feature.py, subscription.py |
| L3 | `guardians.annual_income` as Integer | Should be Numeric for precision | school/student.py:68 |

---

## 10. Recommendations

### Immediate Actions

1. **Generate school migration**: Run `alembic revision --autogenerate -m "add_school_erp_tables"` to create the missing migration for all 55 school tables.

2. **Add missing indexes**: Create a migration adding `index=True` to all ~58 unindexed FK columns. Priority: performance.py, recruitment.py, approval.py.

3. **Fix broken FK**: Add `ForeignKey("guardians.id", ondelete="CASCADE")` to `student_guardians.guardian_id`.

4. **Add ondelete rules**: Systematic migration to add `ondelete` to all ~80 FKs missing it. Use CASCADE for child tables, SET NULL for optional references.

5. **Fix money types**: Change all `Float` money columns to `Numeric(12, 2)`.

### Short-term Improvements

6. **Add unique constraints**: Add composite unique constraints to prevent duplicate data in the ~20 tables identified.

7. **Add missing relationships**: Add `relationship()` definitions to all models that have FK columns but no ORM relationship.

8. **Remove redundant column definitions**: Let `TenantModel` base handle `tenant_id`, `created_at`, `updated_at` — remove explicit re-definitions in subclasses.

9. **Standardize PK defaults**: Ensure all models use `server_default=text("gen_random_uuid()")` for consistency.

### Long-term

10. **Add check constraints**: Consider `CheckConstraint` for status enums, positive amounts, date ranges.

11. **Add partial indexes**: For soft-delete patterns (`is_active=True`), consider partial indexes to reduce index size.

12. **Review cascade strategy**: Document the intended cascade behavior as a project standard.

---

## Appendix: Model File Index

| File Path | Tables | Status |
|-----------|--------|--------|
| `backend/app/models/employee.py` | 4 | Well-structured |
| `backend/app/models/user.py` | 3 | Good |
| `backend/app/models/attendance.py` | 3 | Good |
| `backend/app/models/leave.py` | 3 | Good |
| `backend/app/models/shift.py` | 2 | Missing unique |
| `backend/app/models/device.py` | 2 | Good |
| `backend/app/models/visitor.py` | 2 | Good |
| `backend/app/models/access_control.py` | 4 | Good |
| `backend/app/models/role.py` | 4 | Good |
| `backend/app/models/approval.py` | 6 | Missing indexes, ondelete |
| `backend/app/models/performance.py` | 5 | Missing indexes, Float money |
| `backend/app/models/recruitment.py` | 5 | Missing indexes, Float money |
| `backend/app/models/payroll.py` | 3 | Good |
| `backend/app/models/subscription.py` | 3 | Float money, missing ondelete |
| `backend/app/models/feature.py` | 2 | Inconsistent PK default |
| `backend/app/models/benefit.py` | 2 | Missing indexes |
| `backend/app/models/expense.py` | 2 | Missing indexes, Float |
| `backend/app/models/essl_*.py` | 8 | Best practice model |
| `backend/app/models/school/*.py` | 55 | Not migrated, missing indexes/ondelete/relationships/unique |

---

*Report generated by automated audit. No files were modified.*
