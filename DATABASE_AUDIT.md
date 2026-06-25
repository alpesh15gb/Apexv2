# Database Audit Report

**Date**: 2026-06-25  
**Auditor**: Principal Backend Engineer

---

## Schema Summary

| Table | Columns | Indexes | FKs | Unique Constraints |
|-------|---------|---------|-----|-------------------|
| tenants | 8 | PK | 0 | slug |
| users | 10 | PK, tenant_id | 1 | (tenant_id, email) |
| roles | 5 | PK, tenant_id | 1 | (tenant_id, name) |
| permissions | 4 | PK | 0 | codename |
| role_permissions | 3 | PK | 2 | (role_id, permission_id) |
| user_roles | 3 | PK | 2 | (user_id, role_id) |
| employees | 25 | PK, tenant_id, department_id, branch_id, shift_id | 4 | (tenant_id, employee_code), (tenant_id, email), (tenant_id, device_user_id) |
| departments | 6 | PK, tenant_id | 1 | (tenant_id, code) |
| designations | 6 | PK, tenant_id | 1 | (tenant_id, code) |
| branches | 8 | PK, tenant_id | 1 | (tenant_id, code) |
| attendances | 15 | PK, tenant_id, employee_id, shift_id | 3 | (tenant_id, employee_id, date) |
| punch_logs | 9 | PK, tenant_id, employee_id, device_id | 3 | — |
| attendance_raw_logs | 12 | PK, tenant_id, essl_server_id, processed | 3 | (essl_server_id, employee_code, punch_time, punch_type) |
| shifts | 12 | PK, tenant_id | 1 | (tenant_id, name) |
| shift_schedules | 8 | PK, tenant_id, employee_id, shift_id | 3 | — |
| leave_types | 7 | PK, tenant_id | 1 | (tenant_id, name) |
| leave_balances | 8 | PK, tenant_id, employee_id, leave_type_id | 3 | (employee_id, leave_type_id, year) |
| leave_requests | 12 | PK, tenant_id, employee_id, leave_type_id | 3 | — |
| devices | 12 | PK, tenant_id | 1 | (tenant_id, serial_number) |
| device_logs | 6 | PK, tenant_id, device_id | 2 | — |
| device_commands | 8 | PK, tenant_id, device_id | 2 | — |
| visitors | 12 | PK, tenant_id | 1 | — |
| visitor_passes | 12 | PK, tenant_id, visitor_id, host_employee_id | 3 | pass_number |
| access_zones | 6 | PK, tenant_id | 1 | (tenant_id, name) |
| doors | 7 | PK, tenant_id, zone_id, device_id | 3 | (tenant_id, name) |
| user_access_levels | 6 | PK, tenant_id, employee_id, zone_id | 3 | (employee_id, zone_id) |
| access_logs | 8 | PK, tenant_id, employee_id, door_id | 3 | — |
| notifications | 8 | PK, tenant_id, user_id | 2 | — |
| audit_logs | 10 | PK, tenant_id, user_id | 2 | — |
| essl_servers | 16 | PK, tenant_id | 1 | (tenant_id, name) |
| essl_sync_history | 20 | PK, tenant_id, essl_server_id | 2 | — |
| essl_sync_jobs | 10 | PK, tenant_id, essl_server_id | 2 | (essl_server_id, job_type) |
| essl_sync_errors | 9 | PK, tenant_id, sync_history_id | 2 | — |
| essl_sync_cursors | 7 | PK, tenant_id, essl_server_id | 2 | (essl_server_id, cursor_type) |
| essl_employee_mappings | 6 | PK, tenant_id, essl_server_id | 2 | (essl_server_id, employee_code) |
| essl_device_mappings | 6 | PK, tenant_id, essl_server_id | 2 | (essl_server_id, serial_number) |

---

## Index Analysis

### Explicitly Defined Indexes

| Table | Index | Columns | Type |
|-------|-------|---------|------|
| attendance_raw_logs | ix_raw_logs_unprocessed | tenant_id, processed | Composite |
| attendance_raw_logs | ix_raw_logs_dedup_check | tenant_id, employee_code, punch_time | Composite |

### Implicit Indexes (from FK and unique constraints)

All foreign keys and unique constraints create implicit indexes in PostgreSQL.

### Missing Indexes (Recommended)

| Table | Columns | Reason |
|-------|---------|--------|
| attendances | (tenant_id, date, status) | Dashboard stats query filters on all three |
| attendances | (tenant_id, employee_id, date) | Already has unique constraint — OK |
| punch_logs | (tenant_id, employee_id, punch_time) | Punch log listing queries |
| attendance_raw_logs | (essl_server_id, processed, punch_time) | Reprocess queries |
| essl_sync_history | (essl_server_id, status, started_at) | Dashboard sync history queries |
| essl_sync_history | (essl_server_id, started_at) | Throughput trend queries |
| audit_logs | (tenant_id, created_at) | Recent activity queries |
| essl_sync_errors | (tenant_id, occurred_at) | Error listing queries |

---

## Foreign Key Cascade Rules

| FK | On Delete | Assessment |
|----|-----------|------------|
| employees.tenant_id → tenants.id | CASCADE | ✅ Correct |
| attendances.employee_id → employees.id | CASCADE | ✅ Correct |
| punch_logs.employee_id → employees.id | CASCADE | ✅ Correct |
| attendance_raw_logs.essl_server_id → essl_servers.id | SET NULL | ✅ Correct (preserve raw data) |
| essl_sync_history.essl_server_id → essl_servers.id | CASCADE | ✅ Correct |
| essl_sync_errors.sync_history_id → essl_sync_history.id | CASCADE | ✅ Correct |
| leave_requests.approved_by → employees.id | SET NULL | ✅ Correct |

---

## Recommendations

1. **Add composite index** on `attendances(tenant_id, date, status)` for dashboard queries
2. **Add composite index** on `essl_sync_history(essl_server_id, status, started_at)` for sync dashboard
3. **Add index** on `audit_logs(tenant_id, created_at)` for recent activity
4. **Consider partitioning** `attendance_raw_logs` by date for large datasets (10M+ rows)
5. **Consider partitioning** `punch_logs` by date for historical data
