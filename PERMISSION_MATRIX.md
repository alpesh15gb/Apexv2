# Apex HRMS — Permission Matrix

## Permission Codenames

### System
| Codename | Description |
|----------|-------------|
| `super_admin` | Full system access (wildcard `*`) |

### Employee
| Codename | Description |
|----------|-------------|
| `employee.create` | Create employees |
| `employee.read` | Read employee list and details |
| `employee.update` | Update employee records |
| `employee.delete` | Delete/deactivate employees |

### Attendance
| Codename | Description |
|----------|-------------|
| `attendance.manage` | Configure attendance settings |
| `attendance.read` | Read all attendance records |
| `attendance.approve` | Approve attendance |
| `attendance.read_own` | Read own attendance only |

### Leave
| Codename | Description |
|----------|-------------|
| `leave.approve` | Approve/reject leave requests |
| `leave.read` | Read all leave records |
| `leave.apply` | Apply for leave |
| `leave.read_own` | Read own leave only |

### Shift
| Codename | Description |
|----------|-------------|
| `shift.manage` | Create/edit shifts and assignments |
| `shift.read` | Read shift schedules |

### Visitor
| Codename | Description |
|----------|-------------|
| `visitor.manage` | Full visitor management |
| `visitor.read` | Read visitor logs |
| `visitor.create` | Register visitors |

### Reports
| Codename | Description |
|----------|-------------|
| `report.read` | View reports |

### Payroll
| Codename | Description |
|----------|-------------|
| `payroll.manage` | Configure salary structures |
| `payroll.process` | Process payroll and generate payslips |
| `payroll.read` | Read payroll data |
| `payroll.read_own` | Read own payslips only |

### Finance
| Codename | Description |
|----------|-------------|
| `expense.manage` | Manage expense categories and claims |
| `expense.read` | Read expense data |

### Documents
| Codename | Description |
|----------|-------------|
| `document.manage` | Upload and manage documents |
| `document.read` | Read documents |

### Recruitment
| Codename | Description |
|----------|-------------|
| `recruitment.manage` | Full recruitment management |
| `recruitment.read` | Read recruitment data |

### Performance
| Codename | Description |
|----------|-------------|
| `performance.manage` | Manage review cycles and goals |
| `performance.read` | Read performance data |

### School — Students
| Codename | Description |
|----------|-------------|
| `student.create` | Enroll students |
| `student.read` | Read student list and details |
| `student.update` | Update student records |
| `student.delete` | Remove students |

### School — Attendance
| Codename | Description |
|----------|-------------|
| `student_attendance.mark` | Mark student attendance |
| `student_attendance.read` | Read student attendance |

### School — Academics
| Codename | Description |
|----------|-------------|
| `homework.create` | Create homework |
| `homework.read` | Read homework |
| `exam.manage` | Manage exams and schedules |
| `exam.read` | Read exam data |
| `marks.enter` | Enter exam marks |
| `marks.read` | Read marks |

### School — Finance
| Codename | Description |
|----------|-------------|
| `fee.manage` | Configure fee structures |
| `fee.collect` | Collect fee payments |
| `fee.read` | Read fee data |

### School — Operations
| Codename | Description |
|----------|-------------|
| `transport.manage` | Manage transport routes |
| `hostel.manage` | Manage hostel operations |
| `library.manage` | Manage library |

### School — Communication
| Codename | Description |
|----------|-------------|
| `circular.publish` | Publish circulars |
| `event.manage` | Manage events |

### School — Welfare
| Codename | Description |
|----------|-------------|
| `medical.manage` | Manage health records |
| `discipline.manage` | Manage discipline incidents |

### School — Administration
| Codename | Description |
|----------|-------------|
| `admission.manage` | Manage admissions |
| `certificate.issue` | Issue certificates |
| `school.settings` | Configure school settings |

---

## Role → Permission Mapping

### Corporate Roles

| Permission | Super Admin | HR Admin | Manager | Employee |
|------------|:-----------:|:--------:|:-------:|:--------:|
| employee.create | ✓ | ✓ | - | - |
| employee.read | ✓ | ✓ | ✓ | - |
| employee.update | ✓ | ✓ | - | - |
| employee.delete | ✓ | - | - | - |
| attendance.manage | ✓ | ✓ | - | - |
| attendance.read | ✓ | ✓ | ✓ | - |
| attendance.approve | ✓ | - | ✓ | - |
| attendance.read_own | ✓ | ✓ | ✓ | ✓ |
| leave.approve | ✓ | ✓ | ✓ | - |
| leave.read | ✓ | ✓ | ✓ | - |
| leave.apply | ✓ | ✓ | ✓ | ✓ |
| leave.read_own | ✓ | ✓ | ✓ | ✓ |
| shift.manage | ✓ | ✓ | - | - |
| shift.read | ✓ | ✓ | ✓ | - |
| report.read | ✓ | ✓ | ✓ | - |
| visitor.manage | ✓ | ✓ | - | - |
| visitor.read | ✓ | ✓ | ✓ | - |
| visitor.create | ✓ | ✓ | ✓ | ✓ |
| payroll.manage | ✓ | ✓ | - | - |
| payroll.process | ✓ | ✓ | - | - |
| payroll.read | ✓ | ✓ | - | - |
| payroll.read_own | ✓ | ✓ | ✓ | ✓ |
| expense.manage | ✓ | ✓ | - | - |
| expense.read | ✓ | ✓ | ✓ | - |
| document.manage | ✓ | ✓ | - | - |
| document.read | ✓ | ✓ | ✓ | ✓ |
| recruitment.manage | ✓ | ✓ | - | - |
| recruitment.read | ✓ | ✓ | ✓ | - |
| performance.manage | ✓ | ✓ | - | - |
| performance.read | ✓ | ✓ | ✓ | ✓ |

### School Roles

| Permission | Principal | VP | Coordinator | Teacher | Class Teacher | Accountant | Librarian | Transport | Hostel | Parent | Student |
|------------|:---------:|:--:|:-----------:|:-------:|:-------------:|:----------:|:---------:|:---------:|:------:|:------:|:-------:|
| student.create | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| student.read | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | own | own |
| student.update | ✓ | ✓ | ✓ | - | partial | - | - | - | - | - | - |
| student.delete | ✓ | - | - | - | - | - | - | - | - | - | - |
| student_attendance.mark | ✓ | - | - | ✓ | ✓ | - | - | - | - | - | - |
| student_attendance.read | ✓ | ✓ | ✓ | own | own | - | - | - | - | own | own |
| homework.create | ✓ | - | - | ✓ | ✓ | - | - | - | - | - | - |
| homework.read | ✓ | ✓ | ✓ | own | own | - | - | - | - | own | own |
| exam.manage | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| exam.read | ✓ | ✓ | ✓ | own | own | - | - | - | - | own | own |
| marks.enter | ✓ | - | - | own | own | - | - | - | - | - | - |
| marks.read | ✓ | ✓ | ✓ | own | own | - | - | - | - | own | own |
| fee.manage | ✓ | - | - | - | - | ✓ | - | - | - | - | - |
| fee.collect | ✓ | - | - | - | - | ✓ | - | - | - | - | - |
| fee.read | ✓ | ✓ | - | - | - | ✓ | - | - | - | own | own |
| transport.manage | ✓ | - | - | - | - | - | - | ✓ | - | - | - |
| hostel.manage | ✓ | - | - | - | - | - | - | - | ✓ | - | - |
| library.manage | ✓ | - | - | - | - | - | ✓ | - | - | - | - |
| circular.publish | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| event.manage | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| medical.manage | ✓ | - | - | - | ✓ | - | - | - | - | - | - |
| discipline.manage | ✓ | ✓ | - | - | ✓ | - | - | - | - | - | - |
| admission.manage | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| certificate.issue | ✓ | - | - | - | - | ✓ | - | - | - | - | - |
| school.settings | ✓ | - | - | - | - | - | - | - | - | - | - |

---

## Endpoint → Permission Mapping

### Auth (Public — no permission needed)
| Method | Path | Permission |
|--------|------|------------|
| POST | `/auth/login` | Public |
| POST | `/auth/register` | Public |
| POST | `/auth/refresh` | Public |
| POST | `/auth/logout` | Public |

### Employees
| Method | Path | Permission |
|--------|------|------------|
| GET | `/employees/departments` | `employee.read` |
| POST | `/employees/departments` | `employee.create` |
| PUT | `/employees/departments/{id}` | `employee.update` |
| GET | `/employees/designations` | `employee.read` |
| POST | `/employees/designations` | `employee.create` |
| GET | `/employees/branches` | `employee.read` |
| POST | `/employees/branches` | `employee.create` |
| GET | `/employees/` | `employee.read` |
| POST | `/employees/` | `employee.create` |
| GET | `/employees/{id}` | `employee.read` |
| PUT | `/employees/{id}` | `employee.update` |
| DELETE | `/employees/{id}` | `employee.delete` |
| GET | `/employees/stats` | `employee.read` |

### Attendance
| Method | Path | Permission |
|--------|------|------------|
| GET | `/attendance/` | `attendance.read` |
| POST | `/attendance/` | `attendance.manage` |
| PUT | `/attendance/{id}` | `attendance.manage` |
| GET | `/attendance/punch-logs` | `attendance.read` |
| GET | `/attendance/daily-summary` | `attendance.read` |
| POST | `/attendance/recalculate` | `attendance.manage` |

### Shifts
| Method | Path | Permission |
|--------|------|------------|
| GET | `/shifts/` | `shift.read` |
| POST | `/shifts/` | `shift.manage` |
| PUT | `/shifts/{id}` | `shift.manage` |
| POST | `/shifts/assign` | `shift.manage` |

### Leaves
| Method | Path | Permission |
|--------|------|------------|
| GET | `/leaves/types` | `leave.read` |
| POST | `/leaves/types` | `leave.approve` |
| GET | `/leaves/requests` | `leave.read` |
| POST | `/leaves/apply` | `leave.apply` |
| PUT | `/leaves/requests/{id}/approve` | `leave.approve` |
| PUT | `/leaves/requests/{id}/reject` | `leave.approve` |

### Visitors
| Method | Path | Permission |
|--------|------|------------|
| GET | `/visitors/` | `visitor.read` |
| POST | `/visitors/` | `visitor.create` |
| GET | `/visitors/active` | `visitor.read` |
| POST | `/visitors/{id}/check-in` | `visitor.manage` |
| POST | `/visitors/{id}/check-out` | `visitor.manage` |

### Payroll
| Method | Path | Permission |
|--------|------|------------|
| GET | `/payroll/structures` | `payroll.read` |
| POST | `/payroll/structures` | `payroll.manage` |
| GET | `/payroll/payslips` | `payroll.read` |
| POST | `/payroll/payslips/generate` | `payroll.process` |
| POST | `/payroll/payslips/{id}/freeze` | `payroll.process` |
| GET | `/payroll/loans` | `payroll.read` |
| POST | `/payroll/loans` | `payroll.manage` |

### School — Students
| Method | Path | Permission |
|--------|------|------------|
| GET | `/school/students/` | `student.read` |
| POST | `/school/students/` | `student.create` |
| GET | `/school/students/{id}` | `student.read` |
| PUT | `/school/students/{id}` | `student.update` |
| POST | `/school/students/{id}/promote` | `student.update` |

### School — Attendance
| Method | Path | Permission |
|--------|------|------------|
| POST | `/school/student-attendance/mark` | `student_attendance.mark` |
| POST | `/school/student-attendance/bulk-mark` | `student_attendance.mark` |
| GET | `/school/student-attendance/` | `student_attendance.read` |

### School — Homework
| Method | Path | Permission |
|--------|------|------------|
| GET | `/school/homework/` | `homework.read` |
| POST | `/school/homework/` | `homework.create` |
| POST | `/school/homework/{id}/submit` | `homework.read` |
| PUT | `/school/homework/submissions/{id}/review` | `homework.create` |

### School — Examinations
| Method | Path | Permission |
|--------|------|------------|
| GET | `/school/exams` | `exam.read` |
| POST | `/school/exams` | `exam.manage` |
| GET | `/school/exams/{id}/schedules` | `exam.read` |
| POST | `/school/exams/{id}/schedules` | `exam.manage` |
| POST | `/school/marks/enter` | `marks.enter` |
| POST | `/school/marks/bulk-enter` | `marks.enter` |
| GET | `/school/marks/{id}` | `marks.read` |

### School — Fees
| Method | Path | Permission |
|--------|------|------------|
| GET | `/school/fees/categories` | `fee.read` |
| POST | `/school/fees/categories` | `fee.manage` |
| GET | `/school/fees/structures` | `fee.read` |
| POST | `/school/fees/structures` | `fee.manage` |
| POST | `/school/fees/payments` | `fee.collect` |
| GET | `/school/fees/payments` | `fee.read` |

---

## Enforcement Status

| Module | Endpoints | Protected | Partial | Unprotected |
|--------|-----------|-----------|---------|-------------|
| Auth | 4 | 0 | 0 | 4 (intentional) |
| Employees | 14 | 0 | 14 | 0 |
| Attendance | 6 | 0 | 6 | 0 |
| Shifts | 4 | 0 | 4 | 0 |
| Leaves | 6 | 0 | 6 | 0 |
| Visitors | 5 | 0 | 5 | 0 |
| Payroll | 6 | 0 | 6 | 0 |
| Devices | 8 | 0 | 8 | 0 |
| Reports | 3 | 0 | 3 | 0 |
| Dashboard | 8 | 0 | 8 | 0 |
| School | 50+ | 0 | 50+ | 0 |
| **Total** | **~230** | **0** | **~225** | **5** |

**Status**: 0% of endpoints have proper RBAC enforcement. All need `require_permissions` added.

---

## Next Steps

1. Add `require_permissions` to all endpoints listed above
2. Create comprehensive permission codenames for all modules
3. Seed permissions during tenant creation
4. Add automated tests to verify enforcement
