# Apex HRMS — Role Permission Matrix

## Corporate Roles (All Tenant Types)

### Super Admin (`super_admin`)
| Permission | Description |
|-----------|-------------|
| `*` | Wildcard — all permissions |

### HR Admin (`hr_admin`)
| Permission | Description |
|-----------|-------------|
| `employee.create` | Create employees |
| `employee.read` | View employees |
| `employee.update` | Edit employees |
| `employee.delete` | Delete employees |
| `attendance.create` | Create attendance records |
| `attendance.read` | View attendance |
| `attendance.update` | Edit attendance |
| `attendance.delete` | Delete attendance records |
| `attendance.approve` | Approve attendance |
| `attendance.manage` | Manage attendance settings |
| `leave.create` | Create leave records |
| `leave.read` | View leave |
| `leave.update` | Edit leave |
| `leave.delete` | Delete leave records |
| `leave.approve` | Approve leave |
| `shift.create` | Create shifts |
| `shift.read` | View shifts |
| `shift.update` | Edit shifts |
| `shift.delete` | Delete shifts |
| `shift.manage` | Manage shift settings |
| `report.create` | Create reports |
| `report.read` | View reports |
| `report.update` | Edit reports |
| `report.delete` | Delete reports |
| `visitor.create` | Create visitor records |
| `visitor.read` | View visitors |
| `visitor.update` | Edit visitors |
| `visitor.delete` | Delete visitors |
| `visitor.manage` | Manage visitor settings |

### Manager (`manager`)
| Permission | Description |
|-----------|-------------|
| `employee.read` | View employees |
| `attendance.read` | View attendance |
| `attendance.approve` | Approve attendance |
| `leave.read` | View leave |
| `leave.approve` | Approve leave |
| `report.read` | View reports |
| `visitor.read` | View visitors |

### Employee (`employee`)
| Permission | Description |
|-----------|-------------|
| `attendance.read_own` | View own attendance |
| `leave.apply` | Apply for leave |
| `leave.read_own` | View own leave |
| `visitor.create` | Create visitor entry |
| `ess.read` | Employee self-service portal |

---

## School-Specific Roles

### Principal (`principal`)
All school permissions:

| Module | Permissions |
|--------|-------------|
| Student | `student.create`, `student.read`, `student.update`, `student.delete` |
| Attendance | `attendance.create`, `attendance.read`, `attendance.mark`, `attendance.update` |
| Exam | `exam.create`, `exam.read`, `exam.update`, `exam.manage` |
| Report | `report.create`, `report.read`, `report.update` |
| Class | `class.create`, `class.read`, `class.update`, `class.manage` |
| Subject | `subject.create`, `subject.read`, `subject.update`, `subject.manage` |
| Timetable | `timetable.create`, `timetable.read`, `timetable.update`, `timetable.manage` |
| Homework | `homework.create`, `homework.read`, `homework.update`, `homework.delete` |
| Marks | `marks.create`, `marks.read`, `marks.update`, `marks.enter` |
| Fee | `fee.create`, `fee.read`, `fee.update`, `fee.manage`, `fee.collect` |
| Payroll | `payroll.read` |
| Library | `library.create`, `library.read`, `library.update`, `library.manage` |
| Transport | `transport.create`, `transport.read`, `transport.update`, `transport.manage` |
| Hostel | `hostel.create`, `hostel.read`, `hostel.update`, `hostel.manage` |
| Visitor | `visitor.create`, `visitor.read` |
| ESS | `ess.read` |

### Vice Principal (`vice_principal`)
| Permission | Description |
|-----------|-------------|
| `student.read` | View students |
| `attendance.read` | View attendance |
| `exam.read` | View exams |
| `report.read` | View reports |

### Academic Coordinator (`academic_coordinator`)
| Permission | Description |
|-----------|-------------|
| `class.manage` | Manage classes |
| `subject.manage` | Manage subjects |
| `timetable.manage` | Manage timetable |

### Class Teacher (`class_teacher`)
| Permission | Description |
|-----------|-------------|
| `student.read` | View students |
| `attendance.mark` | Mark attendance |
| `attendance.read` | View attendance |
| `homework.create` | Create homework |
| `homework.read` | View homework |

### Subject Teacher (`subject_teacher`)
| Permission | Description |
|-----------|-------------|
| `homework.create` | Create homework |
| `homework.read` | View homework |
| `marks.enter` | Enter marks |
| `marks.read` | View marks |

### Accountant (`school_accountant`)
| Permission | Description |
|-----------|-------------|
| `fee.manage` | Manage fee structure |
| `fee.collect` | Collect fees |
| `fee.read` | View fee records |
| `payroll.read` | View payroll |

### Librarian (`librarian`)
| Permission | Description |
|-----------|-------------|
| `library.manage` | Manage library |

### Transport Manager (`transport_manager`)
| Permission | Description |
|-----------|-------------|
| `transport.manage` | Manage transport |

### Hostel Warden (`hostel_warden`)
| Permission | Description |
|-----------|-------------|
| `hostel.manage` | Manage hostel |

### Receptionist (`receptionist`)
| Permission | Description |
|-----------|-------------|
| `visitor.create` | Create visitor entry |
| `visitor.read` | View visitors |

### Parent (`parent`)
| Permission | Description |
|-----------|-------------|
| `student.read_own` | View own child's info |
| `attendance.read_own` | View own child's attendance |
| `fee.read_own` | View own fee records |

### Student (`student`)
| Permission | Description |
|-----------|-------------|
| `homework.read` | View homework |
| `exam.read` | View exams |
| `attendance.read_own` | View own attendance |
