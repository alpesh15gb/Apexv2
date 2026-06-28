# Apex HRMS — Bug Report (Code Review)

## Document Info
- **Date**: 2026-06-28
- **Review Scope**: All backend endpoints, frontend screens, security infrastructure
- **Methodology**: Static code review (no runtime testing)
- **Prepared By**: MiMo Code Agent

---

## Critical Severity

### BUG-001: Token Revocation is Dead Code
- **File**: `backend/app/core/security.py` + `backend/app/core/deps.py`
- **Description**: `revoke_token()`, `is_token_revoked()`, `revoke_all_user_tokens()`, and `is_user_revoked()` functions exist in `security.py` but are NEVER called in `get_current_user()` or `TenantMiddleware`. Revoked tokens remain valid until natural expiry.
- **Impact**: When a user is deactivated, password changed, or admin revokes sessions, old tokens continue working for up to 30 minutes (access) or 7 days (refresh). Critical security gap.
- **Reproduction**: Login → get token → logout → use old token → still works.
- **Recommended Fix**: Add `is_token_revoked(token)` check in `get_current_user()` after `decode_token()`. Call `revoke_token()` in logout and password change flows.

### BUG-002: `is_superuser` Never Set in JWT Payload
- **File**: `backend/app/core/security.py` → `create_access_token()`, `backend/app/middleware/tenant.py`
- **Description**: `TenantMiddleware` reads `payload.get("is_superuser", False)` for cross-tenant bypass, but `create_access_token()` does NOT include `is_superuser` in the JWT claims. The flag is always `False` in the token.
- **Impact**: Superusers cannot perform cross-tenant operations through middleware (e.g., admin viewing all tenants). The middleware bypass never activates.
- **Recommended Fix**: Include `is_superuser=True` in JWT payload when creating tokens for superuser accounts, OR remove the middleware bypass and rely solely on `require_permissions` superuser check.

### BUG-003: Default SECRET_KEY is Hardcoded and Insecure
- **File**: `backend/app/core/config.py`
- **Description**: Default `SECRET_KEY = "change-this-to-a-random-secret-key-in-production"`. No startup validation forces a non-default value.
- **Impact**: If environment variable is unset (common in dev/staging), all JWTs can be forged by anyone who reads the source code.
- **Recommended Fix**: Add startup assertion: `assert settings.SECRET_KEY != "change-this-to-a-random-secret-key-in-production", "Set SECRET_KEY env var"`.

---

## High Severity

### BUG-004: Write Endpoints Lack Permission Checks (Pervasive)
- **Files**: All endpoint files under `backend/app/api/v1/endpoints/`
- **Description**: Nearly every router sets only a read permission at the router level (e.g., `require_permissions("employee.read")`). POST/PUT/DELETE handlers do not check for write permissions like `employee.create`, `employee.update`, `employee.delete`.
- **Affected Modules**: Employees, Attendance, Shifts, Visitors, Devices, Categories, Timeline, Lifecycle, Reports, Dashboard, all School modules.
- **Impact**: Any authenticated user with read access can create, update, and delete records. No role differentiation for write operations.
- **Recommended Fix**: Add `require_permissions("employee.create")` to POST handlers, `require_permissions("employee.update")` to PUT handlers, etc.

### BUG-005: Import/Export Endpoints Completely Unprotected
- **File**: `backend/app/api/v1/endpoints/import_export.py`
- **Description**: Bulk import and export endpoints have no permission checks beyond `get_current_active_user`. Any authenticated user can import employees or export the entire employee list.
- **Impact**: Data exfiltration (export) and unauthorized data modification (import).
- **Recommended Fix**: Add `require_permissions("employee.create")` to import, `require_permissions("employee.read")` to export.

### BUG-006: Examination Marks Cross-Tenant Write Vulnerability
- **File**: `backend/app/api/v1/endpoints/school/examination.py` — `enter_marks()` and `bulk_enter_marks()`
- **Description**: When updating existing marks (`if existing` branch), the query does not filter by `tenant_id`. A user from Tenant A could overwrite marks belonging to Tenant B if they know the `exam_schedule_id` and `student_id`.
- **Impact**: Data integrity — cross-tenant marks corruption.
- **Reproduction**: Tenant A user sends marks entry with Tenant B's exam_schedule_id and student_id.
- **Recommended Fix**: Add `tenant_id=current_user.tenant_id` filter to the existing marks query.

### BUG-007: Lifecycle `promote_employee` Silently Ignores Salary Change
- **File**: `backend/app/api/v1/endpoints/lifecycle.py` — `promote_employee()`
- **Description**: The handler accepts `new_salary` in the request body but the code contains `if data.new_salary: pass` — salary changes are silently discarded.
- **Impact**: HR believes salary was updated during promotion but it wasn't. Payroll discrepancy.
- **Recommended Fix**: Implement salary update logic or remove `new_salary` from the schema.

### BUG-008: Lifecycle `transfer_employee` Never Sets `manager_id`
- **File**: `backend/app/api/v1/endpoints/lifecycle.py` — `transfer_employee()`
- **Description**: The handler tracks "manager" in the changes list (for audit trail) but never actually sets `manager_id` on the employee record.
- **Impact**: Employee appears transferred but manager assignment is lost.
- **Recommended Fix**: Add `employee.manager_id = data.new_manager_id` to the update logic.

### BUG-009: Admin Login Does Not Reset Failed Login Counter
- **File**: `backend/app/api/v1/endpoints/admin/auth.py`
- **Description**: Unlike the main auth login which calls `reset_failed_login()` on success, the admin login endpoint does not. Failed login counter keeps incrementing even after successful admin login.
- **Impact**: Admin account could get locked out after a series of failed attempts followed by successful ones.
- **Recommended Fix**: Call `reset_failed_login(db, user)` after successful admin authentication.

---

## Medium Severity

### BUG-010: Admission `review_application` Uses Raw Dict Instead of Pydantic Model
- **File**: `backend/app/api/v1/endpoints/school/admission.py` — `review_application()`
- **Description**: Accepts `data: dict` instead of a Pydantic schema. No validation on the `status` field — attacker could set any arbitrary status value, bypassing the review workflow.
- **Impact**: Workflow bypass — could set status to "approved" without going through proper review.
- **Recommended Fix**: Create `ApplicationReviewUpdate` Pydantic model with `status: Literal["approved", "rejected", "under_review"]`.

### BUG-011: Admission `enroll_student` Skips Review Gate
- **File**: `backend/app/api/v1/endpoints/school/admission.py` — `enroll_student()`
- **Description**: Allows enrollment when `app.status == "submitted"`, which likely skips the intended review gate. Should require "approved" status.
- **Impact**: Students can be enrolled without application review.
- **Recommended Fix**: Change check to `if app.status != "approved": raise HTTPException(400)`.

### BUG-012: Admission Application Number Collision Risk
- **File**: `backend/app/api/v1/endpoints/school/admission.py`
- **Description**: Application number generation uses only 4 random digits (10,000 possibilities per month). High collision risk for active schools.
- **Impact**: Duplicate application numbers, data confusion.
- **Recommended Fix**: Use 6+ digits or a sequential counter per tenant.

### BUG-013: `create_access_token` Refresh Endpoint Swallows Redis Errors
- **File**: `backend/app/api/v1/endpoints/auth.py` — `refresh_token()`
- **Description**: The Redis token blacklist check is wrapped in `except Exception as e: pass`. If Redis is down, revoked tokens will still be accepted.
- **Impact**: Token revocation fails silently during Redis outages.
- **Recommended Fix**: Fail closed (reject token) when Redis is unavailable, or log warning and accept with reduced TTL.

### BUG-014: `daily_summary` Uses Inline SQL Instead of Service Layer
- **File**: `backend/app/api/v1/endpoints/attendance.py` — `daily_summary()`
- **Description**: Runs an inline SQL query instead of going through the service layer, inconsistent with the rest of the file. Potential for SQL injection if date parameters are not properly sanitized (though current code appears safe).
- **Impact**: Maintenance burden, inconsistency.
- **Recommended Fix**: Move to service layer with parameterized queries.

### BUG-015: Exam Schedule Does Not Verify Parent Exam Ownership
- **File**: `backend/app/api/v1/endpoints/school/examination.py` — `create_exam_schedule()`
- **Description**: Does not verify the parent `exam_id` belongs to the current tenant. Could attach schedules to a cross-tenant exam.
- **Impact**: Data integrity — orphaned or cross-tenant exam schedules.
- **Recommended Fix**: Verify `Exam.tenant_id == current_user.tenant_id` before creating schedule.

### BUG-016: `bulk_enter_marks` Has No Payload Size Limit
- **File**: `backend/app/api/v1/endpoints/school/examination.py` — `bulk_enter_marks()`
- **Description**: Accepts an unbounded list of marks entries. No upper limit on list size.
- **Impact**: Potential DoS via huge payload causing memory exhaustion or long transaction.
- **Recommended Fix**: Add `max_items=1000` to the Pydantic schema or validate list length in handler.

### BUG-017: `create_grading_scale` Accepts Raw Dict
- **File**: `backend/app/api/v1/endpoints/school/examination.py` — `create_grading_scale()`
- **Description**: Accepts raw `dict` for details. The `**detail` unpacking could inject unexpected fields.
- **Impact**: Schema bypass, potential data corruption.
- **Recommended Fix**: Use a proper Pydantic model for grading scale details.

### BUG-018: Communication `CircularCreate.attachment_urls` No Validation
- **File**: `backend/app/api/v1/endpoints/school/communication.py`
- **Description**: `attachment_urls` accepts `List[str]` with no URL format validation. Potential for malicious URLs.
- **Impact**: Stored XSS via malicious links, phishing.
- **Recommended Fix**: Validate URL format (scheme, domain) in the Pydantic schema.

### BUG-019: Academic Year Missing Date Validation
- **File**: `backend/app/api/v1/endpoints/school/academic_year.py`
- **Description**: No validation that `start_date < end_date` in `AcademicYearCreate` or `TermCreate`.
- **Impact**: Invalid date ranges could be created.
- **Recommended Fix**: Add Pydantic validator to ensure start < end.

### BUG-020: Academic Year `create_term`/`create_holiday` Skip Year Ownership Check
- **File**: `backend/app/api/v1/endpoints/school/academic_year.py`
- **Description**: Never verify that `year_id` belongs to an existing academic year for the current tenant.
- **Impact**: Orphaned terms/holidays under fabricated year IDs.
- **Recommended Fix**: Add ownership check before creating terms/holidays.

### BUG-021: Certificate Number Collision Risk
- **File**: `backend/app/api/v1/endpoints/school/certificate.py`
- **Description**: Certificate number uses only 4 random digits — collision risk on busy days.
- **Impact**: Duplicate certificate numbers.
- **Recommended Fix**: Use 6+ digits or UUID-based numbering.

---

## Low Severity

### BUG-022: Duplicate `require_permissions` Imports
- **Files**: Nearly all endpoint files
- **Description**: Almost every file imports `require_permissions` twice from `app.core.deps`. Harmless at runtime but signals careless copy-paste.
- **Impact**: No functional impact, code cleanliness.
- **Recommended Fix**: Remove duplicate imports.

### BUG-023: Global `_redis` Singleton in auth.py Not Thread-Safe
- **File**: `backend/app/api/v1/endpoints/auth.py` — lines 36-41
- **Description**: Module-level Redis connection singleton is not thread-safe and leaks a connection that is never closed.
- **Impact**: Potential connection leak on shutdown.
- **Recommended Fix**: Use FastAPI's dependency injection or lifespan management for Redis connections.

### BUG-024: CSP Allows `unsafe-inline` and `unsafe-eval`
- **File**: `backend/app/middleware/security_headers.py`
- **Description**: Content-Security-Policy permits `script-src 'self' 'unsafe-inline' 'unsafe-eval'`, significantly weakening XSS protection.
- **Impact**: Reduced XSS mitigation.
- **Recommended Fix**: Tighten CSP if frontend framework allows it (may be necessary for Next.js/Flutter web).

### BUG-025: bcrypt Password Truncation Silent
- **File**: `backend/app/core/security.py`
- **Description**: Monkeypatch truncates passwords to 72 bytes silently. Users with passwords >72 characters are not informed.
- **Impact**: Reduced password entropy for users with long passwords.
- **Recommended Fix**: Add validation warning or reject passwords >72 bytes at registration.

### BUG-026: `EventCreate.is_public` Never Used in Filtering
- **File**: `backend/app/api/v1/endpoints/school/communication.py`
- **Description**: The `is_public` field exists on events but `list_events` returns all events regardless of this flag.
- **Impact**: Public/private event distinction not enforced.
- **Recommended Fix**: Filter by `is_public` for non-admin users.

### BUG-027: No Update/Delete Endpoints for Circulars or Events
- **File**: `backend/app/api/v1/endpoints/school/communication.py`
- **Description**: Only create and list endpoints exist. No way to edit or delete published circulars/events.
- **Impact**: Published errors cannot be corrected.
- **Recommended Fix**: Add PUT/DELETE endpoints.

### BUG-028: Admin Login Does Not Update `last_login_at`
- **File**: `backend/app/api/v1/endpoints/admin/auth.py`
- **Description**: Unlike main auth login, admin login does not update the user's `last_login_at` timestamp.
- **Impact**: Audit trail incomplete for admin logins.
- **Recommended Fix**: Update `last_login_at` on successful admin login.

### BUG-029: Rate Limiting Missing on Auth Endpoints
- **Files**: `auth.py`, `admin/auth.py`
- **Description**: Login, registration, and admin login endpoints have no rate limiting. Brute force and mass registration attacks possible.
- **Impact**: Security — brute force risk.
- **Recommended Fix**: Apply `@rate_limit(max_requests=5, window_seconds=60)` decorator.

### BUG-030: No Response Model on Many Endpoints
- **Files**: Various endpoint files
- **Description**: Several endpoints return raw dicts/lists instead of Pydantic response models.
- **Impact**: No automatic OpenAPI documentation, no response validation.
- **Recommended Fix**: Add `response_model` to route decorators.

### BUG-031: `EventCreate.is_public` Field Unused
- **File**: `backend/app/api/v1/endpoints/school/communication.py`
- **Description**: The `is_public` field on `EventCreate` is accepted but `list_events` does not filter by it.
- **Impact**: Private events visible to all.
- **Recommended Fix**: Filter `is_public` based on user role.

---

## Defect Summary

| Severity | Count | Blocking Production? |
|----------|:-----:|:-------------------:|
| Critical | 3 | YES |
| High | 6 | YES |
| Medium | 12 | Recommended |
| Low | 10 | No |
| **Total** | **31** | |

### Production Blockers
1. BUG-001: Token revocation dead code
2. BUG-002: is_superuser not in JWT
3. BUG-003: Default SECRET_KEY
4. BUG-004: Write endpoints lack RBAC
5. BUG-005: Import/export unprotected
6. BUG-006: Cross-tenant marks write
7. BUG-007: Promote ignores salary
8. BUG-008: Transfer ignores manager
9. BUG-009: Admin login counter not reset

### Recommended Fix Priority
1. **Immediate**: BUG-001, BUG-003, BUG-004, BUG-005, BUG-006
2. **Before Production**: BUG-002, BUG-007, BUG-008, BUG-009, BUG-010, BUG-011
3. **Next Sprint**: BUG-012 through BUG-021
4. **Backlog**: BUG-022 through BUG-031
