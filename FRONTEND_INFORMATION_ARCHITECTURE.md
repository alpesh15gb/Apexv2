# Frontend Information Architecture — Apex HRMS

## 1. Current Structure

All screens live under `frontend/lib/screens/` organized by feature subdirectories. Some root-level files sit outside any folder.

```
frontend/lib/screens/
├── access_control/
│   ├── access_logs_screen.dart
│   ├── door_list_screen.dart
│   └── zone_list_screen.dart
├── admin/
│   ├── admin_analytics_screen.dart
│   ├── admin_dashboard_screen.dart
│   ├── admin_feature_screen.dart
│   ├── admin_login_screen.dart
│   ├── admin_plan_screen.dart
│   ├── admin_tenant_detail_screen.dart
│   └── admin_tenant_list_screen.dart
├── assets/
│   └── asset_dashboard_screen.dart
├── attendance/
│   ├── attendance_calendar_screen.dart
│   ├── attendance_correction_screen.dart
│   ├── attendance_dashboard_screen.dart
│   ├── attendance_list_screen.dart
│   ├── attendance_log_screen.dart
│   ├── attendance_policy_screen.dart
│   ├── attendance_report_screen.dart
│   └── attendance_summary_screen.dart
├── commands/
│   └── command_center_screen.dart
├── dashboard/
│   └── dashboard_screen.dart
├── devices/
│   ├── device_detail_screen.dart
│   ├── device_health_screen.dart
│   └── device_list_screen.dart
├── employees/
│   ├── bulk_employee_upload_screen.dart
│   ├── create_employee_screen.dart
│   ├── department_screen.dart
│   ├── designation_screen.dart
│   ├── document_type_screen.dart
│   ├── employee_detail_screen.dart
│   ├── employee_list_screen.dart
│   ├── employee_profile_screen.dart
│   └── organization_screen.dart
├── ess/
│   ├── ess_attendance_calendar_screen.dart
│   ├── ess_attendance_screen.dart
│   ├── ess_dashboard_screen.dart
│   ├── ess_leave_screen.dart
│   └── ess_profile_screen.dart
├── finance/
│   └── expense_screen.dart
├── holidays/
│   └── holiday_calendar_screen.dart
├── hr/
│   ├── announcement_screen.dart
│   ├── asset_screen.dart
│   ├── document_screen.dart
│   ├── exit_request_screen.dart
│   └── travel_screen.dart
├── leaves/
│   ├── leave_apply_screen.dart
│   ├── leave_balance_screen.dart
│   ├── leave_calendar_screen.dart
│   ├── leave_dashboard_screen.dart
│   ├── leave_requests_screen.dart
│   └── leave_types_screen.dart
├── notifications/
│   └── notification_list_screen.dart
├── payroll/
│   ├── loans_screen.dart
│   ├── payroll_dashboard_screen.dart
│   ├── payroll_screen.dart
│   └── salary_structures_screen.dart
├── performance/
│   ├── goals_screen.dart
│   └── performance_dashboard_screen.dart
├── recruitment/
│   ├── candidates_screen.dart
│   ├── interviews_screen.dart
│   └── recruitment_dashboard_screen.dart
├── reports/
│   └── report_selection_screen.dart
├── school/
│   ├── academic_year_screen.dart
│   ├── admission_screen.dart
│   ├── attendance_mark_screen.dart
│   ├── exam_list_screen.dart
│   ├── fee_collection_screen.dart
│   ├── grade_section_screen.dart
│   ├── homework_screen.dart
│   ├── hostel_screen.dart
│   ├── library_screen.dart
│   ├── school_dashboard_screen.dart
│   ├── student_detail_screen.dart
│   ├── student_list_screen.dart
│   ├── timetable_screen.dart
│   └── transport_screen.dart
├── settings/
│   ├── category_screen.dart
│   ├── essl_dashboard_screen.dart
│   ├── essl_initial_sync_screen.dart
│   ├── essl_locations_screen.dart
│   ├── essl_reprocess_screen.dart
│   ├── essl_server_form_screen.dart
│   ├── essl_server_list_screen.dart
│   ├── essl_sync_history_screen.dart
│   ├── settings_screen.dart
│   ├── tenant_settings_screen.dart
│   └── work_code_screen.dart
├── setup/
│   └── setup_wizard_screen.dart
├── shifts/
│   ├── department_shift_screen.dart
│   ├── shift_assign_screen.dart
│   ├── shift_create_screen.dart
│   ├── shift_group_screen.dart
│   ├── shift_list_screen.dart
│   ├── shift_management_screen.dart
│   └── shift_roster_screen.dart
├── system/
│   ├── health_screen.dart
│   ├── notification_center_screen.dart
│   └── settings_screen.dart
├── visitors/
│   ├── active_visitors_screen.dart
│   ├── visitor_list_screen.dart
│   ├── visitor_pass_screen.dart
│   └── visitor_register_screen.dart
├── login_screen.dart          (root-level)
├── main_shell.dart            (root-level)
├── register_screen.dart       (root-level)
└── splash_screen.dart         (root-level)
```

**Total: 109 screen files across 24 subdirectories + 4 root files.**

---

## 2. Screen Classification

### Core / Shared (8 files)

Screens used by all roles — auth, app shell, global dashboard, notifications, reports, setup.

| File | Class | Purpose |
|------|-------|---------|
| `splash_screen.dart` | `SplashScreen` | App launch / loading screen |
| `login_screen.dart` | `LoginScreen` | Primary login form |
| `register_screen.dart` | `RegisterScreen` | New account registration |
| `main_shell.dart` | `MainShell` | App scaffold with sidebar/bottom nav, role-based menu |
| `dashboard/dashboard_screen.dart` | `DashboardScreen` | Role-adaptive home dashboard |
| `notifications/notification_list_screen.dart` | `NotificationListScreen` | In-app notification list |
| `reports/report_selection_screen.dart` | `ReportSelectionScreen` | Report category picker |
| `setup/setup_wizard_screen.dart` | `SetupWizardScreen` | First-time org setup wizard |

### Corporate / HRMS (77 files)

All HR/attendance/payroll/shift/recruitment/device/settings screens for corporate tenants.

| Subgroup | Files | Count |
|----------|-------|-------|
| Employees | `employee_list_screen`, `employee_detail_screen`, `employee_profile_screen`, `create_employee_screen`, `bulk_employee_upload_screen`, `department_screen`, `designation_screen`, `organization_screen`, `document_type_screen` | 9 |
| Attendance | `attendance_dashboard_screen`, `attendance_list_screen`, `attendance_log_screen`, `attendance_summary_screen`, `attendance_calendar_screen`, `attendance_correction_screen`, `attendance_report_screen`, `attendance_policy_screen` | 8 |
| Leaves | `leave_dashboard_screen`, `leave_requests_screen`, `leave_apply_screen`, `leave_balance_screen`, `leave_types_screen`, `leave_calendar_screen` | 6 |
| Payroll | `payroll_dashboard_screen`, `payroll_screen`, `salary_structures_screen`, `loans_screen` | 4 |
| Shifts | `shift_management_screen`, `shift_list_screen`, `shift_create_screen`, `shift_group_screen`, `shift_roster_screen`, `shift_assign_screen`, `department_shift_screen` | 7 |
| Holidays | `holiday_calendar_screen` | 1 |
| Recruitment | `recruitment_dashboard_screen`, `candidates_screen`, `interviews_screen` | 3 |
| Assets | `asset_dashboard_screen` | 1 |
| Devices / Biometric | `device_list_screen`, `device_detail_screen`, `device_health_screen` | 3 |
| eSSL Integration | `essl_server_list_screen`, `essl_server_form_screen`, `essl_locations_screen`, `essl_dashboard_screen`, `essl_sync_history_screen`, `essl_initial_sync_screen`, `essl_reprocess_screen` | 7 |
| Settings | `settings_screen`, `tenant_settings_screen`, `category_screen`, `work_code_screen` | 4 |
| HR Misc | `announcement_screen`, `document_screen`, `asset_screen`, `exit_request_screen`, `travel_screen` | 5 |
| ESS (Self-Service) | `ess_dashboard_screen`, `ess_attendance_screen`, `ess_attendance_calendar_screen`, `ess_leave_screen`, `ess_profile_screen` | 5 |
| Visitors | `visitor_list_screen`, `visitor_register_screen`, `visitor_pass_screen`, `active_visitors_screen` | 4 |
| Finance | `expense_screen` | 1 |
| Access Control | `zone_list_screen`, `door_list_screen`, `access_logs_screen` | 3 |
| Performance | `performance_dashboard_screen`, `goals_screen` | 2 |
| Commands | `command_center_screen` | 1 |
| System | `health_screen`, `notification_center_screen`, `settings_screen` | 3 |

### School / Education ERP (14 files)

School-specific screens — students, academics, fees, transport.

| File | Class | Purpose |
|------|-------|---------|
| `school_dashboard_screen.dart` | `SchoolDashboardScreen` | School overview with stats grid |
| `student_list_screen.dart` | `StudentListScreen` | Student list with grade/section filters |
| `student_detail_screen.dart` | `StudentDetailScreen` | Student profile (5 tabs) |
| `admission_screen.dart` | `AdmissionScreen` | Applications and inquiries |
| `academic_year_screen.dart` | `AcademicYearScreen` | Session/term CRUD |
| `grade_section_screen.dart` | `GradeSectionScreen` | Classes and sections |
| `attendance_mark_screen.dart` | `AttendanceMarkScreen` | Student attendance marking |
| `timetable_screen.dart` | `TimetableScreen` | Class timetable by day |
| `exam_list_screen.dart` | `ExamListScreen` | Exam scheduling |
| `homework_screen.dart` | `HomeworkScreen` | Homework assignments |
| `fee_collection_screen.dart` | `FeeCollectionScreen` | Fee payments and dues |
| `library_screen.dart` | `LibraryScreen` | Book catalog and issue/return |
| `hostel_screen.dart` | `HostelScreen` | Room allocations |
| `transport_screen.dart` | `TransportScreen` | Route and vehicle management |

### Admin / Super Admin (7 files)

Platform admin screens for managing tenants, plans, and analytics.

| File | Class | Purpose |
|------|-------|---------|
| `admin_login_screen.dart` | `AdminLoginScreen` | Admin-specific login |
| `admin_dashboard_screen.dart` | `AdminDashboardScreen` | Platform overview |
| `admin_tenant_list_screen.dart` | `AdminTenantListScreen` | Tenant management list |
| `admin_tenant_detail_screen.dart` | `AdminTenantDetailScreen` | Single tenant detail |
| `admin_plan_screen.dart` | `AdminPlanScreen` | Subscription plan management |
| `admin_feature_screen.dart` | `AdminFeatureScreen` | Feature flag management |
| `admin_analytics_screen.dart` | `AdminAnalyticsScreen` | Usage analytics |

---

## 3. Proposed Structure

```
frontend/lib/screens/
├── core/                          # Shared across all roles
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── splash_screen.dart
│   ├── shell/
│   │   └── main_shell.dart
│   ├── dashboard/
│   │   └── dashboard_screen.dart
│   ├── notifications/
│   │   └── notification_list_screen.dart
│   ├── reports/
│   │   └── report_selection_screen.dart
│   └── setup/
│       └── setup_wizard_screen.dart
│
├── corporate/                     # HRMS screens for corporate tenants
│   ├── employees/
│   │   ├── employee_list_screen.dart
│   │   ├── employee_detail_screen.dart
│   │   ├── employee_profile_screen.dart
│   │   ├── create_employee_screen.dart
│   │   ├── bulk_employee_upload_screen.dart
│   │   ├── department_screen.dart
│   │   ├── designation_screen.dart
│   │   ├── organization_screen.dart
│   │   └── document_type_screen.dart
│   ├── attendance/
│   │   ├── attendance_dashboard_screen.dart
│   │   ├── attendance_list_screen.dart
│   │   ├── attendance_log_screen.dart
│   │   ├── attendance_summary_screen.dart
│   │   ├── attendance_calendar_screen.dart
│   │   ├── attendance_correction_screen.dart
│   │   ├── attendance_report_screen.dart
│   │   └── attendance_policy_screen.dart
│   ├── leaves/
│   │   ├── leave_dashboard_screen.dart
│   │   ├── leave_requests_screen.dart
│   │   ├── leave_apply_screen.dart
│   │   ├── leave_balance_screen.dart
│   │   ├── leave_types_screen.dart
│   │   └── leave_calendar_screen.dart
│   ├── payroll/
│   │   ├── payroll_dashboard_screen.dart
│   │   ├── payroll_screen.dart
│   │   ├── salary_structures_screen.dart
│   │   └── loans_screen.dart
│   ├── shifts/
│   │   ├── shift_management_screen.dart
│   │   ├── shift_list_screen.dart
│   │   ├── shift_create_screen.dart
│   │   ├── shift_group_screen.dart
│   │   ├── shift_roster_screen.dart
│   │   ├── shift_assign_screen.dart
│   │   └── department_shift_screen.dart
│   ├── holidays/
│   │   └── holiday_calendar_screen.dart
│   ├── recruitment/
│   │   ├── recruitment_dashboard_screen.dart
│   │   ├── candidates_screen.dart
│   │   └── interviews_screen.dart
│   ├── performance/
│   │   ├── performance_dashboard_screen.dart
│   │   └── goals_screen.dart
│   ├── visitors/
│   │   ├── visitor_list_screen.dart
│   │   ├── visitor_register_screen.dart
│   │   ├── visitor_pass_screen.dart
│   │   └── active_visitors_screen.dart
│   ├── finance/
│   │   └── expense_screen.dart
│   ├── access_control/
│   │   ├── zone_list_screen.dart
│   │   ├── door_list_screen.dart
│   │   └── access_logs_screen.dart
│   ├── ess/
│   │   ├── ess_dashboard_screen.dart
│   │   ├── ess_attendance_screen.dart
│   │   ├── ess_attendance_calendar_screen.dart
│   │   ├── ess_leave_screen.dart
│   │   └── ess_profile_screen.dart
│   ├── hr/
│   │   ├── announcement_screen.dart
│   │   ├── document_screen.dart
│   │   ├── asset_screen.dart
│   │   ├── exit_request_screen.dart
│   │   └── travel_screen.dart
│   ├── devices/
│   │   ├── device_list_screen.dart
│   │   ├── device_detail_screen.dart
│   │   └── device_health_screen.dart
│   ├── assets/
│   │   └── asset_dashboard_screen.dart
│   ├── commands/
│   │   └── command_center_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   ├── tenant_settings_screen.dart
│   │   ├── category_screen.dart
│   │   └── work_code_screen.dart
│   ├── essl/
│   │   ├── essl_server_list_screen.dart
│   │   ├── essl_server_form_screen.dart
│   │   ├── essl_locations_screen.dart
│   │   ├── essl_dashboard_screen.dart
│   │   ├── essl_sync_history_screen.dart
│   │   ├── essl_initial_sync_screen.dart
│   │   └── essl_reprocess_screen.dart
│   └── system/
│       ├── health_screen.dart
│       ├── notification_center_screen.dart
│       └── settings_screen.dart
│
├── school/                        # Education ERP screens (unchanged)
│   ├── school_dashboard_screen.dart
│   ├── student_list_screen.dart
│   ├── student_detail_screen.dart
│   ├── admission_screen.dart
│   ├── academic_year_screen.dart
│   ├── grade_section_screen.dart
│   ├── attendance_mark_screen.dart
│   ├── timetable_screen.dart
│   ├── exam_list_screen.dart
│   ├── homework_screen.dart
│   ├── fee_collection_screen.dart
│   ├── library_screen.dart
│   ├── hostel_screen.dart
│   └── transport_screen.dart
│
└── admin/                         # Platform super-admin screens (unchanged)
    ├── admin_login_screen.dart
    ├── admin_dashboard_screen.dart
    ├── admin_tenant_list_screen.dart
    ├── admin_tenant_detail_screen.dart
    ├── admin_plan_screen.dart
    ├── admin_feature_screen.dart
    └── admin_analytics_screen.dart
```

### Key Changes in Proposed Structure

1. **Root-level files** (`login_screen.dart`, `register_screen.dart`, `splash_screen.dart`, `main_shell.dart`) move into `core/auth/` and `core/shell/`.
2. **ESS screens** move from standalone `ess/` into `corporate/ess/` — they are corporate HRMS self-service, not a separate domain.
3. **eSSL screens** extracted from `settings/` into their own `corporate/essl/` subfolder — they form a distinct integration subsystem.
4. **Performance**, **visitors**, **finance**, **access_control**, **commands**, **system**, **hr** stay as subdirectories under `corporate/` instead of being top-level.
5. **School** and **admin** remain unchanged — they are already well-isolated.

---

## 4. Migration Plan

### Phase 1: Create New Directory Structure

Create the four top-level folders and their subdirectories:

```
mkdir -p frontend/lib/screens/core/{auth,shell,dashboard,notifications,reports,setup}
mkdir -p frontend/lib/screens/corporate/{employees,attendance,leaves,payroll,shifts,holidays,recruitment,performance,visitors,finance,access_control,ess,hr,devices,assets,commands,settings,essl,system}
mkdir -p frontend/lib/screens/school
mkdir -p frontend/lib/screens/admin
```

### Phase 2: Move Files (Grouped by Risk)

**Low risk — root files into core:**
```bash
# Auth
mv frontend/lib/screens/login_screen.dart       frontend/lib/screens/core/auth/
mv frontend/lib/screens/register_screen.dart     frontend/lib/screens/core/auth/
mv frontend/lib/screens/splash_screen.dart       frontend/lib/screens/core/auth/

# Shell
mv frontend/lib/screens/main_shell.dart          frontend/lib/screens/core/shell/

# Already in correct subdirectories — just move under core/
mv frontend/lib/screens/dashboard/*              frontend/lib/screens/core/dashboard/
mv frontend/lib/screens/notifications/*          frontend/lib/screens/core/notifications/
mv frontend/lib/screens/reports/*                frontend/lib/screens/core/reports/
mv frontend/lib/screens/setup/*                  frontend/lib/screens/core/setup/
```

**Medium risk — corporate feature folders:**
```bash
# Move existing subdirectories under corporate/
mv frontend/lib/screens/employees/*       frontend/lib/screens/corporate/employees/
mv frontend/lib/screens/attendance/*      frontend/lib/screens/corporate/attendance/
mv frontend/lib/screens/leaves/*          frontend/lib/screens/corporate/leaves/
mv frontend/lib/screens/payroll/*         frontend/lib/screens/corporate/payroll/
mv frontend/lib/screens/shifts/*          frontend/lib/screens/corporate/shifts/
mv frontend/lib/screens/holidays/*        frontend/lib/screens/corporate/holidays/
mv frontend/lib/screens/recruitment/*     frontend/lib/screens/corporate/recruitment/
mv frontend/lib/screens/performance/*     frontend/lib/screens/corporate/performance/
mv frontend/lib/screens/visitors/*        frontend/lib/screens/corporate/visitors/
mv frontend/lib/screens/finance/*         frontend/lib/screens/corporate/finance/
mv frontend/lib/screens/access_control/*  frontend/lib/screens/corporate/access_control/
mv frontend/lib/screens/ess/*             frontend/lib/screens/corporate/ess/
mv frontend/lib/screens/hr/*              frontend/lib/screens/corporate/hr/
mv frontend/lib/screens/devices/*         frontend/lib/screens/corporate/devices/
mv frontend/lib/screens/assets/*          frontend/lib/screens/corporate/assets/
mv frontend/lib/screens/commands/*        frontend/lib/screens/corporate/commands/
mv frontend/lib/screens/system/*          frontend/lib/screens/corporate/system/

# Split settings/ — eSSL files get their own folder
mv frontend/lib/screens/settings/essl_*.dart  frontend/lib/screens/corporate/essl/
mv frontend/lib/screens/settings/*.dart        frontend/lib/screens/corporate/settings/
```

**No change — school and admin stay as-is:**
```bash
# school/ and admin/ already exist at the correct location
# No moves needed — they are already properly scoped
```

### Phase 3: Update All Import Paths

Every `.dart` file that imports from `screens/` needs its import path updated. This is the highest-effort step.

**Strategy:**
1. Use `grep -r "import.*screens/" frontend/lib/` to find all affected files.
2. Apply systematic find-and-replace per group:
   - `import '../screens/login_screen.dart'` → `import '../screens/core/auth/login_screen.dart'`
   - `import '../screens/employees/...'` → `import '../screens/corporate/employees/...'`
   - `import '../screens/settings/essl_...'` → `import '../screens/corporate/essl/essl_...'`
3. Run `dart analyze` after each batch to catch broken imports.
4. **School and admin imports remain unchanged** — their paths don't move.

**Estimated affected files:** ~150–200 import statements across the codebase.

### Phase 4: Clean Up Empty Directories

After all moves, remove the now-empty original directories:

```bash
rmdir frontend/lib/screens/dashboard
rmdir frontend/lib/screens/notifications
rmdir frontend/lib/screens/reports
rmdir frontend/lib/screens/setup
rmdir frontend/lib/screens/employees
rmdir frontend/lib/screens/attendance
# ... etc for all emptied directories
```

### Phase 5: Verify

1. `dart analyze frontend/lib/` — must pass with zero errors.
2. `flutter build web --debug` or `flutter build apk --debug` — verify compilation.
3. Manual smoke test: login, navigate to each module, verify routing works.

---

## 5. Route Registration Impact

Check `frontend/lib/` for router configuration files. All `GoRouter` or `Navigator` route definitions that reference screen paths will need updating. Common locations:

- `frontend/lib/routes/` or `frontend/lib/router.dart`
- `frontend/lib/main.dart` (if routes are defined inline)
- `main_shell.dart` (sidebar/menu navigation targets)

**Recommendation:** Create a barrel file at each level to simplify imports:

```dart
// frontend/lib/screens/core/core.dart
export 'auth/login_screen.dart';
export 'auth/register_screen.dart';
export 'auth/splash_screen.dart';
export 'shell/main_shell.dart';
export 'dashboard/dashboard_screen.dart';
// ...
```

```dart
// frontend/lib/screens/corporate/corporate.dart
export 'employees/employee_list_screen.dart';
export 'employees/employee_detail_screen.dart';
// ...
```

This reduces import churn in router files to one line per domain.

---

## 6. File Count Summary

| Proposed Folder | File Count |
|-----------------|------------|
| `core/` | 8 |
| `corporate/employees/` | 9 |
| `corporate/attendance/` | 8 |
| `corporate/leaves/` | 6 |
| `corporate/payroll/` | 4 |
| `corporate/shifts/` | 7 |
| `corporate/holidays/` | 1 |
| `corporate/recruitment/` | 3 |
| `corporate/performance/` | 2 |
| `corporate/visitors/` | 4 |
| `corporate/finance/` | 1 |
| `corporate/access_control/` | 3 |
| `corporate/ess/` | 5 |
| `corporate/hr/` | 5 |
| `corporate/devices/` | 3 |
| `corporate/assets/` | 1 |
| `corporate/commands/` | 1 |
| `corporate/settings/` | 4 |
| `corporate/essl/` | 7 |
| `corporate/system/` | 3 |
| `school/` | 14 |
| `admin/` | 7 |
| **TOTAL** | **109** |
