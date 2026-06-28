# Usability Scorecard — Apex v2 Platform
**Audit Date:** 2026-06-28  
**Auditor Role:** Senior UX Researcher / QA Lead (Read-Only)  
**Version:** v2.0  

---

## Overall Usability Score: **5.8 / 10**

> *Score reflects the current state of the application as analysed from source code — not a live-session UX test. Scores are weighted by module completeness, workflow integrity, navigation correctness, and design consistency.*

---

## Scorecard by Dimension

| Dimension | Score | Weight | Weighted | Notes |
|-----------|-------|--------|---------|-------|
| Visual Design & Consistency | 7.5 | 15% | 1.13 | Strong design system; dark/light theme gaps |
| Navigation Architecture | 4.5 | 20% | 0.90 | Shell gap for school/ESS; mobile dead ends |
| Forms & Data Entry | 5.5 | 15% | 0.83 | Wizard lacks step validation; balance not shown |
| Workflow Completeness | 5.0 | 20% | 1.00 | Several workflows broken or placeholder |
| Error Handling & Feedback | 5.0 | 15% | 0.75 | Silent errors, missing confirmations |
| Mobile Usability | 3.5 | 10% | 0.35 | 70% of modules unreachable; logout buried |
| Accessibility | 5.5 | 5% | 0.28 | No a11y labels checked; tap targets small |
| **TOTAL** | | **100%** | **5.24** | Rounded up for design system quality |

> Adjusted Score: **5.8 / 10** (bonus +0.56 for strong design token system, component library quality, and responsive structure that is close to complete)

---

## Scorecard by Module

| Module | Usability Score | Completeness | Navigation | Notes |
|--------|----------------|--------------|-----------|-------|
| Corporate Login | 7/10 | ✅ Functional | ✅ Correct | Missing forgot-pw, no register link |
| Corporate Dashboard | 7.5/10 | ✅ Good | ✅ Correct | All KPIs, charts, quick actions present |
| Employee Management | 6.5/10 | ⚠️ Partial | ✅ Correct | Wizard validation gap; orphaned screen |
| Attendance | 7/10 | ✅ Good | ✅ Correct | Process button needs confirmation |
| Leave Management | 6/10 | ⚠️ Partial | ✅ Correct | No balance on form; no cancel flow |
| Payroll | 5.5/10 | ⚠️ Partial | ✅ Correct | No payslip download; no future-month guard |
| Reports | 6/10 | ⚠️ Functional | ✅ Correct | No report descriptions; transient history |
| Shifts | 6.5/10 | ✅ Good | ⚠️ Duplicate | Duplicate nav paths from sidebar + settings |
| Visitors | 6/10 | ⚠️ Partial | ✅ Correct | Null-crash on missing passId |
| Devices | 6.5/10 | ⚠️ Good | ✅ Correct | No confirm on destructive device commands |
| ESS (Employee Self-Service) | 3/10 | ⚠️ Partial | ❌ Broken | No shell; no ESS nav; isolated islands |
| Performance & Recruitment | 5.5/10 | ⚠️ Partial | ✅ Correct | No cross-module navigation |
| Assets, Travel, Expense | 5/10 | ⚠️ Partial | ✅ Correct | Exist but are HR module hybrids |
| School Dashboard | 6/10 | ✅ Functional | ✅ Correct (only one) | Silent stat failures |
| School Admissions | 3/10 | ⚠️ Partial | ❌ Broken | No AppBar, no back nav, no shell |
| School Student Mgmt | 4/10 | ⚠️ Partial | ❌ Broken (edit route) | Edit route not in router |
| School Attendance | 6.5/10 | ✅ Good | ❌ Broken shell | Best school screen; shell missing |
| School Fee Collection | 2/10 | ❌ Incomplete | ❌ Broken | Placeholder implementation |
| School Examinations | 2.5/10 | ❌ Incomplete | ❌ Broken | No marks entry; raw text date fields |
| School Timetable, Hostel, Transport, Library | 4/10 avg | ⚠️ Unknown | ❌ Broken shell | Screens exist; functionality unverified |
| Admin Login | 6.5/10 | ✅ Functional | ✅ Correct | Credential pre-fill security/UX issue |
| Admin Dashboard | 7/10 | ✅ Good | ✅ Correct | Clean stats + quick actions |
| Admin Tenant Management | 5.5/10 | ⚠️ Partial | ✅ Correct | Known syntax error; theme mismatch |
| Admin Plans | 8/10 | ✅ Strong | ✅ Correct | Best-implemented admin screen |
| Admin Features | 6/10 | ✅ Functional | ✅ Correct | Two entry points may confuse |

---

## Issue Count by Severity

| Severity | UI/UX Issues | Operability Issues | Total |
|----------|-------------|-------------------|-------|
| Critical | 0 | 3 | **3** |
| High | 8 | 10 | **18** |
| Medium | 13 | 11 | **24** |
| Low | 8 | 0 | **8** |
| Cosmetic | 0 | 0 | **0** |
| **Total** | **29** | **24** | **53** |

---

## Pre-GA Priority List

Issues are ranked by user-impact severity, frequency of encounter, and workflow criticality. This list represents the minimum fixes required before General Availability.

### 🔴 MUST FIX — Blocker (GA Blockers)

| # | Issue | Module | Ref | Impact |
|---|-------|--------|-----|--------|
| 1 | All school routes outside ShellRoute — navigation chrome missing | School ERP | OP-001, UX-010, UX-011 | School ERP completely unusable |
| 2 | Student edit route not registered in router — clicking Edit crashes | School ERP | WF-09 | Data management blocked |
| 3 | Fee collection is a placeholder — core school revenue workflow broken | School ERP | OP-016, WF-11 | Core school workflow blocked |
| 4 | Admin tenant list syntax error at line 219 | Admin | OP-021 | Admin management broken |
| 5 | ESS routes outside ShellRoute — no navigation for employees | ESS | OP-002, UX-016 | Employee self-service unusable |
| 6 | Mobile: 70% of modules unreachable from bottom nav | All | UX-002, OP-011 | Mobile users locked out |
| 7 | No forgot password flow exists | Auth | WF-01 | Standard auth requirement |

### 🟠 SHOULD FIX — High Priority (Before GA)

| # | Issue | Module | Ref | Impact |
|---|-------|--------|-----|--------|
| 8 | Employee create wizard: "Continue" skips step validation | Employees | OP-004 | Bad data submitted to API |
| 9 | Leave apply form: no remaining balance shown | Leave | OP-005, WF-04 | User blindly submits invalid requests |
| 10 | Payroll generation: no confirmation dialog | Payroll | OP-008 | Accidental bulk payroll run |
| 11 | Payroll: no future-month guard | Payroll | UX-012 | Generate payroll for wrong month |
| 12 | Leave approve/reject: no confirmation dialog | Leave | OP-014 | Accidental approvals in dense table |
| 13 | Admin credential pre-fill in admin login | Admin | UX-006 | Production credential exposure |
| 14 | Visitor pass route: null crash on missing passId | Visitors | OP-018 | Runtime crash on direct URL |
| 15 | Employee credential display on review step | Employees | UX-007 | Password visible before creation |
| 16 | Attendance process button: no confirmation | Attendance | OP-006 | Accidental bulk recalculation |
| 17 | No leave cancellation flow | Leave | WF-04 | Missing critical leave management step |
| 18 | Tablet layout: sidebar squeezes content on 600–1200px | Global | UX-001 | Tables unreadable on tablets |
| 19 | Exam screen: raw TextField for dates instead of date picker | School | WF-12 | Poor date entry UX |
| 20 | School attendance: no unsaved-changes guard | School | WF-10 | Loss of marking work |

### 🟡 SHOULD FIX — Medium Priority (First Sprint Post-GA)

| # | Issue | Module | Ref | Impact |
|---|-------|--------|-----|--------|
| 21 | Breadcrumbs show raw URL slugs with hyphens | Global | UX-008 | Unprofessional; confusing |
| 22 | Dual active sidebar items (attendance + outdoor-duty) | Global | UX-009 | Navigation confusion |
| 23 | Leave duration not shown dynamically on apply form | Leave | UX-014 | User must calculate manually |
| 24 | ISO date format shown to users instead of readable format | Attendance | UX-015 | Unfamiliar to non-technical HR |
| 25 | No unread badge on notification bell icon | Global | UX-023 | User unaware of pending notifications |
| 26 | Logout buried in mobile flow (3+ taps) | Global | OP-019 | Poor mobile ergonomics |
| 27 | Download history lost on navigation (reports) | Reports | OP-009 | User frustration |
| 28 | Settings screen mixes config + transactional features | Settings | UX-017 | Information architecture confusion |
| 29 | Duplicate nav paths: sidebar OPERATIONS Shifts + Settings Shifts | Shifts | UX-019 | Two paths to same screen |
| 30 | Orphaned `employee_list_screen.dart` (no route, dead code) | Employees | UX-020 | Bundle size; maintainer confusion |
| 31 | Orphaned `payroll_screen.dart` (no route, dead code) | Payroll | UX-021 | Bundle size; maintainer confusion |
| 32 | Access Control: no unified hub — 3 separate settings items | Access | UX-024 | 3 extra clicks per context switch |
| 33 | School stats: silent error returns `{}` showing all zeros | School | UX-025 | No feedback on API failure |
| 34 | Tenant not found: bare text, no back button | Admin | UX-026 | User trapped; no escape |
| 35 | Device commands: no confirmation before destructive ops | Devices | OP-010 | Accidental device reboot |
| 36 | `⌘K` shown on Windows (should be `Ctrl+K`) | Global | UX-018 | Incorrect platform labeling |
| 37 | eSSL initial sync: in-shell route loses progress on navigation | eSSL | OP-017 | Long-running op interrupted |

### 🟢 LOW PRIORITY — Cosmetic / Polish (Post-GA Backlog)

| # | Issue | Module | Ref | Impact |
|---|-------|--------|-----|--------|
| 38 | Typography has 20+ named styles for 7 semantic levels | Design System | UX-022 | Developer confusion; inconsistent use |
| 39 | Dark mode: hardcoded `Colors.white` in some screens | Global | UX-029 | Dark mode broken on specific screens |
| 40 | Splash → 401 flash before login redirect | Auth | UX-027 | Brief flash of dashboard before login |
| 41 | No "Clear All Filters" one-tap in employee directory | Employees | OP-022 | Minor UX friction |
| 42 | Pagination state not reset on filter change | Employees | OP-012 | Empty page result |
| 43 | Performance → Goals: no contextual cross-navigation | Performance | OP-024 | Extra click to switch related screens |
| 44 | Attendance list: pagination lost on browser refresh | Attendance | OP-023 | Minor state management issue |

---

## Summary for Stakeholders

**Corporate HRMS** is usable and approaching GA quality on desktop. The core loops (employees, attendance, leave, payroll) are functional with medium-severity gaps in validation, confirmations, and feedback.

**School ERP** is **not production-ready**. The navigation shell is architecturally broken for all school-specific routes. Fee collection and examinations are incomplete. The student edit route will crash. School ERP requires a dedicated sprint before GA.

**Employee Self-Service (ESS)** is architecturally broken in the same way as school — routes are outside the shell, leaving employees with no navigation.

**Admin Panel** is functional for plan management and analytics. The tenant list has a known syntax error and a dark/light theme mismatch that should be resolved before go-live.

**Mobile usability** is the weakest dimension across all modules — the platform is not viable as a mobile-first solution in its current state.

---

*Report generated by static code analysis of `C:/Apexv2/frontend/lib/` — 100+ screens, widget library, design system, and navigation graph examined.*
