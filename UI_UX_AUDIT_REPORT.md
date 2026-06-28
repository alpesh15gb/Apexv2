# UI/UX Audit Report — Apex v2 Platform
**Audit Date:** 2026-06-28  
**Auditor Role:** Senior QA / UX Researcher (Read-Only)  
**Scope:** Flutter Web frontend — Corporate HRMS + School ERP + Super Admin  
**Method:** Static code analysis of all screen files, widget library, design system, navigation graph, and router configuration.

---

## Executive Summary

The platform has a coherent design system (`ApexColors`, `ApexTypography`, `ApexSpacing`, `ApexRadius`) and a well-structured component library. The global shell (sidebar + topbar + breadcrumbs + mobile bottom nav) is architecturally sound. However, a significant number of UI/UX issues were found — particularly around **tablet/mid-width breakpoints**, **navigation hierarchy inconsistencies**, **missing confirmation dialogs**, **credential exposure**, **form validation gaps**, and **school ERP screens that are functionally shells** with no navigation back-path.

---

## Issues Found

### Category 1: Layout & Responsive Design

---

**UX-001**  
**Module:** Shell / Global  
**Screen:** All screens (600px – 1200px tablet range)  
**Severity:** High  
**Summary:** No tablet-specific layout. The `Responsive` utility defines three breakpoints (mobile <600, tablet 600–1200, desktop ≥1200), but the sidebar is suppressed only on mobile (<600px). On a 900px tablet, the full 240px sidebar renders alongside content, leaving the content area only ~660px — severe layout squeeze on data-heavy tables (attendance, employee list, payroll).

**Steps to Reproduce:**
1. Open app on a 900px-wide viewport (tablet).
2. Navigate to Attendance, Employee List, or Payroll.

**Expected:** Sidebar collapses to icon-only (64px) or slides off-canvas automatically at <1200px.  
**Actual:** Full 240px sidebar renders; tables overflow or become unreadable.

---

**UX-002**  
**Module:** Shell / Navigation  
**Screen:** All screens — mobile bottom nav  
**Severity:** High  
**Summary:** Mobile bottom navigation only exposes 4 destinations: Dashboard, Employees, Attendance, and "More" (a bottom sheet). The "More" sheet lists only 5 items: Leave, Visitors, Devices, Reports, Administration. Payroll, Announcements, Holidays, Shifts, OT Register, ESS, Recruitment, Performance, Assets, Travel, and Exit Requests are **unreachable from mobile** without knowing deep URL paths. There is no mobile drawer, no hamburger menu, and no fallback.

**Steps to Reproduce:**
1. Open app on a device with <600px width.
2. Tap "More" in the bottom nav.
3. Try to navigate to Payroll, Holidays, ESS, or Recruitment.

**Expected:** Full module access from mobile.  
**Actual:** ~70% of modules are unreachable on mobile.

---

**UX-003**  
**Module:** Employee Management  
**Screen:** `employee_directory_screen.dart` — Grid & Table toggle  
**Severity:** Medium  
**Summary:** The screen defaults to `ViewMode.table`. On mobile, the data table renders with fixed column widths and no horizontal scroll wrapper confirmed in the directory. Multi-column tables (employee code, name, dept, designation, branch, status, actions) will overflow the viewport on screens <600px.

**Steps to Reproduce:**
1. Open Employee Directory on mobile.
2. Observe the table layout.

**Expected:** Table collapses to a card list automatically on mobile, or horizontal scroll is enabled.  
**Actual:** Table potentially overflows horizontally; no mobile-specific layout toggle is forced.

---

**UX-004**  
**Module:** Employee Management  
**Screen:** `employee_create_wizard.dart` — Step Indicator  
**Severity:** Medium  
**Summary:** The 7-step wizard uses a top horizontal progress bar where step labels are only shown on non-mobile (`if (!Responsive.isMobile(context))`). On mobile, only 7 numbered circles appear without labels, and the connecting lines between circles share `Expanded` space with the step circle itself — at narrow widths this causes circles to be pushed very close together or truncated.

**Steps to Reproduce:**
1. Open Add Employee on mobile.
2. Observe the step indicator bar.

**Expected:** Step indicator clearly communicates current step even on mobile (label below circle, or step n of 7 text).  
**Actual:** Unlabelled circles only; usability severely reduced for first-time users.

---

**UX-005**  
**Module:** Admin Panel  
**Screen:** `admin_tenant_list_screen.dart`  
**Severity:** High  
**Summary:** Admin panel uses `ApexColors.darkBackground` (a near-black `#0F172A`) as the scaffold background. The rest of the admin section (`admin_tenant_detail_screen`, `admin_plan_screen`, `admin_feature_screen`) switches back to `ApexColors.neutral50` (near-white). This creates a jarring theme mismatch — the Tenant List is dark, every other admin screen is light. There is no intentional dark mode toggle; the admin login screen is also dark. This produces an inconsistent visual identity within the same user journey.

**Steps to Reproduce:**
1. Log in as Super Admin.
2. Navigate to Tenant Management.
3. Click any tenant row to view its detail.

**Expected:** Consistent visual theme throughout admin panel.  
**Actual:** Dark → Light theme switch on every drill-down.

---

**UX-006**  
**Module:** Admin Panel  
**Screen:** `admin_login_screen.dart`  
**Severity:** Medium  
**Summary:** The admin login form has the email field **pre-filled** with `admin@apexhrms.com` as a default value in the `TextEditingController`. While useful for development, this is a security-adjacent UX issue: it reveals the super admin email to anyone who opens the URL, and on production it will pre-populate sensitive credentials.

**Steps to Reproduce:**
1. Navigate to `/admin/login`.
2. Observe the email field.

**Expected:** Blank email field.  
**Actual:** Pre-filled `admin@apexhrms.com`.

---

**UX-007**  
**Module:** Employee Management  
**Screen:** `employee_create_wizard.dart` — Review Step  
**Severity:** High  
**Summary:** The Review step (Step 7) displays "Auto-Generated Credentials" showing the employee's username and **temporary password** (both equal to the employee code) in plain text on screen. This is displayed in a visible card within the review step, before any employee has actually been created. Any screen recording, screenshare, or shoulder-surfer can read these credentials. Additionally, there is no copy/mask toggle.

**Steps to Reproduce:**
1. Navigate to Add Employee.
2. Fill Employee Code field (e.g., `EMP001`).
3. Advance to the Review step (Step 7).

**Expected:** Credentials shown post-creation, ideally with a copy-button and a mask toggle.  
**Actual:** Plain-text password visible on the review card before submission.

---

**UX-008**  
**Module:** Shell / Navigation  
**Screen:** All screens — breadcrumb component  
**Severity:** Medium  
**Summary:** Breadcrumbs are generated by splitting the current URL path on `/` and capitalising each segment. This produces raw URL-segment text as breadcrumb labels. For example:
- `/attendance/outdoor-duty` → `Home > Attendance > Outdoor-duty`
- `/settings/essl` → `Home > Settings > Essl`
- `/settings/tenant-settings` → `Home > Settings > Tenant-settings`
- `/shift-groups` → `Home > Shift-groups`

Hyphens in route slugs appear directly in breadcrumbs. Proper noun rendering is absent.

**Steps to Reproduce:**
1. Navigate to any multi-segment route with hyphens.
2. Observe the breadcrumb bar in the top bar.

**Expected:** Human-readable labels (e.g., "Outdoor Duty", "eSSL Servers", "Shift Groups").  
**Actual:** Raw URL slugs with hyphens.

---

**UX-009**  
**Module:** Shell / Navigation  
**Screen:** Sidebar  
**Severity:** Medium  
**Summary:** The sidebar `_isActive()` check uses `startsWith('$path/')`, which means `/attendance` highlights the Attendance nav item for all sub-routes including `/attendance/outdoor-duty` and `/attendance/regularization`. However, the Outdoor Duty and OT Register items are in the OPERATIONS section, NOT under the Attendance section. When a user is on `/attendance/outdoor-duty`, both the "Attendance" item (WORKSPACE section) and the "Outdoor Duty" item (OPERATIONS section) will visually appear active simultaneously.

**Steps to Reproduce:**
1. Navigate to Outdoor Duty (`/attendance/outdoor-duty`).
2. Observe the sidebar.

**Expected:** Only "Outdoor Duty" is highlighted.  
**Actual:** Both "Attendance" and "Outdoor Duty" appear active.

---

**UX-010**  
**Module:** School ERP  
**Screen:** `admission_screen.dart`, `fee_collection_screen.dart`, `exam_list_screen.dart`  
**Severity:** High  
**Summary:** School screens use a `Scaffold` with a `Column` header and `TabBarView` body, but **no AppBar is defined**. There is no back-navigation button. When a user navigates to `/school/admissions`, `/school/fees`, or `/school/exams`, they cannot return to the school dashboard or any prior screen without the browser back button. The mobile bottom nav does not show school-specific items. These screens are effectively navigation dead ends.

**Steps to Reproduce:**
1. Log in as a school tenant user.
2. Tap any School section item (Admissions, Fee Collection, Examinations).
3. Try to go back.

**Expected:** Visible back button or AppBar with back navigation.  
**Actual:** No AppBar, no back button; trapped on the screen.

---

**UX-011**  
**Module:** School ERP  
**Screen:** All school screens — sidebar navigation  
**Severity:** High  
**Summary:** School screens (`/school/*`) are registered as top-level `GoRoute` entries outside the `ShellRoute`. This means they render WITHOUT the MainShell (sidebar + topbar + breadcrumbs). School users who navigate to school screens lose the entire navigation chrome. The sidebar, command palette, notifications button, and quick-create button all disappear. Only the school dashboard route resolves correctly only if it redirects as part of the main `/dashboard`.

**Steps to Reproduce:**
1. Log in as a school tenant.
2. Navigate to any school-specific route (e.g., `/school/timetable`).

**Expected:** Sidebar with school nav items, topbar, breadcrumbs.  
**Actual:** Bare scaffold with no navigation chrome.

---

**UX-012**  
**Module:** Payroll  
**Screen:** `payroll_dashboard_screen.dart` — Month Selector  
**Severity:** Medium  
**Summary:** The month selector uses a `Row` with left/right chevron buttons and a centered month/year display. There is no visual affordance for which direction is "past" and which is "future" (e.g., no disabled state for future months beyond the current). An HR manager could inadvertently generate payroll for a future month without any warning or confirmation.

**Steps to Reproduce:**
1. Navigate to Payroll.
2. Click the right arrow to advance to a future month.
3. Click "Generate Payroll."

**Expected:** Future months are disabled or show a warning ("You are generating payroll for a future period").  
**Actual:** No restriction or warning on future month selection.

---

**UX-013**  
**Module:** Reports  
**Screen:** `report_selection_screen.dart`  
**Severity:** Medium  
**Summary:** The report screen imports `dart:html` at line 8 for web-specific file download handling. On non-web targets, this import will cause a compile error. More importantly from a UX perspective: the `_selectedFormat` defaults to `'pdf'` but the available formats offered in the config section are not consistently previewed. If the user changes format but not the download type, the file extension in `_getFilename()` may mismatch the actual output. No preview or description of what each report type contains is offered.

**Steps to Reproduce:**
1. Navigate to Reports.
2. Select a report type.
3. Note there is no description of what data the report contains.

**Expected:** Brief description of each report type, expected columns/fields, and typical use case.  
**Actual:** Report type names only (e.g., "Daily Attendance", "Monthly Summary") without any content description.

---

**UX-014**  
**Module:** Leave Management  
**Screen:** `leave_apply_screen.dart`  
**Severity:** Medium  
**Summary:** The Leave Apply form has a `_endDate` defaulting to `DateTime.now().add(Duration(days: 1))`, meaning leave applications always default to a 2-day duration. There is no visible day count ("You are applying for X days") shown dynamically as start/end dates are changed. The user must mentally calculate the leave duration.

**Steps to Reproduce:**
1. Navigate to Apply Leave.
2. Change the start date.
3. Observe — no live day count shown.

**Expected:** "Duration: 3 days" dynamically updated as dates change.  
**Actual:** No duration feedback.

---

**UX-015**  
**Module:** Attendance  
**Screen:** `attendance_dashboard_screen.dart` — Date Picker  
**Severity:** Low  
**Summary:** The attendance dashboard has a date picker to switch between dates. However, on the attendance list, the date displayed in the filter bar is formatted as `yyyy-MM-dd` (ISO format) which is unfamiliar to most non-technical users. Business users expect `DD MMM YYYY` (e.g., "28 Jun 2026").

**Steps to Reproduce:**
1. Navigate to Attendance Dashboard.
2. Observe the date display in the filter/date bar.

**Expected:** "28 Jun 2026" or localised date format.  
**Actual:** `2026-06-28` raw ISO format.

---

**UX-016**  
**Module:** Employee Self-Service (ESS)  
**Screen:** ESS routes (e.g., `/ess/dashboard`, `/ess/attendance`, `/ess/profile`)  
**Severity:** High  
**Summary:** All ESS routes are registered as top-level `GoRoute` entries OUTSIDE the `ShellRoute`. This means ESS users navigate without any sidebar, topbar, or breadcrumbs — the navigation chrome completely disappears. There is also no dedicated ESS nav bar implemented (no bottom nav for ESS users, no hamburger menu). ESS screens are effectively isolated islands with no persistent navigation.

**Steps to Reproduce:**
1. Navigate to `/ess/dashboard`.
2. Observe — no sidebar, no topbar, no breadcrumbs.
3. Try to navigate to another ESS screen without knowing the URL.

**Expected:** ESS-specific nav bar or equivalent persistent navigation.  
**Actual:** Isolated screens with no navigation chrome.

---

**UX-017**  
**Module:** Administration / Settings  
**Screen:** `settings_screen.dart`  
**Severity:** Medium  
**Summary:** The Settings screen is titled "Administration" in the AppBar (`title: const Text('Administration')`), but the sidebar nav item label is also "Administration." The screen is a link-list hub that redirects to other screens — it is not a settings screen in the traditional sense. The page contains 6+ groups of items (SYSTEM, ORGANIZATION, ATTENDANCE, HR, FINANCE, SECURITY) mixing config items (Departments, Shifts) with transactional items (Documents, Exit Requests, Company Assets, Announcements, Travel Requests). Transactional modules should not live inside an Administration/Settings screen.

**Steps to Reproduce:**
1. Click "Administration" in the sidebar.
2. Observe "Company Assets," "Travel Requests," "Announcements" under HR section.

**Expected:** Administration contains only configuration and system-level settings.  
**Actual:** Transactional features (Assets, Travel, Exit Requests, Announcements) mixed with settings.

---

**UX-018**  
**Module:** Shell / Command Palette  
**Screen:** Command Palette (`_CommandPalette` widget)  
**Severity:** Medium  
**Summary:** The command palette (⌘K) is only visible on the desktop topbar (`if (!isMobile)`). Mobile users have no access to the command palette shortcut. Additionally, the keyboard shortcut `⌘K` displayed in the topbar button is a macOS shortcut — on Windows/Linux it would be `Ctrl+K`. No platform-specific shortcut label adaptation is present.

**Steps to Reproduce:**
1. Open app on Windows in a browser.
2. Observe the topbar shows `⌘K`.

**Expected:** `Ctrl+K` on Windows/Linux, `⌘K` on macOS.  
**Actual:** Always shows `⌘K` regardless of platform.

---

**UX-019**  
**Module:** Shift Management  
**Screen:** `shift_create_screen.dart`, `shift_management_screen.dart`  
**Severity:** Low  
**Summary:** Shifts, Shift Groups, Shift Rosters, and Department Shifts are split across 4 different screens reached from 2 different navigation paths (sidebar OPERATIONS section, and Administration Settings ORGANIZATION section). A user can navigate to Shifts from the sidebar and from Settings → Shifts. Both lead to the same screen, creating duplicate navigation paths that may confuse users about the canonical location of this feature.

**Steps to Reproduce:**
1. Click "Shifts" in the OPERATIONS sidebar section → `/shifts`.
2. Click "Administration" → "Shifts" → `/shifts`.

**Expected:** Single, canonical navigation path.  
**Actual:** Two identical paths to the same screen.

---

**UX-020**  
**Module:** Employee Management  
**Screen:** `employee_list_screen.dart` vs `employee_directory_screen.dart`  
**Severity:** High  
**Summary:** There are **two separate employee listing screens**: `employee_list_screen.dart` (with bulk selection, a `_BulkBar`, filter chips, and `_EmployeeTable`) and `employee_directory_screen.dart` (with grid/table toggle, pagination, department/branch/status filters, and a different layout). The sidebar navigates to `/employees` which loads `EmployeeDirectoryScreen`. But `EmployeeListScreen` exists and is a separate widget never registered in the router at all — it is a ghost screen. This constitutes dead code that inflates bundle size, confuses maintainers, and may have been an intended replacement for the directory.

**Steps to Reproduce:**
1. Check router — `/employees` → `EmployeeDirectoryScreen`.
2. `employee_list_screen.dart` exists but has no route registration.

**Expected:** One canonical employee listing screen.  
**Actual:** Two parallel implementations; one is orphaned.

---

**UX-021**  
**Module:** Payroll  
**Screen:** `payroll_screen.dart` vs `payroll_dashboard_screen.dart`  
**Severity:** Medium  
**Summary:** Similar to the employee screen duplication: `payroll_screen.dart` exists as a full-featured `PayrollScreen` widget with `PayslipItem` model, `PayslipListNotifier`, and a tab layout. Meanwhile `payroll_dashboard_screen.dart` is separately registered at `/payroll`. The `payroll_screen.dart` has no route registration. Again, a duplicate/orphaned screen.

**Steps to Reproduce:**
1. Check router — `/payroll` → `PayrollDashboardScreen`.
2. `payroll_screen.dart` has no route entry.

**Expected:** One canonical payroll screen.  
**Actual:** Two parallel implementations; one unreachable.

---

**UX-022**  
**Module:** Design System  
**Screen:** Global — Typography  
**Severity:** Low  
**Summary:** `ApexTypography` defines both a clean semantic hierarchy (`pageTitle`, `sectionTitle`, `cardTitle`, `body`, `caption`, etc.) AND a set of legacy aliases (`headingLarge`, `headingMedium`, `titleLarge`, `titleMedium`, `bodyMedium`, `bodySmall`, `captionLarge`, `captionMedium`, `captionSmall`, `buttonLarge`, `buttonMedium`, `buttonSmall`, `displayLarge`, `displayMedium`). Having 20+ named text styles for what is semantically a 7-style hierarchy creates confusion. Additionally, `bodyMedium` = `body` and `bodySmall` = `caption`, which means the same visual style has two names throughout the codebase — leading to inconsistent usage.

---

**UX-023**  
**Module:** Notifications  
**Screen:** `notification_center_screen.dart`, `notification_list_screen.dart`  
**Severity:** Medium  
**Summary:** Two separate notification screens exist: `/notifications` (shell route → `NotificationListScreen`) and a notification center push route from the topbar button (`context.push('/notifications')`). Additionally, a `notification_center_screen.dart` file exists in `screens/system/`. This creates ambiguity about which screen is the "real" notification center. The notification bell in the topbar has no badge count visible — unread count is not surfaced.

**Steps to Reproduce:**
1. Observe topbar notification bell — no unread count badge.
2. Check both notification screen files for duplication.

**Expected:** Single notification screen, badge count on bell icon.  
**Actual:** Two notification screen files; no unread badge.

---

**UX-024**  
**Module:** Access Control  
**Screen:** `zone_list_screen.dart`, `door_list_screen.dart`, `access_logs_screen.dart`  
**Severity:** Medium  
**Summary:** Access Control has three sub-screens (Zones, Doors, Access Logs) reached only through Administration → Access Control, Access Doors, Access Logs — three separate settings items. There is no unified Access Control hub screen or tab container. Users must return to Settings to switch between zones, doors, and logs — 3 extra clicks per context switch.

---

**UX-025**  
**Module:** School ERP  
**Screen:** `school_dashboard_screen.dart`  
**Severity:** Medium  
**Summary:** The school dashboard's `_QuickActions` component renders a `Wrap` of action chips. Each chip navigates to a school route. However, `schoolStatsProvider` silently catches all errors and returns `{}` — the dashboard will render with all stats showing as null/zero without any error feedback to the user. The `_StatsGrid` accesses `stats['total_students']`, `stats['today_present']`, etc. without null-safe defaults. If the API is down or slow, the dashboard shows "0" everywhere.

**Steps to Reproduce:**
1. Log in as a school tenant.
2. Navigate to School Dashboard with a slow/unavailable API.

**Expected:** Error state or loading indicator on stat cards.  
**Actual:** Stats silently display as 0 or null-cast values.

---

**UX-026**  
**Module:** Admin Panel  
**Screen:** `admin_tenant_detail_screen.dart` — "Tenant not found" error state  
**Severity:** Low  
**Summary:** When a tenant fails to load (`_tenant == null` after loading), the screen renders `const Scaffold(body: Center(child: Text('Tenant not found')))` — a bare white screen with plain text. There is no Back button, no retry option, no error icon, and the AppBar is completely absent. The user is trapped.

**Steps to Reproduce:**
1. Navigate to `/admin/tenants/nonexistent-id`.

**Expected:** Error state with a back button and retry action.  
**Actual:** Bare text on white scaffold with no navigation escape.

---

**UX-027**  
**Module:** Global  
**Screen:** `splash_screen.dart`  
**Severity:** Low  
**Summary:** The splash screen has a timed delay before routing. If the stored token is present but expired, the user is routed to `/dashboard` by the redirect logic (which only checks token presence, not validity), then immediately receives a 401 and is redirected to `/login`. This produces a flash of the dashboard before the login redirect — a jarring experience.

---

**UX-028**  
**Module:** Employee Self-Service  
**Screen:** `ess_leave_screen.dart`  
**Severity:** Medium  
**Summary:** ESS screens for leave, profile, payslips, and documents are registered at `/ess/*` paths outside the ShellRoute. However, ESS documents (`/ess/documents`) and ESS notifications (`/ess/notifications`) load `EssDocumentScreen` and `EssNotificationScreen` — both import from screen files that may overlap in content with HR screens (`document_screen.dart` in `hr/`). The ESS experience has no persistent navigation, making deep-linking confusing.

---

**UX-029**  
**Module:** Design System  
**Screen:** Global — Dark Mode  
**Severity:** Low  
**Summary:** The theme file defines a `darkTheme` (lines 98–185, elided), but there is no dark mode toggle anywhere in the UI — not in Settings, not in the user profile menu, and not in the topbar. The `isDark` variable is derived from `Theme.of(context).brightness`, which follows system brightness. On systems set to dark mode, the light sidebar/topbar components will render in dark mode correctly, but some screens hardcode `Colors.white` or `backgroundColor: Colors.white` (e.g., `leave_apply_screen.dart` AppBar, `employee_create_wizard.dart` AppBar, step indicator) — these will not respect the dark theme.

**Steps to Reproduce:**
1. Set device/browser to dark mode.
2. Navigate to Apply Leave or Add Employee.

**Expected:** Full dark mode support.  
**Actual:** Hardcoded `Colors.white` backgrounds ignore system dark mode.
