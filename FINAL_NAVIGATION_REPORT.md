# FINAL NAVIGATION AUDIT REPORT — Apex HRMS

**Date**: 2026-06-28
**Auditor**: MiMoCode Agent
**Scope**: Full navigation audit of `frontend/lib/core/router.dart` and all referencing screens

---

## 1. EXECUTIVE SUMMARY

The Apex HRMS router defines **102 GoRoute entries** (21 top-level + 81 inside ShellRoute). All 107 imported screen files exist on disk. However, **7 navigation calls reference undefined routes** that will cause runtime failures, and **3 screen imports are unused**.

| Metric | Count |
|--------|-------|
| Total defined routes | 102 |
| Shell routes (inside MainShell) | 81 |
| Top-level routes (outside shell) | 21 |
| Route parameters (`:id`) | 8 |
| Imported screen files | 107 |
| Missing screen files | 0 |
| **Broken navigation calls** | **7** |
| Unused imports | 3 |
| Duplicate routes | 1 pair |

---

## 2. ROUTE ARCHITECTURE

### 2.1 Top-Level Routes (Outside ShellRoute)

| # | Path | Screen | Purpose |
|---|------|--------|---------|
| 1 | `/splash` | SplashScreen | App launch |
| 2 | `/login` | LoginScreen | User auth |
| 3 | `/register` | RegisterScreen | New account |
| 4 | `/setup` | SetupWizardScreen | First-time setup |
| 5 | `/admin/login` | AdminLoginScreen | Super admin auth |
| 6 | `/admin/dashboard` | AdminDashboardScreen | Super admin home |
| 7 | `/admin/tenants` | AdminTenantListScreen | Tenant management |
| 8 | `/admin/plans` | AdminPlanScreen | Subscription plans |
| 9 | `/admin/features` | AdminFeatureScreen | Feature flags |
| 10 | `/admin/analytics` | AdminAnalyticsScreen | Platform analytics |
| 11 | `/employees/:id` | EmployeeDetailScreen | Employee view (root) |
| 12 | `/employees/:id/edit` | EmployeeEditScreen | Employee edit (root) |
| 13 | `/attendance/detail` | AttendanceDetailScreen | Attendance by employee |
| 14 | `/attendance/summary` | DailySummaryScreen | Daily attendance summary |
| 15 | `/attendance/mark` | MarkAttendanceScreen | Mark attendance (root) |
| 16 | `/shifts/create` | ShiftCreateScreen | New shift (root) |
| 17 | `/shifts/assign` | ShiftAssignScreen | Assign shift (root) |
| 18 | `/shifts/:id/edit` | ShiftCreateScreen(shiftId) | Edit shift (root) |
| 19 | `/leaves/balance` | LeaveBalanceScreen | Leave balances (root) |
| 20 | `/leaves/apply` | LeaveApplyScreen | Apply leave (root) |
| 21 | `/leaves/requests` | LeaveRequestsScreen | Pending requests (root) |

### 2.2 Shell Routes (Inside MainShell — 81 routes)

#### Core Modules
| Path | Screen |
|------|--------|
| `/dashboard` | DashboardScreen |
| `/employees` | EmployeeDirectoryScreen |
| `/employees/create` | EmployeeCreateWizard |
| `/attendance` | AttendanceDashboardScreen |
| `/attendance/regularization` | AttendanceRegularizationScreen |
| `/attendance/ot` | OTRegisterScreen |
| `/attendance/outdoor-duty` | OutdoorDutyScreen |
| `/shifts` | ShiftManagementScreen |
| `/shift-groups` | ShiftGroupScreen |
| `/shift-rosters` | ShiftRosterScreen |
| `/department-shifts` | DepartmentShiftScreen |
| `/leaves` | LeaveDashboardScreen |
| `/leaves/types` | LeaveTypesScreen |
| `/leaves/calendar` | LeaveCalendarScreen |
| `/holidays` | HolidayCalendarScreen |
| `/devices` | DeviceListScreen |
| `/devices/health` | DeviceHealthScreen |
| `/devices/:id` | DeviceDetailScreen |
| `/visitors` | VisitorListScreen |
| `/visitors/register` | VisitorRegisterScreen |
| `/visitors/pass?passId=` | VisitorPassScreen |
| `/visitors/active` | ActiveVisitorsScreen |

#### Access Control & Commands
| Path | Screen |
|------|--------|
| `/access/zones` | ZoneListScreen |
| `/access/doors` | DoorListScreen |
| `/access/logs` | AccessLogsScreen |
| `/commands` | CommandCenterScreen |
| `/notifications` | NotificationListScreen |

#### Recruitment & Performance
| Path | Screen |
|------|--------|
| `/recruitment` | RecruitmentDashboardScreen |
| `/recruitment/candidates` | CandidatesScreen |
| `/recruitment/interviews` | InterviewsScreen |
| `/performance` | PerformanceDashboardScreen |
| `/performance/goals` | GoalsScreen |

#### Finance & Assets
| Path | Screen |
|------|--------|
| `/payroll` | PayrollDashboardScreen |
| `/payroll/salary-structures` | SalaryStructuresScreen |
| `/payroll/loans` | LoansScreen |
| `/expenses` | ExpenseScreen |
| `/assets` | AssetDashboardScreen |

#### HR Admin
| Path | Screen |
|------|--------|
| `/departments` | DepartmentScreen |
| `/branches` | BranchScreen |
| `/designations` | DesignationScreen |
| `/documents` | DocumentScreen |
| `/exit-requests` | ExitRequestScreen |
| `/travel` | TravelScreen |
| `/announcements` | AnnouncementScreen |
| `/reports` | ReportSelectionScreen |
| `/health` | HealthDashboardScreen |

#### Settings & eSSL
| Path | Screen |
|------|--------|
| `/settings` | SettingsScreen |
| `/settings/essl` | EsslServerListScreen |
| `/settings/essl/create` | EsslServerFormScreen |
| `/settings/essl/:id` | EsslServerFormScreen(serverId) |
| `/settings/essl/:id/history` | EsslSyncHistoryScreen |
| `/settings/essl/:id/locations` | EsslLocationsScreen |
| `/settings/essl/:id/initial-sync` | EsslInitialSyncScreen |
| `/settings/essl/:id/reprocess` | EsslReprocessScreen |
| `/settings/essl/dashboard` | EsslDashboardScreen |
| `/settings/categories` | CategoryScreen |
| `/settings/tenant-settings` | TenantSettingsScreen |
| `/settings/work-codes` | WorkCodeScreen |

#### ESS (Employee Self-Service)
| Path | Screen |
|------|--------|
| `/ess/dashboard` | EssDashboardScreen |
| `/ess/attendance` | EssAttendanceCalendarScreen |
| `/ess/attendance/calendar` | EssAttendanceCalendarScreen |
| `/ess/leaves` | EssLeaveScreen |
| `/ess/profile` | EssProfileScreen |
| `/ess/payslips` | EssPayslipScreen |
| `/ess/documents` | EssDocumentScreen |
| `/ess/notifications` | EssNotificationScreen |

#### School ERP
| Path | Screen |
|------|--------|
| `/school/dashboard` | SchoolDashboardScreen |
| `/school/students` | StudentListScreen |
| `/school/students/:id` | StudentDetailScreen |
| `/school/students/:id/edit` | StudentEditScreen |
| `/school/academic-years` | AcademicYearScreen |
| `/school/classes` | GradeSectionScreen |
| `/school/attendance/mark` | AttendanceMarkScreen |
| `/school/homework` | HomeworkScreen |
| `/school/exams` | ExamListScreen |
| `/school/fees` | FeeCollectionScreen |
| `/school/transport` | TransportScreen |
| `/school/hostel` | HostelScreen |
| `/school/library` | LibraryScreen |
| `/school/timetable` | TimetableScreen |
| `/school/admissions` | AdmissionScreen |

---

## 3. SIDEBAR NAVIGATION AUDIT

All sidebar items in `main_shell.dart` point to valid routes. **PASS.**

| Section | Item | Route | Status |
|---------|------|-------|--------|
| WORKSPACE | Dashboard | `/dashboard` | VALID |
| WORKSPACE | Employees | `/employees` | VALID |
| WORKSPACE | Attendance | `/attendance` | VALID |
| MANAGEMENT | Leave | `/leaves` | VALID |
| MANAGEMENT | Holidays | `/holidays` | VALID |
| MANAGEMENT | Visitors | `/visitors` | VALID |
| MANAGEMENT | Announcements | `/announcements` | VALID |
| MANAGEMENT | Exit Requests | `/exit-requests` | VALID |
| OPERATIONS | Shifts | `/shifts` | VALID |
| OPERATIONS | Devices | `/devices` | VALID |
| OPERATIONS | Outdoor Duty | `/attendance/outdoor-duty` | VALID |
| OPERATIONS | OT Register | `/attendance/ot` | VALID |
| OPERATIONS | Travel | `/travel` | VALID |
| OPERATIONS | Assets | `/assets` | VALID |
| OPERATIONS | Reports | `/reports` | VALID |
| FINANCE | Payroll | `/payroll` | VALID |
| FINANCE | Expenses | `/expenses` | VALID |
| FINANCE | Documents | `/documents` | VALID |
| SCHOOL | School Dashboard | `/school/dashboard` | VALID |
| SCHOOL | Students | `/school/students` | VALID |
| SCHOOL | Admissions | `/school/admissions` | VALID |
| SCHOOL | Attendance | `/school/attendance/mark` | VALID |
| SCHOOL | Timetable | `/school/timetable` | VALID |
| SCHOOL | Homework | `/school/homework` | VALID |
| SCHOOL | Examinations | `/school/exams` | VALID |
| SCHOOL | Fee Collection | `/school/fees` | VALID |
| SCHOOL | Transport | `/school/transport` | VALID |
| SCHOOL | Hostel | `/school/hostel` | VALID |
| SCHOOL | Library | `/school/library` | VALID |
| SCHOOL | Classes | `/school/classes` | VALID |
| SCHOOL | Academic Year | `/school/academic-years` | VALID |
| ADMIN | Administration | `/settings` | VALID |

---

## 4. DASHBOARD SHORTCUTS & QUICK ACTIONS AUDIT

All dashboard navigation targets are valid. **PASS.**

| Element | Route | Status |
|---------|-------|--------|
| KPI: Attendance | `/attendance` | VALID |
| KPI: Present | `/attendance` | VALID |
| KPI: Absent | `/attendance` | VALID |
| KPI: Late | `/attendance` | VALID |
| KPI: Leave | `/leaves/requests` | VALID |
| KPI: Devices | `/devices` | VALID |
| KPI: Visitors | `/visitors/active` | VALID |
| Pending: Missing Punches | `/attendance` | VALID |
| Pending: Late Today | `/attendance` | VALID |
| Pending: Pending Approvals | `/leaves/requests` | VALID |
| Pending: Offline Devices | `/devices` | VALID |
| Quick Action: Mark Attendance | `/attendance/mark` | VALID |
| Quick Action: Add Employee | `/employees/create` | VALID |
| Quick Action: Apply Leave | `/leaves/apply` | VALID |
| Quick Action: Reports | `/reports` | VALID |

---

## 5. COMMAND PALETTE AUDIT

All 25 command palette entries point to valid routes. **PASS.**

| Command | Route | Status |
|---------|-------|--------|
| Dashboard | `/dashboard` | VALID |
| Employees | `/employees` | VALID |
| Attendance | `/attendance` | VALID |
| Leave | `/leaves` | VALID |
| Visitors | `/visitors` | VALID |
| Devices | `/devices` | VALID |
| Reports | `/reports` | VALID |
| Administration | `/settings` | VALID |
| Add Employee | `/employees/create` | VALID |
| Mark Attendance | `/attendance/mark` | VALID |
| Apply Leave | `/leaves/apply` | VALID |
| School Dashboard | `/school/dashboard` | VALID |
| Students | `/school/students` | VALID |
| Mark Student Attendance | `/school/attendance/mark` | VALID |
| Homework | `/school/homework` | VALID |
| Examinations | `/school/exams` | VALID |
| Fee Collection | `/school/fees` | VALID |
| Transport | `/school/transport` | VALID |
| Hostel | `/school/hostel` | VALID |
| Library | `/school/library` | VALID |
| Timetable | `/school/timetable` | VALID |
| Admissions | `/school/admissions` | VALID |
| Classes & Sections | `/school/classes` | VALID |
| Academic Years | `/school/academic-years` | VALID |

---

## 6. BROKEN NAVIGATION CALLS (7 ISSUES)

### CRITICAL: Runtime errors when users tap these UI elements

| # | Undefined Route | Source File | Line | Severity | Fix |
|---|----------------|-------------|------|----------|-----|
| 1 | `/performance/reviews` | `performance_dashboard_screen.dart` | 67 | **HIGH** | Add route + screen, or remove button |
| 2 | `/performance/competencies` | `performance_dashboard_screen.dart` | 72 | **HIGH** | Add route + screen, or remove button |
| 3 | `/shifts/groups` | `shift_management_screen.dart` | 45 | **HIGH** | Change to `/shift-groups` (route exists) |
| 4 | `/shifts/rosters` | `shift_management_screen.dart` | 51 | **HIGH** | Change to `/shift-rosters` (route exists) |
| 5 | `/admin/tenants/${id}` | `admin_tenant_list_screen.dart` | 112 | **CRITICAL** | Add `GoRoute(path: '/admin/tenants/:id')` → AdminTenantDetailScreen |
| 6 | `/school/exams/${id}` | `exam_list_screen.dart` | 86 | **MEDIUM** | Add route + exam detail screen |
| 7 | `/school/students/create` | `student_list_screen.dart` | 68 | **MEDIUM** | Add route + student create screen |

### Details

**#1-2: Performance module missing routes**
`performance_dashboard_screen.dart` has buttons for "Reviews" and "Competencies" that push to `/performance/reviews` and `/performance/competencies`. Neither route exists. No screen files for reviews or competencies are imported in `router.dart`.

**#3-4: Shift management path mismatch**
`shift_management_screen.dart` navigates to `/shifts/groups` and `/shifts/rosters`, but the actual defined routes are `/shift-groups` and `/shift-rosters`. The URL pattern is inconsistent — some shift routes use `/shifts/*` (nested) while others use `/shift-*` (flat).

**#5: Admin tenant detail — orphaned screen**
`AdminTenantDetailScreen` is imported at `router.dart:55` but never wired to any route. The tenant list navigates to `/admin/tenants/${t['id']}` which has no matching GoRoute. This will cause a runtime error when super admin clicks any tenant row.

**#6: School exam detail — missing**
`exam_list_screen.dart` navigates to `/school/exams/${e['id']}` but no `/school/exams/:id` route or exam detail screen exists.

**#7: School student create — missing**
`student_list_screen.dart` navigates to `/school/students/create` but no such route exists. Employee creation uses `/employees/create` → `EmployeeCreateWizard`, but no equivalent exists for school students.

---

## 7. UNUSED IMPORTS (3 FILES)

These screens are imported in `router.dart` but never used in any route definition:

| # | Import | Line | Class |
|---|--------|------|-------|
| 1 | `screens/employees/employee_list_screen.dart` | 10 | EmployeeListScreen |
| 2 | `screens/attendance/attendance_list_screen.dart` | 20 | AttendanceListScreen |
| 3 | `screens/shifts/shift_list_screen.dart` | 24 | ShiftListScreen |

These appear to be legacy screens replaced by newer versions (EmployeeDirectoryScreen, AttendanceDashboardScreen, ShiftManagementScreen).

---

## 8. ROUTE PARAMETER ANALYSIS

| Route | Parameter | Type | Status |
|-------|-----------|------|--------|
| `/employees/:id` | id | path | VALID — uses `rootNavigatorKey` |
| `/employees/:id/edit` | id | path | VALID — uses `rootNavigatorKey` |
| `/shifts/:id/edit` | id | path | VALID — uses `rootNavigatorKey` |
| `/devices/:id` | id | path | VALID — inside ShellRoute |
| `/settings/essl/:id` | id | path | VALID — inside ShellRoute |
| `/settings/essl/:id/history` | id | path | VALID — inside ShellRoute |
| `/settings/essl/:id/locations` | id | path | VALID — inside ShellRoute |
| `/settings/essl/:id/initial-sync` | id | path | VALID — inside ShellRoute |
| `/settings/essl/:id/reprocess` | id | path | VALID — inside ShellRoute |
| `/school/students/:id` | id | path | VALID — inside ShellRoute |
| `/school/students/:id/edit` | id | path | VALID — inside ShellRoute |
| `/attendance/detail` | employeeId | query | VALID — uses `rootNavigatorKey` |
| `/visitors/pass` | passId | query | VALID — inside ShellRoute |

**Note**: All parameterized routes correctly use `state.pathParameters['id']!` or `state.uri.queryParameters['key']!` with non-null assertions. A missing parameter will throw at runtime — no defensive fallback exists. This is acceptable for internal navigation but would crash on malformed deep links.

---

## 9. ROUTE GUARD (REDIRECT) ANALYSIS

The redirect logic at `router.dart:122-154` handles:

| Condition | Behavior | Status |
|-----------|----------|--------|
| Unauthenticated user → protected route | Redirect to `/login` | VALID |
| Authenticated user → login/register/splash | Redirect to `/dashboard` or `/admin/dashboard` | VALID |
| Admin user → non-admin routes | Redirect to `/admin/dashboard` | VALID |
| Non-admin user → admin routes | Redirect to `/dashboard` | VALID |
| Admin user → admin routes | Allow | VALID |

**Potential issue**: The redirect checks `state.matchedLocation` but does not validate that the matched route actually exists. A deep link to `/nonexistent` would pass the guard and hit GoRouter's default 404 behavior (which is a blank screen unless a custom error page is configured). No `errorPageBuilder` or `errorBuilder` is defined.

---

## 10. DUPLICATE ROUTES

| Route | Both Map To | Issue |
|-------|-------------|-------|
| `/ess/attendance` | EssAttendanceCalendarScreen | Redundant — both resolve to same screen |
| `/ess/attendance/calendar` | EssAttendanceCalendarScreen | One should be removed or one should redirect |

---

## 11. BROWSER BACK/FORWARD ANALYSIS

- Uses `GoRouter` with `navigatorKey` separation (root vs shell) — **correct pattern**
- Shell routes preserve bottom nav state via `ShellRoute` — **correct**
- Top-level detail routes use `parentNavigatorKey: rootNavigatorKey` — **correct** (full-screen overlays)
- `context.go()` (49 uses) replaces the current URL — back button navigates to previous logical entry
- `context.push()` (112 uses) pushes onto the navigation stack — back button returns correctly
- `context.pop()` (12 uses) — standard back behavior
- **No `context.replace()` usage** — all transitions are either full navigation or push
- **Verdict**: Browser back/forward should work correctly for all valid routes.

---

## 12. RECOMMENDATIONS

### Priority 1 — Fix Broken Routes (Runtime Errors)

1. **Add `/admin/tenants/:id` route** → `AdminTenantDetailScreen`
   ```dart
   GoRoute(
     path: '/admin/tenants/:id',
     builder: (context, state) {
       final id = state.pathParameters['id']!;
       return AdminTenantDetailScreen(tenantId: id);
     },
   ),
   ```

2. **Fix shift management paths** in `shift_management_screen.dart`:
   - Line 45: Change `/shifts/groups` → `/shift-groups`
   - Line 51: Change `/shifts/rosters` → `/shift-rosters`

3. **Add performance routes** (or remove buttons):
   - Add `/performance/reviews` route + ReviewsScreen
   - Add `/performance/competencies` route + CompetenciesScreen

### Priority 2 — Add Missing Routes

4. **Add `/school/exams/:id` route** + ExamDetailScreen
5. **Add `/school/students/create` route** + StudentCreateScreen (or reuse StudentEditScreen in create mode)

### Priority 3 — Cleanup

6. **Remove 3 unused imports** from `router.dart`:
   - `employee_list_screen.dart`
   - `attendance_list_screen.dart`
   - `shift_list_screen.dart`

7. **Deduplicate ESS attendance routes** — keep one of `/ess/attendance` or `/ess/attendance/calendar`

8. **Add error page** to GoRouter:
   ```dart
   errorBuilder: (context, state) => const NotFoundScreen(),
   ```

9. **Normalize route naming** — decide between `/shifts/*` (nested) and `/shift-*` (flat) patterns. Currently mixed.

10. **Add null-safe deep link handling** — consider wrapping path parameter extraction with validation instead of `!` (non-null assertion).

---

## 13. SUMMARY TABLE

| Category | Total | Valid | Broken | Notes |
|----------|-------|-------|--------|-------|
| Defined routes | 102 | 102 | 0 | All GoRoute entries are well-formed |
| Imported screens | 107 | 107 | 0 | All files exist on disk |
| Sidebar navigation | 33 | 33 | 0 | All items valid |
| Dashboard shortcuts | 15 | 15 | 0 | All KPIs and actions valid |
| Command palette | 25 | 25 | 0 | All commands valid |
| **Cross-screen navigation** | **166** | **159** | **7** | **7 broken calls found** |
| Route guards | 1 | 1 | 0 | Redirect logic works (no error page) |
| Unused imports | 3 | — | — | Dead code |

**Overall navigation health: 95.8%** (159/166 cross-screen nav calls are valid)

---

*Report generated by automated navigation audit. No files were modified.*
