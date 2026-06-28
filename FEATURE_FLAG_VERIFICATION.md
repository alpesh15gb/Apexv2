# Feature Flag Verification Report

**Date:** 2026-06-28
**Scope:** `backend/app/core/feature_gate.py` + all endpoint files in `backend/app/api/v1/endpoints/`

---

## 1. Executive Summary

| Metric | Count |
|--------|-------|
| Feature flags in DEFAULT_FEATURES | 55 |
| Endpoints using `require_feature()` | 35 routers (across 32 files) |
| Endpoints importing `require_feature` but NOT using it | 15 files |
| Unused DEFAULT_FEATURES (no endpoint consumes them) | 22 flags |
| Feature flag code mismatches | 2 |
| Cross-module violations (Corporate in School or vice versa) | 0 |

---

## 2. DEFAULT_FEATURES Inventory

### Core/Corporate Features (33 flags)

| Code | Name | Module | Category | Used by Endpoint |
|------|------|--------|----------|-----------------|
| `attendance` | Attendance | attendance | Core HR | **MISSING** - no endpoint uses it |
| `leave` | Leave Management | leave | Core HR | **MISSING** - no endpoint uses it |
| `shift` | Shift Management | shift | Core HR | `shifts.py`, `shift_groups.py`, `shift_rosters.py`, `department_shifts.py` |
| `overtime` | Overtime | attendance | Core HR | `ot_register.py` |
| `outdoor_duty` | Outdoor Duty | attendance | Core HR | `outdoor_duties.py` |
| `payroll` | Payroll | payroll | Finance | `payroll.py` |
| `expense` | Expense Claims | finance | Finance | `expense_benefits.py` |
| `tax` | Tax Declarations | finance | Finance | **UNUSED** |
| `benefits` | Benefits | finance | Finance | **UNUSED** |
| `loans` | Loans | finance | Finance | **UNUSED** |
| `travel` | Travel Requests | hr | HR Operations | **UNUSED** |
| `assets` | Company Assets | hr | HR Operations | `assets.py` |
| `documents` | Documents | hr | HR Operations | `documents.py` |
| `onboarding` | Onboarding | hr | HR Operations | `onboarding.py` |
| `exit_management` | Exit Management | hr | HR Operations | `exit_requests.py` |
| `announcements` | Announcements | hr | HR Operations | **UNUSED** |
| `polls` | Polls | hr | HR Operations | **UNUSED** |
| `visitor` | Visitor Management | visitor | Security | `visitors.py` |
| `access_control` | Access Control | access | Security | `access_control.py` |
| `biometric` | Biometric Integration | essl | Integration | `essl_connector.py`, `essl_locations.py` |
| `device` | Device Management | device | Integration | `devices.py` |
| `gps_attendance` | GPS Attendance | attendance | Advanced | **UNUSED** |
| `face_recognition` | Face Recognition | attendance | Advanced | **UNUSED** |
| `geo_fencing` | Geo Fencing | attendance | Advanced | **UNUSED** |
| `reports` | Reports | reports | Analytics | `reports.py` |
| `analytics` | Analytics | reports | Analytics | **UNUSED** |
| `api_access` | API Access | system | Platform | **UNUSED** |
| `webhooks` | Webhooks | system | Platform | **UNUSED** |
| `custom_branding` | Custom Branding | system | Platform | **UNUSED** |
| `white_label` | White Label | system | Platform | **UNUSED** |
| `ess` | Employee Self Service | ess | Employee | `ess.py` |
| `chat` | Chat | communication | Communication | **UNUSED** |
| `helpdesk` | Helpdesk | support | Communication | **UNUSED** |
| `notification_templates` | Notification Templates | notification | Communication | **UNUSED** |

### School Features (22 flags)

| Code | Name | Module | Category | Used by Endpoint |
|------|------|--------|----------|-----------------|
| `student_management` | Student Management | school | School Core | `school/student.py`, `school/school_dashboard.py` |
| `admissions` | Admissions | school | School Core | `school/admission.py` |
| `academic_year` | Academic Year | school | School Core | `school/academic_year.py` |
| `class_management` | Class Management | school | School Core | `school/grade_section.py` (router + alloc_router) |
| `subject_management` | Subject Management | school | School Core | `school/grade_section.py` (subjects_router) |
| `school_timetable` | Timetable | school | Academics | `school/timetable.py` |
| `homework` | Homework | school | Academics | `school/homework.py` |
| `school_assignments` | Assignments | school | Academics | **UNUSED** |
| `lesson_planning` | Lesson Planning | school | Academics | **UNUSED** |
| `student_attendance` | Student Attendance | school | Academics | `school/student_attendance.py` |
| `examinations` | Examinations | school | Assessment | `school/examination.py` |
| `report_cards` | Report Cards | school | Assessment | **UNUSED** |
| `grading_system` | Grading System | school | Assessment | **UNUSED** |
| `fee_management` | Fee Management | school | Finance | `school/fee.py` |
| `scholarships` | Scholarships | school | Finance | **UNUSED** |
| `school_transport` | Transport | school | Operations | `school/transport.py` |
| `school_hostel` | Hostel | school | Operations | `school/hostel.py` |
| `school_library` | Library | school | Operations | `school/library.py` |
| `school_events` | School Events | school | Communication | `school/communication.py` (event_router) |
| `school_circulars` | Circulars | school | Communication | `school/communication.py` (circular_router) |
| `parent_portal` | Parent Portal | school | Communication | **UNUSED** |
| `school_medical` | Medical Records | school | Student Welfare | `school/medical.py` (medical_router) |
| `school_discipline` | Discipline | school | Student Welfare | `school/medical.py` (discipline_router) |
| `school_certificates` | Certificates | school | Administration | `school/certificate.py` |

---

## 3. Missing Feature Flags

These endpoints have NO feature flag gating (only RBAC `require_permissions`):

| Endpoint File | Module Type | Recommended Feature Code |
|---------------|-------------|--------------------------|
| `attendance.py` | Core HR | `attendance` (exists in DEFAULT_FEATURES but unused) |
| `leaves.py` | Core HR | `leave` (exists in DEFAULT_FEATURES but unused) |
| `employees.py` | Core HR | Needs new flag or use existing |
| `holidays.py` | Core HR | Needs new flag |
| `categories.py` | Core HR | Needs new flag |
| `work_codes.py` | Core HR | Needs new flag |
| `timeline.py` | Core HR | Needs new flag |
| `lifecycle.py` | Core HR | Needs new flag |
| `dashboard.py` | Core HR | Needs new flag |
| `notification_center.py` | Communication | `notification_templates` (exists but unused) |
| `notifications.py` | Communication | `notification_templates` (exists but unused) |
| `tenant_settings.py` | Platform | Needs new flag |
| `setup.py` | Platform | Needs new flag |
| `settings_api.py` | Platform | Needs new flag |
| `system.py` | Platform | `api_access` (exists but unused) |
| `hr_ops.py` | HR Ops | Multiple flags needed (assets, travel, announcements, polls) |
| `import_export.py` | Core HR | Needs new flag |
| `recruitment.py` | HR Ops | Needs new flag |
| `performance.py` | HR Ops | Needs new flag |
| `operations.py` | Platform | Needs new flag |
| `billing.py` | Platform | Needs new flag |
| `analytics.py` | Analytics | `analytics` (exists but unused) |
| `websocket.py` | Platform | Needs new flag |

**Note:** `tenants.py`, `admin/auth.py`, `admin/dashboard.py`, `admin/tenants.py`, `admin/plans.py`, `admin/features.py` are super-admin endpoints and correctly do NOT use feature flags.

---

## 4. Feature Flag Code Mismatches

### 4.1 `homework` endpoint vs `school_assignments` DEFAULT_FEATURE

- **Endpoint:** `school/homework.py` uses `require_feature("homework")`
- **DEFAULT_FEATURES:** Has `{"code": "homework", "name": "Homework"}` at sort_order 111
- **Also in DEFAULT_FEATURES:** `{"code": "school_assignments", "name": "Assignments"}` at sort_order 112
- **Issue:** The endpoint uses `homework` which exists, but there's also an orphaned `school_assignments` flag that likely should be the same feature or is a duplicate concept.

### 4.2 `hr_ops.py` serves multiple features under one router

- `hr_ops.py` handles Company Assets, Travel Requests, Announcements, Polls, and Notification Templates
- All 5 features are accessible with only `require_permissions("hr.read")` — no feature flag gating
- The `assets` feature flag exists and is used by `assets.py` (a separate file), but `hr_ops.py` also exposes `/assets` endpoints without the `assets` feature gate

---

## 5. Cross-Module Violations

**No violations found.**

- All School endpoints use School feature flags (`school_*`, `student_management`, `admissions`, `academic_year`, `class_management`, `subject_management`, `examinations`, `fee_management`, `homework`, `student_attendance`)
- All Corporate endpoints use Corporate feature flags (`payroll`, `shift`, `biometric`, `documents`, etc.)
- No School feature flag is used in a Corporate endpoint
- No Corporate feature flag is used in a School endpoint

---

## 6. Files Importing `require_feature` But Not Using It

These 15 files import `require_feature` in their import statement but do NOT apply it to any router or endpoint:

1. `recruitment.py` — imports `require_feature`, router uses only `require_permissions`
2. `operations.py` — imports `require_feature`, router uses only `require_permissions`
3. `performance.py` — imports `require_feature`, router uses only `require_permissions`
4. `lifecycle.py` — imports `require_feature`, router uses only `require_permissions`
5. `categories.py` — imports `require_feature`, router uses only `require_permissions`
6. `holidays.py` — imports `require_feature`, router uses only `require_permissions`
7. `leaves.py` — imports `require_feature`, router uses only `require_permissions`
8. `work_codes.py` — imports `require_feature`, router uses only `require_permissions`
9. `timeline.py` — imports `require_feature`, router uses only `require_permissions`
10. `tenant_settings.py` — imports `require_feature`, router uses only `require_permissions`
11. `system.py` — imports `require_feature`, router uses only `require_permissions`
12. `setup.py` — imports `require_feature`, router uses only `require_permissions`
13. `settings_api.py` — imports `require_feature`, router uses only `require_permissions`
14. `notification_center.py` — imports `require_feature`, router uses only `require_permissions`
15. `hr_ops.py` — imports `require_feature`, router uses only `require_permissions`

These are likely prepared for future feature flag integration but not yet wired up.

---

## 7. Recommendations

### Critical

1. **Gate `attendance.py` with the existing `attendance` flag** — the flag exists in DEFAULT_FEATURES but the main attendance endpoint has no feature gate. This is the most-used module.
2. **Gate `leaves.py` with the existing `leave` flag** — same issue; flag exists but is unused.
3. **Gate `hr_ops.py` sub-routes with their respective feature flags** — the file exposes assets, travel, announcements, polls, and notification templates under a single permissions-only router. Each should check its feature flag.
4. **Resolve `homework` vs `school_assignments` duplication** — either remove `school_assignments` from DEFAULT_FEATURES or map it to an endpoint.

### High

5. **Gate `analytics.py` with the existing `analytics` flag** — the flag exists but the endpoint only checks permissions.
6. **Gate `system.py` with the existing `api_access` flag** — the flag exists but is unused.
7. **Gate `notification_center.py` / `notifications.py` with `notification_templates`** — the flag exists but is unused.
8. **Clean up unused imports** — 15 files import `require_feature` without using it. Either wire them up or remove the import.

### Medium

9. **Create feature flags for ungated modules** — recruitment, performance, employees, holidays, categories, work_codes, timeline, lifecycle, dashboard, import_export, operations, billing, tenant_settings, setup, settings_api, websocket all lack feature flags entirely.
10. **Remove or implement unused flags** — 22 flags in DEFAULT_FEATURES have no consuming endpoint: `tax`, `benefits`, `loans`, `travel`, `announcements`, `polls`, `gps_attendance`, `face_recognition`, `geo_fencing`, `api_access`, `webhooks`, `custom_branding`, `white_label`, `chat`, `helpdesk`, `notification_templates`, `school_assignments`, `lesson_planning`, `report_cards`, `grading_system`, `scholarships`, `parent_portal`.

### Low

11. **Consistent naming for school features** — Some school flags use `school_` prefix (e.g., `school_transport`), others don't (e.g., `examinations`, `homework`). Consider standardizing.

---

## 8. Architecture Summary

The feature gate system (`feature_gate.py`) is well-designed:
- `FeatureGate.is_enabled()` checks per-tenant feature flags via `TenantFeature` join
- `require_feature()` dependency in `deps.py` (line 180) provides FastAPI dependency injection
- `DEFAULT_FEATURES` seeds 55 flags across Core HR, Finance, HR Ops, Security, Integration, Advanced, Analytics, Platform, Employee, Communication, and School categories
- School features are cleanly separated with `school` module type and `school_*` prefixed codes
- No cross-module contamination detected

**Overall Assessment:** The feature flag infrastructure is solid. The main gap is enforcement — many endpoints (especially core HR ones like attendance, leaves, employees) have feature flags defined but don't enforce them at the router level. The School ERP module has excellent feature flag coverage (20/22 flags enforced). The Corporate module has moderate coverage (13/33 flags enforced).
