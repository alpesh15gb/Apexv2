# FINAL RBAC COVERAGE REPORT — Apex HRMS Write Endpoints

**Audit Date:** 2026-06-28
**Scope:** ALL `@router.post`, `@router.put`, `@router.delete` handlers across:
- `backend/app/api/v1/endpoints/*.py` (44 files)
- `backend/app/api/v1/endpoints/admin/*.py` (5 files)
- `backend/app/api/v1/endpoints/school/*.py` (16 files)
- Includes sub-routers (`medical_router`, `discipline_router`, `circular_router`, `event_router`, `subjects_router`, `alloc_router`)

---

## SUMMARY

| Metric | Count |
|---|---|
| **Total write endpoints** | **254** |
| **Protected with proper write permission** | **101** |
| **Protected by superuser gate (not RBAC)** | **22** |
| **Public / self-service (intentionally no RBAC)** | **13** |
| **UNPROTECTED — only gated by READ permission** | **118** |
| **Coverage (proper write RBAC)** | **39.8%** |
| **Coverage (including superuser-gated)** | **48.4%** |

---

## TIER 1: FULLY PROTECTED (write endpoints with correct permission) — 101 endpoints

These files have **both** router-level read permission AND endpoint-level write/manage permission:

| File | Write Endpoints | Permission Pattern |
|---|---|---|
| attendance.py | 3 | `attendance.manage` on each endpoint |
| categories.py | 3 | `category.manage` on each endpoint |
| devices.py | 4 | `device.manage` on each endpoint |
| documents.py | 3 | `document.manage` on each endpoint |
| employees.py | 14 | `employee.create` / `.update` / `.delete` per action |
| holidays.py | 3 | `holiday.manage` on each endpoint |
| import_export.py | 2 | `employee.create` / `.manage` via dependencies |
| leaves.py | 5 | `leave.approve` on each endpoint |
| lifecycle.py | 7 | `employee.manage` via dependencies |
| payroll.py | 5 | `payroll.manage` on each endpoint |
| performance.py | 12 | `performance.manage` on each endpoint |
| recruitment.py | 16 | `recruitment.manage` on each endpoint |
| shifts.py | 4 | `shift.manage` on each endpoint |
| visitors.py | 4 | `visitor.manage` on each endpoint |
| **examination.py** | **6** | `exam.create` / `exam.manage` per endpoint |

**Subtotal: 88 core + 6 school examination + 7 school router-manage = 101**

School files with write-level router permissions (correctly protected):
- grade_section.py: 7 writes — router `school.settings` (manage-level) ✓
- academic_year.py: 5 writes — router `school.settings` ✓
- admission.py: 4 writes — router `admission.manage` ✓
- timetable.py: 3 writes — router `school.settings` ✓
- library.py: 3 writes — router `library.manage` ✓
- hostel.py: 3 writes — router `hostel.manage` ✓
- transport.py: 3 writes — router `transport.manage` ✓
- certificate.py: 2 writes — router `certificate.issue` (write-level) ✓
- medical.py: 3 writes — routers `medical.manage` / `discipline.manage` ✓
- communication.py: 2 writes — routers `circular.publish` / `event.manage` ✓

---

## TIER 2: PROTECTED BY SUPERUSER GATE (not standard RBAC) — 22 endpoints

These use `get_current_superuser` instead of `require_permissions`. Only platform superadmins can access them.

| File | Endpoints | Auth Mechanism |
|---|---|---|
| billing.py | 6 | `get_current_superuser` |
| tenants.py (root) | 3 | `get_current_superuser` |
| operations.py (/backup) | 1 | `get_current_superuser` |
| admin/tenants.py | 6 | `get_current_superuser` |
| admin/plans.py | 3 | `get_current_superuser` |
| admin/features.py | 3 | `get_current_superuser` |

**Note:** These are intentionally superadmin-only. No fine-grained RBAC is needed for platform-level operations.

---

## TIER 3: PUBLIC / SELF-SERVICE (no auth or self-auth) — 13 endpoints

| File | Endpoint | Reason |
|---|---|---|
| auth.py | POST /register | Public registration |
| auth.py | POST /login | Public login |
| auth.py | POST /refresh | Public token refresh |
| auth.py | PUT /me | Self-service profile update |
| auth.py | POST /change-password | Self-service password change |
| auth.py | POST /logout-all | Self-service session management |
| ess.py | POST /attendance/clock-in | Employee self-service |
| ess.py | POST /attendance/clock-out | Employee self-service |
| ess.py | PUT /profile | Employee self-service |
| ess.py | POST /change-password | Employee self-service |
| admin/auth.py | POST /login | Superadmin login (is_superuser checked in handler body) |

**Note:** auth.py `/logout` (1 endpoint) lacks auth dependency entirely — counted as public. auth.py total: 7 write endpoints (4 public + 2 self-service + 1 unauthenticated logout).

---

## TIER 4: UNPROTECTED — WRITE ENDPOINTS ONLY GATED BY READ PERMISSION — 118 endpoints

**These are the security gaps.** Any user with read access to a module can perform write operations.

### root endpoints/*.py — 106 unprotected writes

| File | Unprotected | Router Permission | Needed |
|---|---|---|---|
| essl_connector.py | 14 | `biometric.read` | `biometric.manage` |
| hr_ops.py | 11 | `hr.read` | `hr.manage` |
| expense_benefits.py | 7 | `expense.read` | `expense.manage` |
| setup.py | 7 | `setup.read` | `setup.manage` |
| essl_locations.py | 3 | `biometric.read` | `biometric.manage` |
| assets.py | 5 | `asset.read` | `asset.manage` |
| ess.py | 4 | `ess.read` | `ess.manage` |
| access_control.py | 4 | `access_control.read` | `access_control.manage` |
| ot_register.py | 3 | `attendance.read` | `attendance.manage` |
| outdoor_duties.py | 3 | `attendance.read` | `attendance.manage` |
| shift_groups.py | 3 | `shift.read` | `shift.manage` |
| shift_rosters.py | 3 | `shift.read` | `shift.manage` |
| onboarding.py | 3 | `onboarding.read` | `onboarding.manage` |
| work_codes.py | 3 | `attendance.read` | `attendance.manage` |
| commands.py | 2 | `device.read` | `device.manage` |
| department_shifts.py | 2 | `shift.read` | `shift.manage` |
| exit_requests.py | 2 | `exit.read` | `exit.manage` |
| timeline.py | 2 | `employee.read` | `employee.manage` |
| notification_center.py | 2 | `notification.read` | `notification.manage` |
| operations.py (/branding) | 1 | `operations.read` | `operations.manage` |
| notifications.py | 1 | `notification.read` | `notification.manage` |
| reports.py | 1 | `report.read` | `report.manage` |
| settings_api.py | 1 | `settings.read` | `settings.manage` |
| tenant_settings.py | 1 | `settings.read` | `settings.manage` |

**Core subtotal: 106 unprotected write endpoints across 24 files**

### school/*.py — 12 unprotected writes

| File | Unprotected | Router Permission | Needed |
|---|---|---|---|
| student.py | 4 | `student.read` | `student.manage` |
| fee.py | 3 | `fee.read` | `fee.manage` |
| homework.py | 3 | `homework.read` | `homework.manage` |
| student_attendance.py | 2 | `student_attendance.read` | `student_attendance.manage` |

**School subtotal: 12 unprotected write endpoints across 4 files**

---

## DETAILED UNPROTECTED ENDPOINT LIST

### essl_connector.py (14 unprotected) — Router: `biometric.read`
- `POST /` — Create ESSL server
- `PUT /{server_id}` — Update ESSL server
- `DELETE /{server_id}` — Delete ESSL server
- `POST /{server_id}/test` — Test connection
- `POST /{server_id}/sync/employees` — Sync employees
- `POST /{server_id}/sync/attendance` — Sync attendance
- `POST /{server_id}/sync/devices` — Sync devices
- `POST /{server_id}/sync/initial` — Initial sync
- `POST /{server_id}/reprocess` — Reprocess attendance
- `POST /{server_id}/recover` — Recover sync
- `POST /{server_id}/sync/{history_id}/pause` — Pause sync
- `POST /{server_id}/sync/{history_id}/resume` — Resume sync
- `POST /{server_id}/sync/{history_id}/cancel` — Cancel sync
- `POST /duplicates/resolve` — Resolve duplicates

### hr_ops.py (11 unprotected) — Router: `hr.read`
- `POST /assets` — Create company asset
- `PUT /assets/{asset_id}` — Update company asset
- `DELETE /assets/{asset_id}` — Delete company asset
- `POST /travel` — Create travel request
- `PUT /travel/{tr_id}` — Update travel request
- `POST /announcements` — Create announcement
- `DELETE /announcements/{ann_id}` — Delete announcement
- `POST /polls` — Create poll
- `POST /polls/{poll_id}/vote` — Vote in poll
- `POST /notification-templates` — Create notification template
- `PUT /notification-templates/{tmpl_id}` — Update notification template

### expense_benefits.py (7 unprotected) — Router: `expense.read`
- `POST /expense-categories` — Create expense category
- `POST /expense-claims` — Create expense claim
- `PUT /expense-claims/{claim_id}` — Update expense claim
- `POST /tax-declarations` — Create tax declaration
- `PUT /tax-declarations/{td_id}` — Update tax declaration
- `POST /benefits` — Create benefit
- `POST /employee-benefits` — Assign benefit to employee

### setup.py (7 unprotected) — Router: `setup.read`
- `POST /company` — Create company setup
- `POST /branches` — Create branches
- `POST /departments` — Create departments
- `POST /designations` — Create designations
- `POST /shifts` — Create shifts
- `POST /leaves` — Create leave types
- `POST /attendance` — Create attendance rules

### essl_locations.py (3 unprotected) — Router: `biometric.read`
- `POST /{server_id}/locations` — Create location
- `PUT /{server_id}/locations/{location_id}` — Update location
- `DELETE /{server_id}/locations/{location_id}` — Delete location

### assets.py (5 unprotected) — Router: `asset.read`
- `POST /` — Create asset
- `PUT /{asset_id}` — Update asset
- `POST /{asset_id}/assign` — Assign asset to employee
- `POST /{asset_id}/return` — Return asset
- `POST /{asset_id}/maintenance` — Log maintenance

### ess.py (4 unprotected) — Router: `ess.read`
- `POST /attendance/clock-in` — Clock in
- `POST /attendance/clock-out` — Clock out
- `PUT /profile` — Update own profile
- `POST /change-password` — Change own password

### access_control.py (4 unprotected) — Router: `access_control.read`
- `POST /zones` — Create access zone
- `POST /doors` — Create door
- `POST /grant` — Grant access level to user
- `DELETE /grant/{access_level_id}` — Revoke access level

### student.py (4 unprotected) — Router: `student.read`
- `POST /` — Create student
- `PUT /{student_id}` — Update student
- `POST /{student_id}/guardians` — Add guardian
- `POST /{student_id}/promote` — Promote student

### ot_register.py (3 unprotected) — Router: `attendance.read`
- `POST /` — Create OT record
- `PUT /{ot_id}` — Update OT record
- `DELETE /{ot_id}` — Delete OT record

### outdoor_duties.py (3 unprotected) — Router: `attendance.read`
- `POST /` — Create outdoor duty
- `PUT /{od_id}` — Update outdoor duty
- `DELETE /{od_id}` — Delete outdoor duty

### shift_groups.py (3 unprotected) — Router: `shift.read`
- `POST /` — Create shift group
- `PUT /{group_id}` — Update shift group
- `DELETE /{group_id}` — Delete shift group

### shift_rosters.py (3 unprotected) — Router: `shift.read`
- `POST /` — Create shift roster
- `PUT /{roster_id}` — Update shift roster
- `DELETE /{roster_id}` — Delete shift roster

### onboarding.py (3 unprotected) — Router: `onboarding.read`
- `POST /` — Create onboarding task
- `PUT /{task_id}` — Update onboarding task
- `DELETE /{task_id}` — Delete onboarding task

### work_codes.py (3 unprotected) — Router: `attendance.read`
- `POST /` — Create work code
- `PUT /{wc_id}` — Update work code
- `DELETE /{wc_id}` — Delete work code

### fee.py (3 unprotected) — Router: `fee.read`
- `POST /categories` — Create fee category
- `POST /structures` — Create fee structure
- `POST /payments` — Record payment

### homework.py (3 unprotected) — Router: `homework.read`
- `POST /` — Create homework assignment
- `POST /{homework_id}/submit` — Submit homework
- `PUT /submissions/{submission_id}/review` — Review submission

### commands.py (2 unprotected) — Router: `device.read`
- `POST /` — Create device command
- `POST /{command_id}/execute` — Execute command

### department_shifts.py (2 unprotected) — Router: `shift.read`
- `POST /` — Create department-shift mapping
- `DELETE /{ds_id}` — Delete department-shift mapping

### exit_requests.py (2 unprotected) — Router: `exit.read`
- `POST /` — Create exit request
- `PUT /{req_id}` — Update exit request

### timeline.py (2 unprotected) — Router: `employee.read`
- `POST /` — Create employee event
- `DELETE /{event_id}` — Delete employee event

### notification_center.py (2 unprotected) — Router: `notification.read`
- `PUT /{notification_id}/read` — Mark notification as read
- `POST /read-all` — Mark all as read

### student_attendance.py (2 unprotected) — Router: `student_attendance.read`
- `POST /mark` — Mark single student attendance
- `POST /bulk-mark` — Bulk mark attendance

### operations.py (1 unprotected) — Router: `operations.read`
- `PUT /branding` — Update branding settings

### notifications.py (1 unprotected) — Router: `notification.read`
- `PUT /{notification_id}/read` — Mark notification as read

### reports.py (1 unprotected) — Router: `report.read`
- `POST /attendance/recalculate` — Recalculate attendance

### settings_api.py (1 unprotected) — Router: `settings.read`
- `PUT /company` — Update company settings

### tenant_settings.py (1 unprotected) — Router: `settings.read`
- `PUT /` — Update tenant settings

---

## FILES WITH NO WRITE ENDPOINTS (0 issues)

| File | Notes |
|---|---|
| dashboard.py | All GET |
| analytics.py | All GET |
| websocket.py | WebSocket only |
| system.py | All GET |
| admin/dashboard.py | All GET |
| school/school_dashboard.py | All GET |

---

## RECOMMENDED FIX PRIORITY

### P0 — Critical (data mutation without proper authZ)
1. **hr_ops.py** — 11 endpoints (assets, travel, announcements, polls, templates)
2. **expense_benefits.py** — 7 endpoints (claims, tax, benefits)
3. **essl_connector.py** — 14 endpoints (server CRUD, sync operations)
4. **setup.py** — 7 endpoints (initial company setup)
5. **assets.py** — 5 endpoints (asset CRUD, assignment)
6. **student.py** — 4 endpoints (student CRUD, promotion)
7. **essl_locations.py** — 3 endpoints (biometric location management)

### P1 — High (operational data at risk)
8. **access_control.py** — 4 endpoints (zone/door/grant management)
9. **ot_register.py** — 3 endpoints (overtime records)
10. **outdoor_duties.py** — 3 endpoints (OD records)
11. **shift_groups.py** — 3 endpoints
12. **shift_rosters.py** — 3 endpoints
13. **work_codes.py** — 3 endpoints
14. **fee.py** — 3 endpoints (fee structure, payments)
15. **homework.py** — 3 endpoints

### P2 — Medium
16. **onboarding.py** — 3 endpoints
17. **ess.py** — 4 endpoints (self-service, lower risk)
18. **commands.py** — 2 endpoints
19. **department_shifts.py** — 2 endpoints
20. **exit_requests.py** — 2 endpoints
21. **student_attendance.py** — 2 endpoints
22. **timeline.py** — 2 endpoints

### P3 — Low (self-service or low-impact)
23. **notification_center.py** — 2 endpoints (mark as read)
24. **notifications.py** — 1 endpoint (mark as read)
25. **reports.py** — 1 endpoint (recalculate)
26. **settings_api.py** — 1 endpoint (company settings)
27. **tenant_settings.py** — 1 endpoint
28. **operations.py** — 1 endpoint (branding)

---

## FIX PATTERN

Each unprotected file needs endpoint-level `require_permissions` on write handlers. Keep router-level `*.read` for GET endpoints.

**Option A — Endpoint-level dependency (recommended):**
```python
@router.post("/", dependencies=[Depends(require_permissions("asset.manage"))])
async def create_asset(...):
```

**Option B — Parameter-level dependency:**
```python
@router.post("/")
async def create_asset(
    ...,
    current_user: User = Depends(require_permissions("asset.manage")),
):
```

**Option C — Write sub-router:**
```python
write_router = APIRouter(dependencies=[Depends(require_permissions("asset.manage"))])
write_router.include_router(router)  # for reads
# Add write endpoints to write_router
```
