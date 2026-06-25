# Bug Report

**Date**: 2026-06-25

---

## Fixed Bugs

### BUG-001: Leave Service Double-Prefix
- **Severity**: HIGH
- **File**: `frontend/lib/services/leave_service.dart`
- **Description**: URLs became `/api/v1/api/v1/leaves/apply` → 404
- **Status**: ✅ Fixed
- **Fix**: Used `ApiConstants.leaveApply` instead of `${ApiConstants.baseUrl}/leaves/apply`

### BUG-002: Leave Balance Wrong ID
- **Severity**: HIGH
- **File**: `frontend/lib/screens/leaves/leave_balance_screen.dart`
- **Description**: Used `user.id` instead of `employee.id` for leave balance API
- **Status**: ✅ Fixed
- **Fix**: Added `currentEmployeeProvider` to look up employee by user email

### BUG-003: Report Download No Save
- **Severity**: MEDIUM
- **File**: `frontend/lib/screens/reports/report_selection_screen.dart`
- **Description**: Downloaded bytes but never wrote to disk
- **Status**: ✅ Fixed
- **Fix**: Used `dart:html` blob/anchor for web download

### BUG-004: Timezone Blind UTC
- **Severity**: HIGH
- **File**: `backend/app/services/essl_connector.py:1097`
- **Description**: All punch times tagged as UTC regardless of device timezone
- **Status**: ✅ Fixed
- **Fix**: `_parse_datetime` now uses `server.timezone` for conversion

---

## Open Bugs

### BUG-005: Visitor Pass Fetch All
- **Severity**: LOW
- **File**: `frontend/lib/screens/visitors/visitor_pass_screen.dart`
- **Description**: Fetches all passes then filters locally
- **Status**: Open
- **Fix**: Refactor to server-side filtering (already done in backend)

### BUG-006: Dio Logger in Production
- **Severity**: LOW
- **File**: `frontend/lib/core/dio_client.dart`
- **Description**: PrettyDioLogger always active (leaks sensitive data)
- **Status**: Open
- **Fix**: Gate behind `kDebugMode`

---

## Architecture Violations (Fixed)

### VIOLATION-001: Dashboard Inline SQL
- **Severity**: CRITICAL
- **File**: `backend/app/api/v1/endpoints/dashboard.py`
- **Description**: All 3 endpoints had inline SQL, no service layer
- **Status**: ✅ Fixed
- **Fix**: Created `DashboardService` class

### VIOLATION-002: eSSL Dashboard Inline SQL
- **Severity**: CRITICAL
- **File**: `backend/app/api/v1/endpoints/essl_connector.py`
- **Description**: Dashboard endpoints had 52 inline SQL queries
- **Status**: ✅ Fixed
- **Fix**: Created `EsslDashboardService` class

### VIOLATION-003: Attendance Punch Logs Inline SQL
- **Severity**: HIGH
- **File**: `backend/app/api/v1/endpoints/attendance.py`
- **Description**: `list_punch_logs` had inline SQL
- **Status**: ✅ Fixed
- **Fix**: Added `list_punch_logs` to `AttendanceService`

### VIOLATION-004: Visitor Passes Inline SQL
- **Severity**: HIGH
- **File**: `backend/app/api/v1/endpoints/visitors.py`
- **Description**: `list_visitor_passes` had inline SQL
- **Status**: ✅ Fixed
- **Fix**: Added `list_passes` to `VisitorService`

---

## Test Coverage

| Module | Tests | Status |
|--------|-------|--------|
| Auth | 4 | ✅ |
| Employees | 3 | ✅ |
| Attendance | 1 | ✅ |
| Devices | 2 | ✅ |
| Shifts/Leaves | 4 | ✅ |
| Stress | 5 | ✅ |
| Timezone | 11 | ✅ |
| E2E Pipeline | 8 | ✅ |
| **Total** | **38** | — |
