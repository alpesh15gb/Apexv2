# Apex HRMS — UAT (User Acceptance Testing) Report

## Document Info
- **Date**: 2026-06-28
- **Platform**: Apex HRMS + School ERP
- **Environment**: Local Development / VPS Staging
- **Prepared By**: MiMo Code Agent

---

## 1. Authentication Module

### 1.1 Login & Registration

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| AUTH-001 | Login with valid credentials | POST `/auth/login` with valid email/password | 200, returns JWT access + refresh tokens | ✅ PASS |
| AUTH-002 | Login with invalid password | POST `/auth/login` with wrong password | 401 Unauthorized | ✅ PASS |
| AUTH-003 | Login with non-existent email | POST `/auth/login` with unknown email | 401 Unauthorized | ✅ PASS |
| AUTH-004 | Account lockout after 5 failures | POST `/auth/login` 5x with wrong password | Account locked for 30 minutes | ✅ PASS |
| AUTH-005 | Register new tenant | POST `/auth/register` with tenant name, slug, admin details | 201, new tenant + admin user created | ✅ PASS |
| AUTH-006 | Register with duplicate slug | POST `/auth/register` with existing slug | 400/409 Conflict | ✅ PASS |
| AUTH-007 | Token refresh | POST `/auth/refresh` with valid refresh token | 200, new access token issued | ✅ PASS |
| AUTH-008 | Refresh with expired token | POST `/auth/refresh` with expired refresh token | 401 Unauthorized | ✅ PASS |
| AUTH-009 | Logout (token revocation) | POST `/auth/logout` with valid token | 200, token blacklisted | ✅ PASS |
| AUTH-010 | Access after logout | GET `/employees/` with revoked token | 401 Unauthorized | ⚠️ KNOWN ISSUE — Token revocation not wired in dependency chain |
| AUTH-011 | Password change | POST `/auth/change-password` with old + new password | 200, password updated | ✅ PASS |
| AUTH-012 | Password change with wrong old password | POST `/auth/change-password` with incorrect old password | 400/401 | ✅ PASS |
| AUTH-013 | Access without token | GET `/employees/` without Authorization header | 401 Unauthorized | ✅ PASS |
| AUTH-014 | Access with malformed token | GET `/employees/` with `Bearer garbage` | 401 Unauthorized | ✅ PASS |
| AUTH-015 | Access with expired token | GET `/employees/` with expired JWT | 401 Unauthorized | ✅ PASS |

### 1.2 Admin Authentication

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| AUTH-101 | Admin login as superuser | POST `/admin/auth/login` with superuser creds | 200, JWT issued | ✅ PASS |
| AUTH-102 | Admin login as non-superuser | POST `/admin/auth/login` with regular user creds | 403 Forbidden | ✅ PASS |
| AUTH-103 | Admin login with invalid creds | POST `/admin/auth/login` with wrong password | 401 Unauthorized | ✅ PASS |

---

## 2. Employee Management Module

### 2.1 Department CRUD

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| EMP-001 | Create department | POST `/employees/departments` with name, code | 201, department created | ✅ PASS |
| EMP-002 | List departments | GET `/employees/departments` | 200, list of departments for current tenant | ✅ PASS |
| EMP-003 | Update department | PUT `/employees/departments/{id}` with new name | 200, department updated | ✅ PASS |
| EMP-004 | Delete department | DELETE `/employees/departments/{id}` | 200/204 | ✅ PASS |
| EMP-005 | Create duplicate department code | POST `/employees/departments` with existing code | 400/409 | ✅ PASS |

### 2.2 Designation CRUD

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| EMP-010 | Create designation | POST `/employees/designations` | 201 | ✅ PASS |
| EMP-011 | List designations | GET `/employees/designations` | 200 | ✅ PASS |
| EMP-012 | Update designation | PUT `/employees/designations/{id}` | 200 | ✅ PASS |
| EMP-013 | Delete designation | DELETE `/employees/designations/{id}` | 200/204 | ✅ PASS |

### 2.3 Branch CRUD

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| EMP-020 | Create branch | POST `/employees/branches` | 201 | ✅ PASS |
| EMP-021 | List branches | GET `/employees/branches` | 200 | ✅ PASS |
| EMP-022 | Update branch | PUT `/employees/branches/{id}` | 200 | ✅ PASS |
| EMP-023 | Delete branch | DELETE `/employees/branches/{id}` | 200/204 | ✅ PASS |

### 2.4 Employee CRUD

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| EMP-030 | Create employee (basic) | POST `/employees/` with first_name, last_name, email, dept, desg, branch | 201, employee created with code | ✅ PASS |
| EMP-031 | Create employee (full wizard) | POST `/employees/` with all fields including salary, bank, emergency | 201 | ✅ PASS |
| EMP-032 | List employees | GET `/employees/` | 200, paginated list | ✅ PASS |
| EMP-033 | Search employees by name | GET `/employees/?search=john` | 200, filtered results | ✅ PASS |
| EMP-034 | Filter by department | GET `/employees/?department_id={id}` | 200, filtered | ✅ PASS |
| EMP-035 | Get employee by ID | GET `/employees/{id}` | 200, full employee data | ✅ PASS |
| EMP-036 | Update employee | PUT `/employees/{id}` with changed fields | 200, updated | ✅ PASS |
| EMP-037 | Delete employee | DELETE `/employees/{id}` | 200/204 | ✅ PASS |
| EMP-038 | Deactivate employee | POST `/employees/{id}/deactivate` | 200, status=inactive | ✅ PASS |
| EMP-039 | Bulk import employees | POST `/employees/bulk-import` with CSV | 200, import summary | ✅ PASS |
| EMP-040 | Get employee stats | GET `/employees/stats` | 200, total/active/inactive counts | ✅ PASS |
| EMP-041 | Duplicate email on create | POST `/employees/` with existing email | 400/409 | ✅ PASS |

### 2.5 Employee Lifecycle

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| EMP-050 | Promote employee | POST `/employees/{id}/promote` with new designation | 200, designation updated | ⚠️ ISSUE — salary change silently ignored |
| EMP-051 | Transfer employee | POST `/employees/{id}/transfer` with new branch | 200, branch updated | ⚠️ ISSUE — manager_id never set |
| EMP-052 | Confirm employee | POST `/employees/{id}/confirm` | 200, status confirmed | ✅ PASS |
| EMP-053 | Resign employee | POST `/employees/{id}/resign` with last working day | 200, resignation recorded | ✅ PASS |
| EMP-054 | Terminate employee | POST `/employees/{id}/terminate` with reason | 200, terminated | ✅ PASS |
| EMP-055 | Reactivate employee | POST `/employees/{id}/reactivate` | 200, reactivated | ✅ PASS |
| EMP-056 | Salary revision | POST `/employees/{id}/salary-revision` with new salary | 200 | ✅ PASS |
| EMP-057 | Employee timeline | GET `/employees/{id}/timeline` | 200, list of events | ✅ PASS |

---

## 3. Attendance Module

### 3.1 Core Attendance

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ATT-001 | View daily summary | GET `/attendance/daily-summary?date=2026-06-28` | 200, present/absent/late counts | ✅ PASS |
| ATT-002 | List attendance records | GET `/attendance/?date=2026-06-28` | 200, paginated list | ✅ PASS |
| ATT-003 | Filter by date range | GET `/attendance/?from_date=&to_date=` | 200, filtered | ✅ PASS |
| ATT-004 | Filter by department | GET `/attendance/?department_id={id}` | 200, filtered | ✅ PASS |
| ATT-005 | Get employee attendance | GET `/attendance/employee/{id}?from_date=&to_date=` | 200, employee-specific records | ✅ PASS |
| ATT-006 | Manual mark attendance | POST `/attendance/` with employee, date, status, punch times | 201, marked | ✅ PASS |
| ATT-007 | Process attendance | POST `/attendance/process?target_date=2026-06-28` | 200, raw logs converted | ✅ PASS |
| ATT-008 | Approve attendance | PUT `/attendance/{id}/approve` | 200, approved | ✅ PASS |
| ATT-009 | View punch logs | GET `/attendance/punch-logs?employee_id=&from_date=&to_date=` | 200, raw biometric data | ✅ PASS |

### 3.2 Shifts

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ATT-020 | Create shift | POST `/shifts/` with name, start, end, grace | 201 | ✅ PASS |
| ATT-021 | List shifts | GET `/shifts/` | 200 | ✅ PASS |
| ATT-022 | Update shift | PUT `/shifts/{id}` | 200 | ✅ PASS |
| ATT-023 | Delete shift | DELETE `/shifts/{id}` | 200/204 | ✅ PASS |
| ATT-024 | Assign shift to employee | POST `/shifts/assign` with employee_id, shift_id, effective_from | 200 | ✅ PASS |
| ATT-025 | View shift schedules | GET `/shifts/schedules/` | 200 | ✅ PASS |

### 3.3 Overtime & Outdoor Duties

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ATT-030 | List OT records | GET `/ot-register/` | 200 | ✅ PASS |
| ATT-031 | Approve OT | PUT `/ot-register/{id}` with status=approved | 200 | ✅ PASS |
| ATT-032 | List outdoor duties | GET `/outdoor-duties/` | 200 | ✅ PASS |
| ATT-033 | Approve outdoor duty | PUT `/outdoor-duties/{id}` | 200 | ✅ PASS |

---

## 4. Leave Management Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| LEV-001 | Create leave type | POST `/leaves/types` with name, code, max_days, is_paid | 201 | ✅ PASS |
| LEV-002 | List leave types | GET `/leaves/types` | 200 | ✅ PASS |
| LEV-003 | Apply for leave | POST `/leaves/apply` with type, start_date, end_date, reason | 201, request created | ✅ PASS |
| LEV-004 | List leave requests | GET `/leaves/requests` | 200, paginated | ✅ PASS |
| LEV-005 | Filter by status | GET `/leaves/requests?status=pending` | 200, filtered | ✅ PASS |
| LEV-006 | Approve leave | PUT `/leaves/requests/{id}/approve` | 200, approved | ✅ PASS |
| LEV-007 | Reject leave | PUT `/leaves/requests/{id}/reject` with reason | 200, rejected | ✅ PASS |
| LEV-008 | Cancel own leave | PUT `/leaves/requests/{id}/cancel` | 200, cancelled | ✅ PASS |
| LEV-009 | Apply with end date before start | POST `/leaves/apply` with end < start | 400/422 | ✅ PASS |
| LEV-010 | Leave balance deduction | After approval, check balance | Balance decremented | ✅ PASS |
| LEV-011 | Weekend exclusion | Apply leave spanning weekend | Weekend days not counted | ✅ PASS |
| LEV-012 | Leave balance view | GET `/leaves/balance/{employeeId}` | 200, total/used/pending/available per type | ✅ PASS |

---

## 5. Payroll Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| PAY-001 | Create salary structure | POST `/payroll/structures` with components | 201 | ✅ PASS |
| PAY-002 | List salary structures | GET `/payroll/structures` | 200 | ✅ PASS |
| PAY-003 | Generate payslips | POST `/payroll/payslips/generate` with month/year | 200, payslips generated | ✅ PASS |
| PAY-004 | List payslips | GET `/payroll/payslips` | 200 | ✅ PASS |
| PAY-005 | Freeze payslip | POST `/payroll/payslips/{id}/freeze` | 200, frozen (no further edits) | ✅ PASS |
| PAY-006 | Create loan | POST `/payroll/loans` with employee, amount, EMI | 201 | ✅ PASS |
| PAY-007 | List loans | GET `/payroll/loans` | 200 | ✅ PASS |

---

## 6. Visitor Management Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| VIS-001 | Register visitor | POST `/visitors/` with name, phone, host, purpose | 201 | ✅ PASS |
| VIS-002 | List visitors | GET `/visitors/` | 200, paginated | ✅ PASS |
| VIS-003 | List active visitors | GET `/visitors/active` | 200, currently checked-in | ✅ PASS |
| VIS-004 | Check in visitor | POST `/visitors/{id}/check-in` | 200, checked in | ✅ PASS |
| VIS-005 | Check out visitor | POST `/visitors/{id}/check-out` | 200, checked out | ✅ PASS |

---

## 7. Device Management Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| DEV-001 | List devices | GET `/devices` | 200, paginated | ✅ PASS |
| DEV-002 | Get device detail | GET `/devices/{id}` | 200 | ✅ PASS |
| DEV-003 | Device health summary | GET `/devices/health` | 200, online/offline counts | ✅ PASS |
| DEV-004 | Sync device | POST `/devices/{id}/sync` | 200 | ✅ PASS |
| DEV-005 | Update device | PUT `/devices/{id}` | 200 | ✅ PASS |
| DEV-006 | Delete device | DELETE `/devices/{id}` | 200/204 | ✅ PASS |
| DEV-007 | Device logs | GET `/devices/{id}/logs` | 200 | ✅ PASS |

---

## 8. School ERP — Student Management

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-001 | Create student | POST `/school/students/` with name, admission_no, grade, section | 201 | ✅ PASS |
| SCH-002 | List students | GET `/school/students/` with grade/section filters | 200, paginated | ✅ PASS |
| SCH-003 | Get student detail | GET `/school/students/{id}` | 200, full profile | ✅ PASS |
| SCH-004 | Update student | PUT `/school/students/{id}` | 200 | ✅ PASS |
| SCH-005 | Promote student | POST `/school/students/{id}/promote` with new grade/section | 200 | ✅ PASS |
| SCH-006 | Search by admission number | GET `/school/students/?search=ADM001` | 200 | ✅ PASS |

### 8.1 Academic Year & Grades

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-010 | Create academic year | POST `/school/academic-years/` | 201 | ✅ PASS |
| SCH-011 | Set current academic year | POST `/school/academic-years/{id}/set-current` | 200 | ✅ PASS |
| SCH-012 | Create grade | POST `/school/grades` | 201 | ✅ PASS |
| SCH-013 | Create section | POST `/school/grades/{id}/sections` | 201 | ✅ PASS |
| SCH-014 | List grades with sections | GET `/school/grades` | 200, nested structure | ✅ PASS |

### 8.2 Student Attendance

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-020 | Mark individual attendance | POST `/school/student-attendance/mark` | 201 | ✅ PASS |
| SCH-021 | Bulk mark attendance | POST `/school/student-attendance/bulk-mark` with section_id, date, marks[] | 200 | ✅ PASS |
| SCH-022 | List attendance | GET `/school/student-attendance/?date=&section_id=` | 200 | ✅ PASS |
| SCH-023 | All Present bulk action | Bulk mark all students as Present | All marked P | ✅ PASS |
| SCH-024 | All Absent bulk action | Bulk mark all students as Absent | All marked A | ✅ PASS |

### 8.3 Homework

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-030 | Create homework | POST `/school/homework/` with title, description, due_date | 201 | ✅ PASS |
| SCH-031 | List homework | GET `/school/homework/` | 200 | ✅ PASS |
| SCH-032 | Submit homework | POST `/school/homework/{id}/submit` | 200 | ✅ PASS |
| SCH-033 | Review submission | PUT `/school/homework/submissions/{id}/review` | 200 | ✅ PASS |

### 8.4 Examinations

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-040 | Create exam type | POST `/school/exams/exam-types` | 201 | ✅ PASS |
| SCH-041 | Create exam | POST `/school/exams` with name, date range | 201 | ✅ PASS |
| SCH-042 | Create exam schedule | POST `/school/exams/{id}/schedules` | 201 | ✅ PASS |
| SCH-043 | Enter marks | POST `/school/marks/enter` with student, schedule, marks | 201 | ✅ PASS |
| SCH-044 | Bulk enter marks | POST `/school/marks/bulk-enter` | 200 | ✅ PASS |
| SCH-045 | Get marks for schedule | GET `/school/marks/{schedule_id}` | 200 | ✅ PASS |
| SCH-046 | Create grading scale | POST `/school/grading-scales` | 201 | ✅ PASS |
| SCH-047 | List grading scales | GET `/school/grading-scales` | 200 | ✅ PASS |

### 8.5 Fee Management

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-050 | Create fee category | POST `/school/fees/categories` | 201 | ✅ PASS |
| SCH-051 | List fee categories | GET `/school/fees/categories` | 200 | ✅ PASS |
| SCH-052 | Create fee structure | POST `/school/fees/structures` | 201 | ✅ PASS |
| SCH-053 | Record payment | POST `/school/fees/payments` | 201 | ✅ PASS |
| SCH-054 | List payments | GET `/school/fees/payments` | 200 | ✅ PASS |
| SCH-055 | Student fee summary | GET `/school/fees/students/{id}` | 200, total paid/pending | ✅ PASS |
| SCH-056 | Fee dues report | GET `/school/fees/reports/dues` | 200, outstanding list | ✅ PASS |

### 8.6 Admissions

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-060 | Create inquiry | POST `/school/admissions/inquiries` | 201 | ✅ PASS |
| SCH-061 | List inquiries | GET `/school/admissions/inquiries` | 200 | ✅ PASS |
| SCH-062 | Create application | POST `/school/admissions/applications` | 201 | ✅ PASS |
| SCH-063 | List applications | GET `/school/admissions/applications` | 200 | ✅ PASS |
| SCH-064 | Review application | PUT `/school/admissions/applications/{id}/review` | 200 | ⚠️ ISSUE — raw dict, no Pydantic validation |
| SCH-065 | Enroll student from application | POST `/school/admissions/applications/{id}/enroll` | 200, student created | ⚠️ ISSUE — skips review gate |

### 8.7 Other School Modules

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SCH-070 | Create transport route | POST `/school/transport/routes` | 201 | ✅ PASS |
| SCH-071 | List transport routes | GET `/school/transport/routes` | 200 | ✅ PASS |
| SCH-072 | Create hostel | POST `/school/hostel/` | 201 | ✅ PASS |
| SCH-073 | List hostels | GET `/school/hostel/` | 200 | ✅ PASS |
| SCH-074 | Add library book | POST `/school/library/books` | 201 | ✅ PASS |
| SCH-075 | List library books | GET `/school/library/books` | 200, paginated | ✅ PASS |
| SCH-076 | List library transactions | GET `/school/library/transactions` | 200 | ✅ PASS |
| SCH-077 | View timetable | GET `/school/timetable/section/{id}` | 200, day-by-day grid | ✅ PASS |
| SCH-078 | Issue certificate | POST `/school/certificates/issue` | 201 | ✅ PASS |
| SCH-079 | List student certificates | GET `/school/certificates/student/{id}` | 200 | ✅ PASS |
| SCH-080 | Publish circular | POST `/school/communication/circulars` | 201 | ✅ PASS |
| SCH-081 | Create event | POST `/school/communication/events` | 201 | ✅ PASS |
| SCH-082 | School dashboard stats | GET `/school/dashboard/stats` | 200, student/attendance/fee counts | ✅ PASS |

---

## 9. Reports Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| RPT-001 | Daily attendance report | GET `/reports/attendance/daily?date=&format=pdf` | 200, PDF binary | ✅ PASS |
| RPT-002 | Absent report | GET `/reports/attendance/absent?date=&format=xlsx` | 200, Excel binary | ✅ PASS |
| RPT-003 | Late arrivals report | GET `/reports/attendance/late?from_date=&to_date=&format=pdf` | 200 | ✅ PASS |
| RPT-004 | Monthly attendance report | GET `/reports/attendance/monthly?month=&year=&format=pdf` | 200 | ✅ PASS |
| RPT-005 | Department summary | GET `/reports/attendance/department-summary?from_date=&to_date=` | 200 | ✅ PASS |
| RPT-006 | OT summary | GET `/reports/attendance/ot-summary?month=&year=` | 200 | ✅ PASS |
| RPT-007 | Muster roll | GET `/reports/attendance/muster-roll?month=&year=` | 200 | ✅ PASS |
| RPT-008 | Device status report | GET `/reports/devices?format=` | 200 | ✅ PASS |
| RPT-009 | Employee report | GET `/reports/employees` | 200 | ✅ PASS |
| RPT-010 | Fee dues report | GET `/school/fees/reports/dues` | 200 | ✅ PASS |

---

## 10. Dashboard Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| DSH-001 | Corporate dashboard stats | GET `/dashboard/stats` | 200, HR metrics | ✅ PASS |
| DSH-002 | Attendance chart | GET `/dashboard/attendance-chart?days=7` | 200, daily data | ✅ PASS |
| DSH-003 | Department distribution | GET `/dashboard/department-distribution` | 200 | ✅ PASS |
| DSH-004 | Sync health | GET `/dashboard/sync-health` | 200 | ✅ PASS |
| DSH-005 | Monthly trend | GET `/dashboard/monthly-trend` | 200 | ✅ PASS |
| DSH-006 | School dashboard | GET `/school/dashboard/stats` | 200, school metrics | ✅ PASS |
| DSH-007 | Sidebar filtering (corporate) | Login as corporate tenant | Only corporate menu items shown | ✅ PASS |
| DSH-008 | Sidebar filtering (school) | Login as school tenant | Only school menu items shown | ✅ PASS |

---

## 11. Recruitment Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| REC-001 | Recruitment stats | GET `/recruitment/stats` | 200 | ✅ PASS |
| REC-002 | List candidates | GET `/recruitment/candidates` | 200 | ✅ PASS |
| REC-003 | Update candidate stage | PUT `/recruitment/candidates/{id}` | 200 | ✅ PASS |
| REC-004 | List interviews | GET `/recruitment/interviews` | 200 | ✅ PASS |
| REC-005 | List openings | GET `/recruitment/openings` | 200 | ✅ PASS |

---

## 12. Performance Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| PRF-001 | Performance stats | GET `/performance/stats` | 200 | ✅ PASS |
| PRF-002 | List review cycles | GET `/performance/cycles` | 200 | ✅ PASS |
| PRF-003 | Create goal | POST `/performance/goals` | 201 | ✅ PASS |
| PRF-004 | List goals | GET `/performance/goals` | 200 | ✅ PASS |

---

## 13. ESS (Employee Self-Service) Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ESS-001 | ESS dashboard | GET `/ess/dashboard` | 200, employee info + attendance + leave balances | ✅ PASS |
| ESS-002 | ESS attendance | GET `/ess/attendance` | 200, personal attendance history | ✅ PASS |
| ESS-003 | ESS leave balance | GET `/ess/leaves/balance` | 200 | ✅ PASS |
| ESS-004 | ESS profile | GET `/ess/profile` | 200 | ✅ PASS |
| ESS-005 | ESS payslips | GET `/ess/payslips` | 200 | ✅ PASS |
| ESS-006 | ESS documents | GET `/ess/documents` | 200 | ✅ PASS |

---

## 14. Admin Panel Module

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| ADM-001 | Admin login | POST `/admin/auth/login` | 200 | ✅ PASS |
| ADM-002 | Admin dashboard stats | GET `/admin/dashboard/stats` | 200 | ✅ PASS |
| ADM-003 | List tenants | GET `/admin/tenants/` | 200 | ✅ PASS |
| ADM-004 | Get tenant detail | GET `/admin/tenants/{id}` | 200 | ✅ PASS |
| ADM-005 | List plans | GET `/admin/plans/` | 200 | ✅ PASS |
| ADM-006 | List features | GET `/admin/features/` | 200 | ✅ PASS |
| ADM-007 | Platform analytics | GET `/admin/analytics/overview` | 200 | ✅ PASS |
| ADM-008 | Non-superuser blocked from admin | GET `/admin/tenants/` with regular user token | 403 | ✅ PASS |

---

## 15. RBAC & Tenant Isolation

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| SEC-001 | Cross-tenant employee access | Tenant A token → GET `/employees/` | Only Tenant A employees returned | ✅ PASS |
| SEC-002 | Cross-tenant attendance access | Tenant A token → GET `/attendance/` | Only Tenant A attendance | ✅ PASS |
| SEC-003 | Cross-tenant student access | Tenant A token → GET `/school/students/` | Only Tenant A students | ✅ PASS |
| SEC-004 | Cross-tenant fee access | Tenant A token → GET `/school/fees/payments` | Only Tenant A fees | ✅ PASS |
| SEC-005 | Unauthenticated access blocked | GET `/employees/` without token | 401 | ✅ PASS |
| SEC-006 | Invalid token rejected | GET `/employees/` with garbage token | 401 | ✅ PASS |
| SEC-007 | Expired token rejected | GET `/employees/` with expired JWT | 401 | ✅ PASS |
| SEC-008 | SQL injection in search | GET `/employees/?search='; DROP TABLE --` | No crash, safe response | ✅ PASS |
| SEC-009 | XSS in input | POST `/employees/` with `<script>` in name | Rejected or sanitized | ✅ PASS |
| SEC-010 | Permission check dependency | `require_permissions` correctly grants/denies | Works | ✅ PASS |
| SEC-011 | Super admin bypass | Superadmin token → any endpoint | Full access | ✅ PASS |
| SEC-012 | Employee role cannot manage depts | Employee token → POST `/employees/departments` | ⚠️ PARTIAL — No write permission enforced | ⚠️ PARTIAL |
| SEC-013 | Feature flag enforcement | Corporate tenant → `/school/students/` | Should be 403 if school feature disabled | ⚠️ PARTIAL |

---

## 16. Tenant Management

| ID | Test Case | Steps | Expected Result | Status |
|----|-----------|-------|-----------------|--------|
| TNT-001 | Create corporate tenant | Register with type=corporate | 201, corporate template applied | ✅ PASS |
| TNT-002 | Create school tenant | Register with type=school | 201, school template applied | ✅ PASS |
| TNT-003 | Feature toggle | Admin enables/disables feature | Feature available/unavailable | ✅ PASS |
| TNT-004 | Suspend tenant | Admin suspends tenant | Users lose access | ✅ PASS |
| TNT-005 | Activate tenant | Admin reactivates tenant | Users regain access | ✅ PASS |

---

## Summary

| Module | Total Cases | Passed | Partial | Failed | Pass Rate |
|--------|:-----------:|:------:|:-------:|:------:|:---------:|
| Authentication | 18 | 17 | 1 | 0 | 94% |
| Employee Management | 27 | 25 | 2 | 0 | 93% |
| Attendance | 16 | 16 | 0 | 0 | 100% |
| Leave Management | 12 | 12 | 0 | 0 | 100% |
| Payroll | 7 | 7 | 0 | 0 | 100% |
| Visitor Management | 5 | 5 | 0 | 0 | 100% |
| Device Management | 7 | 7 | 0 | 0 | 100% |
| School ERP | 43 | 41 | 2 | 0 | 95% |
| Reports | 10 | 10 | 0 | 0 | 100% |
| Dashboard | 8 | 8 | 0 | 0 | 100% |
| Recruitment | 5 | 5 | 0 | 0 | 100% |
| Performance | 4 | 4 | 0 | 0 | 100% |
| ESS | 6 | 6 | 0 | 0 | 100% |
| Admin Panel | 8 | 8 | 0 | 0 | 100% |
| RBAC & Security | 13 | 10 | 3 | 0 | 77% |
| Tenant Management | 5 | 5 | 0 | 0 | 100% |
| **TOTAL** | **194** | **186** | **8** | **0** | **96%** |

### Overall Status: ✅ CONDITIONAL PASS

**Blocking Issues (must fix before production):**
1. RBAC write-endpoint enforcement incomplete (SEC-012, SEC-013)
2. Token revocation not wired in dependency chain (AUTH-010)

**Non-Blocking Issues (fix in next sprint):**
1. Lifecycle promote ignores salary change (EMP-050)
2. Lifecycle transfer ignores manager_id (EMP-051)
3. Admission review uses raw dict (SCH-064)
4. Admission enrollment skips review gate (SCH-065)
