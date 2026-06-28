# Module Dependency Report — Apex HRMS

**Generated**: 2026-06-28  
**Scope**: `backend/app/api/v1/endpoints/`, `backend/app/services/`, `backend/app/models/`

---

## 1. Module Classification

### Core Modules (shared infrastructure)
Top-level packages serving all tenant types:

| Layer | Path | Files |
|-------|------|-------|
| Models | `app.models.*` | 44 files (user, tenant, employee, attendance, device, shift, leave, payroll, etc.) |
| Services | `app.services.*` | 21 files (attendance, employee, shift, leave, visitor, device, etc.) |
| Endpoints | `app.api.v1.endpoints.*` | 45 files (auth, employees, attendance, payroll, etc.) |

### School Modules
Isolated sub-packages for school ERP:

| Layer | Path | Files |
|-------|------|-------|
| Models | `app.models.school.*` | 19 files (student, fee, examination, transport, hostel, library, etc.) |
| Services | `app.services.school.*` | 5 files (admission, attendance, exam, fee, student) |
| Endpoints | `app.api.v1.endpoints.school.*` | 16 files (academic_year, admission, certificate, etc.) |

### Admin/Corporate Modules
Admin endpoints for super-admin operations:

| Layer | Path | Files |
|-------|------|-------|
| Endpoints | `app.api.v1.endpoints.admin.*` | 5 files (auth, dashboard, tenants, plans, features) |

> **Note**: "Corporate" is a tenant type (`tenant_type="corporate"`) defined in `app.models.tenant`, not a separate module. Corporate-specific features (recruitment, performance) live in Core modules.

---

## 2. Dependency Graph

```
┌─────────────────────────────────────────────────────────────┐
│                        SHARED INFRA                         │
│  app.core.*  │  app.db.*  │  app.schemas.*  │  app.middleware│
└──────┬───────┴─────┬──────┴───────┬─────────┴───────┬───────┘
       │             │              │                 │
       ▼             ▼              ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│                     CORE MODELS (44)                         │
│  user, tenant, employee, attendance, device, shift, leave,  │
│  payroll, visitor, notification, subscription, feature,     │
│  recruitment*, performance*, ...                            │
└──────┬──────────────────────────────────────┬───────────────┘
       │                                      │
       ▼                                      ▼
┌──────────────────────┐          ┌───────────────────────────┐
│   CORE SERVICES (21) │          │    CORE ENDPOINTS (45)    │
│  attendance, employee│◄─────────│  auth, employees, payroll │
│  shift, leave, ...   │          │  attendance, shifts, ...  │
└──────────────────────┘          └───────────────────────────┘

       ▲ Shared deps (User, Tenant, get_db, require_feature)
       │
┌──────┴──────────────────────────────────────────────────────┐
│                    SCHOOL MODELS (19)                         │
│  student, fee, examination, transport, hostel, library,     │
│  academic_year, admission, certificate, ...                 │
└──────┬──────────────────────────────────────┬───────────────┘
       │                                      │
       ▼                                      ▼
┌──────────────────────┐          ┌───────────────────────────┐
│   SCHOOL SERVICES (5)│          │   SCHOOL ENDPOINTS (16)   │
│  admission, exam,    │◄─────────│  student, fee, exam,      │
│  fee, student, attn  │          │  transport, hostel, ...   │
└──────────────────────┘          └───────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                  ADMIN ENDPOINTS (5)                         │
│  auth, dashboard, tenants, plans, features                  │
│  ── depends on → Core models (Tenant, User, Employee,       │
│                  SubscriptionPlan, FeatureFlag)              │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. Detailed Dependency Mapping

### 3.1 Core Endpoints → Models

| Endpoint | Models Imported |
|----------|----------------|
| `auth.py` | User, Tenant |
| `employees.py` | User |
| `attendance.py` | User |
| `payroll.py` | User, Employee, Attendance, SalaryStructure, PaySlip, Loan |
| `leaves.py` | User |
| `shifts.py` | User |
| `devices.py` | User |
| `visitors.py` | User |
| `ess.py` | User, Employee, Attendance, PunchLog, LeaveRequest, LeaveBalance, LeaveType, PaySlip, Document, Announcement, Notification, ExpenseClaim |
| `essl_connector.py` | User, EsslServer, EsslSyncHistory, EsslSyncError, EsslEmployeeMapping, EsslDeviceMapping, EsslSyncCursor, AttendanceRawLog, Device, Employee |
| `billing.py` | User, Tenant, SubscriptionPlan, TenantSubscription |
| `analytics.py` | User, Tenant, Employee, TenantSubscription, LoginHistory |
| `recruitment.py` | User, JobRequisition, JobOpening, Candidate, Interview, Offer |
| `performance.py` | User, ReviewCycle, Goal, PerformanceReview, Competency, PerformanceRecommendation |
| `setup.py` | User, Tenant, Department, Designation, Branch, Shift, LeaveType, EmployeeCategory |

### 3.2 Core Services → Models

| Service | Models Imported |
|---------|----------------|
| `attendance.py` | Attendance, PunchLog, Employee, Shift, ShiftSchedule, LeaveRequest |
| `employee.py` | Employee, Department, Designation, Branch, Device, DeviceCommand |
| `leave.py` | LeaveType, LeaveBalance, LeaveRequest, Employee |
| `shift.py` | Shift, ShiftSchedule, Employee |
| `dashboard.py` | Employee, Device, Attendance, VisitorPass, LeaveRequest, AuditLog, EsslServer, EsslSyncHistory |
| `report.py` | Attendance, Employee, Device, VisitorPass, Shift |
| `essl_connector.py` | EsslServer, EsslSync*, EsslMapping, EsslCursor, EsslLocation, Employee, Device, AttendanceRawLog |
| `tenant.py` | Tenant, SubscriptionPlan |
| `user.py` | User, Role |

### 3.3 School Endpoints → Dependencies

| Endpoint | Dependencies |
|----------|-------------|
| `student.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `StudentService` |
| `fee.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `FeeService` |
| `examination.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `ExamService` |
| `admission.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `AdmissionService` |
| `school_dashboard.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `Student`, `StudentAttendance`, `StudentFee`, `FeePayment`, `Grade`, `Section`, `Exam` |
| `transport.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `TransportRoute`, `TransportStop`, `StudentTransport`, `Student` |
| `hostel.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `Hostel`, `HostelRoom`, `HostelAllocation`, `Student` |
| `library.py` | Core: `User`, `get_db`, `require_feature`, `require_permissions`<br>School: `LibraryBook`, `LibraryTransaction` |

### 3.4 School Services → Dependencies

| Service | Dependencies |
|---------|-------------|
| `student_service.py` | School: `Student`, `Guardian`, `StudentGuardian` |
| `fee_service.py` | School: `FeeCategory`, `FeeStructure`, `StudentFee`, `FeePayment`, `Student` |
| `exam_service.py` | School: `ExamType`, `Exam`, `ExamSchedule`, `ExamMark`, `GradingScale`, `GradingScaleDetail`, `Student` |
| `admission_service.py` | School: `AdmissionInquiry`, `AdmissionApplication`, `Student` |
| `attendance_service.py` | School: `StudentAttendance`, `Student` |

### 3.5 School Models → Dependencies

All 19 school models depend **only** on:
- `app.db.base.TenantModel` (shared ORM base)
- Standard SQLAlchemy/PostgreSQL types

No school model imports any core model or any other school model.

### 3.6 Admin Endpoints → Dependencies

| Endpoint | Dependencies |
|----------|-------------|
| `auth.py` | Core: `User`, `get_db`, `verify_password`, `create_access_token` |
| `dashboard.py` | Core: `Tenant`, `User`, `Employee`, `TenantSubscription` |
| `tenants.py` | Core: `Tenant`, `User`, `Employee`, `TenantSubscription`, `ResourceLimit`, `SubscriptionPlan`, `TenantFeature`, `FeatureFlag`<br>Core: `app.core.tenant_templates` |
| `plans.py` | Core: `User`, `SubscriptionPlan` |
| `features.py` | Core: `User`, `FeatureFlag`, `app.core.feature_gate` |

---

## 4. Cross-Module Dependency Violations

### 4.1 Core → School: ✅ NO VIOLATIONS

No core endpoint, service, or model imports from `app.models.school`, `app.services.school`, or `app.api.v1.endpoints.school`.

### 4.2 Core → Admin: ✅ NO VIOLATIONS

No core endpoint or service imports from `app.api.v1.endpoints.admin`. The `admin` endpoints are consumers of core models, not the reverse.

### 4.3 School → Corporate: ✅ NO VIOLATIONS

School modules do not import from admin endpoints or any corporate-specific module. School modules depend only on shared core infrastructure (`User`, `get_db`, `require_feature`, `require_permissions`).

### 4.4 Corporate → School: ✅ NO VIOLATIONS

Admin endpoints do not import from any school module.

### 4.5 Circular Dependencies: ✅ NONE DETECTED

Dependency flow is strictly one-directional:
```
School ──► Core ──► Shared Infra
Admin  ──► Core ──► Shared Infra
```

---

## 5. Design Observations

### 5.1 Well-Structured Isolation

The school module is cleanly isolated as a sub-package across all three layers (models, services, endpoints). Its only coupling to core is through shared infrastructure:
- `app.models.user.User` (authentication)
- `app.core.deps` (`get_db`, `require_feature`, `require_permissions`)
- `app.db.base.TenantModel` (multi-tenancy ORM base)

### 5.2 Shared `models/__init__.py` Barrel Export

`app/models/__init__.py:49-68` re-exports all school models alongside core models. This is a convenience import aggregator — it doesn't create a runtime dependency from core to school, but it does mean importing `app.models` loads all school model classes. This is acceptable for SQLAlchemy model registration but could be split if module lazy-loading becomes necessary.

### 5.3 Tenant Type as Feature Gate

School vs corporate differentiation is handled via `tenant_type` column + feature flags (`app.core.tenant_templates`), not via separate code paths. School features are gated by `require_feature("school_*")` decorators on endpoints.

### 5.4 Model Cross-Reference

`app/models/role.py` imports from `app/models/user.py` (`user_roles`, `UserRole`) — this is a legitimate core-to-core dependency (roles reference users).

---

## 6. Recommendations

1. **No action required** — the module boundaries are clean and all four dependency rules are satisfied.

2. **Optional improvement**: Split `app/models/__init__.py` into lazy sub-imports so that `from app.models import ...` doesn't eagerly load all 63+ model classes. This would improve startup time if the school module grows significantly.

3. **Future consideration**: If a "Corporate" sub-package is created (e.g., `app.models.corporate`, `app.services.corporate`), apply the same sub-package isolation pattern used by School to maintain clean boundaries.

4. **Monitoring**: The `app/core/tenant_templates.py` file is the only place where school and corporate feature sets are defined side-by-side. Keep this as the single source of truth for feature gating.

---

## Summary

| Rule | Status | Details |
|------|--------|---------|
| Core ⊬ School | ✅ Pass | No core module imports from school packages |
| Core ⊬ Corporate | ✅ Pass | Corporate features live within core; no separate corporate package |
| School ⊬ Corporate | ✅ Pass | School modules have zero admin/corporate imports |
| Corporate ⊬ School | ✅ Pass | Admin endpoints have zero school imports |
| No circular deps | ✅ Pass | All dependency flows are acyclic |
