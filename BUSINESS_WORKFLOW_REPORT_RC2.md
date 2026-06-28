# Apex HRMS - Business Workflow Validation Report (RC2)

> **Version:** RC2 — Generated from source code analysis of `backend/app/api/v1/endpoints/`, `backend/app/api/v1/endpoints/admin/`, and `backend/app/api/v1/endpoints/school/`
>
> **Date:** 2026-06-28

---

## Table of Contents

- [Authentication](#authentication)
- [Super Admin Workflows](#super-admin-workflows)
- [Corporate HRMS Workflows](#corporate-hrms-workflows)
  - [1. Tenant Creation](#1-tenant-creation)
  - [2. Employee Lifecycle](#2-employee-lifecycle)
  - [3. Attendance Management](#3-attendance-management)
  - [4. Leave Management](#4-leave-management)
  - [5. Payroll Processing](#5-payroll-processing)
  - [6. Reports](#6-reports)
- [School ERP Workflows](#school-erp-workflows)
  - [1. School Tenant Creation](#1-school-tenant-creation)
  - [2. Academic Year Setup](#2-academic-year-setup)
  - [3. Classes and Sections](#3-classes-and-sections)
  - [4. Student Enrollment](#4-student-enrollment)
  - [5. Teacher Allocation](#5-teacher-allocation)
  - [6. Student Attendance](#6-student-attendance)
  - [7. Fee Structure and Collection](#7-fee-structure-and-collection)
  - [8. Timetable Management](#8-timetable-management)
  - [9. Examinations and Marks](#9-examinations-and-marks)
  - [10. Report Cards and Certificates](#10-report-cards-and-certificates)
- [Cross-Cutting Concerns](#cross-cutting-concerns)

---

## Authentication

All authenticated endpoints require a JWT Bearer token in the `Authorization` header.

**Source:** `backend/app/api/v1/endpoints/auth.py`

### Login

```
POST /api/v1/auth/login
```

**Request:**
```json
{
  "email": "admin@company.com",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "email": "admin@company.com",
    "full_name": "Admin User",
    "tenant_id": "uuid",
    "is_active": true,
    "is_superuser": false
  }
}
```

**Permissions Required:** None (public endpoint)

**Error Responses:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 401 | Wrong credentials | `"Incorrect email or password."` |
| 400 | Inactive account | `"User account is inactive."` |
| 423 | Account locked | Lockout message from password policy |
| 429 | Rate limited | 5 attempts per 60 seconds |

### Token Refresh

```
POST /api/v1/auth/refresh
```

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):** Same as login response with new token pair.

**Error Responses:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 401 | Invalid token | `"Invalid refresh token."` |
| 401 | Revoked token | `"Refresh token has been revoked."` |
| 400 | Inactive user | `"User account is inactive."` |

### Logout

```
POST /api/v1/auth/logout
```

**Request:**
```json
{
  "refresh_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "status": "success",
  "message": "Successfully logged out."
}
```

### Logout All Devices

```
POST /api/v1/auth/logout-all
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "status": "success",
  "message": "All sessions revoked. Please login again."
}
```

### Get Current User

```
GET /api/v1/auth/me
Authorization: Bearer <token>
```

**Response (200):** Returns `UserResponse` with full profile.

### Update Profile

```
PUT /api/v1/auth/me
Authorization: Bearer <token>
```

**Request:**
```json
{
  "full_name": "Updated Name",
  "phone": "+91-9876543210",
  "avatar_url": "https://cdn.example.com/avatar.jpg"
}
```

### Change Password

```
POST /api/v1/auth/change-password
Authorization: Bearer <token>
```

**Request:**
```json
{
  "old_password": "currentPass123",
  "new_password": "newSecurePass456!"
}
```

**Data Flow:**
1. Verifies old password
2. Hashes new password
3. Updates `last_password_change` timestamp
4. Revokes all existing sessions via Redis

**Error Responses:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 400 | Wrong old password | `"Incorrect old password."` |

---

## Super Admin Workflows

Super Admin endpoints are prefixed with `/api/v1/admin/` and require `is_superuser=true` on the user.

**Source:** `backend/app/api/v1/endpoints/admin/auth.py`, `admin/tenants.py`, `admin/plans.py`, `admin/features.py`

### Super Admin Login

```
POST /api/v1/admin/auth/login
```

**Request:**
```json
{
  "email": "superadmin@apex.com",
  "password": "SuperAdminPass!"
}
```

**Response (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": "uuid",
    "email": "superadmin@apex.com",
    "full_name": "Super Admin",
    "is_superuser": true
  }
}
```

**Error Responses:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 401 | Invalid credentials | `"Invalid credentials"` |
| 403 | Not superuser | `"Not a super admin"` |
| 403 | Account disabled | `"Account disabled"` |
| 423 | Account locked | Lockout message |

### Tenant Management (Super Admin)

#### Create Tenant

```
POST /api/v1/admin/tenants/
Authorization: Bearer <super_admin_token>
```

**Request:**
```json
{
  "name": "Acme Corporation",
  "slug": "acme-corp",
  "email": "admin@acme.com",
  "mobile": "+91-9876543210",
  "contact_person": "John Doe",
  "company_code": "ACME",
  "gst_number": "22AAAAA0000A1Z5",
  "pan_number": "AAAAA0000A",
  "currency": "INR",
  "timezone": "Asia/Kolkata",
  "subscription_plan_code": "enterprise",
  "tenant_type": "corporate"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "Acme Corporation",
  "slug": "acme-corp",
  "tenant_type": "corporate"
}
```

**Data Flow:**
1. Validates slug uniqueness
2. Creates `Tenant` with `subscription_status="trial"`, `trial_ends_at=now+14days`
3. Applies tenant template via `apply_tenant_template()`
4. Creates default RBAC roles (corporate or school based on `tenant_type`)
5. Commits transaction

**Error Responses:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 400 | Duplicate slug | `"Slug already exists"` |
| 401 | Not authenticated | Token required |
| 403 | Not superuser | Permission denied |

#### List Tenants

```
GET /api/v1/admin/tenants/?page=1&page_size=20&status=active&search=acme
Authorization: Bearer <super_admin_token>
```

**Response (200):**
```json
{
  "items": [
    {
      "id": "uuid",
      "name": "Acme Corporation",
      "slug": "acme-corp",
      "email": "admin@acme.com",
      "subscription_status": "active",
      "is_active": true,
      "employee_count": 150,
      "user_count": 5,
      "created_at": "2025-01-15T10:00:00Z"
    }
  ],
  "total": 1,
  "page": 1,
  "page_size": 20,
  "total_pages": 1
}
```

#### Get Tenant Detail

```
GET /api/v1/admin/tenants/{tenant_id}
Authorization: Bearer <super_admin_token>
```

**Response (200):** Returns full tenant details including subscription, resource limits, and feature flags.

#### Update Tenant

```
PUT /api/v1/admin/tenants/{tenant_id}
Authorization: Bearer <super_admin_token>
```

**Request:**
```json
{
  "name": "Updated Company Name",
  "email": "newemail@acme.com",
  "is_active": true
}
```

#### Suspend Tenant

```
POST /api/v1/admin/tenants/{tenant_id}/suspend
Authorization: Bearer <super_admin_token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "suspended"
}
```

**Data Flow:** Sets `subscription_status="suspended"` and `is_active=False`.

#### Activate Tenant

```
POST /api/v1/admin/tenants/{tenant_id}/activate
Authorization: Bearer <super_admin_token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "active"
}
```

#### Manage Resource Limits

```
GET  /api/v1/admin/tenants/{tenant_id}/limits
PUT  /api/v1/admin/tenants/{tenant_id}/limits
Authorization: Bearer <super_admin_token>
```

**Update Request:**
```json
[
  {"resource_key": "max_employees", "max_value": 500, "is_unlimited": false},
  {"resource_key": "max_devices", "max_value": 20, "is_unlimited": false}
]
```

**Response (200):**
```json
{
  "updated": 2
}
```

#### Manage Tenant Features

```
GET  /api/v1/admin/tenants/{tenant_id}/features
PUT  /api/v1/admin/tenants/{tenant_id}/features
Authorization: Bearer <super_admin_token>
```

**Update Request:**
```json
{
  "feature_codes": ["payroll", "reports", "onboarding", "examinations"],
  "enabled": true
}
```

**Response (200):**
```json
{
  "updated": 4
}
```

#### List Tenant Users

```
GET /api/v1/admin/tenants/{tenant_id}/users?page=1&page_size=50
Authorization: Bearer <super_admin_token>
```

### Subscription Plans Management

#### Create Plan

```
POST /api/v1/admin/plans/
Authorization: Bearer <super_admin_token>
```

**Request:**
```json
{
  "name": "Enterprise",
  "code": "enterprise",
  "description": "Full-featured enterprise plan",
  "price_monthly": 9999.00,
  "price_annual": 99999.00,
  "max_employees": 1000,
  "max_branches": 50,
  "max_departments": 100,
  "max_devices": 100,
  "max_admin_users": 10,
  "max_hr_users": 50,
  "trial_days": 14,
  "features": ["payroll", "reports", "onboarding", "performance", "recruitment"],
  "is_active": true,
  "sort_order": 3
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "code": "enterprise"
}
```

#### List Plans

```
GET /api/v1/admin/plans/
Authorization: Bearer <super_admin_token>
```

#### Update Plan

```
PUT /api/v1/admin/plans/{plan_id}
Authorization: Bearer <super_admin_token>
```

#### Deactivate Plan

```
DELETE /api/v1/admin/plans/{plan_id}
Authorization: Bearer <super_admin_token>
```

### Feature Flags Management

#### List Features

```
GET /api/v1/admin/features/?category=core&module=hrms
Authorization: Bearer <super_admin_token>
```

#### Create Feature

```
POST /api/v1/admin/features/
Authorization: Bearer <super_admin_token>
```

**Request:**
```json
{
  "name": "Payroll Module",
  "code": "payroll",
  "description": "Payroll processing and payslip generation",
  "module": "hrms",
  "category": "core",
  "is_active": true,
  "sort_order": 5
}
```

#### Seed Default Features

```
POST /api/v1/admin/features/seed
Authorization: Bearer <super_admin_token>
```

**Response (200):**
```json
{
  "message": "Feature flags seeded successfully",
  "count": 25
}
```

---

## Corporate HRMS Workflows

---

### 1. Tenant Creation

**Source:** `backend/app/api/v1/endpoints/auth.py:46`, `backend/app/api/v1/endpoints/tenants.py`, `backend/app/api/v1/endpoints/admin/tenants.py`

#### Workflow A: Self-Registration (Public)

```
POST /api/v1/auth/register
```

**Request:**
```json
{
  "tenant_name": "Acme Corporation",
  "tenant_slug": "acme-corp",
  "admin_email": "admin@acme.com",
  "admin_password": "SecurePass123!",
  "admin_full_name": "John Admin"
}
```

**Response (201):**
```json
{
  "tenant_id": "550e8400-e29b-41d4-a716-446655440000",
  "tenant_name": "Acme Corporation",
  "tenant_slug": "acme-corp",
  "admin_user": {
    "id": "uuid",
    "email": "admin@acme.com",
    "full_name": "John Admin",
    "tenant_id": "uuid",
    "is_active": true
  }
}
```

**Permissions Required:** None (public endpoint, rate limited: 3 per 60s)

**Data Flow:**
1. Validates tenant slug uniqueness
2. Creates `Tenant` record
3. Creates default RBAC roles and permissions via `create_default_roles()`
4. Creates admin `User` with hashed password
5. Assigns "Super Admin" role to admin user
6. Commits transaction

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 400 | Tenant slug already exists | `"Tenant with this slug already exists."` |
| 400 | Registration failure | `"Tenant registration failed: <error>"` |
| 429 | Rate limited | 3 attempts per 60 seconds |

#### Workflow B: Super Admin Creates Tenant

```
POST /api/v1/admin/tenants/
Authorization: Bearer <super_admin_token>
```

See [Super Admin Workflows — Create Tenant](#create-tenant) for full details.

#### Sub-Workflow: Tenant Settings Configuration

```
GET  /api/v1/tenant-settings/
PUT  /api/v1/tenant-settings/
Authorization: Bearer <token>
```

**Update Request:**
```json
{
  "attendance_policy": { "grace_minutes": 15 },
  "leave_policy": { "carry_forward": true },
  "payroll_settings": { "pay_date": 28 }
}
```

---

### 2. Employee Lifecycle

**Source:** `backend/app/api/v1/endpoints/employees.py`, `backend/app/api/v1/endpoints/lifecycle.py`, `backend/app/api/v1/endpoints/onboarding.py`

#### Step 1: Create Organizational Structure

##### 1a. Create Department

```
POST /api/v1/employees/departments
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Engineering",
  "code": "ENG",
  "description": "Software Engineering Department"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "name": "Engineering",
  "code": "ENG",
  "tenant_id": "uuid"
}
```

**Permissions Required:** `employee.create`

##### 1b. Create Designation

```
POST /api/v1/employees/designations
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Senior Software Engineer",
  "code": "SSE",
  "department_id": "uuid",
  "level": 3
}
```

**Permissions Required:** `employee.create`

##### 1c. Create Branch

```
POST /api/v1/employees/branches
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Mumbai Office",
  "code": "MUM",
  "address": "123 Business Park, Mumbai"
}
```

**Permissions Required:** `employee.create`

#### Step 2: Create Employee

```
POST /api/v1/employees/
Authorization: Bearer <token>
```

**Request:**
```json
{
  "employee_code": "EMP001",
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane.doe@acme.com",
  "phone": "+91-9876543210",
  "date_of_birth": "1990-05-15",
  "gender": "female",
  "department_id": "uuid",
  "designation_id": "uuid",
  "branch_id": "uuid",
  "date_of_joining": "2025-01-15",
  "employment_type": "full_time",
  "status": "active"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "employee_code": "EMP001",
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane.doe@acme.com",
  "department_id": "uuid",
  "designation_id": "uuid",
  "branch_id": "uuid",
  "status": "active",
  "tenant_id": "uuid"
}
```

**Permissions Required:** `employee.create`

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Department/Designation/Branch not found | Resource not found |
| 400 | Duplicate employee code or email | Validation error |

##### Bulk Import

```
POST /api/v1/employees/bulk-import
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Imported 25 employees, 2 errors",
  "data": {
    "created": 25,
    "errors": ["Row 3: Invalid department", "Row 18: Duplicate email"]
  }
}
```

#### Step 3: Onboarding

Requires `onboarding` feature enabled.

```
POST /api/v1/onboarding/
Authorization: Bearer <token>
```

**Request:**
```json
{
  "employee_id": "uuid",
  "task_name": "Submit ID proof",
  "description": "Upload scanned copy of government-issued ID",
  "due_date": "2025-02-01",
  "order_index": 1,
  "assigned_to": "uuid"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "employee_id": "uuid",
  "task_name": "Submit ID proof",
  "status": "pending",
  "order_index": 1
}
```

**Permissions Required:** `onboarding.read` (read), `onboarding.write` (write)

**List Onboarding Tasks:**
```
GET /api/v1/onboarding/?employee_id={id}&status=pending
```

**Complete a Task:**
```
PUT /api/v1/onboarding/{task_id}
```
```json
{
  "status": "completed"
}
```
Sets `completed_at` timestamp automatically when status changes to `"completed"`.

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Task not found | Task doesn't exist or belongs to different tenant |
| 403 | Feature not enabled | `onboarding` feature not enabled on tenant |

#### Step 4: Promotion

```
POST /api/v1/employees/{employee_id}/promote
Authorization: Bearer <token>
```

**Request:**
```json
{
  "event_type": "promotion",
  "title": "Promoted to Tech Lead",
  "description": "Promoted based on exceptional Q4 performance",
  "event_date": "2025-07-01",
  "effective_date": "2025-07-01",
  "new_designation_id": "uuid",
  "new_salary": 120000.00
}
```

**Response (200):**
```json
{
  "message": "Employee promoted",
  "event_id": "uuid"
}
```

**Permissions Required:** `employee.manage`

**Data Flow:**
1. Validates employee exists and belongs to tenant
2. Updates `employee.designation_id` if `new_designation_id` provided
3. If `new_salary` provided: deactivates current `SalaryStructure`, creates new one
4. Creates `EmployeeEvent` record with type `"promotion"`
5. Commits transaction

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Employee not found | Employee doesn't exist or belongs to different tenant |
| 400 | Missing data | `"At least one of new_designation_id or new_salary is required"` |
| 400 | Invalid salary | `"New salary must be positive"` |

#### Step 5: Transfer

```
POST /api/v1/employees/{employee_id}/transfer
Authorization: Bearer <token>
```

**Request:**
```json
{
  "event_type": "transfer",
  "title": "Transferred to Bangalore Office",
  "description": "Transfer due to project requirements",
  "event_date": "2025-08-01",
  "new_department_id": "uuid",
  "new_branch_id": "uuid",
  "new_manager_id": "uuid"
}
```

**Response (200):**
```json
{
  "message": "Employee transferred",
  "event_id": "uuid"
}
```

**Permissions Required:** `employee.manage`

**Data Flow:**
1. Validates at least one of `new_department_id`, `new_branch_id`, or `new_manager_id` provided
2. Updates employee fields accordingly
3. Creates `EmployeeEvent` with type `"transfer"`

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Employee not found | Employee doesn't exist or belongs to different tenant |
| 400 | No changes | `"At least one of new_department_id, new_branch_id, or new_manager_id is required"` |

#### Step 6: Resignation

```
POST /api/v1/employees/{employee_id}/resign
Authorization: Bearer <token>
```

**Request:**
```json
{
  "event_type": "resignation",
  "title": "Voluntary Resignation",
  "description": "Pursuing higher education",
  "event_date": "2025-09-01",
  "reason": "Career growth"
}
```

**Response (200):**
```json
{
  "message": "Resignation recorded",
  "event_id": "uuid"
}
```

**Permissions Required:** `employee.manage`

**Data Flow:**
1. Sets `employee.status = "resigned"`
2. Creates `EmployeeEvent` with type `"resignation"`

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Employee not found | Employee doesn't exist or belongs to different tenant |
| 400 | Already terminated/resigned | `"Cannot resign an employee with status 'terminated'"` |

#### Additional Lifecycle Events

**Confirm from Probation:**
```
POST /api/v1/employees/{employee_id}/confirm
```
Sets `employee.status = "active"`. Cannot confirm terminated employees.

**Terminate:**
```
POST /api/v1/employees/{employee_id}/terminate
```
Sets `employee.status = "terminated"`. Cannot terminate already terminated employees.

**Reactivate:**
```
POST /api/v1/employees/{employee_id}/reactivate
```
Sets `employee.status = "active"`. Cannot reactivate already active employees.

**Salary Revision:**
```
POST /api/v1/employees/{employee_id}/salary-revision
```
**Request:**
```json
{
  "event_type": "salary_revision",
  "title": "Annual Increment",
  "event_date": "2025-04-01",
  "effective_date": "2025-04-01",
  "new_salary": 130000.00
}
```
Deactivates current salary structure and creates new one.

#### View Employee Timeline

```
GET /api/v1/employees/{employee_id}/timeline
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "id": "uuid",
    "event_type": "promotion",
    "title": "Promoted to Tech Lead",
    "description": "Promoted based on exceptional Q4 performance",
    "event_date": "2025-07-01",
    "created_at": "2025-07-01T10:30:00Z"
  }
]
```

#### Complete Employee Lifecycle Data Flow

```
Registration → Employee Created (status=active)
     ↓
Onboarding Tasks Created → Tasks Completed
     ↓
Confirm from Probation → EmployeeEvent(confirmation)
     ↓
Promotion → designation updated + salary structure updated + EmployeeEvent(promotion)
     ↓
Transfer → department/branch updated + EmployeeEvent(transfer)
     ↓
Resignation → status=resigned + EmployeeEvent(resignation)
     OR
Termination → status=terminated + EmployeeEvent(termination)
     OR
Reactivation → status=active + EmployeeEvent(reactivation)
```

---

### 3. Attendance Management

**Source:** `backend/app/api/v1/endpoints/attendance.py`

> Requires `attendance.read` permission for reads, `attendance.manage` for writes.

#### Step 1: Process Daily Attendance

```
POST /api/v1/attendance/process?target_date=2025-06-15
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Processed attendance for 150 employees"
}
```

**Permissions Required:** `attendance.manage`

**Data Flow:**
1. Fetches all active employees for the tenant
2. Calculates attendance status based on punch logs (present/absent/late/half-day)
3. Creates `Attendance` records for each employee
4. Returns count of processed records

#### Step 2: Manual Attendance Marking

```
POST /api/v1/attendance/
Authorization: Bearer <token>
```

**Request:**
```json
{
  "employee_id": "uuid",
  "date": "2025-06-15",
  "status": "present",
  "check_in": "09:00",
  "check_out": "18:00",
  "remarks": "Manual entry - biometric device offline"
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "employee_id": "uuid",
  "date": "2025-06-15",
  "status": "present",
  "tenant_id": "uuid"
}
```

**Permissions Required:** `attendance.manage`

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Employee not found | Employee doesn't exist or belongs to different tenant |
| 400 | Duplicate attendance | Attendance already recorded for this date |

#### Step 3: Approve Attendance

```
PUT /api/v1/attendance/{attendance_id}/approve
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "approved",
  "approved_by": "uuid",
  "approved_at": "2025-06-16T10:00:00Z"
}
```

**Permissions Required:** `attendance.manage`

#### Step 4: Query Attendance

**List Attendance Records:**
```
GET /api/v1/attendance/?page=1&page_size=20&department_id={id}&status=present&from_date=2025-06-01&to_date=2025-06-30
```

**Daily Summary:**
```
GET /api/v1/attendance/daily-summary?date=2025-06-15
```

**Response (200):**
```json
{
  "date": "2025-06-15",
  "total_employees": 150,
  "present": 130,
  "absent": 10,
  "late": 5,
  "half_day": 3,
  "on_leave": 2
}
```

**Employee Attendance Summary:**
```
GET /api/v1/attendance/employee/{employee_id}?from_date=2025-06-01&to_date=2025-06-30
```

**Punch Logs:**
```
GET /api/v1/attendance/punch-logs?employee_id={id}&from_date=2025-06-01&to_date=2025-06-30
```

**Response (200):**
```json
{
  "items": [
    {
      "id": "uuid",
      "employee_id": "uuid",
      "punch_time": "2025-06-15T09:05:00Z",
      "punch_type": "in",
      "device_id": "uuid"
    }
  ],
  "total": 45,
  "page": 1,
  "page_size": 20,
  "total_pages": 3
}
```

#### Complete Attendance Data Flow

```
Biometric Device → Punch Logs Captured
     ↓
POST /attendance/process → Calculate daily attendance
     ↓
Manual corrections via POST /attendance/ (if needed)
     ↓
PUT /attendance/{id}/approve → Supervisor approves
     ↓
Reports generated via /reports/attendance/*
```

---

### 4. Leave Management

**Source:** `backend/app/api/v1/endpoints/leaves.py`

> Requires `leave.read` permission for reads, `leave.approve` for writes.

#### Step 1: Define Leave Types

```
POST /api/v1/leaves/types
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Annual Leave",
  "code": "AL",
  "max_days_per_year": 15,
  "is_paid": true,
  "carry_forward": true,
  "max_carry_forward": 5,
  "is_active": true
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "name": "Annual Leave",
  "code": "AL",
  "max_days_per_year": 15,
  "is_paid": true
}
```

**Permissions Required:** `leave.approve`

#### Step 2: Check Leave Balance

```
GET /api/v1/leaves/balance/{employee_id}?year=2025
Authorization: Bearer <token>
```

**Response (200):**
```json
[
  {
    "leave_type_id": "uuid",
    "leave_type_name": "Annual Leave",
    "total_entitled": 15,
    "taken": 5,
    "pending": 1,
    "available": 9,
    "carried_forward": 2
  }
]
```

#### Step 3: Apply for Leave

```
POST /api/v1/leaves/apply
Authorization: Bearer <token>
```

**Request:**
```json
{
  "leave_type_id": "uuid",
  "start_date": "2025-07-10",
  "end_date": "2025-07-12",
  "reason": "Family vacation",
  "is_half_day": false
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "employee_id": "uuid",
  "leave_type_id": "uuid",
  "start_date": "2025-07-10",
  "end_date": "2025-07-12",
  "days": 3,
  "status": "pending",
  "reason": "Family vacation"
}
```

**Data Flow:**
1. Looks up employee record by matching `current_user.email` to `Employee.email` within tenant
2. Validates leave balance availability
3. Creates `LeaveRequest` with status `"pending"`
4. Deducts from available balance (pending count)

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Employee record not found | No employee record matching current user |
| 400 | Insufficient leave balance | Not enough days available |
| 400 | Overlapping leave | Leave already applied for these dates |

#### Step 4: Approve/Reject Leave

**Approve:**
```
PUT /api/v1/leaves/requests/{request_id}/approve
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "approved",
  "approved_by": "uuid",
  "approved_at": "2025-07-08T14:00:00Z"
}
```

**Reject:**
```
PUT /api/v1/leaves/requests/{request_id}/reject
Authorization: Bearer <token>
```

**Request:**
```json
{
  "rejection_reason": "Insufficient team coverage during requested dates"
}
```

**Cancel (by employee):**
```
PUT /api/v1/leaves/requests/{request_id}/cancel
```

#### Step 5: Query Leave Requests

```
GET /api/v1/leaves/requests?employee_id={id}&status=pending&from_date=2025-06-01&to_date=2025-12-31&page=1&page_size=20
```

#### Complete Leave Data Flow

```
Admin defines Leave Types (POST /leaves/types)
     ↓
Leave Balances initialized per employee per year
     ↓
Employee applies (POST /leaves/apply) → status=pending
     ↓
Manager reviews (GET /leaves/requests?status=pending)
     ↓
Approve (PUT /requests/{id}/approve) → status=approved, balance deducted
  OR
Reject (PUT /requests/{id}/reject) → status=rejected, balance restored
  OR
Cancel (PUT /requests/{id}/cancel) → status=cancelled, balance restored
```

---

### 5. Payroll Processing

**Source:** `backend/app/api/v1/endpoints/payroll.py`

> Requires `payroll` feature enabled on tenant and `payroll.read` permission for reads, `payroll.manage` for writes.

#### Step 1: Define Salary Structure

```
POST /api/v1/payroll/salary-structure
Authorization: Bearer <token>
```

**Request:**
```json
{
  "employee_id": "uuid",
  "basic": 50000.00,
  "hra": 20000.00,
  "da": 5000.00,
  "conveyance": 3000.00,
  "medical": 2000.00,
  "special": 10000.00,
  "pf_employee": 6000.00,
  "esi_employee": 1000.00,
  "professional_tax": 200.00,
  "income_tax": 5000.00,
  "effective_from": "2025-01-01",
  "is_active": true
}
```

**Response (201):**
```json
{
  "id": "uuid",
  "employee_id": "uuid",
  "basic": 50000.00,
  "hra": 20000.00,
  "gross_total": 90000.00,
  "effective_from": "2025-01-01",
  "is_active": true,
  "tenant_id": "uuid"
}
```

**Permissions Required:** `payroll.manage`

**List Salary Structures:**
```
GET /api/v1/payroll/salary-structure?employee_id={id}
```

**Update Salary Structure:**
```
PUT /api/v1/payroll/salary-structure/{ss_id}
```

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Not found | Salary structure doesn't exist or belongs to different tenant |
| 403 | Feature not enabled | `payroll` feature not enabled on tenant |

#### Step 2: Generate Payslips

```
POST /api/v1/payroll/payslips/generate?month=6&year=2025&department_id={optional}
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "generated": 145,
  "month": 6,
  "year": 2025
}
```

**Permissions Required:** `payroll.manage`

**Data Flow (per employee):**
1. Fetches all active employees (optionally filtered by department)
2. Skips if payslip already exists for the month
3. Fetches active `SalaryStructure` for the employee
4. Fetches all `Attendance` records for the month
5. Calculates:
   - `present_days` = count of status "present" or "late"
   - `absent_days` = count of status "absent"
   - `half_days` = count of status "half_day"
   - `leave_days` = count of status "on_leave"
   - `ot_hours` = sum of overtime_hours
   - `lop_days` = absent + (half_days × 0.5)
   - `per_day` = (basic + hra + da + conveyance + medical + special) / working_days
   - `lop_amount` = per_day × lop_days
   - `gross` = (basic + hra + da + conveyance + medical + special) - lop_amount
   - `deductions` = pf + esi + professional_tax + income_tax
   - `net_pay` = gross - deductions
6. Creates `PaySlip` with status `"calculated"`

#### Step 3: Freeze Payslip

```
PUT /api/v1/payroll/payslips/{payslip_id}/freeze
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "frozen",
  "employee_id": "uuid",
  "month": 6,
  "year": 2025,
  "basic": 50000.00,
  "hra": 20000.00,
  "gross_earnings": 85000.00,
  "total_deductions": 12200.00,
  "net_pay": 72800.00,
  "working_days": 30,
  "present_days": 27,
  "absent_days": 1,
  "lop_days": 1,
  "lop_amount": 3000.00
}
```

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Not found | Payslip doesn't exist or belongs to different tenant |

#### Step 4: Query Payslips

```
GET /api/v1/payroll/payslips?month=6&year=2025&employee_id={id}
```

#### Step 5: Loan Management

**Create Loan:**
```
POST /api/v1/payroll/loans
```
```json
{
  "employee_id": "uuid",
  "loan_type": "personal",
  "amount": 100000.00,
  "emi_amount": 10000.00,
  "start_date": "2025-07-01",
  "tenure_months": 10
}
```

**List Loans:**
```
GET /api/v1/payroll/loans?employee_id={id}
```

#### Complete Payroll Data Flow

```
Admin defines Salary Structures per employee
     ↓
Attendance finalized for the month
     ↓
POST /payroll/payslips/generate?month=X&year=Y
     → Creates PaySlip(status="calculated") per active employee
     → Computes: gross, deductions, net_pay from attendance + salary structure
     ↓
Review generated payslips (GET /payroll/payslips)
     ↓
PUT /payroll/payslips/{id}/freeze → status="frozen" (locks payslip)
     ↓
Payslips ready for disbursement
```

---

### 6. Reports

**Source:** `backend/app/api/v1/endpoints/reports.py`

> Requires `reports` feature and `report.read` permission.

All report endpoints return file downloads (PDF/Excel/CSV) via `StreamingResponse`.

#### Attendance Reports

| Endpoint | Parameters | Description |
|----------|-----------|-------------|
| `GET /reports/attendance/daily` | `date`, `format` | Daily attendance for all employees |
| `GET /reports/attendance/monthly` | `month`, `year`, `format` | Monthly attendance summary |
| `GET /reports/attendance/employee/{id}` | `from_date`, `to_date`, `format` | Individual employee attendance |
| `GET /reports/attendance/late` | `from_date`, `to_date`, `format` | Late arrival report |
| `GET /reports/attendance/overtime` | `from_date`, `to_date`, `format` | Overtime hours report |
| `GET /reports/attendance/absent` | `date`, `format` | Absent employees for a date |
| `GET /reports/attendance/early-going` | `from_date`, `to_date`, `format` | Early departure report |
| `GET /reports/attendance/missed-punch` | `from_date`, `to_date`, `format` | Missed punch report |
| `GET /reports/attendance/department-summary` | `from_date`, `to_date`, `format` | Department-wise summary |
| `GET /reports/attendance/ot-summary` | `month`, `year`, `format` | OT summary for payroll |
| `GET /reports/attendance/muster-roll` | `month`, `year`, `format` | Muster roll (legal compliance) |

**Example Request:**
```
GET /api/v1/reports/attendance/monthly?month=6&year=2025&format=pdf
Authorization: Bearer <token>
```

**Response:** Binary file download
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="monthly_attendance_2025_06.pdf"
```

**Format Options:** `pdf`, `excel` (.xlsx), `csv`

#### Other Reports

| Endpoint | Parameters | Description |
|----------|-----------|-------------|
| `GET /reports/visitors` | `from_date`, `to_date`, `format` | Visitor log report |
| `GET /reports/devices` | `format` | Device status report |

#### Attendance Recalculation

```
POST /reports/attendance/recalculate?from_date=2025-06-01&to_date=2025-06-30&department_id={optional}
Authorization: Bearer <token>
```

Reprocesses attendance for the specified date range using `AttendanceProcessor`.

---

## School ERP Workflows

---

### 1. School Tenant Creation

**Source:** `backend/app/api/v1/endpoints/admin/tenants.py`

School tenants are created by Super Admin with `tenant_type="school"`.

```
POST /api/v1/admin/tenants/
Authorization: Bearer <super_admin_token>
```

**Request:**
```json
{
  "name": "Sunrise International School",
  "slug": "sunrise-school",
  "email": "admin@sunriseschool.edu",
  "mobile": "+91-9876543210",
  "contact_person": "Dr. Principal Name",
  "currency": "INR",
  "timezone": "Asia/Kolkata",
  "tenant_type": "school"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "Sunrise International School",
  "slug": "sunrise-school",
  "tenant_type": "school"
}
```

**Data Flow:**
1. Creates tenant with `subscription_status="trial"`
2. Applies school tenant template via `apply_tenant_template()`
3. Creates school-specific RBAC roles via `create_school_default_roles()`
4. Commits transaction

**Required Features to Enable (via Super Admin):**
- `academic_year`
- `class_management`
- `student_management`
- `student_attendance`
- `fee_management`
- `school_timetable`
- `examinations`
- `school_certificates`
- `admissions`

---

### 2. Academic Year Setup

**Source:** `backend/app/api/v1/endpoints/school/academic_year.py`

> Requires `academic_year` feature and `school.settings` permission.

#### Step 1: Create Academic Year

```
POST /api/v1/school/academic-years/
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "2025-2026",
  "start_date": "2025-04-01",
  "end_date": "2026-03-31"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "name": "2025-2026"
}
```

**Data Flow:**
- Creates `AcademicYear` with `status="planning"`

#### Step 2: Set as Current Academic Year

```
POST /api/v1/school/academic-years/{year_id}/set-current
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "is_current": true
}
```

**Data Flow:**
1. Sets all other academic years' `is_current = false`
2. Sets target year `is_current = true` and `status = "active"`

#### Step 3: Create Academic Terms

```
POST /api/v1/school/academic-years/{year_id}/terms
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Term 1",
  "start_date": "2025-04-01",
  "end_date": "2025-09-30",
  "sort_order": 1
}
```

#### Step 4: Add Holidays

```
POST /api/v1/school/academic-years/{year_id}/holidays
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Independence Day",
  "date": "2025-08-15",
  "type": "national"
}
```

#### List Academic Years

```
GET /api/v1/school/academic-years/
```

**Response (200):**
```json
[
  {
    "id": "uuid",
    "name": "2025-2026",
    "start_date": "2025-04-01",
    "end_date": "2026-03-31",
    "is_current": true,
    "status": "active"
  }
]
```

---

### 3. Classes and Sections

**Source:** `backend/app/api/v1/endpoints/school/grade_section.py`

> Requires `class_management` feature and `school.settings` permission.

#### Step 1: Create Grades

```
POST /api/v1/school/grades
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Class 10",
  "code": "X",
  "sort_order": 10
}
```

**Response (200):**
```json
{
  "id": "uuid"
}
```

#### Step 2: Create Sections under Grade

```
POST /api/v1/school/grades/{grade_id}/sections
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Section A",
  "capacity": 40,
  "class_teacher_id": "uuid",
  "academic_year_id": "uuid"
}
```

#### Step 3: Create Subjects

```
POST /api/v1/school/subjects
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Mathematics",
  "code": "MATH",
  "subject_type": "core",
  "credits": 4.0,
  "max_marks": 100,
  "pass_marks": 33,
  "has_practical": false
}
```

> Requires `subject_management` feature.

#### Step 4: Assign Subjects to Grade

```
POST /api/v1/school/grades/{grade_id}/subjects
Authorization: Bearer <token>
```

**Request:**
```json
{
  "subject_ids": ["uuid1", "uuid2", "uuid3"],
  "academic_year_id": "uuid"
}
```

**Response (200):**
```json
{
  "assigned": 3
}
```

#### Query Operations

**List Grades:**
```
GET /api/v1/school/grades
```

**List Sections for Grade:**
```
GET /api/v1/school/grades/{grade_id}/sections?academic_year_id={id}
```

**List Students in Section:**
```
GET /api/v1/school/sections/{section_id}/students
```

**List Grade Subjects:**
```
GET /api/v1/school/grades/{grade_id}/subjects?academic_year_id={id}
```

---

### 4. Student Enrollment

**Source:** `backend/app/api/v1/endpoints/school/admission.py`, `backend/app/api/v1/endpoints/school/student.py`

> Requires `student_management` feature and `student.read` permission.

#### Workflow A: Via Admission Process

##### Step 1: Record Inquiry

```
POST /api/v1/school/admissions/inquiries
Authorization: Bearer <token>
```

**Request:**
```json
{
  "student_name": "Aarav Sharma",
  "parent_name": "Rajesh Sharma",
  "phone": "+91-9876543210",
  "email": "rajesh@email.com",
  "grade_applying": "Class 10",
  "source": "website",
  "notes": "Transferring from another city"
}
```

##### Step 2: Submit Application

```
POST /api/v1/school/admissions/applications
Authorization: Bearer <token>
```

**Request:**
```json
{
  "inquiry_id": "uuid",
  "student_name": "Aarav Sharma",
  "date_of_birth": "2010-03-15",
  "gender": "male",
  "grade_applying": "Class 10",
  "parent_name": "Rajesh Sharma",
  "parent_phone": "+91-9876543210",
  "parent_email": "rajesh@email.com",
  "previous_school": "Delhi Public School",
  "address": "456 Park Avenue, Mumbai",
  "academic_year_id": "uuid"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "application_number": "APP-202506-1234"
}
```

##### Step 3: Review Application

```
PUT /api/v1/school/admissions/applications/{app_id}/review
Authorization: Bearer <token>
```

**Request:**
```json
{
  "status": "selected",
  "remarks": "Meets all admission criteria"
}
```

##### Step 4: Enroll Student

```
POST /api/v1/school/admissions/applications/{app_id}/enroll
Authorization: Bearer <token>
```

**Request:**
```json
{
  "grade_id": "uuid",
  "section_id": "uuid"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "admission_number": "ADM-2025-1234"
}
```

**Data Flow:**
1. Validates application status is `"selected"` or `"submitted"`
2. Creates `Student` record with admission number
3. Links application to student
4. Sets application status to `"enrolled"`

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Application not found | Application doesn't exist |
| 400 | Invalid state | Application not in enrollable state |

#### Workflow B: Direct Student Creation

```
POST /api/v1/school/students/
Authorization: Bearer <token>
```

**Request:**
```json
{
  "admission_number": "ADM-2025-0050",
  "first_name": "Priya",
  "last_name": "Patel",
  "date_of_birth": "2010-08-22",
  "gender": "female",
  "admission_date": "2025-04-01",
  "current_grade_id": "uuid",
  "current_section_id": "uuid",
  "academic_year_id": "uuid",
  "emergency_contact_name": "Suresh Patel",
  "emergency_contact_phone": "+91-9876543211"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "admission_number": "ADM-2025-0050"
}
```

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 400 | Duplicate admission number | `"Admission number already exists"` |

#### Add Guardian Information

```
POST /api/v1/school/students/{student_id}/guardians
Authorization: Bearer <token>
```

**Request:**
```json
{
  "first_name": "Rajesh",
  "last_name": "Sharma",
  "phone": "+91-9876543210",
  "email": "rajesh@email.com",
  "occupation": "Engineer",
  "relationship": "father",
  "is_primary": true
}
```

#### Student Promotion

```
POST /api/v1/school/students/{student_id}/promote
Authorization: Bearer <token>
```

**Request:**
```json
{
  "new_grade_id": "uuid",
  "new_section_id": "uuid",
  "new_academic_year_id": "uuid"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "status": "promoted"
}
```

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Student not found | Student doesn't exist or belongs to different tenant |

---

### 5. Teacher Allocation

**Source:** `backend/app/api/v1/endpoints/school/grade_section.py:238`

> Requires `class_management` feature and `school.settings` permission.

#### Allocate Teacher to Subject-Section

```
POST /api/v1/school/teacher-allocations
Authorization: Bearer <token>
```

**Request:**
```json
{
  "employee_id": "uuid",
  "subject_id": "uuid",
  "section_id": "uuid",
  "academic_year_id": "uuid",
  "periods_per_week": 6
}
```

**Response (200):**
```json
{
  "id": "uuid"
}
```

#### List Teacher Allocations

```
GET /api/v1/school/teacher-allocations?section_id={id}&employee_id={id}&academic_year_id={id}
Authorization: Bearer <token>
```

---

### 6. Student Attendance

**Source:** `backend/app/api/v1/endpoints/school/student_attendance.py`

> Requires `student_attendance` feature and `student_attendance.read` permission.

#### Mark Individual Attendance

```
POST /api/v1/school/student-attendance/mark
Authorization: Bearer <token>
```

**Request:**
```json
{
  "student_id": "uuid",
  "date": "2025-06-15",
  "status": "present",
  "remarks": null,
  "attendance_type": "daily"
}
```

**Response (200):**
```json
{
  "status": "marked"
}
```

**Data Flow:**
1. Validates student exists and belongs to tenant
2. Checks for existing attendance record (same student, date, type)
3. If exists: updates status
4. If new: creates `StudentAttendance` record

**Error Handling:**
| Status | Condition | Detail |
|--------|-----------|--------|
| 404 | Student not found | Student doesn't exist or belongs to different tenant |

#### Bulk Mark Attendance (Entire Section)

```
POST /api/v1/school/student-attendance/bulk-mark
Authorization: Bearer <token>
```

**Request:**
```json
{
  "section_id": "uuid",
  "date": "2025-06-15",
  "attendance_type": "daily",
  "marks": [
    {"student_id": "uuid1", "status": "present"},
    {"student_id": "uuid2", "status": "absent"},
    {"student_id": "uuid3", "status": "late"},
    {"student_id": "uuid4", "status": "present"}
  ]
}
```

**Response (200):**
```json
{
  "marked": 4
}
```

#### Period-wise Attendance

```
POST /api/v1/school/student-attendance/mark
```
```json
{
  "student_id": "uuid",
  "date": "2025-06-15",
  "status": "present",
  "attendance_type": "period",
  "period_definition_id": "uuid"
}
```

#### Query Attendance

**Date Range Query:**
```
GET /api/v1/school/student-attendance/?date_from=2025-06-01&date_to=2025-06-30&section_id={id}
```

**Daily Summary:**
```
GET /api/v1/school/student-attendance/daily-summary?date=2025-06-15&section_id={id}
```

**Response (200):**
```json
{
  "present": 35,
  "absent": 3,
  "late": 1,
  "half-day": 1
}
```

---

### 7. Fee Structure and Collection

**Source:** `backend/app/api/v1/endpoints/school/fee.py`

> Requires `fee_management` feature and `fee.read` permission.

#### Step 1: Create Fee Categories

```
POST /api/v1/school/fees/categories
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Tuition Fee",
  "code": "TUIT",
  "sort_order": 1
}
```

**Common Categories:** Tuition, Lab, Library, Sports, Transport, Hostel, Exam

#### Step 2: Define Fee Structure per Grade

```
POST /api/v1/school/fees/structures
Authorization: Bearer <token>
```

**Request:**
```json
{
  "academic_year_id": "uuid",
  "grade_id": "uuid",
  "fee_category_id": "uuid",
  "amount": 5000.00,
  "frequency": "monthly",
  "due_day": 10,
  "is_mandatory": true
}
```

**Frequency Options:** `monthly`, `quarterly`, `half_yearly`, `annual`, `one_time`

#### Step 3: Record Fee Payment

```
POST /api/v1/school/fees/payments
Authorization: Bearer <token>
```

**Request:**
```json
{
  "student_id": "uuid",
  "student_fee_id": "uuid",
  "amount": 5000.00,
  "payment_date": "2025-06-10",
  "payment_method": "online",
  "reference_number": "TXN-20250610-5678",
  "remarks": "June tuition fee"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "receipt_number": "RCP-20250610-1234"
}
```

**Data Flow:**
1. Creates `FeePayment` with auto-generated receipt number
2. Fetches `StudentFee` record
3. Calculates total paid across all payments for this fee
4. Updates `StudentFee.status`:
   - `"paid"` if total_paid >= final_amount
   - `"partial"` if total_paid < final_amount

#### Query Operations

**List Fee Categories:**
```
GET /api/v1/school/fees/categories?page=1&page_size=50
```

**List Fee Structures:**
```
GET /api/v1/school/fees/structures?academic_year_id={id}&grade_id={id}
```

**Student Fee Summary:**
```
GET /api/v1/school/fees/students/{student_id}
```

**Response (200):**
```json
[
  {
    "id": "uuid",
    "fee_structure_id": "uuid",
    "amount": 5000.00,
    "discount_amount": 0.00,
    "scholarship_amount": 0.00,
    "final_amount": 5000.00,
    "due_date": "2025-06-10",
    "status": "paid"
  }
]
```

**List Payments:**
```
GET /api/v1/school/fees/payments?student_id={id}&page=1&page_size=50
```

**Fee Dues Report:**
```
GET /api/v1/school/fees/reports/dues?academic_year_id={id}
```

#### Complete Fee Data Flow

```
Admin creates Fee Categories (POST /fees/categories)
     ↓
Admin defines Fee Structures per grade per academic year (POST /fees/structures)
     → Links: academic_year + grade + fee_category + amount + frequency
     ↓
StudentFee records auto-generated per student (system process)
     ↓
Fee collection (POST /fees/payments)
     → Creates payment with receipt number
     → Auto-updates StudentFee status (paid/partial)
     ↓
Track dues (GET /fees/reports/dues)
     ↓
Student summary (GET /fees/students/{id})
```

---

### 8. Timetable Management

**Source:** `backend/app/api/v1/endpoints/school/timetable.py`

> Requires `school_timetable` feature and `school.settings` permission.

#### Step 1: Define Period Schedule

```
POST /api/v1/school/timetable/periods
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Period 1",
  "start_time": "08:00",
  "end_time": "08:45",
  "period_type": "period",
  "sort_order": 1
}
```

**Period Types:** `period`, `break`, `lunch`, `assembly`

#### Step 2: Set Section Timetable

```
POST /api/v1/school/timetable/section/{section_id}
Authorization: Bearer <token>
```

**Request:**
```json
[
  {
    "section_id": "uuid",
    "subject_id": "uuid",
    "employee_id": "uuid",
    "room_id": "uuid",
    "period_definition_id": "uuid",
    "day_of_week": 1,
    "academic_year_id": "uuid"
  },
  {
    "section_id": "uuid",
    "subject_id": "uuid2",
    "employee_id": "uuid2",
    "room_id": "uuid",
    "period_definition_id": "uuid2",
    "day_of_week": 1,
    "academic_year_id": "uuid"
  }
]
```

**Response (200):**
```json
{
  "saved": 2
}
```

**Data Flow:**
- `day_of_week`: 1=Monday, 2=Tuesday, ..., 5=Friday
- If entry exists for same section+day+period+year: updates it
- Otherwise: creates new entry

#### Step 3: Create Substitutions

```
POST /api/v1/school/timetable/substitutions
Authorization: Bearer <token>
```

**Request:**
```json
{
  "original_employee_id": "uuid",
  "substitute_employee_id": "uuid",
  "timetable_entry_id": "uuid",
  "date": "2025-06-16",
  "reason": "Original teacher on leave"
}
```

#### Query Timetables

**Section Timetable:**
```
GET /api/v1/school/timetable/section/{section_id}?academic_year_id={id}
```

**Teacher Timetable:**
```
GET /api/v1/school/timetable/teacher/{employee_id}?academic_year_id={id}
```

**List Substitutions:**
```
GET /api/v1/school/timetable/substitutions?date_from=2025-06-01&date_to=2025-06-30
```

---

### 9. Examinations and Marks

**Source:** `backend/app/api/v1/endpoints/school/examination.py`

> Requires `examinations` feature and `exam.read` permission.

#### Step 1: Create Exam Type

```
POST /api/v1/school/examinations/exam-types
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Mid-Term Examination",
  "code": "MID",
  "weightage": 30.0,
  "exam_category": "internal"
}
```

**Exam Categories:** `internal`, `external`, `board`

**Permissions Required:** `exam.create`

#### Step 2: Create Exam

```
POST /api/v1/school/examinations/exams
Authorization: Bearer <token>
```

**Request:**
```json
{
  "exam_type_id": "uuid",
  "academic_year_id": "uuid",
  "academic_term_id": "uuid",
  "name": "Mid-Term Exam June 2025",
  "start_date": "2025-06-20",
  "end_date": "2025-06-30"
}
```

Creates exam with `status="draft"`.

**Permissions Required:** `exam.create`

#### Step 3: Create Exam Schedules

```
POST /api/v1/school/examinations/exams/{exam_id}/schedules
Authorization: Bearer <token>
```

**Request:**
```json
{
  "subject_id": "uuid",
  "grade_id": "uuid",
  "exam_date": "2025-06-20",
  "start_time": "09:00",
  "end_time": "12:00",
  "max_marks": 100,
  "pass_marks": 33
}
```

**Permissions Required:** `exam.manage`

#### Step 4: Enter Marks

**Individual Entry:**
```
POST /api/v1/school/examinations/marks/enter
Authorization: Bearer <token>
```

**Request:**
```json
{
  "exam_schedule_id": "uuid",
  "student_id": "uuid",
  "marks_obtained": 85.0,
  "practical_marks": null,
  "grade": "A",
  "is_absent": false,
  "remarks": null
}
```

**Response (200):**
```json
{
  "status": "entered"
}
```

**Data Flow:**
- If mark exists for same student+schedule: updates it
- Otherwise: creates new mark entry

**Bulk Entry:**
```
POST /api/v1/school/examinations/marks/bulk-enter
Authorization: Bearer <token>
```

**Request:**
```json
[
  {
    "exam_schedule_id": "uuid",
    "student_id": "uuid1",
    "marks_obtained": 85.0,
    "is_absent": false
  },
  {
    "exam_schedule_id": "uuid",
    "student_id": "uuid2",
    "marks_obtained": 92.0,
    "is_absent": false
  },
  {
    "exam_schedule_id": "uuid",
    "student_id": "uuid3",
    "marks_obtained": null,
    "is_absent": true,
    "remarks": "Medical leave"
  }
]
```

**Response (200):**
```json
{
  "entered": 3
}
```

#### Step 5: Create Grading Scale

```
POST /api/v1/school/examinations/grading-scales
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "CBSE Grading",
  "scale_type": "percentage",
  "is_default": true,
  "details": [
    {"min_marks": 91, "max_marks": 100, "grade": "A1", "grade_point": 10},
    {"min_marks": 81, "max_marks": 90, "grade": "A2", "grade_point": 9},
    {"min_marks": 71, "max_marks": 80, "grade": "B1", "grade_point": 8},
    {"min_marks": 61, "max_marks": 70, "grade": "B2", "grade_point": 7},
    {"min_marks": 51, "max_marks": 60, "grade": "C1", "grade_point": 6},
    {"min_marks": 41, "max_marks": 50, "grade": "C2", "grade_point": 5},
    {"min_marks": 33, "max_marks": 40, "grade": "D", "grade_point": 4},
    {"min_marks": 0, "max_marks": 32, "grade": "E", "grade_point": 0}
  ]
}
```

#### Query Operations

**List Exam Types:**
```
GET /api/v1/school/examinations/exam-types
```

**List Exams:**
```
GET /api/v1/school/examinations/exams?academic_year_id={id}
```

**List Exam Schedules:**
```
GET /api/v1/school/examinations/exams/{exam_id}/schedules
```

**Get Marks for Schedule:**
```
GET /api/v1/school/examinations/marks/{exam_schedule_id}
```

**Response (200):**
```json
[
  {
    "id": "uuid",
    "student_id": "uuid",
    "student_name": "Aarav Sharma",
    "marks_obtained": 85.0,
    "practical_marks": null,
    "grade": "A",
    "is_absent": false
  }
]
```

#### Complete Examination Data Flow

```
Create Exam Types (POST /exam-types)
     → e.g., Mid-Term, Final, Unit Test
     ↓
Create Exam instance (POST /exams)
     → Links to academic year, term, date range
     ↓
Create Exam Schedules (POST /exams/{id}/schedules)
     → Per subject, per grade: date, time, max/pass marks
     ↓
Enter Marks (POST /marks/enter or /marks/bulk-enter)
     → Per student per schedule
     ↓
Query marks (GET /marks/{schedule_id})
     → For report card generation
     ↓
Grading scales used to convert marks → grades
```

---

### 10. Report Cards and Certificates

**Source:** `backend/app/api/v1/endpoints/school/certificate.py`

> Requires `school_certificates` feature and `certificate.issue` permission.

#### Certificate Templates

**Create Template:**
```
POST /api/v1/school/certificates/templates
Authorization: Bearer <token>
```

**Request:**
```json
{
  "name": "Merit Certificate",
  "template_type": "merit",
  "template_html": "<html>...</html>",
  "is_default": true
}
```

**List Templates:**
```
GET /api/v1/school/certificates/templates?template_type=merit
```

#### Issue Certificate

```
POST /api/v1/school/certificates/issue
Authorization: Bearer <token>
```

**Request:**
```json
{
  "student_id": "uuid",
  "template_id": "uuid",
  "issue_date": "2025-03-31",
  "purpose": "Academic excellence in 2024-2025"
}
```

**Response (200):**
```json
{
  "id": "uuid",
  "certificate_number": "CERT-20250331-5678"
}
```

**Data Flow:**
1. Validates student exists and belongs to tenant
2. Generates unique certificate number (`CERT-YYYYMMDD-XXXX`)
3. Creates `IssuedCertificate` record

#### List Student Certificates

```
GET /api/v1/school/certificates/student/{student_id}
Authorization: Bearer <token>
```

#### Report Card Generation Workflow

Report cards are generated by combining data from multiple modules:

```
Exam marks (GET /examinations/marks/{schedule_id})
     ↓
Grading scales (GET /examinations/grading-scales)
     ↓
Student info (GET /students/{id})
     ↓
Attendance summary (GET /student-attendance/daily-summary)
     ↓
Report card template renders:
  - Subject-wise marks and grades
  - Total / Percentage / Grade
  - Attendance summary
  - Co-curricular activities
  - Remarks
```

---

## Cross-Cutting Concerns

### Error Handling Summary

#### Common HTTP Status Codes

| Code | Meaning | Common Causes |
|------|---------|---------------|
| 200 | Success | Operation completed |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Validation errors, duplicate entries, invalid state transitions |
| 401 | Unauthorized | Missing/expired JWT token, wrong credentials |
| 403 | Forbidden | Insufficient permissions, feature not enabled |
| 404 | Not Found | Resource doesn't exist or belongs to different tenant |
| 423 | Locked | Account locked due to failed login attempts |
| 429 | Too Many Requests | Rate limit exceeded |

#### Authentication Errors

```json
// 401 - Invalid credentials
{"detail": "Incorrect email or password."}

// 400 - Inactive account
{"detail": "User account is inactive."}

// 423 - Account locked
{"detail": "Account is locked. Try again after X minutes."}

// 401 - Invalid/expired token
{"detail": "Could not validate credentials"}

// 401 - Revoked token
{"detail": "Refresh token has been revoked."}
```

#### Permission Errors

```json
// 403 - Missing permission
{"detail": "Permission denied: required permission 'employee.read'"}

// 403 - Feature not enabled
{"detail": "Feature 'payroll' is not enabled for this tenant"}

// 403 - Not superuser
{"detail": "Not a super admin"}
```

#### Tenant Isolation

All endpoints enforce tenant isolation via `current_user.tenant_id`. Cross-tenant data access is impossible through normal API calls. The tenant context is embedded in the JWT token during login.

### API Prefix

All endpoints are prefixed with `/api/v1/`. The school module endpoints are under `/api/v1/school/`. Super Admin endpoints are under `/api/v1/admin/`.

**Base URL Pattern:**
```
https://{domain}/api/v1/{resource}
https://{domain}/api/v1/school/{resource}
https://{domain}/api/v1/admin/{resource}
```

### Permission Model

Each endpoint requires specific permissions checked via `require_permissions()` dependency:

| Module | Read Permission | Write Permission |
|--------|----------------|-----------------|
| Tenants | `tenant.read` | (superuser only) |
| Employees | `employee.read` | `employee.create`, `employee.update`, `employee.delete` |
| Employee Lifecycle | `employee.read` | `employee.manage` |
| Attendance | `attendance.read` | `attendance.manage` |
| Leaves | `leave.read` | `leave.approve` |
| Payroll | `payroll.read` | `payroll.manage` |
| Reports | `report.read` | - |
| Onboarding | `onboarding.read` | `onboarding.write` |
| Exit Management | `exit.read` | `exit.write` |
| School Settings | `school.settings` | `school.settings` |
| Students | `student.read` | `student.write` |
| Student Attendance | `student_attendance.read` | `student_attendance.write` |
| Fees | `fee.read` | `fee.write` |
| Examinations | `exam.read` | `exam.create`, `exam.manage` |
| Certificates | `certificate.issue` | `certificate.issue` |

### Feature Flags

Certain modules require feature flags enabled on the tenant:

| Feature Flag | Module |
|-------------|--------|
| `payroll` | Payroll processing |
| `reports` | Report generation |
| `onboarding` | Employee onboarding |
| `exit_management` | Exit request management |
| `academic_year` | Academic year management |
| `class_management` | Grades, sections, teacher allocation |
| `subject_management` | Subject CRUD |
| `student_management` | Student CRUD |
| `student_attendance` | Student attendance |
| `fee_management` | Fee structure and collection |
| `school_timetable` | Timetable management |
| `examinations` | Exam and marks management |
| `school_certificates` | Certificate generation |
| `admissions` | Admission workflow |

### Rate Limiting

| Endpoint | Limit | Period |
|----------|-------|--------|
| `POST /auth/login` | 5 | 60 seconds |
| `POST /auth/register` | 3 | 60 seconds |
| `POST /auth/refresh` | 10 | 60 seconds |
| `POST /admin/auth/login` | 5 | 60 seconds |
