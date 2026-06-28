# Dependency Analysis — Apex HRMS

## Architecture Overview

The application follows a 3-layer architecture:

```
Endpoints (api/v1/endpoints/)  →  Services (services/)  →  Models (models/)
        ↕                                                          ↕
    Schemas (schemas/)                                    Base (db/base.py)
    Core (core/deps, config, security)                    Session (db/session.py)
```

**Files analyzed:**
- 46 endpoint modules
- 21 service modules
- 44 model modules

---

## 1. Module Dependency Graph

### 1.1 Endpoint Dependencies

Each endpoint's `app.*` imports (excluding `app.core.deps` and `app.models.user` which are universal):

| Endpoint | Models (direct) | Services | Schemas |
|---|---|---|---|
| `access_control.py` | — | `access_control` | `common`, `access_control` |
| `analytics.py` | `tenant`, `employee`, `subscription`, `approval` | — | — |
| `assets.py` | `asset_travel` | — | — |
| `attendance.py` | — | `attendance` | `common`, `attendance` |
| `auth.py` | `tenant` | — | `auth`, `common` |
| `billing.py` | `tenant`, `subscription` | — | — |
| `categories.py` | `category` | — | `common`, `category` |
| `commands.py` | — | `command` | `common`, `device` |
| `dashboard.py` | — | `dashboard` | `dashboard` |
| `department_shifts.py` | `department_shift` | — | `common`, `department_shift` |
| `devices.py` | — | `device`, `command` | `common`, `device` |
| `documents.py` | `document` | — | `common`, `document` |
| `employees.py` | — | `employee` | `common`, `employee` |
| **`ess.py`** | **`employee`, `attendance`, `leave`, `payroll`, `document`, `announcement`, `notification`, `expense`** | **—** | **—** |
| `essl_connector.py` | `essl_server`, `essl_sync`, `essl_mapping`, `essl_cursor`, `attendance`, `device`, `employee` | `essl_connector` | `common`, `essl` |
| `essl_locations.py` | `essl_server`, `essl_location` | — | `common`, `essl` |
| `exit_requests.py` | `exit` | — | `common`, `exit` |
| `expense_benefits.py` | `expense`, `tax`, `benefit` | — | `common`, `hr_features` |
| `holidays.py` | `holiday` | — | `common`, `holiday` |
| `hr_ops.py` | `asset_travel`, `announcement`, `notification_template`, `employee` | — | `common`, `hr_features` |
| `import_export.py` | `employee`, `leave` | — | — |
| `leaves.py` | — | `leave` | `common`, `leave` |
| `lifecycle.py` | `employee`, `timeline`, `payroll` | — | — |
| `notification_center.py` | `notification` | — | — |
| `notifications.py` | — | `notification` | `common`, `notification` |
| `onboarding.py` | `onboarding` | — | `common`, `onboarding` |
| `operations.py` | `tenant` | — | — |
| `ot_register.py` | `ot_register` | — | `common`, `ot_register` |
| `outdoor_duties.py` | `employee`, `outdoor_duty` | — | `common`, `outdoor_duty` |
| `payroll.py` | `payroll`, `employee`, `attendance` | — | `common`, `payroll` |
| `performance.py` | `performance` | — | — |
| `recruitment.py` | `recruitment` | — | — |
| `reports.py` | — | `report`, `attendance_processor` | — |
| `settings_api.py` | `tenant` | — | — |
| `setup.py` | `tenant`, `employee`, `shift`, `leave`, `category`, `tenant_settings` | — | — |
| `shift_groups.py` | `shift_group`, `shift` | — | `common`, `shift_group` |
| `shift_rosters.py` | `shift_roster` | — | `common`, `shift_roster` |
| `shifts.py` | — | `shift` | `common`, `shift` |
| `system.py` | `tenant`, `employee`, `attendance`, `leave`, `notification` | — | — |
| `tenant_settings.py` | `tenant_settings` | — | `tenant_settings` |
| `tenants.py` | — | `tenant` | `tenant`, `common` |
| `timeline.py` | `timeline` | — | `common`, `timeline` |
| `visitors.py` | — | `visitor` | `common`, `visitor` |
| `websocket.py` | — | `websocket_manager` | — |
| `work_codes.py` | `work_code` | — | `common`, `work_code` |

### 1.2 Service Dependencies

| Service | Models | Other Services | Core/DB |
|---|---|---|---|
| `access_control.py` | `access_control`, `employee` | — | `db.session` |
| `attendance.py` | `attendance`, `employee`, `shift`, `leave` | — | `db.session` |
| `attendance_processor.py` | `attendance`, `employee`, `shift` | — | — |
| `command.py` | `command`, `device` | `essl_soap` | `db.session` |
| `dashboard.py` | `employee`, `device`, `attendance`, `visitor`, `leave`, `audit_log`, `essl_server`, `essl_sync` | — | — |
| `device.py` | `device` | — | `db.session` |
| `duplicate_detector.py` | `attendance` | — | — |
| `employee.py` | `employee`, `device`, `command` | — | `db.session` |
| `essl_client.py` | — | `essl_soap` | — |
| `essl_connector.py` | `essl_server`, `essl_sync`, `essl_mapping`, `essl_cursor`, `essl_location`, `employee`, `device`, `attendance` | `essl_soap`, `essl_client` | `core.encryption`, `core.config` |
| `essl_dashboard.py` | `essl_server`, `essl_sync`, `essl_mapping`, `essl_cursor`, `attendance` | `duplicate_detector` | — |
| `leave.py` | `leave`, `employee` | — | `db.session` |
| `notification.py` | `notification`, `user` | — | `db.session` |
| `report.py` | `attendance`, `employee`, `device`, `visitor`, `shift` | — | `db.session` |
| `shift.py` | `shift`, `employee` | — | `db.session` |
| `sync_audit.py` | `audit_log` | — | — |
| `tenant.py` | `tenant`, `subscription` | — | `db.session` |
| `user.py` | `user`, `role` | — | `db.session`, `core.security` |
| `visitor.py` | `visitor` | `essl_soap` (lazy) | `db.session` |
| `websocket_manager.py` | — | — | — |

### 1.3 Model Dependencies

All models depend only on `app.db.base` except:

| Model | Additional Dependencies |
|---|---|
| `role.py` | `app.models.user` (imports `user_roles`, `UserRole`) |

---

## 2. Circular Dependencies Found

### 2.1 CRITICAL: eSSL Service Cluster (3-service cycle)

```
essl_connector.py
  ├──→ essl_soap.py
  └──→ essl_client.py
         └──→ essl_soap.py
```

`essl_connector` imports both `essl_soap` and `essl_client`. `essl_client` imports `essl_soap`. This creates a tightly coupled cluster of 3 services that form a circular dependency chain:

```
essl_connector → essl_client → essl_soap ← essl_connector
```

While Python's lazy import mechanism may prevent a runtime `ImportError`, this represents a **logical circular dependency** where the services are not independently testable or replaceable.

### 2.2 WARNING: Visitor Service → eSSL Cross-Domain Coupling

```
visitor.py (line 64): lazy import of app.services.essl_soap.ESSLSoapService
visitor.py (line 65): lazy import of app.models.essl_server.EsslServer
```

The visitor service has a hidden runtime dependency on the eSSL subsystem. This is a **domain boundary violation** — visitor management should not depend on biometric device integration.

### 2.3 Model Layer: role.py → user.py

```
role.py → user.py (imports user_roles association table and UserRole enum)
```

This is a **design-time coupling** — `role.py` reuses the association table defined in `user.py`. While not a runtime cycle (user.py does not import role.py), it creates a tight coupling between two models that should be independently defined.

---

## 3. Cross-Module Coupling Issues

### 3.1 Endpoints Bypassing the Service Layer (18 endpoints)

These endpoints directly import models and implement business logic, violating the service layer boundary:

| Endpoint | # Models | Models Used Directly |
|---|---|---|
| **`ess.py`** | **8** | employee, attendance, leave, payroll, document, announcement, notification, expense |
| **`setup.py`** | **6** | tenant, employee, shift, leave, category, tenant_settings |
| **`system.py`** | **5** | tenant, employee, attendance, leave, notification |
| **`analytics.py`** | **5** | tenant, employee, subscription, approval |
| **`hr_ops.py`** | **4** | employee, asset_travel, announcement, notification_template |
| **`essl_connector.py`** | **7** | essl_server, essl_sync, essl_mapping, essl_cursor, attendance, device, employee |
| **`expense_benefits.py`** | **3** | expense, tax, benefit |
| **`payroll.py`** | **3** | payroll, employee, attendance |
| **`lifecycle.py`** | **3** | employee, timeline, payroll |
| `import_export.py` | 2 | employee, leave |
| `outdoor_duties.py` | 2 | employee, outdoor_duty |
| `shift_groups.py` | 2 | shift_group, shift |
| `billing.py` | 2 | tenant, subscription |
| `essl_locations.py` | 2 | essl_server, essl_location |
| `auth.py` | 1 | tenant |
| `operations.py` | 1 | tenant |
| `settings_api.py` | 1 | tenant |
| `categories.py` | 1 | category |

**By contrast, these 12 endpoints correctly use the service layer:**

`access_control`, `attendance`, `commands`, `dashboard`, `devices`, `employees`, `leaves`, `notifications`, `reports`, `shifts`, `tenants`, `visitors`

### 3.2 Service Layer Cross-Domain Dependencies

| Service | Unexpected Dependency | Issue |
|---|---|---|
| `visitor.py` | `essl_soap` + `essl_server` model | Visitor check-in calls eSSL SOAP API |
| `command.py` | `essl_soap` | Device commands depend on eSSL protocol |
| `essl_dashboard.py` | `duplicate_detector` | Dashboard mixes detection logic |
| `dashboard.py` | 8 models across 6 domains | Aggregates too many unrelated models |

### 3.3 Endpoint Using 5 Services

`essl_connector.py` endpoint imports **5 services** (`essl_connector`, `essl_soap`, `essl_client`, `duplicate_detector`, `essl_dashboard`, `sync_audit`, `attendance_processor`). This endpoint has too many responsibilities.

---

## 4. Dependency Boundary Recommendations

### 4.1 Introduce an eSSL Integration Module

The eSSL subsystem (`essl_soap`, `essl_client`, `essl_connector`, `essl_dashboard`, `duplicate_detector`) should be consolidated into a single cohesive module:

```
services/essl/
├── __init__.py          # Public API: EsslConnectorService, EsslDashboardService
├── soap_client.py       # ESSLSoapService (raw SOAP protocol)
├── api_client.py        # ESSLClient (high-level API wrapper)
├── connector.py         # EsslConnectorService (sync orchestration)
├── dashboard.py         # EsslDashboardService (monitoring)
└── duplicate_detector.py
```

This eliminates the circular dependency chain and makes the boundary explicit.

### 4.2 Extract Services for Heavily-Coupled Endpoints

Create missing services for endpoints that bypass the service layer:

| Missing Service | For Endpoints | Models to Encapsulate |
|---|---|---|
| `EssService` | `ess.py` | employee, attendance, leave, payroll, document, announcement, notification, expense |
| `SetupService` | `setup.py` | tenant, employee, shift, leave, category, tenant_settings |
| `SystemService` | `system.py` | tenant, employee, attendance, leave, notification |
| `AnalyticsService` | `analytics.py` | tenant, employee, subscription, approval |
| `PayrollService` | `payroll.py` | payroll, employee, attendance |
| `LifecycleService` | `lifecycle.py` | employee, timeline, payroll |
| `HrOpsService` | `hr_ops.py` | employee, asset_travel, announcement, notification_template |
| `ExpenseBenefitService` | `expense_benefits.py` | expense, tax, benefit |

### 4.3 Remove Visitor → eSSL Coupling

The visitor check-in's eSSL validation should be handled via an event/callback pattern:

```python
# Instead of visitor.py directly calling essl_soap:
class VisitorService:
    def __init__(self, db, validation_callback=None):
        self.validation_callback = validation_callback

    async def check_in(self, ...):
        if self.validation_callback:
            await self.validation_callback(visitor_pass)
```

The eSSL integration would register as a callback, keeping the visitor domain clean.

### 4.4 Fix Model Layer Coupling

Move the `user_roles` association table to a shared location:

```python
# app/models/associations.py
user_roles = Table("user_roles", Base.metadata, ...)
role_permissions = Table("role_permissions", Base.metadata, ...)
```

Both `user.py` and `role.py` would import from `associations.py`, eliminating the cross-model dependency.

### 4.5 Define Dependency Direction Rules

```
Endpoints → Services → Models → Base
    ↓           ↓
 Schemas    Core/DB

Forbidden:
- Models → Services (never)
- Models → Endpoints (never)
- Services → Endpoints (never)
- Endpoint → Model (only for User auth context)
```

---

## 5. Summary of Severity

| Category | Count | Severity |
|---|---|---|
| Circular service dependencies | 1 cluster (3 services) | **CRITICAL** |
| Cross-domain service coupling | 4 instances | **HIGH** |
| Endpoints bypassing service layer | 18 of 46 endpoints | **HIGH** |
| Model cross-dependencies | 1 (role→user) | **LOW** |
| Endpoints with 5+ direct model imports | 5 endpoints | **MEDIUM** |
| Service aggregating 6+ models | 2 services | **MEDIUM** |
