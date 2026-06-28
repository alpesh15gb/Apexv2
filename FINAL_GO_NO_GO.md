# FINAL GO / NO-GO — Apex HRMS Sprint T13

**Date**: 2026-06-28
**Sprint**: T13
**Auditor**: Independent Release Reviewer (MiMo Code Agent)
**Scope**: School ERP migration, RBAC hardening, service-layer architecture, regression & security tests

---

## Executive Summary

**RECOMMENDATION: NO-GO**

Sprint T13 delivered significant progress: 55 school database tables migrated, 16 service-layer modules built, 16 school endpoint files with router-level RBAC, and a documented role-permission matrix covering 15 roles. However, **3 hard blockers** and **2 soft blockers** prevent production release:

1. The migration `downgrade()` is broken — `subjects` table missing from the drop list.
2. School write endpoints lack write-level RBAC — any authenticated user with read access can mutate data.
3. Prior security blockers (refresh token rotation, info leakage, `is_superuser` JWT) remain unresolved.

---

## Criteria Verification

| # | Criterion | Threshold | Actual | Status |
|---|-----------|-----------|--------|:------:|
| 1 | Critical blockers | 0 | 2 | **FAIL** |
| 2 | High blockers | 0 | 1 | **FAIL** |
| 3 | 100% migrated database schema | 55/55 tables | 55/55 tables created; downgrade broken | **FAIL** |
| 4 | 100% protected write endpoints | All write endpoints | Core HRMS: ✅ / School: ❌ (12 of 16 files use `get_current_active_user` on writes) | **FAIL** |
| 5 | 100% validated role templates | All roles valid | 15 roles documented; codename mismatches vs endpoints | **CONDITIONAL** |
| 6 | Complete service-layer architecture | All modules | 16 school services + 11 core services = 27 total | **PASS** |
| 7 | Regression tests passing | 100% | 86% (152/177, 22 failures) | **FAIL** |
| 8 | Security tests passing | 100% | Partial — 53/53 pass but quality concerns; 3 hard security failures from prior sprint unresolved | **FAIL** |

**Criteria Met**: 1/8
**Criteria Conditional**: 1/8
**Criteria Failed**: 6/8

---

## Detailed Findings

### 1. Database Migration — CRITICAL

**File**: `backend/alembic/versions/b2c3d4e5f6a7_add_school_erp_tables.py`

- **55 tables created** across 6 dependency-ordered phases — all `op.create_table` calls present.
- **Column matching**: All 55 models match migration on names, types, nullables, FKs, and defaults.
- **Indexes**: 4 composite indexes verified (students, student_fees, student_attendance).
- **Model imports**: All 55 classes imported in `school/__init__.py` and re-exported in `models/__init__.py`.

**BLOCKER**: `subjects` table (created at line 251) is **missing from `downgrade()`** (lines 686-704). Seven tables have FK constraints pointing to `subjects` (`grade_subjects`, `exam_schedules`, `homework`, `assignments`, `lesson_plans`, `timetable_entries`, `teacher_allocations`). Running `alembic downgrade` will fail with a foreign-key constraint error.

**Fix**: Insert `'subjects'` between `'grade_subjects'` and `'fee_structures'` in the downgrade list.

### 2. Write Endpoint RBAC — CRITICAL

**Core HRMS modules** (employees, attendance, shifts, leaves, visitors, payroll): **31/31 write handlers protected** with `require_permissions("module.manage")` — verified in `RBAC_VERIFICATION_REPORT.md`.

**School modules**: **Only `examination.py`** has endpoint-level write RBAC (`require_permissions("exam.create")`, `require_permissions("exam.manage")`). The remaining **12 school endpoint files** use `get_current_active_user` on write handlers — no write-level permission check:

| File | Write Handlers | Protected? |
|------|:--------------:|:----------:|
| student.py | create_student, update_student | ❌ |
| fee.py | create_fee_category, create_fee_structure, record_payment | ❌ |
| student_attendance.py | mark_attendance, bulk_mark | ❌ |
| academic_year.py | create_academic_year, update_academic_year, create_term, create_holiday | ❌ |
| grade_section.py | create_grade, update_grade, create_section, create_subject, update_subject, create_teacher_allocation | ❌ |
| admission.py | create_inquiry, create_application | ❌ |
| homework.py | create_homework | ❌ |
| hostel.py | create_hostel, create_room | ❌ |
| transport.py | create_route, create_stop | ❌ |
| library.py | create_book, create_transaction | ❌ |
| certificate.py | create_template | ❌ |
| timetable.py | create_period, create_substitution | ❌ |

These files have router-level read permissions (e.g., `require_permissions("student.read")`), so any authenticated user with read access can perform writes.

### 3. Role Permission Matrix — CONDITIONAL PASS

**15 roles** documented in `ROLE_PERMISSION_MATRIX.md`:
- Corporate: super_admin, hr_admin, manager, employee
- School: principal, vice_principal, academic_coordinator, class_teacher, subject_teacher, school_accountant, librarian, transport_manager, hostel_warden, receptionist, parent, student

**Issue**: Permission codenames in the matrix (e.g., `student.create`, `fee.collect`, `attendance.mark`) do not consistently match what endpoints enforce (e.g., `student.manage`, `fee.manage`, `student_attendance.mark`). The `RBAC_VERIFICATION_REPORT.md` confirms that default Employee and Manager roles are effectively non-functional for several modules due to codename mismatches. The system currently works only because Super Admin bypasses all checks.

### 4. Service-Layer Architecture — PASS

**27 service modules** present:

| Layer | Count | Files |
|-------|:-----:|-------|
| School services | 16 | student_service, attendance_service, exam_service, fee_service, academic_year_service, admission_service, grade_section_service, homework_service, transport_service, hostel_service, library_service, timetable_service, certificate_service, communication_service, medical_service, school_dashboard_service |
| Core HRMS services | 11 | employee, attendance, leave, shift, visitor, report, notification, access_control, device, user, dashboard |

All school services accept `tenant_id` as first parameter and filter queries accordingly.

### 5. Regression Tests — FAIL

Per `REGRESSION_REPORT.md`:
- **Pass rate**: 86% (152/177 tests, 22 failures, 6 partial)
- **RBAC test stubs**: 3 tests in `TestRBAC` are `pass` with no assertions
- **Tenant isolation tests**: Assert `status_code in [200, 401, 403]` — too permissive
- **Critical failures**: Write RBAC not enforced (10 modules), token revocation dead code, default SECRET_KEY

### 6. Security Tests — FAIL

Per `SECURITY_TEST_REPORT.md` and prior `GO_NO_GO_REPORT.md`:
- **Refresh token rotation**: Old token NOT revoked after use — attacker can reuse indefinitely
- **Information leakage**: 5+ endpoints return `str(e)` in API responses
- **`is_superuser` not in JWT**: `TenantMiddleware` reads it but `create_access_token()` never includes it
- **SQL injection**: ✅ Clean — ORM-only, no vectors
- **Token revocation**: ✅ Wired in (logout, logout-all, password change)

---

## Remaining Blockers

### Critical (Must fix before release)

| # | Issue | Impact | Est. Fix |
|---|-------|--------|----------|
| C-1 | `subjects` missing from migration downgrade | `alembic downgrade` fails; cannot roll back | 5 min |
| C-2 | School write endpoints lack write-level RBAC | Any authenticated user can mutate school data | 4-6 hrs |
| C-3 | Refresh token rotation not revoked | Session hijacking via stolen refresh token | 2 hrs |

### High (Should fix before release)

| # | Issue | Impact | Est. Fix |
|---|-------|--------|----------|
| H-1 | Information leakage (5 endpoints) | Internal error details exposed to clients | 1 hr |
| H-2 | `is_superuser` not in JWT claims | Superuser cross-tenant bypass non-functional | 1 hr |
| H-3 | Role permission codename mismatches | Default Employee/Manager roles non-functional | 2 hrs |
| H-4 | Regression pass rate 86% | 22 test failures across multiple modules | 4-8 hrs |

### Low (Can defer)

| # | Issue | Impact |
|---|-------|--------|
| L-1 | RBAC test stubs (3 tests with no assertions) | False confidence in coverage |
| L-2 | No permission caching (DB hit per check) | Performance under load |
| L-3 | Lifecycle bugs (promote salary, transfer manager) | Non-security, non-data-loss |

---

## Go / No-Go Recommendation

### **NO-GO**

**Rationale**: Two critical blockers are security-related (C-2, C-3). The school write endpoint gap (C-2) means any authenticated user can create/modify students, fees, attendance, admissions, and all other school data without appropriate permission checks. This is a data-integrity and compliance risk that cannot be accepted.

### Conditions for Conditional GO

If the business accepts the following risks, a conditional GO may be granted:

1. **C-1** (migration downgrade) must be fixed immediately — 5-minute one-liner
2. **C-2** (school write RBAC) must be fixed within 24 hours of deployment
3. **C-3** (refresh token rotation) must be fixed within 24 hours of deployment
4. **H-1, H-2** (info leakage + JWT claims) must be fixed within 48 hours
5. Monitoring must be active to detect exploitation of known gaps

### Path to GO

| Step | Task | Priority | Est. |
|------|------|----------|------|
| 1 | Add `'subjects'` to migration downgrade list | P0 | 5 min |
| 2 | Add `require_permissions("module.manage")` to all school write endpoints | P0 | 4-6 hrs |
| 3 | Revoke old refresh token after rotation | P0 | 2 hrs |
| 4 | Replace `str(e)` with generic error messages | P1 | 1 hr |
| 5 | Add `is_superuser` to JWT claims | P1 | 1 hr |
| 6 | Align role permission codenames | P1 | 2 hrs |
| 7 | Fix regression test failures | P1 | 4-8 hrs |
| 8 | Re-run full regression + security suite | — | 2 hrs |

**Total estimated effort to GO**: 16-22 hours (2-3 days)

---

**Decision**: **NO-GO**
**Next Review**: After P0/P1 fixes completed
**Prepared By**: MiMo Code Agent (Independent Release Reviewer)
**Date**: 2026-06-28
