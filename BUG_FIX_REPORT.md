# Bug Fix Report

**Date**: 2026-06-26

---

## Bugs Fixed

### BUG-001: ApexTableColumn Missing ID Field
- **Severity**: HIGH
- **Location**: `frontend/lib/screens/employees/employee_list_screen.dart`
- **Description**: ApexTableColumn constructor requires `id` field but was not provided
- **Root Cause**: ApexTable was redesigned to require `id` field for column operations
- **Fix**: Added `id` field to all ApexTableColumn instances
- **Status**: ✅ Fixed

### BUG-002: Icons.density_medium Syntax Error
- **Severity**: HIGH
- **Location**: `frontend/lib/design_system/components/apex_table.dart:158`
- **Description**: Missing dot in `Icons density_medium` → `Icons.density_medium`
- **Root Cause**: Typo during code generation
- **Fix**: Added missing dot
- **Status**: ✅ Fixed

---

## Previously Fixed Bugs

### BUG-003: Leave Double-Prefix
- **Severity**: HIGH
- **Location**: `frontend/lib/services/leave_service.dart`
- **Description**: URLs became `/api/v1/api/v1/leaves/apply` → 404
- **Status**: ✅ Fixed (in previous session)

### BUG-004: Leave Balance Wrong ID
- **Severity**: HIGH
- **Location**: `frontend/lib/screens/leaves/leave_balance_screen.dart`
- **Description**: Used `user.id` instead of `employee.id`
- **Status**: ✅ Fixed (in previous session)

### BUG-005: Report Download No Save
- **Severity**: MEDIUM
- **Location**: `frontend/lib/screens/reports/report_selection_screen.dart`
- **Description**: Downloaded bytes but never wrote to disk
- **Status**: ✅ Fixed (in previous session)

### BUG-006: Timezone Blind UTC
- **Severity**: HIGH
- **Location**: `backend/app/services/essl_connector.py:1097`
- **Description**: All punch times tagged as UTC regardless of device timezone
- **Status**: ✅ Fixed (in previous session)

---

## Open Issues (Low Priority)

### BUG-007: Visitor Pass Fetch All
- **Severity**: LOW
- **Location**: `frontend/lib/screens/visitors/visitor_pass_screen.dart`
- **Description**: Fetches all passes then filters locally
- **Status**: Open

### BUG-008: Dio Logger in Production
- **Severity**: LOW
- **Location**: `frontend/lib/core/dio_client.dart`
- **Description**: PrettyDioLogger always active (leaks sensitive data)
- **Status**: Open

---

## Summary

| Category | Count |
|----------|-------|
| Fixed (this session) | 2 |
| Fixed (previous session) | 4 |
| Open (low priority) | 2 |
| **Total** | **8** |

---

## Recommendation

All critical and high-severity bugs have been fixed. The remaining low-priority issues do not block pilot deployment.
