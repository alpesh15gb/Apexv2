# Apex HRMS - Super Admin & Multi-Tenant RBAC Implementation Plan

## Existing Architecture Summary

**Already Built:**
- Multi-tenant row-level isolation via `TenantModel` base class
- JWT auth with access/refresh tokens (python-jose)
- Basic RBAC: `Role`, `Permission`, `UserRole`, `RolePermission` tables
- 4 default roles per tenant: Super Admin, HR Admin, Manager, Employee
- Tenant middleware with cross-tenant protection
- `is_superuser` flag on User model
- 30+ API routers, 35+ database models
- Full CRUD for employees, attendance, leaves, shifts, payroll, etc.

**What Needs Building:**
- Super Admin portal (separate from tenant portal)
- Subscription/plan management
- Feature flag engine
- Resource limits per tenant
- Enhanced RBAC (feature-level permissions)
- Employee Self Service (auto-login creation)
- Approval workflow engine
- Enhanced audit logging

---

## Implementation Phases

### Phase 1: Database Schema (New Models)

**New Models Required:**

```python
# 1. SubscriptionPlan - Plans available for purchase
class SubscriptionPlan(TenantModel):
    name, code, description, price_monthly, price_quarterly,
    price_half_yearly, price_annual, price_lifetime,
    max_employees, max_branches, max_departments, max_devices,
    max_admin_users, max_hr_users, max_storage_mb, max_api_calls,
    max_mobile_logins, features (JSONB), is_active, trial_days

# 2. TenantSubscription - Active subscription per tenant
class TenantSubscription(TenantModel):
    plan_id, start_date, end_date, renewal_date, status,
    payment_status, auto_renewal, last_payment_amount,
    last_payment_date, next_invoice_date, billing_cycle,
    trial_ends_at

# 3. ResourceLimit - Per-tenant configurable limits
class ResourceLimit(TenantModel):
    resource_key, max_value, current_value, is_unlimited

# 4. FeatureFlag - Feature definitions (global)
class FeatureFlag(BaseModel):
    name, code, description, module, category, is_active

# 5. TenantFeature - Per-tenant feature mapping
class TenantFeature(TenantModel):
    feature_id, is_enabled, enabled_at, enabled_by

# 6. ApprovalWorkflow - Configurable approval chains
class ApprovalWorkflow(TenantModel):
    name, entity_type, is_active, steps (JSONB)

# 7. ApprovalStep - Steps in a workflow
class ApprovalStep(TenantModel):
    workflow_id, step_order, approver_role, approver_user_id,
    is_parallel, auto_approve_hours

# 8. ApprovalRequest - Individual approval requests
class ApprovalRequest(TenantModel):
    workflow_id, entity_type, entity_id, requester_id,
    current_step, status, remarks

# 9. ApprovalHistory - Audit trail for approvals
class ApprovalHistory(TenantModel):
    request_id, step_order, approver_id, action, remarks, acted_at

# 10. LoginHistory - Track all logins
class LoginHistory(TenantModel):
    user_id, ip_address, user_agent, device_type, location,
    login_at, logout_at, is_successful, failure_reason

# 11. SuperAdminLog - Super admin actions
class SuperAdminLog(BaseModel):  # No tenant_id - global
    admin_user_id, action, target_type, target_id,
    old_value, new_value, ip_address, created_at
```

### Phase 2: Super Admin API Endpoints

```
/api/admin/
├── auth/
│   POST /login                    # Super admin login
├── dashboard/
│   GET  /stats                    # Total/active/trial/suspended tenants
│   GET  /revenue                  # Monthly revenue stats
│   GET  /health                   # Server health
│   GET  /login-stats              # Login statistics
│   GET  /recent-activity          # Recent admin actions
├── tenants/
│   GET  /                         # List all tenants with filters
│   POST /                         # Create tenant
│   GET  /{id}                     # Get tenant details
│   PUT  /{id}                     # Update tenant
│   DELETE /{id}                   # Suspend/delete tenant
│   POST /{id}/activate            # Activate suspended tenant
│   GET  /{id}/usage               # Resource usage stats
│   PUT  /{id}/limits              # Update resource limits
│   GET  /{id}/features            # Get tenant features
│   PUT  /{id}/features            # Enable/disable features
├── plans/
│   GET  /                         # List plans
│   POST /                         # Create plan
│   PUT  /{id}                     # Update plan
│   DELETE /{id}                   # Deactivate plan
├── subscriptions/
│   GET  /                         # List all subscriptions
│   POST /                         # Create subscription
│   PUT  /{id}                     # Update subscription
│   POST /{id}/renew               # Renew subscription
│   POST /{id}/suspend             # Suspend subscription
├── features/
│   GET  /                         # List all feature flags
│   POST /                         # Create feature flag
│   PUT  /{id}                     # Update feature flag
│   GET  /modules                  # List feature categories
├── users/
│   GET  /                         # List all super admin users
│   POST /                         # Create super admin
│   PUT  /{id}                     # Update super admin
├── audit/
│   GET  /                         # List audit logs
│   GET  /export                   # Export audit logs
```

### Phase 3: Enhanced RBAC

**Expand permission modules:**
```
employee.create/read/update/delete/approve/export/import
attendance.create/read/update/delete/approve/export
leave.create/read/update/delete/approve/reject
shift.create/read/update/delete/assign
payroll.create/read/update/delete/process/approve
device.create/read/update/delete/command
visitor.create/read/update/delete/approve
document.create/read/update/delete/approve
expense.create/read/update/delete/approve/reject
travel.create/read/update/delete/approve/reject
loan.create/read/update/delete/approve/reject
report.read/export
announcement.create/read/update/delete
settings.read/update/configure
user.create/read/update/delete/assign_roles
role.create/read/update/delete/assign_permissions
tenant.read/update/configure
subscription.read/update/manage
feature.read/enable/disable
audit.read/export
workflow.create/read/update/delete/configure
```

### Phase 4: Employee Self Service

**Auto-create on employee creation:**
1. Generate username = employee_code
2. Generate temporary password = employee_code
3. Create User record with `must_change_password=True`
4. Assign "Employee" role
5. Send credentials via email/SMS (configurable)

**ESS Dashboard endpoints:**
```
GET /api/ess/dashboard          # My summary
GET /api/ess/attendance         # My attendance
POST /api/ess/attendance/clock-in
POST /api/ess/attendance/clock-out
GET /api/ess/leaves             # My leaves
POST /api/ess/leaves/apply      # Apply leave
GET /api/ess/leaves/balance     # My balance
GET /api/ess/payslips           # My payslips
GET /api/ess/documents          # My documents
GET /api/ess/profile            # My profile
PUT /api/ess/profile            # Update profile
POST /api/ess/change-password   # Change password
GET /api/ess/announcements      # Company announcements
POST /api/ess/expenses          # Submit expense
POST /api/ess/travel            # Submit travel request
POST /api/ess/loans             # Request loan
GET /api/ess/notifications      # My notifications
```

### Phase 5: Approval Workflow Engine

**Generic workflow:**
1. Define workflow with steps (entity_type + ordered approvers)
2. When entity needs approval, create `ApprovalRequest`
3. Each step: approver approves/rejects
4. On approve: move to next step
5. On reject: mark rejected, notify requester
6. On final approve: mark entity as approved

**Configurable per tenant:**
- Leave approval: Employee → Dept Head → HR
- Expense: Employee → Manager → Finance
- Travel: Employee → Dept Head → Admin
- Loan: Employee → HR → Finance → Admin

### Phase 6: Subscription Engine

**Subscription lifecycle:**
1. Trial: 14-day free trial on registration
2. Active: Paid subscription
3. Expired: Grace period (7 days) then suspend
4. Suspended: Read-only access, no new data

**Feature gating:**
- Check `TenantFeature.is_enabled` before allowing access
- Check `ResourceLimit` before creating new entities
- Middleware: `require_feature("payroll")` dependency

---

## Implementation Order

1. **Models** (Phase 1) - New DB tables via Alembic migration
2. **Super Admin Auth** - Separate login for platform admins
3. **Super Admin Dashboard** - Stats endpoints
4. **Tenant Management** - CRUD + limits + features
5. **Feature Flag Engine** - Feature checking middleware
6. **Enhanced RBAC** - Expanded permissions
7. **Approval Workflows** - Generic workflow engine
8. **ESS Portal** - Employee self-service
9. **Subscription Engine** - Plans, billing, lifecycle
10. **Super Admin Frontend** - Flutter web portal

## Files to Create/Modify

### Backend (New Files)
```
backend/app/models/subscription.py
backend/app/models/feature.py
backend/app/models/approval.py
backend/app/models/login_history.py
backend/app/api/v1/endpoints/admin/
├── __init__.py
├── dashboard.py
├── tenants.py
├── plans.py
├── subscriptions.py
├── features.py
├── users.py
├── audit.py
backend/app/api/v1/endpoints/ess.py
backend/app/services/admin_service.py
backend/app/services/subscription_service.py
backend/app/services/feature_service.py
backend/app/services/approval_service.py
backend/app/services/ess_service.py
backend/app/core/feature_gate.py
backend/alembic/versions/xxxx_add_super_admin_tables.py
```

### Frontend (New Files)
```
frontend/lib/screens/admin/
├── admin_login_screen.dart
├── admin_dashboard_screen.dart
├── admin_tenant_list_screen.dart
├── admin_tenant_detail_screen.dart
├── admin_plan_screen.dart
├── admin_feature_screen.dart
├── admin_subscription_screen.dart
├── admin_audit_screen.dart
frontend/lib/screens/ess/
├── ess_dashboard_screen.dart
├── ess_attendance_screen.dart
├── ess_leave_screen.dart
├── ess_payslip_screen.dart
├── ess_profile_screen.dart
frontend/lib/services/admin_service.dart
frontend/lib/services/ess_service.dart
frontend/lib/providers/admin_provider.dart
frontend/lib/providers/ess_provider.dart
```

### Files to Modify
```
backend/app/models/__init__.py          # Add new model imports
backend/app/models/tenant.py            # Add subscription fields
backend/app/models/user.py              # Add must_change_password, login tracking
backend/app/api/v1/router.py            # Add admin + ESS routers
backend/app/core/deps.py                # Add feature gate dependency
backend/app/core/rbac.py                # Expand default permissions
backend/app/middleware/tenant.py        # Add subscription status check
backend/app/api/v1/endpoints/auth.py    # Add first-login password change
backend/app/api/v1/endpoints/employees.py # Auto-create ESS login
frontend/lib/core/router.dart           # Add admin + ESS routes
frontend/lib/screens/main_shell.dart    # Add ESS navigation
```
