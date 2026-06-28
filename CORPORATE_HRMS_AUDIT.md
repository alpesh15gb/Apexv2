# Corporate HRMS Module Audit — Apex HRMS v2

**Audit Date**: 2026-06-28
**Scope**: All Corporate HRMS modules in the Apex HRMS codebase
**Stack**: FastAPI (Python) + PostgreSQL + Flutter (Dart/Riverpod)

---

## Table of Contents

1. [Core Infrastructure](#1-core-infrastructure)
2. [Employees](#2-employees)
3. [Attendance](#3-attendance)
4. [Shifts](#4-shifts)
5. [Leaves](#5-leaves)
6. [Payroll](#6-payroll)
7. [Visitors](#7-visitors)
8. [Access Control](#8-access-control)
9. [Devices](#9-devices)
10. [eSSL Biometric](#10-essl-biometric)
11. [Recruitment](#11-recruitment)
12. [Performance](#12-performance)
13. [Assets](#13-assets)
14. [Reports](#14-reports)
15. [Lifecycle](#15-lifecycle)
16. [Timeline](#16-timeline)
17. [Onboarding](#17-onboarding)
18. [Exit Requests](#18-exit-requests)
19. [OT Register](#19-ot-register)
20. [Outdoor Duties](#20-outdoor-duties)
21. [Work Codes](#21-work-codes)
22. [Expense/Benefits](#22-expensebenefits)
23. [HR Ops](#23-hr-ops)
24. [ESS](#24-ess-employee-self-service)
25. [Cross-Module Dependency Matrix](#25-cross-module-dependency-matrix)
26. [Feature Flag Summary](#26-feature-flag-summary)
27. [Permission Matrix](#27-permission-matrix)
28. [Critical Findings](#28-critical-findings)

---

## 1. Core Infrastructure

### Authentication & Authorization

| Component | File | Purpose |
|-----------|------|---------|
| JWT Auth | `backend/app/core/deps.py` | OAuth2 bearer token, access-token-only, revocation via Redis |
| RBAC | `backend/app/core/rbac.py` | Permission checking via role→permission mapping |
| Feature Gate | `backend/app/core/feature_gate.py` | Per-tenant feature flag toggling |
| Password Policy | `backend/app/core/password_policy.py` | Password complexity enforcement |
| Encryption | `backend/app/core/encryption.py` | At-rest encryption for sensitive fields |

### Key Dependencies (used by all modules)

- `get_current_active_user` — JWT validation + user fetch + active check
- `get_current_tenant` — Extracts tenant from authenticated user
- `require_permissions(*codenames)` — RBAC check; superusers bypass
- `require_feature(feature_code)` — Feature flag check; superusers bypass

### Default Roles (seeded per tenant)

| Role | Codename | Permissions |
|------|----------|-------------|
| Super Admin | `super_admin` | `*` (all) |
| HR Admin | `hr_admin` | employee.crud, attendance.read/manage, leave.approve/read, shift.manage/read, report.read, visitor.manage/read |
| Manager | `manager` | employee.read, attendance.read/approve, leave.approve/read, report.read, visitor.read |
| Employee | `employee` | attendance.read_own, leave.apply/read_own, visitor.create |

### Base Model

All business entities extend `TenantModel` providing:
- `id` — UUID PK (auto-generated via `gen_random_uuid()`)
- `tenant_id` — UUID FK → `tenants.id`, CASCADE, indexed
- `created_at` — DateTime with timezone, server default `now()`
- `updated_at` — DateTime with timezone, auto-updates

---

## 2. Employees

### Purpose
Core workforce management. Manages employee records and three sub-entities: departments, designations, branches. Foundational layer referenced by nearly all other modules.

### Key Entities

**Employee** (`employees`): `employee_code`, `first_name`, `last_name`, `email`, `phone`, `photo_url`, `department_id` FK, `designation_id` FK, `branch_id` FK, `shift_id` FK, `category_id` FK, `shift_group_id` FK, `shift_roster_id` FK, `joining_date`, `date_of_birth`, `gender`, `address`, `city`, `state`, `pincode`, `emergency_contact_name/phone`, `blood_group`, `status` (active/inactive/terminated/on_notice), `device_user_id`. Unique constraints: `(tenant_id, employee_code)`, `(tenant_id, email)`, `(tenant_id, device_user_id)`.

**Department** (`departments`): `name`, `code`, `is_active`. Unique: `(tenant_id, code)`.

**Designation** (`designations`): `name`, `code`, `is_active`. Unique: `(tenant_id, code)`.

**Branch** (`branches`): `name`, `code`, `is_active`. Unique: `(tenant_id, code)`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/employees/departments` | `employee.read` | List departments (paginated) |
| POST | `/employees/departments` | `employee.create` | Create department |
| PUT | `/employees/departments/{id}` | `employee.update` | Update department |
| DELETE | `/employees/departments/{id}` | `employee.delete` | Delete department |
| GET | `/employees/designations` | `employee.read` | List designations (paginated) |
| POST | `/employees/designations` | `employee.create` | Create designation |
| PUT | `/employees/designations/{id}` | `employee.update` | Update designation |
| DELETE | `/employees/designations/{id}` | `employee.delete` | Delete designation |
| GET | `/employees/branches` | `employee.read` | List branches (paginated) |
| POST | `/employees/branches` | `employee.create` | Create branch |
| PUT | `/employees/branches/{id}` | `employee.update` | Update branch |
| DELETE | `/employees/branches/{id}` | `employee.delete` | Delete branch |
| GET | `/employees/` | `employee.read` | List employees (paginated, searchable) |
| POST | `/employees/` | `employee.create` | Create employee |
| POST | `/employees/bulk-import` | `employee.create` | Bulk import from CSV/Excel |
| GET | `/employees/{id}` | `employee.read` | Get employee detail |
| PUT | `/employees/{id}` | `employee.update` | Update employee |
| DELETE | `/employees/{id}` | `employee.delete` | Delete employee |
| POST | `/employees/{id}/deactivate` | `employee.update` | Deactivate employee |

### Feature Flags
None — Employees module has no feature flag gate.

### Permissions
`employee.read`, `employee.create`, `employee.update`, `employee.delete` — **properly granular**.

### Files
- Backend: `models/employee.py`, `schemas/employee.py`, `services/employee.py`, `api/v1/endpoints/employees.py`
- Frontend: `screens/employees/`, `providers/employee_provider.dart`, `services/employee_service.dart`

### Dependencies On
- Core: Auth, RBAC, Tenants
- Shifts: FK `shift_id`, `shift_group_id`, `shift_roster_id`
- Categories: FK `category_id`

### Depended On By
Attendance, Leaves, Shifts, Payroll, Visitors, Access Control, Devices, Recruitment, Performance, Assets, Lifecycle, Timeline, Onboarding, Exit Requests, OT Register, Outdoor Duties, ESS, HR Ops

---

## 3. Attendance

### Purpose
Biometric punch ingestion from eSSL devices, shift-aware daily attendance calculation, manual marking, approval workflows, and OT/outdoor duty tracking.

### Key Entities

**Attendance** (`attendances`): `employee_id` FK, `date`, `punch_in`, `punch_out`, `total_hours`, `overtime_hours`, `status` (present/absent/half_day/late/early_out/holiday/week_off), `is_late`, `late_minutes`, `is_early_out`, `early_out_minutes`, `shift_id` FK, `is_manual`, `approved_by` FK, `remarks`. Unique: `(tenant_id, employee_id, date)`.

**PunchLog** (`punch_logs`): `employee_id` FK, `device_id` FK, `punch_time`, `punch_type` (in/out/break_in/break_out), `source` (biometric/manual/import), `raw_data`.

**AttendanceRawLog** (`attendance_raw_logs`): `essl_server_id` FK, `employee_code`, `employee_id` FK, `device_serial`, `punch_time`, `raw_data` (JSONB), `processed` (bool), `processing_error`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/attendance/daily-summary` | `attendance.read` | Aggregate stats for a date |
| GET | `/attendance/employee/{id}` | `attendance.read` | Per-employee summary over date range |
| GET | `/attendance/` | `attendance.read` | Paginated attendance list with filters |
| POST | `/attendance/` | `attendance.manage` | Manual attendance entry |
| POST | `/attendance/process` | `attendance.manage` | Trigger batch calculation |
| PUT | `/attendance/{id}/approve` | `attendance.manage` | Approve attendance record |
| GET | `/attendance/punch-logs` | `attendance.read` | Paginated punch logs |

### Feature Flags
None — no feature flag gate on attendance endpoints.

### Permissions
`attendance.read`, `attendance.manage` — **no write granularity** (manage covers all mutations).

### Service Methods
- `process_punch_log()` — Creates PunchLog, triggers calculation
- `calculate_attendance()` — Core shift-aware attendance logic
- `calculate_daily_attendance()` — Batch for all active employees
- `manual_mark_attendance()` — Upsert with `is_manual=True`
- `approve_attendance()` — Sets `approved_by`

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`
- **Shift**: FK `shift_id`, shift schedule lookup
- **Leave**: LeaveRequest count for daily summary
- **Device**: FK on PunchLog
- **eSSL**: FK on AttendanceRawLog

### Files
- Backend: `models/attendance.py`, `schemas/attendance.py`, `services/attendance.py`, `services/attendance_processor.py`, `api/v1/endpoints/attendance.py`
- Frontend: `screens/attendance/` (8 screens), `providers/attendance_provider.dart`, `services/attendance_service.dart`

---

## 4. Shifts

### Purpose
Shift definition, employee shift assignment, shift groups, shift rosters, and department-level shifts.

### Key Entities

**Shift** (`shifts`): `name`, `start_time`, `end_time`, `grace_period_minutes`, `late_rule_minutes`, `early_rule_minutes`, `overtime_threshold_minutes`, `is_night_shift`, `is_active`.

**ShiftSchedule** (`shift_schedules`): `employee_id` FK, `shift_id` FK, `effective_from`, `effective_to`, `day_of_week` (0-6).

**ShiftGroup** (`shift_groups`): `name`, `description` + members via `ShiftGroupMember`.

**ShiftRoster** (`shift_rosters`): `name`, `description`, `rotation_pattern`, `weekly_off_1`, `weekly_off_2`, `weekly_off_2_week` + entries via `ShiftRosterEntry`.

**DepartmentShift** (`department_shifts`): `department_id`, `shift_id`, `effective_from`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/shifts/` | `shift.read` | List shifts (paginated) |
| POST | `/shifts/` | `shift.manage` | Create shift |
| GET | `/shifts/{id}` | `shift.read` | Get shift |
| PUT | `/shifts/{id}` | `shift.manage` | Update shift |
| DELETE | `/shifts/{id}` | `shift.manage` | Delete shift |
| POST | `/shifts/assign` | `shift.manage` | Assign shift to employee |
| GET | `/shifts/schedules/` | `shift.read` | List shift schedules |
| GET | `/shift-groups/` | `shift.read` | List shift groups |
| POST | `/shift-groups/` | `shift.read` | Create shift group |
| PUT | `/shift-groups/{id}` | `shift.read` | Update shift group |
| DELETE | `/shift-groups/{id}` | `shift.read` | Delete shift group |
| GET | `/shift-groups/{id}/shifts` | `shift.read` | Get group's shifts |
| GET | `/shift-rosters/` | `shift.read` | List rosters |
| POST | `/shift-rosters/` | `shift.read` | Create roster |
| PUT | `/shift-rosters/{id}` | `shift.read` | Update roster |
| DELETE | `/shift-rosters/{id}` | `shift.read` | Delete roster |
| GET | `/shift-rosters/{id}/entries` | `shift.read` | Get roster entries |
| GET | `/department-shifts/` | `shift.read` | List department shifts |
| POST | `/department-shifts/` | `shift.read` | Create department shift |
| DELETE | `/department-shifts/{id}` | `shift.read` | Delete department shift |

### Feature Flags
`shift` — gates all four routers (shifts, shift_groups, shift_rosters, department_shifts).

### Permissions
`shift.read`, `shift.manage` — **properly granular on main shifts router**; sub-routers (groups, rosters, dept shifts) only enforce `shift.read` on all CRUD ops.

### Dependencies On
- **Employee**: FK `employee_id` on schedules
- **Tenants**: FK on all entities
- **Attendance**: Referenced by `Attendance.shift_id`

### Files
- Backend: `models/shift.py`, `models/shift_group.py`, `models/shift_roster.py`, `models/department_shift.py`, `schemas/shift.py`, `schemas/shift_group.py`, `schemas/shift_roster.py`, `schemas/department_shift.py`, `services/shift.py`, `api/v1/endpoints/shifts.py`, `shift_groups.py`, `shift_rosters.py`, `department_shifts.py`
- Frontend: `screens/shifts/`, `providers/shift_provider.dart`, `services/shift_service.dart`

---

## 5. Leaves

### Purpose
Leave type definitions, per-employee balance tracking, leave application, and approval workflow (approve/reject/cancel).

### Key Entities

**LeaveType** (`leave_types`): `name`, `code`, `default_days`, `is_paid`, `carry_forward`, `max_consecutive`, `is_active`. Unique: `(tenant_id, code)`.

**LeaveBalance** (`leave_balances`): `employee_id` FK, `leave_type_id` FK, `year`, `total_days`, `used_days`, `pending_days`, `carried_forward`. Unique: `(tenant_id, employee_id, leave_type_id, year)`.

**LeaveRequest** (`leave_requests`): `employee_id` FK, `leave_type_id` FK, `start_date`, `end_date`, `total_days`, `reason`, `status` (pending/approved/rejected/cancelled), `approved_by` FK, `approved_at`, `rejection_reason`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/leaves/types` | `leave.read` | List leave types |
| POST | `/leaves/types` | `leave.approve` | Create leave type |
| GET | `/leaves/balance/{employee_id}` | `leave.read` | Get leave balances |
| POST | `/leaves/apply` | `leave.approve` | Apply for leave |
| GET | `/leaves/requests` | `leave.read` | List leave requests |
| PUT | `/leaves/requests/{id}/approve` | `leave.approve` | Approve leave |
| PUT | `/leaves/requests/{id}/reject` | `leave.approve` | Reject leave |
| PUT | `/leaves/requests/{id}/cancel` | `leave.approve` | Cancel leave |

### Feature Flags
`leave` — gates the entire module.

### Permissions
`leave.read`, `leave.approve` — **properly granular**.

### Service Methods
- `apply_leave()` — Validates dates, calculates weekdays, checks balance, checks overlaps
- `approve_leave()` — PENDING→APPROVED, moves days from pending to used
- `reject_leave()` — PENDING→REJECTED, decrements pending
- `cancel_leave()` — Restores balance accordingly

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`
- **Attendance**: Referenced in daily summary for on-leave count

### Files
- Backend: `models/leave.py`, `schemas/leave.py`, `services/leave.py`, `api/v1/endpoints/leaves.py`
- Frontend: `screens/leaves/`, `providers/leave_provider.dart`, `services/leave_service.dart`

---

## 6. Payroll

### Purpose
Salary structure management, payslip generation (batch), and employee loan tracking.

### Key Entities

**SalaryStructure** (`salary_structures`): `employee_id` FK, `basic`, `hra`, `da`, `conveyance`, `medical`, `special`, `pf_employee`, `pf_employer`, `esi_employee`, `esi_employer`, `professional_tax`, `income_tax`, `effective_from`, `is_active`. Unique: `(employee_id, effective_from)`.

**PaySlip** (`pay_slips`): `employee_id` FK, `month`, `year`, all salary components, `gross_earnings`, deductions (`pf`, `esi`, `pt`, `it`), `total_deductions`, `net_pay`, `working_days`, `present_days`, `absent_days`, `leave_days`, `ot_hours`, `ot_amount`, `lop_days`, `lop_amount`, `status` (draft/calculated/frozen/paid), `generated_at`. Unique: `(tenant_id, employee_id, month, year)`.

**Loan** (`loans`): `employee_id` FK, `loan_type`, `amount`, `emi_amount`, `start_date`, `total_installments`, `paid_installments`, `status`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/payroll/salary-structure` | `payroll.read` | List salary structures |
| POST | `/payroll/salary-structure` | `payroll.manage` | Create salary structure |
| PUT | `/payroll/salary-structure/{id}` | `payroll.manage` | Update salary structure |
| GET | `/payroll/payslips` | `payroll.read` | List payslips |
| POST | `/payroll/payslips/generate` | `payroll.manage` | Batch-generate payslips |
| PUT | `/payroll/payslips/{id}/freeze` | `payroll.manage` | Freeze payslip |
| GET | `/payroll/loans` | `payroll.read` | List loans |
| POST | `/payroll/loans` | `payroll.manage` | Create loan |

### Feature Flags
`payroll` — gates the entire module.

### Permissions
`payroll.read`, `payroll.manage` — **properly granular**.

### Dependencies On
- **Employee**: FK `employee_id` on all entities
- **Attendance**: Uses attendance data for payslip generation (present/absent/leave days)

### Files
- Backend: `models/payroll.py`, `models/tax.py`, `schemas/payroll.py`, `api/v1/endpoints/payroll.py`
- Frontend: `screens/payroll/`

---

## 7. Visitors

### Purpose
Visitor registration, pass issuance, check-in/check-out, live occupancy tracking, and historical reporting. Integrates with eSSL for visitor desk validation.

### Key Entities

**Visitor** (`visitors`): `name`, `phone`, `email`, `photo_url`, `id_proof_type`, `id_proof_number`, `company`, `address`.

**VisitorPass** (`visitor_passes`): `visitor_id` FK, `host_employee_id` FK, `purpose`, `expected_date`, `check_in_time`, `check_out_time`, `pass_number` (unique per tenant), `status` (pending/checked_in/checked_out/expired/cancelled), `badge_number`, `zone_access` (JSONB), `visitor_desk_validated`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/visitors/` | `visitor.read` | List visitors |
| POST | `/visitors/` | `visitor.manage` | Register visitor |
| POST | `/visitors/passes` | `visitor.manage` | Create visitor pass |
| POST | `/visitors/passes/{id}/check-in` | `visitor.manage` | Check in visitor |
| POST | `/visitors/passes/{id}/check-out` | `visitor.manage` | Check out visitor |
| GET | `/visitors/active` | `visitor.read` | List active (checked-in) visitors |
| GET | `/visitors/passes` | `visitor.read` | List passes |
| GET | `/visitors/history` | `visitor.read` | Historical pass data |

### Feature Flags
`visitor` — gates the entire module.

### Permissions
`visitor.read`, `visitor.manage` — **properly granular**.

### Dependencies On
- **Employee**: FK `host_employee_id`
- **eSSL**: SOAP `validate_visitor_desk` on check-in
- **Access Control**: AccessLog references visitor_passes

### Files
- Backend: `models/visitor.py`, `schemas/visitor.py`, `services/visitor.py`, `api/v1/endpoints/visitors.py`
- Frontend: `screens/visitors/` (4 screens), `providers/visitor_provider.dart`, `services/visitor_service.dart`

---

## 8. Access Control

### Purpose
Physical access zone management, door management, user access level grants, and access logging.

### Key Entities

**AccessZone** (`access_zones`): `name`, `description`, `branch_id` FK, `is_restricted`, `access_level_required`. Unique: `(tenant_id, branch_id, name)`.

**Door** (`doors`): `name`, `zone_id` FK, `device_id` FK, `is_active`.

**UserAccessLevel** (`user_access_levels`): `employee_id` FK, `zone_id` FK, `access_level`, `granted_by` FK, `valid_from`, `valid_to`. Unique: `(tenant_id, employee_id, zone_id)`.

**AccessLog** (`access_logs`): `employee_id` FK, `visitor_id` FK, `visitor_pass_id` FK, `door_id` FK, `access_time`, `access_type` (entry/exit), `granted`, `denial_reason`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/access-control/zones` | `access_control.read` | List zones |
| POST | `/access-control/zones` | `access_control.read` | Create zone |
| GET | `/access-control/doors` | `access_control.read` | List doors |
| POST | `/access-control/doors` | `access_control.read` | Create door |
| POST | `/access-control/grant` | `access_control.read` | Grant access |
| DELETE | `/access-control/grant/{id}` | `access_control.read` | Revoke access |
| GET | `/access-control/check` | `access_control.read` | Check access |
| GET | `/access-control/logs` | `access_control.read` | List access logs |

### Feature Flags
`access_control` — gates the entire module.

### Permissions
`access_control.read` — **single permission for all ops including writes** (security gap).

### Dependencies On
- **Branch**: FK `branch_id` on AccessZone
- **Device**: FK `device_id` on Door
- **Employee**: FK `employee_id`, `granted_by`
- **Visitor**: FK `visitor_id`, `visitor_pass_id`

### Files
- Backend: `models/access_control.py`, `schemas/access_control.py`, `services/access_control.py`, `api/v1/endpoints/access_control.py`
- Frontend: `screens/access_control/` (3 screens), `services/access_control_service.dart`

---

## 9. Devices

### Purpose
Biometric and access-control terminal lifecycle management: registration, status polling, health aggregation, activity logging, remote sync/reboot commands.

### Key Entities

**Device** (`devices`): `serial_number`, `device_name`, `model`, `firmware_version`, `ip_address`, `port`, `location`, `branch_id` FK, `last_ping`, `last_sync`, `status` (online/offline/inactive/error), `is_active`, `device_type` (biometric/access_control/both), `communication_mode` (tcp_ip/wifi/4g). Unique: `(tenant_id, serial_number)`.

**DeviceLog** (`device_logs`): `device_id` FK, `log_type`, `message`, `raw_data` (JSONB).

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/devices/health` | `device.read` | Aggregated device health |
| GET | `/devices/` | `device.read` | List devices (paginated) |
| POST | `/devices/` | `device.manage` | Create device |
| GET | `/devices/{id}` | `device.read` | Get device |
| PUT | `/devices/{id}` | `device.manage` | Update device |
| DELETE | `/devices/{id}` | `device.manage` | Delete device |
| GET | `/devices/{id}/logs` | `device.read` | Device logs |
| POST | `/devices/{id}/sync` | `device.manage` | Trigger sync |
| POST | `/devices/{id}/command` | `device.manage` | Send device command |

### Feature Flags
`device` — gates the entire module.

### Permissions
`device.read`, `device.manage` — **properly granular**.

### Dependencies On
- **Branch**: FK `branch_id`
- **eSSL**: Device commands via eSSL SOAP
- **Attendance**: PunchLog references devices

### Files
- Backend: `models/device.py`, `schemas/device.py`, `services/device.py`, `api/v1/endpoints/devices.py`
- Frontend: `screens/devices/`, `providers/device_provider.dart`, `services/device_service.dart`

---

## 10. eSSL Biometric

### Purpose
Integration with eSSL eBioserverNew biometric devices via SOAP 1.1. Handles server configuration, employee/attendance/device sync, cursor-based incremental sync, conflict resolution, pause/resume/cancel, duplicate detection, and enterprise dashboards.

### Key Entities

**EsslServer** (`essl_servers`): `server_url`, `username`, `password_encrypted`, `timeout_seconds`, `timezone`, `auto_sync_enabled`, sync intervals, conflict policies, `status`, `last_connected_at`, `server_version`.

**EsslSyncCursor** (`essl_sync_cursors`): `essl_server_id` FK, `cursor_type`, `last_transaction_id`, `last_punch_time`.

**EsslSyncHistory** (`essl_sync_history`): `sync_type`, `status`, `started_at`/`completed_at`, record counts, `triggered_by`, `progress_percent`, `is_paused`/`is_cancelled`.

**EsslSyncJob** (`essl_sync_jobs`): `job_type`, `interval_minutes`, `is_enabled`, `last_run_at`, `next_run_at`.

**EsslSyncError** (`essl_sync_errors`): `sync_history_id` FK, `error_code`, `error_message`, `entity_type`, `raw_data`.

**EsslEmployeeMapping** (`essl_employee_mappings`): Bridge eSSL `employee_code` ↔ local `Employee.id`.

**EsslDeviceMapping** (`essl_device_mappings`): Bridge eSSL `serial_number` ↔ local `Device.id`.

**EsslLocation** (`essl_locations`): Per-server location mapping.

### API Endpoints (27 total)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/essl/` | Create server config |
| GET | `/essl/` | List servers |
| GET | `/essl/{id}` | Get server |
| PUT | `/essl/{id}` | Update server |
| DELETE | `/essl/{id}` | Delete server + cascade |
| POST | `/essl/{id}/test` | Connection test |
| POST | `/essl/{id}/sync/employees` | Manual employee sync |
| POST | `/essl/{id}/sync/attendance` | Manual attendance sync |
| POST | `/essl/{id}/sync/devices` | Manual device sync |
| POST | `/essl/{id}/sync/initial` | First-time attendance import |
| POST | `/essl/{id}/reprocess` | Reprocess raw logs |
| POST | `/essl/{id}/recover` | Offline catch-up sync |
| GET | `/essl/{id}/recovery-status` | Recovery monitoring |
| GET | `/essl/{id}/cursor-integrity` | Validate/repair cursor |
| GET | `/essl/{id}/clock-drift` | Device clock skew detection |
| POST | `/essl/{id}/sync/{history_id}/pause` | Pause sync |
| POST | `/essl/{id}/sync/{history_id}/resume` | Resume sync |
| POST | `/essl/{id}/sync/{history_id}/cancel` | Cancel sync |
| GET | `/essl/{id}/sync/{history_id}/progress` | Sync progress |
| GET | `/essl/{id}/sync/history` | Sync history |
| GET | `/essl/{id}/sync/errors` | Sync errors |
| GET | `/essl/duplicates/stats` | Duplicate statistics |
| GET | `/essl/duplicates/cross-server` | Cross-server duplicates |
| POST | `/essl/duplicates/resolve` | Resolve duplicates |
| GET | `/essl/dashboard/sync-status` | Per-server dashboard |
| GET | `/essl/dashboard/enterprise` | Enterprise dashboard |
| GET/POST/PUT/DELETE | `/essl/{id}/locations/*` | Location CRUD |

### Feature Flags
`biometric` — gates the entire module.

### Permissions
`biometric.read` — **single permission for all ops including writes** (no `biometric.write`).

### Services
- `ESSLSoapService` — Raw SOAP 1.1 integration with circuit breaker + retry
- `ESSLClient` — Higher-level client with Redis caching
- `EsslConnectorService` — Core sync orchestrator (1271 lines)
- `EsslDashboardService` — Aggregated dashboard data
- `DuplicateDetector` — Cross-server duplicate detection
- `SyncAuditService` — Sync audit logging

### Dependencies On
- **Employee**: Employee mapping, sync
- **Attendance**: Raw log ingestion, AttendanceProcessor
- **Device**: Device mapping, sync
- **Core**: Encryption for passwords

### Files
- Backend: 5 models, 1 schema file, 4 service files, 2 endpoint files
- Frontend: `providers/essl_provider.dart`, `services/essl_service.dart`

---

## 11. Recruitment

### Purpose
End-to-end applicant tracking: requisition approval, job posting, candidate pipeline management, interview scheduling, and offer lifecycle.

### Key Entities

**JobRequisition** (`job_requisitions`): `title`, `department_id`, `branch_id`, `hiring_manager_id`, `employment_type`, `openings`, `experience_min/max`, `salary_min/max`, `skills`, `description`, `status` (draft/pending_approval/approved), `approved_by`, `approved_at`.

**JobOpening** (`job_openings`): `requisition_id`, `title`, `department_id`, `branch_id`, `description`, `requirements`, `employment_type`, `openings`, `salary_min/max`, `location`, `status` (draft/published/closed), `published_at`, `closed_at`, `created_by`.

**Candidate** (`candidates`): `opening_id`, `first_name`, `last_name`, `email`, `phone`, `resume_path`, `skills`, `experience_years`, `education`, `current_company`, `current_designation`, `expected_salary`, `notice_period`, `source`, `stage` (applied→screening→hr_interview→technical_interview→manager_interview→final_round→offer→accepted→joined/rejected), `rating`, `notes`, `tags`, `applied_at`.

**Interview** (`interviews`): `candidate_id` FK, `opening_id`, `interviewer_id` FK→users, `scheduled_at`, `duration_minutes`, `location`, `meeting_link`, `interview_type`, `status` (scheduled/completed/cancelled/no_show), `feedback`, `rating`, `recommendation`.

**Offer** (`offers`): `candidate_id` FK, `opening_id`, `offered_salary`, `offered_designation`, `offered_department_id`, `joining_date`, `expiry_date`, `status` (draft/sent/pending/accepted/rejected), `offer_letter_path`, `notes`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/recruitment/requisitions` | `recruitment.read` | List requisitions |
| POST | `/recruitment/requisitions` | `recruitment.manage` | Create requisition |
| PUT | `/recruitment/requisitions/{id}` | `recruitment.manage` | Update requisition |
| POST | `/recruitment/requisitions/{id}/submit` | `recruitment.manage` | Submit for approval |
| POST | `/recruitment/requisitions/{id}/approve` | `recruitment.manage` | Approve requisition |
| GET | `/recruitment/openings` | `recruitment.read` | List openings (with candidate counts) |
| POST | `/recruitment/openings` | `recruitment.manage` | Create opening |
| PUT | `/recruitment/openings/{id}` | `recruitment.manage` | Update opening |
| POST | `/recruitment/openings/{id}/publish` | `recruitment.manage` | Publish opening |
| POST | `/recruitment/openings/{id}/close` | `recruitment.manage` | Close opening |
| GET | `/recruitment/candidates` | `recruitment.read` | List candidates |
| POST | `/recruitment/candidates` | `recruitment.manage` | Create candidate |
| PUT | `/recruitment/candidates/{id}` | `recruitment.manage` | Update candidate |
| POST | `/recruitment/candidates/{id}/move` | `recruitment.manage` | Move candidate stage |
| GET | `/recruitment/interviews` | `recruitment.read` | List interviews |
| POST | `/recruitment/interviews` | `recruitment.manage` | Schedule interview |
| PUT | `/recruitment/interviews/{id}` | `recruitment.manage` | Update interview |
| POST | `/recruitment/interviews/{id}/feedback` | `recruitment.manage` | Submit feedback |
| GET | `/recruitment/offers` | `recruitment.read` | List offers |
| POST | `/recruitment/offers` | `recruitment.manage` | Create offer |
| PUT | `/recruitment/offers/{id}` | `recruitment.manage` | Update offer |
| POST | `/recruitment/offers/{id}/accept` | `recruitment.manage` | Accept offer |
| POST | `/recruitment/offers/{id}/reject` | `recruitment.manage` | Reject offer |
| GET | `/recruitment/stats` | `recruitment.read` | Recruitment stats |

### Feature Flags
None — `require_feature` is imported but not used.

### Permissions
`recruitment.read`, `recruitment.manage` — **properly granular**.

### Dependencies On
- **Employee**: FK `hiring_manager_id`, `approved_by`
- **Department**: FK `department_id`, `offered_department_id`
- **Branch**: FK `branch_id`
- **Users**: FK `interviewer_id`, `created_by`

### Files
- Backend: `models/recruitment.py`, `api/v1/endpoints/recruitment.py`
- Frontend: `screens/recruitment/`

---

## 12. Performance

### Purpose
Review cycles, goal tracking, performance reviews, competency management, and performance-based recommendations.

### Key Entities

**ReviewCycle** (`review_cycles`): `name`, `description`, `cycle_type` (monthly/quarterly/half_yearly/annual), `start_date`, `end_date`, `self_review_due`, `manager_review_due`, `hr_review_due`, `status`, `created_by` FK→users.

**Goal** (`goals`): `employee_id` FK, `cycle_id` FK, `title`, `description`, `goal_type` (individual/team/department/company), `category`, `weightage`, `target_value`, `current_value`, `progress`, `due_date`, `status` (draft/approved/completed/overdue), `approved_by` FK, `approved_at`.

**PerformanceReview** (`performance_reviews`): `cycle_id` FK, `employee_id` FK, `reviewer_id` FK→users, `review_type` (self/manager/360), `status`, `rating`, `strengths`, `improvements`, `comments`, `goals_achievement`, `competency_scores` (JSON as Text), `submitted_at`.

**Competency** (`competencies`): `name`, `description`, `category`, `is_active`, `sort_order`.

**PerformanceRecommendation** (`performance_recommendations`): `review_id` FK, `employee_id` FK, `recommended_by` FK→users, `recommendation_type`, `details`, `salary_increment`, `new_designation_id` FK, `status`, `approved_by` FK.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/performance/cycles` | `performance.read` | List review cycles |
| POST | `/performance/cycles` | `performance.manage` | Create cycle |
| PUT | `/performance/cycles/{id}` | `performance.manage` | Update cycle |
| POST | `/performance/cycles/{id}/publish` | `performance.manage` | Publish cycle |
| GET | `/performance/goals` | `performance.read` | List goals |
| POST | `/performance/goals` | `performance.manage` | Create goal |
| PUT | `/performance/goals/{id}` | `performance.manage` | Update goal |
| PUT | `/performance/goals/{id}/progress` | `performance.manage` | Update progress |
| POST | `/performance/goals/{id}/approve` | `performance.manage` | Approve goal |
| GET | `/performance/reviews` | `performance.read` | List reviews |
| POST | `/performance/reviews` | `performance.manage` | Create review |
| PUT | `/performance/reviews/{id}/submit` | `performance.manage` | Submit review |
| GET | `/performance/competencies` | `performance.read` | List competencies |
| POST | `/performance/competencies` | `performance.manage` | Create competency |
| GET | `/performance/recommendations` | `performance.read` | List recommendations |
| POST | `/performance/recommendations` | `performance.manage` | Create recommendation |
| PUT | `/performance/recommendations/{id}/approve` | `performance.manage` | Approve recommendation |
| GET | `/performance/stats` | `performance.read` | Dashboard stats |

### Feature Flags
None — `require_feature` imported but not used.

### Permissions
`performance.read`, `performance.manage` — **properly granular**.

### Dependencies On
- **Employee**: FK `employee_id` on goals, reviews, recommendations
- **Users**: FK `created_by`, `reviewer_id`, `recommended_by`, `approved_by`
- **Designations**: FK `new_designation_id` on recommendations

### Files
- Backend: `models/performance.py`, `api/v1/endpoints/performance.py`
- Frontend: `screens/performance/` (2 screens)

---

## 13. Assets

### Purpose
Company asset lifecycle: registration, assignment, return, maintenance, and warranty tracking. **Note**: Duplicate endpoint sets exist in `/assets/` and `/hr/assets`.

### Key Entities

**CompanyAsset** (`company_assets`): `name`, `asset_code`, `category`, `serial_number`, `model`, `brand`, `vendor`, `purchase_date`, `purchase_cost`, `warranty_expiry`, `location`, `assigned_to` FK, `status` (available/assigned/maintenance/retired), `description`.

**TravelRequest** (`travel_requests`): `employee_id` FK, `destination`, `purpose`, `from_date`, `to_date`, `estimated_cost`, `status`, `approved_by` FK, `approved_at`.

### API Endpoints — Set A (`/assets/`)

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/assets/stats` | `asset.read` | Dashboard stats |
| GET | `/assets/` | `asset.read` | List assets (paginated, filterable) |
| POST | `/assets/` | `asset.read` | Create asset |
| GET | `/assets/{id}` | `asset.read` | Get asset |
| PUT | `/assets/{id}` | `asset.read` | Update asset |
| POST | `/assets/{id}/assign` | `asset.read` | Assign to employee |
| POST | `/assets/{id}/return` | `asset.read` | Return asset |
| POST | `/assets/{id}/maintenance` | `asset.read` | Set maintenance |

### API Endpoints — Set B (`/hr/assets`)

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/hr/assets` | `hr.read` | List assets (no pagination) |
| POST | `/hr/assets` | `hr.read` | Create asset |
| PUT | `/hr/assets/{id}` | `hr.read` | Update asset |
| DELETE | `/hr/assets/{id}` | `hr.read` | Delete asset |

### Feature Flags
`assets` — gates Set A only. Set B (HR Ops) has no feature flag.

### Permissions
- Set A: `asset.read` — **single permission for all ops**
- Set B: `hr.read` — **shared with all HR Ops**

### Dependencies On
- **Employee**: FK `assigned_to`, `employee_id`, `approved_by`

### Files
- Backend: `models/asset_travel.py`, `api/v1/endpoints/assets.py`, `api/v1/endpoints/hr_ops.py`
- Frontend: `screens/assets/`, `screens/hr/asset_screen.dart`

---

## 14. Reports

### Purpose
Generate streamed file downloads (PDF/XLSX/CSV) for attendance, visitor, and device reports.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/reports/attendance/daily` | `report.read` | Daily attendance snapshot |
| GET | `/reports/attendance/monthly` | `report.read` | Monthly attendance |
| GET | `/reports/attendance/employee/{id}` | `report.read` | Per-employee report |
| GET | `/reports/attendance/late` | `report.read` | Late arrivals |
| GET | `/reports/attendance/overtime` | `report.read` | Overtime report |
| GET | `/reports/attendance/absent` | `report.read` | Absent employees |
| GET | `/reports/attendance/early-going` | `report.read` | Early departures |
| GET | `/reports/attendance/missed-punch` | `report.read` | Missed punches |
| GET | `/reports/attendance/department-summary` | `report.read` | Department summary |
| GET | `/reports/attendance/ot-summary` | `report.read` | OT summary |
| GET | `/reports/attendance/muster-roll` | `report.read` | Statutory muster roll |
| GET | `/reports/visitors` | `report.read` | Visitor report |
| GET | `/reports/devices` | `report.read` | Device report |
| POST | `/reports/attendance/recalculate` | `report.read` | **Reprocess attendance** (mutation) |

### Feature Flags
`reports` — gates the entire module.

### Permissions
`report.read` — **single permission including mutation endpoint** (security gap: `recalculate` is a POST but only requires read).

### Dependencies On
- **Attendance**: Queries Attendance, PunchLog, OTRegister models
- **Employee**: Employee, Department for grouping
- **Visitor**: VisitorPass for visitor reports
- **Device**: Device for device reports
- **eSSL**: OTRegister for OT summary

### Files
- Backend: `schemas/report.py`, `services/report.py` (556 lines), `api/v1/endpoints/reports.py`
- Frontend: `screens/reports/`, `services/report_service.dart`

---

## 15. Lifecycle

### Purpose
Employee lifecycle event management: promotion, transfer, confirmation, resignation, termination, reactivation, salary revision. All logic inline (no service layer).

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/employees/{id}/timeline` | `employee.read` | Full event history |
| POST | `/employees/{id}/promote` | `employee.manage` | Promote employee |
| POST | `/employees/{id}/transfer` | `employee.manage` | Transfer employee |
| POST | `/employees/{id}/confirm` | `employee.manage` | Confirm from probation |
| POST | `/employees/{id}/resign` | `employee.manage` | Record resignation |
| POST | `/employees/{id}/terminate` | `employee.manage` | Terminate employee |
| POST | `/employees/{id}/reactivate` | `employee.manage` | Reactivate employee |
| POST | `/employees/{id}/salary-revision` | `employee.manage` | Salary revision |

### Feature Flags
None — `require_feature` imported but not used.

### Permissions
`employee.read`, `employee.manage` — **reuses employee permissions**.

### Dependencies On
- **Employee**: Direct mutation of Employee fields
- **Timeline**: Creates EmployeeEvent audit records
- **Payroll**: SalaryStructure versioning on promote/salary-revision

### Files
- Backend: `api/v1/endpoints/lifecycle.py` (inline logic, no service)

---

## 16. Timeline

### Purpose
Employee event/history timeline — stores discrete events (promotions, transfers, disciplinary actions).

### Key Entities

**EmployeeEvent** (`employee_events`): `employee_id` FK, `event_type` (free-form string), `title`, `description`, `event_date`, `created_by` FK→users.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/timeline/` | `employee.read` | List events (requires `employee_id` query) |
| POST | `/timeline/` | `employee.read` | Create event |
| DELETE | `/timeline/{id}` | `employee.read` | Delete event |

### Feature Flags
None — `require_feature` imported but not used.

### Permissions
`employee.read` — **single permission for all ops including create/delete** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`
- **Users**: FK `created_by`

### Files
- Backend: `models/timeline.py`, `schemas/timeline.py`, `api/v1/endpoints/timeline.py`

---

## 17. Onboarding

### Purpose
Employee onboarding task management — create, assign, track, and complete onboarding tasks.

### Key Entities

**OnboardingTask** (`onboarding_tasks`): `employee_id` FK, `title`, `description`, `assigned_to` FK, `due_date`, `status` (pending/in_progress/completed), `completed_at`, `order_index`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/onboarding/` | `onboarding.read` | List tasks (filterable by employee, status) |
| POST | `/onboarding/` | `onboarding.read` | Create task |
| PUT | `/onboarding/{id}` | `onboarding.read` | Update task |
| DELETE | `/onboarding/{id}` | `onboarding.read` | Delete task |

### Feature Flags
`onboarding` — gates the entire module.

### Permissions
`onboarding.read` — **single permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`, `assigned_to`

### Files
- Backend: `models/onboarding.py`, `schemas/onboarding.py`, `api/v1/endpoints/onboarding.py`

---

## 18. Exit Requests

### Purpose
Employee resignation/exit workflow: submission, approval/rejection, clearance tracking.

### Key Entities

**ExitRequest** (`exit_requests`): `employee_id` FK, `resignation_date`, `last_working_date`, `reason`, `status` (pending/approved/rejected/completed), `approved_by` FK, `approved_at`, `exit_interview_notes`, `clearance_status`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/exit-requests/` | `exit.read` | List exit requests |
| POST | `/exit-requests/` | `exit.read` | Create exit request |
| PUT | `/exit-requests/{id}` | `exit.read` | Update/approve exit request |

### Feature Flags
`exit_management` — gates the entire module.

### Permissions
`exit.read` — **single permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`

### Files
- Backend: `models/exit.py`, `schemas/exit.py`, `api/v1/endpoints/exit_requests.py`

---

## 19. OT Register

### Purpose
Overtime hour tracking with approval workflow.

### Key Entities

**OTRegister** (`ot_register`): `employee_id` FK, `date`, `ot_hours`, `ot_type` (normal/holiday/weekly_off), `status` (pending/approved/rejected/preserved), `approved_by` FK, `remarks`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/ot-register/` | `attendance.read` | List OT records |
| POST | `/ot-register/` | `attendance.read` | Create OT record |
| PUT | `/ot-register/{id}` | `attendance.read` | Update/approve OT |
| DELETE | `/ot-register/{id}` | `attendance.read` | Delete OT record |

### Feature Flags
`overtime` — gates the entire module.

### Permissions
`attendance.read` — **reuses attendance permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`

### Files
- Backend: `models/ot_register.py`, `schemas/ot_register.py`, `api/v1/endpoints/ot_register.py`

---

## 20. Outdoor Duties

### Purpose
Track employees working outside the office with approval workflow.

### Key Entities

**OutdoorDuty** (`outdoor_duties`): `employee_id` FK, `date`, `from_time`, `to_time`, `reason`, `location`, `status` (pending/approved/rejected), `approved_by` FK, `approved_at`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/outdoor-duties/` | `attendance.read` | List OD records |
| POST | `/outdoor-duties/` | `attendance.read` | Create OD |
| PUT | `/outdoor-duties/{id}` | `attendance.read` | Update/approve OD |
| DELETE | `/outdoor-duties/{id}` | `attendance.read` | Delete OD |

### Feature Flags
`outdoor_duty` — gates the entire module.

### Permissions
`attendance.read` — **reuses attendance permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`

### Files
- Backend: `models/outdoor_duty.py`, `schemas/outdoor_duty.py`, `api/v1/endpoints/outdoor_duties.py`

---

## 21. Work Codes

### Purpose
Project/task code management for time allocation tracking.

### Key Entities

**WorkCode** (`work_codes`): `code`, `name`, `description`, `is_active`. Unique: `(tenant_id, code)`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/work-codes/` | `attendance.read` | List work codes |
| POST | `/work-codes/` | `attendance.read` | Create work code |
| PUT | `/work-codes/{id}` | `attendance.read` | Update work code |
| DELETE | `/work-codes/{id}` | `attendance.read` | Delete work code |

### Feature Flags
None — `require_feature` imported but not used.

### Permissions
`attendance.read` — **reuses attendance permission for all ops** (security gap).

### Dependencies On
- **Tenants**: FK `tenant_id`

### Files
- Backend: `models/work_code.py`, `schemas/work_code.py`, `api/v1/endpoints/work_codes.py`

---

## 22. Expense/Benefits

### Purpose
Expense claims, tax declarations, and employee benefits management.

### Key Entities

**ExpenseCategory** (`expense_categories`): `name`, `description`, `max_amount`, `is_active`.

**ExpenseClaim** (`expense_claims`): `employee_id` FK, `category_id` FK, `amount`, `description`, `receipt_path`, `status` (pending/approved/rejected), `approved_by` FK, `approved_at`.

**TaxDeclaration** (`tax_declarations`): `employee_id` FK, `financial_year`, `section`, `description`, `amount`, `proof_path`, `status`.

**Benefit** (`benefits`): `name`, `description`, `benefit_type`, `amount`, `is_active`.

**EmployeeBenefit** (`employee_benefits`): `employee_id` FK, `benefit_id` FK, `start_date`, `end_date`, `status`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/finance/expense-categories` | `expense.read` | List categories |
| POST | `/finance/expense-categories` | `expense.read` | Create category |
| GET | `/finance/expenses` | `expense.read` | List claims |
| POST | `/finance/expenses` | `expense.read` | Create claim |
| PUT | `/finance/expenses/{id}` | `expense.read` | Update claim |
| POST | `/finance/expenses/{id}/approve` | `expense.read` | Approve claim |
| POST | `/finance/expenses/{id}/reject` | `expense.read` | Reject claim |
| GET | `/finance/tax-declarations` | `expense.read` | List declarations |
| POST | `/finance/tax-declarations` | `expense.read` | Create declaration |
| GET | `/finance/benefits` | `expense.read` | List benefits |
| POST | `/finance/benefits` | `expense.read` | Create benefit |
| GET | `/finance/employee-benefits` | `expense.read` | List employee benefits |

### Feature Flags
`expense` — gates the entire module.

### Permissions
`expense.read` — **single permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK `employee_id`, `approved_by`

### Files
- Backend: `models/expense.py`, `models/benefit.py`, `models/tax.py`, `schemas/hr_features.py`, `api/v1/endpoints/expense_benefits.py`

---

## 23. HR Ops

### Purpose
Umbrella endpoints for five HR sub-domains: Company Assets, Travel Requests, Announcements, Polls, and Notification Templates.

### Key Entities

**Announcement** (`announcements`): `title`, `body`, `priority`, `publish_at`, `expires_at`, `is_active`, `created_by` FK→users.

**Poll** (`polls`): `question`, `options` (JSONB), `expires_at`, `is_anonymous`, `is_active`, `created_by` FK→users.

**PollResponse** (`poll_responses`): `poll_id` FK, `employee_id` FK, `selected_option` (int).

**NotificationTemplate** (`notification_templates`): `name`, `event_type`, `channel`, `subject_template`, `body_template`, `is_active`.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/hr/assets` | `hr.read` | List assets |
| POST | `/hr/assets` | `hr.read` | Create asset |
| PUT | `/hr/assets/{id}` | `hr.read` | Update asset |
| DELETE | `/hr/assets/{id}` | `hr.read` | Delete asset |
| GET | `/hr/travel` | `hr.read` | List travel requests |
| POST | `/hr/travel` | `hr.read` | Create travel request |
| PUT | `/hr/travel/{id}` | `hr.read` | Update/approve travel |
| GET | `/hr/announcements` | `hr.read` | List announcements |
| POST | `/hr/announcements` | `hr.read` | Create announcement |
| DELETE | `/hr/announcements/{id}` | `hr.read` | Delete announcement |
| GET | `/hr/polls` | `hr.read` | List polls |
| POST | `/hr/polls` | `hr.read` | Create poll |
| POST | `/hr/polls/{id}/vote` | `hr.read` | Cast vote |
| GET | `/hr/notification-templates` | `hr.read` | List templates |
| POST | `/hr/notification-templates` | `hr.read` | Create template |
| PUT | `/hr/notification-templates/{id}` | `hr.read` | Update template |

### Feature Flags
None — `require_feature` imported but not used.

### Permissions
`hr.read` — **single permission for all ops** (security gap).

### Dependencies On
- **Employee**: FK on assets, travel, poll responses
- **Users**: FK `created_by` on announcements, polls

### Files
- Backend: `models/asset_travel.py`, `models/announcement.py`, `models/notification_template.py`, `api/v1/endpoints/hr_ops.py`
- Frontend: `screens/hr/` (multiple screens)

---

## 24. ESS (Employee Self-Service)

### Purpose
Authenticated employee portal: view own attendance, leaves, payslips, documents, profile; clock in/out; update profile; change password.

### API Endpoints

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/ess/dashboard` | `ess.read` | Aggregated dashboard |
| GET | `/ess/attendance` | `ess.read` | My attendance |
| POST | `/ess/attendance/clock-in` | `ess.read` | Clock in |
| POST | `/ess/attendance/clock-out` | `ess.read` | Clock out |
| GET | `/ess/leaves` | `ess.read` | My leave requests |
| GET | `/ess/leaves/balance` | `ess.read` | My leave balance |
| GET | `/ess/payslips` | `ess.read` | My payslips |
| GET | `/ess/documents` | `ess.read` | My documents |
| GET | `/ess/profile` | `ess.read` | My profile |
| PUT | `/ess/profile` | `ess.read` | Update my profile |
| GET | `/ess/announcements` | `ess.read` | Company announcements |
| GET | `/ess/notifications` | `ess.read` | My notifications |
| POST | `/ess/change-password` | `ess.read` | Change password |

### Feature Flags
`ess` — gates the entire module.

### Permissions
`ess.read` — **single permission for all ops** (intentional for self-service scope).

### Dependencies On
- **Employee**: Resolves employee from current user email
- **Attendance**: Reads/creates attendance records
- **Leave**: Reads leave requests and balances
- **Payroll**: Reads payslips
- **Document**: Reads documents
- **Announcement**: Reads announcements
- **Notification**: Reads notifications

### Files
- Backend: `api/v1/endpoints/ess.py` (462 lines, inline logic)
- Frontend: `screens/ess/` (6 screens), routes in `core/router.dart`

---

## 25. Cross-Module Dependency Matrix

| Module | Depends On | Depended On By |
|--------|-----------|----------------|
| **Tenants** | — | ALL modules |
| **Employees** | Tenants, Shifts, Categories | Attendance, Leaves, Shifts, Payroll, Visitors, Access Control, Devices, Recruitment, Performance, Assets, Lifecycle, Timeline, Onboarding, Exit Requests, OT Register, Outdoor Duties, ESS, HR Ops |
| **Attendance** | Employees, Shifts, Leave, Devices, eSSL | Reports, ESS, Payroll |
| **Shifts** | Employees, Tenants | Attendance, Employees |
| **Leaves** | Employees | Attendance, ESS |
| **Payroll** | Employees, Attendance | ESS, Lifecycle |
| **Visitors** | Employees, eSSL, Access Control | Reports, Dashboard |
| **Access Control** | Branches, Devices, Employees, Visitors | — |
| **Devices** | Branches, eSSL | Attendance, Access Control |
| **eSSL** | Employees, Attendance, Devices | Visitors, Attendance |
| **Recruitment** | Employees, Departments, Branches | — |
| **Performance** | Employees, Users, Designations | — |
| **Assets** | Employees | HR Ops |
| **Reports** | Attendance, Employees, Visitors, Devices | — |
| **Lifecycle** | Employees, Timeline, Payroll | — |
| **Timeline** | Employees, Users | Lifecycle |
| **Onboarding** | Employees | — |
| **Exit Requests** | Employees | — |
| **OT Register** | Employees | Reports |
| **Outdoor Duties** | Employees | — |
| **Work Codes** | Tenants | — |
| **Expense/Benefits** | Employees | — |
| **HR Ops** | Employees, Users | — |
| **ESS** | ALL (read-only) | — |

---

## 26. Feature Flag Summary

| Feature Code | Module | Category | Sort Order |
|--------------|--------|----------|------------|
| `attendance` | Attendance | Core HR | 1 |
| `leave` | Leaves | Core HR | 2 |
| `shift` | Shifts | Core HR | 3 |
| `overtime` | OT Register | Core HR | 4 |
| `outdoor_duty` | Outdoor Duties | Core HR | 5 |
| `payroll` | Payroll | Finance | 10 |
| `expense` | Expense/Benefits | Finance | 11 |
| `tax` | Tax Declarations | Finance | 12 |
| `benefits` | Benefits | Finance | 13 |
| `loans` | Loans | Finance | 14 |
| `travel` | Travel Requests | HR Operations | 20 |
| `assets` | Assets | HR Operations | 21 |
| `documents` | Documents | HR Operations | 22 |
| `onboarding` | Onboarding | HR Operations | 23 |
| `exit_management` | Exit Requests | HR Operations | 24 |
| `announcements` | Announcements | HR Operations | 25 |
| `polls` | Polls | HR Operations | 26 |
| `visitor` | Visitors | Security | 30 |
| `access_control` | Access Control | Security | 31 |
| `biometric` | eSSL Biometric | Integration | 40 |
| `device` | Devices | Integration | 41 |
| `reports` | Reports | Analytics | 60 |
| `analytics` | Analytics | Analytics | 61 |
| `ess` | ESS | Employee | 80 |

**Modules WITHOUT feature flags** (always enabled):
- Employees (foundational — no gate)
- Recruitment (`require_feature` imported but unused)
- Performance (`require_feature` imported but unused)
- Lifecycle (`require_feature` imported but unused)
- Timeline (`require_feature` imported but unused)
- Work Codes (`require_feature` imported but unused)
- HR Ops (`require_feature` imported but unused)

---

## 27. Permission Matrix

| Module | Read Permission | Write Permission | Granularity |
|--------|----------------|-----------------|-------------|
| **Employees** | `employee.read` | `employee.create`, `.update`, `.delete` | Full CRUD |
| **Attendance** | `attendance.read` | `attendance.manage` | Read/Manage |
| **Shifts** | `shift.read` | `shift.manage` | Read/Manage (main router); Read-only on sub-routers |
| **Leaves** | `leave.read` | `leave.approve` | Read/Approve |
| **Payroll** | `payroll.read` | `payroll.manage` | Read/Manage |
| **Visitors** | `visitor.read` | `visitor.manage` | Read/Manage |
| **Access Control** | `access_control.read` | *(none)* | **Single permission** |
| **Devices** | `device.read` | `device.manage` | Read/Manage |
| **eSSL** | `biometric.read` | *(none)* | **Single permission** |
| **Recruitment** | `recruitment.read` | `recruitment.manage` | Read/Manage |
| **Performance** | `performance.read` | `performance.manage` | Read/Manage |
| **Assets** | `asset.read` | *(none)* | **Single permission** |
| **Reports** | `report.read` | *(none)* | **Single permission** |
| **Lifecycle** | `employee.read` | `employee.manage` | Reuses Employee perms |
| **Timeline** | `employee.read` | *(none)* | **Single permission** |
| **Onboarding** | `onboarding.read` | *(none)* | **Single permission** |
| **Exit Requests** | `exit.read` | *(none)* | **Single permission** |
| **OT Register** | `attendance.read` | *(none)* | **Single permission** |
| **Outdoor Duties** | `attendance.read` | *(none)* | **Single permission** |
| **Work Codes** | `attendance.read` | *(none)* | **Single permission** |
| **Expense/Benefits** | `expense.read` | *(none)* | **Single permission** |
| **HR Ops** | `hr.read` | *(none)* | **Single permission** |
| **ESS** | `ess.read` | *(none)* | **Single permission** (intentional) |

---

## 28. Critical Findings

### Security Issues

1. **Write permission gaps in 12 modules** — Access Control, eSSL, Assets, Reports, Timeline, Onboarding, Exit Requests, OT Register, Outdoor Duties, Work Codes, Expense/Benefits, HR Ops all use a single read-level permission for write/mutation operations. Any user with read access can create, update, and delete records.

2. **Reports mutation endpoint** — `POST /reports/attendance/recalculate` triggers data reprocessing but only requires `report.read`.

3. **SSL verification disabled** — eSSL SOAP client uses `verify=False` on HTTPX.

4. **No self-approval guard** — Outdoor Duties, OT Register, and Exit Requests allow `approved_by` to be set to any employee, including the requester.

### Data Integrity Issues

5. **Visitor status mismatch** — Backend defaults to `"pending"` but frontend checks for `"scheduled"` — check-in button will never appear.

6. **`list_visitors` signature mismatch** — Endpoint passes kwargs but service expects filters object — runtime crash on visitor list.

7. **Assets `/stats` route shadowed** — `GET /assets/stats` defined after `GET /assets/{asset_id}` — FastAPI may match `stats` as an asset_id.

8. **December warranty overflow** — Assets warranty expiry calculation: `date.today().month + 1` overflows to 13 in December.

9. **Lifecycle `new_manager_id` not persisted** — Transfer endpoint accepts manager_id but never sets it on the employee record.

### Architecture Issues

10. **Duplicate asset endpoints** — `/assets/` and `/hr/assets` serve the same model with different permissions, pagination, and feature gates.

11. **No service layer in 8 modules** — Lifecycle, Timeline, Onboarding, Exit Requests, OT Register, Outdoor Duties, Work Codes, HR Ops have all business logic inline in route handlers.

12. **`require_feature` imported but unused in 7 modules** — Recruitment, Performance, Lifecycle, Timeline, Work Codes, HR Ops, and Onboarding (partially) import the dependency but don't apply it.

13. **No pagination in 10 modules** — Shift Groups, Shift Rosters, Department Shifts, Performance (all lists), Onboarding, Exit Requests, OT Register, Outdoor Duties, Work Codes, HR Ops return unbounded result sets.

14. **Financial fields use `Float`** — Salary, expense, and payroll amounts use `Float` instead of `Numeric` — precision issues for financial calculations.

15. **`event_type` is unvalidated free-form string** — Timeline accepts any string up to 50 chars with no enum or allowed-values check.

16. **Status fields accept arbitrary strings** — Exit Requests, Onboarding, and other modules store status as `String(50)` with no DB-level or schema-level enum constraint.

### Files touched
`(none) — read-only audit`

### Findings worth promoting
- **RBAC pattern**: Modules use `require_permissions(codename)` at router level with per-endpoint overrides for writes — when properly implemented (Employees, Shifts, Leaves, Payroll, Visitors, Devices, Recruitment, Performance)
- **Feature gate pattern**: `require_feature(code)` at router level gates entire modules — 17 of 24 modules have this properly wired
- **Tenant isolation**: All models extend `TenantModel` with automatic `tenant_id` FK and query scoping — consistently applied across all modules
- **12 modules have write-permission gaps** — the most systemic security issue in the codebase
- **8 modules lack a service layer** — business logic in route handlers makes testing and reuse difficult
- **Duplicate asset endpoints** (`/assets/` vs `/hr/assets`) — architectural debt with divergent behavior
- **`Float` for financial columns** — project-wide pattern affecting precision in payroll, expenses, loans
