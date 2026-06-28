# Workflow Review — Apex v2 Platform
**Audit Date:** 2026-06-28  
**Auditor Role:** Senior QA / Workflow Analyst (Read-Only)  
**Scope:** Complete end-to-end user journey validation for all specified workflows.

---

## Methodology

Each workflow was traced through the router configuration, screen implementations, provider state, and navigation logic. Issues are rated as: ✅ Pass | ⚠️ Partial | ❌ Fail.

---

## CORPORATE HRMS WORKFLOWS

---

### WF-01: Login
**Route:** `/login` → `LoginScreen` (within ShellRoute? No — standalone)

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Navigate to `/login` | Login form renders | Renders correctly with email + password + show/hide password | ✅ |
| 2 | Submit with valid credentials | Redirects to `/dashboard` | `authProvider` triggers redirect; `is_admin` flag routes admin to `/admin/dashboard` | ✅ |
| 3 | Submit with invalid credentials | Inline error message | Error message via `ScaffoldMessenger.showSnackBar` — disappears in 4s, not inline | ⚠️ |
| 4 | "Register" link present | Link to registration | Not found in code — no link from login to register page | ❌ |
| 5 | Forgot password flow | Reset password path | No forgot password screen exists in router or file list | ❌ |
| 6 | Stay logged in / remember me | Persistent session option | Not implemented; JWT stored in secure storage | ⚠️ |

**Workflow Score: 3/6 Pass**  
**Critical Gaps:** No forgot password flow. No login → register link. Error feedback via disappearing snackbar only.

---

### WF-02: Employee Management
**Routes:** `/employees` → `/employees/create` → `/employees/:id` → `/employees/:id/edit`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View employee list | Paginated table or grid with search | `EmployeeDirectoryScreen` with grid/table toggle, search, department/branch/status filters | ✅ |
| 2 | Search employees | Real-time search | Search is present via `EmployeeDirectoryNotifier`; triggers API call | ✅ |
| 3 | Filter by department/branch/status | Filter dialog | Filter dialog exists (`_FilterDialog`) | ✅ |
| 4 | Create new employee | 7-step wizard | Wizard exists and covers all key data (basic, employment, org, salary, bank, emergency, review) | ⚠️ |
| 4a | Wizard step-by-step validation | Per-step validation before advancing | "Continue" advances without validation; no per-step checks | ❌ |
| 4b | Organization dropdowns populated | Departments, branches, shifts loaded | Loaded async; silently empty on error | ⚠️ |
| 5 | View employee detail | Full employee profile | `EmployeeDetailScreen` exists with tab-based layout | ✅ |
| 6 | Edit employee | Pre-filled edit form | `EmployeeEditScreen` exists (16.2KB, substantial) | ✅ |
| 7 | Deactivate employee | Confirmation + deactivation | `POST /employees/:id/deactivate` endpoint exists; UI path unclear | ⚠️ |
| 8 | Bulk import | CSV/Excel import | Endpoint exists (`POST /employees/bulk-import`); no UI screen for it | ❌ |

**Workflow Score: 5/10 checkpoints Pass/Partial**  
**Critical Gaps:** No per-step validation in wizard. Bulk import has no frontend UI screen. Deactivation path unclear in UI.

---

### WF-03: Attendance
**Routes:** `/attendance` → `/attendance/detail` → `/attendance/regularization` → `/attendance/mark` → `/attendance/summary`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View daily attendance | Stats + table with date filter | `AttendanceDashboardScreen` with stats row, date picker, paginated table | ✅ |
| 2 | Filter by department/status | Filter bar | `_FiltersBar` widget with dept/status dropdowns | ✅ |
| 3 | View employee attendance detail | Per-employee attendance history | `AttendanceDetailScreen` (passes `employeeId` via query param) | ✅ |
| 4 | Regularization request | Submit attendance correction | `AttendanceRegularizationScreen` exists | ✅ |
| 5 | Mark manual attendance | Select employee + mark | `MarkAttendanceScreen` exists | ✅ |
| 6 | Process/recalculate attendance | Trigger engine | Action exists but no confirmation dialog | ⚠️ |
| 7 | View OT register | OT hours list | `OTRegisterScreen` exists at `/attendance/ot` | ✅ |
| 8 | Export attendance | Download report | Via Reports screen (`/reports`) — not inline from attendance | ⚠️ |
| 9 | Punch log view | Raw punch logs | `GET /attendance/punch-logs` endpoint exists; unclear if there is a dedicated screen | ⚠️ |

**Workflow Score: 6/9 Pass**  
**Critical Gaps:** No confirmation on process/recalculate. Export not integrated into attendance screen. No dedicated punch log screen found in file list.

---

### WF-04: Leave Management
**Routes:** `/leaves` → `/leaves/apply` → `/leaves/requests` → `/leaves/balance` → `/leaves/calendar` → `/leaves/types`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View leave dashboard | Stats + pending requests | `LeaveDashboardScreen` with stats (pending, approved, rejected) and filterable table | ✅ |
| 2 | Apply for leave | Select type + dates + reason | `LeaveApplyScreen` exists with leave type dropdown + date pickers + reason field | ✅ |
| 2a | View remaining balance before applying | Balance shown on form | Not shown on form; separate `/leaves/balance` screen only | ❌ |
| 2b | Duration shown dynamically | "You are applying for N days" | Not implemented | ❌ |
| 3 | Approve/reject leave requests | Inline action buttons | Present in `_LeaveRequestsTable`; no confirmation dialog | ⚠️ |
| 4 | View leave calendar | Visual calendar of approved leaves | `LeaveCalendarScreen` exists | ✅ |
| 5 | Manage leave types | Create/edit leave types | `LeaveTypesScreen` exists | ✅ |
| 6 | View leave balance | Per-employee balance | `LeaveBalanceScreen` exists at `/leaves/balance` | ✅ |
| 7 | Cancel an applied leave | Retract leave request | No cancel leave action found in router or screen list | ❌ |

**Workflow Score: 5/9 Pass**  
**Critical Gaps:** No balance on apply form. No leave cancellation flow. No duration feedback. No confirm on approve/reject.

---

### WF-05: Payroll
**Routes:** `/payroll` → `/payroll/salary-structures` → `/payroll/loans`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View payroll dashboard | Month selector + stats + payslip table | `PayrollDashboardScreen` with `_MonthSelector`, `_StatsGrid`, `_ActionRow`, `_PayslipsTable` | ✅ |
| 2 | Generate payroll | Trigger payroll generation for month | Action exists; no confirmation dialog | ⚠️ |
| 3 | View individual payslip | Payslip detail / download | Payslip list table exists; individual view/download unclear from structure | ⚠️ |
| 4 | Freeze payroll | Lock payroll for a month | `freeze()` method in `PayslipsNotifier`; UI affordance unclear | ⚠️ |
| 5 | View salary structures | Define pay components | `SalaryStructuresScreen` at `/payroll/salary-structures` | ✅ |
| 6 | Manage loans | Employee loan advances | `LoansScreen` at `/payroll/loans` | ✅ |
| 7 | Download payslip | PDF/Excel download | No download button found in `payroll_dashboard_screen.dart` structure; separate via Reports? | ❌ |
| 8 | Future month protection | Prevent generating for future months | Not implemented | ❌ |

**Workflow Score: 4/8 Pass**  
**Critical Gaps:** No payslip download. No future-month guard. No generation confirmation. Freeze payroll affordance unclear.

---

### WF-06: Reports
**Route:** `/reports`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View report categories | Grid of available reports | `_buildCategories()` renders a list of report type cards | ✅ |
| 2 | Select report type | Choose from available types | `_selectedType` state updated | ✅ |
| 3 | Configure date range | Select start/end or specific date | `_buildConfig()` with date picker | ✅ |
| 4 | Choose format (PDF/Excel) | Format selector | `_selectedFormat` state | ✅ |
| 5 | Download report | File downloaded to local device | Web: `dart:html` AnchorElement; non-web: `path_provider` | ⚠️ |
| 6 | View download history | See previous downloads | `_history` list in widget state — cleared on navigation | ⚠️ |
| 7 | Report description | Know what's in each report | No descriptions provided | ❌ |

**Workflow Score: 4/7 Pass**  
**Critical Gaps:** No report descriptions. Download history not persistent. `dart:html` only works on web.

---

## SCHOOL ERP WORKFLOWS

> **Critical Context:** All school routes are outside the ShellRoute. Navigation chrome (sidebar, topbar) is absent on ALL school screens except the school dashboard (which renders within the main `/dashboard` route via `DashboardScreen`'s `isSchool` check). This is a foundational issue affecting every school workflow below.

---

### WF-07: School Login
**Note:** School tenants use the same `/login` route as corporate. No school-specific login customization.

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Navigate to `/login` | Standard login form | Same as corporate login | ✅ |
| 2 | Login as school tenant admin | Redirected to school dashboard | `DashboardScreen` checks `user.isSchool` and renders `SchoolDashboardScreen` | ✅ |
| 3 | School dashboard loads with school stats | School-specific KPIs | `schoolStatsProvider` fetches stats; silent error returns `{}` | ⚠️ |
| 4 | Navigate to school modules via sidebar | School nav items in sidebar | Sidebar shows school nav items conditionally when `isSchool` | ✅ |

**Workflow Score: 3/4 Pass**  
**Critical Gap:** Silent stat failure shows all zeros with no feedback.

---

### WF-08: Admissions
**Route:** `/school/admissions` → `AdmissionScreen` (outside ShellRoute)

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View admissions screen | Tab view: Applications + Inquiries | `_tabCtrl` with 2 tabs; lists loaded from API | ✅ |
| 2 | Add new inquiry | Dialog form | `_showInquiryDialog()` exists | ✅ |
| 3 | Navigate back to school dashboard | Back button | No AppBar, no back button — trapped | ❌ |
| 4 | Convert inquiry to application | Workflow step | Not visible in code structure | ❌ |
| 5 | Navigation chrome present | Sidebar visible | No — outside ShellRoute | ❌ |

**Workflow Score: 2/5 Pass**

---

### WF-09: Student Management
**Routes:** `/school/students` → `/school/students/:id`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View student list | Searchable/filterable list | `StudentListScreen` exists (file exists in dir listing) | ⚠️ |
| 2 | View student detail | Tabs: Overview, Guardians, Attendance, Fees, Documents | `StudentDetailScreen` with 5-tab layout | ✅ |
| 3 | Edit student | Edit form via "Edit" button in AppBar | `context.go('/school/students/${widget.studentId}/edit')` | ❌ |
| 3a | Edit route exists in router | `/school/students/:id/edit` | Route NOT registered in router | ❌ |
| 4 | Navigate back | Back button in AppBar | `context.go('/school/students')` — present | ✅ |
| 5 | View guardians | Guardian tab | `_guardians` list loaded from API | ✅ |

**Workflow Score: 3/6 Pass**  
**Critical Gap:** Student edit route (`/school/students/:id/edit`) is NOT registered in the router — clicking Edit will crash.

---

### WF-10: School Attendance
**Route:** `/school/attendance/mark` → `AttendanceMarkScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Select grade | Dropdown of grades | `gradesProvider` loads grades | ✅ |
| 2 | Select section | Dropdown of sections for grade | `sectionsProvider.family` loads sections | ✅ |
| 3 | View students for section | Student list loads | `sectionStudentsProvider` loads students | ✅ |
| 4 | Mark attendance for each student | Present/Absent/Late/Half-day buttons | `_statusButton` for each status | ✅ |
| 5 | Quick mark all present | "Mark All Present" button | `_markAll()` method with quick action buttons | ✅ |
| 6 | Submit | POST to API | `_submitAttendance()` exists | ✅ |
| 7 | Navigate away with unsaved marks | Warning dialog | No unsaved-changes guard | ❌ |
| 8 | Navigation chrome | Back button / sidebar | Outside ShellRoute — no chrome; no AppBar with back | ❌ |

**Workflow Score: 6/8 Pass**  
**Note:** Functionally the best-implemented school screen. Main gaps: no unsaved-changes guard, no navigation chrome.

---

### WF-11: Fee Collection
**Route:** `/school/fees` → `FeeCollectionScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View fee payments + dues | Tab view | Two tabs: Payments + Dues | ✅ |
| 2 | Collect a fee payment | Full dialog: student, fee type, amount, mode | `_showCollectDialog` is only 6 lines — incomplete implementation | ❌ |
| 3 | Generate fee receipt | PDF receipt post-collection | Not implemented | ❌ |
| 4 | View outstanding dues | List of students with dues | `feeDuesProvider` loads dues list | ✅ |
| 5 | Navigation back | Back button | No AppBar — trapped | ❌ |
| 6 | Navigation chrome | Sidebar visible | Outside ShellRoute | ❌ |

**Workflow Score: 2/6 Pass**  
**Critical Gap:** Fee collection dialog is a placeholder. This workflow is not production-ready.

---

### WF-12: Examinations
**Route:** `/school/exams` → `ExamListScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View exam list | List of scheduled exams | `examsProvider` loads exam list | ✅ |
| 2 | Create new exam | Dialog with name + dates | `_showCreateDialog()` with `TextField` for name, start, end | ⚠️ |
| 2a | Date input in dialog | Date picker | Raw `TextField` used instead of date picker — user must type dates manually | ❌ |
| 3 | View exam details / marks entry | Drill into exam for marks | No drill-down from exam list | ❌ |
| 4 | Generate result sheet | Report generation | Not implemented | ❌ |
| 5 | Navigation chrome | Sidebar / back button | Outside ShellRoute — no chrome | ❌ |

**Workflow Score: 1/5 Pass**  
**Critical Gap:** Exam screen is a list with a create dialog only. No marks entry, no results, no detail view.

---

### WF-13: Timetable
**Route:** `/school/timetable` → `TimetableScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View timetable | Class-period-subject grid | `TimetableScreen` exists (6.0KB) | ⚠️ |
| 2 | Edit period entries | Assign teacher + subject to period | Unclear from static analysis | ⚠️ |
| 3 | Filter by class/section | Dropdown selectors | Likely present given screen size | ⚠️ |
| 4 | Navigation chrome | Sidebar / back | Outside ShellRoute | ❌ |

**Workflow Score: Insufficient data — unconfirmed pass/fail; navigation chrome failure confirmed.**

---

## ADMIN WORKFLOWS

---

### WF-14: Admin Login
**Route:** `/admin/login` → `AdminLoginScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | Navigate to `/admin/login` | Dark-themed admin login form | Renders correctly with dark background | ✅ |
| 2 | Pre-filled email | Blank email field | Email pre-filled with `admin@apexhrms.com` — credential exposure | ❌ |
| 3 | Login with valid super-admin credentials | Redirect to `/admin/dashboard` | `is_admin` stored in secure storage; redirect implemented | ✅ |
| 4 | Login failure message | Inline error | `_error` state displayed on form — inline, which is correct | ✅ |

**Workflow Score: 3/4 Pass**

---

### WF-15: Tenant Management
**Routes:** `/admin/tenants` → `/admin/tenants/:id`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View tenant list | List of all tenants with status | `adminTenantListProvider` fetches from `/admin/tenants/` | ✅ |
| 2 | Add new tenant | Dialog form with all required fields | `_showAddTenantDialog()` with form fields | ✅ |
| 3 | View tenant detail | 6-tab detail: Overview, Subscription, Limits, Features, Users, Audit | `AdminTenantDetailScreen` with TabController(length: 6) | ✅ |
| 4 | Suspend tenant | AppBar action → confirmation | `_suspendTenant()` with `showDialog<bool>` confirmation | ✅ |
| 5 | Activate tenant | AppBar action | Activate path (when tenant is suspended) exists | ⚠️ |
| 6 | Known syntax error at line 219 | Clean render | Pre-existing syntax error in the file | ❌ |
| 7 | Dark/light theme switch | Consistent theme | Tenant list is dark; tenant detail is light — jarring | ❌ |

**Workflow Score: 4/7 Pass**

---

### WF-16: Plans Management
**Route:** `/admin/plans` → `AdminPlanScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View plan list | Cards showing all subscription plans | `adminPlansProvider` + list of plan cards | ✅ |
| 2 | Create new plan | Dialog form | `_showPlanDialog(context, ref, null)` | ✅ |
| 3 | Edit plan | Pre-filled edit dialog | `_showPlanDialog(context, ref, p)` | ✅ |
| 4 | Clone plan | Duplicate plan | `_clonePlan()` exists | ✅ |
| 5 | Toggle active/inactive | Activate or deactivate plan | `_togglePlan()` exists | ✅ |
| 6 | Delete plan (irreversible) | Confirmation dialog | Not visible; deletion may be via toggle only | ⚠️ |

**Workflow Score: 5/6 Pass** — Best admin workflow.

---

### WF-17: Feature Assignment
**Route:** `/admin/features` → `AdminFeatureScreen`

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View feature flags | List of system features | `AdminFeatureScreen` exists (8.2KB) | ⚠️ |
| 2 | Assign features to a tenant | Per-tenant feature enable/disable | Also accessible via Tenant Detail → Features tab | ✅ |
| 3 | Consistent with tenant detail | Same flags shown in both places | Two entry points — potential sync confusion | ⚠️ |

---

### WF-18: Admin User Management
**Route:** Tenant Detail → Users tab

| Step | Action | Expected | Actual | Status |
|------|--------|----------|--------|--------|
| 1 | View tenant users | User list within a tenant | `_UsersTab` in `AdminTenantDetailScreen` | ✅ |
| 2 | No standalone user management route | `/admin/users` route | No standalone admin user route in router | ❌ |
| 3 | Manage super-admin users | Create/modify admin accounts | Not present; admin manages only tenant users | ⚠️ |

---

## Workflow Summary Table

| Workflow | Module | Pass Rate | Critical Gaps |
|----------|--------|-----------|---------------|
| WF-01: Corporate Login | Auth | 3/6 | No forgot password, no register link |
| WF-02: Employee Management | Corp | 5/10 | No step validation, no bulk import UI |
| WF-03: Attendance | Corp | 6/9 | No process confirmation |
| WF-04: Leave | Corp | 5/9 | No balance on form, no cancel flow |
| WF-05: Payroll | Corp | 4/8 | No payslip download, no future month guard |
| WF-06: Reports | Corp | 4/7 | No descriptions, non-persistent history |
| WF-07: School Login | School | 3/4 | Silent stat errors |
| WF-08: Admissions | School | 2/5 | No back nav, no inquiry→application flow |
| WF-09: Student Management | School | 3/6 | Edit route not registered |
| WF-10: School Attendance | School | 6/8 | No unsaved-changes guard |
| WF-11: Fee Collection | School | 2/6 | Incomplete implementation |
| WF-12: Examinations | School | 1/5 | No marks entry, raw text date input |
| WF-13: Timetable | School | Partial | No navigation chrome |
| WF-14: Admin Login | Admin | 3/4 | Pre-filled credentials |
| WF-15: Tenant Management | Admin | 4/7 | Syntax error, theme mismatch |
| WF-16: Plans | Admin | 5/6 | Best-implemented workflow |
| WF-17: Feature Assignment | Admin | Partial | Two entry points |
| WF-18: User Management | Admin | 2/3 | No standalone admin user route |

---

## Most Critical Unfinished Workflows (Before GA)

1. **School ERP shell navigation** — All school screens outside ShellRoute; users trapped on isolated screens.
2. **Student edit route** — `/school/students/:id/edit` not in router; clicking Edit crashes.
3. **Fee collection** — Placeholder implementation; core school revenue workflow broken.
4. **Exam marks entry** — No marks entry or results generation.
5. **ESS navigation** — No persistent navigation for employee self-service users.
6. **Employee wizard validation** — No per-step validation; submit-time errors only.
7. **Leave cancel flow** — Missing; no way to retract a submitted leave.
8. **Payslip download** — No in-app download from payroll screen.
9. **Forgot password** — No UI exists.
10. **Admin tenant list syntax error** — Known crash in admin core screen.
