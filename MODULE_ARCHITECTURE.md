# Apex HRMS — Module Architecture & Classification

> **Audit date:** 2026-06-28
> **Scope:** Backend models, API endpoints, and services
> **Rule:** A module is **Core** only if it is useful to BOTH Corporate (HRMS) AND School (ERP) tenants with no domain-specific dependency.

---

## 1. Classification Summary

| Layer | Core | Corporate-only | School-only | Admin/Super | **Total** |
|-------|------|----------------|-------------|-------------|-----------|
| Models (`backend/app/models/`) | 11 | 25 | 15 | — | 51 |
| Endpoints (`backend/app/api/v1/endpoints/`) | 16 | 24 | 16 | 5 | 61 |
| Services (`backend/app/services/`) | 5 | 13 | 0 | — | 18 |

---

## 2. Core Platform Modules

Modules shared by **ALL** tenant types (Corporate AND School).

### 2.1 Models

| Model File | Key Tables | Purpose |
|------------|------------|---------|
| `models/tenant.py` | `tenants` | Multi-tenant entity, subscription status |
| `models/user.py` | `users`, `user_roles` | User accounts, tenant-scoped user-role mapping |
| `models/role.py` | `roles`, `permissions`, `role_permissions` | RBAC: roles, granular permissions |
| `models/audit_log.py` | `audit_logs` | Immutable audit trail for all actions |
| `models/notification.py` | `notifications` | In-app notification records |
| `models/notification_template.py` | `notification_templates` | Reusable notification templates |
| `models/document.py` | `documents` | File/document storage metadata |
| `models/tenant_settings.py` | `tenant_settings` | Key-value per-tenant configuration |
| `models/category.py` | `employee_categories` | Configurable entity categories |
| `models/holiday.py` | `holidays` | Tenant-scoped holiday calendar |
| `models/announcement.py` | `announcements`, `polls`, `poll_responses` | Company-wide announcements & polls |

### 2.2 API Endpoints

| Endpoint File | Prefix | Purpose |
|---------------|--------|---------|
| `endpoints/auth.py` | `/auth` | Login, token refresh, password management |
| `endpoints/tenants.py` | `/tenants` | Tenant CRUD, onboarding |
| `endpoints/dashboard.py` | `/dashboard` | Main dashboard aggregation |
| `endpoints/documents.py` | `/documents` | Document upload/download/management |
| `endpoints/notifications.py` | `/notifications` | Notification CRUD (legacy) |
| `endpoints/notification_center.py` | `/notifications` | Notification center (unified) |
| `endpoints/settings_api.py` | `/settings` | System settings management |
| `endpoints/tenant_settings.py` | `/tenant-settings` | Per-tenant settings CRUD |
| `endpoints/categories.py` | `/categories` | Category management |
| `endpoints/holidays.py` | `/holidays` | Holiday calendar CRUD |
| `endpoints/setup.py` | `/setup` | First-run setup wizard |
| `endpoints/system.py` | `/system` | Health check, system info |
| `endpoints/websocket.py` | *(ws)* | Real-time WebSocket connections |
| `endpoints/import_export.py` | `/data` | Bulk data import/export |
| `endpoints/operations.py` | `/ops` | Background jobs, enterprise branding |
| `endpoints/lifecycle.py` | `/employees` | Generic entity lifecycle (reusable) |

### 2.3 Services

| Service File | Purpose |
|--------------|---------|
| `services/tenant.py` | Tenant provisioning, slug generation |
| `services/user.py` | User creation, password hashing |
| `services/notification.py` | Notification dispatch logic |
| `services/dashboard.py` | Dashboard data aggregation |
| `services/websocket_manager.py` | WebSocket connection management |

---

## 3. Corporate-Only Modules (HRMS)

Modules that depend on **Employee** as the core entity. Only meaningful for Corporate/HR tenants.

### 3.1 Models

| Model File | Key Tables | Domain |
|------------|------------|--------|
| `models/employee.py` | `employees`, `departments`, `designations`, `branches` | Employee master data |
| `models/attendance.py` | `attendances`, `punch_logs`, `attendance_raw_logs` | Attendance tracking |
| `models/shift.py` | `shifts`, `shift_schedules` | Shift definitions |
| `models/shift_group.py` | `shift_groups`, `shift_group_members` | Shift grouping |
| `models/shift_roster.py` | `shift_rosters`, `shift_roster_entries` | Shift rosters |
| `models/department_shift.py` | `department_shifts` | Department-level shifts |
| `models/leave.py` | `leave_types`, `leave_balances`, `leave_requests` | Leave management |
| `models/payroll.py` | `salary_structures`, `pay_slips`, `loans` | Payroll processing |
| `models/visitor.py` | `visitors`, `visitor_passes` | Visitor management |
| `models/access_control.py` | `access_zones`, `doors`, `user_access_levels`, `access_logs` | Physical access control |
| `models/device.py` | `devices`, `device_logs` | Biometric device management |
| `models/command.py` | `device_commands` | Remote device commands |
| `models/essl_server.py` | `essl_servers` | eSSL server configuration |
| `models/essl_sync.py` | `essl_sync_history`, `essl_sync_jobs`, `essl_sync_errors` | eSSL sync tracking |
| `models/essl_mapping.py` | `essl_employee_mappings`, `essl_device_mappings` | eSSL entity mapping |
| `models/essl_cursor.py` | `essl_sync_cursors` | eSSL incremental sync cursors |
| `models/essl_location.py` | `essl_locations` | eSSL location mapping |
| `models/recruitment.py` | `job_requisitions`, `job_openings`, `candidates`, `interviews`, `offers` | Recruitment pipeline |
| `models/performance.py` | `review_cycles`, `goals`, `performance_reviews`, `competencies` | Performance management |
| `models/onboarding.py` | `onboarding_tasks` | Employee onboarding |
| `models/exit.py` | `exit_requests` | Employee exit/resignation |
| `models/timeline.py` | `employee_events` | Employee lifecycle events |
| `models/ot_register.py` | `ot_registers` | Overtime tracking |
| `models/outdoor_duty.py` | `outdoor_duties` | Outdoor duty tracking |
| `models/work_code.py` | `work_codes` | Work code definitions |
| `models/expense.py` | `expense_categories`, `expense_claims` | Expense management |
| `models/benefit.py` | `benefits`, `employee_benefits` | Benefits administration |
| `models/tax.py` | `tax_declarations` | Tax declarations (links to `employees`) |
| `models/asset_travel.py` | `company_assets`, `travel_requests` | Asset & travel (links to `employees`) |

### 3.2 API Endpoints

| Endpoint File | Prefix | Domain |
|---------------|--------|--------|
| `endpoints/employees.py` | `/employees` | Employee CRUD |
| `endpoints/attendance.py` | `/attendance` | Attendance management |
| `endpoints/shifts.py` | `/shifts` | Shift management |
| `endpoints/shift_groups.py` | `/shift-groups` | Shift groups |
| `endpoints/shift_rosters.py` | `/shift-rosters` | Shift rosters |
| `endpoints/department_shifts.py` | `/department-shifts` | Department shifts |
| `endpoints/leaves.py` | `/leaves` | Leave requests & balances |
| `endpoints/payroll.py` | `/payroll` | Payroll processing |
| `endpoints/visitors.py` | `/visitors` | Visitor management |
| `endpoints/access_control.py` | `/access-control` | Access zones & logs |
| `endpoints/devices.py` | `/devices` | Device management |
| `endpoints/commands.py` | `/commands` | Device commands |
| `endpoints/essl_connector.py` | `/essl` | eSSL server management |
| `endpoints/essl_locations.py` | `/essl` | eSSL location mapping |
| `endpoints/recruitment.py` | `/recruitment` | Recruitment pipeline |
| `endpoints/performance.py` | `/performance` | Performance reviews |
| `endpoints/assets.py` | `/assets` | Asset management |
| `endpoints/onboarding.py` | `/onboarding` | Onboarding tasks |
| `endpoints/exit_requests.py` | `/exit-requests` | Exit requests |
| `endpoints/timeline.py` | `/timeline` | Employee timeline |
| `endpoints/ot_register.py` | `/ot-register` | Overtime register |
| `endpoints/outdoor_duties.py` | `/outdoor-duties` | Outdoor duties |
| `endpoints/work_codes.py` | `/work-codes` | Work codes |
| `endpoints/expense_benefits.py` | `/finance` | Expense & benefits |
| `endpoints/hr_ops.py` | `/hr` | HR operations |
| `endpoints/ess.py` | `/ess` | Employee self-service |
| `endpoints/reports.py` | `/reports` | HR reports |

### 3.3 Services

| Service File | Purpose |
|--------------|---------|
| `services/employee.py` | Employee CRUD logic |
| `services/attendance.py` | Attendance business logic |
| `services/attendance_processor.py` | Raw punch → attendance pipeline |
| `services/shift.py` | Shift management logic |
| `services/leave.py` | Leave business logic |
| `services/visitor.py` | Visitor management logic |
| `services/access_control.py` | Access control logic |
| `services/device.py` | Device management logic |
| `services/command.py` | Device command dispatch |
| `services/report.py` | Report generation |
| `services/essl_connector.py` | eSSL connection management |
| `services/essl_soap.py` | eSSL SOAP integration |
| `services/essl_client.py` | eSSL client with Redis caching |
| `services/essl_dashboard.py` | eSSL dashboard aggregation |
| `services/sync_audit.py` | eSSL sync audit logging |
| `services/duplicate_detector.py` | Cross-server punch deduplication |

---

## 4. School-Only Modules (ERP)

Modules specific to school management. All endpoints are under `/school/` prefix.

### 4.1 Models (`backend/app/models/school/`)

| Model File | Key Tables | Domain |
|------------|------------|--------|
| `school/academic_year.py` | `academic_years`, `academic_terms`, `school_holidays` | Academic calendar |
| `school/campus.py` | `campuses`, `buildings`, `rooms` | Campus infrastructure |
| `school/grade.py` | `grades`, `sections`, `houses` | Grade/section structure |
| `school/student.py` | `students`, `guardians`, `student_guardians`, `student_siblings` | Student master data |
| `school/subject.py` | `subjects`, `grade_subjects`, `teacher_allocations` | Curriculum |
| `school/timetable.py` | `period_definitions`, `timetable_entries`, `substitutions` | Class timetables |
| `school/student_attendance.py` | `student_attendance`, `student_attendance_summaries` | Student attendance |
| `school/homework.py` | `homework`, `homework_submissions`, `assignments` | Homework & assignments |
| `school/examination.py` | `exam_types`, `exams`, `exam_schedules`, `exam_marks`, `grading_scales` | Examinations |
| `school/fee.py` | `fee_categories`, `fee_structures`, `student_fees`, `fee_payments`, `scholarships` | Fee management |
| `school/transport.py` | `transport_routes`, `transport_stops`, `student_transport` | Transport |
| `school/hostel.py` | `hostels`, `hostel_rooms`, `hostel_allocations` | Hostel management |
| `school/library.py` | `library_books`, `library_transactions` | Library |
| `school/lesson_plan.py` | `lesson_plans` | Lesson planning |
| `school/communication.py` | `school_events`, `circulars` | School communication |
| `school/medical.py` | `health_records`, `discipline_incidents` | Medical & discipline |
| `school/certificate.py` | `certificate_templates`, `issued_certificates` | Certificates |
| `school/admission.py` | `admission_inquiries`, `admission_applications` | Admissions |

### 4.2 API Endpoints (`backend/app/api/v1/endpoints/school/`)

| Endpoint File | Prefix | Domain |
|---------------|--------|--------|
| `school/academic_year.py` | `/school/academic-years` | Academic year management |
| `school/grade_section.py` | `/school` | Grades, sections, subjects, teacher allocation |
| `school/student.py` | `/school/students` | Student CRUD |
| `school/student_attendance.py` | `/school/student-attendance` | Student attendance |
| `school/homework.py` | `/school/homework` | Homework & assignments |
| `school/examination.py` | `/school` | Exams, schedules, marks |
| `school/fee.py` | `/school/fees` | Fee management |
| `school/school_dashboard.py` | `/school/dashboard` | School-specific dashboard |
| `school/transport.py` | `/school/transport` | Transport routes |
| `school/hostel.py` | `/school/hostel` | Hostel management |
| `school/library.py` | `/school/library` | Library management |
| `school/timetable.py` | `/school/timetable` | Timetable management |
| `school/communication.py` | `/school/circulars`, `/school/events` | Circulars & events |
| `school/medical.py` | `/school/health`, `/school/discipline` | Health & discipline |
| `school/certificate.py` | `/school/certificates` | Certificate issuance |
| `school/admission.py` | `/school/admissions` | Admission pipeline |

---

## 5. Admin / Super Admin Modules

Platform-level admin endpoints (not tenant-scoped).

| Endpoint File | Prefix | Purpose |
|---------------|--------|---------|
| `admin/auth.py` | `/admin/auth` | Super admin authentication |
| `admin/dashboard.py` | `/admin/dashboard` | Super admin dashboard |
| `admin/tenants.py` | `/admin/tenants` | Tenant management |
| `admin/plans.py` | `/admin/plans` | Subscription plan management |
| `admin/features.py` | `/admin/features` | Feature flag management |

Supporting models: `models/subscription.py`, `models/feature.py`, `models/approval.py`

---

## 6. Shared Dependencies

### 6.1 Base Infrastructure
- `app/db/base.py` — SQLAlchemy `Base`, `TenantModel` (auto `tenant_id` scoping)
- `app/core/deps.py` — FastAPI dependency injection (`get_db`, `get_current_active_user`, `require_permissions`, `require_feature`, `get_current_superuser`)
- `app/core/security.py` — JWT token creation/validation, password hashing

### 6.2 Cross-Module Dependencies

```
Core (tenant, user, role, audit_log)
  └─► Corporate modules depend on Employee model
       ├─► Attendance, Shifts, Leaves, Payroll → employee_id FK
       ├─► Devices, Commands, Access Control → employee_id FK
       ├─► eSSL stack → employee mapping + device mapping
       └─► Recruitment, Performance, Assets → employee_id FK
  └─► School modules depend on Student model
       ├─► Student Attendance, Homework, Exams → student_id FK
       ├─► Fees, Transport, Hostel → student_id FK
       └─► All school models use TenantModel (tenant-scoped)
```

### 6.3 Key Architectural Patterns

1. **Multi-tenancy**: All tenant-scoped models inherit `TenantModel` which adds `tenant_id` column. RLS or application-level filtering enforces isolation.
2. **RBAC**: Permission strings follow `resource.action` convention (e.g., `employees.read`, `payroll.write`).
3. **Feature flags**: `require_feature()` dependency gates modules per tenant subscription.
4. **Audit trail**: `AuditLog` model captures all write operations with actor, entity, and diff.
5. **eSSL integration**: Dedicated 5-model stack (server, sync, mapping, cursor, location) with SOAP client, circuit breaker, and duplicate detection.

---

## 7. Module Counts

| Category | Models | Endpoints | Services | **Total files** |
|----------|--------|-----------|----------|-----------------|
| **Core** | 11 | 16 | 5 | **32** |
| **Corporate** | 25 | 24 | 13 | **62** |
| **School** | 15 | 16 | 0 | **31** |
| **Admin** | 3 | 5 | 0 | **8** |
| **Grand Total** | **54** | **61** | **18** | **133** |
