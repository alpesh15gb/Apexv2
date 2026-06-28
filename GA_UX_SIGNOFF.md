# GA UX Sign-Off — Apex HRMS v2

**Date**: 2026-06-28
**Reviewer**: Independent UX Review Agent
**Sprint**: T15 — UI/UX Polish

---

## Executive Summary

Sprint T15 delivered the core structural changes needed for GA: School ERP and ESS routes are now inside `ShellRoute`, giving them the standard sidebar/topbar chrome. The fee collection workflow is complete with a 4-step guided dialog. Loading, empty, and error states are applied across 30+ screens. No hardcoded admin credentials remain.

**However, two functional gaps prevent a clean GA sign-off:**

1. **3 broken quick-action routes** in the School Dashboard and Student List navigate to non-existent paths.
2. **Mobile users cannot reach School or ESS modules** — the bottom nav omits them entirely, and the sidebar (where they live) is hidden on mobile.

---

## GA Blocker Status

| # | Blocker | Status | Notes |
|---|---------|--------|-------|
| 1 | School routes in ShellRoute | **RESOLVED** | All 14 school routes nested inside ShellRoute (router.dart:488-549). Sidebar nav visible for `isSchool` users. |
| 2 | ESS routes in ShellRoute | **RESOLVED** | All 7 ESS routes nested inside ShellRoute (router.dart:455-487). |
| 3 | Student edit route | **RESOLVED** | `/school/students/:id/edit` route exists (router.dart:501-504). Full form with validation, loading, save. |
| 4 | Fee collection workflow | **RESOLVED** | Complete 4-step flow: Search Student → Select Fee → Payment Details → Confirm. Receipt generated on success. |
| 5 | Admin login credentials removed | **RESOLVED** | `AdminLoginScreen` has empty fields, no defaults. No hardcoded credentials found in codebase. |
| 6 | Loading/empty/error states | **RESOLVED** | 32 screens use `LoadingWidget`, 23 use `EmptyState`, 30 use `CustomErrorWidget`. All School and ESS screens covered. |

---

## Issues Found During Review

### P1 — Broken Routes (Functional)

| Location | Broken Route | Should Be |
|----------|-------------|-----------|
| `school_dashboard_screen.dart:108` | `/school/students/create` | No route exists — needs a create screen or route |
| `school_dashboard_screen.dart:110` | `/school/homework/create` | No route exists |
| `school_dashboard_screen.dart:111` | `/school/fees/collection` | Should be `/school/fees` |
| `student_list_screen.dart:68` | `/school/students/create` | No route exists |

**Impact**: Tapping "Add Student", "Create Homework", or "Fee Collection" quick actions on the School Dashboard navigates to a blank/error screen. Same for the "Add Student" button on the Student List.

### P2 — Mobile Accessibility Gap

The `MainShell._buildBottomNav()` (main_shell.dart:383-405) exposes only 4 tabs: Dashboard, Employees, Attendance, More. The "More" bottom sheet only includes Leave, Visitors, Devices, Reports, and Administration.

**School and ESS modules are completely unreachable on mobile.** The sidebar (which contains these nav items) is hidden when `Responsive.isMobile(context)` returns true (width < 600px).

**Impact**: Any user on a phone or narrow tablet cannot navigate to School ERP or ESS features.

### P3 — Minor Issues

| Issue | Location | Severity |
|-------|----------|----------|
| ESS Dashboard clock in/out buttons are TODO stubs | `ess_dashboard_screen.dart:202-206` | Low (attendance screen has working buttons) |
| Duplicate ESS attendance routes | `router.dart:460-467` (`/ess/attendance` and `/ess/attendance/calendar` both → same screen) | Low |
| School Dashboard doesn't use shared `LoadingWidget`/`CustomErrorWidget` | `school_dashboard_screen.dart:51-52` | Low (uses inline `CircularProgressIndicator` and plain text) |

---

## Route Inventory Verification

### ShellRoute Children (70 routes)

**Core HRMS** (35 routes): Dashboard, Employees, Attendance, Shifts, Leaves, Holidays, Devices, Visitors, Access Control, Commands, Notifications, Recruitment, Performance, Assets, Reports, Expenses, Settings (eSSL, categories, tenant, work-codes), Departments, Branches, Designations, Documents, Exit Requests, Travel, Announcements, Health, Shift Groups/Rosters/Dept Shifts, OT, Outdoor Duty.

**ESS** (7 routes): Dashboard, Attendance, Attendance Calendar, Leaves, Profile, Payslips, Documents, Notifications.

**School ERP** (14 routes): Dashboard, Students (list/detail/edit), Academic Years, Classes, Attendance Mark, Homework, Exams, Fees, Transport, Hostel, Library, Timetable, Admissions.

### Root-Level Routes (outside Shell)

Admin routes (6): Login, Dashboard, Tenants, Plans, Features, Analytics.
Detail routes (6): Employee detail/edit, Attendance detail/summary/mark, Shift create/assign/edit, Leave balance/apply/requests.

---

## Navigation Coverage

| Module | Desktop Sidebar | Mobile Bottom Nav | Command Palette |
|--------|:-:|:-:|:-:|
| Dashboard | ✅ | ✅ | ✅ |
| Employees | ✅ | ✅ | ✅ |
| Attendance | ✅ | ✅ | ✅ |
| Leave | ✅ | ✅ (More) | ❌ |
| Visitors | ✅ | ✅ (More) | ❌ |
| Devices | ✅ | ✅ (More) | ❌ |
| Reports | ✅ | ✅ (More) | ❌ |
| Administration | ✅ | ✅ (More) | ✅ |
| School ERP (all) | ✅ | ❌ | ✅ |
| ESS (all) | ✅ | ❌ | ❌ |
| Payroll | ✅ | ❌ | ❌ |
| Recruitment | ✅ | ❌ | ❌ |
| Performance | ✅ | ❌ | ❌ |

---

## Loading/Empty/Error State Coverage

| Module | Screens | L/E/E States |
|--------|---------|:---:|
| ESS | 5 screens (dashboard, attendance, leaves, profile+payslips+docs+notifications) | ✅ All |
| School | 14 screens | ✅ 13/14 (dashboard uses inline) |
| Admin | 6 screens | ✅ All |
| Core HRMS | 15+ screens | ✅ All data-fetching screens |

---

## UX Score Assessment

| Category | Score | Weight | Notes |
|----------|-------|--------|-------|
| Navigation Structure | 8/10 | 25% | Solid ShellRoute architecture. Deducted for mobile gap and missing ESS/School in bottom nav. |
| Workflow Completeness | 9/10 | 25% | Fee collection is polished. Deducted for 3 broken quick-action routes. |
| State Handling | 9/10 | 20% | Consistent LoadingWidget/EmptyState/ErrorWidget pattern across 30+ screens. |
| Mobile Responsiveness | 6/10 | 15% | Layout adapts well but School/ESS modules are inaccessible on mobile. |
| Security | 10/10 | 10% | No hardcoded credentials. Admin auth uses API. |
| Visual Consistency | 9/10 | 5% | Design system (colors, typography, spacing) applied consistently. |

**Weighted Score: 8.3 / 10**

---

## Go / No-Go Recommendation

### CONDITIONAL GO ✅

Ship GA with the following conditions:

**Must-fix before public launch (P1):**
1. Fix 3 broken quick-action routes in School Dashboard and Student List — either create the missing screens or update the route paths.
2. Add School and ESS modules to the mobile bottom navigation "More" menu so mobile users can access them.

**Can ship and fix in next sprint (P2-P3):**
3. Implement ESS Dashboard clock in/out (currently working on Attendance screen).
4. Remove duplicate `/ess/attendance` route.
5. Standardize School Dashboard to use shared loading/error widgets.

The core architecture is sound. The two P1 items are straightforward fixes (< 1 hour each) and should be resolved before the first external users onboard.

---

*Reviewed by: Independent UX Review Agent*
*Date: 2026-06-28*
