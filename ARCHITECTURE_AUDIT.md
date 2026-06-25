# Architecture Audit Report

**Date**: 2026-06-25  
**Auditor**: Principal QA Architect  
**Scope**: All backend API endpoints, services, and models

---

## Executive Summary

The codebase has **102 inline SQL violations** across 6 endpoint files. The most critical offenders are `dashboard.py` (entirely inline SQL, no service layer) and `essl_connector.py` (dashboard endpoints with 50+ inline queries). These violations break the layer separation principle and make the code untestable, unmaintainable, and prone to bugs.

---

## Violation Report

### CRITICAL — No Service Layer (All SQL Inline)

| File | Endpoints | Inline SQL Count | Severity |
|------|-----------|-----------------|----------|
| `dashboard.py` | `/stats`, `/attendance-chart`, `/recent-activity` | 18 | CRITICAL |
| `essl_connector.py` | `/dashboard/sync-status`, `/dashboard/enterprise` | 52 | CRITICAL |

### HIGH — Partial Service Layer (Some SQL Inline)

| File | Endpoint | Violation | Severity |
|------|----------|-----------|----------|
| `attendance.py:98` | `list_punch_logs` | Direct PunchLog query | HIGH |
| `visitors.py:90` | `list_passes` | Direct VisitorPass query | HIGH |
| `visitors.py:119` | `visitor_history` | Direct VisitorPass query | HIGH |
| `auth.py:38` | `register` | Direct Tenant query | MEDIUM |
| `auth.py:108` | `login` | Direct User query | MEDIUM |
| `leaves.py:65` | `apply_leave` | Direct Employee query | MEDIUM |

---

## Detailed Findings

### 1. `dashboard.py` — CRITICAL

**All 3 endpoints have NO service layer.** Every query is inline:

```
/stats → 8 inline SQL queries (Employee, Attendance, VisitorPass, Device, LeaveRequest)
/attendance-chart → 1 complex aggregation query
/recent-activity → 1 AuditLog query
```

**Required Fix**: Create `DashboardService` class with methods:
- `get_stats(tenant_id, target_date) -> DashboardStats`
- `get_attendance_trend(tenant_id, days) -> List[AttendanceTrend]`
- `get_recent_activity(tenant_id, limit) -> List[RecentActivity]`

### 2. `essl_connector.py` — CRITICAL

**Dashboard endpoints contain 52 inline SQL queries:**

```
/dashboard/sync-status → ~25 inline queries (cursors, counts, sync history, errors)
/dashboard/enterprise → ~27 inline queries (health scores, throughput, lag calculations)
```

**Required Fix**: Create `EsslDashboardService` class with methods:
- `get_sync_dashboard(tenant_id) -> List[EsslSyncDashboardStatus]`
- `get_enterprise_dashboard(tenant_id, throughput_days) -> EnterpriseSyncDashboard`

### 3. `attendance.py:98` — HIGH

`list_punch_logs` endpoint has inline SQL for PunchLog querying.

**Required Fix**: Add `list_punch_logs()` method to `AttendanceService`.

### 4. `visitors.py:90,119` — HIGH

`list_passes` and `visitor_history` endpoints have inline SQL.

**Required Fix**: Add methods to `VisitorService`.

### 5. `auth.py:38,108` — MEDIUM

Registration and login have inline SQL. These are justified for auth flow complexity but should still be extracted.

### 6. `leaves.py:65` — MEDIUM

`apply_leave` queries Employee directly to validate the employee exists.

---

## Layer Separation Rules

### Correct Pattern
```
API Endpoint → Service → Repository/Model → Database
```

### Current Violation Pattern
```
API Endpoint → Database (inline SQL)
```

### API Endpoint Responsibilities (ONLY)
1. Validate request (Pydantic schemas)
2. Authorize (deps.py)
3. Call service method
4. Return response

### Service Responsibilities
1. Business logic
2. Data aggregation
3. Cross-model queries
4. Transaction management

---

## Remediation Priority

| Priority | File | Action |
|----------|------|--------|
| P0 | `dashboard.py` | Create `DashboardService`, move all queries |
| P0 | `essl_connector.py` | Create `EsslDashboardService`, move dashboard queries |
| P1 | `attendance.py` | Add `list_punch_logs` to `AttendanceService` |
| P1 | `visitors.py` | Add pass/history methods to `VisitorService` |
| P2 | `auth.py` | Extract registration/login logic to `AuthService` |
| P2 | `leaves.py` | Move employee lookup to `EmployeeService` |

---

## Verification Checklist

- [ ] No `select()` calls in any endpoint file
- [ ] No `func.count/sum/max` calls in any endpoint file
- [ ] No `db.execute()` calls in any endpoint file (except through service)
- [ ] All endpoints follow: validate → authorize → call service → return
- [ ] All services are injectable via FastAPI Depends
