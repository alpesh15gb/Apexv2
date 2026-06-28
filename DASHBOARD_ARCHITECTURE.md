# Apex HRMS — Dashboard Architecture

## 1. Widget Classification

### 1.1 Core Dashboard Widgets (Shared)

| Widget | Description | Shared By |
|--------|-------------|-----------|
| **Welcome Header** | Page title + date + primary CTA button | Corporate + School |
| **Quick Actions** | Grid of shortcut buttons to frequent tasks | Corporate + School |
| **KPI Stats Grid** | Responsive grid of stat cards with icon, value, label | Corporate + School (different data) |
| **Attendance Trend Chart** | Time-series line/bar chart showing attendance over N days | Corporate + School (different granularity) |
| **Error / Loading / Empty States** | Reusable feedback widgets for async data | Corporate + School |

### 1.2 Corporate-Only Widgets

| Widget | Data Source (Backend) | Description |
|--------|----------------------|-------------|
| **Attendance KPIs** | `DashboardStats` — present, absent, late, attendance % | 4 KPI cards in grid |
| **Leave Summary** | `DashboardStats.pendingLeaves` | KPI card + pending work item |
| **Visitor Count** | `DashboardStats.visitorsInside` | KPI card |
| **Device Status** | `DashboardStats.onlineDevices / offlineDevices` | KPI card + sync health section |
| **Department Distribution** | `GET /dashboard/department-distribution` | Horizontal bar chart |
| **Pending Work** | Derived from `DashboardStats` | List of actionable items (missing punches, late, approvals, offline devices) |
| **Recent Punch Logs** | `GET /dashboard/recent-activity` | Scrollable activity feed (last 8) |
| **Sync Health** | `GET /dashboard/sync-health` | Server connectivity status |

### 1.3 School-Only Widgets

| Widget | Data Source (Backend) | Description |
|--------|----------------------|-------------|
| **Student Count** | `GET /school/dashboard/stats` → `total_students` | KPI card |
| **Attendance Percentage** | `GET /school/dashboard/stats` → `attendance_percentage` | KPI card |
| **Fee Collection** | `GET /school/dashboard/stats` → `total_fee_collected` | KPI card (INR formatted) |
| **Pending Fees** | `GET /school/dashboard/stats` → `pending_fee_count` | KPI card |
| **Grade / Section Count** | `GET /school/dashboard/stats` → `total_grades / total_sections` | KPI cards |
| **Attendance Overview (7-day)** | `GET /school/dashboard/attendance-overview?days=7` | Horizontal progress bars per day |
| **School Quick Actions** | Hardcoded routes | 6 action chips (Add Student, Mark Attendance, Homework, Fees, Exams, Timetable) |

### 1.4 Planned Widgets (Not Yet Implemented)

| Widget | Target Dashboard | Notes |
|--------|-----------------|-------|
| Notifications Widget | Core | No backend endpoint exists yet |
| Upcoming Exams | School | `Exam` model exists but not wired to dashboard |
| Recent Admissions | School | `Student` model has `created_at` but no dashboard query |
| Shift Overview | Corporate | Shift data exists but not surfaced on dashboard |
| Leave Calendar | Corporate | Backend endpoint exists (`/dashboard/leave-calendar`) but no frontend widget |
| Birthdays / Anniversaries | Corporate | Backend endpoints exist (`/dashboard/birthdays`, `/dashboard/anniversaries`) but no frontend widget |
| Attendance Heatmap | Corporate | Backend endpoint exists (`/dashboard/attendance-heatmap`) but no frontend widget |

---

## 2. Data Sources

### 2.1 Backend API Endpoints

#### Corporate Dashboard (`/api/v1/dashboard/`)

| Endpoint | Method | Response Model | Auth |
|----------|--------|---------------|------|
| `/stats` | GET | `DashboardStats` | `dashboard.read` |
| `/attendance-chart?days=N` | GET | `List[AttendanceTrend]` | `dashboard.read` |
| `/department-distribution` | GET | `List[DepartmentDistribution]` | `dashboard.read` |
| `/recent-activity?limit=N` | GET | `List[RecentActivity]` | `dashboard.read` |
| `/sync-health` | GET | `SyncHealthStatus` | `dashboard.read` |
| `/attendance-heatmap?days=N` | GET | `List[AttendanceHeatmapItem]` | `dashboard.read` |
| `/leave-calendar?year=&month=` | GET | `List[LeaveCalendarItem]` | `dashboard.read` |
| `/birthdays` | GET | `List[BirthdayItem]` | `dashboard.read` |
| `/anniversaries` | GET | `List[AnniversaryItem]` | `dashboard.read` |
| `/monthly-trend?months=N` | GET | `List[MonthlyTrend]` | `dashboard.read` |

#### School Dashboard (`/api/v1/school/dashboard/`)

| Endpoint | Method | Response | Auth |
|----------|--------|----------|------|
| `/stats` | GET | `dict` (inline) | `student.read` + `student_management` feature |
| `/attendance-overview?days=N` | GET | `List[dict]` (inline) | `student.read` + `student_management` feature |

### 2.2 Frontend Providers (Riverpod)

#### Corporate (`dashboard_provider.dart`)

| Provider | Type | Caches |
|----------|------|--------|
| `dashboardStatsProvider` | `FutureProvider<DashboardStats>` | Stats from `/stats` |
| `dashboardChartProvider(days)` | `FutureProvider<List<AttendanceTrend>>` | Chart data from `/attendance-chart` |
| `departmentDistributionProvider` | `FutureProvider<List<DepartmentDistribution>>` | Dept data from `/department-distribution` |
| `recentPunchLogsProvider` | `FutureProvider<List<Map>>` | Activity from `/recent-activity` |
| `syncHealthProvider` | `FutureProvider<SyncHealthStatus>` | Sync from `/sync-health` |

#### School (`school_dashboard_screen.dart` — co-located)

| Provider | Type | Caches |
|----------|------|--------|
| `schoolStatsProvider` | `FutureProvider<Map<String, dynamic>>` | Stats from `/school/dashboard/stats` |
| `attendanceOverviewProvider` | `FutureProvider<List<dynamic>>` | Attendance from `/school/dashboard/attendance-overview` |

### 2.3 Service Layer

| Service | Location | Pattern |
|---------|----------|---------|
| `DashboardService` | `backend/app/services/dashboard.py` | Stateless; receives `db` session, returns dicts |
| School dashboard | Inline in `school_dashboard.py` endpoint | Direct SQLAlchemy queries (no service extraction) |

---

## 3. Layout Design

### 3.1 Corporate Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  _Header: "Dashboard" + date + [Mark Attendance] btn    │
├─────────────────────────────────────────────────────────┤
│  _KpiRow: 7 KPI cards in responsive grid                │
│  ┌──────┬──────┬──────┬──────┬──────┬──────┬──────┐    │
│  │ Attd │Prsnt │Absent│ Late │Leave │Device│Visit │    │
│  └──────┴──────┴──────┴──────┴──────┴──────┴──────┘    │
├─────────────────────────────────────────────────────────┤
│  Charts Row (desktop: side-by-side, mobile: stacked)    │
│  ┌─────────────────────────┬───────────────────────┐    │
│  │  _TrendChart (flex:2)   │ _DeptDistribution(1)  │    │
│  │  LineChart (7 days)     │ Horizontal bars       │    │
│  └─────────────────────────┴───────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  Bottom Row (desktop: side-by-side, mobile: stacked)    │
│  ┌─────────────────────────┬───────────────────────┐    │
│  │  _PendingWork           │ _RecentPunchLogs      │    │
│  │  - Missing Punches      │  - Last 8 entries     │    │
│  │  - Late Today           │  - Employee + time    │    │
│  │  - Pending Approvals    │  - In/Out indicator    │    │
│  │  - Offline Devices      │                       │    │
│  └─────────────────────────┴───────────────────────┘    │
├─────────────────────────────────────────────────────────┤
│  Footer Row (desktop: side-by-side, mobile: stacked)    │
│  ┌─────────────────────────┬───────────────────────┐    │
│  │  _QuickActions          │ _SyncHealth           │    │
│  │  4 action buttons       │ Servers/Connected/Err │    │
│  └─────────────────────────┴───────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 3.2 School Dashboard Layout

```
┌─────────────────────────────────────────────────────────┐
│  "School Dashboard"                                     │
│  "Overview of your school operations"                   │
├─────────────────────────────────────────────────────────┤
│  _StatsGrid: 8 KPI cards in responsive grid             │
│  ┌──────┬──────┬──────┬──────┐                          │
│  │Stdnt │Prsnt │Absent│ At%  │                          │
│  ├──────┼──────┼──────┼──────┤                          │
│  │Grade │Sectn │ Fee  │PendF │                          │
│  └──────┴──────┴──────┴──────┘                          │
├─────────────────────────────────────────────────────────┤
│  _QuickActions: Wrap of 6 action chips                   │
│  [Add Student] [Mark Att.] [Homework] [Fees] [Exam] [TT]│
├─────────────────────────────────────────────────────────┤
│  _AttendanceOverview: 7-day horizontal progress bars     │
│  ┌─────────────────────────────────────────────────┐    │
│  │  2026-06-22  ████████████████░░░░  45P / 5A     │    │
│  │  2026-06-23  ████████████████████  48P / 2A     │    │
│  │  ...                                            │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

### 3.3 Tenant Routing

`DashboardScreen` acts as a router — it checks `authProvider` for `user.isSchool` and conditionally renders either `SchoolDashboardScreen` or the corporate layout. This is a **runtime branch**, not a separate route.

---

## 4. Responsive Behavior

### 4.1 Breakpoints

| Breakpoint | Detection | Behavior |
|------------|-----------|----------|
| **Desktop** | `Responsive.isDesktop(context)` | Side-by-side layouts (Row with Expanded children) |
| **Tablet** | `!isDesktop && !isMobile` | Stacked layouts (Column) |
| **Mobile** | `Responsive.isMobile(context)` | Stacked layouts, 2-column KPI grid, hidden CTAs |

### 4.2 Corporate Responsive Rules

| Section | Desktop | Tablet/Mobile |
|---------|---------|---------------|
| KPI Grid | 7 columns (`crossAxisCount: 7`) | 2 columns |
| Charts Row | `Row` — TrendChart (flex:2) + DeptDistribution (flex:1) | `Column` — stacked vertically |
| Pending Work + Activity | `Row` — equal flex | `Column` — stacked |
| Quick Actions + Sync | `Row` — equal flex | `Column` — stacked, sync may hide on error |
| Header CTA | Visible (`Mark Attendance` button) | Hidden (`!Responsive.isMobile` guard) |

### 4.3 School Responsive Rules

| Section | Desktop (>1200) | Tablet (800–1200) | Mobile (<800) |
|---------|----------------|-------------------|---------------|
| Stats Grid | 4 columns | 3 columns | 2 columns |
| Quick Actions | `Wrap` with `spacing: 12` | Same (auto-wraps) | Same (auto-wraps) |

### 4.4 Card Aspect Ratios

| Dashboard | Desktop | Mobile |
|-----------|---------|--------|
| Corporate KPI | `childAspectRatio: 2.0` | `childAspectRatio: 1.6` |
| School Stats | `childAspectRatio: 1.6` | `childAspectRatio: 1.6` |

---

## 5. Design System Integration

### 5.1 Shared Components

| Component | File | Usage |
|-----------|------|-------|
| `_SectionCard` | `dashboard_screen.dart` | Corporate section wrapper with title + border |
| `_KpiCard` | `dashboard_screen.dart` | Corporate KPI with hover animation + color bar |
| `StatCard` | `widgets/stat_card.dart` | School KPI card (imported, reusable) |
| `_QuickActions` | Both screens | Different implementations, same concept |
| `_ErrorCard` / `_LoadingCard` / `_EmptyBlock` | `dashboard_screen.dart` | Corporate async states |
| `ApexCard` | `widgets/apex_card.dart` | Imported but not directly used in dashboard |

### 5.2 Design Tokens Used

| Token | Source | Usage |
|-------|--------|-------|
| Colors | `ApexColors` | `neutral50` (bg), `neutral0` (cards), `neutral200` (borders), `primary600` (accent), `success/error/warning` |
| Typography | `ApexTypography` | `pageTitle`, `sectionHeader`, `kpiValue`, `kpiLabel`, `body`, `bodySmall`, `caption`, `captionSmall` |

---

## 6. Data Flow

```
┌──────────────┐     Riverpod      ┌──────────────┐     HTTP/Dio     ┌──────────────┐
│   Flutter     │ ◄── FutureProvider│   Provider    │ ◄──────────────► │   FastAPI     │
│   Widget      │     .when()       │   (ref.watch) │                  │   Endpoint    │
└──────────────┘                   └──────────────┘                  └──────┬───────┘
                                                                            │
                                                                     ┌──────▼───────┐
                                                                     │   Service     │
                                                                     │   Layer       │
                                                                     └──────┬───────┘
                                                                            │
                                                                     ┌──────▼───────┐
                                                                     │   SQLAlchemy  │
                                                                     │   + PostgreSQL│
                                                                     └──────────────┘
```

### Refresh Strategy

- Corporate: `RefreshIndicator` wraps entire body, invalidates all 5 providers on pull-to-refresh
- School: No `RefreshIndicator` — relies on provider auto-dispose and re-fetch on navigation

---

## 7. Identified Gaps & Recommendations

### 7.1 Missing Shared Infrastructure

| Gap | Impact | Recommendation |
|-----|--------|----------------|
| No shared `DashboardWidget` base class | Corporate and school widgets are fully duplicated | Extract common patterns: `_SectionCard`, loading/error/empty states, KPI card into shared widget library |
| School has no service layer | Business logic lives in endpoint handler | Extract `SchoolDashboardService` mirroring `DashboardService` pattern |
| School providers co-located in screen file | Hard to test, hard to share | Move to `providers/school_dashboard_provider.dart` |

### 7.2 Missing Widgets (Backend-Ready, No Frontend)

| Widget | Backend Endpoint | Priority |
|--------|-----------------|----------|
| Leave Calendar | `GET /dashboard/leave-calendar` | High |
| Birthdays | `GET /dashboard/birthdays` | Medium |
| Work Anniversaries | `GET /dashboard/anniversaries` | Medium |
| Attendance Heatmap | `GET /dashboard/attendance-heatmap` | Medium |
| Monthly Trend | `GET /dashboard/monthly-trend` | Low |

### 7.3 Missing Endpoints (Frontend-Desired, No Backend)

| Widget | Needed Endpoint | Priority |
|--------|----------------|----------|
| Notifications | `GET /dashboard/notifications` | High |
| Upcoming Exams | `GET /school/dashboard/upcoming-exams` | Medium |
| Recent Admissions | `GET /school/dashboard/recent-admissions` | Medium |
| Shift Overview | `GET /dashboard/shift-overview` | Low |
| Transport Status | `GET /school/dashboard/transport-status` | Low |

### 7.4 Architectural Improvements

1. **Unified Provider Pattern**: Both dashboards should use `dashboard_provider.dart` with a `dashboardType` discriminator rather than separate provider files
2. **Widget Composition**: Extract a `DashboardSection` abstract widget that handles title, loading, error, empty states uniformly
3. **Real-time Updates**: Consider WebSocket or SSE for punch logs and sync health instead of pull-to-refresh
4. **Caching**: School stats are re-fetched on every navigation; add `keepAlive: true` or cache duration
5. **Feature Flags**: School dashboard gates on `student_management` feature — extend this pattern to corporate sub-widgets (e.g., visitors module)
