# High Severity Security Fixes — Apex HRMS

## Date: 2026-06-28

---

## 1. import_export.py — Write Endpoints Protected Only by Read Permission

**Severity:** HIGH  
**File:** `backend/app/api/v1/endpoints/import_export.py`

**Issue:** The router declared `require_permissions("employee.read")` at the router level, granting all authenticated users with read access the ability to import employees and leave balances (POST endpoints).

**Fix:**
- `POST /import/employees` — added `dependencies=[Depends(require_permissions("employee.create"))]`
- `POST /import/leave-balances` — added `dependencies=[Depends(require_permissions("employee.manage"))]`
- Fixed duplicate `require_permissions` import

---

## 2. examination.py — Missing Write Permissions + Cross-Tenant Marks Entry

**Severity:** HIGH  
**File:** `backend/app/api/v1/endpoints/school/examination.py`

**Issue 2a:** Router declared `require_permissions("exam.read")` but had 5 POST write endpoints with no write permission check.

**Fix 2a:** Added endpoint-level write permissions:
- `POST /exam-types` → `require_permissions("exam.create")`
- `POST /exams` → `require_permissions("exam.create")`
- `POST /exams/{exam_id}/schedules` → `require_permissions("exam.manage")`
- `POST /marks/enter` → `require_permissions("exam.manage")`
- `POST /marks/bulk-enter` → `require_permissions("exam.manage")`
- `POST /grading-scales` → `require_permissions("exam.manage")`

**Issue 2b:** `POST /marks/enter` queried for existing marks by `exam_schedule_id` and `student_id` WITHOUT filtering by `tenant_id`. A user from Tenant A could modify marks belonging to Tenant B.

**Fix 2b:** Added `ExamMark.tenant_id == current_user.tenant_id` to the existing-mark lookup query at line 177.

---

## 3. Cross-Tenant Data Access — 4 Files, 6 Endpoints

**Severity:** HIGH

### 3a. recruitment.py — Candidate Stage Modification

**File:** `backend/app/api/v1/endpoints/recruitment.py`

**Issue:** Three endpoints (`POST /offers`, `PUT /offers/{id}/accept`, `PUT /offers/{id}/reject`) fetched candidates via `db.get(Candidate, id)` without tenant filtering, then modified `candidate.stage`.

**Fix:** Replaced `db.get(Candidate, id)` with `select(Candidate).where(Candidate.id == id, Candidate.tenant_id == current_user.tenant_id)` in all three endpoints.

### 3b. school/hostel.py — Student Room Assignment

**File:** `backend/app/api/v1/endpoints/school/hostel.py`

**Issue:** `POST /allocations` fetched student via `db.get(Student, student_id)` without tenant check, then set `student.hostel_room_id`.

**Fix:** Added tenant filter: `select(Student).where(Student.id == id, Student.tenant_id == current_user.tenant_id)`

### 3c. school/transport.py — Student Route Assignment

**File:** `backend/app/api/v1/endpoints/school/transport.py`

**Issue:** `POST /students/assign` fetched student via `db.get(Student, student_id)` without tenant check, then set `student.transport_route_id`.

**Fix:** Added tenant filter: `select(Student).where(Student.id == id, Student.tenant_id == current_user.tenant_id)`

### 3d. school/fee.py — Fee Status Modification

**File:** `backend/app/api/v1/endpoints/school/fee.py`

**Issue:** `POST /payments` fetched `StudentFee` via `db.get(StudentFee, fee_id)` without tenant check, then modified `student_fee.status`.

**Fix:** Added tenant filter: `select(StudentFee).where(StudentFee.id == id, StudentFee.tenant_id == current_user.tenant_id)`

---

## 4. Duplicate Import Cleanup — 40 Files

**Severity:** LOW (code hygiene)  
**Files:** All 40 endpoint files with duplicate `require_permissions` imports

**Issue:** Every endpoint file had `from app.core.deps import ..., require_permissions, require_permissions` (imported twice).

**Fix:** Removed duplicate import from all 40 files.

---

## Remaining Recommendations (Not Fixed — Out of Scope)

### Write Endpoints with Only Read Permissions (45 files)

45 endpoint files use `require_permissions("x.read")` at the router level while exposing POST/PUT/DELETE endpoints. Each write endpoint should have its own `dependencies=[Depends(require_permissions("x.create"))]` or equivalent. Key files:

- `employees.py` (14 write endpoints, `employee.read`)
- `essl_connector.py` (14 write endpoints, `biometric.read`)
- `billing.py` (6 write endpoints, `billing.read`)
- `access_control.py` (4 write endpoints, `access_control.read`)
- `assets.py` (5 write endpoints, `asset.read`)
- `attendance.py` (3 write endpoints, `attendance.read`)
- `devices.py` (4 write endpoints, `device.read`)
- And 38 more files...

### Post-Fetch Tenant Check Pattern (~37 endpoints)

Files like `lifecycle.py`, `performance.py`, `recruitment.py`, `assets.py`, and several school modules use `db.get(Model, id)` then check `model.tenant_id != tenant` post-fetch. This leaks timing information. Should be converted to `select(Model).where(Model.id == id, Model.tenant_id == tenant_id)`.

---

## Verification

```
$ cd backend && python -c "from app.api.v1.router import api_router; print(f'OK: {len(api_router.routes)} routes')"
OK: 455 routes
```

All 455 routes load successfully after fixes.
