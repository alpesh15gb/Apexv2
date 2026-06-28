# Apex HRMS API Module Map

> **Base URL**: `/api/v1` (configured via `API_V1_PREFIX`)
> **Framework**: FastAPI (Python) with async SQLAlchemy, Pydantic, RBAC, Feature Flags
> **Auth**: JWT Bearer tokens (access + refresh)
> **Total Endpoints**: 442
> **Last Updated**: 2026-06-28

---

## Table of Contents

1. [Core APIs](#core-apis) (69 endpoints)
2. [Corporate APIs](#corporate-apis) (235 endpoints)
3. [School APIs](#school-apis) (111 endpoints)
4. [Admin APIs](#admin-apis) (27 endpoints)

---

## Core APIs

### /auth — Authentication & Registration (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/auth.py`
**Router-level deps**: None (public + authenticated)

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| POST | /auth/register | — | — | Create new tenant + admin user |
| POST | /auth/login | — | — | Authenticate, return JWT tokens |
| POST | /auth/refresh | — | — | Refresh token pair |
| POST | /auth/logout | — | — | Revoke current tokens |
| GET | /auth/me | — | — | Get current user profile |
| PUT | /auth/me | — | — | Update current user profile |
| POST | /auth/change-password | — | — | Change password |
| POST | /auth/logout-all | — | — | Revoke all user tokens |

### /tenants — Tenant Management (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/tenants.py`
**Router-level deps**: `require_permissions("tenant.read")` + `get_current_superuser`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /tenants/ | tenant.read | — | List all tenants (superuser) |
| POST | /tenants/ | tenant.read | — | Create tenant (superuser) |
| GET | /tenants/{tenant_id} | tenant.read | — | Get tenant by ID |
| PUT | /tenants/{tenant_id} | tenant.read | — | Update tenant |
| DELETE | /tenants/{tenant_id} | tenant.read | — | Deactivate tenant |

### /dashboard — Dashboard Analytics (10 endpoints)
**Source**: `backend/app/api/v1/endpoints/dashboard.py`
**Router-level deps**: `require_permissions("dashboard.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /dashboard/stats | dashboard.read | — | Dashboard statistics |
| GET | /dashboard/attendance-heatmap | dashboard.read | — | Attendance heatmap (7-90 days) |
| GET | /dashboard/leave-calendar | dashboard.read | — | Leave calendar by year/month |
| GET | /dashboard/birthdays | dashboard.read | — | Upcoming birthdays |
| GET | /dashboard/anniversaries | dashboard.read | — | Work anniversaries |
| GET | /dashboard/department-distribution | dashboard.read | — | Department distribution |
| GET | /dashboard/monthly-trend | dashboard.read | — | Monthly attendance trend |
| GET | /dashboard/sync-health | dashboard.read | — | eSSL sync health status |
| GET | /dashboard/attendance-chart | dashboard.read | — | Attendance trend chart data |
| GET | /dashboard/recent-activity | dashboard.read | — | Recent activity feed |

### /notifications — Notification Center (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/notification_center.py` + `notifications.py`
**Router-level deps**: `require_permissions("notification.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /notifications/ | notification.read | — | List notifications (paginated, filterable) |
| PUT | /notifications/{notification_id}/read | notification.read | — | Mark single notification as read |
| POST | /notifications/read-all | notification.read | — | Mark all notifications as read |
| GET | /notifications/unread-count | notification.read | — | Get unread notification count |
| GET | /notifications/ | notification.read | — | List notifications (service-based) |
| GET | /notifications/unread-count | notification.read | — | Unread count (service-based) |
| PUT | /notifications/{notification_id}/read | notification.read | — | Mark as read (service-based) |

### /documents — Document Management (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/documents.py`
**Router-level deps**: `require_feature("documents")` + `require_permissions("document.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /documents/ | document.read | documents | List documents (filterable by employee/type) |
| POST | /documents/ | document.manage | documents | Create document |
| PUT | /documents/{doc_id} | document.manage | documents | Update document |
| DELETE | /documents/{doc_id} | document.manage | documents | Delete document |

### /settings — System Settings (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/settings_api.py`
**Router-level deps**: `require_permissions("settings.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /settings/ | settings.read | — | Get company settings |
| PUT | /settings/company | settings.read | — | Update company settings |

### /system — System Health & Monitoring (3 endpoints)
**Source**: `backend/app/api/v1/endpoints/system.py`
**Router-level deps**: `require_permissions("system.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /system/health | system.read | — | System health check |
| GET | /system/metrics | system.read | — | System metrics (employee/attendance/leave counts) |
| GET | /system/tenant-usage | system.read | — | Current tenant resource usage |

### /setup — Setup Wizard (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/setup.py`
**Router-level deps**: `require_permissions("setup.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /setup/progress | setup.read | — | Get setup wizard progress |
| POST | /setup/company | setup.read | — | Save company information |
| POST | /setup/branches | setup.read | — | Create branches |
| POST | /setup/departments | setup.read | — | Create departments |
| POST | /setup/designations | setup.read | — | Create designations |
| POST | /setup/shifts | setup.read | — | Create shifts |
| POST | /setup/leaves | setup.read | — | Create leave types |
| POST | /setup/attendance | setup.read | — | Save attendance settings |

### /data — Import & Export (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/import_export.py`
**Router-level deps**: `require_permissions("employee.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| POST | /data/import/employees | employee.create | — | Import employees from CSV/Excel |
| POST | /data/import/leave-balances | employee.manage | — | Import leave balances from CSV |
| GET | /data/export/employees | employee.read | — | Export employees to CSV |
| GET | /data/template/employees | — | — | Download employee import template |

### /ops — Operations & Branding (6 endpoints)
**Source**: `backend/app/api/v1/endpoints/operations.py`
**Router-level deps**: `require_permissions("operations.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /ops/jobs | operations.read | — | List background jobs |
| GET | /ops/jobs/{job_name}/status | operations.read | — | Get specific job status |
| GET | /ops/branding | operations.read | — | Get tenant branding settings |
| PUT | /ops/branding | operations.read | — | Update tenant branding settings |
| POST | /ops/backup | operations.read | — | Trigger manual backup |
| GET | /ops/backup/history | operations.read | — | List backup history |

### /ws/dashboard — WebSocket (1 endpoint)
**Source**: `backend/app/api/v1/endpoints/websocket.py`
**Router-level deps**: `require_permissions("dashboard.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| WebSocket | /ws/dashboard | dashboard.read | — | Real-time dashboard push updates (auth via query param token) |

---

## Corporate APIs

### /employees — Employee Management (19 endpoints)
**Source**: `backend/app/api/v1/endpoints/employees.py`
**Router-level deps**: `require_permissions("employee.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /employees/departments | employee.read | — | List departments |
| POST | /employees/departments | employee.create | — | Create department |
| PUT | /employees/departments/{department_id} | employee.update | — | Update department |
| DELETE | /employees/departments/{department_id} | employee.delete | — | Delete department |
| GET | /employees/designations | employee.read | — | List designations |
| POST | /employees/designations | employee.create | — | Create designation |
| PUT | /employees/designations/{designation_id} | employee.update | — | Update designation |
| DELETE | /employees/designations/{designation_id} | employee.delete | — | Delete designation |
| GET | /employees/branches | employee.read | — | List branches |
| POST | /employees/branches | employee.create | — | Create branch |
| PUT | /employees/branches/{branch_id} | employee.update | — | Update branch |
| DELETE | /employees/branches/{branch_id} | employee.delete | — | Delete branch |
| GET | /employees/ | employee.read | — | List employees (paginated, filterable) |
| POST | /employees/ | employee.create | — | Create employee |
| POST | /employees/bulk-import | employee.create | — | Bulk import employees from file |
| GET | /employees/{employee_id} | employee.read | — | Get employee details |
| PUT | /employees/{employee_id} | employee.update | — | Update employee |
| DELETE | /employees/{employee_id} | employee.delete | — | Delete employee |
| POST | /employees/{employee_id}/deactivate | employee.update | — | Deactivate employee |

### /employees — Employee Lifecycle (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/lifecycle.py`
**Router-level deps**: `require_permissions("employee.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /employees/{employee_id}/timeline | employee.read | — | Get complete employee timeline |
| POST | /employees/{employee_id}/promote | employee.manage | — | Promote employee |
| POST | /employees/{employee_id}/transfer | employee.manage | — | Transfer employee |
| POST | /employees/{employee_id}/confirm | employee.manage | — | Confirm from probation |
| POST | /employees/{employee_id}/resign | employee.manage | — | Record resignation |
| POST | /employees/{employee_id}/terminate | employee.manage | — | Terminate employee |
| POST | /employees/{employee_id}/reactivate | employee.manage | — | Reactivate terminated/resigned employee |
| POST | /employees/{employee_id}/salary-revision | employee.manage | — | Record salary revision |

### /attendance — Attendance Management (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/attendance.py`
**Router-level deps**: `require_permissions("attendance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /attendance/daily-summary | attendance.read | — | Daily attendance summary |
| GET | /attendance/employee/{employee_id} | attendance.read | — | Employee attendance summary |
| GET | /attendance/ | attendance.read | — | List attendance records (paginated, filterable) |
| POST | /attendance/ | attendance.manage | — | Manual mark attendance |
| POST | /attendance/process | attendance.manage | — | Process attendance for a date |
| PUT | /attendance/{attendance_id}/approve | attendance.manage | — | Approve attendance |
| GET | /attendance/punch-logs | attendance.read | — | List punch logs |

### /shifts — Shift Management (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/shifts.py`
**Router-level deps**: `require_feature("shift")` + `require_permissions("shift.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /shifts/ | shift.read | shift | List shifts |
| POST | /shifts/ | shift.manage | shift | Create shift |
| GET | /shifts/{shift_id} | shift.read | shift | Get shift details |
| PUT | /shifts/{shift_id} | shift.manage | shift | Update shift |
| DELETE | /shifts/{shift_id} | shift.manage | shift | Delete shift |
| POST | /shifts/assign | shift.manage | shift | Assign shift to employee |
| GET | /shifts/schedules/ | shift.read | shift | List shift schedules |

### /shift-groups — Shift Groups (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/shift_groups.py`
**Router-level deps**: `require_feature("shift")` + `require_permissions("shift.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /shift-groups/ | shift.read | shift | List shift groups |
| POST | /shift-groups/ | shift.read | shift | Create shift group |
| PUT | /shift-groups/{group_id} | shift.read | shift | Update shift group |
| DELETE | /shift-groups/{group_id} | shift.read | shift | Delete shift group |
| GET | /shift-groups/{group_id}/shifts | shift.read | shift | Get shifts in group |

### /shift-rosters — Shift Rosters (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/shift_rosters.py`
**Router-level deps**: `require_feature("shift")` + `require_permissions("shift.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /shift-rosters/ | shift.read | shift | List rosters |
| POST | /shift-rosters/ | shift.read | shift | Create roster |
| PUT | /shift-rosters/{roster_id} | shift.read | shift | Update roster |
| DELETE | /shift-rosters/{roster_id} | shift.read | shift | Delete roster |
| GET | /shift-rosters/{roster_id}/entries | shift.read | shift | Get roster entries |

### /department-shifts — Department Shifts (3 endpoints)
**Source**: `backend/app/api/v1/endpoints/department_shifts.py`
**Router-level deps**: `require_feature("shift")` + `require_permissions("shift.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /department-shifts/ | shift.read | shift | List department shifts |
| POST | /department-shifts/ | shift.read | shift | Create department shift |
| DELETE | /department-shifts/{ds_id} | shift.read | shift | Delete department shift |

### /leaves — Leave Management (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/leaves.py`
**Router-level deps**: `require_permissions("leave.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /leaves/types | leave.read | — | List leave types |
| POST | /leaves/types | leave.approve | — | Create leave type |
| GET | /leaves/balance/{employee_id} | leave.read | — | Get leave balance |
| POST | /leaves/apply | leave.approve | — | Apply for leave |
| GET | /leaves/requests | leave.read | — | List leave requests |
| PUT | /leaves/requests/{request_id}/approve | leave.approve | — | Approve leave |
| PUT | /leaves/requests/{request_id}/reject | leave.approve | — | Reject leave |
| PUT | /leaves/requests/{request_id}/cancel | leave.approve | — | Cancel leave |

### /payroll — Payroll & Salary (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/payroll.py`
**Router-level deps**: `require_feature("payroll")` + `require_permissions("payroll.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /payroll/salary-structure | payroll.read | payroll | List salary structures |
| POST | /payroll/salary-structure | payroll.manage | payroll | Create salary structure |
| PUT | /payroll/salary-structure/{ss_id} | payroll.manage | payroll | Update salary structure |
| GET | /payroll/payslips | payroll.read | payroll | List payslips |
| POST | /payroll/payslips/generate | payroll.manage | payroll | Generate payslips for month |
| PUT | /payroll/payslips/{payslip_id}/freeze | payroll.manage | payroll | Freeze payslip |
| GET | /payroll/loans | payroll.read | payroll | List loans |
| POST | /payroll/loans | payroll.manage | payroll | Create loan |

### /visitors — Visitor Management (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/visitors.py`
**Router-level deps**: `require_feature("visitor")` + `require_permissions("visitor.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /visitors/ | visitor.read | visitor | List visitors |
| POST | /visitors/ | visitor.manage | visitor | Register visitor |
| POST | /visitors/passes | visitor.manage | visitor | Create visitor pass |
| POST | /visitors/passes/{pass_id}/check-in | visitor.manage | visitor | Check in visitor |
| POST | /visitors/passes/{pass_id}/check-out | visitor.manage | visitor | Check out visitor |
| GET | /visitors/active | visitor.read | visitor | List active visitors |
| GET | /visitors/passes | visitor.read | visitor | List visitor passes |
| GET | /visitors/history | visitor.read | visitor | Visitor history |

### /access-control — Physical Access Control (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/access_control.py`
**Router-level deps**: `require_feature("access_control")` + `require_permissions("access_control.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /access-control/zones | access_control.read | access_control | List access zones |
| POST | /access-control/zones | access_control.read | access_control | Create access zone |
| GET | /access-control/doors | access_control.read | access_control | List doors |
| POST | /access-control/doors | access_control.read | access_control | Create door |
| POST | /access-control/grant | access_control.read | access_control | Grant access |
| DELETE | /access-control/grant/{access_level_id} | access_control.read | access_control | Revoke access |
| GET | /access-control/check | access_control.read | access_control | Check access for employee/door |
| GET | /access-control/logs | access_control.read | access_control | List access logs |

### /devices — Device Management (9 endpoints)
**Source**: `backend/app/api/v1/endpoints/devices.py`
**Router-level deps**: `require_feature("device")` + `require_permissions("device.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /devices/health | device.read | device | Device health summary |
| GET | /devices/ | device.read | device | List devices |
| POST | /devices/ | device.manage | device | Create device |
| GET | /devices/{device_id} | device.read | device | Get device details |
| PUT | /devices/{device_id} | device.manage | device | Update device |
| DELETE | /devices/{device_id} | device.manage | device | Delete device |
| GET | /devices/{device_id}/logs | device.read | device | Get device logs |
| POST | /devices/{device_id}/sync | device.manage | device | Trigger device sync |
| GET | /devices/{device_id}/live-status | device.read | device | Get device live status |

### /commands — Device Commands (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/commands.py`
**Router-level deps**: `require_permissions("device.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /commands/ | device.read | — | List device commands |
| POST | /commands/ | device.read | — | Create device command |
| POST | /commands/{command_id}/execute | device.read | — | Execute command |
| GET | /commands/{command_id} | device.read | — | Get command status |

### /essl — eSSL Biometric Connector (26 endpoints)
**Source**: `backend/app/api/v1/endpoints/essl_connector.py` + `essl_locations.py`
**Router-level deps**: `require_feature("biometric")` + `require_permissions("biometric.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| POST | /essl/ | biometric.read | biometric | Create eSSL server |
| GET | /essl/ | biometric.read | biometric | List eSSL servers |
| GET | /essl/{server_id} | biometric.read | biometric | Get eSSL server |
| PUT | /essl/{server_id} | biometric.read | biometric | Update eSSL server |
| DELETE | /essl/{server_id} | biometric.read | biometric | Delete eSSL server |
| POST | /essl/{server_id}/test | biometric.read | biometric | Test eSSL connection |
| POST | /essl/{server_id}/sync/employees | biometric.read | biometric | Manual employee sync |
| POST | /essl/{server_id}/sync/attendance | biometric.read | biometric | Manual attendance sync |
| POST | /essl/{server_id}/sync/devices | biometric.read | biometric | Manual device sync |
| POST | /essl/{server_id}/sync/initial | biometric.read | biometric | Initial attendance sync (date range) |
| POST | /essl/{server_id}/reprocess | biometric.read | biometric | Reprocess attendance records |
| POST | /essl/{server_id}/recover | biometric.read | biometric | Recover from offline period |
| GET | /essl/{server_id}/recovery-status | biometric.read | biometric | Get recovery status |
| GET | /essl/{server_id}/cursor-integrity | biometric.read | biometric | Validate cursor integrity |
| GET | /essl/{server_id}/clock-drift | biometric.read | biometric | Detect clock drift |
| POST | /essl/{server_id}/sync/{history_id}/pause | biometric.read | biometric | Pause running sync |
| POST | /essl/{server_id}/sync/{history_id}/resume | biometric.read | biometric | Resume paused sync |
| POST | /essl/{server_id}/sync/{history_id}/cancel | biometric.read | biometric | Cancel sync |
| GET | /essl/{server_id}/sync/{history_id}/progress | biometric.read | biometric | Get sync progress |
| GET | /essl/{server_id}/sync/history | biometric.read | biometric | Sync history |
| GET | /essl/{server_id}/sync/errors | biometric.read | biometric | Sync errors |
| GET | /essl/duplicates/stats | biometric.read | biometric | Duplicate statistics |
| GET | /essl/duplicates/cross-server | biometric.read | biometric | Find cross-server duplicates |
| POST | /essl/duplicates/resolve | biometric.read | biometric | Resolve duplicates |
| GET | /essl/dashboard/sync-status | biometric.read | biometric | eSSL sync dashboard |
| GET | /essl/dashboard/enterprise | biometric.read | biometric | Enterprise sync dashboard |
| GET | /essl/{server_id}/locations | biometric.read | biometric | List eSSL locations |
| POST | /essl/{server_id}/locations | biometric.read | biometric | Create eSSL location |
| PUT | /essl/{server_id}/locations/{location_id} | biometric.read | biometric | Update eSSL location |
| DELETE | /essl/{server_id}/locations/{location_id} | biometric.read | biometric | Delete eSSL location |

### /recruitment — Recruitment & ATS (21 endpoints)
**Source**: `backend/app/api/v1/endpoints/recruitment.py`
**Router-level deps**: `require_permissions("recruitment.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /recruitment/requisitions | recruitment.read | — | List job requisitions |
| POST | /recruitment/requisitions | recruitment.manage | — | Create requisition |
| PUT | /recruitment/requisitions/{req_id} | recruitment.manage | — | Update requisition |
| POST | /recruitment/requisitions/{req_id}/submit | recruitment.manage | — | Submit requisition for approval |
| POST | /recruitment/requisitions/{req_id}/approve | recruitment.manage | — | Approve requisition |
| GET | /recruitment/openings | recruitment.read | — | List job openings |
| POST | /recruitment/openings | recruitment.manage | — | Create job opening |
| PUT | /recruitment/openings/{opening_id} | recruitment.manage | — | Update job opening |
| POST | /recruitment/openings/{opening_id}/publish | recruitment.manage | — | Publish opening |
| POST | /recruitment/openings/{opening_id}/close | recruitment.manage | — | Close opening |
| GET | /recruitment/candidates | recruitment.read | — | List candidates |
| POST | /recruitment/candidates | recruitment.manage | — | Create candidate |
| PUT | /recruitment/candidates/{candidate_id} | recruitment.manage | — | Update candidate |
| PUT | /recruitment/candidates/{candidate_id}/stage | recruitment.manage | — | Move candidate stage |
| GET | /recruitment/interviews | recruitment.read | — | List interviews |
| POST | /recruitment/interviews | recruitment.manage | — | Create interview |
| PUT | /recruitment/interviews/{interview_id}/feedback | recruitment.manage | — | Submit interview feedback |
| GET | /recruitment/offers | recruitment.read | — | List offers |
| POST | /recruitment/offers | recruitment.manage | — | Create offer |
| PUT | /recruitment/offers/{offer_id}/accept | recruitment.manage | — | Accept offer |
| PUT | /recruitment/offers/{offer_id}/reject | recruitment.manage | — | Reject offer |
| GET | /recruitment/stats | recruitment.read | — | Recruitment dashboard stats |
| GET | /recruitment/pipeline | recruitment.read | — | Recruitment pipeline stages |

### /performance — Performance Management (16 endpoints)
**Source**: `backend/app/api/v1/endpoints/performance.py`
**Router-level deps**: `require_permissions("performance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /performance/cycles | performance.read | — | List review cycles |
| POST | /performance/cycles | performance.manage | — | Create review cycle |
| PUT | /performance/cycles/{cycle_id} | performance.manage | — | Update review cycle |
| POST | /performance/cycles/{cycle_id}/publish | performance.manage | — | Publish cycle |
| GET | /performance/goals | performance.read | — | List goals |
| POST | /performance/goals | performance.manage | — | Create goal |
| PUT | /performance/goals/{goal_id} | performance.manage | — | Update goal |
| PUT | /performance/goals/{goal_id}/progress | performance.manage | — | Update goal progress |
| POST | /performance/goals/{goal_id}/approve | performance.manage | — | Approve goal |
| GET | /performance/reviews | performance.read | — | List performance reviews |
| POST | /performance/reviews | performance.manage | — | Create review |
| PUT | /performance/reviews/{review_id}/submit | performance.manage | — | Submit review |
| GET | /performance/competencies | performance.read | — | List competencies |
| POST | /performance/competencies | performance.manage | — | Create competency |
| GET | /performance/recommendations | performance.read | — | List recommendations |
| POST | /performance/recommendations | performance.manage | — | Create recommendation |
| PUT | /performance/recommendations/{rec_id}/approve | performance.manage | — | Approve recommendation |
| GET | /performance/stats | performance.read | — | Performance dashboard stats |

### /assets — Asset Management (9 endpoints)
**Source**: `backend/app/api/v1/endpoints/assets.py`
**Router-level deps**: `require_feature("assets")` + `require_permissions("asset.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /assets/ | asset.read | assets | List assets |
| POST | /assets/ | asset.read | assets | Create asset |
| GET | /assets/{asset_id} | asset.read | assets | Get asset details |
| PUT | /assets/{asset_id} | asset.read | assets | Update asset |
| POST | /assets/{asset_id}/assign | asset.read | assets | Assign asset to employee |
| POST | /assets/{asset_id}/return | asset.read | assets | Return asset |
| POST | /assets/{asset_id}/maintenance | asset.read | assets | Send to maintenance |
| GET | /assets/stats | asset.read | assets | Asset statistics |

### /reports — Report Generation (14 endpoints)
**Source**: `backend/app/api/v1/endpoints/reports.py`
**Router-level deps**: `require_feature("reports")` + `require_permissions("report.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /reports/attendance/daily | report.read | reports | Daily attendance report (PDF/Excel/CSV) |
| GET | /reports/attendance/monthly | report.read | reports | Monthly attendance report |
| GET | /reports/attendance/employee/{employee_id} | report.read | reports | Employee attendance report |
| GET | /reports/attendance/late | report.read | reports | Late report |
| GET | /reports/attendance/overtime | report.read | reports | Overtime report |
| GET | /reports/attendance/absent | report.read | reports | Absent report |
| GET | /reports/visitors | report.read | reports | Visitor report |
| GET | /reports/devices | report.read | reports | Device status report |
| GET | /reports/attendance/early-going | report.read | reports | Early going report |
| GET | /reports/attendance/missed-punch | report.read | reports | Missed punch report |
| GET | /reports/attendance/department-summary | report.read | reports | Department summary report |
| GET | /reports/attendance/ot-summary | report.read | reports | OT summary report |
| GET | /reports/attendance/muster-roll | report.read | reports | Muster roll report |
| POST | /reports/attendance/recalculate | report.read | reports | Recalculate attendance |

### /finance — Expense & Benefits (12 endpoints)
**Source**: `backend/app/api/v1/endpoints/expense_benefits.py`
**Router-level deps**: `require_feature("expense")` + `require_permissions("expense.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /finance/expense-categories | expense.read | expense | List expense categories |
| POST | /finance/expense-categories | expense.read | expense | Create expense category |
| GET | /finance/expense-claims | expense.read | expense | List expense claims |
| POST | /finance/expense-claims | expense.read | expense | Create expense claim |
| PUT | /finance/expense-claims/{claim_id} | expense.read | expense | Update expense claim |
| GET | /finance/tax-declarations | expense.read | expense | List tax declarations |
| POST | /finance/tax-declarations | expense.read | expense | Create tax declaration |
| PUT | /finance/tax-declarations/{td_id} | expense.read | expense | Update tax declaration |
| GET | /finance/benefits | expense.read | expense | List benefits |
| POST | /finance/benefits | expense.read | expense | Create benefit |
| GET | /finance/employee-benefits | expense.read | expense | List employee benefits |
| POST | /finance/employee-benefits | expense.read | expense | Assign benefit to employee |

### /hr — HR Operations (16 endpoints)
**Source**: `backend/app/api/v1/endpoints/hr_ops.py`
**Router-level deps**: `require_permissions("hr.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /hr/assets | hr.read | — | List company assets |
| POST | /hr/assets | hr.read | — | Create company asset |
| PUT | /hr/assets/{asset_id} | hr.read | — | Update company asset |
| DELETE | /hr/assets/{asset_id} | hr.read | — | Delete company asset |
| GET | /hr/travel | hr.read | — | List travel requests |
| POST | /hr/travel | hr.read | — | Create travel request |
| PUT | /hr/travel/{tr_id} | hr.read | — | Update travel request |
| GET | /hr/announcements | hr.read | — | List announcements |
| POST | /hr/announcements | hr.read | — | Create announcement |
| DELETE | /hr/announcements/{ann_id} | hr.read | — | Delete announcement |
| GET | /hr/polls | hr.read | — | List polls |
| POST | /hr/polls | hr.read | — | Create poll |
| POST | /hr/polls/{poll_id}/vote | hr.read | — | Vote in poll |
| GET | /hr/notification-templates | hr.read | — | List notification templates |
| POST | /hr/notification-templates | hr.read | — | Create notification template |
| PUT | /hr/notification-templates/{tmpl_id} | hr.read | — | Update notification template |

### /ess — Employee Self-Service (14 endpoints)
**Source**: `backend/app/api/v1/endpoints/ess.py`
**Router-level deps**: `require_feature("ess")` + `require_permissions("ess.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /ess/dashboard | ess.read | ess | ESS dashboard summary |
| GET | /ess/attendance | ess.read | ess | My attendance records |
| POST | /ess/attendance/clock-in | ess.read | ess | Clock in |
| POST | /ess/attendance/clock-out | ess.read | ess | Clock out |
| GET | /ess/leaves | ess.read | ess | My leave requests |
| GET | /ess/leaves/balance | ess.read | ess | My leave balance |
| GET | /ess/payslips | ess.read | ess | My payslips |
| GET | /ess/documents | ess.read | ess | My documents |
| GET | /ess/profile | ess.read | ess | My profile |
| PUT | /ess/profile | ess.read | ess | Update my profile |
| GET | /ess/announcements | ess.read | ess | Company announcements |
| GET | /ess/notifications | ess.read | ess | My notifications |
| POST | /ess/change-password | ess.read | ess | Change my password |

### /holidays — Holiday Management (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/holidays.py`
**Router-level deps**: `require_permissions("holiday.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /holidays/ | holiday.read | — | List holidays |
| POST | /holidays/ | holiday.manage | — | Create holiday |
| PUT | /holidays/{holiday_id} | holiday.manage | — | Update holiday |
| DELETE | /holidays/{holiday_id} | holiday.manage | — | Delete holiday |

### /categories — Employee Categories (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/categories.py`
**Router-level deps**: `require_permissions("category.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /categories/ | category.read | — | List categories |
| POST | /categories/ | category.manage | — | Create category |
| PUT | /categories/{category_id} | category.manage | — | Update category |
| DELETE | /categories/{category_id} | category.manage | — | Delete category |

### /tenant-settings — Tenant Settings (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/tenant_settings.py`
**Router-level deps**: `require_permissions("settings.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /tenant-settings/ | settings.read | — | Get tenant settings |
| PUT | /tenant-settings/ | settings.read | — | Update tenant settings |

### /work-codes — Work Codes (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/work_codes.py`
**Router-level deps**: `require_permissions("attendance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /work-codes/ | attendance.read | — | List work codes |
| POST | /work-codes/ | attendance.read | — | Create work code |
| PUT | /work-codes/{wc_id} | attendance.read | — | Update work code |
| DELETE | /work-codes/{wc_id} | attendance.read | — | Delete work code |

### /outdoor-duties — Outdoor Duties (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/outdoor_duties.py`
**Router-level deps**: `require_feature("outdoor_duty")` + `require_permissions("attendance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /outdoor-duties/ | attendance.read | outdoor_duty | List outdoor duties |
| POST | /outdoor-duties/ | attendance.read | outdoor_duty | Create outdoor duty |
| PUT | /outdoor-duties/{od_id} | attendance.read | outdoor_duty | Update outdoor duty |
| DELETE | /outdoor-duties/{od_id} | attendance.read | outdoor_duty | Delete outdoor duty |

### /ot-register — Overtime Register (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/ot_register.py`
**Router-level deps**: `require_feature("overtime")` + `require_permissions("attendance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /ot-register/ | attendance.read | overtime | List OT records |
| POST | /ot-register/ | attendance.read | overtime | Create OT record |
| PUT | /ot-register/{ot_id} | attendance.read | overtime | Update OT record |
| DELETE | /ot-register/{ot_id} | attendance.read | overtime | Delete OT record |

### /timeline — Employee Timeline (3 endpoints)
**Source**: `backend/app/api/v1/endpoints/timeline.py`
**Router-level deps**: `require_permissions("employee.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /timeline/ | employee.read | — | List employee events |
| POST | /timeline/ | employee.read | — | Create event |
| DELETE | /timeline/{event_id} | employee.read | — | Delete event |

### /onboarding — Onboarding Tasks (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/onboarding.py`
**Router-level deps**: `require_feature("onboarding")` + `require_permissions("onboarding.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /onboarding/ | onboarding.read | onboarding | List onboarding tasks |
| POST | /onboarding/ | onboarding.read | onboarding | Create onboarding task |
| PUT | /onboarding/{task_id} | onboarding.read | onboarding | Update onboarding task |
| DELETE | /onboarding/{task_id} | onboarding.read | onboarding | Delete onboarding task |

### /exit-requests — Exit Management (3 endpoints)
**Source**: `backend/app/api/v1/endpoints/exit_requests.py`
**Router-level deps**: `require_feature("exit_management")` + `require_permissions("exit.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /exit-requests/ | exit.read | exit_management | List exit requests |
| POST | /exit-requests/ | exit.read | exit_management | Create exit request |
| PUT | /exit-requests/{req_id} | exit.read | exit_management | Update exit request |

---

## School APIs

### /school/academic-years — Academic Year Management (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/academic_year.py`
**Router-level deps**: `require_feature("academic_year")` + `require_permissions("school.settings")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/academic-years/ | school.settings | academic_year | List academic years |
| POST | /school/academic-years/ | school.settings | academic_year | Create academic year |
| PUT | /school/academic-years/{year_id} | school.settings | academic_year | Update academic year |
| POST | /school/academic-years/{year_id}/set-current | school.settings | academic_year | Set current academic year |
| GET | /school/academic-years/{year_id}/terms | school.settings | academic_year | List terms |
| POST | /school/academic-years/{year_id}/terms | school.settings | academic_year | Create term |
| GET | /school/academic-years/{year_id}/holidays | school.settings | academic_year | List holidays |
| POST | /school/academic-years/{year_id}/holidays | school.settings | academic_year | Create holiday |

### /school — Grades, Sections & Subjects (13 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/grade_section.py`
**Router-level deps**: `require_feature("class_management"/"subject_management")` + `require_permissions("school.settings")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/grades | school.settings | class_management | List grades |
| POST | /school/grades | school.settings | class_management | Create grade |
| PUT | /school/grades/{grade_id} | school.settings | class_management | Update grade |
| GET | /school/grades/{grade_id}/sections | school.settings | class_management | List sections for grade |
| POST | /school/grades/{grade_id}/sections | school.settings | class_management | Create section |
| GET | /school/sections/{section_id}/students | school.settings | class_management | List students in section |
| GET | /school/subjects | school.settings | subject_management | List subjects |
| POST | /school/subjects | school.settings | subject_management | Create subject |
| PUT | /school/subjects/{subject_id} | school.settings | subject_management | Update subject |
| GET | /school/grades/{grade_id}/subjects | school.settings | subject_management | List grade subjects |
| POST | /school/grades/{grade_id}/subjects | school.settings | subject_management | Assign subjects to grade |
| GET | /school/teacher-allocations | school.settings | class_management | List teacher allocations |
| POST | /school/teacher-allocations | school.settings | class_management | Create teacher allocation |

### /school/students — Student Management (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/student.py`
**Router-level deps**: `require_feature("student_management")` + `require_permissions("student.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/students/ | student.read | student_management | List students |
| POST | /school/students/ | student.read | student_management | Create student |
| GET | /school/students/{student_id} | student.read | student_management | Get student details |
| PUT | /school/students/{student_id} | student.read | student_management | Update student |
| POST | /school/students/{student_id}/guardians | student.read | student_management | Add guardian |
| GET | /school/students/{student_id}/guardians | student.read | student_management | List guardians |
| POST | /school/students/{student_id}/promote | student.read | student_management | Promote student |

### /school/student-attendance — Student Attendance (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/student_attendance.py`
**Router-level deps**: `require_feature("student_attendance")` + `require_permissions("student_attendance.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| POST | /school/student-attendance/mark | student_attendance.read | student_attendance | Mark attendance |
| POST | /school/student-attendance/bulk-mark | student_attendance.read | student_attendance | Bulk mark attendance |
| GET | /school/student-attendance/ | student_attendance.read | student_attendance | List attendance records |
| GET | /school/student-attendance/daily-summary | student_attendance.read | student_attendance | Daily summary |

### /school/homework — Homework & Assignments (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/homework.py`
**Router-level deps**: `require_feature("homework")` + `require_permissions("homework.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/homework/ | homework.read | homework | List homework |
| POST | /school/homework/ | homework.read | homework | Create homework |
| GET | /school/homework/{homework_id}/submissions | homework.read | homework | List submissions |
| POST | /school/homework/{homework_id}/submit | homework.read | homework | Submit homework |
| PUT | /school/homework/submissions/{submission_id}/review | homework.read | homework | Review submission |

### /school — Examinations (11 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/examination.py`
**Router-level deps**: `require_feature("examinations")` + `require_permissions("exam.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/exam-types | exam.read | examinations | List exam types |
| POST | /school/exam-types | exam.create | examinations | Create exam type |
| GET | /school/exams | exam.read | examinations | List exams |
| POST | /school/exams | exam.create | examinations | Create exam |
| GET | /school/exams/{exam_id}/schedules | exam.read | examinations | List exam schedules |
| POST | /school/exams/{exam_id}/schedules | exam.manage | examinations | Create exam schedule |
| POST | /school/marks/enter | exam.manage | examinations | Enter marks |
| POST | /school/marks/bulk-enter | exam.manage | examinations | Bulk enter marks |
| GET | /school/marks/{exam_schedule_id} | exam.read | examinations | Get marks |
| GET | /school/grading-scales | exam.read | examinations | List grading scales |
| POST | /school/grading-scales | exam.manage | examinations | Create grading scale |

### /school/fees — Fee Management (8 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/fee.py`
**Router-level deps**: `require_feature("fee_management")` + `require_permissions("fee.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/fees/categories | fee.read | fee_management | List fee categories |
| POST | /school/fees/categories | fee.read | fee_management | Create fee category |
| GET | /school/fees/structures | fee.read | fee_management | List fee structures |
| POST | /school/fees/structures | fee.read | fee_management | Create fee structure |
| POST | /school/fees/payments | fee.read | fee_management | Record payment |
| GET | /school/fees/payments | fee.read | fee_management | List payments |
| GET | /school/fees/students/{student_id} | fee.read | fee_management | Student fee summary |
| GET | /school/fees/reports/dues | fee.read | fee_management | Fee dues report |

### /school/dashboard — School Dashboard (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/school_dashboard.py`
**Router-level deps**: `require_feature("student_management")` + `require_permissions("student.read")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/dashboard/stats | student.read | student_management | School dashboard statistics |
| GET | /school/dashboard/attendance-overview | student.read | student_management | Attendance overview |

### /school/transport — Transport Management (6 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/transport.py`
**Router-level deps**: `require_feature("school_transport")` + `require_permissions("transport.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/transport/routes | transport.manage | school_transport | List routes |
| POST | /school/transport/routes | transport.manage | school_transport | Create route |
| GET | /school/transport/routes/{route_id}/stops | transport.manage | school_transport | List stops |
| POST | /school/transport/routes/{route_id}/stops | transport.manage | school_transport | Create stop |
| POST | /school/transport/students/assign | transport.manage | school_transport | Assign student |
| GET | /school/transport/students/{student_id} | transport.manage | school_transport | Get student transport |

### /school/hostel — Hostel Management (6 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/hostel.py`
**Router-level deps**: `require_feature("school_hostel")` + `require_permissions("hostel.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/hostel/ | hostel.manage | school_hostel | List hostels |
| POST | /school/hostel/ | hostel.manage | school_hostel | Create hostel |
| GET | /school/hostel/{hostel_id}/rooms | hostel.manage | school_hostel | List rooms |
| POST | /school/hostel/{hostel_id}/rooms | hostel.manage | school_hostel | Create room |
| POST | /school/hostel/allocations | hostel.manage | school_hostel | Allocate student |
| GET | /school/hostel/allocations | hostel.manage | school_hostel | List allocations |

### /school/library — Library Management (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/library.py`
**Router-level deps**: `require_feature("school_library")` + `require_permissions("library.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/library/books | library.manage | school_library | List books |
| POST | /school/library/books | library.manage | school_library | Add book |
| POST | /school/library/issue | library.manage | school_library | Issue book |
| POST | /school/library/return | library.manage | school_library | Return book |
| GET | /school/library/transactions | library.manage | school_library | List transactions |

### /school/timetable — Timetable Management (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/timetable.py`
**Router-level deps**: `require_feature("school_timetable")` + `require_permissions("school.settings")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/timetable/periods | school.settings | school_timetable | List periods |
| POST | /school/timetable/periods | school.settings | school_timetable | Create period |
| GET | /school/timetable/section/{section_id} | school.settings | school_timetable | Get section timetable |
| POST | /school/timetable/section/{section_id} | school.settings | school_timetable | Set section timetable |
| GET | /school/timetable/teacher/{employee_id} | school.settings | school_timetable | Get teacher timetable |
| POST | /school/timetable/substitutions | school.settings | school_timetable | Create substitution |
| GET | /school/timetable/substitutions | school.settings | school_timetable | List substitutions |

### /school/circulars — School Circulars (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/communication.py`
**Router-level deps**: `require_feature("school_circulars")` + `require_permissions("circular.publish")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/circulars/ | circular.publish | school_circulars | List circulars |
| POST | /school/circulars/ | circular.publish | school_circulars | Create circular |

### /school/events — School Events (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/communication.py`
**Router-level deps**: `require_feature("school_events")` + `require_permissions("event.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/events/ | event.manage | school_events | List events |
| POST | /school/events/ | event.manage | school_events | Create event |

### /school/health — Medical Records (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/medical.py`
**Router-level deps**: `require_feature("school_medical")` + `require_permissions("medical.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/health/students/{student_id} | medical.manage | school_medical | Get health records |
| POST | /school/health/ | medical.manage | school_medical | Create health record |

### /school/discipline — Discipline Management (3 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/medical.py`
**Router-level deps**: `require_feature("school_discipline")` + `require_permissions("discipline.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/discipline/ | discipline.manage | school_discipline | List incidents |
| POST | /school/discipline/ | discipline.manage | school_discipline | Create incident |
| PUT | /school/discipline/{incident_id}/resolve | discipline.manage | school_discipline | Resolve incident |

### /school/certificates — Certificate Management (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/certificate.py`
**Router-level deps**: `require_feature("school_certificates")` + `require_permissions("certificate.issue")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/certificates/templates | certificate.issue | school_certificates | List templates |
| POST | /school/certificates/templates | certificate.issue | school_certificates | Create template |
| POST | /school/certificates/issue | certificate.issue | school_certificates | Issue certificate |
| GET | /school/certificates/student/{student_id} | certificate.issue | school_certificates | List student certificates |

### /school/admissions — Admission Management (6 endpoints)
**Source**: `backend/app/api/v1/endpoints/school/admission.py`
**Router-level deps**: `require_feature("admissions")` + `require_permissions("admission.manage")`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /school/admissions/inquiries | admission.manage | admissions | List inquiries |
| POST | /school/admissions/inquiries | admission.manage | admissions | Create inquiry |
| GET | /school/admissions/applications | admission.manage | admissions | List applications |
| POST | /school/admissions/applications | admission.manage | admissions | Create application |
| PUT | /school/admissions/applications/{app_id}/review | admission.manage | admissions | Review application |
| POST | /school/admissions/applications/{app_id}/enroll | admission.manage | admissions | Enroll from application |

---

## Admin APIs

> All Admin endpoints require `get_current_superuser` (superuser JWT). No RBAC codenames or feature flags.

### /admin/auth — Super Admin Authentication (1 endpoint)
**Source**: `backend/app/api/v1/endpoints/admin/auth.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| POST | /admin/auth/login | superuser | — | Super admin login (rate-limited 5/min) |

### /admin/dashboard — Super Admin Dashboard (2 endpoints)
**Source**: `backend/app/api/v1/endpoints/admin/dashboard.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/dashboard/stats | superuser | — | Dashboard statistics |
| GET | /admin/dashboard/recent-activity | superuser | — | Recent audit log activity |

### /admin/tenants — Tenant Administration (11 endpoints)
**Source**: `backend/app/api/v1/endpoints/admin/tenants.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/tenants/ | superuser | — | List all tenants |
| GET | /admin/tenants/{tenant_id} | superuser | — | Get tenant details |
| POST | /admin/tenants/ | superuser | — | Create tenant |
| PUT | /admin/tenants/{tenant_id} | superuser | — | Update tenant |
| POST | /admin/tenants/{tenant_id}/suspend | superuser | — | Suspend tenant |
| POST | /admin/tenants/{tenant_id}/activate | superuser | — | Activate tenant |
| GET | /admin/tenants/{tenant_id}/limits | superuser | — | Get resource limits |
| PUT | /admin/tenants/{tenant_id}/limits | superuser | — | Update resource limits |
| GET | /admin/tenants/{tenant_id}/features | superuser | — | Get feature flags |
| PUT | /admin/tenants/{tenant_id}/features | superuser | — | Enable/disable features |
| GET | /admin/tenants/{tenant_id}/users | superuser | — | List tenant users |

### /admin/plans — Subscription Plans (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/admin/plans.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/plans/ | superuser | — | List plans |
| POST | /admin/plans/ | superuser | — | Create plan |
| PUT | /admin/plans/{plan_id} | superuser | — | Update plan |
| DELETE | /admin/plans/{plan_id} | superuser | — | Deactivate plan |

### /admin/features — Feature Flag Management (5 endpoints)
**Source**: `backend/app/api/v1/endpoints/admin/features.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/features/ | superuser | — | List feature flags |
| GET | /admin/features/categories | superuser | — | List feature categories |
| POST | /admin/features/ | superuser | — | Create feature flag |
| PUT | /admin/features/{feature_id} | superuser | — | Update feature flag |
| POST | /admin/features/seed | superuser | — | Seed default features |

### /admin/billing — Billing & Subscriptions (7 endpoints)
**Source**: `backend/app/api/v1/endpoints/billing.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/billing/subscriptions | superuser | — | List subscriptions |
| POST | /admin/billing/subscriptions | superuser | — | Create subscription |
| PUT | /admin/billing/subscriptions/{sub_id}/upgrade | superuser | — | Upgrade subscription |
| POST | /admin/billing/subscriptions/{sub_id}/renew | superuser | — | Renew subscription |
| POST | /admin/billing/subscriptions/{sub_id}/suspend | superuser | — | Suspend subscription |
| POST | /admin/billing/subscriptions/{sub_id}/cancel | superuser | — | Cancel subscription |
| POST | /admin/billing/check-expired | superuser | — | Check expired subscriptions |

### /admin/analytics — Platform Analytics (4 endpoints)
**Source**: `backend/app/api/v1/endpoints/analytics.py`

| Method | Path | Permission | Feature Flag | Description |
|--------|------|------------|--------------|-------------|
| GET | /admin/analytics/customer-success | superuser | — | Customer success overview |
| GET | /admin/analytics/customer-success/tenants | superuser | — | Tenant metrics listing |
| GET | /admin/analytics/overview | superuser | — | Platform-wide analytics |
| GET | /admin/analytics/tenant/{tenant_id} | superuser | — | Per-tenant analytics |

---

## Appendix

### Endpoint Count Summary

| Group | Endpoints |
|-------|-----------|
| **Core APIs** | 69 |
| — /auth | 8 |
| — /tenants | 5 |
| — /dashboard | 10 |
| — /notifications | 7 |
| — /documents | 4 |
| — /settings | 2 |
| — /system | 3 |
| — /setup | 8 |
| — /data | 4 |
| — /ops | 6 |
| — /ws/dashboard | 1 |
| **Corporate APIs** | 235 |
| — /employees (CRUD) | 19 |
| — /employees (lifecycle) | 8 |
| — /attendance | 7 |
| — /shifts | 7 |
| — /shift-groups | 5 |
| — /shift-rosters | 5 |
| — /department-shifts | 3 |
| — /leaves | 8 |
| — /payroll | 8 |
| — /visitors | 8 |
| — /access-control | 8 |
| — /devices | 9 |
| — /commands | 4 |
| — /essl | 26 |
| — /recruitment | 23 |
| — /performance | 18 |
| — /assets | 9 |
| — /reports | 14 |
| — /finance | 12 |
| — /hr | 16 |
| — /ess | 13 |
| — /holidays | 4 |
| — /categories | 4 |
| — /tenant-settings | 2 |
| — /work-codes | 4 |
| — /outdoor-duties | 4 |
| — /ot-register | 4 |
| — /timeline | 3 |
| — /onboarding | 4 |
| — /exit-requests | 3 |
| **School APIs** | 111 |
| — /school/academic-years | 8 |
| — /school (grades/sections/subjects) | 13 |
| — /school/students | 7 |
| — /school/student-attendance | 4 |
| — /school/homework | 5 |
| — /school (examinations) | 11 |
| — /school/fees | 8 |
| — /school/dashboard | 2 |
| — /school/transport | 6 |
| — /school/hostel | 6 |
| — /school/library | 5 |
| — /school/timetable | 7 |
| — /school/circulars | 2 |
| — /school/events | 2 |
| — /school/health | 2 |
| — /school/discipline | 3 |
| — /school/certificates | 4 |
| — /school/admissions | 6 |
| **Admin APIs** | 27 |
| — /admin/auth | 1 |
| — /admin/dashboard | 2 |
| — /admin/tenants | 11 |
| — /admin/plans | 4 |
| — /admin/features | 5 |
| — /admin/billing | 7 |
| — /admin/analytics | 4 |
| **TOTAL** | **442** |

### RBAC Permission Codenames

| Codename | Used By |
|----------|---------|
| employee.read / .create / .update / .delete / .manage | Employees, Lifecycle, Timeline, Data |
| attendance.read / .manage | Attendance, Work Codes, Outdoor Duties, OT Register |
| shift.read / .manage | Shifts, Shift Groups, Shift Rosters, Department Shifts |
| leave.read / .approve | Leaves |
| payroll.read / .manage | Payroll |
| device.read / .manage | Devices, Commands |
| biometric.read | eSSL Connector, eSSL Locations |
| visitor.read / .manage | Visitors |
| access_control.read | Access Control |
| report.read | Reports |
| dashboard.read | Dashboard, WebSocket |
| notification.read | Notifications |
| document.read / .manage | Documents |
| settings.read | Settings, Tenant Settings |
| system.read | System |
| setup.read | Setup Wizard |
| operations.read | Operations |
| recruitment.read / .manage | Recruitment |
| performance.read / .manage | Performance |
| asset.read | Assets |
| hr.read | HR Operations |
| ess.read | Employee Self-Service |
| holiday.read / .manage | Holidays |
| category.read / .manage | Categories |
| onboarding.read | Onboarding |
| exit.read | Exit Requests |
| expense.read | Expense & Benefits |
| billing.read | Billing |
| analytics.read | Analytics |
| tenant.read | Tenants |
| school.settings | School Academic Years, Grades, Timetable |
| student.read | School Students, Dashboard |
| student_attendance.read | School Student Attendance |
| homework.read | School Homework |
| exam.read / .create / .manage | School Examinations |
| fee.read | School Fees |
| transport.manage | School Transport |
| hostel.manage | School Hostel |
| library.manage | School Library |
| circular.publish | School Circulars |
| event.manage | School Events |
| medical.manage | School Medical |
| discipline.manage | School Discipline |
| certificate.issue | School Certificates |
| admission.manage | School Admissions |

### Feature Flags

| Code | Module | Category | Description |
|------|--------|----------|-------------|
| attendance | attendance | Core HR | Attendance module |
| leave | leave | Core HR | Leave management |
| shift | shift | Core HR | Shift management |
| overtime | attendance | Core HR | Overtime tracking |
| outdoor_duty | attendance | Core HR | Outdoor duty |
| payroll | payroll | Finance | Payroll processing |
| expense | finance | Finance | Expense claims |
| tax | finance | Finance | Tax declarations |
| benefits | finance | Finance | Benefits |
| loans | finance | Finance | Loans |
| travel | hr | HR Operations | Travel requests |
| assets | hr | HR Operations | Company assets |
| documents | hr | HR Operations | Document management |
| onboarding | hr | HR Operations | Onboarding |
| exit_management | hr | HR Operations | Exit management |
| announcements | hr | HR Operations | Announcements |
| polls | hr | HR Operations | Polls |
| visitor | visitor | Security | Visitor management |
| access_control | access | Security | Access control |
| biometric | essl | Integration | eSSL biometric integration |
| device | device | Integration | Device management |
| gps_attendance | attendance | Advanced | GPS attendance |
| face_recognition | attendance | Advanced | Face recognition |
| geo_fencing | attendance | Advanced | Geo fencing |
| reports | reports | Analytics | Report generation |
| analytics | reports | Analytics | Analytics |
| api_access | system | Platform | API access |
| webhooks | system | Platform | Webhooks |
| custom_branding | system | Platform | Custom branding |
| white_label | system | Platform | White label |
| ess | ess | Employee | Employee self-service |
| chat | communication | Communication | Chat |
| helpdesk | support | Communication | Helpdesk |
| notification_templates | notification | Communication | Notification templates |
| student_management | school | School Core | Student management |
| admissions | school | School Core | Admissions |
| academic_year | school | School Core | Academic year |
| class_management | school | School Core | Class management |
| subject_management | school | School Core | Subject management |
| school_timetable | school | Academics | Timetable |
| homework | school | Academics | Homework |
| school_assignments | school | Academics | Assignments |
| lesson_planning | school | Academics | Lesson planning |
| student_attendance | school | Academics | Student attendance |
| examinations | school | Assessment | Examinations |
| report_cards | school | Assessment | Report cards |
| grading_system | school | Assessment | Grading system |
| fee_management | school | Finance | Fee management |
| scholarships | school | Finance | Scholarships |
| school_transport | school | Operations | Transport |
| school_hostel | school | Operations | Hostel |
| school_library | school | Operations | Library |
| school_events | school | Communication | School events |
| school_circulars | school | Communication | Circulars |
| parent_portal | school | Communication | Parent portal |
| school_medical | school | Student Welfare | Medical records |
| school_discipline | school | Student Welfare | Discipline |
| school_certificates | school | Administration | Certificates |

### Middleware Stack

| Order | Middleware | File | Purpose |
|-------|-----------|------|---------|
| 1 | CORS | main.py | Cross-origin request handling |
| 2 | Audit | middleware/audit.py | Logs all mutating requests to audit_logs |
| 3 | RateLimit | middleware/rate_limit.py | Redis-backed per-user/IP rate limiting |
| 4 | Tenant | middleware/tenant.py | Extracts tenant from X-Tenant-ID header or JWT |
| 5 | SecurityHeaders | middleware/security_headers.py | CSP, HSTS, X-Frame-Options |

### Authorization Dependencies

| Dependency | File | Behavior |
|------------|------|----------|
| get_current_user | core/deps.py | Decodes JWT, checks revocation, loads user |
| get_current_active_user | core/deps.py | Adds is_active check |
| get_current_superuser | core/deps.py | Requires is_superuser=True |
| require_permissions(*codenames) | core/deps.py | RBAC gate — user must hold ALL codenames |
| require_feature(feature_code) | core/deps.py | Feature flag gate — tenant must have feature enabled |

> **Note**: Superusers bypass both `require_permissions` and `require_feature` checks.
