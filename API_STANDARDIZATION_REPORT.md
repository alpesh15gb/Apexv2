# API Standardization Audit Report

**Project**: Apex HRMS  
**Date**: 2026-06-28  
**Scope**: All REST API endpoints under `backend/app/api/v1/endpoints/`  
**Files Audited**: 67 endpoint files  

---

## Executive Summary

The codebase has **established standard schemas** (`PaginatedResponse`, `ResponseBase`, `ErrorResponse`, `PaginationParams`) in `backend/app/schemas/common.py`, but adoption is inconsistent. Roughly **40% of list endpoints** bypass `PaginatedResponse` in favor of raw dicts or unpaginated `List[T]` returns. Create endpoints return 4 different formats. Error handling is mostly consistent (HTTPException with detail strings) but doesn't use the defined `ErrorResponse` schema.

---

## 1. Response Format Inconsistencies

### 1A. List Endpoints — Three Competing Patterns

**Pattern 1: `PaginatedResponse[T]` (Standard — ~25 files)**  
Returns typed Pydantic model with all pagination metadata.

| File | Endpoint |
|------|----------|
| `employees.py` | `GET /departments`, `/designations`, `/branches`, `/` |
| `attendance.py` | `GET /`, `/punch-logs` |
| `shifts.py` | `GET /`, `/schedules/` |
| `leaves.py` | `GET /types`, `/requests` |
| `visitors.py` | `GET /`, `/active`, `/passes`, `/history` |
| `devices.py` | `GET /`, `/{device_id}/logs` |
| `tenants.py` | `GET /` |
| `notifications.py` | `GET /` |
| `commands.py` | `GET /` |
| `access_control.py` | `GET /zones`, `/doors`, `/logs` |
| `essl_connector.py` | `GET /`, `/{server_id}/sync/history`, `/{server_id}/sync/errors` |

**Pattern 2: Raw dict with pagination keys (~15 files)**  
Returns `{"items": [...], "total": N, "page": N, "page_size": N}` — manually constructed, no Pydantic validation. Some include `total_pages`, some don't.

| File | Endpoint | Has `total_pages`? |
|------|----------|--------------------|
| `holidays.py:37` | `GET /` | **NO** |
| `recruitment.py:73` | `GET /requisitions` | YES |
| `recruitment.py:212` | `GET /openings` | YES |
| `recruitment.py:356` | `GET /candidates` | YES |
| `recruitment.py:471` | `GET /interviews` | YES |
| `admin/tenants.py:120` | `GET /` | YES |
| `assets.py:82` | `GET /` | YES |
| `school/student.py:89` | `GET /` | **NO** |
| `school/fee.py:53` | `GET /categories` | **NO** |
| `school/fee.py:85` | `GET /structures` | **NO** |
| `school/examination.py:63` | `GET /exam-types` | **NO** |
| `school/examination.py:95` | `GET /exams` | **NO** |
| `school/academic_year.py` | `GET /` | **NO** |
| `school/grade_section.py` | `GET /` | **NO** |
| `school/student_attendance.py` | `GET /` | **NO** |

**Pattern 3: Unpaginated `List[T]` return (~20 files)**  
Returns all records with no pagination at all. Uses `response_model=List[T]`.

| File | Endpoint |
|------|----------|
| `payroll.py:26` | `GET /salary-structure` |
| `payroll.py:63` | `GET /payslips` |
| `payroll.py:159` | `GET /loans` |
| `documents.py:17` | `GET /` |
| `categories.py:18` | `GET /` |
| `shift_groups.py:18` | `GET /` |
| `shift_rosters.py:18` | `GET /` |
| `work_codes.py:18` | `GET /` |
| `timeline.py:17` | `GET /` |
| `department_shifts.py:18` | `GET /` |
| `outdoor_duties.py:20` | `GET /` |
| `ot_register.py:19` | `GET /` |
| `onboarding.py:18` | `GET /` |
| `exit_requests.py:18` | `GET /` |
| `expense_benefits.py:27,39,66,89,99` | All 5 list endpoints |
| `hr_ops.py:27,58,85,105,130` | All 5 list endpoints |
| `essl_locations.py:28` | `GET /{server_id}/locations` |
| `school/homework.py:29` | `GET /` (returns raw list of dicts) |
| `dashboard.py` | 8 dashboard endpoints (heatmaps, charts, etc.) |

**Pattern 4: Raw list of manually-constructed dicts (some school files)**  
Returns `[{"id": "...", "title": "...", ...}]` without Pydantic models.

| File | Endpoint |
|------|----------|
| `school/homework.py:44` | `GET /` |
| `school/homework.py:79` | `GET /{id}/submissions` |

### 1B. Create Endpoints — Four Return Formats

| Format | Files | Example |
|--------|-------|---------|
| **Full resource** (via `response_model=T`) | `employees.py`, `attendance.py`, `shifts.py`, `leaves.py`, `visitors.py`, `documents.py`, `holidays.py`, `payroll.py` | `return holiday` → `HolidayResponse` |
| **ID + partial fields** (raw dict) | `recruitment.py:113`, `school/student.py:100` | `{"id": "...", "title": "...", "status": "..."}` |
| **ID only** (raw dict) | `school/fee.py:64`, `school/examination.py:74`, `school/homework.py:67` | `{"id": "..."}` |
| **No response_model, returns ORM object** | `school/examination.py:66` (create_exam_type) | Returns ORM object directly |

### 1C. Delete Endpoints — Two Patterns

| Pattern | Files |
|---------|-------|
| Returns `ResponseBase(message="...")` | `documents.py:55` |
| Returns `StatusResponse(status="ok", message="...")` | `holidays.py:96` |
| Returns raw dict `{"status": "...", "message": "..."}` | `recruitment.py`, `school/*` |
| No delete endpoint | Many school files |

---

## 2. Pagination Inconsistencies

### 2A. Default `page_size` Varies

| Default | Files |
|---------|-------|
| `page_size=20, le=100` | `employees.py`, `attendance.py`, `shifts.py`, `leaves.py`, `visitors.py`, `devices.py`, `tenants.py`, `notifications.py`, `commands.py`, `access_control.py`, `essl_connector.py`, `recruitment.py` |
| `page_size=50, le=100` | `school/student.py`, `school/fee.py`, `school/examination.py`, `school/academic_year.py`, `school/grade_section.py`, `school/student_attendance.py` |
| `page_size=50, le=200` | `holidays.py` |
| No pagination at all | `payroll.py`, `documents.py`, `categories.py`, `shift_groups.py`, `shift_rosters.py`, `work_codes.py`, `timeline.py`, `department_shifts.py`, `outdoor_duties.py`, `ot_register.py`, `onboarding.py`, `exit_requests.py`, `expense_benefits.py`, `hr_ops.py`, `dashboard.py`, `school/homework.py` |

### 2B. `total_pages` Computation

- Files using `PaginatedResponse` always compute `total_pages=(total + page_size - 1) // page_size`
- Files using raw dicts sometimes include `total_pages`, sometimes omit it
- **8 school endpoint files** that return paginated dicts are **missing `total_pages`**

### 2C. `PaginationParams` Schema Unused

The `PaginationParams` Pydantic model in `schemas/common.py:29-34` (with `page`, `page_size`, `search`, `sort_by`, `sort_order`) is defined but **never used** in any endpoint. All endpoints define `page` and `page_size` as individual `Query()` params.

---

## 3. Error Handling Inconsistencies

### 3A. Error Format

All error handling uses `raise HTTPException(status_code=N, detail="...")` — this is consistent across all 67 files (152 HTTPException instances found).

However, the codebase defines `ErrorResponse` in `schemas/common.py:46-50` with fields `success`, `message`, `error_code`, `details` — this schema is **never used** as a response model or in error returns.

### 3B. Error Detail Patterns

| Pattern | Usage |
|---------|-------|
| `"Resource not found"` (generic) | 90% of 404 errors |
| `"Resource with this X already exists"` | `categories.py:41`, `work_codes.py:28` |
| Longer descriptive messages | `auth.py:65` — `"Tenant with this slug already exists."` |
| Status-specific messages | `lifecycle.py:200` — `"Cannot confirm a terminated employee"` |

### 3C. Auth Error Handling

`auth.py` uses the standard `HTTPException` pattern but with more nuanced status codes (400, 401, 403, 423) and longer detail messages. Some include trailing periods, most don't.

---

## 4. Naming Inconsistencies

### 4A. Route Prefix Casing

| Style | Examples |
|-------|----------|
| **kebab-case** (majority) | `/shift-groups`, `/shift-rosters`, `/department-shifts`, `/outdoor-duties`, `/ot-register`, `/work-codes`, `/exit-requests`, `/access-control`, `/tenant-settings` |
| **snake_case** | `/essl` (prefix for eSSL connector — brand name, acceptable) |
| **Single word** | `/employees`, `/shifts`, `/leaves`, `/visitors`, `/devices`, `/attendance` |

Route prefixes are **mostly consistent** with kebab-case for multi-word resources.

### 4B. Sub-route Naming

| Issue | File | Route |
|-------|------|-------|
| Trailing slash inconsistency | `shifts.py` | `GET /schedules/` (trailing slash) vs `GET /` (no trailing slash) |
| Verb in route | `leaves.py:60` | `POST /apply` (verb) instead of `POST /requests` |
| Mixed plural/singular | `payroll.py` | `/salary-structure` (singular) vs `/payslips` (plural) vs `/loans` (plural) |
| Inconsistent resource naming | `hr_ops.py` | `/assets`, `/travel`, `/announcements`, `/polls`, `/notification-templates` (mixed) |

### 4C. School Route Inconsistencies

School routes use `/school/` prefix consistently, but sub-paths vary:

| Route | Style |
|-------|-------|
| `/school/academic-years` | Plural, kebab-case ✓ |
| `/school/students` | Plural ✓ |
| `/school/student-attendance` | Singular compound (should be plural?) |
| `/school/homework` | Uncountable noun (acceptable) |
| `/school/fees` | Plural ✓ |
| `/school/transport` | Uncountable (acceptable) |
| `/school/hostel` | Singular (should be `/hostels`?) |
| `/school/library` | Singular (should be `/libraries`?) |
| `/school/health` | Abstract noun (should be `/medical`?) |
| `/school/discipline` | Abstract noun |

---

## 5. Summary of Files Needing Updates

### High Priority (Missing Pagination Entirely)

These files return unpaginated `List[T]` and will degrade with data growth:

1. `payroll.py` — 3 list endpoints (`/salary-structure`, `/payslips`, `/loans`)
2. `documents.py` — `GET /`
3. `categories.py` — `GET /`
4. `shift_groups.py` — `GET /`
5. `shift_rosters.py` — `GET /`
6. `work_codes.py` — `GET /`
7. `timeline.py` — `GET /`
8. `department_shifts.py` — `GET /`
9. `outdoor_duties.py` — `GET /`
10. `ot_register.py` — `GET /`
11. `onboarding.py` — `GET /`
12. `exit_requests.py` — `GET /`
13. `expense_benefits.py` — 5 list endpoints
14. `hr_ops.py` — 5 list endpoints
15. `essl_locations.py` — `GET /{server_id}/locations`
16. `school/homework.py` — `GET /`

### Medium Priority (Raw Dict Instead of PaginatedResponse)

These paginate but bypass the standard schema:

1. `holidays.py` — missing `total_pages`
2. `recruitment.py` — 4 list endpoints (has `total_pages` but no schema validation)
3. `admin/tenants.py` — `GET /`
4. `assets.py` — `GET /`
5. `school/student.py` — missing `total_pages`
6. `school/fee.py` — 2 endpoints, missing `total_pages`
7. `school/examination.py` — 2 endpoints, missing `total_pages`
8. `school/academic_year.py` — missing `total_pages`
9. `school/grade_section.py` — missing `total_pages`
10. `school/student_attendance.py` — missing `total_pages`

### Low Priority (Create/Delete Response Inconsistency)

Files where create endpoints return `{"id": "..."}` instead of the full resource:

1. `recruitment.py` — all create endpoints
2. `school/student.py` — `POST /`
3. `school/fee.py` — all create endpoints
4. `school/examination.py` — all create endpoints
5. `school/homework.py` — `POST /`

---

## 6. Standardization Recommendations

### R1. All List Endpoints → `PaginatedResponse[T]`

**Standard**: Every list endpoint should use `response_model=PaginatedResponse[T]` and return a `PaginatedResponse` instance.

```python
# BEFORE (holidays.py)
return {"items": items, "total": total, "page": page, "page_size": page_size}

# AFTER
return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                         total_pages=(total + page_size - 1) // page_size)
```

### R2. Standardize Pagination Defaults

**Standard**: `page=1, page_size=20, le=100` for all list endpoints.

```python
page: int = Query(1, ge=1),
page_size: int = Query(20, ge=1, le=100),
```

Exception: Domain-specific overrides allowed (e.g., `page_size=50` for student lists where class sizes are ~40).

### R3. All Create Endpoints → Return Full Resource

**Standard**: Create endpoints should use `response_model=T` and return the created ORM object.

```python
# BEFORE (school/fee.py)
return {"id": str(cat.id)}

# AFTER
return cat  # with response_model=FeeCategoryResponse
```

### R4. Error Handling → Use `ErrorResponse` Schema

**Standard**: Register `ErrorResponse` as a response model on endpoints and consider a global exception handler.

```python
@router.post("/", response_model=HolidayResponse, status_code=201,
             responses={400: {"model": ErrorResponse}, 409: {"model": ErrorResponse}})
```

Or better: add a global exception handler in `main.py` that formats all `HTTPException` into `ErrorResponse` shape.

### R5. Naming → Plural Nouns, kebab-case

**Standard**: All resource routes use plural nouns in kebab-case.

| Current | Recommended |
|---------|-------------|
| `/salary-structure` | `/salary-structures` |
| `/hostel` | `/hostels` |
| `/library` | `/libraries` |
| `/student-attendance` | `/student-attendances` |
| `/apply` (in leaves) | `POST /requests` |
| `/travel` | `/travel-requests` |

### R6. Use `PaginationParams` or Remove It

Either refactor endpoints to use the `PaginationParams` model (reduces boilerplate) or delete it from `schemas/common.py` to avoid confusion. Recommendation: keep individual `Query()` params (more explicit) and delete `PaginationParams`.

### R7. Consistent Trailing Slash

Remove all trailing slashes from route paths. FastAPI normalizes them but explicit inconsistency causes confusion.

---

## 7. Effort Estimate

| Category | Files | Est. Effort |
|----------|-------|-------------|
| Add pagination to unpaginated endpoints | 16 files, ~30 endpoints | 2-3 days |
| Switch raw dicts to PaginatedResponse | 10 files, ~15 endpoints | 1 day |
| Standardize create response format | 5 files, ~10 endpoints | 0.5 day |
| Standardize pagination defaults | ~10 files | 0.5 day |
| Naming fixes (routes) | 5-8 files | 0.5 day |
| Add ErrorResponse to response models | All files (optional) | 1 day |
| **Total** | | **~5-6 days** |

---

## Appendix: File-by-File Quick Reference

| File | List Pattern | Create Returns | Pagination Default | Notes |
|------|-------------|----------------|-------------------|-------|
| `employees.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `attendance.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `shifts.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `leaves.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `visitors.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `devices.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `tenants.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `notifications.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `commands.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `access_control.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `essl_connector.py` | PaginatedResponse | Full resource | 20/100 | ✓ Standard |
| `holidays.py` | Raw dict | Full resource | 50/200 | Missing total_pages |
| `recruitment.py` | Raw dict | ID+fields | 20/100 | 4 list endpoints |
| `assets.py` | Raw dict | Full resource | 20/100 | Missing PaginatedResponse |
| `admin/tenants.py` | Raw dict | Full resource | 20/100 | Missing PaginatedResponse |
| `payroll.py` | List[T] | Full resource | NONE | 3 unpaginated endpoints |
| `documents.py` | List[T] | Full resource | NONE | Unpaginated |
| `categories.py` | List[T] | Full resource | NONE | Unpaginated |
| `shift_groups.py` | List[T] | Full resource | NONE | Unpaginated |
| `shift_rosters.py` | List[T] | Full resource | NONE | Unpaginated |
| `work_codes.py` | List[T] | Full resource | NONE | Unpaginated |
| `timeline.py` | List[T] | Full resource | NONE | Unpaginated |
| `department_shifts.py` | List[T] | Full resource | NONE | Unpaginated |
| `outdoor_duties.py` | List[T] | Full resource | NONE | Unpaginated |
| `ot_register.py` | List[T] | Full resource | NONE | Unpaginated |
| `onboarding.py` | List[T] | Full resource | NONE | Unpaginated |
| `exit_requests.py` | List[T] | Full resource | NONE | Unpaginated |
| `expense_benefits.py` | List[T] | Full resource | NONE | 5 unpaginated endpoints |
| `hr_ops.py` | List[T] | Full resource | NONE | 5 unpaginated endpoints |
| `dashboard.py` | List[T] | N/A | NONE | Dashboard widgets (acceptable) |
| `school/student.py` | Raw dict | ID+fields | 50/100 | Missing total_pages |
| `school/fee.py` | Raw dict | ID only | 50/200 | Missing total_pages |
| `school/examination.py` | Raw dict | ID only | 50/200 | Missing total_pages |
| `school/homework.py` | Raw list | ID only | NONE | Unpaginated, no Pydantic |
| `school/academic_year.py` | Raw dict | ID only | 50/100 | Missing total_pages |
| `school/grade_section.py` | Raw dict | ID only | 50/100 | Missing total_pages |
| `school/student_attendance.py` | Raw dict | ID only | 50/100 | Missing total_pages |
| `school/admission.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/transport.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/hostel.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/library.py` | Raw dict | Full resource | varies | Mixed patterns |
| `school/timetable.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/communication.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/medical.py` | Raw dict | ID only | varies | Missing total_pages |
| `school/certificate.py` | Raw dict | ID only | varies | Missing total_pages |
| `auth.py` | N/A | Full resource | N/A | Auth endpoints (no list) |
| `recruitment.py` | Raw dict | ID+fields | 20/100 | Inconsistent |
| `performance.py` | Raw dict | Full resource | varies | Mixed |
| `import_export.py` | N/A | N/A | N/A | File operations |
| `operations.py` | Raw dict | Full resource | varies | Admin ops |
| `settings_api.py` | N/A | N/A | N/A | Settings CRUD |
| `setup.py` | N/A | N/A | N/A | Setup wizard |
| `system.py` | N/A | N/A | N/A | Health checks |
| `billing.py` | Raw dict | varies | varies | Admin billing |
| `analytics.py` | Raw dict | N/A | varies | Admin analytics |
| `ess.py` | Raw dict | varies | varies | Employee self-service |
| `websocket.py` | N/A | N/A | N/A | WebSocket |
| `admin/auth.py` | N/A | varies | N/A | Admin auth |
| `admin/dashboard.py` | N/A | N/A | N/A | Admin dashboard |
| `admin/plans.py` | varies | varies | varies | Admin plans |
| `admin/features.py` | varies | varies | varies | Admin features |
