# APEX v2 — COMPLETE TECHNICAL HANDOVER

---

## 1. Executive Summary

**What**: Multi-tenant SaaS platform for attendance management, biometric device management (eSSL eBioserverNew), visitor management, and access control. Comparable to Keka, GreytHR, ZKTeco BioTime.

**Stack**: FastAPI + SQLAlchemy 2.x + PostgreSQL + Redis + Celery (backend). Flutter + Riverpod + Dio (frontend). Docker Compose + Nginx (infra).

**Business problem**: Enterprises need centralized attendance tracking from biometric devices, shift management, leave workflows, visitor desk operations, and access control — all tenant-isolated.

**Completion**: ~75% functional, ~55% production-ready.

| Area | Status |
|------|--------|
| Backend models (29 tables) | 100% |
| Backend API endpoints (68 routes) | 95% |
| eSSL SOAP integration (22 ops) | 100% |
| Celery background tasks (6 tasks) | 100% |
| Frontend screens (16 screens) | 90% |
| Reports (8 types, CSV/Excel/PDF) | 85% |
| Testing | 0% |
| CI/CD | 0% |
| Production hardening | 30% |

**Production readiness score**: 4/10

---

## 2. Architecture Overview

### Backend Architecture

```
FastAPI App (main.py)
├── Middleware Pipeline
│   ├── CORSMiddleware
│   ├── AuditMiddleware → audit_logs table
│   ├── RateLimitMiddleware → Redis sliding window
│   └── TenantMiddleware → JWT tenant_id extraction
├── API Router (/api/v1)
│   ├── auth (7 routes)
│   ├── tenants (5 routes)
│   ├── employees (13 routes)
│   ├── attendance (7 routes)
│   ├── devices (8 routes)
│   ├── shifts (6 routes)
│   ├── leaves (7 routes)
│   ├── visitors (8 routes)
│   ├── access_control (6 routes)
│   ├── commands (4 routes)
│   ├── notifications (3 routes)
│   ├── reports (8 routes)
│   ├── dashboard (3 routes)
│   └── websocket (1 route)
├── Services (15 files, business logic)
├── Models (15 files, 29 tables)
├── Schemas (Pydantic request/response)
└── Core (config, security, deps, RBAC)
```

Key files:
- `backend/app/main.py` — app creation, middleware, lifespan
- `backend/app/core/config.py` — pydantic-settings, all env vars
- `backend/app/core/security.py` — JWT create/decode, bcrypt
- `backend/app/core/deps.py` — get_current_user, require_permissions
- `backend/app/core/rbac.py` — default roles, permission checking
- `backend/app/db/session.py` — async engine, session factory
- `backend/app/db/base.py` — BaseModel, TenantModel abstract classes

### Frontend Architecture

```
Flutter App (main.dart)
├── Core Layer
│   ├── constants.dart — API URLs, storage keys
│   ├── dio_client.dart — Dio + JWT interceptor + token refresh
│   ├── router.dart — GoRouter with auth redirect
│   ├── secure_storage.dart
│   └── theme.dart — Material 3 light/dark
├── Models (10 files)
├── Services (13 files, Dio HTTP calls)
├── Providers (9 files, Riverpod StateNotifiers)
├── Screens (16 directories, ~40 files)
└── Widgets (9 reusable components)
```

### Authentication Flow

1. `POST /api/v1/auth/login` with email+password
2. Backend verifies bcrypt hash, creates JWT (HS256, 30min) + refresh (7 days)
3. Frontend stores tokens in `flutter_secure_storage`
4. Dio interceptor attaches `Authorization: Bearer` to every request
5. On 401, interceptor tries `POST /api/v1/auth/refresh`
6. Refresh checks Redis revocation list before issuing new pair
7. Logout stores refresh token in Redis with TTL = remaining expiry

### Authorization Flow (RBAC)

- `core/rbac.py` creates 4 default roles per tenant: Super Admin, HR Admin, Manager, Employee
- Permission model: codename-based (e.g. `employee.create`, `leave.approve`)
- `require_permissions(*codenames)` dependency checks user has ALL listed permissions
- Superusers bypass all permission checks

### Multi-Tenant Design

Every business table inherits `TenantModel` → adds `tenant_id UUID NOT NULL INDEX`.
Isolation enforced at:
- **Middleware**: `TenantMiddleware` extracts tenant_id from JWT, rejects cross-tenant
- **Service layer**: every query includes `.where(Model.tenant_id == tenant_id)`
- **Database**: FK to `tenants.id` with CASCADE delete

### External Integration

eSSL eBioserverNew SOAP at `http://keystoneinfra.ddns.net:8080/webservice.asmx`

Three-layer architecture:
1. `essl_soap.py` (649 lines) — XML envelope construction, httpx transport, tenacity retry, circuit breaker
2. `essl_client.py` (423 lines) — Redis caching, key normalization, Pydantic models
3. `sync_tasks.py` (458 lines) — Celery periodic tasks

---

## 3. Project Structure

```
C:\Apexv2\
├── .env                              # DB, Redis, JWT, eSSL, SMTP config
├── docker-compose.yml                # 6 services: postgres, redis, backend, celery_worker, celery_beat, nginx
├── Prompt.txt                        # 530-line requirements spec
├── API .txt                          # eSSL API reference
│
├── backend/
│   ├── Dockerfile                    # Python 3.12-slim
│   ├── requirements.txt              # 29 packages
│   ├── alembic.ini
│   ├── alembic/
│   │   ├── env.py                    # Async migration runner
│   │   └── versions/
│   │       └── 3b6cf98d123b_initial_schema.py  # Single migration, all 29 tables
│   ├── app/
│   │   ├── main.py
│   │   ├── core/
│   │   │   ├── config.py             # Settings class
│   │   │   ├── security.py           # JWT + bcrypt
│   │   │   ├── deps.py               # FastAPI dependencies
│   │   │   └── rbac.py               # Role/permission system
│   │   ├── db/
│   │   │   ├── session.py            # Async engine + session factory
│   │   │   └── base.py               # BaseModel, TenantModel
│   │   ├── models/                   # 15 files, 29 tables
│   │   ├── schemas/                  # Pydantic models
│   │   ├── services/                 # 15 files
│   │   ├── api/v1/endpoints/         # 16 files, 68 routes
│   │   ├── middleware/               # tenant, rate_limit, audit
│   │   ├── tasks/                    # celery_app.py, sync_tasks.py
│   │   └── utils/
│   └── tests/                        # EMPTY
│
├── frontend/
│   ├── pubspec.yaml
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                     # constants, dio_client, router, theme, secure_storage
│   │   ├── models/                   # 10 files
│   │   ├── services/                 # 13 files
│   │   ├── providers/                # 9 files
│   │   ├── screens/                  # 16 directories
│   │   └── widgets/                  # 9 files
│   └── build/web/                    # Compiled output
│
└── nginx/
    └── nginx.conf                    # Reverse proxy + static file serving
```

---

## 4. Database Analysis

### Base Classes (`backend/app/db/base.py`)

- **BaseModel**: UUID PK (`gen_random_uuid()`), `created_at`, `updated_at` (auto-update)
- **TenantModel**: BaseModel + `tenant_id UUID NOT NULL INDEX`

### ER Diagram

```
tenants (1) ──┬──< users
              ├──< roles ──< role_permissions ──< permissions
              ├──< user_roles
              ├──< audit_logs
              ├──< departments ──< employees
              ├──< designations ──< employees
              ├──< branches ──< employees, devices, access_zones
              ├──< shifts ──< employees, shift_schedules, attendances
              ├──< employees ──┬──< attendances
              │                ├──< punch_logs
              │                ├──< shift_schedules
              │                ├──< leave_balances
              │                ├──< leave_requests
              │                ├──< visitor_passes
              │                ├──< user_access_levels
              │                └──< access_logs
              ├──< devices ──┬──< device_logs
              │              ├──< device_commands
              │              └──< doors ──< access_logs
              ├──< visitors ──< visitor_passes
              ├──< access_zones ──< doors, user_access_levels
              ├──< leave_types ──< leave_balances, leave_requests
              └──< notifications
```

### Table Inventory

| # | Table | Purpose | Has Data | Actively Used |
|---|-------|---------|----------|---------------|
| 1 | tenants | Org registry | Yes (1 row) | Yes |
| 2 | users | Auth users | Yes (1 row) | Yes |
| 3 | roles | RBAC roles | Yes (4 rows) | Yes |
| 4 | permissions | Granular perms | No | Schema only |
| 5 | role_permissions | Role→Perm map | No | Schema only |
| 6 | user_roles | User→Role | Yes (1 row) | Yes |
| 7 | audit_logs | Middleware trail | Yes (8+ rows) | Yes |
| 8 | departments | Org units | No | Ready |
| 9 | designations | Job titles | No | Ready |
| 10 | branches | Office locations | No | Ready |
| 11 | employees | Employee master | No | Ready |
| 12 | devices | Biometric devices | No | Ready |
| 13 | device_logs | Device events | No | Ready |
| 14 | shifts | Shift definitions | No | Ready |
| 15 | shift_schedules | Employee↔Shift | No | Ready |
| 16 | attendances | Daily attendance | No | Ready |
| 17 | punch_logs | Raw biometric | No | Ready |
| 18 | leave_types | Leave categories | No | Ready |
| 19 | leave_balances | Leave balances | No | Ready |
| 20 | leave_requests | Leave apps | No | Ready |
| 21 | visitors | Visitor master | No | Ready |
| 22 | visitor_passes | Check-in/out | No | Ready |
| 23 | access_zones | Restricted areas | No | Ready |
| 24 | doors | Door↔Device | No | Ready |
| 25 | user_access_levels | Employee↔Zone | No | Ready |
| 26 | access_logs | Door events | No | Ready |
| 27 | device_commands | Remote commands | No | Ready |
| 28 | notifications | User notifs | No | Ready |
| 29 | alembic_version | Migration state | Yes (1 row) | Yes |

---

## 5. API Analysis

### Auth (`backend/app/api/v1/endpoints/auth.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/auth/register` | POST | No | Create tenant + admin user |
| `/api/v1/auth/login` | POST | No | JWT login |
| `/api/v1/auth/refresh` | POST | No | Refresh token pair |
| `/api/v1/auth/logout` | POST | No | Revoke refresh in Redis |
| `/api/v1/auth/me` | GET | Yes | Current user profile |
| `/api/v1/auth/me` | PUT | Yes | Update profile |
| `/api/v1/auth/change-password` | POST | Yes | Change password |

### Employees (`backend/app/api/v1/endpoints/employees.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/employees/` | GET | Yes | List employees (paginated, filtered) |
| `/api/v1/employees/` | POST | Yes | Create employee |
| `/api/v1/employees/bulk-import` | POST | Yes | CSV/Excel bulk import |
| `/api/v1/employees/{id}` | GET | Yes | Get employee detail |
| `/api/v1/employees/{id}` | PUT | Yes | Update employee |
| `/api/v1/employees/{id}` | DELETE | Yes | Delete employee |
| `/api/v1/employees/{id}/deactivate` | POST | Yes | Deactivate employee |
| `/api/v1/employees/departments` | GET | Yes | List departments |
| `/api/v1/employees/departments` | POST | Yes | Create department |
| `/api/v1/employees/designations` | GET | Yes | List designations |
| `/api/v1/employees/designations` | POST | Yes | Create designation |
| `/api/v1/employees/branches` | GET | Yes | List branches |
| `/api/v1/employees/branches` | POST | Yes | Create branch |

### Attendance (`backend/app/api/v1/endpoints/attendance.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/attendance/` | GET | Yes | List attendance records |
| `/api/v1/attendance/` | POST | Yes | Manual mark attendance |
| `/api/v1/attendance/daily-summary` | GET | Yes | Daily stats (present/absent/late) |
| `/api/v1/attendance/employee/{id}` | GET | Yes | Employee attendance summary |
| `/api/v1/attendance/process` | POST | Yes | Run attendance engine for date |
| `/api/v1/attendance/{id}/approve` | PUT | Yes | Approve attendance |
| `/api/v1/attendance/punch-logs` | GET | Yes | Raw punch logs |

### Devices (`backend/app/api/v1/endpoints/devices.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/devices/` | GET | Yes | List devices |
| `/api/v1/devices/` | POST | Yes | Register device |
| `/api/v1/devices/health` | GET | Yes | Device health summary |
| `/api/v1/devices/{id}` | GET | Yes | Device detail |
| `/api/v1/devices/{id}` | PUT | Yes | Update device |
| `/api/v1/devices/{id}` | DELETE | Yes | Delete device |
| `/api/v1/devices/{id}/logs` | GET | Yes | Device logs |
| `/api/v1/devices/{id}/sync` | POST | Yes | Trigger eSSL sync |

### Shifts (`backend/app/api/v1/endpoints/shifts.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/shifts/` | GET | Yes | List shifts |
| `/api/v1/shifts/` | POST | Yes | Create shift |
| `/api/v1/shifts/{id}` | GET | Yes | Shift detail |
| `/api/v1/shifts/{id}` | PUT | Yes | Update shift |
| `/api/v1/shifts/{id}` | DELETE | Yes | Delete shift |
| `/api/v1/shifts/assign` | POST | Yes | Assign shift to employee |
| `/api/v1/shifts/schedules/` | GET | Yes | List schedules |

### Leaves (`backend/app/api/v1/endpoints/leaves.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/leaves/types` | GET | Yes | List leave types |
| `/api/v1/leaves/types` | POST | Yes | Create leave type |
| `/api/v1/leaves/balance/{id}` | GET | Yes | Employee leave balance |
| `/api/v1/leaves/apply` | POST | Yes | Apply for leave |
| `/api/v1/leaves/requests` | GET | Yes | List leave requests |
| `/api/v1/leaves/requests/{id}/approve` | PUT | Yes | Approve leave |
| `/api/v1/leaves/requests/{id}/reject` | PUT | Yes | Reject leave |
| `/api/v1/leaves/requests/{id}/cancel` | PUT | Yes | Cancel leave |

### Visitors (`backend/app/api/v1/endpoints/visitors.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/visitors/` | GET | Yes | List visitors |
| `/api/v1/visitors/` | POST | Yes | Register visitor |
| `/api/v1/visitors/active` | GET | Yes | Active visitors |
| `/api/v1/visitors/history` | GET | Yes | Visit history |
| `/api/v1/visitors/passes` | GET | Yes | List passes |
| `/api/v1/visitors/passes` | POST | Yes | Create pass |
| `/api/v1/visitors/passes/{id}/check-in` | POST | Yes | Check in visitor |
| `/api/v1/visitors/passes/{id}/check-out` | POST | Yes | Check out visitor |

### Access Control (`backend/app/api/v1/endpoints/access_control.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/access-control/zones` | GET | Yes | List zones |
| `/api/v1/access-control/zones` | POST | Yes | Create zone |
| `/api/v1/access-control/doors` | GET | Yes | List doors |
| `/api/v1/access-control/doors` | POST | Yes | Create door |
| `/api/v1/access-control/grant` | POST | Yes | Grant access |
| `/api/v1/access-control/grant/{id}` | DELETE | Yes | Revoke access |
| `/api/v1/access-control/check` | GET | Yes | Check access |
| `/api/v1/access-control/logs` | GET | Yes | Access logs |

### Commands (`backend/app/api/v1/endpoints/commands.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/commands/` | GET | Yes | List commands |
| `/api/v1/commands/` | POST | Yes | Queue command |
| `/api/v1/commands/{id}` | GET | Yes | Command detail |
| `/api/v1/commands/{id}/execute` | POST | Yes | Execute via eSSL |

### Dashboard (`backend/app/api/v1/endpoints/dashboard.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/dashboard/stats` | GET | Yes | Real-time stats |
| `/api/v1/dashboard/attendance-chart` | GET | Yes | Trend data |
| `/api/v1/dashboard/recent-activity` | GET | Yes | Activity feed |

### Reports (`backend/app/api/v1/endpoints/reports.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/reports/attendance/daily` | GET | Yes | Daily attendance report |
| `/api/v1/reports/attendance/monthly` | GET | Yes | Monthly attendance |
| `/api/v1/reports/attendance/employee/{id}` | GET | Yes | Per-employee report |
| `/api/v1/reports/attendance/late` | GET | Yes | Late arrivals |
| `/api/v1/reports/attendance/overtime` | GET | Yes | Overtime report |
| `/api/v1/reports/attendance/absent` | GET | Yes | Absent report |
| `/api/v1/reports/visitors` | GET | Yes | Visitor report |
| `/api/v1/reports/devices` | GET | Yes | Device status report |

All reports support `format=csv|excel|pdf` query param.

### Notifications (`backend/app/api/v1/endpoints/notifications.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/notifications/` | GET | Yes | List notifications |
| `/api/v1/notifications/unread-count` | GET | Yes | Unread count |
| `/api/v1/notifications/{id}/read` | PUT | Yes | Mark as read |

### WebSocket (`backend/app/api/v1/endpoints/websocket.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/ws/dashboard` | WS | Token query param | Real-time dashboard updates |

### Tenants (`backend/app/api/v1/endpoints/tenants.py`)

| Route | Method | Auth | Purpose |
|-------|--------|------|---------|
| `/api/v1/tenants/` | GET | Superuser | List tenants |
| `/api/v1/tenants/` | POST | None (gap) | Create tenant |
| `/api/v1/tenants/{id}` | GET | None (gap) | Tenant detail |
| `/api/v1/tenants/{id}` | PUT | None (gap) | Update tenant |
| `/api/v1/tenants/{id}` | DELETE | None (gap) | Deactivate tenant |

**Security gap**: Tenant CRUD endpoints lack auth guards.

---

## 6. Authentication & Security

### JWT Implementation (`backend/app/core/security.py`)

- Algorithm: HS256
- Access token: 30 min expiry, contains `sub` (user_id) + `tenant_id`
- Refresh token: 7 day expiry, same payload
- `decode_token()` returns payload dict or None on failure
- Refresh tokens revocable via Redis set

### Password Hashing

- passlib with bcrypt scheme
- `hash_password(plain)` → bcrypt hash
- `verify_password(plain, hash)` → bool

### RBAC (`backend/app/core/rbac.py`)

Default roles per tenant (auto-created during registration):
1. **Super Admin** — wildcard permission `*`
2. **HR Admin** — employee, attendance, leave management
3. **Manager** — team attendance, leave approval
4. **Employee** — self-service only

Permission model:
- `Permission` table: name, codename, module
- `RolePermission` association: role_id, permission_id
- `UserRole` association: user_id, role_id
- `require_permissions(*codenames)` dependency factory

### Security Vulnerabilities

1. **Tenant CRUD has no auth** — anyone can create/read/update/delete tenants
2. **Hardcoded secrets** — `Keystone@999` eSSL password in `config.py` defaults
3. **JWT secret default** — `change-this-to-a-random-secret-key-in-production-min-32-chars` in `.env`
4. **CORS allows all** — `CORS_ORIGINS=["*"]` default
5. **Dio logger in production** — `PrettyDioLogger` always active, leaks request/response bodies

---

## 7. Employee Management Module

### Data Flow

1. User navigates to `/employees` → `EmployeeListScreen`
2. `employeeListProvider` calls `EmployeeService.getEmployees()` with pagination/filters
3. Dio sends `GET /api/v1/employees?page=1&page_size=20&search=...`
4. Backend `list_employees()` queries with ilike filters, eager-loads department/designation/branch/shift
5. Returns `PaginatedResponse(items=[...])`
6. Provider deserializes into `Employee` model list
7. UI renders with `PaginatedList` widget

### Tables Involved

- `employees` — main table
- `departments`, `designations`, `branches` — FK references
- `shifts` — optional FK for default shift

### APIs Used

- `GET /employees` — list with search/filter
- `POST /employees` — create
- `PUT /employees/{id}` — update
- `DELETE /employees/{id}` — delete
- `POST /employees/bulk-import` — CSV/Excel upload
- `GET/POST /employees/departments` — department CRUD
- `GET/POST /employees/designations` — designation CRUD
- `GET/POST /employees/branches` — branch CRUD

### Frontend Screens

- `employee_list_screen.dart` — list with search, department/branch/status filters
- `employee_create_screen.dart` — form with all fields
- `employee_detail_screen.dart` — view/edit with department/branch/designation management
- `department_screen.dart` — department CRUD dialog
- `branch_screen.dart` — branch CRUD dialog

### Answer: Can employees be fully managed today?

**Yes.** Create, read, update, delete, bulk import, department/designation/branch management all work end-to-end. The only gap is biometric device sync (employees are not automatically pushed to eSSL devices).

---

## 8. Attendance Module — End-to-End Trace

### Step 1: Punch Origination

Punches arrive from eSSL biometric devices. The Celery task `sync_employee_punch_logs` (in `backend/app/tasks/sync_tasks.py`) runs every 15 minutes:

1. Calls `ESSLClient.get_employee_punch_logs(employee_code, from_date, to_date)` for every employee in the DB
2. The SOAP call `GetEmployeePunchLogs` returns raw punch records from eSSL
3. Each punch is deduplicated by `(employee_id, punch_time, punch_type)` composite key
4. Device serial is mapped to local `device_id` via the `devices` table
5. New records are inserted into `punch_logs` table

**Key files**:
- `backend/app/tasks/sync_tasks.py` — `sync_employee_punch_logs` task
- `backend/app/services/essl_soap.py` — `get_employee_punch_logs()` SOAP call
- `backend/app/services/essl_client.py` — cached client facade
- `backend/app/models/attendance.py` — `PunchLog` model

### Step 2: Punch Storage

`punch_logs` table (`backend/app/models/attendance.py`):

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID PK | |
| tenant_id | UUID FK | Multi-tenant isolation |
| employee_id | UUID FK | → employees |
| device_id | UUID FK | → devices (nullable) |
| punch_time | DateTime | When the punch occurred |
| punch_type | String | "in" or "out" |
| source | String | "biometric", "manual", "mobile" |
| raw_data | JSONB | Original eSSL response |

### Step 3: Attendance Calculation

The Celery task `process_daily_attendance` runs every 15 minutes. Also callable via `POST /api/v1/attendance/process?target_date=...`.

The engine (`async_process_daily_attendance` in `sync_tasks.py`, lines 223-354):

1. Fetch all active employees for the tenant
2. For each employee:
   a. Find shift schedule for the date (or employee's default shift)
   b. Skip if no shift assigned (marked as ABSENT)
   c. Query all punches for that day (handles night shifts by extending to next day)
   d. First punch = punch_in, last punch = punch_out
   e. Calculate total_hours = (punch_out - punch_in) / 3600
   f. Compare against shift rules:
      - **Late**: punch_in > shift.start_time + grace_period_minutes
      - **Early out**: punch_out < shift.end_time - early_rule_minutes
      - **Overtime**: total_hours - shift.duration > overtime_threshold_minutes
   g. Determine status:
      - No punches → ABSENT
      - ≥ 8 hours → PRESENT
      - ≥ 4 hours → HALF_DAY
      - < 4 hours → ABSENT
   h. Upsert into `attendances` table (updates if employee+date exists)

**Key files**:
- `backend/app/tasks/sync_tasks.py` — `async_process_daily_attendance`
- `backend/app/models/attendance.py` — `Attendance` model
- `backend/app/models/shift.py` — `Shift`, `ShiftSchedule` models

### Step 4: Attendance Storage

`attendances` table:

| Column | Type | Purpose |
|--------|------|---------|
| id | UUID PK | |
| tenant_id | UUID FK | |
| employee_id | UUID FK | → employees |
| date | Date | Attendance date |
| punch_in | DateTime | First punch |
| punch_out | DateTime | Last punch |
| total_hours | Float | Calculated hours |
| overtime_hours | Float | Beyond shift duration |
| status | String | present/absent/half_day/late/early_out |
| is_late | Boolean | |
| late_minutes | Integer | |
| is_early_out | Boolean | |
| early_out_minutes | Integer | |
| shift_id | UUID FK | → shifts |
| is_manual | Boolean | True if manually marked |
| approved_by | UUID FK | → users |
| remarks | String | |

### Step 5: Reports

`ReportService` (`backend/app/services/report.py`, 431 lines) generates:
- Daily attendance — present/absent/late counts for a date
- Monthly attendance — per-employee summary for a month
- Employee attendance — date range for one employee
- Late arrivals — all late punches in date range
- Overtime — all overtime records
- Absent — all absent records

All export as CSV, Excel (openpyxl), or PDF (reportlab).

### Step 6: Frontend Display

- `attendance_list_screen.dart` — paginated list with date range, department, status filters
- `attendance_detail_screen.dart` — per-employee attendance view
- `daily_summary_screen.dart` — present/absent/late counts with "Process" button
- `mark_attendance_screen.dart` — manual attendance form

---

## 9. eSSL Integration Analysis

### Implemented SOAP Operations (22 of 23)

**Device ops (5):**
1. `GetDeviceList` — fetch all devices
2. `GetDeviceLastPing` — device heartbeat
3. `DeviceCommand_GetDeviceLogs` — device logs between dates
4. `UpdateDevice` — create/update device config
5. `DeleteDevice` — remove device

**Employee ops (7):**
6. `GetEmployeeCodes` — list all codes
7. `GetEmployeeDetails` — single lookup
8. `GetEmployeePunchLogs` — punch records (called once per day per employee)
9. `UpdateEmployee` — basic info
10. `UpdateEmployeeEx` — extended info + photo
11. `UpdateEmployeePhoto` — standalone photo
12. `DeleteEmployee` — remove

**Location ops (2):**
13. `UpdateLocation`
14. `DeleteLocation`

**Device commands (8):**
15. `DeviceCommand_Reboot`
16. `DeviceCommand_ClearLogs`
17. `DeviceCommand_EnrollFP`
18. `DeviceCommand_EnrollFace`
19. `DeviceCommand_UnlockDoor`
20. `DeviceCommand_BlockUnBlockUser`
21. `DeviceCommand_ResetOPStamp`
22. `DeviceCommand_ResetTransactionStamp`

**Visitor (1):**
23. `ValidateVisitorDesk`

### Missing: `DeviceCommand_GetDeviceIllegalLogs` — referenced in API.txt but not implemented.

### How Employee Sync Works

1. Celery task `sync_all_devices` runs every 5 minutes
2. Calls `ESSLClient.get_devices(bypass_cache=True)` → `GetDeviceList` SOAP
3. For each device returned: upserts into `devices` table
4. Assigns to first tenant (hardcoded — no multi-tenant device assignment logic)
5. Online status: `last_ping` within 5 minutes = online, else offline

**No automatic employee sync exists.** Employees must be created manually in the app. The eSSL integration fetches punch logs for employees that already exist in the local DB, but does NOT pull employee records from eSSL into the local DB.

### How Punch Log Sync Works

1. Celery task `sync_employee_punch_logs` runs every 15 minutes
2. Queries all local employees from `employees` table
3. For each employee, calls `GetEmployeePunchLogs(employee_code, yesterday, today)`
4. **N+1 problem**: iterates day-by-day, so a 30-day range = 30 sequential SOAP calls per employee
5. Deduplicates by `(employee_id, punch_time, punch_type)`
6. Maps device serial → local device_id
7. Inserts new `PunchLog` records

### How Device Command Execution Works

1. User queues command via `POST /api/v1/commands/` (creates `DeviceCommand` with status=PENDING)
2. User triggers execution via `POST /api/v1/commands/{id}/execute`
3. `CommandService.execute_command()` loads command + device
4. Sets status=SENT, calls appropriate `ESSLSoapService` method
5. On success: status=SUCCESS, stores response_data
6. On failure: status=FAILED, stores error_message

### Critical Issues

1. **N+1 SOAP calls**: 100 employees × 7 days = 700 sequential SOAP calls per 15-min sync
2. **No HTTP error retry**: `raise_for_status()` errors are not retried (only network errors)
3. **Circuit breaker too broad**: `expected_exception=Exception` trips on any error including XML parse
4. **Hardcoded credentials**: `Keystone@999` in source code
5. **In-memory pagination**: full dataset fetched before slicing
6. **Unused config**: `EBIOSERVER_MAX_RETRIES` defined but never read

---

## 10. Device Management

### Registration

- Manual via `POST /api/v1/devices/` or automatic via `sync_all_devices` Celery task
- Fields: serial_number (unique per tenant), device_name, model, firmware, ip_address, location, branch_id, device_type, communication_mode

### Status Monitoring

- `check_device_health` Celery task runs every 1 minute
- Calls `GetDeviceLastPing` for every device
- Updates status: online (ping within 5min), offline, inactive
- `GET /api/v1/devices/health` returns aggregate counts

### Sync

- `POST /api/v1/devices/{id}/sync` triggers `sync_all_devices.delay()` (syncs ALL devices, not just one)

### Commands

- Queue via `POST /api/v1/commands/` with device_id + command_type + parameters
- Execute via `POST /api/v1/commands/{id}/execute`
- 9 command types supported: reboot, clear_logs, enroll_fp, enroll_face, unlock_door, block_user, unblock_user, reset_op_stamp, reset_transaction_stamp

### Missing

- No automatic device discovery on network
- No firmware update capability
- No device grouping
- No per-device sync (only all-at-once)

---

## 11. Reports

### Available Reports (8)

| Report | Endpoint | Data Source |
|--------|----------|-------------|
| Daily Attendance | `/reports/attendance/daily` | `attendances` table |
| Monthly Attendance | `/reports/attendance/monthly` | `attendances` table |
| Employee Attendance | `/reports/attendance/employee/{id}` | `attendances` table |
| Late Arrivals | `/reports/attendance/late` | `attendances` WHERE is_late=true |
| Overtime | `/reports/attendance/overtime` | `attendances` WHERE overtime > 0 |
| Absent | `/reports/attendance/absent` | `attendances` WHERE status=absent |
| Visitor Report | `/reports/visitors` | `visitor_passes` table |
| Device Status | `/reports/devices` | `devices` table |

### Export Formats

- **CSV**: `csv.writer` → UTF-8 bytes
- **Excel**: `openpyxl.Workbook` → styled with headers
- **PDF**: `reportlab.SimpleDocTemplate` → table with styles

### Missing

- No scheduled report generation
- No email delivery of reports
- No report templates/configuration
- Frontend downloads bytes but never saves/shares the file

---

## 12. Frontend Analysis

| Screen | Route | Backend API | Status | Issues |
|--------|-------|-------------|--------|--------|
| LoginScreen | `/login` | `POST /auth/login` | Working | None |
| RegisterScreen | `/register` | `POST /auth/register` | Working | None |
| SplashScreen | `/splash` | `GET /auth/me` | Working | None |
| DashboardScreen | `/dashboard` | `GET /dashboard/stats`, `/attendance-chart`, `/recent-activity` | Working | None |
| EmployeeListScreen | `/employees` | `GET /employees` | Working | None |
| EmployeeCreateScreen | `/employees/create` | `POST /employees` | Working | None |
| EmployeeDetailScreen | `/employees/:id` | `GET/PUT /employees/{id}` | Working | None |
| DepartmentScreen | `/departments` | `GET/POST /employees/departments` | Working | None |
| BranchScreen | `/branches` | `GET/POST /employees/branches` | Working | None |
| AttendanceListScreen | `/attendance` | `GET /attendance/` | Working | None |
| AttendanceDetailScreen | `/attendance/detail` | `GET /attendance/employee/{id}` | Working | None |
| DailySummaryScreen | `/attendance/summary` | `GET /attendance/daily-summary`, `POST /attendance/process` | Working | None |
| MarkAttendanceScreen | `/attendance/mark` | `POST /attendance/` | Working | None |
| DeviceListScreen | `/devices` | `GET /devices`, `GET /devices/health` | Working | None |
| DeviceDetailScreen | `/devices/:id` | `GET /devices/{id}` | Working | None |
| DeviceHealthScreen | `/devices/health` | `GET /devices/health` | Working | None |
| ShiftListScreen | `/shifts` | `GET /shifts/` | Working | None |
| ShiftCreateScreen | `/shifts/create` | `POST /shifts/` | Working | None |
| ShiftAssignScreen | `/shifts/assign` | `POST /shifts/assign` | Working | None |
| LeaveBalanceScreen | `/leaves/balance` | `GET /leaves/balance/{id}` | **BUG** | Uses `user.id` instead of `employee.id` |
| LeaveApplyScreen | `/leaves/apply` | `POST /leaves/apply` | **BUG** | Double-prefix: `/api/v1/api/v1/leaves/apply` |
| LeaveRequestsScreen | `/leaves/requests` | `GET /leaves/requests` | Working | None |
| VisitorListScreen | `/visitors` | `GET /visitors/` | Working | None |
| VisitorRegisterScreen | `/visitors/register` | `POST /visitors/` | Working | None |
| VisitorPassScreen | `/visitors/pass` | `GET /visitors/passes` | **BUG** | Fetches all then filters locally |
| ActiveVisitorsScreen | `/visitors/active` | `GET /visitors/active` | Working | None |
| ZoneListScreen | `/access/zones` | `GET/POST /access-control/zones` | Working | None |
| DoorListScreen | `/access/doors` | `GET/POST /access-control/doors` | Working | None |
| AccessLogsScreen | `/access/logs` | `GET /access-control/logs` | Working | None |
| CommandCenterScreen | `/commands` | `GET/POST /commands` | Working | None |
| NotificationListScreen | `/notifications` | `GET /notifications/` | Working | None |
| ReportSelectionScreen | `/reports` | `GET /reports/*` | **BUG** | Downloads bytes, never saves file |
| SettingsScreen | `/settings` | Various navigation | Working | None |
| MainShell | Shell route | WebSocket connect | Working | None |

### Known Bugs

1. **`leave_service.dart` lines 40, 72, 79, 89**: Double-prefix bug. Uses `ApiConstants.baseUrl + '/leaves/apply'` but Dio already has `baseUrl` set. Result: `/api/v1/api/v1/leaves/apply` → 404.

2. **`report_selection_screen.dart`**: Downloads report bytes but never writes to disk or opens the file. User sees "Download completed" but gets nothing.

3. **`visitor_pass_screen.dart`**: Fetches all passes paginated then does `.firstWhere()` locally instead of calling a single-item endpoint.

4. **`leave_balance_screen.dart`**: Passes `user.id` as `employeeId`. If user ID ≠ employee ID (likely), returns wrong data.

5. **WebSocket URL hardcoded**: `ws://localhost/api/v1/ws/dashboard` — won't work on non-localhost deployments.

---

## 13. Background Jobs

All in `backend/app/tasks/sync_tasks.py` via Celery Beat:

| Task | Interval | Purpose | eSSL Calls |
|------|----------|---------|------------|
| `sync_all_devices` | 5 min | Pull device list from eSSL, upsert into DB | `GetDeviceList` |
| `sync_employee_punch_logs` | 15 min | Pull punch logs for all employees | `GetEmployeePunchLogs` × N employees × days |
| `process_daily_attendance` | 15 min | Calculate attendance from punch logs | None (DB only) |
| `check_device_health` | 1 min | Ping each device for status | `GetDeviceLastPing` × N devices |
| `send_notification_digests` | 1 hour | Process pending notifications | None |
| `cleanup_old_logs` | Daily midnight | Delete DeviceLog > 30 days | None |

**Celery config** (`backend/app/tasks/celery_app.py`):
- Broker: Redis (db 1)
- Result backend: Redis (db 2)
- Beat schedule defined in `celery_beat_schedule`

**Note**: Celery workers are defined in `docker-compose.yml` but the beat schedule references tasks that use `asyncio.run()` to bridge sync Celery → async SQLAlchemy.

---

## 14. Production Readiness Audit

| Category | Score | Notes |
|----------|-------|-------|
| Architecture | 7/10 | Clean layered design, proper separation of concerns |
| Security | 3/10 | Hardcoded secrets, no auth on tenant CRUD, CORS wildcard, logger in prod |
| Scalability | 5/10 | Async backend, connection pooling, but N+1 SOAP calls, in-memory pagination |
| Reliability | 4/10 | No tests, circuit breaker too broad, no retry on HTTP errors |
| Maintainability | 6/10 | Good code structure, but no docstrings, no type hints on some services |
| Performance | 5/10 | Redis caching, but aggressive health polling (1min), sequential SOAP calls |
| **Overall** | **4/10** | Functional but not production-ready |

---

## 15. Critical Questions

### Q1: How are employees fetched?

Employees are created manually via the Flutter app (`POST /api/v1/employees`) or bulk-imported via CSV/Excel. There is NO automatic sync from eSSL to the local DB. The eSSL integration only fetches punch logs for employees that already exist locally.

### Q2: How are punch logs fetched?

Celery task `sync_employee_punch_logs` runs every 15 minutes. It queries all local employees, then for each one calls `GetEmployeePunchLogs` SOAP API with yesterday-today date range. Results are deduplicated and inserted into `punch_logs` table.

### Q3: How is attendance calculated?

Celery task `process_daily_attendance` runs every 15 minutes (also manually triggerable via API). For each active employee: finds their shift, collects punches for the day, determines punch_in (first) and punch_out (last), calculates hours/lateness/overtime, assigns status (present/absent/half_day/late), upserts into `attendances` table.

### Q4: Which jobs must run automatically?

- `sync_all_devices` — every 5 min (device registry sync)
- `sync_employee_punch_logs` — every 15 min (punch data)
- `process_daily_attendance` — every 15 min (attendance calculation)
- `check_device_health` — every 1 min (device status)
- `cleanup_old_logs` — daily (maintenance)

### Q5: What happens when a new device is added?

If added to eSSL: `sync_all_devices` picks it up within 5 minutes, creates a local `Device` record, assigns to first tenant. If added locally via `POST /api/v1/devices/`: only exists locally, NOT pushed to eSSL.

### Q6: What happens when a new employee is added on a biometric device?

**Nothing automatic.** The employee must be manually created in the Apex app with the same `employee_code` used on the device. Only then will `sync_employee_punch_logs` start fetching their punches. There is no reverse sync from eSSL employee list to local DB.

### Q7: What data is stored locally versus fetched live?

| Data | Stored Locally | Fetched Live |
|------|---------------|--------------|
| Employees | Yes (employees table) | No |
| Punch logs | Yes (punch_logs table) | Synced every 15 min from eSSL |
| Attendance | Yes (attendances table) | Calculated from punch_logs |
| Devices | Yes (devices table) | Synced every 5 min from eSSL |
| Device health | Yes (status column) | Checked every 1 min from eSSL |
| Visitor validation | No | Called live on check-in |
| Device commands | Yes (device_commands table) | Executed live via eSSL |

---

## 16. Missing Work (Prioritized)

### CRITICAL (must fix before any real use)

1. **Seed leave types** — No leave types exist. Leave module is non-functional without them. Effort: 1 hour.

2. **Fix double-prefix bug in leave_service.dart** — Leave apply/approve/reject/cancel all 404. Effort: 15 min.

3. **Fix tenant CRUD auth** — All tenant endpoints are unprotected. Effort: 30 min.

4. **Rotate secrets** — JWT secret, eSSL password, DB password all hardcoded. Effort: 30 min.

5. **Add employee↔eSSL sync** — Without this, punch logs are never fetched for new employees. Need `GetEmployeeCodes` → auto-create local employees. Effort: 4 hours.

6. **Fix report download** — Frontend downloads bytes but never saves file. Effort: 2 hours.

### HIGH (needed for real usage)

7. **Add HTTPS** — No SSL certificates configured. Effort: 2 hours.

8. **Add data seeding** — Departments, designations, shifts, leave types need initial data. Effort: 3 hours.

9. **Fix N+1 SOAP calls** — `sync_employee_punch_logs` makes sequential calls per employee per day. Should batch or use date-range API. Effort: 4 hours.

10. **Add WebSocket reconnection** — Current implementation reconnects but doesn't re-authenticate. Effort: 2 hours.

11. **Fix Dio logger** — Disable `PrettyDioLogger` in production builds. Effort: 15 min.

12. **Fix CORS** — Should not be wildcard in production. Effort: 15 min.

### MEDIUM (improve reliability)

13. **Add backend tests** — Empty `tests/` directory. Need unit + integration tests. Effort: 3-5 days.

14. **Add frontend tests** — No test files. Effort: 3-5 days.

15. **Add CI/CD pipeline** — No GitHub Actions. Effort: 1 day.

16. **Fix circuit breaker** — `expected_exception=Exception` is too broad. Should be `httpx.RequestError`. Effort: 30 min.

17. **Add HTTP error retry** — `raise_for_status()` errors should be retried. Effort: 1 hour.

18. **Add database backups** — No backup strategy. Effort: 2 hours.

19. **Add monitoring** — No health metrics, no alerting. Effort: 1 day.

### LOW (nice to have)

20. **Add API rate limiting per endpoint** — Currently global only. Effort: 2 hours.

21. **Add audit log UI** — Audit logs are collected but not viewable. Effort: 4 hours.

22. **Add holiday management** — Referenced in requirements but no implementation. Effort: 1 day.

23. **Add payroll export** — Referenced in requirements but no implementation. Effort: 2 days.

24. **Add mobile app** — Flutter web exists, but mobile-specific features (push notifications, camera) not implemented. Effort: 1-2 weeks.

25. **Add notification delivery** — Email/SMS channels defined but no actual sending. Effort: 2 days.

---

## 17. Final Verdict

### What is actually finished?

- Complete database schema with 29 properly constrained tables
- Full CRUD APIs for all 14 modules (68 endpoints)
- JWT authentication with refresh token revocation
- RBAC with 4 default roles
- Multi-tenant middleware with cross-tenant protection
- eSSL SOAP integration (22 operations)
- Celery background tasks (6 periodic jobs)
- Flutter web frontend with 16 screens, all connecting to real APIs
- Docker Compose deployment with nginx reverse proxy
- Report generation in CSV/Excel/PDF formats

### What only appears finished?

- **Leave module**: Double-prefix bug makes apply/approve/reject/cancel all fail
- **Report downloads**: Backend generates files but frontend never delivers them to the user
- **Employee sync from eSSL**: All the SOAP code exists but no task actually pulls employees into the local DB
- **Visitor desk validation**: SOAP call exists but failures are silently swallowed
- **Holiday management**: Mentioned in requirements, zero implementation
- **Payroll export**: Mentioned in requirements, zero implementation

### What will fail in production?

- Hardcoded JWT secret → token forgery possible
- CORS wildcard → any origin can call the API
- No HTTPS → credentials transmitted in plaintext
- N+1 SOAP calls → sync tasks will timeout with >50 employees
- Circuit breaker on Exception → any XML glitch disables eSSL for 60 seconds
- No database backups → data loss on container failure
- Dio logger active → sensitive data in browser console

### What should be built next?

1. Fix the 3 critical bugs (leave double-prefix, tenant auth, report download)
2. Add employee auto-sync from eSSL
3. Seed initial data (departments, shifts, leave types)
4. Rotate all secrets
5. Add HTTPS
6. Add backend tests
7. Fix the N+1 SOAP performance issue
