# Naming Standardization Audit — Apex HRMS

**Date:** 2026-06-28
**Scope:** File names, route prefixes, service names, model names, permission codes, feature flag codes

---

## 1. Current Naming Patterns

### 1.1 Backend Endpoint Files (`backend/app/api/v1/endpoints/*.py`)

| Pattern | Examples |
|---------|----------|
| Plural noun | `employees.py`, `devices.py`, `visitors.py`, `shifts.py`, `leaves.py`, `holidays.py`, `categories.py`, `documents.py`, `tenants.py` |
| Singular noun | `attendance.py`, `dashboard.py`, `lifecycle.py`, `performance.py`, `recruitment.py`, `analytics.py`, `payroll.py`, `onboarding.py`, `billing.py` |
| Compound (underscore) | `access_control.py`, `notification_center.py`, `expense_benefits.py`, `ot_register.py`, `outdoor_duties.py`, `work_codes.py`, `shift_groups.py`, `shift_rosters.py`, `department_shifts.py`, `exit_requests.py` |
| Abbreviated | `ess.py`, `essl_connector.py`, `essl_locations.py`, `hr_ops.py` |
| Suffixed | `settings_api.py` |

### 1.2 Backend Model Files (`backend/app/models/*.py`)

All use **singular snake_case**: `employee.py`, `device.py`, `visitor.py`, `shift.py`, `leave.py`, `attendance.py`, `payroll.py`, etc. **Consistent.**

### 1.3 Backend Service Files (`backend/app/services/*.py`)

All use **singular snake_case**: `employee.py`, `device.py`, `visitor.py`, `shift.py`, `leave.py`, `attendance.py`, etc. **Consistent.**

### 1.4 Frontend Screen Files (`frontend/lib/screens/**/*.dart`)

All use **snake_case with `_screen` suffix**: `employee_list_screen.dart`, `dashboard_screen.dart`, `login_screen.dart`. **Consistent.**

### 1.5 Route Prefixes (`/api/v1/*`)

| Pattern | Examples |
|---------|----------|
| Plural noun | `/employees`, `/devices`, `/visitors`, `/shifts`, `/leaves`, `/holidays`, `/categories`, `/documents`, `/tenants` |
| Singular noun | `/attendance`, `/dashboard`, `/recruitment`, `/performance`, `/payroll`, `/onboarding`, `/billing`, `/analytics` |
| Hyphenated compound | `/access-control`, `/shift-groups`, `/shift-rosters`, `/department-shifts`, `/outdoor-duties`, `/ot-register`, `/work-codes`, `/exit-requests`, `/tenant-settings` |
| Semantic (not file name) | `/finance` (file: `expense_benefits.py`), `/hr` (file: `hr_ops.py`), `/data` (file: `import_export.py`), `/ops` (file: `operations.py`) |
| Prefixed namespace | `/admin/*`, `/school/*` |

### 1.6 Permission Codes

Pattern: `<resource>.<action>`

| Pattern | Examples |
|---------|----------|
| `<plural>.<verb>` | `employee.read`, `employee.create`, `employee.update`, `employee.delete`, `employee.manage`, `device.read`, `device.manage` |
| `<singular>.<verb>` | `category.read`, `category.manage`, `holiday.read`, `holiday.manage`, `attendance.read`, `attendance.manage` |
| `<domain>.<verb>` | `school.settings`, `circular.publish`, `certificate.issue` |
| `<compound>.<verb>` | `access_control.read`, `student_attendance.read` |

**Verb inconsistency:** Most modules use `read`/`manage`, but `employees` uses `read`/`create`/`update`/`delete` (granular) while `leaves` uses `read`/`approve` (domain-specific).

### 1.7 Feature Flag Codes

Pattern: **Mixed** — some singular, some plural, some prefixed.

| Pattern | Examples |
|---------|----------|
| Singular | `attendance`, `leave`, `shift`, `overtime`, `payroll`, `expense`, `visitor`, `device`, `biometric`, `homework` |
| Plural | `assets`, `benefits`, `loans`, `reports`, `admissions`, `examinations`, `scholarships`, `polls`, `announcements` |
| Underscore compound | `outdoor_duty`, `access_control`, `exit_management`, `tax_declarations` → actually `tax`, `fee_management`, `school_timetable`, `school_hostel`, `school_library`, `school_events`, `school_circulars`, `school_medical`, `school_discipline`, `school_certificates`, `school_transport`, `school_assignments`, `student_management`, `student_attendance`, `class_management`, `subject_management`, `academic_year`, `custom_branding`, `white_label`, `api_access`, `gps_attendance`, `face_recognition`, `geo_fencing`, `notification_templates`, `parent_portal`, `grading_system`, `report_cards`, `lesson_planning` |

---

## 2. Inconsistencies Found

### 2.1 File Name ↔ Route Prefix Mismatch

| File | Route Prefix | Issue |
|------|-------------|-------|
| `expense_benefits.py` | `/finance` | Name describes content, prefix is semantic — mismatch |
| `hr_ops.py` | `/hr` | Abbreviated file name vs abbreviated prefix — at least consistent abbreviations, but `hr_ops` is unclear |
| `import_export.py` | `/data` | Completely different naming — `import_export` vs `data` |
| `operations.py` | `/ops` | Full word in file, abbreviated in route |
| `notification_center.py` | `/notifications` | `notification_center` (singular center) vs `notifications` (plural) |
| `settings_api.py` | `/settings` | `_api` suffix in file not reflected in route |
| `lifecycle.py` | `/employees` | Shares prefix with `employees.py` — two routers on same prefix |

### 2.2 Permission Code Inconsistencies

**Singular vs Plural resource names:**

| Singular | Plural |
|----------|--------|
| `category.read` | `employee.read` |
| `holiday.read` | `device.read` |
| `attendance.read` | `visitor.read` |
| `notification.read` | `operations.read` |
| `onboarding.read` | `recruitment.read` |
| `payroll.read` | `performance.read` |
| `biometric.read` | `shift.read` |
| `admission.manage` | — |
| `asset.read` | — |

**Verb inconsistency — not all modules follow `read`/`manage`:**

| Module | Verbs Used | Issue |
|--------|-----------|-------|
| `employee` | `read`, `create`, `update`, `delete`, `manage` | Has both granular CRUD AND `manage` — `manage` used in `lifecycle.py` and `import_export.py` alongside CRUD in `employees.py` |
| `leave` | `read`, `approve` | No `manage` — uses domain-specific `approve` |
| `exam` | `read`, `create`, `manage` | Mixed — has `create` AND `manage` but no `update`/`delete` |
| `circular` | `publish` | Single domain verb only |
| `certificate` | `issue` | Single domain verb only |
| `school` | `settings` | Uses noun as action, not a verb |

**Cross-module permission leaks:**

| Endpoint File | Permission Used | Expected |
|---------------|----------------|----------|
| `import_export.py` | `employee.read`, `employee.create`, `employee.manage` | Should be `data.read` / `data.import` or similar |
| `lifecycle.py` | `employee.read`, `employee.manage` | Reuses employee permissions — arguably correct but semantically different from `employees.py` |
| `timeline.py` | `employee.read` | Should be `timeline.read` or explicitly documented as employee-scoped |
| `ot_register.py` | `attendance.read` | Should be `overtime.read` or `ot.read` |
| `outdoor_duties.py` | `attendance.read` | Should be `outdoor_duty.read` |
| `work_codes.py` | `attendance.read` | Should be `work_code.read` |
| `commands.py` | `device.read` | Should be `command.read` |
| `websocket.py` | `dashboard.read` | Should be `websocket.read` or `notification.read` |
| `medical.py` (school) | `medical.manage` on base router AND on `medical_router` | Base router has no feature gate; `medical_router` does — inconsistent gating |

### 2.3 Feature Flag Code Inconsistencies

**Singular vs Plural:**

| Singular | Plural |
|----------|--------|
| `attendance` | `assets` |
| `leave` | `benefits` |
| `shift` | `loans` |
| `payroll` | `reports` |
| `expense` | `admissions` |
| `visitor` | `examinations` |
| `device` | `scholarships` |
| `biometric` | `polls` |
| `homework` | `announcements` |
| `access_control` | — |

**Feature code ↔ Permission prefix mismatch:**

| Feature Code | Permission Prefix | Issue |
|-------------|-------------------|-------|
| `assets` | `asset.read` | Plural feature, singular permission |
| `documents` | `document.read` | Plural feature, singular permission |
| `exit_management` | `exit.read` | Feature has `_management` suffix, permission doesn't |
| `expense` | `expense.read` | OK |
| `reports` | `report.read` | Plural feature, singular permission |
| `overtime` | `attendance.read` | Feature is `overtime`, permission is `attendance` |
| `outdoor_duty` | `attendance.read` | Feature is `outdoor_duty`, permission is `attendance` |
| `biometric` | `biometric.read` | OK — matches |
| `access_control` | `access_control.read` | OK — matches |
| `student_management` | `student.read` | Feature has `_management`, permission doesn't |
| `class_management` | `school.settings` | Completely different |
| `subject_management` | `school.settings` | Completely different |

### 2.4 Model Name Inconsistencies

| File | Class Name | Issue |
|------|-----------|-------|
| `payroll.py` | `PaySlip` | Should be `Payslip` (single word in common usage) — inconsistent PascalCase |
| `payroll.py` | `PayslipStatus` (enum) | Uses `Payslip` but class is `PaySlip` — **inconsistent within same file** |

### 2.5 ESSL/Essl Casing Inconsistency

| File | Classes/Services | Casing |
|------|-----------------|--------|
| `models/essl_server.py` | `EsslServer`, `EsslServerStatus` | `Essl` |
| `models/essl_sync.py` | `EsslSyncHistory`, `EsslSyncJob`, `EsslSyncError` | `Essl` |
| `models/essl_mapping.py` | `EsslEmployeeMapping`, `EsslDeviceMapping` | `Essl` |
| `models/essl_cursor.py` | `EsslSyncCursor` | `Essl` |
| `models/essl_location.py` | `EsslLocation` | `Essl` |
| `services/essl_client.py` | `ESSLClient`, `ESSLDevice`, `ESSLEmployee`, `ESSLPunchLog` | `ESSL` |
| `services/essl_soap.py` | `ESSLSoapService` | `ESSL` |
| `services/essl_connector.py` | `EsslConnectorService` | `Essl` |
| `services/essl_dashboard.py` | `EsslDashboardService` | `Essl` |

**Models use `Essl`, services use both `ESSL` and `Essl`.**

### 2.6 Duplicate/Overlapping Files

| Files | Issue |
|-------|-------|
| `settings/settings_screen.dart` + `system/settings_screen.dart` | Two settings screens — unclear scope separation |
| `notifications.py` + `notification_center.py` | Two notification endpoint files |
| `employees.py` + `lifecycle.py` | Both mount on `/employees` prefix |

### 2.7 School Endpoint Naming

School subdirectory files use **singular** names (`student.py`, `fee.py`, `certificate.py`, `admission.py`) which is **inconsistent** with the main endpoints directory which uses mostly **plural** names.

---

## 3. Recommended Standards

### 3.1 File Names

| Layer | Convention | Example |
|-------|-----------|---------|
| Endpoints | **plural_snake_case.py** | `employees.py`, `shift_groups.py`, `exit_requests.py` |
| Models | **singular_snake_case.py** | `employee.py`, `shift.py` (already consistent) |
| Services | **singular_snake_case.py** | `employee.py`, `shift.py` (already consistent) |
| Frontend screens | **snake_case_screen.dart** | `employee_list_screen.dart` (already consistent) |

**Specific renames needed:**

| Current | Recommended |
|---------|-------------|
| `expense_benefits.py` | `finance.py` (match route prefix) |
| `hr_ops.py` | `hr.py` (match route prefix) |
| `import_export.py` | `data.py` (match route prefix) |
| `settings_api.py` | `settings.py` (drop `_api` suffix) |
| `notification_center.py` | Merge into `notifications.py` or rename to `notifications_center.py` |

### 3.2 Route Prefixes

Adopt **plural kebab-case** for all resource routes:

| Current | Standard |
|---------|----------|
| `/access-control` | `/access-controls` (pluralize) |
| `/tenant-settings` | OK (plural `settings`) |
| `/shift-groups` | OK |
| `/department-shifts` | OK |
| `/outdoor-duties` | OK |
| `/ot-register` | `/ot-registers` (pluralize) or keep singular for register-style |
| `/exit-requests` | OK |
| `/work-codes` | OK |

### 3.3 Permission Codes

**Standard format:** `<resource>.<action>` where:
- `resource` is **always singular lowercase** (`employee`, `device`, `leave`, `category`)
- `action` is one of: `read`, `create`, `update`, `delete`, `manage`, or domain-specific verbs

**Migration mapping:**

| Current | Standard |
|---------|----------|
| `category.read` | OK (singular) |
| `holiday.read` | OK (singular) |
| `employee.read/create/update/delete` | OK (keep granular) |
| `employee.manage` | Deprecate — use granular CRUD |
| `leave.approve` | OK (domain verb) |
| `school.settings` | `school.setting` (singular) or `school.configure` |
| `circular.publish` | OK (domain verb) |
| `certificate.issue` | OK (domain verb) |
| `attendance.read` (used by OT/outdoor) | Create `overtime.read`, `outdoor_duty.read` |
| `device.read` (used by commands) | Create `command.read` |
| `dashboard.read` (used by websocket) | Create `websocket.read` |
| `employee.read` (used by import/export) | Create `data.read` |
| `employee.read` (used by timeline) | Create `timeline.read` |

### 3.4 Feature Flag Codes

**Standard:** Always **singular snake_case** for the primary noun:

| Current | Standard |
|---------|----------|
| `assets` | `asset` |
| `benefits` | `benefit` |
| `loans` | `loan` |
| `reports` | `report` |
| `admissions` | `admission` |
| `examinations` | `examination` |
| `scholarships` | `scholarship` |
| `polls` | `poll` |
| `announcements` | `announcement` |
| `notification_templates` | `notification_template` |
| `school_events` | `school_event` |
| `school_circulars` | `school_circular` |
| `school_certificates` | `school_certificate` |

### 3.5 Model Names

- Use `Payslip` not `PaySlip` (standard English compound)
- Standardize ESSL casing to `Essl` everywhere (match SQLAlchemy model convention)

### 3.6 Service Names

- `ESSLClient` → `EsslClient`
- `ESSLDevice` → `EsslDevice`
- `ESSLEmployee` → `EsslEmployee`
- `ESSLPunchLog` → `EsslPunchLog`
- `ESSLSoapService` → `EsslSoapService`

---

## 4. Migration Plan

### Phase 1: Permission Codes (Highest Priority — Breaking Change)

Permission codes are stored in the database (`role_permissions` table). Changes require:

1. Create migration script to rename permission codenames in `permissions` table
2. Update all `require_permissions()` calls in endpoints
3. Update role seed data
4. **Can be done non-destructively** by adding new permissions and mapping old → new

**Estimated files to change:** ~30 endpoint files

### Phase 2: Feature Flag Codes (Breaking Change)

Feature codes are stored in `feature_flags` table. Changes require:

1. Create migration to update `code` column in `feature_flags`
2. Update all `require_feature()` calls in endpoints (~30 calls)
3. Update `DEFAULT_FEATURES` list in `feature_gate.py`
4. Update `tenant_features` references

**Estimated files to change:** `feature_gate.py` + ~20 endpoint files

### Phase 3: File Renames (Non-Breaking)

Python file renames only affect imports. Steps:

1. Rename files
2. Update imports in `router.py` and any other importers
3. No database changes needed

**Files to rename:**
- `expense_benefits.py` → `finance.py`
- `hr_ops.py` → `hr.py`
- `import_export.py` → `data.py`
- `settings_api.py` → `settings.py`

### Phase 4: Model/Service Casing (Non-Breaking)

1. Rename `PaySlip` → `Payslip` in model, service, endpoint, and schema files
2. Rename `ESSL*` → `Essl*` in service files
3. Add `alembic` migration if table/column names change (they shouldn't — this is class-level only)

### Phase 5: Route Prefix Alignment (Non-Breaking)

Low priority — only affects API consumers. Can be done with redirect aliases.

---

## 5. Summary of Critical Issues

| Severity | Issue | Count |
|----------|-------|-------|
| **High** | Permission code singular/plural inconsistency | ~15 modules |
| **High** | Permission reuse across unrelated modules (OT uses `attendance.read`) | 4 cases |
| **Medium** | Feature flag singular/plural inconsistency | ~13 flags |
| **Medium** | ESSL casing mismatch between models and services | 5 service classes |
| **Medium** | `PaySlip` vs `PayslipStatus` within same file | 1 file |
| **Low** | File name ↔ route prefix mismatch | 5 files |
| **Low** | School endpoints use singular, main uses plural | 16 files |
| **Low** | Duplicate settings screens in frontend | 2 files |
