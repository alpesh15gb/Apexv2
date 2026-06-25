# Information Architecture: Apex HRMS

**Date**: 2026-06-26

---

## Navigation Structure

### Primary Navigation (Sidebar)

```
Dashboard          → /dashboard
Employees          → /employees
  ├── Directory    → /employees
  ├── Departments  → /departments
  ├── Designations → /designations
  ├── Shifts       → /shifts
  └── Organization → /organization
Attendance         → /attendance
  ├── Today        → /attendance
  ├── Calendar     → /attendance/calendar
  ├── Timeline     → /attendance/timeline
  └── Exceptions   → /attendance/exceptions
Leave              → /leaves
  ├── Apply        → /leaves/apply
  ├── Requests     → /leaves/requests
  └── Balance      → /leaves/balance
Visitors           → /visitors
  ├── Register     → /visitors/register
  ├── Active       → /visitors/active
  └── Passes       → /visitors/passes
Devices            → /devices
  ├── List         → /devices
  ├── Health       → /devices/health
  └── Commands     → /devices/commands
Reports            → /reports
Administration     → /settings
```

---

## Route Map

| Route | Screen | Description |
|-------|--------|-------------|
| `/dashboard` | DashboardScreen | Executive overview |
| `/employees` | EmployeeListScreen | Employee directory |
| `/employees/:id` | EmployeeDetailScreen | Employee profile |
| `/employees/create` | EmployeeCreateScreen | Add employee |
| `/departments` | DepartmentScreen | Department management |
| `/shifts` | ShiftListScreen | Shift management |
| `/attendance` | AttendanceListScreen | Attendance workspace |
| `/attendance/detail` | AttendanceDetailScreen | Employee attendance |
| `/attendance/mark` | MarkAttendanceScreen | Manual mark |
| `/leaves` | LeaveRequestsScreen | Leave requests |
| `/leaves/apply` | LeaveApplyScreen | Apply for leave |
| `/leaves/balance` | LeaveBalanceScreen | Leave balance |
| `/visitors` | VisitorListScreen | Visitor management |
| `/visitors/register` | VisitorRegisterScreen | Register visitor |
| `/devices` | DeviceListScreen | Device operations |
| `/devices/:id` | DeviceDetailScreen | Device detail |
| `/reports` | ReportSelectionScreen | Report center |
| `/settings` | SettingsScreen | Administration |
| `/settings/essl` | EsslServerListScreen | eSSL servers |
| `/settings/essl/dashboard` | EsslDashboardScreen | Sync dashboard |

---

## Permission Model

### Roles
1. **Super Admin**: Full access
2. **HR Admin**: Employee, attendance, leave management
3. **Manager**: Team attendance, approvals
4. **Employee**: Self-service only

### Permission Matrix

| Feature | Super Admin | HR Admin | Manager | Employee |
|---------|-------------|----------|---------|----------|
| Dashboard | ✅ | ✅ | ✅ | ✅ |
| Employee CRUD | ✅ | ✅ | ❌ | ❌ |
| Attendance | ✅ | ✅ | ✅ (team) | ✅ (self) |
| Leave Approve | ✅ | ✅ | ✅ (team) | ❌ |
| Devices | ✅ | ❌ | ❌ | ❌ |
| Reports | ✅ | ✅ | ✅ | ❌ |
| Settings | ✅ | ❌ | ❌ | ❌ |

---

## Search Architecture

### Global Search (Ctrl+K)
- Employees (name, code, email)
- Attendance (date, status)
- Visitors (name, company)
- Devices (name, serial)
- Reports (name)
- Settings (pages)

### Module Search
- Employee list: name, code, email
- Attendance: employee, date, status
- Leave: employee, status, type
- Visitors: name, company, status
- Devices: name, serial, status

---

## Data Flow

### Employee Creation
```
User fills form → API validates → DB creates employee → 
eSSL sync triggered → Device mapping created → 
Attendance processing enabled
```

### Attendance Processing
```
eSSL sync → Raw logs stored → Processor runs → 
Attendance records created → Dashboard updated
```

### Leave Workflow
```
Employee applies → Manager approves → 
Leave balance updated → Attendance recalculated
```
