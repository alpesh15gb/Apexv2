# Apex HRMS — Module Classification Validation Report

> **Validation date:** 2026-06-28
> **Validator:** Automated codebase scan vs MODULE_ARCHITECTURE.md
> **Scope:** Backend endpoints, models, services; Frontend screens & services
> **Method:** File-system enumeration compared against documented classification

---

## 1. Executive Summary

| Check | Result |
|-------|--------|
| Every module in exactly one category | **PASS** — no duplicate classifications found |
| No duplicate modules | **PASS** — no file appears in two categories |
| No orphan modules | **FAIL** — 5 backend files undocumented in classification tables |
| Cross-module dependencies documented | **PARTIAL** — high-level deps OK, internal eSSL chain missing |
| File counts match document | **FAIL** — multiple count discrepancies |
| Frontend screens classified | **N/A** — MODULE_ARCHITECTURE.md covers backend only |

**Overall: PARTIAL PASS** — Classification logic is sound (no duplicates), but document is incomplete and has arithmetic errors.

---

## 2. File Count Verification

### 2.1 Backend Endpoints (`backend/app/api/v1/endpoints/`)

| Category | Documented | Actual on Disk | Delta |
|----------|-----------|----------------|-------|
| Core | 16 | 16 | 0 |
| Corporate | 24 | 26 | **+2** |
| School | 16 | 16 | 0 |
| Admin/Super | 5 | 7 | **+2** |
| **Total** | **61** | **65** | **+4** |

> Note: Excluding `__init__.py` files from counts.

**Discrepancy:** Document claims 61 total endpoints; actual count is 65 (4 undocumented files).

### 2.2 Backend Models (`backend/app/models/`)

| Category | Documented | Actual on Disk | Delta |
|----------|-----------|----------------|-------|
| Core | 11 | 11 | 0 |
| Corporate | 25 | 25 | 0 |
| School | 15 | 18 | **+3** |
| Admin/Super (supporting) | 3 (mentioned §5) | 3 | 0 |
| **Total** | **54** | **57** | **+3** |

> Note: Excluding `__init__.py` files from counts. Admin models (approval.py, subscription.py, feature.py) are mentioned in §5 "Supporting models" but not counted in the §7 summary table.

### 2.3 Backend Services (`backend/app/services/`)

| Category | Documented | Actual on Disk | Delta |
|----------|-----------|----------------|-------|
| Core | 5 | 5 | 0 |
| Corporate | 13 | 16 | **+3** |
| School | 0 | 0 | 0 |
| **Total** | **18** | **21** | **+3** |

**Root cause:** The §3.3 table lists all 16 Corporate services by name but reports count as 13. Three services (`essl_soap.py`, `essl_client.py`, `duplicate_detector.py`) are listed in the table body but excluded from the count.

### 2.4 Frontend Screens (`frontend/lib/screens/`)

> MODULE_ARCHITECTURE.md does not cover frontend. Below is an independent classification for completeness.

| Category | Screen Count |
|----------|-------------|
| Core (login, register, splash, main_shell, dashboard, setup, holidays, settings, system) | 14 |
| Corporate (employees, attendance, shifts, leaves, payroll, devices, visitors, access_control, commands, notifications, ess, performance, recruitment, assets, hr, finance, reports) | 68 |
| School (school/ subdirectory) | 14 |
| Admin (admin/ subdirectory) | 6 |
| **Total** | **102** |

### 2.5 Frontend Services (`frontend/lib/services/`)

| Category | Count | Files |
|----------|-------|-------|
| Core | 3 | auth_service, dashboard_service, websocket_service |
| Corporate | 11 | employee, attendance, shift, leave, visitor, device, command, access_control, notification, report, essl |
| **Total** | **14** | |

---

## 3. Orphan Modules (Exist on Disk, Not in Classification Tables)

### 3.1 Endpoint Orphans

| File | Location | Classification | Issue |
|------|----------|---------------|-------|
| `analytics.py` | `endpoints/` | Admin/Super | Not listed in §2, §3, §4, or §5 |
| `billing.py` | `endpoints/` | Admin/Super | Not listed in §2, §3, §4, or §5 |

Both files use `get_current_superuser` dependency, confirming Admin/Super classification.

### 3.2 Model Orphans

| File | Location | Classification | Issue |
|------|----------|---------------|-------|
| `approval.py` | `models/` | Admin/Super | Mentioned in §5 "Supporting models" line but not in any classification table |
| `subscription.py` | `models/` | Admin/Super | Mentioned in §5 "Supporting models" line but not in any classification table |
| `feature.py` | `models/` | Admin/Super | Mentioned in §5 "Supporting models" line but not in any classification table |

### 3.3 School Model Count Error

The §4.1 table lists 15 School models, but 18 exist on disk. Three files are listed in the table body but excluded from the count:

| File | Listed in Table? | Counted? |
|------|-----------------|----------|
| `school/campus.py` | Yes | **No** |
| `school/lesson_plan.py` | Yes | **No** |
| `school/admission.py` | Yes | **No** |

---

## 4. Duplicate Module Check

**Result: PASS — No duplicates found.**

Every backend file (endpoint, model, service) appears in exactly one category. Cross-referencing all 65 endpoints, 57 models, and 21 services against the four categories (Core, Corporate, School, Admin) confirmed zero overlaps.

---

## 5. Misclassified Modules

**Result: PASS — No misclassifications found.**

Spot-checked classification logic for all modules:
- All Core modules have no Employee/Student domain dependency ✓
- All Corporate modules reference `employee_id` FK or Employee entity ✓
- All School modules are under `school/` subdirectory and reference Student entity ✓
- All Admin modules use `get_current_superuser` dependency ✓

---

## 6. Cross-Module Dependency Analysis

### 6.1 Documented Dependencies (§6.2) — Verified Correct

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

### 6.2 Undocumented Dependencies

| Dependency | From | To | Type |
|-----------|------|----|------|
| eSSL internal chain | `essl_sync.py` | `essl_server.py`, `essl_cursor.py` | FK references |
| eSSL mapping | `essl_mapping.py` | `employee.py`, `device.py` | FK to `employees`, `devices` |
| eSSL services | `essl_client.py` | `essl_soap.py`, `essl_connector.py` | Service-layer import |
| eSSL dedup | `duplicate_detector.py` | `essl_sync.py` | Reads sync records |
| Admin models | `approval.py`, `subscription.py`, `feature.py` | `tenant.py` | FK to `tenants` |
| Announcement | `announcement.py` | `tenant.py` | TenantModel (Core) |
| Document | `document.py` | `tenant.py` | TenantModel (Core) |

### 6.3 Shared Infrastructure (§6.1) — Verified

- `app/db/base.py` — `TenantModel` base class ✓
- `app/core/deps.py` — FastAPI DI (get_db, get_current_active_user, require_permissions, require_feature, get_current_superuser) ✓
- `app/core/security.py` — JWT + password hashing ✓

---

## 7. Document Arithmetic Errors

| Section | Claimed | Actual | Error |
|---------|---------|--------|-------|
| §1 Summary: Endpoints total | 61 | 65 | Undercount by 4 |
| §1 Summary: Models total | 51 | 54 (excl. admin) | Undercount by 3 |
| §1 Summary: Services total | 18 | 21 | Undercount by 3 |
| §3.3 Corporate services count | 13 | 16 | Undercount by 3 |
| §4.1 School models count | 15 | 18 | Undercount by 3 |
| §7 Grand Total files | 133 | 143 (excl. admin models) | Undercount by 10 |

---

## 8. Recommendations

### 8.1 Critical (Fix Immediately)

1. **Add missing endpoints to §5:** `analytics.py` and `billing.py` are live Admin/Super endpoints with no documented classification. Add them to the Admin endpoints table:
   - `endpoints/analytics.py` → `/admin/analytics` — Customer Success & Analytics
   - `endpoints/billing.py` → `/admin/billing` — Billing & Subscription management

2. **Fix §7 service count:** Change Corporate services from 13 → 16. The table body lists all 16 files correctly; only the count is wrong.

3. **Fix §7 School model count:** Change School models from 15 → 18. All 18 files are listed in §4.1 table body; only the count is wrong.

### 8.2 Important (Fix Soon)

4. **Promote Admin supporting models to full table entries:** `approval.py`, `subscription.py`, `feature.py` are mentioned in a prose line in §5 but not given proper table rows. Add them to the §5 table with Key Tables and Purpose columns.

5. **Add §7 Grand Total row for Admin models:** Currently Admin shows 0 models in the summary; actual is 3.

6. **Document eSSL internal dependency chain:** §6.2 shows eSSL as one bullet. Add explicit sub-items showing the 5-model chain (server → sync → cursor → mapping → location) and the 4-service chain (connector → soap → client → dashboard + sync_audit + duplicate_detector).

### 8.3 Nice to Have

7. **Extend MODULE_ARCHITECTURE.md to cover frontend:** 102 screens and 14 services exist in `frontend/lib/` with no classification document. Consider adding §8 Frontend Classification.

8. **Add `regularization_screen.dart` mapping:** This attendance screen has no corresponding backend endpoint — verify if it's wired to `attendance.py` or is a dead screen.

---

## 9. Corrected Counts

| Layer | Core | Corporate | School | Admin | **Actual Total** |
|-------|------|-----------|--------|-------|-----------------|
| Endpoints | 16 | 26 | 16 | 7 | **65** |
| Models | 11 | 25 | 18 | 3 | **57** |
| Services | 5 | 16 | 0 | 0 | **21** |
| **Backend Total** | **32** | **67** | **34** | **10** | **143** |

| Layer | Core | Corporate | School | Admin | **Total** |
|-------|------|-----------|--------|-------|-----------|
| Frontend Screens | 14 | 68 | 14 | 6 | **102** |
| Frontend Services | 3 | 11 | 0 | 0 | **14** |
| **Frontend Total** | **17** | **79** | **14** | **6** | **116** |

| **Grand Total (Backend + Frontend)** | | | | | **259** |
|---|---|---|---|---|---|

---

## 10. Validation Checklist

- [x] Every endpoint file classified (65/65) — 2 missing from doc
- [x] Every model file classified (57/57) — 3 missing from doc counts
- [x] Every service file classified (21/21) — 3 missing from doc counts
- [x] No duplicate classifications
- [x] No misclassified modules
- [x] Cross-module dependencies partially documented
- [ ] Frontend screens classified (not in scope of MODULE_ARCHITECTURE.md)
- [ ] Document counts match actual counts (multiple errors found)
