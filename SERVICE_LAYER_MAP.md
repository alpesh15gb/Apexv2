# Service Layer Map — Apex HRMS

> **Generated**: 2026-06-28
> **Scope**: `backend/app/services/` (21 files, ~6,200 lines)
> **Status**: Read-only audit — no files modified

---

## 1. Service Inventory

### Core Services

| Service | File | Lines | Classes | Purpose |
|---------|------|-------|---------|---------|
| Tenant | `tenant.py` | 68 | `TenantService` | Multi-tenant CRUD, subscription plan management |
| User | `user.py` | 155 | `UserService` | User CRUD, role assignment, password hashing, login tracking |
| Notification | `notification.py` | 150 | `NotificationService` | Email/SMS/Push/In-app notifications, read tracking |
| WebSocket | `websocket_manager.py` | 99 | `ConnectionManager` | Real-time tenant-scoped WebSocket broadcasting |

### Corporate Services

| Service | File | Lines | Classes | Purpose |
|---------|------|-------|---------|---------|
| Employee | `employee.py` | 594 | `EmployeeService`, `DepartmentService`, `DesignationService`, `BranchService` | Employee/org-structure CRUD, bulk import (CSV/Excel), device sync |
| Attendance | `attendance.py` | 455 | `AttendanceService` | Punch processing, attendance calculation, shift-aware status, daily summary |
| Attendance Processor | `attendance_processor.py` | 413 | `AttendanceProcessor` | Raw eSSL log → attendance pipeline, deduplication, reprocessing |
| Leave | `leave.py` | 378 | `LeaveService` | Leave types, balances, apply/approve/reject/cancel workflow |
| Shift | `shift.py` | 194 | `ShiftService` | Shift CRUD, schedule assignment, employee shift resolution |
| Visitor | `visitor.py` | 199 | `VisitorService` | Visitor registration, pass management, check-in/out with eSSL validation |
| Device | `device.py` | 171 | `DeviceService` | Device CRUD, status tracking, health summary |
| Command | `command.py` | 159 | `CommandService` | Device command queue, execute via eSSL SOAP, status tracking |
| Report | `report.py` | 556 | `ReportService` | 12+ report types (daily/monthly/late/OT/absent/visitor/device/muster roll) in CSV/Excel/PDF |
| Dashboard | `dashboard.py` | 416 | `DashboardService` | Stats, heatmap, leave calendar, birthdays, anniversaries, trends, sync health |
| Access Control | `access_control.py` | 307 | `AccessControlService` | Zone/door CRUD, access grant/revoke/check, access logging |
| Duplicate Detector | `duplicate_detector.py` | 176 | `DuplicateDetector` | Cross-server punch duplicate detection and resolution |
| Sync Audit | `sync_audit.py` | 202 | `SyncAuditService` | Sync lifecycle event logging (started/completed/reprocess/recovery) |

### eSSL Integration Services

| Service | File | Lines | Classes | Purpose |
|---------|------|-------|---------|---------|
| eSSL SOAP | `essl_soap.py` | 670 | `ESSLSoapService` | Low-level SOAP 1.1 XML client with retry/circuit-breaker for eBioserverNew |
| eSSL Client | `essl_client.py` | 463 | `ESSLClient` | Higher-level wrapper: Redis caching, pagination, typed Pydantic models |
| eSSL Connector | `essl_connector.py` | 1271 | `EsslConnectorService` | Per-tenant connector: employee/device/attendance sync, cursors, conflict resolution, offline recovery, clock drift detection |
| eSSL Dashboard | `essl_dashboard.py` | 368 | `EsslDashboardService` | eSSL sync dashboard: health scores, throughput, alerts, enterprise overview |

### School Services

| Service | File | Lines | Classes | Purpose |
|---------|------|-------|---------|---------|
| *(none)* | — | — | — | All school logic lives directly in endpoint files |

---

## 2. Dependency Graph

```
                    ┌──────────────────┐
                    │   essl_soap.py   │  (lowest-level SOAP client)
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │  essl_client.py  │  (Redis cache + typed models)
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──────┐ ┌────▼───────┐ ┌────▼───────────────┐
    │ essl_connector │ │ command.py │ │ visitor.py          │
    │     .py        │ │            │ │ (SOAP validation)   │
    └───────┬────────┘ └────────────┘ └────────────────────┘
            │
    ┌───────┼──────────────────┐
    │       │                  │
    │  ┌────▼───────────┐  ┌───▼──────────────┐
    │  │attendance_     │  │ essl_dashboard   │
    │  │processor.py    │  │     .py          │
    │  └────┬───────────┘  └───┬──────────────┘
    │       │                  │
    │  ┌────▼───────────┐  ┌───▼──────────────┐
    │  │attendance.py   │  │duplicate_        │
    │  │(also feeds     │  │detector.py       │
    │  │ from devices)  │  └──────────────────┘
    │  └────────────────┘
    │
    └──► sync_audit.py (log all sync events)

    ┌──────────────┐
    │ websocket_   │◄──── dashboard.py, attendance.py, visitor.py
    │ manager.py   │      (broadcast events)
    └──────────────┘

    ┌──────────────┐
    │notification  │◄──── leave.py, attendance.py (send alerts)
    │    .py       │
    └──────────────┘

    ┌──────────────┐
    │ access_      │──► device.py, employee.py
    │ control.py   │
    └──────────────┘

    ┌──────────────┐
    │ report.py    │──► attendance.py, employee.py, device.py, visitor.py, shift.py
    └──────────────┘

    ┌──────────────┐
    │ dashboard.py │──► attendance.py, employee.py, device.py, visitor.py, leave.py
    └──────────────┘

    ┌──────────────┐
    │  leave.py    │──► employee.py (verify employee exists)
    └──────────────┘

    ┌──────────────┐
    │  shift.py    │──► employee.py (verify employee exists)
    └──────────────┘

    ┌──────────────┐
    │ employee.py  │──► device.py, command.py (sync to device)
    └──────────────┘
```

### Service → Model Dependencies

| Service | Models Used |
|---------|------------|
| `tenant.py` | `Tenant`, `SubscriptionPlan` |
| `user.py` | `User`, `Role` |
| `notification.py` | `Notification`, `User` |
| `websocket_manager.py` | *(none — in-memory only)* |
| `employee.py` | `Employee`, `Department`, `Designation`, `Branch`, `Device`, `DeviceCommand` |
| `attendance.py` | `Attendance`, `PunchLog`, `Employee`, `Shift`, `ShiftSchedule`, `LeaveRequest` |
| `attendance_processor.py` | `Attendance`, `AttendanceRawLog`, `Employee`, `Shift`, `ShiftSchedule` |
| `leave.py` | `LeaveType`, `LeaveBalance`, `LeaveRequest`, `Employee` |
| `shift.py` | `Shift`, `ShiftSchedule`, `Employee` |
| `visitor.py` | `Visitor`, `VisitorPass` |
| `device.py` | `Device`, `DeviceLog` |
| `command.py` | `DeviceCommand`, `Device` |
| `report.py` | `Attendance`, `Employee`, `Department`, `Device`, `VisitorPass`, `Shift`, `OTRegister` |
| `dashboard.py` | `Employee`, `Department`, `Device`, `Attendance`, `VisitorPass`, `LeaveRequest`, `AuditLog`, `EsslServer`, `EsslSyncHistory` |
| `access_control.py` | `AccessZone`, `Door`, `UserAccessLevel`, `AccessLog`, `Employee` |
| `duplicate_detector.py` | `AttendanceRawLog` |
| `sync_audit.py` | `AuditLog` |
| `essl_soap.py` | *(none — HTTP/XML only)* |
| `essl_client.py` | *(none — wraps essl_soap.py)* |
| `essl_connector.py` | `EsslServer`, `EsslSyncHistory`, `EsslSyncJob`, `EsslSyncError`, `EsslEmployeeMapping`, `EsslDeviceMapping`, `EsslSyncCursor`, `EsslLocation`, `Employee`, `Department`, `Designation`, `Branch`, `Device`, `AttendanceRawLog` |
| `essl_dashboard.py` | `EsslServer`, `EsslSyncHistory`, `EsslSyncError`, `EsslEmployeeMapping`, `EsslDeviceMapping`, `EsslSyncCursor`, `AttendanceRawLog` |

---

## 3. School Endpoints (No Service Layer)

The following school modules have **endpoint files only** — business logic is inline in the API handlers:

| Module | Endpoint File | Has Models | Needs Service |
|--------|--------------|------------|---------------|
| Student | `school/student.py` | Likely yes | `StudentService` |
| Admission | `school/admission.py` | Likely yes | `AdmissionService` |
| Academic Year | `school/academic_year.py` | Likely yes | `AcademicYearService` |
| Grade/Section | `school/grade_section.py` | Likely yes | `GradeSectionService` |
| Attendance (Student) | `school/student_attendance.py` | Likely yes | `StudentAttendanceService` |
| Fee | `school/fee.py` | Likely yes | `FeeService` |
| Examination | `school/examination.py` | Likely yes | `ExaminationService` |
| Timetable | `school/timetable.py` | Likely yes | `TimetableService` |
| Homework | `school/homework.py` | Likely yes | `HomeworkService` |
| Library | `school/library.py` | Likely yes | `LibraryService` |
| Transport | `school/transport.py` | Likely yes | `TransportService` |
| Hostel | `school/hostel.py` | Likely yes | `HostelService` |
| Medical | `school/medical.py` | Likely yes | `MedicalService` |
| Communication | `school/communication.py` | Likely yes | `CommunicationService` |
| Certificate | `school/certificate.py` | Likely yes | `CertificateService` |
| School Dashboard | `school/school_dashboard.py` | Likely yes | `SchoolDashboardService` |

---

## 4. Architecture Observations

### Strengths
- **Consistent pattern**: All services take `AsyncSession` in `__init__`, use tenant-scoped queries
- **Clean separation**: Services don't import from API layer; dependency flows one way
- **eSSL layering**: 4-tier architecture (SOAP → Client → Connector → Dashboard) is well-structured
- **Resilience**: Circuit breaker + retry on SOAP calls; offline recovery with cursor-based incremental sync
- **Multi-server safety**: eSSL connector handles cross-server employee/device deduplication

### Weaknesses
- **No `__init__.py` exports**: Services package has empty `__init__.py` — no public API surface
- **Inconsistent error handling**: Some services raise `HTTPException` (mixing HTTP concerns into service layer), others return error dicts
- **Duplicate shift-finding logic**: `_find_shift()` in `attendance_processor.py` nearly duplicates `get_employee_shift()` in `shift.py`
- **No service for auth**: Login/JWT logic lives in `api/v1/endpoints/auth.py` directly
- **No base service class**: Common patterns (pagination, tenant filtering, CRUD) are repeated across every service
- **`report.py` heavy imports**: reportlab + openpyxl imported at module level — slows startup even when reports aren't used

---

## 5. Recommendations

### High Priority
1. **Extract school services**: Create `backend/app/services/school/` with service classes for each school module (16 services needed). Follow the existing pattern: `__init__(db: AsyncSession)`, tenant-scoped queries, no HTTP concerns.

2. **Extract auth service**: Create `backend/app/services/auth.py` for login, token refresh, password reset — currently inline in endpoints.

3. **Unify error handling**: Services should return `Result` types or raise domain exceptions, not `HTTPException`. Let the API layer translate to HTTP status codes.

### Medium Priority
4. **Deduplicate shift resolution**: Extract a shared `ShiftResolver` utility used by both `attendance.py` and `attendance_processor.py`.

5. **Add `__init__.py` exports**: Expose service classes from the package for cleaner imports:
   ```python
   from app.services import TenantService, UserService, ...
   ```

6. **Consider a base service**: Extract common CRUD patterns into a generic `BaseService[T]` to reduce boilerplate.

### Low Priority
7. **Lazy-load report dependencies**: Import reportlab/openpyxl inside report methods, not at module level.

8. **Add service-level logging**: Only `notification.py`, `websocket_manager.py`, and eSSL services use structured logging. Add `structlog` to all services.

---

## 6. Statistics

| Metric | Value |
|--------|-------|
| Total service files | 20 (excluding `__init__.py`) |
| Total lines of service code | ~6,200 |
| Largest service | `essl_connector.py` (1,271 lines) |
| Smallest service | `tenant.py` (68 lines) |
| Services with HTTPException in service layer | 12/20 |
| Services using structlog | 7/20 |
| School modules needing services | 16 |
| Services with no external dependencies | 2 (`websocket_manager.py`, `tenant.py`) |
