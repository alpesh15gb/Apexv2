# Apex HRMS Product Specification

**Version**: 3.0  
**Date**: 2026-06-26

---

## Product Vision

Apex HRMS is an enterprise-grade attendance and workforce management platform that feels like premium SaaS software. It should be comparable to Keka, Darwinbox, and BambooHR in terms of usability and visual polish.

---

## Target Users

### Primary Users
1. **HR Manager**: Daily attendance management, leave approvals, reports
2. **IT Administrator**: Device management, sync monitoring, system health
3. **Company Owner**: Executive dashboard, workforce analytics
4. **Employee**: Self-service attendance, leave applications

### Secondary Users
1. **Department Manager**: Team attendance, approvals
2. **Receptionist**: Visitor management
3. **Security**: Access control, device monitoring

---

## Information Architecture

### Navigation Structure

```
Dashboard
├── Executive Overview
├── Pending Work
├── Quick Actions
└── Activity Feed

Employees
├── Directory
├── Departments
├── Designations
├── Shifts
└── Organization

Attendance
├── Today's Attendance
├── Calendar View
├── Timeline View
├── Exceptions
└── Analytics

Leave
├── Apply Leave
├── Leave Requests
├── Leave Balance
└── Leave Calendar

Visitors
├── Register Visitor
├── Active Visitors
├── Visitor Passes
└── Visitor History

Devices
├── Device List
├── Device Health
├── Command Center
└── Sync Status

Reports
├── Attendance Reports
├── Employee Reports
├── Device Reports
└── Export Center

Administration
├── Users
├── Roles
├── Permissions
├── Settings
└── Audit Logs
```

---

## Screen Specifications

### 1. Dashboard

**Purpose**: Executive overview of workforce status

**Layout**:
```
┌─────────────────────────────────────────────┐
│ KPI KPI KPI KPI KPI KPI KPI               │
├─────────────────────────────────────────────┤
│ Attendance Trend                            │
├─────────────────────────────────────────────┤
│ Department Stats                            │
├─────────────────────────────────────────────┤
│ Pending Work                                │
├─────────────────────────────────────────────┤
│ Quick Actions                               │
├─────────────────────────────────────────────┤
│ Activity Feed                               │
└─────────────────────────────────────────────┘
```

**KPIs**:
- Attendance % (today)
- Present count
- Absent count
- Late count
- Leave count
- Online devices
- Offline devices

**Widgets**:
- Attendance trend chart (7 days)
- Department distribution
- Pending approvals
- Missing punches
- Recent activity
- Quick actions

---

### 2. Employee List

**Purpose**: Primary workspace for HR to manage employees

**Layout**:
```
┌─────────────────────────────────────────────┐
│ [Search] [Filters] [+ Add] [Export]         │
├─────────────────────────────────────────────┤
│ ☐ │ Photo │ Name │ Dept │ Status │ Actions  │
│───┼───────┼──────┼──────┼────────┼──────────│
│ ☐ │ JD    │ John │ Eng  │ Active │ •••      │
│ ☐ │ JS    │ Jane │ Mktg │ Active │ •••      │
└─────────────────────────────────────────────┘
```

**Features**:
- Search by name, code, email
- Filter by department, branch, status
- Bulk selection
- Bulk actions (export, deactivate)
- Row actions (view, edit, attendance)
- Column sorting
- Pagination

---

### 3. Employee Profile

**Purpose**: Comprehensive employee workspace

**Layout**:
```
┌─────────────────────────────────────────────┐
│ [Photo] John Doe           [Edit] [More]    │
│         EMP001 • Engineering • Active        │
├─────────────────────────────────────────────┤
│ Current Status                              │
│ • Today: Present (09:05 AM)                 │
│ • Shift: General (09:00-18:00)              │
│ • Leave Balance: 12 days                    │
├─────────────────────────────────────────────┤
│ Overview | Attendance | Leaves | Devices    │
├─────────────────────────────────────────────┤
│ Personal Info          │ Employment Info    │
│ ───────────────────── │ ────────────────── │
│ Email: john@test.com   │ Code: EMP001       │
│ Phone: 1234567890      │ Dept: Engineering  │
└─────────────────────────────────────────────┘
```

**Tabs**:
- Overview: Personal + employment info
- Attendance: Attendance history
- Leaves: Leave balance + requests
- Devices: Assigned devices
- Emergency: Emergency contacts
- Activity: Activity timeline

---

### 4. Attendance Workspace

**Purpose**: Daily attendance management

**Layout**:
```
┌─────────────────────────────────────────────┐
│ Today: 45 present | 3 absent | 5 late       │
├─────────────────────────────────────────────┤
│ Today | Calendar | Timeline | Exceptions    │
├─────────────────────────────────────────────┤
│ [Tab Content]                               │
└─────────────────────────────────────────────┘
```

**Today Tab**:
- List of employees with today's status
- Quick filters: Present, Absent, Late, Leave
- Click → punch timeline

**Calendar Tab**:
- Monthly calendar with colored dots
- Click day → day details

**Exceptions Tab**:
- Missing punches
- Late arrivals
- Overtime
- Early departures

---

### 5. Device Operations

**Purpose**: Device monitoring and management

**Layout**:
```
┌─────────────────────────────────────────────┐
│ [Online] [Offline] [Error] [Total]          │
├─────────────────────────────────────────────┤
│ Device Grid                                 │
│ [Device] [Device] [Device] [Device]         │
├─────────────────────────────────────────────┤
│ Sync Status                                 │
├─────────────────────────────────────────────┤
│ Recent Errors                               │
└─────────────────────────────────────────────┘
```

---

### 6. Report Center

**Purpose**: Report generation and management

**Layout**:
```
┌──────────┬────────────────────┬─────────────┐
│ Categories│ Configuration      │ Preview     │
│           │                    │             │
│ Attendance│ Date: ________     │ [Preview]   │
│ Employee  │ Department: ____   │             │
│ Leave     │ Format: PDF/Excel  │             │
│           │                    │             │
│           │ [Download]         │             │
├──────────┴────────────────────┴─────────────┤
│ Recent Exports                              │
└─────────────────────────────────────────────┘
```

---

## Design Principles

### 1. Information Density
- Compact KPI cards (80px height)
- Dense tables (44px rows)
- Minimal whitespace between related elements
- Group related data

### 2. Visual Hierarchy
- Strong page titles (24px, w700)
- Section headers (11px, w600, uppercase, gray)
- Data values (large, bold)
- Labels (small, gray)

### 3. Productivity
- Fast search
- Bulk operations
- Keyboard shortcuts
- Context menus
- Quick actions

### 4. Consistency
- Design system
- Consistent spacing
- Consistent typography
- Consistent colors
- Consistent interactions
