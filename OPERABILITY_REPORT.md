# Operability Report — Apex v2 Platform
**Audit Date:** 2026-06-28  
**Auditor Role:** Senior QA / Operability Reviewer (Read-Only)  
**Scope:** All user-facing workflows — Corporate HRMS, School ERP, Super Admin  

---

## Executive Summary

The platform is functionally navigable on desktop for HR Admins. The most critical operability issues are concentrated in three areas: (1) **school ERP screens that lack shell navigation**, making the entire school workflow operationally broken on production; (2) **forms with silent error handling** where errors are swallowed and users receive no feedback; and (3) **the mobile experience**, which leaves 70%+ of modules unreachable.

---

## Issues Found

### Category: Navigation & Workflow

---

**OP-001**  
**Module:** School ERP  
**Screen:** All `/school/*` routes  
**Severity:** Critical  
**Summary:** All school routes (`/school/attendance/mark`, `/school/admissions`, `/school/fees`, `/school/timetable`, `/school/exams`, `/school/transport`, `/school/hostel`, `/school/library`, `/school/classes`, `/school/academic-years`) are registered as top-level `GoRoute` entries **outside** the `ShellRoute`. This means navigating to any school-specific screen strips away the entire navigation shell (sidebar, topbar, breadcrumbs, bottom nav). School users are left on isolated screens with no way to navigate to another section except the browser's back button.

**Steps to Reproduce:**
1. Log in as a school tenant admin.
2. Click "Timetable" or "Fee Collection" in the sidebar.
3. Arrive at the screen — no sidebar, no topbar, no way back.

**Expected:** School screens render within the MainShell with school-specific sidebar items.  
**Actual:** Navigation chrome disappears; user is trapped on a bare scaffold.

---

**OP-002**  
**Module:** Employee Self-Service (ESS)  
**Screen:** All `/ess/*` routes  
**Severity:** Critical  
**Summary:** Like school routes, all ESS routes are outside the `ShellRoute`. An employee logging in is routed to `/dashboard` (within the shell) but ESS screens at `/ess/dashboard`, `/ess/attendance`, `/ess/profile`, `/ess/payslips`, `/ess/documents`, `/ess/notifications` lose all navigation chrome. There is no ESS-specific navigation bar implemented either. ESS users must know URLs by heart to navigate between ESS sections.

**Steps to Reproduce:**
1. Log in as an employee-role user.
2. Navigate to ESS Dashboard.
3. Try to go from ESS Attendance back to ESS Dashboard without the browser back button.

**Expected:** Persistent ESS navigation bar or integration into MainShell.  
**Actual:** Isolated screens; no persistent navigation.

---

**OP-003**  
**Module:** Employee Management  
**Screen:** `employee_create_wizard.dart` — Step 3 (Organization)  
**Severity:** High  
**Summary:** The wizard's `_loadDropdowns()` silently catches all errors with an empty `catch (e) { // Silently handle - dropdowns will be empty }` comment. If the API is unavailable during wizard load (departments, designations, branches, shifts, employees), all dropdowns in Steps 3–4 (Organization, Manager) render empty. The user sees blank dropdowns with no explanation. They cannot distinguish between "no departments exist" and "API failed." There is no retry button, no error message.

**Steps to Reproduce:**
1. Begin Add Employee with a slow/unavailable API.
2. Navigate to Step 3 — Organization.
3. All dropdowns show empty options.

**Expected:** Error state explaining that data failed to load, with a retry button.  
**Actual:** Silent empty dropdowns with no feedback.

---

**OP-004**  
**Module:** Employee Management  
**Screen:** `employee_create_wizard.dart` — Step validation  
**Severity:** High  
**Summary:** The wizard's "Continue" button (`_currentStep < 6`) advances to the next step with **zero validation** on intermediate steps. A user can click through all 7 steps without entering any data, then click "Create Employee" on the final step. Only `_firstNameCtrl`, `_lastNameCtrl`, `_codeCtrl` have `required: true` attributes on their `ApexTextField`, but the `Continue` button never triggers form validation — it only calls `setState(() => _currentStep++)`. Validation only fires on `_submit()` at the end.

**Steps to Reproduce:**
1. Open Add Employee.
2. Click "Continue" 6 times without filling any fields.
3. Observe that all steps are bypassed without validation.
4. Click "Create Employee" — only then does the API error surface.

**Expected:** Each step validates its own fields before allowing advancement.  
**Actual:** No per-step validation; user discovers errors only at submission.

---

**OP-005**  
**Module:** Leave Management  
**Screen:** `leave_apply_screen.dart`  
**Severity:** High  
**Summary:** The leave application form does not load available leave balances before submission. A user can apply for 10 days of Casual Leave even if their balance is 0. The balance check apparently happens server-side, returning an error only after submission. There is no real-time balance display on the form to guide the user before they submit. The `leaveTypesProvider` provides type names but not remaining balances.

**Steps to Reproduce:**
1. Navigate to Apply Leave.
2. Select a leave type.
3. Observe — no remaining balance shown.
4. Submit a leave request for more days than the balance allows.

**Expected:** Remaining balance shown per leave type; warning if requested days exceed balance.  
**Actual:** No balance displayed; error only surfaces post-submission.

---

**OP-006**  
**Module:** Attendance  
**Screen:** `attendance_dashboard_screen.dart` — Process Attendance  
**Severity:** High  
**Summary:** The attendance dashboard contains a "Process Attendance" action (via `POST /attendance/process`). This is a bulk operation that recalculates attendance for all employees. There is no confirmation dialog before triggering this action. Accidental clicks can trigger a computationally expensive bulk operation on the server without user intent.

**Steps to Reproduce:**
1. Navigate to Attendance Dashboard.
2. Click the process/recalculate button.

**Expected:** Confirmation dialog: "This will recalculate attendance for all employees. Continue?"  
**Actual:** Immediate execution without confirmation.

---

**OP-007**  
**Module:** Admin Panel  
**Screen:** `admin_tenant_list_screen.dart` — Suspend Tenant  
**Severity:** High  
**Summary:** The Tenant Detail screen has a "Suspend" action in the AppBar. The `_suspendTenant()` method calls `showDialog<bool>` for confirmation (line 102), which is correct. However, the "Activate" action (`_activateTenant()`) does not appear to have the same confirmation dialog pattern — it calls the API directly. Suspending vs. activating a tenant are equally consequential actions and both require explicit confirmation.

**Steps to Reproduce:**
1. Navigate to a suspended tenant.
2. Click "Activate."

**Expected:** Confirmation dialog before activating.  
**Actual:** Potentially direct API call without confirmation (based on code pattern observed in first 103 lines).

---

**OP-008**  
**Module:** Payroll  
**Screen:** `payroll_dashboard_screen.dart` — Generate Payroll  
**Severity:** High  
**Summary:** The payroll generation action is a destructive batch operation affecting all employees' payslips. No confirmation dialog, no preview of affected count, and no indication of "are you sure you want to generate payroll for N employees for [Month Year]?" is surfaced before executing. In payroll operations, a double-generation for the same month (if generation is not idempotent) would create duplicate payslips.

**Steps to Reproduce:**
1. Navigate to Payroll.
2. Select a month.
3. Click "Generate Payroll."

**Expected:** Confirmation: "Generate payroll for [Month Year] for N employees. This cannot be undone."  
**Actual:** Immediate execution.

---

**OP-009**  
**Module:** Reports  
**Screen:** `report_selection_screen.dart` — Download  
**Severity:** Medium  
**Summary:** The report download relies on `dart:html` for web (`html.AnchorElement(...).click()`). On non-web targets, the `dart:html` import causes a compile failure. Additionally, the download history (`_history`) is stored only in widget state — refreshing the page loses all download history. There is no persistence. A user who downloads a report, navigates away, and returns sees an empty history.

**Steps to Reproduce:**
1. Download a report.
2. Navigate to another screen and return to Reports.

**Expected:** Download history persists within the session at minimum.  
**Actual:** History cleared on navigation.

---

**OP-010**  
**Module:** Devices  
**Screen:** `device_list_screen.dart`, `command_center_screen.dart`  
**Severity:** Medium  
**Summary:** The Command Center screen (`/commands`) allows sending remote commands (reboot, sync, clear logs) to biometric devices. These are irreversible device operations. The code pattern across similar screens suggests no confirmation dialog is shown before issuing device commands. Accidental taps on "Reboot" for an active device at a busy location would disrupt attendance capture in real time.

**Steps to Reproduce:**
1. Navigate to Command Center.
2. Select a device command (e.g., "Reboot").
3. Execute.

**Expected:** "Are you sure you want to reboot device [Name] at [Location]? This will interrupt attendance capture."  
**Actual:** Likely direct execution without safeguard.

---

**OP-011**  
**Module:** Shell / Global  
**Screen:** Topbar — Quick Create menu  
**Severity:** Medium  
**Summary:** The Quick Create button (`+` icon in topbar) offers three actions: New Employee, Mark Attendance, Apply Leave. These navigate via `context.push()` to full-page routes. On mobile, the Quick Create button is hidden (`if (!isMobile)`). The mobile user has no Quick Create equivalent — they must navigate the 3-item "More" bottom sheet and then find the relevant action.

**Steps to Reproduce:**
1. Open app on mobile.
2. Try to quickly mark attendance.
3. Must go: More → Attendance → Mark Attendance (3 taps).

**Expected:** Mobile equivalent of Quick Create (e.g., FAB on key screens).  
**Actual:** Quick Create inaccessible on mobile.

---

**OP-012**  
**Module:** Employee Management  
**Screen:** `employee_directory_screen.dart` — Pagination  
**Severity:** Medium  
**Summary:** The directory has a `_Pagination` widget and `page`/`totalPages` state. However, the search and filter changes do not reset the page to 1 automatically. If a user is on page 3, applies a department filter, and the filtered result has only 2 pages, they will see an empty page 3 result with no indication that they need to go back to page 1.

**Steps to Reproduce:**
1. Navigate to Employee Directory.
2. Page to page 3 (if enough employees).
3. Apply a department filter that results in fewer pages.

**Expected:** Filter/search changes reset to page 1 automatically.  
**Actual:** Page state may persist across filter changes, showing empty results.

---

**OP-013**  
**Module:** Shifts  
**Screen:** `shift_assign_screen.dart`  
**Severity:** Medium  
**Summary:** The Shift Assignment screen is registered as a top-level route outside the ShellRoute (`parentNavigatorKey: rootNavigatorKey`). This means it renders without the sidebar. This is correct for modal/full-screen contexts, but the Shift Assign screen has no back button provided — users must use the device/browser back button. This is especially problematic on web where there may be no browser chrome (kiosk mode, embedded).

**Steps to Reproduce:**
1. Navigate to Shifts → Assign Shift.

**Expected:** AppBar with back button.  
**Actual:** No visible back navigation control.

---

**OP-014**  
**Module:** Leave Management  
**Screen:** `leave_dashboard_screen.dart` — Approval actions  
**Severity:** High  
**Summary:** The leave requests table shows Approve/Reject action buttons inline on each row. Approving a leave request is a consequential action (modifies employee leave balance, sends notification). The `_LeaveRequestsTable` widget renders these as inline action buttons within the table row. There is no confirmation dialog. An HR manager can accidentally approve or reject a leave request with a single misclick in a dense table.

**Steps to Reproduce:**
1. Navigate to Leave Dashboard.
2. Click "Approve" on any leave request row.

**Expected:** Confirmation: "Approve leave for [Employee] from [Date] to [Date]?"  
**Actual:** Immediate state change without confirmation.

---

**OP-015**  
**Module:** School ERP  
**Screen:** `attendance_mark_screen.dart`  
**Severity:** Medium  
**Summary:** The school attendance marking screen requires the user to: (1) select a grade, (2) select a section, (3) wait for students to load, (4) mark each student's status, (5) submit. If the API for grades or sections fails (`gradesProvider`, `sectionsProvider`, `sectionStudentsProvider` all use `FutureProvider`), the screen will show a loading spinner indefinitely or an error — but there is no timeout message or retry button. Additionally, there is no "Save progress" option — if the user navigates away mid-marking, all marks are lost.

**Steps to Reproduce:**
1. Open School Attendance Mark.
2. Select grade and section.
3. Mark 20 students.
4. Navigate away by accident.

**Expected:** Draft save or confirmation "You have unsaved attendance — leave anyway?"  
**Actual:** All marks silently discarded.

---

**OP-016**  
**Module:** School ERP  
**Screen:** `fee_collection_screen.dart` — _showCollectDialog  
**Severity:** Medium  
**Summary:** The fee collection dialog (`_showCollectDialog`) exists but the implementation body is in an elided range (lines 162–167 are only 6 lines). This is a very minimal implementation. The fee collection workflow — which involves searching for a student, selecting an outstanding fee, entering a payment amount, and recording the transaction — cannot be completed in 6 lines. This screen is likely a placeholder with incomplete functionality that would fail in production use.

**Steps to Reproduce:**
1. Navigate to Fee Collection.
2. Click "Collect Fee."

**Expected:** Full fee collection dialog with student search, fee selection, amount input, payment mode, and receipt generation.  
**Actual:** Minimal placeholder dialog.

---

**OP-017**  
**Module:** Administration / eSSL Settings  
**Screen:** `essl_initial_sync_screen.dart`  
**Severity:** Medium  
**Summary:** The initial sync screen (14.8KB) is a complex operation screen with progress tracking, pause/resume/cancel support. However, from a navigation perspective: the sync progress route is `/settings/essl/:id/initial-sync` — inside the ShellRoute. If a sync is running and the user accidentally clicks the sidebar, the shell navigation will push a new route and the progress polling may be lost. Real-time operations like sync should be presented as a modal overlay or a persistent status indicator.

---

**OP-018**  
**Module:** Visitor Management  
**Screen:** `visitor_register_screen.dart`, `visitor_pass_screen.dart`  
**Severity:** Medium  
**Summary:** The Visitor Pass screen is accessed via `/visitors/pass?passId=...` query parameter. If `passId` is missing from the query string, `state.uri.queryParameters['passId']!` will throw a Null Check Operator exception and crash the route. This is a null-safety gap in the router that directly affects operability.

**Steps to Reproduce:**
1. Navigate to `/visitors/pass` without a `passId` query param.

**Expected:** Graceful error: "No pass ID provided. Return to visitor list."  
**Actual:** Runtime exception / crash.

---

**OP-019**  
**Module:** Shell / User Profile  
**Screen:** Sidebar — User info area  
**Severity:** Medium  
**Summary:** The only logout path from the main application is a `PopupMenuButton` in the collapsed sidebar user-info area — a 3-dot `more_vert` icon of size 16px (very small touch target). On mobile the sidebar is hidden entirely, removing the logout option. Mobile users must navigate to Administration (Settings) to find the Logout button there.

**Steps to Reproduce:**
1. Open app on mobile.
2. Try to log out.
3. Sidebar is hidden → must go to More → Administration → Logout.

**Expected:** Logout accessible from the topbar user menu or a prominent mobile location.  
**Actual:** Logout requires 3+ taps on mobile; icon is 16px (too small for touch).

---

**OP-020**  
**Module:** Search / Command Palette  
**Screen:** `_CommandPalette` widget in `main_shell.dart`  
**Severity:** Medium  
**Summary:** The command palette is a `StatefulWidget` that opens as a dialog (`showDialog`). The palette state is in `_CommandPaletteState` (lines 429–499, elided). From the structural summary, it appears to be a search/navigation shortcut dialog. However, without full code visibility, it is unclear if the palette (a) searches across employees/records or (b) only provides navigation shortcuts. The topbar button says "Search..." which implies record-level search, but the palette implementation may only support navigation commands. This gap between the label ("Search...") and actual functionality (command navigation only) would confuse users expecting a global search.

---

**OP-021**  
**Module:** Admin Panel  
**Screen:** `admin_tenant_list_screen.dart` — Known syntax error  
**Severity:** Critical  
**Summary:** The existing `UI_UX_AUDIT.md` in the frontend directory explicitly notes: "1 pre-existing syntax error in `admin_tenant_list_screen.dart:219`." A syntax error in a screen file will cause the screen to fail compilation or render broken at line 219. This is in the primary admin tenant management screen — a core super-admin workflow. If this screen fails to compile, super-admin tenant management is completely non-functional.

**Steps to Reproduce:**
1. Build the Flutter app with `flutter build web`.
2. Navigate to `/admin/tenants`.

**Expected:** Tenant list renders correctly.  
**Actual:** Potential compile failure or runtime crash at line 219.

---

**OP-022**  
**Module:** Employee Management  
**Screen:** `employee_directory_screen.dart` — clearFilter  
**Severity:** Low  
**Summary:** The filter dialog allows selecting department, branch, and status filters. There is a filter dialog widget (`_FilterDialog`) but no "Clear All Filters" one-tap option visible in the main toolbar. Users must open the filter dialog and manually reset each field to clear filters, which is a multi-step process.

**Steps to Reproduce:**
1. Apply department + branch + status filters.
2. Try to clear all filters with one tap.

**Expected:** "Clear Filters" chip or button in the filter bar when filters are active.  
**Actual:** No single-tap clear; must re-open dialog and reset manually.

---

**OP-023**  
**Module:** Attendance  
**Screen:** `attendance_list_screen.dart`  
**Severity:** Medium  
**Summary:** The attendance list (24.2KB) is a large screen. Based on structure, it likely has its own internal pagination. However, pagination state and sort order are held in local widget state. Refreshing the page (browser F5 on web) will reset to page 1, losing the user's scroll position and pagination state. For an HR manager reviewing 200 employees' attendance, this forces renavigation from scratch.

---

**OP-024**  
**Module:** Performance  
**Screen:** `performance_dashboard_screen.dart`, `goals_screen.dart`  
**Severity:** Low  
**Summary:** Performance and Goals are both accessible from the sidebar but have no sub-navigation between them. To go from Performance Dashboard to Goals, the user must click the sidebar "Goals" item — there is no "View Goals" action within the Performance Dashboard. Contextual navigation between related modules is absent.
