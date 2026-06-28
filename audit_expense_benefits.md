# Expense/Benefits Module Audit — Apex HRMS

## 1. Endpoint Router: `backend/app/api/v1/endpoints/expense_benefits.py`

### Purpose
Single FastAPI router combining CRUD for expense categories, expense claims, tax declarations, benefits, and employee-benefit assignments. All queries are tenant-scoped via `current_user.tenant_id`.

### Feature Flags & Permissions

- **Feature gate**: `require_feature("expense")` at router level — all endpoints require the `expense` feature enabled on the tenant.
- **Permission gate**: `require_permissions("expense.read")` at router level — only `expense.read` is enforced; no separate write/approve codenames exist.
- **Superuser bypass**: Both gates are skipped for `is_superuser=True` users.

### API Endpoints

| Method | Path | Filters | Description |
|--------|------|---------|-------------|
| GET | `/expense-categories` | — | List categories |
| POST | `/expense-categories` | — | Create category |
| GET | `/expense-claims` | `employee_id`, `status` | List claims |
| POST | `/expense-claims` | — | Create claim |
| PUT | `/expense-claims/{claim_id}` | — | Update claim; auto-sets `approved_at` when status → `approved` |
| GET | `/tax-declarations` | `employee_id` | List declarations |
| POST | `/tax-declarations` | — | Create declaration |
| PUT | `/tax-declarations/{td_id}` | — | Update declaration |
| GET | `/benefits` | — | List benefit definitions |
| POST | `/benefits` | — | Create benefit |
| GET | `/employee-benefits` | `employee_id` | List employee-benefit assignments |
| POST | `/employee-benefits` | — | Assign benefit to employee |

### Observations

- **No DELETE endpoints** exist for any entity.
- **No pagination** — all list endpoints return full result sets.
- **Write ops share read permission** — POST/PUT use the same `expense.read` permission as GET. No `expense.write` or `expense.approve` granularity.
- **Approval logic is inline** in the PUT handler (sets `approved_at` timestamp) with no separate approval workflow or state-machine validation.
- **No receipt upload endpoint** — `receipt_path` exists on the model but there's no file upload handler.

---

## 2. Model: `backend/app/models/expense.py`

### `ExpenseStatus` (enum)
Values: `draft`, `submitted`, `approved`, `rejected`, `reimbursed`

### `ExpenseCategory` (extends `TenantModel`)

| Column | Type | Constraints |
|--------|------|-------------|
| `tenant_id` | UUID FK → `tenants.id` | CASCADE, indexed |
| `name` | String(255) | NOT NULL |
| `code` | String(100) | NOT NULL |
| `description` | Text | nullable |
| `is_active` | Boolean | default True |

Inherited from `TenantModel`: `id` (UUID PK), `created_at`, `updated_at`

### `ExpenseClaim` (extends `TenantModel`)

| Column | Type | Constraints |
|--------|------|-------------|
| `tenant_id` | UUID FK → `tenants.id` | CASCADE, indexed |
| `employee_id` | UUID FK → `employees.id` | CASCADE, indexed |
| `category_id` | UUID FK → `expense_categories.id` | SET NULL, nullable |
| `amount` | Float | NOT NULL |
| `date` | Date | NOT NULL |
| `description` | Text | nullable |
| `receipt_path` | String(512) | nullable |
| `status` | String(50) | default `draft` |
| `approved_by` | UUID FK → `employees.id` | SET NULL, nullable |
| `approved_at` | DateTime(tz) | nullable |

**Relationships**: `employee` → Employee, `approver` → Employee, `category` → ExpenseCategory

### Cross-Module Dependencies
- `employees` table (for `employee_id` and `approved_by` foreign keys)
- `tenants` table (multi-tenancy isolation)
- `expense_categories` table (category reference on claims)

---

## 3. Model: `backend/app/models/benefit.py`

### `Benefit` (extends `TenantModel`)

| Column | Type | Constraints |
|--------|------|-------------|
| `tenant_id` | UUID FK → `tenants.id` | CASCADE, indexed |
| `name` | String(255) | NOT NULL |
| `type` | String(50) | default `allowance` |
| `amount` | Float | default 0 |
| `frequency` | String(50) | default `monthly` |
| `is_taxable` | Boolean | default True |
| `is_active` | Boolean | default True |

### `EmployeeBenefit` (extends `TenantModel`)

| Column | Type | Constraints |
|--------|------|-------------|
| `tenant_id` | UUID FK → `tenants.id` | CASCADE, indexed |
| `employee_id` | UUID FK → `employees.id` | CASCADE, indexed |
| `benefit_id` | UUID FK → `benefits.id` | CASCADE, indexed |
| `amount` | Float | default 0 |
| `effective_from` | Date | NOT NULL |
| `is_active` | Boolean | default True |

**Relationships**: `employee` → Employee, `benefit` → Benefit

### Cross-Module Dependencies
- `employees` table (employee assignment)
- `tenants` table (multi-tenancy)
- `benefits` table (benefit definition reference)

---

## 4. Model: `backend/app/models/tax.py`

### `TaxDeclaration` (extends `TenantModel`)

| Column | Type | Constraints |
|--------|------|-------------|
| `tenant_id` | UUID FK → `tenants.id` | CASCADE, indexed |
| `employee_id` | UUID FK → `employees.id` | CASCADE, indexed |
| `financial_year` | String(10) | NOT NULL |
| `hra_received` | Float | default 0 |
| `rent_paid` | Float | default 0 |
| `section_80c` | Float | default 0 |
| `section_80d` | Float | default 0 |
| `home_loan_interest` | Float | default 0 |
| `other_exemptions` | Float | default 0 |
| `status` | String(50) | default `draft` |
| `remarks` | Text | nullable |

### Cross-Module Dependencies
- `employees` table (employee reference)
- `tenants` table (multi-tenancy)

---

## 5. Schemas: `backend/app/schemas/hr_features.py`

All schemas are shared in a single file with other HR features (assets, travel, announcements, polls, notifications).

| Schema | Type | Fields |
|--------|------|--------|
| `ExpenseCategoryCreate` | Input | `name`, `code`, `description?`, `is_active` |
| `ExpenseCategoryResponse` | Output | + `id`, `tenant_id`, `created_at`, `updated_at` |
| `ExpenseClaimCreate` | Input | `employee_id`, `category_id?`, `amount`, `date`, `description?` |
| `ExpenseClaimUpdate` | Input | `status?`, `approved_by?` |
| `ExpenseClaimResponse` | Output | + `id`, `tenant_id`, `status`, `approved_by?`, `approved_at?`, timestamps |
| `TaxDeclarationCreate` | Input | `employee_id`, `financial_year`, all exemption floats |
| `TaxDeclarationUpdate` | Input | all exemption floats?, `status?` |
| `TaxDeclarationResponse` | Output | + `id`, `tenant_id`, `status`, timestamps |
| `BenefitCreate` | Input | `name`, `type`, `amount`, `frequency`, `is_taxable` |
| `BenefitResponse` | Output | + `id`, `tenant_id`, `is_active`, timestamps |
| `EmployeeBenefitCreate` | Input | `employee_id`, `benefit_id`, `amount`, `effective_from` |
| `EmployeeBenefitResponse` | Output | + `id`, `tenant_id`, `is_active`, timestamps |

---

## 6. Base Model: `backend/app/db/base.py`

`TenantModel` provides:
- `id`: UUID primary key (auto-generated via `gen_random_uuid()`)
- `created_at`: DateTime with timezone, server-default `now()`
- `updated_at`: DateTime with timezone, auto-updates on change
- `tenant_id`: UUID FK → `tenants.id` with CASCADE delete

---

## 7. Dependency Injection: `backend/app/core/deps.py`

| Dependency | Purpose |
|------------|---------|
| `get_db` | Async SQLAlchemy session |
| `get_current_active_user` | JWT auth + active check |
| `require_permissions(*codenames)` | RBAC check; superusers bypass |
| `require_feature(feature_code)` | Tenant feature flag check; superusers bypass |

---

## 8. Findings & Risks

| Category | Finding | Severity |
|----------|---------|----------|
| **Auth** | No write-level permissions — any user with `expense.read` can create/update/approve | High |
| **Data integrity** | `amount` uses `Float` instead of `Numeric/Decimal` — rounding errors on financial data | Medium |
| **Missing endpoints** | No DELETE for any entity; no receipt file upload | Medium |
| **Pagination** | All list endpoints return unbounded results | Medium |
| **State machine** | `ExpenseStatus` enum exists but status transitions aren't enforced in code — any string accepted | Medium |
| **Approval workflow** | Approval is a simple field update with no role check or multi-step workflow | Medium |
| **Schema organization** | All HR feature schemas crammed into one 92-line file | Low |
| **Tenant isolation** | Properly enforced — all queries filter by `tenant_id` | OK |
| **Relationships** | Properly defined with appropriate CASCADE/SET NULL behavior | OK |

---

## 9. Cross-Module Dependency Map

```
expense_benefits.py (router)
  ├── models/expense.py ──→ tenants, employees, expense_categories
  ├── models/benefit.py ──→ tenants, employees, benefits
  ├── models/tax.py ──────→ tenants, employees
  ├── schemas/hr_features.py
  └── core/deps.py ───────→ core/rbac.py, core/feature_gate.py
```

**External module dependencies**: `employees` module (FK references), `tenants` module (multi-tenancy), `auth` module (JWT + RBAC).
