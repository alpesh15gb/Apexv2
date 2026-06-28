# Apex HRMS — Frontend Module Map

> **Total: 106 screens** across 20 modules  
> Framework: Flutter + Riverpod + GoRouter  
> Responsive: `<600px` mobile | `600–1200px` tablet | `>1200px` desktop

---

## Screen Classification

### 1. Core Screens (Shared — 6 screens)

| # | Screen | File | Route | Description |
|---|--------|------|-------|-------------|
| 1 | Splash | `splash_screen.dart` | `/splash` | Logo + auth check, redirects to login/dashboard/admin |
| 2 | Login | `login_screen.dart` | `/login` | Email/password form, links to register |
| 3 | Register | `register_screen.dart` | `/register` | New tenant registration (company, slug, name, email, password) |
| 4 | Dashboard | `dashboard/dashboard_screen.dart` | `/dashboard` | Corporate KPIs, charts, quick actions; auto-switches to `SchoolDashboardScreen` for school tenants |
| 5 | Notifications | `notifications/notification_list_screen.dart` | `/notifications` | Notification feed |
| 6 | Setup Wizard | `setup/setup_wizard_screen.dart` | `/setup` | Multi-step onboarding wizard for new tenants |

**Shared Layout Shell:** `main_shell.dart` — sidebar (desktop/tablet) + bottom nav (mobile) + top bar with breadcrumbs, search (⌘K), quick-create menu.

---

### 2. Corporate Screens (71 screens)

#### 2.1 Employee Module (9 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Employee Directory | `employees/employee_directory_screen.dart` | `/employees` |
| 2 | Employee List (legacy) | `employees/employee_list_screen.dart` | — (referenced internally) |
| 3 | Employee Detail | `employees/employee_detail_screen.dart` | `/employees/:id` |
| 4 | Employee Create | `employees/employee_create_screen.dart` | — (legacy) |
| 5 | Employee Create Wizard | `employees/employee_create_wizard.dart` | `/employees/create` |
| 6 | Employee Edit | `employees/employee_edit_screen.dart` | `/employees/:id/edit` |
| 7 | Departments | `employees/department_screen.dart` | `/departments` |
| 8 | Designations | `employees/designation_screen.dart` | `/designations` |
| 9 | Branches | `employees/branch_screen.dart` | `/branches` |

#### 2.2 Attendance Module (8 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Attendance Dashboard | `attendance/attendance_dashboard_screen.dart` | `/attendance` |
| 2 | Attendance List | `attendance/attendance_list_screen.dart` | — (embedded in dashboard) |
| 3 | Attendance Detail | `attendance/attendance_detail_screen.dart` | `/attendance/detail` |
| 4 | Daily Summary | `attendance/daily_summary_screen.dart` | `/attendance/summary` |
| 5 | Mark Attendance | `attendance/mark_attendance_screen.dart` | `/attendance/mark` |
| 6 | Regularization | `attendance/regularization_screen.dart` | `/attendance/regularization` |
| 7 | Outdoor Duty | `attendance/outdoor_duty_screen.dart` | `/attendance/outdoor-duty` |
| 8 | OT Register | `attendance/ot_register_screen.dart` | `/attendance/ot` |

#### 2.3 Shift Module (7 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Shift Management | `shifts/shift_management_screen.dart` | `/shifts` |
| 2 | Shift List | `shifts/shift_list_screen.dart` | — (embedded) |
| 3 | Shift Create/Edit | `shifts/shift_create_screen.dart` | `/shifts/create`, `/shifts/:id/edit` |
| 4 | Shift Assign | `shifts/shift_assign_screen.dart` | `/shifts/assign` |
| 5 | Shift Groups | `shifts/shift_group_screen.dart` | `/shift-groups` |
| 6 | Shift Rosters | `shifts/shift_roster_screen.dart` | `/shift-rosters` |
| 7 | Department Shifts | `shifts/department_shift_screen.dart` | `/department-shifts` |

#### 2.4 Leave Module (6 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Leave Dashboard | `leaves/leave_dashboard_screen.dart` | `/leaves` |
| 2 | Leave Types | `leaves/leave_types_screen.dart` | `/leaves/types` |
| 3 | Leave Calendar | `leaves/leave_calendar_screen.dart` | `/leaves/calendar` |
| 4 | Apply Leave | `leaves/leave_apply_screen.dart` | `/leaves/apply` |
| 5 | Leave Requests | `leaves/leave_requests_screen.dart` | `/leaves/requests` |
| 6 | Leave Balance | `leaves/leave_balance_screen.dart` | `/leaves/balance` |

#### 2.5 Payroll Module (4 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Payroll Dashboard | `payroll/payroll_dashboard_screen.dart` | `/payroll` |
| 2 | Payslips | `payroll/payroll_screen.dart` | — (tab within dashboard) |
| 3 | Salary Structures | `payroll/salary_structures_screen.dart` | `/payroll/salary-structures` |
| 4 | Loans | `payroll/loans_screen.dart` | `/payroll/loans` |

#### 2.6 Visitor Module (4 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Visitor List | `visitors/visitor_list_screen.dart` | `/visitors` |
| 2 | Register Visitor | `visitors/visitor_register_screen.dart` | `/visitors/register` |
| 3 | Visitor Pass | `visitors/visitor_pass_screen.dart` | `/visitors/pass` |
| 4 | Active Visitors | `visitors/active_visitors_screen.dart` | `/visitors/active` |

#### 2.7 Device Module (3 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Device List | `devices/device_list_screen.dart` | `/devices` |
| 2 | Device Detail | `devices/device_detail_screen.dart` | `/devices/:id` |
| 3 | Device Health | `devices/device_health_screen.dart` | `/devices/health` |

#### 2.8 Recruitment Module (3 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Recruitment Dashboard | `recruitment/recruitment_dashboard_screen.dart` | `/recruitment` |
| 2 | Candidates | `recruitment/candidates_screen.dart` | `/recruitment/candidates` |
| 3 | Interviews | `recruitment/interviews_screen.dart` | `/recruitment/interviews` |

#### 2.9 Performance Module (2 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Performance Dashboard | `performance/performance_dashboard_screen.dart` | `/performance` |
| 2 | Goals | `performance/goals_screen.dart` | `/performance/goals` |

#### 2.10 Asset Module (1 screen)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Asset Dashboard | `assets/asset_dashboard_screen.dart` | `/assets` |

#### 2.11 Report Module (1 screen)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Report Selection | `reports/report_selection_screen.dart` | `/reports` |

Supports: daily, absent, late, early-going, missed-punch, monthly, department-summary reports. Export to PDF/Excel/CSV.

#### 2.12 Holiday Module (1 screen)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Holiday Calendar | `holidays/holiday_calendar_screen.dart` | `/holidays` |

#### 2.13 HR Module (5 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Announcements | `hr/announcement_screen.dart` | `/announcements` |
| 2 | Exit Requests | `hr/exit_request_screen.dart` | `/exit-requests` |
| 3 | Travel Requests | `hr/travel_screen.dart` | `/travel` |
| 4 | Documents | `hr/document_screen.dart` | `/documents` |
| 5 | Company Assets (HR) | `hr/asset_screen.dart` | — (linked from settings) |

#### 2.14 Finance Module (1 screen)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Expense Claims | `finance/expense_screen.dart` | `/expenses` |

#### 2.15 ESS — Employee Self-Service (5 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | ESS Dashboard | `ess/ess_dashboard_screen.dart` | `/ess/dashboard` |
| 2 | ESS Attendance | `ess/ess_attendance_screen.dart` | — (linked from ESS dashboard) |
| 3 | ESS Attendance Calendar | `ess/ess_attendance_calendar_screen.dart` | `/ess/attendance` |
| 4 | ESS Leave | `ess/ess_leave_screen.dart` | — (linked from ESS dashboard) |
| 5 | ESS Profile | `ess/ess_profile_screen.dart` | `/ess/profile` |

Note: Router also references `EssPayslipScreen`, `EssDocumentScreen`, `EssNotificationScreen` at `/ess/payslips`, `/ess/documents`, `/ess/notifications` (imported from ESS module).

#### 2.16 Access Control Module (3 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Zone List | `access_control/zone_list_screen.dart` | `/access/zones` |
| 2 | Door List | `access_control/door_list_screen.dart` | `/access/doors` |
| 3 | Access Logs | `access_control/access_logs_screen.dart` | `/access/logs` |

#### 2.17 System Module (3 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Notification Center | `system/notification_center_screen.dart` | — (system-level) |
| 2 | Health Dashboard | `system/health_screen.dart` | `/health` |
| 3 | System Settings | `system/settings_screen.dart` | — (system-level) |

#### 2.18 Commands Module (1 screen)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Command Center | `commands/command_center_screen.dart` | `/commands` |

#### 2.19 Settings Module (11 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Administration Hub | `settings/settings_screen.dart` | `/settings` |
| 2 | eSSL Server List | `settings/essl_server_list_screen.dart` | `/settings/essl` |
| 3 | eSSL Server Form | `settings/essl_server_form_screen.dart` | `/settings/essl/create`, `/settings/essl/:id` |
| 4 | eSSL Sync History | `settings/essl_sync_history_screen.dart` | `/settings/essl/:id/history` |
| 5 | eSSL Initial Sync | `settings/essl_initial_sync_screen.dart` | `/settings/essl/:id/initial-sync` |
| 6 | eSSL Reprocess | `settings/essl_reprocess_screen.dart` | `/settings/essl/:id/reprocess` |
| 7 | eSSL Dashboard | `settings/essl_dashboard_screen.dart` | `/settings/essl/dashboard` |
| 8 | eSSL Locations | `settings/essl_locations_screen.dart` | `/settings/essl/:id/locations` |
| 9 | Categories | `settings/category_screen.dart` | `/settings/categories` |
| 10 | Tenant Settings | `settings/tenant_settings_screen.dart` | `/settings/tenant-settings` |
| 11 | Work Codes | `settings/work_code_screen.dart` | `/settings/work-codes` |

---

### 3. School Screens (14 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | School Dashboard | `school/school_dashboard_screen.dart` | `/school/dashboard` |
| 2 | Student List | `school/student_list_screen.dart` | `/school/students` |
| 3 | Student Detail | `school/student_detail_screen.dart` | `/school/students/:id` |
| 4 | Academic Years | `school/academic_year_screen.dart` | `/school/academic-years` |
| 5 | Grades & Sections | `school/grade_section_screen.dart` | `/school/classes` |
| 6 | Attendance Mark | `school/attendance_mark_screen.dart` | `/school/attendance/mark` |
| 7 | Homework | `school/homework_screen.dart` | `/school/homework` |
| 8 | Examinations | `school/exam_list_screen.dart` | `/school/exams` |
| 9 | Fee Collection | `school/fee_collection_screen.dart` | `/school/fees` |
| 10 | Transport | `school/transport_screen.dart` | `/school/transport` |
| 11 | Hostel | `school/hostel_screen.dart` | `/school/hostel` |
| 12 | Library | `school/library_screen.dart` | `/school/library` |
| 13 | Timetable | `school/timetable_screen.dart` | `/school/timetable` |
| 14 | Admissions | `school/admission_screen.dart` | `/school/admissions` |

**Activation:** School screens appear when `user.isSchool == true`. The sidebar dynamically swaps corporate sections for the SCHOOL section. The main `DashboardScreen` auto-delegates to `SchoolDashboardScreen`.

---

### 4. Admin Screens (7 screens)

| # | Screen | File | Route |
|---|--------|------|-------|
| 1 | Admin Login | `admin/admin_login_screen.dart` | `/admin/login` |
| 2 | Admin Dashboard | `admin/admin_dashboard_screen.dart` | `/admin/dashboard` |
| 3 | Tenant List | `admin/admin_tenant_list_screen.dart` | `/admin/tenants` |
| 4 | Tenant Detail | `admin/admin_tenant_detail_screen.dart` | `/admin/tenants/:tenantId` |
| 5 | Plan Management | `admin/admin_plan_screen.dart` | `/admin/plans` |
| 6 | Feature Flags | `admin/admin_feature_screen.dart` | `/admin/features` |
| 7 | Analytics | `admin/admin_analytics_screen.dart` | `/admin/analytics` |

**Activation:** Admin screens use a separate auth flow (`is_admin` flag in secure storage). Router redirects superusers to `/admin/dashboard` and blocks non-admin access to `/admin/*` routes. Admin uses a dark theme (`ApexColors.darkBackground`).

---

## Navigation Flow

### Auth & Routing Guards

```
/splash → check token
  ├─ no token → /login
  ├─ token + isSuperuser → /admin/dashboard
  └─ token + normal user → /dashboard

/login → authenticate
  ├─ superuser → /admin/dashboard
  └─ normal → /dashboard

/admin/login → admin authenticate → /admin/dashboard
```

**Guard rules** (in `router.dart`):
- Unauthenticated users can only access `/login`, `/register`, `/splash`, `/admin/login`
- Authenticated non-admin users are blocked from `/admin/*`
- Authenticated admin users are forced to `/admin/*`

### Shell Routes (wrapped in `MainShell`)

All corporate and school routes inside the `ShellRoute` share the sidebar + top bar layout. Root-level routes (detail screens, create forms, ESS) use `rootNavigatorKey` to bypass the shell for full-screen presentation.

### Sidebar Sections (Desktop/Tablet)

```
WORKSPACE
  ├── Dashboard
  ├── Employees
  └── Attendance

MANAGEMENT
  ├── Leave
  ├── Holidays
  ├── Visitors
  ├── Announcements
  └── Exit Requests

OPERATIONS (hidden for school tenants)
  ├── Shifts
  ├── Devices
  ├── Outdoor Duty
  ├── OT Register
  ├── Travel
  ├── Assets
  └── Reports

FINANCE (hidden for school tenants)
  ├── Payroll
  ├── Expenses
  └── Documents

SCHOOL (shown only for school tenants)
  ├── School Dashboard
  ├── Students
  ├── Admissions
  ├── Attendance
  ├── Timetable
  ├── Homework
  ├── Examinations
  ├── Fee Collection
  ├── Transport
  ├── Hostel
  ├── Library
  ├── Classes
  └── Academic Year

ADMINISTRATION → /settings
```

### Mobile Bottom Navigation

```
[Dashboard] [Employees] [Attendance] [More...]
```

"More" opens a bottom sheet with: Leave, Visitors, Devices, Reports, Administration.

### Command Palette (⌘K)

Searchable overlay with all major routes including school and corporate screens. Triggered via keyboard shortcut or search bar in top bar.

---

## Responsive Behavior

### Breakpoints (`core/responsive.dart`)

| Breakpoint | Width | Layout |
|------------|-------|--------|
| Mobile | `<600px` | Bottom nav, single column, collapsed cards |
| Tablet | `600–1200px` | Sidebar (collapsed icons), 2-column grids |
| Desktop | `>1200px` | Sidebar (expanded 240px), 3-column grids, side-by-side charts |

### Key Responsive Patterns

1. **Main Shell** (`main_shell.dart`):
   - Desktop/Tablet: sidebar on left, content on right
   - Mobile: no sidebar, bottom `NavigationBar` with 4 tabs + "More" sheet
   - Sidebar: 240px expanded ↔ 64px collapsed (toggle button)

2. **Dashboard** (`dashboard_screen.dart`):
   - KPI grid: 7 columns desktop, 2 columns mobile
   - Charts: side-by-side on desktop, stacked on mobile
   - Quick actions: horizontal row desktop, wrapped on mobile

3. **Settings** (`settings/settings_screen.dart`):
   - Profile card + grouped settings list
   - Padding adjusts: 16px mobile, 20px desktop

4. **Admin Dashboard** (`admin_dashboard_screen.dart`):
   - Stats grid: 4 cols (>1200px), 3 cols (>800px), 2 cols (mobile)
   - Dark theme throughout

5. **School Dashboard** (`school_dashboard_screen.dart`):
   - Same grid responsive pattern as admin
   - Quick actions wrapped

6. **List screens** (employees, visitors, devices, etc.):
   - Mobile: single-column card layout
   - Desktop: table/grid layout with filters in sidebar or top bar

---

## Module Dependency Graph

```
┌─────────────────────────────────────────────────────────┐
│                    Core / Shared                         │
│  splash → login → main_shell → dashboard                │
│  register, setup_wizard, notifications, settings        │
└───────────────────────┬─────────────────────────────────┘
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
   ┌─────────┐   ┌──────────┐   ┌──────────┐
   │Corporate│   │  School  │   │  Admin   │
   │  (71)   │   │  (14)    │   │  (7)     │
   └────┬────┘   └──────────┘   └──────────┘
        │
   ┌────┴──────────────────────────────┐
   │  Employees ←→ Attendance ←→ Shifts│
   │  Leave ←→ Payroll                 │
   │  Visitors, Devices, Recruitment   │
   │  Performance, Assets, Reports     │
   │  ESS, HR, Finance, Access Control │
   └───────────────────────────────────┘
```

---

## Technology Stack

| Layer | Technology |
|-------|-----------|
| State Management | Riverpod (`FutureProvider`, `StateNotifierProvider`, `StateProvider`) |
| Routing | GoRouter with `ShellRoute` for shared layout |
| HTTP | Dio (`dio_client.dart`) |
| Charts | fl_chart (LineChart, BarChart) |
| Responsive | Custom `Responsive` utility class |
| Design System | Custom `ApexColors`, `ApexTypography`, `ApexSpacing`, `ApexRadius` |
| Storage | flutter_secure_storage for tokens |

---

## File Count by Module

| Module | Directory | Screen Count |
|--------|-----------|:------------:|
| Core (shared) | root + dashboard + notifications + setup | 6 |
| Employees | `employees/` | 9 |
| Attendance | `attendance/` | 8 |
| Shifts | `shifts/` | 7 |
| Leaves | `leaves/` | 6 |
| Payroll | `payroll/` | 4 |
| Visitors | `visitors/` | 4 |
| Devices | `devices/` | 3 |
| Recruitment | `recruitment/` | 3 |
| Performance | `performance/` | 2 |
| Assets | `assets/` | 1 |
| Reports | `reports/` | 1 |
| Holidays | `holidays/` | 1 |
| HR | `hr/` | 5 |
| Finance | `finance/` | 1 |
| ESS | `ess/` | 5 |
| Access Control | `access_control/` | 3 |
| System | `system/` | 3 |
| Commands | `commands/` | 1 |
| Settings | `settings/` | 11 |
| School | `school/` | 14 |
| Admin | `admin/` | 7 |
| **Total** | | **106** |
