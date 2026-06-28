# Apex HRMS — Sidebar Information Architecture

## 1. Current Structure

**Source**: `frontend/lib/screens/main_shell.dart`

The sidebar renders conditionally based on `user.isSchool` (tenant type). Non-school items are hidden for school tenants, and the SCHOOL section is hidden for corporate tenants.

```
┌─────────────────────────────┐
│  Logo / App Title           │
├─────────────────────────────┤
│  WORKSPACE                  │
│    Dashboard                │
│    Employees                │
│    Attendance               │
│                             │
│  MANAGEMENT                 │
│    Leave                    │
│    Holidays                 │
│    Visitors                 │
│    Announcements            │
│    Exit Requests            │
│                             │
│  ── Corporate Only ──────── │
│  OPERATIONS                 │
│    Shifts                   │
│    Devices                  │
│    Outdoor Duty             │
│    OT Register              │
│    Travel                   │
│    Assets                   │
│    Reports                  │
│                             │
│  FINANCE                    │
│    Payroll                  │
│    Expenses                 │
│    Documents                │
│  ────────────────────────── │
│                             │
│  ── School Only ─────────── │
│  SCHOOL                     │
│    School Dashboard         │
│    Students                 │
│    Admissions               │
│    Attendance               │
│    Timetable                │
│    Homework                 │
│    Examinations             │
│    Fee Collection           │
│    Transport                │
│    Hostel                   │
│    Library                  │
│    Classes                  │
│    Academic Year            │
│  ────────────────────────── │
│                             │
│  ────────────────────────── │
│  Administration (settings)  │
├─────────────────────────────┤
│  ◄ Collapse / ► Expand      │
│  User Avatar + Name         │
└─────────────────────────────┘
```

### Current Issues

| Issue | Impact |
|---|---|
| Flat hierarchy in OPERATIONS (7 items) | Cognitive overload; hard to scan |
| "Employees" under WORKSPACE but "Departments/Branches" missing | Incomplete HR management surface |
| Documents buried under FINANCE | Hard to find; logically shared across modules |
| No Notifications in sidebar | Notification icon only in top bar |
| School section has 13 flat items | Too many items without grouping |
| Homework/Communication not grouped | School communication is scattered |
| No dedicated Recruitment or Performance sections | Missing modern HRMS capabilities |

---

## 2. Proposed Structure

### 2.1 Core Navigation (Always Visible — Both Tenant Types)

These items appear at the top of the sidebar for all users. They are utility/global pages, not domain-specific.

```
CORE
  Dashboard           → /dashboard
  Notifications       → /notifications
  Documents           → /documents
  Settings            → /settings
```

**Rationale**: Dashboard, Notifications, Documents, and Settings are universal. Moving Documents out of FINANCE and Notifications into the sidebar makes them first-class citizens. Settings replaces the current "Administration" label.

### 2.2 Corporate Navigation (Visible for Corporate Tenants)

```
HR MANAGEMENT
  Employees           → /employees
  Departments         → /departments
  Branches            → /branches

ATTENDANCE & SHIFTS
  Attendance          → /attendance
  Shifts              → /shifts
  Outdoor Duty        → /attendance/outdoor-duty
  OT Register         → /attendance/ot
  Devices             → /devices

LEAVE MANAGEMENT
  Leave               → /leaves
  Holidays            → /holidays
  Exit Requests       → /exit-requests

PAYROLL & FINANCE
  Payroll             → /payroll
  Expenses            → /expenses

RECRUITMENT
  Job Openings        → /recruitment/jobs
  Candidates          → /recruitment/candidates
  Interviews          → /recruitment/interviews

PERFORMANCE
  Reviews             → /performance/reviews
  Goals               → /performance/goals
  Feedback            → /performance/feedback

ASSETS
  Asset Inventory     → /assets
  Assignments         → /assets/assignments

VISITORS
  Visitor Log         → /visitors
  Pre-Approvals       → /visitors/approvals

ANNOUNCEMENTS & TRAVEL
  Announcements       → /announcements
  Travel Requests     → /travel

REPORTS
  Reports             → /reports
  Analytics           → /reports/analytics
```

**Key changes from current**:
- Employees, Departments, Branches grouped under HR MANAGEMENT (new section)
- Attendance and Shifts merged into one section (currently split across WORKSPACE and OPERATIONS)
- Documents elevated to CORE section
- Recruitment and Performance added as new top-level sections
- Assets gets its own section with assignments sub-item
- Visitors expanded with pre-approvals
- Reports separated from OPERATIONS; Analytics added
- Travel merged with Announcements (both communication/broadcast-oriented)
- Outdoor Duty and OT Register grouped under ATTENDANCE & SHIFTS (they are attendance-adjacent)

### 2.3 School Navigation (Visible for School Tenants)

```
SCHOOL DASHBOARD
  School Dashboard    → /school/dashboard

STUDENTS & ADMISSIONS
  Students            → /school/students
  Admissions          → /school/admissions
  Classes & Sections  → /school/classes

ACADEMICS
  Subjects            → /school/subjects
  Timetable           → /school/timetable
  Academic Year       → /school/academic-years

ATTENDANCE
  Student Attendance  → /school/attendance/mark
  Attendance Reports  → /school/attendance/reports

EXAMINATIONS
  Exam Schedule       → /school/exams
  Results & Report Cards → /school/exams/results

FEES
  Fee Collection      → /school/fees
  Fee Structure       → /school/fees/structure
  Dues & Defaults     → /school/fees/dues

TRANSPORT
  Routes & Vehicles   → /school/transport
  Student Tracking    → /school/transport/tracking

HOSTEL
  Hostel Management   → /school/hostel
  Room Allocation     → /school/hostel/rooms

LIBRARY
  Library             → /school/library
  Issue & Return      → /school/library/transactions

COMMUNICATION
  Homework            → /school/homework
  Circulars           → /school/circulars
  Parent Messaging    → /school/messages
```

**Key changes from current**:
- Grouped 13 flat items into 10 logical sections (2–3 items each)
- COMMUNICATION section consolidates homework, circulars, and parent messaging
- Academics separated from Students & Admissions (was conflated)
- Fees expanded with structure and dues sub-items
- Transport expanded with student tracking
- Attendance split from general into dedicated section with reports
- Examinations expanded with results sub-item

---

## 3. Navigation Hierarchy Diagram

```
Sidebar
├── CORE (always visible)
│   ├── Dashboard
│   ├── Notifications
│   ├── Documents
│   └── Settings
│
├── ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
│
├── [if corporate]
│   ├── HR MANAGEMENT
│   │   ├── Employees
│   │   ├── Departments
│   │   └── Branches
│   ├── ATTENDANCE & SHIFTS
│   │   ├── Attendance
│   │   ├── Shifts
│   │   ├── Outdoor Duty
│   │   ├── OT Register
│   │   └── Devices
│   ├── LEAVE MANAGEMENT
│   │   ├── Leave
│   │   ├── Holidays
│   │   └── Exit Requests
│   ├── PAYROLL & FINANCE
│   │   ├── Payroll
│   │   └── Expenses
│   ├── RECRUITMENT
│   │   ├── Job Openings
│   │   ├── Candidates
│   │   └── Interviews
│   ├── PERFORMANCE
│   │   ├── Reviews
│   │   ├── Goals
│   │   └── Feedback
│   ├── ASSETS
│   │   ├── Asset Inventory
│   │   └── Assignments
│   ├── VISITORS
│   │   ├── Visitor Log
│   │   └── Pre-Approvals
│   ├── ANNOUNCEMENTS & TRAVEL
│   │   ├── Announcements
│   │   └── Travel Requests
│   └── REPORTS
│       ├── Reports
│       └── Analytics
│
├── [if school]
│   ├── SCHOOL DASHBOARD
│   │   └── School Dashboard
│   ├── STUDENTS & ADMISSIONS
│   │   ├── Students
│   │   ├── Admissions
│   │   └── Classes & Sections
│   ├── ACADEMICS
│   │   ├── Subjects
│   │   ├── Timetable
│   │   └── Academic Year
│   ├── ATTENDANCE
│   │   ├── Student Attendance
│   │   └── Attendance Reports
│   ├── EXAMINATIONS
│   │   ├── Exam Schedule
│   │   └── Results & Report Cards
│   ├── FEES
│   │   ├── Fee Collection
│   │   ├── Fee Structure
│   │   └── Dues & Defaults
│   ├── TRANSPORT
│   │   ├── Routes & Vehicles
│   │   └── Student Tracking
│   ├── HOSTEL
│   │   ├── Hostel Management
│   │   └── Room Allocation
│   ├── LIBRARY
│   │   ├── Library
│   │   └── Issue & Return
│   └── COMMUNICATION
│       ├── Homework
│       ├── Circulars
│       └── Parent Messaging
│
└── Bottom Bar
    ├── ◄ Collapse / ► Expand
    └── User Info + Logout
```

---

## 4. Responsive Behavior

### 4.1 Desktop (≥1024px)

| State | Sidebar Width | Behavior |
|---|---|---|
| Expanded | 240px | Full labels, section headers, icons |
| Collapsed | 64px | Icons only, tooltips on hover, no section headers |

- Collapse/expand toggle button at bottom of sidebar
- State persists in local storage across sessions
- Section headers hidden when collapsed (only icons visible)

### 4.2 Tablet (768px–1023px)

| Element | Behavior |
|---|---|
| Sidebar | Collapsed by default (64px, icons only) |
| Expansion | Overlay mode — expands over content with scrim backdrop |
| Touch | Tap icon to expand sidebar; tap outside to collapse |
| Section headers | Visible only when expanded |

### 4.3 Mobile (<768px)

| Element | Behavior |
|---|---|
| Sidebar | Hidden entirely |
| Navigation | Bottom navigation bar with 5 destinations |
| More items | "More" tab opens full-screen modal with grouped sections |
| Gesture | Swipe right from left edge to reveal drawer |

**Proposed Mobile Bottom Nav (5 items)**:

```
┌────────┬────────┬────────┬────────┬────────┐
│  Home  │ People │Clock   │ Money  │  More  │
│  (dash)│ (HR)   │(Attn)  │(Pay)   │  (≡)   │
└────────┴────────┴────────┴────────┴────────┘
```

- **Home** → Dashboard
- **People** → Employees (corporate) / Students (school)
- **Clock** → Attendance
- **Money** → Payroll (corporate) / Fees (school)
- **More** → Opens bottom sheet with all remaining sections

For school tenants, the bottom nav labels/icons swap:
```
┌────────┬────────┬────────┬────────┬────────┐
│  Home  │Students│ Attend │  Fees  │  More  │
└────────┴────────┴────────┴────────┴────────┘
```

### 4.4 Sidebar Interaction Details

| Interaction | Behavior |
|---|---|
| Hover on collapsed item | Show tooltip with label + keyboard shortcut |
| Active item | Primary color background tint, bold label |
| Section header | Uppercase caption, neutral-500 color, 1.2 letter spacing |
| Scroll | Sidebar content scrolls independently; logo + user info are fixed |
| Keyboard | `⌘K` / `Ctrl+K` opens command palette (already implemented) |

---

## 5. Tenant-Type Switching

### 5.1 Mechanism

The tenant type is determined by `user.isSchool` from the auth provider (already in place). The sidebar rebuilds reactively via Riverpod's `ref.watch(authProvider)`.

```
authProvider → user.isSchool (bool)
  ├── false → Show CORE + Corporate sections
  └── true  → Show CORE + School sections
```

### 5.2 Implementation Pattern

```dart
// In _buildSidebar → Consumer builder:
final isSchool = user?.isSchool ?? false;

return Column(
  children: [
    // CORE — always visible
    _navSection('CORE', [
      _nav(..., 'Dashboard', '/dashboard'),
      _nav(..., 'Notifications', '/notifications'),
      _nav(..., 'Documents', '/documents'),
      _nav(..., 'Settings', '/settings'),
    ], isDark),

    const Divider(height: 1, indent: 16, endIndent: 16),

    // Corporate sections
    if (!isSchool) ...[
      _navSection('HR MANAGEMENT', [...], isDark),
      _navSection('ATTENDANCE & SHIFTS', [...], isDark),
      _navSection('LEAVE MANAGEMENT', [...], isDark),
      _navSection('PAYROLL & FINANCE', [...], isDark),
      _navSection('RECRUITMENT', [...], isDark),
      _navSection('PERFORMANCE', [...], isDark),
      _navSection('ASSETS', [...], isDark),
      _navSection('VISITORS', [...], isDark),
      _navSection('ANNOUNCEMENTS & TRAVEL', [...], isDark),
      _navSection('REPORTS', [...], isDark),
    ],

    // School sections
    if (isSchool) ...[
      _navSection('SCHOOL DASHBOARD', [...], isDark),
      _navSection('STUDENTS & ADMISSIONS', [...], isDark),
      _navSection('ACADEMICS', [...], isDark),
      _navSection('ATTENDANCE', [...], isDark),
      _navSection('EXAMINATIONS', [...], isDark),
      _navSection('FEES', [...], isDark),
      _navSection('TRANSPORT', [...], isDark),
      _navSection('HOSTEL', [...], isDark),
      _navSection('LIBRARY', [...], isDark),
      _navSection('COMMUNICATION', [...], isDark),
    ],
  ],
);
```

### 5.3 Collapsible Sections

Each `_navSection` should support collapse/expand state per section. This is critical for the corporate view (10 sections) to avoid excessive scrolling.

```
HR MANAGEMENT  ▾           ← tap header to collapse/expand
  Employees
  Departments
  Branches

ATTENDANCE & SHIFTS  ▸    ← collapsed
```

State: Store collapsed section names in a `Set<String>` in the `MainShell` state. Persist to local storage.

### 5.4 Route Mapping

All existing routes remain unchanged. New sections only require new route entries in `router.dart`. No existing routes are broken.

| Current Route | New Section | Status |
|---|---|---|
| `/dashboard` | CORE → Dashboard | Unchanged |
| `/employees` | HR MANAGEMENT → Employees | Moved from WORKSPACE |
| `/attendance` | ATTENDANCE & SHIFTS → Attendance | Moved from WORKSPACE |
| `/leaves` | LEAVE MANAGEMENT → Leave | Moved from MANAGEMENT |
| `/holidays` | LEAVE MANAGEMENT → Holidays | Moved from MANAGEMENT |
| `/visitors` | VISITORS → Visitor Log | Moved from MANAGEMENT |
| `/announcements` | ANNOUNCEMENTS & TRAVEL | Moved from MANAGEMENT |
| `/exit-requests` | LEAVE MANAGEMENT → Exit Requests | Moved from MANAGEMENT |
| `/shifts` | ATTENDANCE & SHIFTS → Shifts | Moved from OPERATIONS |
| `/devices` | ATTENDANCE & SHIFTS → Devices | Moved from OPERATIONS |
| `/attendance/outdoor-duty` | ATTENDANCE & SHIFTS | Moved from OPERATIONS |
| `/attendance/ot` | ATTENDANCE & SHIFTS | Moved from OPERATIONS |
| `/travel` | ANNOUNCEMENTS & TRAVEL | Moved from OPERATIONS |
| `/assets` | ASSETS → Asset Inventory | Moved from OPERATIONS |
| `/reports` | REPORTS | Moved from OPERATIONS |
| `/payroll` | PAYROLL & FINANCE | Moved from FINANCE |
| `/expenses` | PAYROLL & FINANCE | Moved from FINANCE |
| `/documents` | CORE → Documents | Moved from FINANCE |
| `/settings` | CORE → Settings | Was standalone "Administration" |
| `/notifications` | CORE → Notifications | **New in sidebar** (was top-bar only) |
| `/departments` | HR MANAGEMENT | **New route** |
| `/branches` | HR MANAGEMENT | **New route** |
| `/recruitment/*` | RECRUITMENT | **New route group** |
| `/performance/*` | PERFORMANCE | **New route group** |
| `/school/*` | School sections | Unchanged routes, reorganized groups |

### 5.5 Command Palette Updates

The `_CommandPalette` should be updated to include new entries:

```dart
// New corporate commands
{'label': 'Departments', 'route': '/departments', 'icon': Icons.business},
{'label': 'Branches', 'route': '/branches', 'icon': Icons.location_on},
{'label': 'Job Openings', 'route': '/recruitment/jobs', 'icon': Icons.work_outline},
{'label': 'Candidates', 'route': '/recruitment/candidates', 'icon': Icons.person_search},
{'label': 'Performance Reviews', 'route': '/performance/reviews', 'icon': Icons.star_outline},

// New school commands
{'label': 'Circulars', 'route': '/school/circulars', 'icon': Icons.article},
{'label': 'Parent Messaging', 'route': '/school/messages', 'icon': Icons.message},
{'label': 'Fee Structure', 'route': '/school/fees/structure', 'icon': Icons.receipt},
{'label': 'Room Allocation', 'route': '/school/hostel/rooms', 'icon': Icons.meeting_room},
```

---

## 6. Item Count Summary

| Section | Corporate | School |
|---|---|---|
| CORE | 4 | 4 |
| Domain sections | 22 items across 10 sections | 22 items across 10 sections |
| **Total visible items** | **26** | **26** |

Current total: 24 (corporate) / 19 (school). The increase is modest and offset by grouping, which reduces cognitive load.

---

## 7. Migration Notes

1. **No route changes required** — all existing `/routes` stay the same.
2. **New routes to add**: `/departments`, `/branches`, `/recruitment/*`, `/performance/*`, `/notifications`, `/school/subjects`, `/school/circulars`, `/school/messages`, `/school/fees/structure`, `/school/fees/dues`, `/school/transport/tracking`, `/school/hostel/rooms`, `/school/library/transactions`, `/school/exams/results`, `/school/attendance/reports`.
3. **New screens to build**: Corresponding Flutter screen widgets for each new route.
4. **Router update**: Add `GoRoute` entries for new paths in `frontend/lib/core/router.dart`.
5. **Section collapse state**: Add `_collapsedSections` set to `_MainShellState`, persist via `shared_preferences`.
6. **Bottom nav update**: Update `_buildBottomNav()` to reflect new section grouping and tenant-aware icons/labels.
7. **Command palette**: Add new entries for all new routes.
