# Apex v2 — Project Context & Handover Document

**Last Updated**: 2026-06-25  
**Architecture Version**: 2.0  
**Database Version**: 4 migrations  

---

## Project Overview

**Product Name**: Apex Attendance Platform  
**Purpose**: Multi-tenant SaaS platform for attendance management, biometric device management (eSSL eBioserverNew), visitor management, and access control. Similar to Keka, GreytHR, ZKTeco BioTime.  
**Target Users**: Enterprise HR departments managing attendance across multiple locations with biometric devices.  
**Current Stage**: Backend ~85% complete, Frontend ~80% complete, eSSL Connector ~90% complete.  

---

## Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Backend | Python + FastAPI | 3.12 / 0.115.0 |
| ORM | SQLAlchemy (async) | 2.0.35 |
| Database | PostgreSQL | 16 |
| Migration | Alembic | 1.13.2 |
| Cache | Redis | 7 |
| Queue | Celery | 5.4.0 |
| Frontend | Flutter + Riverpod | 3.44.0 / 2.6.1 |
| HTTP Client | Dio | 5.9.2 |
| Routing | GoRouter | 14.8.1 |
| Auth | JWT (HS256) | python-jose 3.3.0 |
| SOAP | httpx + lxml | 0.27.2 / 5.3.0 |
| Infra | Docker Compose + Nginx | latest |

---

## Current Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Nginx (Port 80)                          │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐│
│  │ Static Files │  │ /api/ proxy  │  │ /ws/ WebSocket proxy   ││
│  │ Flutter Web  │  │ → backend    │  │ → backend              ││
│  └──────────────┘  └──────────────┘  └────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FastAPI Backend (Port 8000)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────┐│
│  │ API Router   │  │ Middleware   │  │ Services               ││
│  │ 68 endpoints │  │ Tenant/RBAC  │  │ Business Logic         ││
│  │              │  │ Rate Limit   │  │                        ││
│  │              │  │ Audit        │  │                        ││
│  └──────────────┘  └──────────────┘  └────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌──────────────┐  ┌──────────────┐  ┌────────────────────────────┐
│ PostgreSQL   │  │ Redis        │  │ Celery Workers             │
│ 29+ tables   │  │ Cache/Queue  │  │ Sync Tasks                 │
│              │  │              │  │                            │
└──────────────┘  └──────────────┘  └────────────────────────────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ eSSL Server  │
                                    │ SOAP API     │
                                    └──────────────┘
```

---

## Database Tables

### Core Tables
| Table | Purpose |
|-------|---------|
| `tenants` | Tenant/org registry with subscription plans |
| `users` | Auth users with tenant_id FK |
| `roles` | RBAC roles (Super Admin, HR Admin, Manager, Employee) |
| `permissions` | Granular permissions with codenames |
| `role_permissions` | Role↔Permission mapping |
| `user_roles` | User↔Role mapping |
| `audit_logs` | Middleware audit trail |

### Employee Tables
| Table | Purpose |
|-------|---------|
| `employees` | Employee master with department/designation/branch/shift |
| `departments` | Organizational units |
| `designations` | Job titles |
| `branches` | Office locations |

### Attendance Tables
| Table | Purpose |
|-------|---------|
| `attendances` | Daily attendance records (calculated) |
| `punch_logs` | Raw biometric punches |
| `shifts` | Shift definitions with grace/late/OT rules |
| `shift_schedules` | Employee↔Shift assignments with date ranges |
| `attendance_raw_logs` | Raw eSSL punch data before processing |

### Leave Tables
| Table | Purpose |
|-------|---------|
| `leave_types` | Leave categories (Casual, Sick, Earned, Comp Off) |
| `leave_balances` | Employee leave balances per type per year |
| `leave_requests` | Leave applications with approval workflow |

### Device Tables
| Table | Purpose |
|-------|---------|
| `devices` | Biometric device registry |
| `device_logs` | Device event logs |
| `device_commands` | Remote command queue (reboot, sync, etc.) |

### Visitor Tables
| Table | Purpose |
|-------|---------|
| `visitors` | Visitor master |
| `visitor_passes` | Visitor check-in/out passes |

### Access Control Tables
| Table | Purpose |
|-------|---------|
| `access_zones` | Restricted areas |
| `doors` | Door↔Device mapping |
| `user_access_levels` | Employee↔Zone access grants |
| `access_logs` | Door access events |

### eSSL Connector Tables
| Table | Purpose |
|-------|---------|
| `essl_servers` | Per-tenant eSSL server config with encrypted credentials |
| `essl_sync_history` | Sync job audit trail with progress tracking |
| `essl_sync_jobs` | Scheduled sync job definitions |
| `essl_sync_errors` | Granular error log per sync entity |
| `essl_employee_mapping` | eSSL employee_code ↔ local employee_id |
| `essl_device_mapping` | eSSL serial_number ↔ local device_id |
| `essl_sync_cursor` | Persistent cursor for incremental sync |

### Other Tables
| Table | Purpose |
|-------|---------|
| `notifications` | User notifications |

---

## eSSL Connector Architecture

### Per-Tenant Server Configuration
Each tenant can have multiple eSSL servers (HO, Factory, Warehouse, Branch). Configuration stored in `essl_servers` with:
- Encrypted credentials (Fernet symmetric encryption)
- Per-type sync intervals (attendance=5min, devices=60min, employees=daily 2AM)
- Conflict resolution policies (ignore/disable/soft_delete/hard_delete)

### SOAP Integration
Three-layer architecture:
1. `ESSLSoapService` — Raw XML transport with httpx, tenacity retry, circuit breaker
2. `ESSLClient` — Redis caching, key normalization, Pydantic models
3. `EsslConnectorService` — Per-tenant connector with bulk sync and cursors

### Employee Sync
**Strategy**: Bulk codes first, then per-new-employee details.
```
GetEmployeeCodes → all codes from eSSL
    ↓
For each code: check if exists across ALL servers
    ↓
If new: GetEmployeeDetails → create employee + mapping
If exists on other server: add mapping (reuse employee)
If exists on this server: update
```

### Attendance Sync
**Strategy**: Bulk via GetDeviceLogs (one call per device, not per employee).
```
For each device:
    GetDeviceLogs(serial, cursor_time, now) → ALL punches
        ↓
    For each punch:
        Resolve employee_id from mapping
        Resolve device_id from mapping
        Skip if punch_time <= cursor (already fetched)
        Upsert into attendance_raw_logs (dedup by server+code+time+type)
        ↓
    Update cursor: last_punch_time = max fetched
```

### Device Sync
**Strategy**: GetDeviceList + GetDeviceLastPing for status.
```
GetDeviceList → all devices
    ↓
For each device:
    Check if exists across ALL servers
    If new: create device + mapping
    If exists on other server: add mapping (migration)
    If exists on this server: update
    GetDeviceLastPing → update status
```

### Sync Cursor
Persistent state per server per type. Enables "fetch after cursor" instead of "download everything again".
- `last_punch_time` — Latest punch timestamp fetched
- `last_employee_sync` — Last employee sync timestamp
- `last_device_sync` — Last device sync timestamp

### Attendance Processing Pipeline
```
eSSL SOAP → attendance_raw_logs → AttendanceProcessor → attendances table
```
NEVER reads from eSSL directly during calculation.

Processing logic:
1. Query unprocessed raw logs
2. Resolve employee_id and device_id from mappings
3. Group punches by employee
4. For each employee: find shift, calculate hours/lateness/OT
5. Upsert into attendances table

### Duplicate Detection
Two-level approach:
1. **Per-server dedup**: Unique constraint `(essl_server_id, employee_code, punch_time, punch_type)`
2. **Cross-server detection**: `DuplicateDetector` service identifies punches from multiple servers
3. **Resolution strategies**: keep_first, keep_all, mark_review

### Offline Recovery
When eSSL server comes back online:
1. Test connection
2. Validate cursor integrity (repair if corrupted)
3. Incremental sync from cursor position
4. Process unprocessed raw logs
5. Recalculate attendance for affected dates
6. Track consecutive failures

### Initial Sync (First-time Import)
Supports configurable date range with progress tracking:
- Day-by-day processing for progress updates
- Pause/Resume/Cancel support
- Real-time progress polling
- Statistics (created, skipped, failed)

### Multi-Server Support
Key design decisions:
- Same employee across multiple servers → reuse employee, add mapping
- Same device across multiple servers → reuse device, add mapping
- Punch dedup per server, cross-server detection service
- Employee transfer preserves history
- Device migration preserves history

### Conflict Resolution
When entity exists locally but not in eSSL:
- `ignore` — Leave local record untouched
- `disable` — Set is_active=False
- `soft_delete` — Mark as deleted
- `hard_delete` — Remove from DB

---

## API Endpoints

### Auth (`/api/v1/auth`)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/register` | Create tenant + admin user |
| POST | `/login` | JWT login |
| POST | `/refresh` | Refresh token pair |
| POST | `/logout` | Revoke refresh token |
| GET | `/me` | Current user profile |
| PUT | `/me` | Update profile |
| POST | `/change-password` | Change password |

### Employees (`/api/v1/employees`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List employees (paginated, filtered) |
| POST | `/` | Create employee |
| POST | `/bulk-import` | CSV/Excel bulk import |
| GET | `/{id}` | Employee detail |
| PUT | `/{id}` | Update employee |
| DELETE | `/{id}` | Delete employee |
| POST | `/{id}/deactivate` | Deactivate employee |
| GET | `/departments` | List departments |
| POST | `/departments` | Create department |
| GET | `/designations` | List designations |
| POST | `/designations` | Create designation |
| GET | `/branches` | List branches |
| POST | `/branches` | Create branch |

### Attendance (`/api/v1/attendance`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List attendance records |
| POST | `/` | Manual mark attendance |
| GET | `/daily-summary` | Daily stats |
| GET | `/employee/{id}` | Employee attendance summary |
| POST | `/process` | Run attendance engine |
| PUT | `/{id}/approve` | Approve attendance |
| GET | `/punch-logs` | Raw punch logs |

### Devices (`/api/v1/devices`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List devices |
| POST | `/` | Register device |
| GET | `/health` | Device health summary |
| GET | `/{id}` | Device detail |
| PUT | `/{id}` | Update device |
| DELETE | `/{id}` | Delete device |
| GET | `/{id}/logs` | Device logs |
| POST | `/{id}/sync` | Trigger sync |

### Shifts (`/api/v1/shifts`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List shifts |
| POST | `/` | Create shift |
| GET | `/{id}` | Shift detail |
| PUT | `/{id}` | Update shift |
| DELETE | `/{id}` | Delete shift |
| POST | `/assign` | Assign shift to employee |
| GET | `/schedules/` | List schedules |

### Leaves (`/api/v1/leaves`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/types` | List leave types |
| POST | `/types` | Create leave type |
| GET | `/balance/{id}` | Employee leave balance |
| POST | `/apply` | Apply for leave |
| GET | `/requests` | List leave requests |
| PUT | `/requests/{id}/approve` | Approve leave |
| PUT | `/requests/{id}/reject` | Reject leave |
| PUT | `/requests/{id}/cancel` | Cancel leave |

### Visitors (`/api/v1/visitors`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List visitors |
| POST | `/` | Register visitor |
| GET | `/active` | Active visitors |
| GET | `/history` | Visit history |
| GET | `/passes` | List passes |
| POST | `/passes` | Create pass |
| POST | `/passes/{id}/check-in` | Check in visitor |
| POST | `/passes/{id}/check-out` | Check out visitor |

### Access Control (`/api/v1/access-control`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/zones` | List zones |
| POST | `/zones` | Create zone |
| GET | `/doors` | List doors |
| POST | `/doors` | Create door |
| POST | `/grant` | Grant access |
| DELETE | `/grant/{id}` | Revoke access |
| GET | `/check` | Check access |
| GET | `/logs` | Access logs |

### Commands (`/api/v1/commands`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List commands |
| POST | `/` | Queue command |
| GET | `/{id}` | Command detail |
| POST | `/{id}/execute` | Execute via eSSL |

### Dashboard (`/api/v1/dashboard`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/stats` | Real-time stats |
| GET | `/attendance-chart` | Trend data |
| GET | `/recent-activity` | Activity feed |

### Reports (`/api/v1/reports`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/attendance/daily` | Daily attendance |
| GET | `/attendance/monthly` | Monthly attendance |
| GET | `/attendance/employee/{id}` | Per-employee |
| GET | `/attendance/late` | Late arrivals |
| GET | `/attendance/overtime` | Overtime |
| GET | `/attendance/absent` | Absent |
| GET | `/visitors` | Visitor report |
| GET | `/devices` | Device status |

### Notifications (`/api/v1/notifications`)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | List notifications |
| GET | `/unread-count` | Unread count |
| PUT | `/{id}/read` | Mark as read |

### eSSL Connector (`/api/v1/essl`)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/` | Create eSSL server |
| GET | `/` | List eSSL servers |
| GET | `/{id}` | Get server config |
| PUT | `/{id}` | Update server |
| DELETE | `/{id}` | Delete server |
| POST | `/{id}/test` | Test connection |
| POST | `/{id}/sync/employees` | Manual employee sync |
| POST | `/{id}/sync/attendance` | Manual attendance sync |
| POST | `/{id}/sync/devices` | Manual device sync |
| POST | `/{id}/sync/initial` | Initial sync with date range |
| POST | `/{id}/sync/{hid}/pause` | Pause sync |
| POST | `/{id}/sync/{hid}/resume` | Resume sync |
| POST | `/{id}/sync/{hid}/cancel` | Cancel sync |
| GET | `/{id}/sync/{hid}/progress` | Get sync progress |
| GET | `/{id}/sync/history` | Sync history |
| GET | `/{id}/sync/errors` | Sync errors |
| POST | `/{id}/recover` | Offline recovery |
| GET | `/{id}/recovery-status` | Recovery status |
| GET | `/{id}/cursor-integrity` | Validate cursor |
| GET | `/dashboard/sync-status` | Enhanced dashboard |
| GET | `/duplicates/stats` | Duplicate statistics |
| GET | `/duplicates/cross-server` | Find cross-server duplicates |
| POST | `/duplicates/resolve` | Resolve duplicates |

### WebSocket (`/api/v1/ws`)
| Path | Purpose |
|------|---------|
| `/dashboard` | Real-time dashboard updates |

---

## Frontend Screens

| Screen | Route | Status |
|--------|-------|--------|
| LoginScreen | `/login` | ✅ Complete |
| RegisterScreen | `/register` | ✅ Complete |
| SplashScreen | `/splash` | ✅ Complete |
| DashboardScreen | `/dashboard` | ✅ Complete |
| EmployeeListScreen | `/employees` | ✅ Complete |
| EmployeeCreateScreen | `/employees/create` | ✅ Complete |
| EmployeeDetailScreen | `/employees/:id` | ✅ Complete |
| DepartmentScreen | `/departments` | ✅ Complete |
| BranchScreen | `/branches` | ✅ Complete |
| AttendanceListScreen | `/attendance` | ✅ Complete |
| AttendanceDetailScreen | `/attendance/detail` | ✅ Complete |
| DailySummaryScreen | `/attendance/summary` | ✅ Complete |
| MarkAttendanceScreen | `/attendance/mark` | ✅ Complete |
| DeviceListScreen | `/devices` | ✅ Complete |
| DeviceDetailScreen | `/devices/:id` | ✅ Complete |
| DeviceHealthScreen | `/devices/health` | ✅ Complete |
| ShiftListScreen | `/shifts` | ✅ Complete |
| ShiftCreateScreen | `/shifts/create` | ✅ Complete |
| ShiftAssignScreen | `/shifts/assign` | ✅ Complete |
| LeaveBalanceScreen | `/leaves/balance` | ⚠️ Uses user.id instead of employee.id |
| LeaveApplyScreen | `/leaves/apply` | ⚠️ Double-prefix bug |
| LeaveRequestsScreen | `/leaves/requests` | ✅ Complete |
| VisitorListScreen | `/visitors` | ✅ Complete |
| VisitorRegisterScreen | `/visitors/register` | ✅ Complete |
| VisitorPassScreen | `/visitors/pass` | ⚠️ Fetches all then filters |
| ActiveVisitorsScreen | `/visitors/active` | ✅ Complete |
| ZoneListScreen | `/access/zones` | ✅ Complete |
| DoorListScreen | `/access/doors` | ✅ Complete |
| AccessLogsScreen | `/access/logs` | ✅ Complete |
| CommandCenterScreen | `/commands` | ✅ Complete |
| NotificationListScreen | `/notifications` | ✅ Complete |
| ReportSelectionScreen | `/reports` | ⚠️ Downloads but never saves |
| SettingsScreen | `/settings` | ✅ Complete |
| EsslServerListScreen | `/settings/essl` | ✅ Complete |
| EsslServerFormScreen | `/settings/essl/:id` | ✅ Complete |
| EsslSyncHistoryScreen | `/settings/essl/:id/history` | ✅ Complete |
| EsslInitialSyncScreen | `/settings/essl/:id/initial-sync` | ✅ Complete |
| EsslDashboardScreen | `/settings/essl/dashboard` | ✅ Complete |

---

## Features Completed

### Backend ✅
- [x] Multi-tenant architecture with TenantModel
- [x] JWT authentication with refresh tokens
- [x] RBAC with 4 default roles
- [x] All CRUD APIs for 14 modules
- [x] eSSL SOAP integration (22 operations)
- [x] Per-tenant eSSL server configuration
- [x] Encrypted credential storage
- [x] Connection testing
- [x] Employee sync (bulk codes + per-new details)
- [x] Attendance sync (bulk GetDeviceLogs + cursor)
- [x] Device sync with migration support
- [x] Sync cursors for incremental fetching
- [x] Attendance processing pipeline
- [x] Duplicate detection service
- [x] Offline recovery
- [x] Initial sync with date range
- [x] Multi-server support
- [x] Conflict resolution policies
- [x] Enhanced sync dashboard
- [x] Celery background tasks (4 periodic)
- [x] Audit middleware
- [x] Rate limiting middleware
- [x] Tenant isolation middleware
- [x] Report generation (CSV/Excel/PDF)

### Frontend ✅
- [x] All 38 screens implemented
- [x] Riverpod state management
- [x] Dio with JWT interceptor + token refresh
- [x] GoRouter with auth redirect
- [x] Material 3 theming
- [x] WebSocket real-time dashboard
- [x] eSSL server management UI
- [x] Initial sync wizard
- [x] Sync dashboard with all metrics
- [x] Sync history viewer

### Infrastructure ✅
- [x] Docker Compose (postgres, redis, backend, celery_worker, celery_beat, nginx)
- [x] Nginx reverse proxy with CSP headers
- [x] Alembic migrations
- [x] Environment variable configuration

---

## Pending Work

### Critical (Must complete before any customer)
- [ ] First-time sync wizard testing with real eSSL server
- [ ] Offline recovery end-to-end testing
- [ ] Multi-server verification with real devices
- [x] Stress testing (100K employees, 10M punches) — test harness created

### High (Operations)
- [x] Enterprise sync dashboard — health scores, throughput, alerts
- [x] Manual attendance reprocessing UI
- [x] Leave service double-prefix bug fix
- [x] Report file download/save functionality
- [x] Complete sync audit trail

### Medium (Enterprise Readiness)
- [x] Audit trail UI — sync-specific audit logging to audit_logs
- [x] Timezone & clock drift handling — server timezone-aware parsing + drift detection
- [x] Backend tests — stress, timezone, e2e pipeline tests added
- [ ] Frontend tests (0% coverage)
- [ ] CI/CD pipeline

### Low (Nice to Have)
- [ ] Holiday management
- [ ] Payroll export
- [ ] Push notifications
- [ ] Mobile app optimizations

---

## Known Bugs

| Bug | Severity | Location | Description | Status |
|-----|----------|----------|-------------|--------|
| ~~Leave double-prefix~~ | ~~High~~ | `leave_service.dart` | ~~URLs become `/api/v1/api/v1/leaves/apply`~~ | ✅ Fixed |
| ~~Leave balance wrong ID~~ | ~~High~~ | `leave_balance_screen.dart` | ~~Uses `user.id` instead of `employee.id`~~ | ✅ Fixed |
| ~~Report download no save~~ | ~~Medium~~ | `report_selection_screen.dart` | ~~Downloads bytes but never writes to disk~~ | ✅ Fixed |
| ~~Timezone blind UTC~~ | ~~High~~ | `essl_connector.py:1097` | ~~All punch times tagged as UTC regardless of device tz~~ | ✅ Fixed |
| Visitor pass fetch all | Low | `visitor_pass_screen.dart` | Fetches all passes then filters locally | Open |
| Dio logger in production | Low | `dio_client.dart` | PrettyDioLogger always active | Open |

---

## Design Decisions

### Why per-tenant eSSL servers?
Customers have multiple locations (HO, Factory, Warehouse) each with their own eBioserverNew instance. A single global config wouldn't work for enterprise deployments.

### Why bulk GetDeviceLogs instead of per-employee GetEmployeePunchLogs?
With 5,000 employees, per-employee approach = 5,000 SOAP calls per sync. Bulk approach = 12 calls (one per device). 400x reduction in API calls.

### Why sync cursors?
Instead of "download everything again", cursors enable "get logs after X". This makes incremental sync fast and prevents duplicate downloads.

### Why per-server dedup constraint instead of cross-server?
Two devices at different locations may legitimately record the same employee at the same time (e.g., HO and Factory). Cross-server dedup would incorrectly merge these. Instead, we use per-server dedup and a separate duplicate detection service.

### Why Fernet encryption for eSSL passwords?
Reversible symmetric encryption allows us to decrypt passwords when making SOAP calls, while storing them encrypted at rest in the database.

### Why attendance_raw_logs as intermediate table?
Strict pipeline: SOAP → raw_logs → Processor → attendance. This ensures attendance calculation NEVER touches eSSL directly, making it resilient to eSSL outages.

### Why conflict resolution policies?
When an employee or device is deleted in eSSL but exists locally, different customers want different behaviors. Some want to disable, some want to delete, some want to ignore.

---

## Configuration

### Environment Variables (.env)
```
# Database
DATABASE_URL=postgresql+asyncpg://apex:apex_secret@postgres:5432/apex_db
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=10

# Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/1
CELERY_RESULT_BACKEND=redis://redis:6379/2

# JWT
SECRET_KEY=change-this-to-a-random-secret-key-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
REFRESH_TOKEN_EXPIRE_DAYS=7

# Encryption (Fernet key for eSSL passwords)
ENCRYPTION_KEY=<generate with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())">

# CORS
CORS_ORIGINS=["http://localhost","http://localhost:8080"]
```

### Docker Services
| Service | Port | Purpose |
|---------|------|---------|
| postgres | 5433 | PostgreSQL database |
| redis | 6380 | Cache + Celery broker |
| backend | 8000 | FastAPI application |
| celery_worker | - | Background task worker |
| celery_beat | - | Periodic task scheduler |
| nginx | 80 | Reverse proxy + static files |

### Celery Schedules
| Task | Interval | Purpose |
|------|----------|---------|
| `sync_all_tenants_attendance` | 5 min | Sync punch logs from all eSSL servers |
| `sync_all_tenants_devices` | 60 min | Sync device status |
| `sync_all_tenants_employees` | Daily 2AM | Sync employee data |
| `process_all_unprocessed_attendance` | 5 min | Process raw logs → attendance |

### Redis Usage
- **DB 0**: General cache (eSSL device list, employee details)
- **DB 1**: Celery broker
- **DB 2**: Celery result backend
- **Rate limiting**: Lua script sliding window
- **Token revocation**: Refresh token blacklist

---

## Testing Status

### Completed
- [x] Manual API testing via PowerShell
- [x] Manual Flutter UI testing in browser
- [x] Docker deployment verification
- [x] Multi-server creation verification

### Pending
- [ ] Unit tests for backend services
- [ ] Integration tests for API endpoints
- [ ] Flutter widget tests
- [ ] End-to-end tests
- [ ] Stress tests (100K employees, 10M punches)
- [ ] Multi-server sync verification with real eSSL
- [ ] Offline recovery verification
- [ ] Cursor corruption recovery

---

## Next Development Session

### Priority 1: Manual Attendance Reprocessing
Create API and UI for reprocessing attendance without re-downloading from eSSL.

**Files to create/modify:**
- `backend/app/services/attendance_processor.py` — Add reprocess_by_date_range, reprocess_by_employee, reprocess_by_department
- `backend/app/api/v1/endpoints/essl_connector.py` — Add reprocess endpoints
- `frontend/lib/screens/settings/essl_reprocess_screen.dart` — New screen

### Priority 2: Fix Known Bugs
1. Fix leave_service.dart double-prefix bug
2. Fix leave_balance_screen.dart wrong ID
3. Fix report_selection_screen.dart file save

### Priority 3: Audit Trail
Add sync-specific logging to audit_logs table.

---

## Resume Instructions

When reading this file in a future session:
1. Read PROJECT_CONTEXT.md completely
2. Read PROJECT_STATUS.json for current state
3. Verify implementation against codebase
4. Continue from "Next Development Session" section
5. Never rebuild already completed functionality
6. Preserve existing architecture unless a defect is found
7. Update PROJECT_CONTEXT.md and PROJECT_STATUS.json before ending session
