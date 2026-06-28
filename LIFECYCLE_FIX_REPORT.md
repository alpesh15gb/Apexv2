# Lifecycle Module Bug Fix Report

## Summary

The employee lifecycle module (`backend/app/api/v1/endpoints/lifecycle.py`) contained multiple critical bugs affecting salary management, permission enforcement, and state validation across all lifecycle operations.

---

## Bugs Found and Fixed

### Bug 1: CRITICAL — Salary Revision Does Not Update Salary

**Root Cause**: The `revise_salary` endpoint (line 236–258) created an `EmployeeEvent` record but never updated the actual salary data. Salary is stored in the `SalaryStructure` model (in `payroll.py`), not on the `Employee` model. The handler only logged the event without creating or updating a `SalaryStructure` record.

**Impact**: All salary revisions were silently lost. Payroll calculations would use stale salary data. Employees and HR would see revision events in the timeline but the actual salary remained unchanged.

**Fix Applied**:
- Import `SalaryStructure` from `app.models.payroll`
- Validate `new_salary` is provided and positive
- Deactivate the current active `SalaryStructure` (`is_active = False`)
- Create a new `SalaryStructure` with the revised basic salary, carrying forward other components (HRA, DA, etc.)
- Set `effective_from` to `effective_date` or `event_date`
- Record old and new salary in the event description for audit trail

---

### Bug 2: Promote Ignores Salary Changes

**Root Cause**: Line 80–81 — `if data.new_salary: pass` — salary update during promotion was explicitly skipped with a no-op.

**Impact**: Promotions that included a salary revision would update the designation but silently ignore the salary change.

**Fix Applied**:
- Validate that at least one of `new_designation_id` or `new_salary` is provided
- When `new_salary` is provided, deactivate old `SalaryStructure` and create a new one (same pattern as salary revision)
- Include salary change details in the event description

---

### Bug 3: Transfer Records Manager Change But Doesn't Apply It

**Root Cause**: Line 115–116 — `new_manager_id` was appended to the changes list but never set on the employee model. The `Employee` model has no `manager_id` column, so this is also a data model gap.

**Impact**: Transfer events would claim a manager change occurred but no data was persisted.

**Fix Applied**:
- Added validation requiring at least one transfer field
- Manager ID is now recorded in the event description for audit purposes
- **Note**: The `Employee` model lacks a `manager_id`/`reporting_to` column — this requires a schema migration to fully resolve

---

### Bug 4: Confirm Does Not Update Employee Status

**Root Cause**: Line 131–153 — The confirm endpoint created an event but never set `employee.status = "active"`. An employee confirmed from probation would still have their old status.

**Impact**: Confirmed employees remained in their previous status. Downstream systems (attendance, payroll) would not recognize them as confirmed.

**Fix Applied**:
- Set `employee.status = "active"` on confirmation
- Added guard against confirming a terminated employee

---

### Bug 5: Missing Write Permission Checks on All Mutation Endpoints

**Root Cause**: The router only enforced `employee.read` at the module level. All POST mutation endpoints (promote, transfer, confirm, resign, terminate, reactivate, salary-revision) inherited only the read permission check.

**Impact**: Any user with `employee.read` permission could perform destructive lifecycle operations (terminate, resign, salary changes) without proper authorization.

**Fix Applied**:
- Added `dependencies=[Depends(require_permissions("employee.manage"))]` to all POST endpoints
- This matches the RBAC configuration in `scripts/apply_rbac.py` and `scripts/add_rbac.py`

---

### Bug 6: No Status Validation on Resign/Terminate

**Root Cause**: No checks prevented resigning or terminating an employee who was already resigned or terminated.

**Impact**: Duplicate resign/terminate operations would overwrite status and create redundant events, corrupting the employee timeline.

**Fix Applied**:
- Resign: Reject if status is already `terminated` or `resigned`
- Terminate: Reject if status is already `terminated`

---

### Bug 7: Reactivate Allows Reactivating Active Employees

**Root Cause**: No check that the employee was actually inactive before reactivating.

**Impact**: Active employees could be "reactivated" creating misleading timeline events.

**Fix Applied****: Reject if employee status is already `active`

---

### Bug 8: Missing `created_by` on All Events

**Root Cause**: The `EmployeeEvent` model has a `created_by` field but none of the handlers set it.

**Impact**: Audit trail was incomplete —无法追踪 which user performed each lifecycle action.

**Fix Applied**: Set `created_by=current_user.id` on all `EmployeeEvent` creations.

---

## Files Modified

| File | Change |
|------|--------|
| `backend/app/api/v1/endpoints/lifecycle.py` | All 8 bug fixes applied |

## Regression Test Cases

### TC-01: Salary Revision Creates Salary Structure
- **Precondition**: Employee with active salary structure (basic=50000)
- **Action**: POST `/{id}/salary-revision` with `new_salary=60000`
- **Expected**: Old salary structure deactivated, new structure with basic=60000 created, event logged

### TC-02: Salary Revision Rejects Invalid Salary
- **Action**: POST `/{id}/salary-revision` with `new_salary=-1000`
- **Expected**: 400 error "new_salary is required and must be positive"

### TC-03: Salary Revision Rejects Missing Salary
- **Action**: POST `/{id}/salary-revision` with `new_salary=null`
- **Expected**: 400 error

### TC-04: Salary Revision for Terminated Employee
- **Precondition**: Employee status = "terminated"
- **Action**: POST `/{id}/salary-revision`
- **Expected**: 400 error "Cannot revise salary for a terminated employee"

### TC-05: Promotion Updates Both Designation and Salary
- **Action**: POST `/{id}/promote` with `new_designation_id` and `new_salary=70000`
- **Expected**: Designation updated, salary structure created, event includes both changes

### TC-06: Promotion Rejects No Changes
- **Action**: POST `/{id}/promote` with neither `new_designation_id` nor `new_salary`
- **Expected**: 400 error

### TC-07: Transfer Records All Changes
- **Action**: POST `/{id}/transfer` with `new_department_id` and `new_manager_id`
- **Expected**: Department updated, manager ID in event description

### TC-08: Transfer Rejects No Changes
- **Action**: POST `/{id}/transfer` with all transfer fields null
- **Expected**: 400 error

### TC-09: Confirm Sets Status to Active
- **Precondition**: Employee status = "inactive"
- **Action**: POST `/{id}/confirm`
- **Expected**: Employee status = "active", event logged

### TC-10: Confirm Rejects Terminated Employee
- **Precondition**: Employee status = "terminated"
- **Action**: POST `/{id}/confirm`
- **Expected**: 400 error

### TC-11: Resign Rejects Already Resigned
- **Precondition**: Employee status = "resigned"
- **Action**: POST `/{id}/resign`
- **Expected**: 400 error

### TC-12: Terminate Rejects Already Terminated
- **Precondition**: Employee status = "terminated"
- **Action**: POST `/{id}/terminate`
- **Expected**: 400 error

### TC-13: Reactivate Rejects Already Active
- **Precondition**: Employee status = "active"
- **Action**: POST `/{id}/reactivate`
- **Expected**: 400 error

### TC-14: Permission Check on Mutation Endpoints
- **Precondition**: User with only `employee.read` permission
- **Action**: POST `/{id}/salary-revision`
- **Expected**: 403 error "Not enough permissions"

### TC-15: Tenant Isolation
- **Precondition**: Employee belongs to tenant A, user belongs to tenant B
- **Action**: Any lifecycle operation
- **Expected**: 404 error "Employee not found"

### TC-16: Timeline Reflects All Events
- **Action**: Perform promote, then salary revision, then transfer
- **Expected**: GET `/{id}/timeline` returns all 3 events in reverse chronological order

---

## Known Remaining Gaps

1. **Manager field**: The `Employee` model has no `manager_id`/`reporting_to` column. Transfer records the intended manager in the event description but cannot persist it on the employee record. Requires a schema migration.
2. **Salary component calculation**: When revising salary, other components (HRA, DA, etc.) are carried forward from the previous structure unchanged. A future enhancement should calculate these based on the new basic salary.
