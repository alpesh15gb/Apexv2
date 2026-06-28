# PERMISSION_GROUPING.md

## Overview

This document defines the RBAC permission structure for Apex HRMS, organized by tenant type. Permissions follow the `module.action` naming convention and are grouped into **Core** (shared), **Corporate**, and **School** categories.

---

## Current State (from `backend/app/core/rbac.py`)

The existing `create_default_roles` function defines 4 roles:

| Role | Codename | Permissions |
|------|----------|-------------|
| Super Admin | `super_admin` | `*` (all) |
| HR Admin | `hr_admin` | employee CRUD, attendance read/manage, leave approve/read, shift manage/read, report read, visitor manage/read |
| Manager | `manager` | employee read, attendance read/approve, leave approve/read, report read, visitor read |
| Employee | `employee` | attendance read_own, leave apply/read_own, visitor create |

School-specific roles are defined in `backend/app/core/tenant_templates.py`:
- Principal, Vice Principal, Academic Coordinator, Class Teacher, Subject Teacher, Accountant, Librarian, Transport Manager, Hostel Warden, Receptionist, Parent, Student

---

## Proposed Permission Grouping

### Core Permissions (shared across all tenant types)

| Module | Permissions | Description |
|--------|-------------|-------------|
| `dashboard` | `read` | View dashboards |
| `notification` | `read`, `manage` | View and manage notifications |
| `document` | `read`, `manage` | View and manage documents |
| `settings` | `read`, `manage` | View and manage settings |
| `report` | `read` | View reports |
| `import_export` | `read`, `manage` | View and manage import/export operations |

### Corporate Permissions

| Module | Permissions | Description |
|--------|-------------|-------------|
| `employee` | `create`, `read`, `update`, `delete` | Employee CRUD |
| `attendance` | `read`, `manage`, `approve` | View, manage, and approve attendance |
| `leave` | `read`, `apply`, `approve` | View, apply, and approve leave |
| `shift` | `read`, `manage` | View and manage shifts |
| `payroll` | `read`, `manage`, `process` | View, manage, and process payroll |
| `visitor` | `read`, `create`, `manage` | View, create, and manage visitors |
| `device` | `read`, `manage` | View and manage biometric devices |
| `recruitment` | `read`, `manage` | View and manage recruitment |
| `performance` | `read`, `manage` | View and manage performance reviews |
| `asset` | `read`, `manage` | View and manage assets |
| `expense` | `read`, `manage` | View and manage expenses |
| `lifecycle` | `manage` | Manage employee lifecycle (onboarding, exit) |

### School Permissions

| Module | Permissions | Description |
|--------|-------------|-------------|
| `student` | `create`, `read`, `update`, `delete` | Student CRUD |
| `student_attendance` | `read`, `mark` | View and mark student attendance |
| `homework` | `read`, `create` | View and create homework |
| `exam` | `read`, `manage` | View and manage examinations |
| `marks` | `enter`, `read` | Enter and view marks |
| `fee` | `read`, `manage`, `collect` | View, manage, and collect fees |
| `transport` | `read`, `manage` | View and manage transport |
| `hostel` | `read`, `manage` | View and manage hostel |
| `library` | `read`, `manage` | View and manage library |
| `timetable` | `read`, `manage` | View and manage timetable |
| `circular` | `read`, `publish` | View and publish circulars |
| `medical` | `read`, `manage` | View and manage medical records |
| `discipline` | `read`, `manage` | View and manage discipline records |
| `admission` | `read`, `manage` | View and manage admissions |
| `certificate` | `read`, `issue` | View and issue certificates |
| `academic_year` | `read`, `manage` | View and manage academic years |
| `class` | `read`, `manage` | View and manage classes |

---

## Role Assignments per Tenant Type

### Corporate Tenant Roles

| Role | Codename | Core | Corporate | Notes |
|------|----------|------|-----------|-------|
| Super Admin | `super_admin` | all | all | Wildcard `*` |
| HR Admin | `hr_admin` | dashboard.read, notification.manage, document.manage, settings.manage, report.read | employee.*, attendance.read/manage, leave.approve/read, shift.manage/read, visitor.manage/read | Full employee lifecycle |
| Manager | `manager` | dashboard.read, notification.read, document.read, report.read | employee.read, attendance.read/approve, leave.approve/read, visitor.read | Team oversight |
| Employee | `employee` | dashboard.read, notification.read, document.read | attendance.read, leave.apply/read, visitor.create | Self-service |
| Payroll Admin | `payroll_admin` | dashboard.read, report.read | payroll.manage/process | Payroll operations |
| Recruitment Lead | `recruitment_lead` | dashboard.read | recruitment.manage | Hiring pipeline |
| Finance Manager | `finance_manager` | dashboard.read, report.read | expense.manage, payroll.read | Financial oversight |

### School Tenant Roles

| Role | Codename | Core | School | Notes |
|------|----------|------|--------|-------|
| Super Admin | `super_admin` | all | all | Wildcard `*` |
| Principal | `principal` | all | all school perms | Full academic access |
| Vice Principal | `vice_principal` | dashboard.read, notification.manage, report.read | student.read, attendance.*, exam.manage, marks.read, discipline.manage, admission.manage | Academic management |
| Academic Coordinator | `academic_coordinator` | dashboard.read, report.read | class.manage, timetable.manage, exam.manage, marks.read, homework.read | Cross-grade coordination |
| Class Teacher | `class_teacher` | dashboard.read, notification.read | student.read, student_attendance.mark, homework.create, marks.enter/read, discipline.read | Class-level access |
| Subject Teacher | `subject_teacher` | dashboard.read, notification.read | homework.create, marks.enter/read, exam.read | Subject-level access |
| Accountant | `school_accountant` | dashboard.read, report.read | fee.manage/collect | Fee management |
| Librarian | `librarian` | dashboard.read | library.manage | Library operations |
| Transport Manager | `transport_manager` | dashboard.read | transport.manage | Transport operations |
| Hostel Warden | `hostel_warden` | dashboard.read | hostel.manage | Hostel operations |
| Receptionist | `receptionist` | dashboard.read, notification.read | admission.read, certificate.read | Front desk |
| Parent | `parent` | dashboard.read, notification.read | student.read, fee.read, homework.read, exam.read, marks.read, transport.read | Parent portal |
| Student | `student` | dashboard.read, notification.read | homework.read, exam.read, timetable.read, library.read, fee.read | Student portal |

---

## Permission Check Implementation Notes

- `super_admin` codename bypasses all permission checks (see `rbac.py:31`)
- Permissions are tenant-scoped via `tenant_id` foreign key
- `UserRole` and `RolePermission` are many-to-many with tenant isolation
- Modules are auto-derived from codename prefix (e.g., `employee.create` → module `employee`)
