# Apex HRMS — Project Structure

> **Version**: 1.0
> **Last Updated**: 2026-06-28
> **Stack**: FastAPI (Python) + Flutter (Dart) + PostgreSQL + Redis

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Module Architecture](#2-module-architecture)
3. [Backend Structure](#3-backend-structure)
4. [Frontend Structure](#4-frontend-structure)
5. [Database Structure](#5-database-structure)
6. [Security](#6-security)
7. [Deployment](#7-deployment)
8. [Development](#8-development)

---

## 1. Project Overview

### What is Apex

Apex is a **multi-tenant SaaS platform** combining Corporate HRMS and School ERP in a single codebase, single database, and single deployment. Tenants are either `corporate` (HRMS features) or `school` (School ERP features). Both tenant types share the same authentication, RBAC, notification, document, and audit infrastructure.

### Key Numbers

| Metric | Count |
|--------|-------|
| API routes | 442 |
| Database tables | 142 |
| Flutter screens | ~106 |
| Feature flags | 58 |
| RBAC permission codenames | 50+ |
| Backend source files | 133 |
| Frontend source files | ~80 |

### Architecture Principles

- **Single codebase**: Same backend, same frontend, same database for both HRMS and School
- **Multi-tenant isolation**: Shared-database, shared-schema with `tenant_id` FK on every business table
- **Feature-flagged**: School modules hidden behind feature flags, invisible to corporate tenants
- **RBAC**: Permission strings follow `resource.action` convention (e.g., `employees.read`)
- **Layer separation**: Endpoint → Service → Model → Database (no inline SQL in endpoints)
- **Reuse-first**: School reuses Auth, RBAC, Attendance, Payroll, Notifications, Documents, Accounting from the shared platform

---

## 2. Module Architecture

### Classification

| Layer | Core | Corporate | School | Admin | **Total** |
|-------|------|-----------|--------|-------|-----------|
| Models | 11 | 25 | 15 | 3 | 54 |
| Endpoints | 16 | 24 | 16 | 5 | 61 |
| Services | 5 | 13 | 0 | 0 | 18 |
| Database tables | 15 | 72 | 55 | — | 142 |
| Feature flags | 13 | 21 | 24 | — | 58 |

### 2.1 Core Platform (Shared)

Modules used by **all** tenant types (Corporate AND School).

| Module | Purpose |
|--------|---------|
| Authentication | Login, JWT, refresh tokens, password reset, MFA |
| RBAC | Roles, permissions, user-role mapping |
| Tenants | Multi-tenant entity, subscription, settings |
| Audit Logs | Immutable audit trail for all actions |
| Notifications | In-app, SMS, email, push notifications |
| Documents | File/document storage metadata |
| Dashboard | Dashboard data aggregation |
| Holidays | Tenant-scoped holiday calendar |
| Announcements | Company-wide announcements & polls |
| WebSocket | Real-time push updates |
| Import/Export | Bulk data import/export (CSV/Excel) |
| Setup Wizard | First-run configuration |

### 2.2 Corporate HRMS

Employee lifecycle modules. Only meaningful for `corporate` tenant type.

| Module | Purpose |
|--------|---------|
| Employee Management | Employee CRUD, departments, designations, branches |
| Attendance | Punch logs, daily summary, processing pipeline |
| Shift Management | Shifts, shift groups, shift rosters, department shifts |
| Leave Management | Leave types, balances, requests, approval |
| Payroll | Salary structures, payslips, loans |
| Recruitment (ATS) | Job requisitions, openings, candidates, interviews, offers |
| Performance | Review cycles, goals, reviews, competencies, recommendations |
| Visitor Management | Visitors, visitor passes, check-in/out |
| Access Control | Zones, doors, access levels, access logs |
| Device Management | Biometric devices, commands, health monitoring |
| eSSL Integration | 8-table biometric sync stack (server, sync, mapping, cursor, location) |
| Expense & Benefits | Expense claims, tax declarations, benefits |
| Onboarding | Employee onboarding task management |
| Exit Management | Resignation, clearance, exit interview |
| Overtime & Outdoor Duty | OT register, outdoor duty tracking |
| Travel & Assets | Travel requests, company asset tracking |
| Employee Self-Service | Self-service portal (attendance, leaves, payslips, profile) |
| Reports | 14 report types (attendance, overtime, visitors, devices) |
| HR Operations | Announcements, polls, notification templates, travel, assets |
| Timeline | Employee lifecycle events |

### 2.3 School ERP

Student lifecycle modules. Only visible to `school` tenant type behind feature flags.

| Module | Purpose |
|--------|---------|
| Academic Year | Sessions, terms, holiday calendar |
| Campus & Infrastructure | Campuses, buildings, rooms (links to branches) |
| Grade & Section | Grades, sections, houses |
| Student Management | Student master, guardians, siblings, medical |
| Subject & Teaching | Subjects, grade-subject mapping, teacher allocation |
| Timetable | Period definitions, timetable entries, substitutions |
| Student Attendance | Daily, period-wise, bus attendance |
| Homework & Assignments | Create, submit, evaluate |
| Examinations | Exam types, schedules, marks, grading scales |
| Fee Management | Fee categories, structures, payments, scholarships, fines |
| Transport | Routes, stops, student transport assignments |
| Hostel | Hostels, rooms, allocations |
| Library | Books, issue/return transactions |
| Lesson Planning | Unit plans, progress tracking |
| Communication | Circulars, school events |
| Medical & Discipline | Health records, discipline incidents |
| Certificates | Templates, issued certificates |
| Admissions | Inquiries, applications, enrollment pipeline |

### 2.4 Admin Panel

Platform-level super admin endpoints (not tenant-scoped).

| Module | Purpose |
|--------|---------|
| Super Admin Auth | Rate-limited superuser login |
| Admin Dashboard | Platform statistics, recent activity |
| Tenant Administration | CRUD, suspend/activate, limits, features |
| Subscription Plans | Plan CRUD, pricing |
| Feature Flags | Feature flag CRUD, seeding |
| Billing & Subscriptions | Subscription lifecycle (create, upgrade, renew, suspend, cancel) |
| Platform Analytics | Customer success, per-tenant analytics |

---

## 3. Backend Structure

**Framework**: FastAPI (async Python)
**ORM**: SQLAlchemy (async) with Alembic migrations
**Task Queue**: Celery with Redis broker
**Base URL**: `/api/v1`

### 3.1 Directory Layout

```
backend/
├── app/
│   ├── api/
│   │   └── v1/
│   │       ├── router.py                  # Route registration
│   │       └── endpoints/
│   │           ├── auth.py                # Authentication (8 routes)
│   │           ├── tenants.py             # Tenant management (5 routes)
│   │           ├── dashboard.py           # Dashboard analytics (10 routes)
│   │           ├── employees.py           # Employee CRUD (19 routes)
│   │           ├── lifecycle.py           # Employee lifecycle (8 routes)
│   │           ├── attendance.py          # Attendance (7 routes)
│   │           ├── shifts.py              # Shifts (7 routes)
│   │           ├── shift_groups.py        # Shift groups (5 routes)
│   │           ├── shift_rosters.py       # Shift rosters (5 routes)
│   │           ├── department_shifts.py   # Dept shifts (3 routes)
│   │           ├── leaves.py              # Leave management (8 routes)
│   │           ├── payroll.py             # Payroll (8 routes)
│   │           ├── visitors.py            # Visitors (8 routes)
│   │           ├── access_control.py      # Access control (8 routes)
│   │           ├── devices.py             # Devices (9 routes)
│   │           ├── commands.py            # Device commands (4 routes)
│   │           ├── essl_connector.py      # eSSL integration (26 routes)
│   │           ├── essl_locations.py      # eSSL locations (4 routes)
│   │           ├── recruitment.py         # Recruitment/ATS (23 routes)
│   │           ├── performance.py         # Performance (18 routes)
│   │           ├── assets.py              # Asset management (9 routes)
│   │           ├── reports.py             # Reports (14 routes)
│   │           ├── expense_benefits.py    # Expense & benefits (12 routes)
│   │           ├── hr_ops.py              # HR operations (16 routes)
│   │           ├── ess.py                 # Employee self-service (13 routes)
│   │           ├── holidays.py            # Holidays (4 routes)
│   │           ├── categories.py          # Categories (4 routes)
│   │           ├── tenant_settings.py     # Tenant settings (2 routes)
│   │           ├── work_codes.py          # Work codes (4 routes)
│   │           ├── outdoor_duties.py      # Outdoor duties (4 routes)
│   │           ├── ot_register.py         # OT register (4 routes)
│   │           ├── timeline.py            # Employee timeline (3 routes)
│   │           ├── onboarding.py          # Onboarding (4 routes)
│   │           ├── exit_requests.py       # Exit management (3 routes)
│   │           ├── notifications.py       # Notifications (legacy)
│   │           ├── notification_center.py # Notifications (unified)
│   │           ├── documents.py           # Document management
│   │           ├── settings_api.py        # System settings
│   │           ├── tenant_settings.py     # Tenant settings
│   │           ├── setup.py               # Setup wizard
│   │           ├── system.py              # Health check
│   │           ├── websocket.py           # WebSocket
│   │           ├── import_export.py       # Import/export
│   │           ├── operations.py          # Background jobs, branding
│   │           ├── billing.py             # Billing (admin)
│   │           ├── analytics.py           # Platform analytics (admin)
│   │           ├── admin/
│   │           │   ├── auth.py            # Super admin auth (1 route)
│   │           │   ├── dashboard.py       # Admin dashboard (2 routes)
│   │           │   ├── tenants.py         # Tenant admin (11 routes)
│   │           │   ├── plans.py           # Plan management (4 routes)
│   │           │   └── features.py        # Feature flags (5 routes)
│   │           └── school/
│   │               ├── academic_year.py   # Academic years (8 routes)
│   │               ├── grade_section.py   # Grades/sections/subjects (13 routes)
│   │               ├── student.py         # Student CRUD (7 routes)
│   │               ├── student_attendance.py # Student attendance (4 routes)
│   │               ├── homework.py        # Homework (5 routes)
│   │               ├── examination.py     # Examinations (11 routes)
│   │               ├── fee.py             # Fee management (8 routes)
│   │               ├── school_dashboard.py # School dashboard (2 routes)
│   │               ├── transport.py       # Transport (6 routes)
│   │               ├── hostel.py          # Hostel (6 routes)
│   │               ├── library.py         # Library (5 routes)
│   │               ├── timetable.py       # Timetable (7 routes)
│   │               ├── communication.py   # Circulars & events (4 routes)
│   │               ├── medical.py         # Medical & discipline (5 routes)
│   │               ├── certificate.py     # Certificates (4 routes)
│   │               └── admission.py       # Admissions (6 routes)
│   ├── models/
│   │   ├── tenant.py              # Tenant, tenant settings
│   │   ├── user.py                # Users
│   │   ├── role.py                # Roles, permissions
│   │   ├── employee.py            # Employee, departments, designations, branches
│   │   ├── attendance.py          # Attendance, punch logs
│   │   ├── shift.py               # Shifts
│   │   ├── shift_group.py         # Shift groups
│   │   ├── shift_roster.py        # Shift rosters
│   │   ├── department_shift.py    # Department shifts
│   │   ├── leave.py               # Leave types, balances, requests
│   │   ├── payroll.py             # Salary, payslips, loans
│   │   ├── visitor.py             # Visitors, passes
│   │   ├── access_control.py      # Zones, doors, access levels
│   │   ├── device.py              # Devices
│   │   ├── command.py             # Device commands
│   │   ├── essl_server.py         # eSSL servers
│   │   ├── essl_sync.py           # eSSL sync history, jobs, errors
│   │   ├── essl_mapping.py        # eSSL employee/device mappings
│   │   ├── essl_cursor.py         # eSSL sync cursors
│   │   ├── essl_location.py       # eSSL locations
│   │   ├── recruitment.py         # Job requisitions, openings, candidates, interviews, offers
│   │   ├── performance.py         # Review cycles, goals, reviews, competencies
│   │   ├── expense.py             # Expense categories, claims
│   │   ├── benefit.py             # Benefits, employee benefits
│   │   ├── tax.py                 # Tax declarations
│   │   ├── asset_travel.py        # Company assets, travel requests
│   │   ├── onboarding.py          # Onboarding tasks
│   │   ├── exit.py                # Exit requests
│   │   ├── timeline.py            # Employee events
│   │   ├── ot_register.py         # OT registers
│   │   ├── outdoor_duty.py        # Outdoor duties
│   │   ├── work_code.py           # Work codes
│   │   ├── notification.py        # Notifications
│   │   ├── notification_template.py # Notification templates
│   │   ├── document.py            # Documents
│   │   ├── audit_log.py           # Audit logs
│   │   ├── holiday.py             # Holidays
│   │   ├── announcement.py        # Announcements, polls
│   │   ├── category.py            # Categories
│   │   ├── tenant_settings.py     # Tenant settings
│   │   ├── feature.py             # Feature flags (global)
│   │   ├── subscription.py        # Subscription plans
│   │   ├── approval.py            # Approval workflows
│   │   └── school/
│   │       ├── academic_year.py   # Academic years, terms, holidays
│   │       ├── campus.py          # Campuses, buildings, rooms
│   │       ├── grade.py           # Grades, sections, houses
│   │       ├── student.py         # Students, guardians, siblings
│   │       ├── subject.py         # Subjects, grade-subjects, teacher allocations
│   │       ├── timetable.py       # Period definitions, timetable entries, substitutions
│   │       ├── student_attendance.py # Student attendance, summaries
│   │       ├── homework.py        # Homework, submissions, assignments
│   │       ├── examination.py     # Exam types, exams, schedules, marks, grading
│   │       ├── fee.py             # Fee categories, structures, payments, scholarships
│   │       ├── transport.py       # Transport routes, stops, student transport
│   │       ├── hostel.py          # Hostels, rooms, allocations
│   │       ├── library.py         # Library books, transactions
│   │       ├── lesson_plan.py     # Lesson plans
│   │       ├── communication.py   # School events, circulars
│   │       ├── medical.py         # Health records, discipline incidents
│   │       ├── certificate.py     # Certificate templates, issued certificates
│   │       └── admission.py       # Admission inquiries, applications
│   ├── schemas/                   # Pydantic request/response schemas (31 files)
│   ├── services/                  # Business logic layer (21 service files)
│   │   ├── tenant.py
│   │   ├── user.py
│   │   ├── employee.py
│   │   ├── attendance.py
│   │   ├── attendance_processor.py
│   │   ├── shift.py
│   │   ├── leave.py
│   │   ├── visitor.py
│   │   ├── access_control.py
│   │   ├── device.py
│   │   ├── command.py
│   │   ├── dashboard.py
│   │   ├── report.py
│   │   ├── notification.py
│   │   ├── websocket_manager.py
│   │   ├── essl_connector.py
│   │   ├── essl_soap.py
│   │   ├── essl_client.py
│   │   ├── essl_dashboard.py
│   │   ├── sync_audit.py
│   │   └── duplicate_detector.py
│   ├── core/
│   │   ├── config.py              # Settings (Pydantic BaseSettings)
│   │   ├── deps.py                # FastAPI dependencies (auth, RBAC, feature gate)
│   │   ├── security.py            # JWT, password hashing
│   │   ├── rbac.py                # RBAC engine
│   │   ├── feature_gate.py        # Feature flag engine (58 flags)
│   │   ├── encryption.py          # Field-level encryption
│   │   ├── password_policy.py     # Password rules
│   │   ├── seed.py                # Default data seeding
│   │   └── tenant_templates.py    # Tenant onboarding templates
│   ├── middleware/
│   │   ├── audit.py               # Audit logging middleware
│   │   ├── rate_limit.py          # Redis-backed rate limiting
│   │   ├── security_headers.py    # CSP, HSTS, X-Frame-Options
│   │   └── tenant.py              # Tenant extraction from header/JWT
│   ├── db/
│   │   ├── base.py                # SQLAlchemy Base, TenantModel, BaseModel mixins
│   │   └── session.py             # Async session factory
│   ├── tasks/
│   │   ├── celery_app.py          # Celery configuration
│   │   └── sync_tasks.py          # Background sync tasks
│   └── utils/
│       └── helpers.py             # Shared utility functions
├── alembic/
│   ├── env.py
│   └── versions/                  # Migration scripts
├── scripts/                       # Operational scripts
├── tests/                         # Test suite
├── uploads/                       # File upload storage
├── Dockerfile
├── alembic.ini
├── requirements.txt
└── pyproject.toml
```

### 3.2 Endpoint Count Summary

| Group | Endpoints |
|-------|-----------|
| **Core APIs** | 69 |
| **Corporate APIs** | 235 |
| **School APIs** | 111 |
| **Admin APIs** | 27 |
| **Total** | **442** |

### 3.3 Request Flow

```
Client Request
  → Middleware (CORS → Audit → RateLimit → Tenant → SecurityHeaders)
  → FastAPI Router
  → Dependency Injection (get_current_user → require_permissions → require_feature)
  → Endpoint (validates Pydantic schema)
  → Service (business logic, data aggregation)
  → Model/Database (SQLAlchemy async)
  → Response (Pydantic serialization)
```

### 3.4 Key Architectural Patterns

- **Multi-tenancy**: All tenant-scoped models inherit `TenantModel` which adds `tenant_id` column. Application-level filtering enforces isolation.
- **RBAC**: `require_permissions(*codenames)` dependency checks user holds ALL required permission codenames.
- **Feature flags**: `require_feature(feature_code)` dependency gates modules per tenant subscription.
- **Audit trail**: `AuditLog` model captures all write operations with actor, entity, and diff.
- **eSSL integration**: Dedicated 8-table stack with SOAP client, circuit breaker, incremental sync cursors, and duplicate detection.
- **Approval engine**: Generic 4-table workflow system (`approval_workflows → approval_steps → approval_requests → approval_history`) attached to any entity via polymorphic `entity_type` + `entity_id`.

---

## 4. Frontend Structure

**Framework**: Flutter (Dart)
**Platforms**: Web, Windows, Android, iOS
**State Management**: Provider pattern
**HTTP Client**: Dio
**Design System**: Custom Apex Design System (Material 3 based)

### 4.1 Directory Layout

```
frontend/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── constants.dart                 # App-wide constants
│   │   ├── dio_client.dart                # HTTP client with interceptors
│   │   ├── responsive.dart                # Responsive breakpoint utilities
│   │   ├── router.dart                    # GoRouter configuration
│   │   ├── secure_storage.dart            # Token/credential storage
│   │   └── theme.dart                     # Material 3 theme (light/dark)
│   ├── design_system/
│   │   ├── border_radius.dart             # Border radius tokens
│   │   ├── colors.dart                    # Color palette
│   │   ├── elevation.dart                 # Shadow/elevation tokens
│   │   ├── spacing.dart                   # Spacing scale
│   │   ├── status_colors.dart             # Semantic status colors
│   │   ├── typography.dart                # Type scale
│   │   └── components/
│   │       ├── apex_badge.dart            # Status badge
│   │       ├── apex_breadcrumb.dart       # Breadcrumb navigation
│   │       ├── apex_button.dart           # Button variants
│   │       ├── apex_card.dart             # Card component
│   │       ├── apex_empty_state.dart      # Empty state placeholder
│   │       ├── apex_filter_bar.dart        # Filter bar
│   │       ├── apex_loading_skeleton.dart # Loading skeleton
│   │       ├── apex_search_bar.dart       # Search bar
│   │       ├── apex_stat_card.dart        # Stat card
│   │       └── apex_table.dart            # Data table
│   ├── screens/
│   │   ├── login_screen.dart              # Login
│   │   ├── register_screen.dart           # Registration
│   │   ├── splash_screen.dart             # Splash
│   │   ├── main_shell.dart                # Sidebar + content shell
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart      # Executive dashboard
│   │   ├── employees/
│   │   │   ├── employee_list_screen.dart
│   │   │   ├── employee_detail_screen.dart
│   │   │   └── employee_create_screen.dart
│   │   ├── attendance/
│   │   │   ├── attendance_list_screen.dart
│   │   │   ├── attendance_detail_screen.dart
│   │   │   └── mark_attendance_screen.dart
│   │   ├── leaves/
│   │   │   ├── leave_requests_screen.dart
│   │   │   ├── leave_apply_screen.dart
│   │   │   └── leave_balance_screen.dart
│   │   ├── shifts/
│   │   │   ├── shift_list_screen.dart
│   │   │   ├── shift_group_screen.dart
│   │   │   └── shift_roster_screen.dart
│   │   ├── visitors/
│   │   │   ├── visitor_list_screen.dart
│   │   │   └── visitor_register_screen.dart
│   │   ├── devices/
│   │   │   ├── device_list_screen.dart
│   │   │   └── device_detail_screen.dart
│   │   ├── access_control/
│   │   ├── assets/
│   │   ├── commands/
│   │   ├── ess/
│   │   ├── finance/
│   │   ├── holidays/
│   │   ├── hr/
│   │   ├── notifications/
│   │   ├── payroll/
│   │   ├── performance/
│   │   ├── recruitment/
│   │   ├── reports/
│   │   ├── settings/
│   │   ├── setup/
│   │   ├── system/
│   │   ├── admin/
│   │   │   ├── admin_login_screen.dart
│   │   │   ├── admin_dashboard_screen.dart
│   │   │   ├── admin_tenant_list_screen.dart
│   │   │   ├── admin_tenant_detail_screen.dart
│   │   │   ├── admin_plan_screen.dart
│   │   │   ├── admin_feature_screen.dart
│   │   │   └── admin_analytics_screen.dart
│   │   └── school/
│   │       ├── school_dashboard_screen.dart
│   │       ├── student_list_screen.dart
│   │       ├── student_detail_screen.dart
│   │       ├── admission_screen.dart
│   │       ├── academic_year_screen.dart
│   │       ├── grade_section_screen.dart
│   │       ├── timetable_screen.dart
│   │       ├── attendance_mark_screen.dart
│   │       ├── homework_screen.dart
│   │       ├── exam_list_screen.dart
│   │       ├── fee_collection_screen.dart
│   │       ├── transport_screen.dart
│   │       ├── hostel_screen.dart
│   │       └── library_screen.dart
│   ├── models/                            # Dart data models (11 files)
│   │   ├── employee.dart
│   │   ├── attendance.dart
│   │   ├── leave.dart
│   │   ├── shift.dart
│   │   ├── visitor.dart
│   │   ├── device.dart
│   │   ├── dashboard.dart
│   │   ├── notification.dart
│   │   ├── user.dart
│   │   ├── access_control.dart
│   │   └── essl_server.dart
│   ├── services/                          # API client services (14 files)
│   │   ├── auth_service.dart
│   │   ├── employee_service.dart
│   │   ├── attendance_service.dart
│   │   ├── leave_service.dart
│   │   ├── shift_service.dart
│   │   ├── visitor_service.dart
│   │   ├── device_service.dart
│   │   ├── dashboard_service.dart
│   │   ├── report_service.dart
│   │   ├── notification_service.dart
│   │   ├── access_control_service.dart
│   │   ├── command_service.dart
│   │   ├── essl_service.dart
│   │   └── websocket_service.dart
│   ├── providers/                         # State management (10 files)
│   │   ├── auth_provider.dart
│   │   ├── employee_provider.dart
│   │   ├── attendance_provider.dart
│   │   ├── leave_provider.dart
│   │   ├── shift_provider.dart
│   │   ├── visitor_provider.dart
│   │   ├── device_provider.dart
│   │   ├── dashboard_provider.dart
│   │   ├── notification_provider.dart
│   │   └── essl_provider.dart
│   └── widgets/                           # Reusable widgets (17 files)
│       ├── apex_app_bar.dart
│       ├── apex_badge.dart
│       ├── apex_button.dart
│       ├── apex_card.dart
│       ├── apex_date_picker.dart
│       ├── apex_dropdown.dart
│       ├── apex_section.dart
│       ├── apex_text_field.dart
│       ├── chart_card.dart
│       ├── date_range_picker.dart
│       ├── empty_state.dart
│       ├── error_widget.dart
│       ├── loading_widget.dart
│       ├── paginated_list.dart
│       ├── search_bar.dart
│       ├── stat_card.dart
│       └── status_badge.dart
├── assets/                                # Static assets (images, fonts)
├── web/                                   # Web build configuration
├── windows/                               # Windows build configuration
├── test/                                  # Widget/unit tests
├── pubspec.yaml
└── analysis_options.yaml
```

### 4.2 Screen Inventory

| Category | Screens | Example |
|----------|---------|---------|
| Corporate HRMS | ~45 | Employees, Attendance, Leave, Shifts, Payroll, Visitors, Devices, eSSL, Recruitment, Performance, Reports |
| School ERP | ~40 | Students, Admissions, Timetable, Homework, Exams, Fees, Transport, Hostel, Library |
| Admin Panel | 7 | Dashboard, Tenants, Plans, Features, Analytics |
| Core/Shared | ~14 | Login, Dashboard, Notifications, Documents, Settings, Setup |
| **Total** | **~106** | |

### 4.3 Sidebar Navigation

The sidebar renders conditionally based on `user.isSchool` (tenant type):

```
WORKSPACE           (always visible)
  Dashboard
  Employees
  Attendance

MANAGEMENT          (always visible)
  Leave
  Holidays
  Visitors
  Announcements
  Exit Requests

OPERATIONS          (corporate only)
  Shifts
  Devices
  Outdoor Duty
  OT Register
  Travel
  Assets
  Reports

FINANCE             (corporate only)
  Payroll
  Expenses
  Documents

SCHOOL              (school only)
  School Dashboard
  Students
  Admissions
  Attendance
  Timetable
  Homework
  Examinations
  Fee Collection
  Transport
  Hostel
  Library
  Classes
  Academic Year

Administration      (always visible)
  Settings
```

---

## 5. Database Structure

**Database**: PostgreSQL 16
**ORM**: SQLAlchemy (async) with Alembic migrations
**Primary Keys**: UUID (`gen_random_uuid()`)
**Tenant Isolation**: Shared-database, shared-schema with `tenant_id` FK + `ON DELETE CASCADE`

### 5.1 Base Classes (`app/db/base.py`)

| Mixin | Purpose |
|-------|---------|
| `UUIDPrimaryKeyMixin` | `id UUID PK` with auto-generated default |
| `TimestampMixin` | `created_at`, `updated_at` with auto-update |
| `TenantMixin` | `tenant_id UUID FK → tenants.id CASCADE` |
| `BaseModel` | Abstract: UUID + Timestamps (for global tables) |
| `TenantModel` | Abstract: UUID + Timestamps + TenantMixin (for tenant-scoped tables) |

### 5.2 Core Tables (15 tables)

Shared infrastructure used by both corporate and school tenants.

| # | Table | Purpose |
|---|-------|---------|
| 1 | `tenants` | Multi-tenant entity (name, slug, domain, tenant_type, subscription) |
| 2 | `tenant_settings` | Per-tenant configuration (attendance rules, shift settings) |
| 3 | `users` | User accounts (email, password, is_active, is_superuser) |
| 4 | `roles` | RBAC roles |
| 5 | `permissions` | Granular permissions (codename, module) |
| 6 | `user_roles` | User ↔ Role (M2M) |
| 7 | `role_permissions` | Role ↔ Permission (M2M) |
| 8 | `subscription_plans` | Global plan catalog (pricing, limits) |
| 9 | `tenant_subscriptions` | Tenant subscription state |
| 10 | `resource_limits` | Per-tenant resource quotas |
| 11 | `feature_flags` | Global feature definitions (58 flags) |
| 12 | `tenant_features` | Per-tenant feature enablement |
| 13 | `audit_logs` | Immutable audit trail |
| 14 | `login_history` | Login attempt tracking |
| 15 | `super_admin_logs` | Platform-wide admin audit (global, no tenant_id) |

### 5.3 Corporate Tables (72 tables)

| Group | Tables | Key Tables |
|-------|--------|------------|
| Organization | 5 | departments, designations, branches, employees, employee_categories |
| Shifts | 7 | shifts, shift_schedules, shift_groups, shift_group_members, shift_rosters, shift_roster_entries, department_shifts |
| Devices | 3 | devices, device_logs, device_commands |
| Attendance | 3 | attendances, punch_logs, attendance_raw_logs |
| Leave | 3 | leave_types, leave_balances, leave_requests |
| Holiday | 1 | holidays |
| Visitors | 2 | visitors, visitor_passes |
| Access Control | 4 | access_zones, doors, user_access_levels, access_logs |
| Notifications | 2 | notifications, notification_templates |
| Approvals | 4 | approval_workflows, approval_steps, approval_requests, approval_history |
| Announcements | 3 | announcements, polls, poll_responses |
| Benefits | 2 | benefits, employee_benefits |
| Documents | 1 | documents |
| Exit | 1 | exit_requests |
| Expenses | 2 | expense_categories, expense_claims |
| Onboarding | 1 | onboarding_tasks |
| Overtime/Outdoor | 2 | ot_register, outdoor_duties |
| Payroll | 3 | salary_structures, pay_slips, loans |
| Performance | 5 | review_cycles, goals, performance_reviews, competencies, performance_recommendations |
| Recruitment | 5 | job_requisitions, job_openings, candidates, interviews, offers |
| Tax | 1 | tax_declarations |
| Timeline/Assets | 4 | employee_events, work_codes, company_assets, travel_requests |
| eSSL Integration | 8 | essl_servers, essl_sync_history, essl_sync_jobs, essl_sync_errors, essl_employee_mapping, essl_device_mapping, essl_sync_cursor, essl_locations |

### 5.4 School Tables (55 tables)

| Group | Tables | Key Tables |
|-------|--------|------------|
| Academic Structure | 3 | academic_years, academic_terms, school_holidays |
| Campus & Infrastructure | 3 | campuses, buildings, rooms |
| Grade & Section | 3 | grades, sections, houses |
| Student Management | 4 | students, guardians, student_guardians, student_siblings |
| Subject & Teaching | 3 | subjects, grade_subjects, teacher_allocations |
| Timetable | 3 | period_definitions, timetable_entries, substitutions |
| Student Attendance | 2 | student_attendance, student_attendance_summary |
| Homework & Assignments | 4 | homework, homework_submissions, assignments, assignment_submissions |
| Examinations | 6 | exam_types, exams, exam_schedules, exam_marks, grading_scales, grading_scale_details |
| Fee Management | 7 | fee_categories, fee_structures, student_fees, fee_payments, fee_fine_rules, scholarships, student_scholarships |
| Transport | 3 | transport_routes, transport_stops, student_transport |
| Hostel | 3 | hostels, hostel_rooms, hostel_allocations |
| Library | 2 | library_books, library_transactions |
| Lesson Planning | 1 | lesson_plans |
| Communication | 2 | school_events, circulars |
| Medical & Discipline | 2 | health_records, discipline_incidents |
| Certificates | 2 | certificate_templates, issued_certificates |
| Admissions | 2 | admission_inquiries, admission_applications |

### 5.5 Cross-Module Shared Tables

Tables used by both Corporate and School:

| Table | Shared Usage |
|-------|-------------|
| `tenants` | Root record for all tenants |
| `users` | Authentication & authorization |
| `roles` / `permissions` | RBAC |
| `employees` | Teachers are employees in school context |
| `departments` | Academic departments in school context |
| `branches` | Campus mapping via `campuses.branch_id` |
| `audit_logs` | Shared audit trail |
| `notifications` | Shared notification system |
| `documents` | Shared document storage |

### 5.6 FK Dependency Tree

```
tenants
├── users → user_roles → roles → role_permissions → permissions
├── employees
│   ├── attendances → shifts
│   ├── punch_logs → devices
│   ├── leave_requests → leave_types
│   ├── salary_structures, pay_slips, loans
│   ├── performance_reviews → review_cycles
│   ├── goals → review_cycles
│   ├── candidates → job_openings → job_requisitions
│   └── exit_requests
├── students
│   ├── student_attendance → academic_years
│   ├── exam_marks → exam_schedules → exams → exam_types
│   ├── student_fees → fee_structures → fee_categories
│   ├── fee_payments → student_fees
│   ├── homework_submissions → homework → subjects
│   ├── student_transport → transport_routes → transport_stops
│   ├── hostel_allocations → hostels, hostel_rooms
│   ├── health_records, discipline_incidents
│   └── issued_certificates → certificate_templates
├── essl_servers
│   ├── essl_sync_history → essl_sync_errors
│   ├── essl_sync_jobs
│   ├── essl_employee_mapping → employees
│   ├── essl_device_mapping → devices
│   ├── essl_sync_cursor
│   └── essl_locations
└── approval_workflows → approval_steps, approval_requests → approval_history
```

### 5.7 Tenant Isolation

| Isolation Pattern | Tables |
|------------------|--------|
| Has `tenant_id` FK | 139 tables |
| Global (no tenant_id) | 3 tables: `feature_flags`, `subscription_plans`, `super_admin_logs` |

All 139 tenant-scoped tables use `ON DELETE CASCADE` on `tenant_id`, ensuring complete data cleanup when a tenant is deleted.

---

## 6. Security

### 6.1 Authentication

- **JWT Bearer tokens**: Access token (short-lived) + Refresh token (long-lived)
- **Token revocation**: Server-side revocation check on every request
- **Password hashing**: bcrypt with configurable rounds
- **Password policy**: Minimum length, complexity requirements
- **Account lockout**: Failed login attempts tracked; account locked after threshold
- **MFA**: Supported (configurable per tenant)

### 6.2 Authorization (RBAC)

- **Permission model**: `resource.action` convention (e.g., `employees.read`, `payroll.write`)
- **50+ permission codenames** covering all modules
- **System roles**: Predefined roles (Super Admin, HR Admin, Manager, Employee, Principal, Teacher, etc.)
- **Custom roles**: Tenants can create custom roles with granular permission sets
- **Dependency injection**: `require_permissions(*codenames)` FastAPI dependency enforces checks
- **Superuser bypass**: `is_superuser=True` users bypass all permission and feature flag checks

### 6.3 Tenant Isolation

- **Shared-database, shared-schema**: All tenants share the same PostgreSQL database and tables
- **Row-level isolation**: Every business table has `tenant_id` FK with `ON DELETE CASCADE`
- **Tenant extraction**: Middleware extracts tenant from `X-Tenant-ID` header or JWT claim
- **Automatic scoping**: `TenantModel` base class auto-filters by `tenant_id`
- **CASCADE delete**: Deleting a tenant removes all associated data across 139 tables

### 6.4 Feature Flags

- **58 feature flags** grouped into:
  - **Core (13)**: Shared by all tenants (API access, reports, analytics, ESS, chat, branding, access control, biometric, device)
  - **Corporate (21)**: HRMS-only (attendance, leave, shift, payroll, recruitment, performance, etc.)
  - **School (24)**: School ERP-only (student management, admissions, timetable, exams, fees, transport, etc.)
- **Gating**: `require_feature(feature_code)` dependency blocks access if feature is disabled for tenant
- **Admin management**: Super admin can enable/disable features per tenant via `/admin/features`

### 6.5 Middleware Stack

| Order | Middleware | Purpose |
|-------|-----------|---------|
| 1 | CORS | Cross-origin request handling |
| 2 | Audit | Logs all mutating requests to `audit_logs` |
| 3 | RateLimit | Redis-backed per-user/IP rate limiting |
| 4 | Tenant | Extracts tenant from header/JWT |
| 5 | SecurityHeaders | CSP, HSTS, X-Frame-Options |

### 6.6 API Security

- All endpoints require authentication (except `/auth/login`, `/auth/register`)
- Permission checks via `require_permissions` dependency
- Rate limiting on sensitive endpoints (login: 5/min, admission forms, etc.)
- File upload validation (type, size) for documents
- Input validation via Pydantic schemas on all endpoints
- Encrypted fields for sensitive data (eSSL passwords, etc.)

---

## 7. Deployment

### 7.1 Docker Stack

```yaml
services:
  postgres:       # PostgreSQL 16 Alpine (port 5434)
  redis:          # Redis 7 Alpine (port 6380)
  backend:        # FastAPI + Uvicorn (port 8001, 4 workers)
  celery_worker:  # Celery worker (concurrency 4)
  celery_beat:    # Celery beat scheduler
```

### 7.2 Infrastructure

| Component | Technology | Port |
|-----------|-----------|------|
| API Server | FastAPI + Uvicorn | 8001 |
| Database | PostgreSQL 16 | 5434 |
| Cache/Queue | Redis 7 | 6380 |
| Task Queue | Celery (Redis broker) | — |
| Frontend | Flutter Web (Nginx) | 80/443 |
| Reverse Proxy | Nginx | 80/443 |

### 7.3 Migrations

```bash
# Generate migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback
alembic downgrade -1
```

### 7.4 Configuration

Environment variables (`.env` file):

| Variable | Purpose |
|----------|---------|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `SECRET_KEY` | JWT signing key |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` | Database credentials |
| `API_V1_PREFIX` | API route prefix (default: `/api/v1`) |
| `CORS_ORIGINS` | Allowed CORS origins |
| `SENTRY_DSN` | Error tracking (optional) |

### 7.5 Background Tasks (Celery)

| Task | Schedule | Purpose |
|------|----------|---------|
| eSSL sync | Configurable | Biometric data synchronization |
| Fee reminders | Daily | SMS/push for overdue fees |
| Attendance summary | Daily | Aggregate student attendance |
| Report card generation | Batch | PDF generation |
| Library overdue | Daily | Overdue book reminders |
| Subscription expiry | Daily | Check expired subscriptions |

---

## 8. Development

### 8.1 Quick Start

```bash
# Start infrastructure
docker-compose up -d postgres redis

# Backend
cd backend
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload --port 8000

# Frontend
cd frontend
flutter pub get
flutter run -d chrome
```

### 8.2 Key Files

| File | Purpose |
|------|---------|
| `backend/app/main.py` | FastAPI app factory, middleware registration |
| `backend/app/api/v1/router.py` | Route registration |
| `backend/app/core/deps.py` | Auth, RBAC, feature gate dependencies |
| `backend/app/core/feature_gate.py` | 58 feature flag definitions |
| `backend/app/db/base.py` | SQLAlchemy base classes (TenantModel, BaseModel) |
| `frontend/lib/main.dart` | Flutter app entry point |
| `frontend/lib/core/router.dart` | GoRouter route definitions |
| `frontend/lib/screens/main_shell.dart` | Sidebar + content layout |
| `docker-compose.yml` | Full stack definition |

### 8.3 Documentation Files

| File | Content |
|------|---------|
| `PROJECT_STRUCTURE.md` | This file — project architecture overview |
| `API_MODULE_MAP.md` | Complete 442-endpoint API reference |
| `DATABASE_MODULE_MAP.md` | Complete 142-table database reference |
| `MODULE_ARCHITECTURE.md` | Module classification (Core/Corporate/School/Admin) |
| `FEATURE_GROUPING.md` | Feature flag grouping (58 flags) |
| `APEX_SCHOOL_ERP_ARCHITECTURE.md` | School ERP blueprint (DB schema, workflows, screen inventory) |
| `INFORMATION_ARCHITECTURE.md` | Navigation structure and data flow |
| `SIDEBAR_INFORMATION_ARCHITECTURE.md` | Sidebar navigation design |
| `ARCHITECTURE_AUDIT.md` | Layer separation violations and remediation |
| `DESIGN_SYSTEM.md` | Apex Design System documentation |
| `PERMISSION_MATRIX.md` | RBAC permission matrix |
| `INSTALLATION_GUIDE.md` | Setup instructions |
| `DEPLOYMENT_CHECKLIST.md` | Production deployment checklist |
