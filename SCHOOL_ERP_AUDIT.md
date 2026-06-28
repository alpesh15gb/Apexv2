# School ERP Module Audit — Apex HRMS

> Auto-generated audit of all School-specific modules.
> Scope: `backend/app/models/school/`, `backend/app/api/v1/endpoints/school/`, `frontend/lib/screens/school/`
> Date: 2026-06-28

---

## Table of Contents

1. [Academic Year](#1-academic-year)
2. [Admission](#2-admission)
3. [Campus](#3-campus)
4. [Certificate](#4-certificate)
5. [Communication](#5-communication)
6. [Examination](#6-examination)
7. [Fee](#7-fee)
8. [Grade / Section](#8-grade--section)
9. [Homework](#9-homework)
10. [Hostel](#10-hostel)
11. [Library](#11-library)
12. [Medical / Discipline](#12-medical--discipline)
13. [School Dashboard](#13-school-dashboard)
14. [Student](#14-student)
15. [Student Attendance](#15-student-attendance)
16. [Timetable](#16-timetable)
17. [Transport](#17-transport)
18. [Cross-Module Dependency Map](#18-cross-module-dependency-map)
19. [Feature Flag Summary](#19-feature-flag-summary)
20. [Permission Summary](#20-permission-summary)

---

## Common Infrastructure

All School models inherit from `TenantModel` (`app/db/base.py:40`), which provides:

| Column | Type | Notes |
|---|---|---|
| `id` | UUID PK | `gen_random_uuid()` |
| `tenant_id` | UUID FK → `tenants.id` | Row-level multi-tenancy |
| `created_at` | DateTime(tz) | Auto-set on insert |
| `updated_at` | DateTime(tz) | Auto-set on update |

Feature gates are enforced via `require_feature(code)` (`app/core/deps.py:180`). Permissions via `require_permissions(*codenames)` (`app/core/deps.py:146`). Superusers bypass both checks.

---

## 1. Academic Year

**Purpose**: Foundation module — defines academic years, terms within a year, and school holidays. Nearly every other School module FK-references `academic_years.id`.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/academic_year.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/academic_year.py` |
| Frontend | `frontend/lib/screens/school/academic_year_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| AcademicYear | `academic_years` | `name`, `start_date`, `end_date`, `is_current`, `promotion_date`, `status` (planning/active/closed/archived) |
| AcademicTerm | `academic_terms` | `academic_year_id` FK, `name`, `start_date`, `end_date`, `sort_order` |
| SchoolHoliday | `school_holidays` | `academic_year_id` FK, `name`, `date`, `type` (holiday/exam/vacation/event) |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/academic-years/` | List all academic years |
| POST | `/school/academic-years/` | Create academic year |
| PUT | `/school/academic-years/{year_id}` | Update academic year |
| POST | `/school/academic-years/{year_id}/set-current` | Set as current year (clears others) |
| GET | `/school/academic-years/{year_id}/terms` | List terms for a year |
| POST | `/school/academic-years/{year_id}/terms` | Create term |
| GET | `/school/academic-years/{year_id}/holidays` | List holidays for a year |
| POST | `/school/academic-years/{year_id}/holidays` | Create holiday |

### Feature Flags

- `academic_year`

### Permissions

- `school.settings`

### Dependencies

- **Core**: TenantModel (tenants)
- **School**: None (foundational module)

---

## 2. Admission

**Purpose**: Full admission pipeline — inquiries → applications → review → enrollment. Enrollment auto-creates a `Student` record.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/admission.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/admission.py` |
| Frontend | `frontend/lib/screens/school/admission_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| AdmissionInquiry | `admission_inquiries` | `student_name`, `parent_name`, `phone`, `email`, `grade_applying`, `academic_year_id` FK, `source` (walk-in/website/referral/agent), `status` (new/contacted/visited/applied/admitted/rejected), `assigned_to` FK→employees |
| AdmissionApplication | `admission_applications` | `inquiry_id` FK, `application_number`, `student_name`, `date_of_birth`, `gender`, `grade_applying`, `parent_name`, `parent_phone`, `academic_year_id` FK, `status` (submitted/under_review/interview_scheduled/selected/rejected/enrolled), `interview_date`, `interview_score`, `reviewed_by` FK→employees, `student_id` FK→students, `documents` JSONB |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/admissions/inquiries` | List inquiries (optional status filter) |
| POST | `/school/admissions/inquiries` | Create inquiry |
| GET | `/school/admissions/applications` | List applications (optional status filter) |
| POST | `/school/admissions/applications` | Create application |
| PUT | `/school/admissions/applications/{app_id}/review` | Review application (set status/remarks) |
| POST | `/school/admissions/applications/{app_id}/enroll` | Enroll student (creates Student record) |

### Feature Flags

- `admissions`

### Permissions

- `admission.manage`

### Dependencies

- **Core**: employees (assigned_to, reviewed_by)
- **School**: Academic Year, Student

---

## 3. Campus

**Purpose**: Physical infrastructure — campuses, buildings, and rooms. Referenced by Timetable (room_id), Grade/Section (room_id), and Hostel (campus_id).

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/campus.py` |
| Endpoint | **NONE — model exists but no endpoint file** |
| Frontend | **NONE** |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| Campus | `campuses` | `branch_id` FK→branches, `name`, `code`, `address`, `phone`, `email`, `latitude`, `longitude`, `is_active` |
| Building | `buildings` | `campus_id` FK, `name`, `code`, `floors`, `is_active` |
| Room | `rooms` | `building_id` FK, `name`, `room_number`, `floor`, `room_type` (classroom/lab/library/office/hall/hostel), `capacity`, `has_projector`, `has_ac`, `is_active` |

### API Endpoints

**None implemented.** Campus/Building/Room data must be seeded directly or managed through other modules that reference rooms (e.g., Section.room_id, TimetableEntry.room_id).

### Feature Flags

- None

### Permissions

- None

### Dependencies

- **Core**: branches table
- **School**: None

### Gap

No CRUD endpoints exist for campus, building, or room management. This is a significant gap — room references are used by Timetable, Grade/Section, and Hostel but there is no way to manage them through the API.

---

## 4. Certificate

**Purpose**: Generate and track certificates (bonafide, transfer, conduct, character, study, custom) issued to students.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/certificate.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/certificate.py` |
| Frontend | **NONE** |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| CertificateTemplate | `certificate_templates` | `name`, `template_type` (bonafide/transfer/conduct/character/study/custom), `template_html`, `template_json` JSONB, `is_default`, `is_active` |
| IssuedCertificate | `issued_certificates` | `student_id` FK, `template_id` FK, `certificate_number`, `issue_date`, `purpose`, `issued_by` FK→employees, `pdf_url`, `qr_code` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/certificates/templates` | List templates (optional template_type filter) |
| POST | `/school/certificates/templates` | Create template |
| POST | `/school/certificates/issue` | Issue certificate to student |
| GET | `/school/certificates/student/{student_id}` | List certificates for a student |

### Feature Flags

- `school_certificates`

### Permissions

- `certificate.issue`

### Dependencies

- **Core**: employees (issued_by)
- **School**: Student (student_id FK)

---

## 5. Communication

**Purpose**: Publish school circulars and manage events. Two separate sub-routers with independent feature flags.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/communication.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/communication.py` |
| Frontend | **NONE** |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| SchoolEvent | `school_events` | `title`, `description`, `event_type` (sports/academic/cultural/ptm/holiday/general), `start_date`, `end_date`, `venue`, `organizer_id` FK→employees, `target_audience` JSONB, `is_public`, `attachment_urls` JSONB |
| Circular | `circulars` | `title`, `content`, `circular_type` (general/academic/fee/event/emergency), `target_audience` JSONB, `attachment_urls` JSONB, `published_at`, `published_by` FK→employees, `is_active` |

### API Endpoints

| Method | Path | Router | Description |
|---|---|---|---|
| GET | `/school/circulars/` | `circular_router` | List active circulars |
| POST | `/school/circulars/` | `circular_router` | Create circular (auto-sets published_at) |
| GET | `/school/events/` | `event_router` | List events |
| POST | `/school/events/` | `event_router` | Create event |

### Feature Flags

- `school_circulars` (circular_router)
- `school_events` (event_router)

### Permissions

- `circular.publish`
- `event.manage`

### Dependencies

- **Core**: employees (organizer_id, published_by)
- **School**: None

---

## 6. Examination

**Purpose**: Full exam lifecycle — exam types, exams, schedules, mark entry (single + bulk), and grading scales.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/examination.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/examination.py` |
| Frontend | `frontend/lib/screens/school/exam_list_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| ExamType | `exam_types` | `name`, `code`, `weightage`, `exam_category` (internal/external/practical/unit/final), `is_active` |
| Exam | `exams` | `exam_type_id` FK, `academic_year_id` FK, `academic_term_id` FK, `name`, `start_date`, `end_date`, `status` (draft/scheduled/ongoing/completed/results_published) |
| ExamSchedule | `exam_schedules` | `exam_id` FK, `subject_id` FK→subjects, `grade_id` FK→grades, `exam_date`, `start_time`, `end_time`, `max_marks`, `pass_marks`, `room_ids` JSONB, `invigilator_ids` JSONB |
| ExamMark | `exam_marks` | `exam_schedule_id` FK, `student_id` FK, `marks_obtained`, `practical_marks`, `grade`, `is_absent`, `is_exempted`, `remarks`, `entered_by` FK→employees, `verified_by` FK→employees |
| GradingScale | `grading_scales` | `name`, `scale_type` (percentage/grade/points), `is_default` |
| GradingScaleDetail | `grading_scale_details` | `grading_scale_id` FK, `grade`, `min_percentage`, `max_percentage`, `gpa`, `description`, `sort_order` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/exam-types` | List exam types (paginated) |
| POST | `/school/exam-types` | Create exam type |
| GET | `/school/exams` | List exams (paginated, optional academic_year_id filter) |
| POST | `/school/exams` | Create exam |
| GET | `/school/exams/{exam_id}/schedules` | List schedules for an exam (paginated) |
| POST | `/school/exams/{exam_id}/schedules` | Create exam schedule |
| POST | `/school/marks/enter` | Enter/update single student mark |
| POST | `/school/marks/bulk-enter` | Bulk enter marks (upsert pattern) |
| GET | `/school/marks/{exam_schedule_id}` | Get marks for a schedule (with student names) |
| GET | `/school/grading-scales` | List grading scales (paginated) |
| POST | `/school/grading-scales` | Create grading scale with details |

### Feature Flags

- `examinations`

### Permissions

- `exam.read` (router-level)
- `exam.create` (on create endpoints)
- `exam.manage` (on schedule/mark/grading endpoints)

### Dependencies

- **Core**: employees (entered_by, verified_by), departments (via Subject)
- **School**: Academic Year, Academic Term, Subject, Grade, Student

---

## 7. Fee

**Purpose**: Complete fee lifecycle — categories, structures (per grade/year), student fee assignment, payments, fine rules, and scholarships.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/fee.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/fee.py` |
| Frontend | `frontend/lib/screens/school/fee_collection_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| FeeCategory | `fee_categories` | `name`, `code`, `is_active`, `sort_order` |
| FeeStructure | `fee_structures` | `academic_year_id` FK, `grade_id` FK→grades, `fee_category_id` FK, `amount`, `frequency` (monthly/quarterly/half-yearly/annual/one-time), `due_day`, `is_mandatory` |
| StudentFee | `student_fees` | `student_id` FK, `fee_structure_id` FK, `academic_year_id` FK, `amount`, `discount_amount`, `scholarship_amount`, `final_amount`, `due_date`, `status` (pending/partial/paid/overdue/waived) |
| FeePayment | `fee_payments` | `student_id` FK, `student_fee_id` FK, `amount`, `payment_date`, `payment_method` (cash/card/upi/cheque/neft/online), `reference_number`, `receipt_number`, `collected_by` FK→employees, `status` (completed/refunded/cancelled) |
| FeeFineRule | `fee_fine_rules` | `fee_category_id` FK, `days_after_due`, `fine_type` (fixed/percentage), `fine_amount`, `max_fine`, `is_active` |
| Scholarship | `scholarships` | `name`, `scholarship_type` (percentage/fixed), `value`, `max_amount`, `applicable_fee_categories` JSONB, `is_active` |
| StudentScholarship | `student_scholarships` | `student_id` FK, `scholarship_id` FK, `academic_year_id` FK, `start_date`, `end_date`, `is_active` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/fees/categories` | List fee categories (paginated) |
| POST | `/school/fees/categories` | Create fee category |
| GET | `/school/fees/structures` | List fee structures (paginated, filterable by year/grade) |
| POST | `/school/fees/structures` | Create fee structure |
| POST | `/school/fees/payments` | Record payment (auto-generates receipt number, updates StudentFee status) |
| GET | `/school/fees/payments` | List payments (paginated, optional student_id filter) |
| GET | `/school/fees/students/{student_id}` | Student fee summary |
| GET | `/school/fees/reports/dues` | Fee dues report (pending/partial/overdue) |

### Feature Flags

- `fee_management`

### Permissions

- `fee.read` (router-level)

### Dependencies

- **Core**: employees (collected_by)
- **School**: Academic Year, Grade, Student

### Gap

No endpoints for FeeFineRule, Scholarship, or StudentScholarship CRUD — these models exist in the database but cannot be managed through the API.

---

## 8. Grade / Section

**Purpose**: Academic structure — grades (classes), sections within grades, houses, subjects, grade-subject mapping, and teacher allocations.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/grade.py`, `backend/app/models/school/subject.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/grade_section.py` |
| Frontend | `frontend/lib/screens/school/grade_section_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| Grade | `grades` | `name`, `code`, `sort_order`, `is_active` |
| Section | `sections` | `grade_id` FK, `name`, `capacity`, `room_id` FK→rooms, `class_teacher_id` FK→employees, `academic_year_id` FK, `is_active` |
| House | `houses` | `name`, `code`, `color`, `house_master_id` FK→employees, `is_active` |
| Subject | `subjects` | `name`, `code`, `subject_type` (core/elective/practical/language/extracurricular), `department_id` FK→departments, `credits`, `max_marks`, `pass_marks`, `has_practical`, `practical_max_marks`, `is_active` |
| GradeSubject | `grade_subjects` | `grade_id` FK, `subject_id` FK, `academic_year_id` FK, `is_compulsory`, `sort_order` |
| TeacherAllocation | `teacher_allocations` | `employee_id` FK→employees, `subject_id` FK, `section_id` FK, `academic_year_id` FK, `periods_per_week` |

### API Endpoints

**Router 1** (`router` — class_management):

| Method | Path | Description |
|---|---|---|
| GET | `/school/grades` | List grades |
| POST | `/school/grades` | Create grade |
| PUT | `/school/grades/{grade_id}` | Update grade |
| GET | `/school/grades/{grade_id}/sections` | List sections for a grade |
| POST | `/school/grades/{grade_id}/sections` | Create section |
| GET | `/school/sections/{section_id}/students` | List students in a section |

**Router 2** (`subjects_router` — subject_management):

| Method | Path | Description |
|---|---|---|
| GET | `/school/subjects` | List subjects |
| POST | `/school/subjects` | Create subject |
| PUT | `/school/subjects/{subject_id}` | Update subject |
| GET | `/school/grades/{grade_id}/subjects` | List subjects assigned to a grade |
| POST | `/school/grades/{grade_id}/subjects` | Assign subjects to a grade |

**Router 3** (`alloc_router` — class_management):

| Method | Path | Description |
|---|---|---|
| GET | `/school/teacher-allocations` | List teacher allocations (filterable by section/employee/year) |
| POST | `/school/teacher-allocations` | Create teacher allocation |

### Feature Flags

- `class_management` (router, alloc_router)
- `subject_management` (subjects_router)

### Permissions

- `school.settings` (all three routers)

### Dependencies

- **Core**: employees (class_teacher_id, house_master_id, employee_id), departments (Subject.department_id), rooms
- **School**: Academic Year, Campus (rooms)

### Gap

No CRUD endpoints for House management.

---

## 9. Homework

**Purpose**: Assign homework/assignments to sections, track submissions, and review/grade them.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/homework.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/homework.py` |
| Frontend | `frontend/lib/screens/school/homework_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| Homework | `homework` | `section_id` FK→sections, `subject_id` FK→subjects, `employee_id` FK→employees, `title`, `description`, `due_date`, `attachment_urls` JSONB, `academic_year_id` FK, `is_active` |
| HomeworkSubmission | `homework_submissions` | `homework_id` FK, `student_id` FK, `submitted_at`, `attachment_urls` JSONB, `remarks`, `marks`, `grade`, `status` (pending/submitted/reviewed/late), `reviewed_by` FK→employees, `reviewed_at` |
| Assignment | `assignments` | `section_id` FK, `subject_id` FK, `employee_id` FK, `title`, `description`, `assignment_type` (online/offline/project), `max_marks`, `rubric` JSONB, `due_date`, `attachment_urls` JSONB, `academic_year_id` FK, `is_active` |
| AssignmentSubmission | `assignment_submissions` | `assignment_id` FK, `student_id` FK, `submitted_at`, `attachment_urls` JSONB, `marks`, `grade`, `feedback`, `status` (pending/submitted/reviewed/late), `evaluated_by` FK→employees, `evaluated_at` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/homework/` | List homework (filterable by section_id, subject_id) |
| POST | `/school/homework/` | Create homework |
| GET | `/school/homework/{homework_id}/submissions` | List submissions for homework |
| POST | `/school/homework/{homework_id}/submit` | Submit homework |
| PUT | `/school/homework/submissions/{submission_id}/review` | Review submission (marks, grade, remarks) |

### Feature Flags

- `homework`

### Permissions

- `homework.read`

### Dependencies

- **Core**: employees (employee_id, reviewed_by)
- **School**: Academic Year, Section, Subject, Student

### Gap

No endpoints for Assignment or AssignmentSubmission CRUD — these models exist but are not exposed via API.

---

## 10. Hostel

**Purpose**: Manage hostel buildings, rooms, and student room allocations.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/hostel.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/hostel.py` |
| Frontend | `frontend/lib/screens/school/hostel_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| Hostel | `hostels` | `campus_id` FK→campuses, `name`, `hostel_type` (boys/girls/staff), `warden_id` FK→employees, `capacity`, `is_active` |
| HostelRoom | `hostel_rooms` | `hostel_id` FK, `room_number`, `floor`, `room_type` (dormitory/single/double/triple/quadruple), `capacity`, `is_active` |
| HostelAllocation | `hostel_allocations` | `student_id` FK, `hostel_id` FK, `room_id` FK, `bed_number`, `academic_year_id` FK, `start_date`, `end_date`, `status` (active/vacated/expelled) |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/hostel/` | List hostels |
| POST | `/school/hostel/` | Create hostel |
| GET | `/school/hostel/{hostel_id}/rooms` | List rooms in a hostel |
| POST | `/school/hostel/{hostel_id}/rooms` | Create room |
| POST | `/school/hostel/allocations` | Allocate student to room (also updates Student.hostel_room_id) |
| GET | `/school/hostel/allocations` | List allocations (filterable by hostel_id) |

### Feature Flags

- `school_hostel`

### Permissions

- `hostel.manage`

### Dependencies

- **Core**: employees (warden_id)
- **School**: Campus (campus_id), Academic Year, Student

---

## 11. Library

**Purpose**: Manage book catalog and issue/return transactions with fine tracking.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/library.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/library.py` |
| Frontend | `frontend/lib/screens/school/library_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| LibraryBook | `library_books` | `isbn`, `title`, `author`, `publisher`, `category`, `subject`, `edition`, `year_published`, `total_copies`, `available_copies`, `shelf_location`, `barcode`, `price`, `is_active` |
| LibraryTransaction | `library_transactions` | `book_id` FK, `borrower_type` (student/employee), `borrower_id` UUID, `issue_date`, `due_date`, `return_date`, `fine_amount`, `fine_paid`, `issued_by` FK→employees, `returned_to` FK→employees, `status` (issued/returned/overdue/lost) |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/library/books` | List books (searchable by title/author, filterable by category, paginated) |
| POST | `/school/library/books` | Add book |
| POST | `/school/library/issue` | Issue book (decrements available_copies) |
| POST | `/school/library/return` | Return book (increments available_copies, sets fine) |
| GET | `/school/library/transactions` | List transactions (filterable by borrower_id, status) |

### Feature Flags

- `school_library`

### Permissions

- `library.manage`

### Dependencies

- **Core**: employees (issued_by, returned_to)
- **School**: None (borrower_id is polymorphic — student or employee)

---

## 12. Medical / Discipline

**Purpose**: Track student health records (checkups, vaccinations, illnesses, injuries) and discipline incidents.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/medical.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/medical.py` |
| Frontend | **NONE** |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| HealthRecord | `health_records` | `student_id` FK, `record_type` (checkup/vaccination/illness/injury), `date`, `description`, `doctor_name`, `medication`, `next_followup`, `attachment_urls` JSONB, `recorded_by` FK→employees |
| DisciplineIncident | `discipline_incidents` | `student_id` FK, `incident_date`, `incident_type` (misconduct/bullying/absenteeism/uniform/other), `severity` (minor/moderate/major/severe), `description`, `action_taken`, `reported_by` FK→employees, `parent_informed`, `parent_meeting_date`, `status` (open/in_review/resolved/escalated), `resolution`, `resolved_by` FK→employees |

### API Endpoints

**Router 1** (`medical_router` — school_medical):

| Method | Path | Description |
|---|---|---|
| GET | `/school/health/students/{student_id}` | Get health records for a student |
| POST | `/school/health/` | Create health record |

**Router 2** (`discipline_router` — school_discipline):

| Method | Path | Description |
|---|---|---|
| GET | `/school/discipline/` | List incidents (filterable by student_id, status) |
| POST | `/school/discipline/` | Create incident |
| PUT | `/school/discipline/{incident_id}/resolve` | Resolve incident |

### Feature Flags

- `school_medical` (medical_router)
- `school_discipline` (discipline_router)

### Permissions

- `medical.manage` (both routers)
- `discipline.manage` (discipline_router)

### Dependencies

- **Core**: employees (recorded_by, reported_by, resolved_by)
- **School**: Student

---

## 13. School Dashboard

**Purpose**: Aggregate statistics and attendance overview for the school dashboard.

### Files

| Layer | Path |
|---|---|
| Model | N/A (queries across multiple models) |
| Endpoint | `backend/app/api/v1/endpoints/school/school_dashboard.py` |
| Frontend | `frontend/lib/screens/school/school_dashboard_screen.dart` |

### Key Entities

None — read-only aggregation endpoint.

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/dashboard/stats` | Dashboard stats: total students, grades, sections, today's attendance, fee collection |
| GET | `/school/dashboard/attendance-overview` | Attendance trend over N days (default 7, max 30) |

### Feature Flags

- `student_management`

### Permissions

- `student.read`

### Dependencies

- **School**: Student, StudentAttendance, StudentFee, FeePayment, Grade, Section, Exam

---

## 14. Student

**Purpose**: Core student CRUD, guardian management, and student promotion.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/student.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/student.py` |
| Frontend | `frontend/lib/screens/school/student_list_screen.dart`, `frontend/lib/screens/school/student_detail_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| Student | `students` | `admission_number`, `roll_number`, `first_name`, `last_name`, `middle_name`, `date_of_birth`, `gender`, `blood_group`, `nationality`, `religion`, `caste`, `category` (General/OBC/SC/ST/EWS), `aadhaar_number`, `email`, `phone`, `address`, `city`, `state`, `pincode`, `photo_url`, `admission_date`, `admission_grade_id` FK→grades, `current_grade_id` FK→grades, `current_section_id` FK→sections, `house_id` FK→houses, `academic_year_id` FK, `status` (active/transferred/graduated/dropped/expelled), `previous_school`, `transfer_certificate_number`, `medical_conditions`, `allergies`, `emergency_contact_*`, `transport_route_id` FK→transport_routes, `hostel_room_id` FK→hostel_rooms, `is_active` |
| Guardian | `guardians` | `user_id` FK→users, `first_name`, `last_name`, `email`, `phone`, `alternate_phone`, `occupation`, `workplace`, `annual_income`, `education`, `address`, `photo_url`, `is_active` |
| StudentGuardian | `student_guardians` | `student_id` FK, `guardian_id` FK→guardians, `relationship` (father/mother/guardian), `is_primary`, `is_emergency_contact`, `can_pickup` |
| StudentSibling | `student_siblings` | `student_id` FK, `sibling_id` FK |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/students/` | List students (paginated, filterable by grade/section/status, searchable) |
| POST | `/school/students/` | Create student (validates unique admission_number) |
| GET | `/school/students/{student_id}` | Get student detail |
| PUT | `/school/students/{student_id}` | Update student |
| POST | `/school/students/{student_id}/guardians` | Add guardian + link to student |
| GET | `/school/students/{student_id}/guardians` | List guardians for a student |
| POST | `/school/students/{student_id}/promote` | Promote student (change grade/section/year) |

### Feature Flags

- `student_management`

### Permissions

- `student.read`

### Dependencies

- **Core**: users (Guardian.user_id), employees
- **School**: Academic Year, Grade, Section, House, Transport Route, Hostel Room

---

## 15. Student Attendance

**Purpose**: Mark and query student attendance (daily, per-period, or bus).

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/student_attendance.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/student_attendance.py` |
| Frontend | `frontend/lib/screens/school/attendance_mark_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| StudentAttendance | `student_attendance` | `student_id` FK, `date`, `status` (present/absent/late/half-day/excused), `check_in_time`, `check_out_time`, `remarks`, `marked_by` FK→employees, `attendance_type` (daily/period/bus), `period_definition_id` FK→period_definitions, `academic_year_id` FK |
| StudentAttendanceSummary | `student_attendance_summary` | `student_id` FK, `academic_year_id` FK, `month`, `year`, `total_days`, `present_days`, `absent_days`, `late_days`, `half_days`, `excused_days` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| POST | `/school/student-attendance/mark` | Mark single student attendance (upsert) |
| POST | `/school/student-attendance/bulk-mark` | Bulk mark attendance for a section |
| GET | `/school/student-attendance/` | Get attendance (date range, optional section/student filter) |
| GET | `/school/student-attendance/daily-summary` | Daily attendance summary by status |

### Feature Flags

- `student_attendance`

### Permissions

- `student_attendance.read`

### Dependencies

- **Core**: employees (marked_by)
- **School**: Academic Year, Student, PeriodDefinition (from Timetable)

---

## 16. Timetable

**Purpose**: Define periods, create section timetables, manage teacher substitutions.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/timetable.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/timetable.py` |
| Frontend | `frontend/lib/screens/school/timetable_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| PeriodDefinition | `period_definitions` | `name`, `start_time`, `end_time`, `period_type` (period/break/assembly/lunch), `sort_order` |
| TimetableEntry | `timetable_entries` | `section_id` FK→sections, `subject_id` FK→subjects, `employee_id` FK→employees, `room_id` FK→rooms, `period_definition_id` FK, `day_of_week` (1=Mon..7=Sun), `academic_year_id` FK, `is_active` |
| Substitution | `substitutions` | `original_employee_id` FK→employees, `substitute_employee_id` FK→employees, `timetable_entry_id` FK, `date`, `reason`, `status` (pending/approved/rejected), `approved_by` FK→users |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/timetable/periods` | List period definitions |
| POST | `/school/timetable/periods` | Create period definition |
| GET | `/school/timetable/section/{section_id}` | Get section timetable |
| POST | `/school/timetable/section/{section_id}` | Set/update section timetable (bulk upsert) |
| GET | `/school/timetable/teacher/{employee_id}` | Get teacher timetable |
| POST | `/school/timetable/substitutions` | Create substitution |
| GET | `/school/timetable/substitutions` | List substitutions (date range filter) |

### Feature Flags

- `school_timetable`

### Permissions

- `school.settings`

### Dependencies

- **Core**: employees (employee_id, original/substitute), users (approved_by), rooms
- **School**: Academic Year, Section, Subject, Campus (rooms)

---

## 17. Transport

**Purpose**: Manage transport routes, stops, and student route assignments.

### Files

| Layer | Path |
|---|---|
| Model | `backend/app/models/school/transport.py` |
| Endpoint | `backend/app/api/v1/endpoints/school/transport.py` |
| Frontend | `frontend/lib/screens/school/transport_screen.dart` |

### Key Entities

| Entity | Table | Key Columns |
|---|---|---|
| TransportRoute | `transport_routes` | `name`, `code`, `vehicle_number`, `vehicle_type` (bus/van/minibus), `capacity`, `driver_id` FK→employees, `helper_id` FK→employees, `is_active` |
| TransportStop | `transport_stops` | `route_id` FK, `name`, `sequence`, `pickup_time`, `drop_time`, `latitude`, `longitude` |
| StudentTransport | `student_transport` | `student_id` FK, `route_id` FK, `stop_id` FK, `academic_year_id` FK, `pickup_type` (pickup/drop/both), `fee_amount`, `is_active` |

### API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/school/transport/routes` | List routes |
| POST | `/school/transport/routes` | Create route |
| GET | `/school/transport/routes/{route_id}/stops` | List stops for a route |
| POST | `/school/transport/routes/{route_id}/stops` | Create stop |
| POST | `/school/transport/students/assign` | Assign student to route (also updates Student.transport_route_id) |
| GET | `/school/transport/students/{student_id}` | Get student transport assignment |

### Feature Flags

- `school_transport`

### Permissions

- `transport.manage`

### Dependencies

- **Core**: employees (driver_id, helper_id)
- **School**: Academic Year, Student

---

## 18. Cross-Module Dependency Map

```
Academic Year ◄─────────────────────────────────────────────────┐
    ▲                                                           │
    │ (FK)                                                      │
    ├─ Admission ◄── Student (via enroll)                       │
    ├─ Fee Structure                                             │
    ├─ Student Fee                                               │
    ├─ Student                                                    │
    ├─ Section                                                    │
    ├─ Exam                                                       │
    ├─ GradeSubject                                               │
    ├─ TeacherAllocation                                          │
    ├─ Homework                                                   │
    ├─ Assignment                                                 │
    ├─ StudentAttendance                                          │
    ├─ AttendanceSummary                                          │
    ├─ TimetableEntry                                             │
    ├─ HostelAllocation                                           │
    └─ StudentTransport                                           │

Grade / Section ◄───────────────────────────────────────────────┐
    ▲                                                           │
    │ (FK)                                                      │
    ├─ Student (current_grade_id, current_section_id)            │
    ├─ Fee Structure (grade_id)                                   │
    ├─ ExamSchedule (grade_id)                                    │
    ├─ Homework (section_id)                                      │
    ├─ TimetableEntry (section_id)                                │
    ├─ TeacherAllocation (section_id)                             │
    └─ GradeSubject (grade_id)                                    │

Student ◄───────────────────────────────────────────────────────┐
    ▲                                                           │
    │ (FK)                                                      │
    ├─ Admission (student_id on enroll)                           │
    ├─ StudentAttendance                                          │
    ├─ ExamMark                                                   │
    ├─ StudentFee / FeePayment                                    │
    ├─ HomeworkSubmission / AssignmentSubmission                  │
    ├─ Certificate (IssuedCertificate)                            │
    ├─ HealthRecord / DisciplineIncident                          │
    ├─ HostelAllocation                                           │
    └─ StudentTransport                                           │

Subject ◄───────────────────────────────────────────────────────┐
    ▲                                                           │
    │ (FK)                                                      │
    ├─ ExamSchedule                                               │
    ├─ Homework                                                   │
    ├─ TimetableEntry                                             │
    ├─ GradeSubject                                               │
    └─ TeacherAllocation                                          │

Campus/Room ◄───────────────────────────────────────────────────┐
    ▲                                                           │
    │ (FK)                                                      │
    ├─ Section (room_id)                                          │
    ├─ TimetableEntry (room_id)                                   │
    └─ Hostel (campus_id)                                         │
```

---

## 19. Feature Flag Summary

| Feature Code | Module(s) | Router(s) |
|---|---|---|
| `academic_year` | Academic Year | `academic_year.router` |
| `admissions` | Admission | `admission.router` |
| `class_management` | Grade/Section, Teacher Allocation | `grade_section.router`, `grade_section.alloc_router` |
| `examinations` | Examination | `examination.router` |
| `fee_management` | Fee | `fee.router` |
| `homework` | Homework | `homework.router` |
| `school_certificates` | Certificate | `certificate.router` |
| `school_circulars` | Communication (Circulars) | `communication.circular_router` |
| `school_discipline` | Discipline | `medical.discipline_router` |
| `school_events` | Communication (Events) | `communication.event_router` |
| `school_hostel` | Hostel | `hostel.router` |
| `school_library` | Library | `library.router` |
| `school_medical` | Medical | `medical.medical_router` |
| `school_timetable` | Timetable | `timetable.router` |
| `school_transport` | Transport | `transport.router` |
| `student_attendance` | Student Attendance | `student_attendance.router` |
| `student_management` | Student, School Dashboard | `student.router`, `school_dashboard.router` |
| `subject_management` | Subject | `grade_section.subjects_router` |

---

## 20. Permission Summary

| Permission Codename | Module(s) | Scope |
|---|---|---|
| `school.settings` | Academic Year, Grade/Section, Subject, Teacher Allocation, Timetable | Configuration |
| `admission.manage` | Admission | Full CRUD |
| `certificate.issue` | Certificate | Issue + read |
| `circular.publish` | Communication (Circulars) | Publish + read |
| `discipline.manage` | Discipline | Full CRUD |
| `event.manage` | Communication (Events) | Full CRUD |
| `exam.create` | Examination | Create exam types and exams |
| `exam.manage` | Examination | Schedules, marks, grading |
| `exam.read` | Examination | Read access |
| `fee.read` | Fee | Read access |
| `homework.read` | Homework | Read access |
| `hostel.manage` | Hostel | Full CRUD |
| `library.manage` | Library | Full CRUD |
| `medical.manage` | Medical | Full CRUD |
| `student.read` | Student, School Dashboard | Read access |
| `student_attendance.read` | Student Attendance | Read + mark |
| `transport.manage` | Transport | Full CRUD |

---

## Gaps & Observations

1. **Campus has no endpoints** — `Campus`, `Building`, `Room` models exist but cannot be managed via API. Referenced by Section, TimetableEntry, and Hostel.

2. **No frontend screens** for: Certificate, Communication, Medical/Discipline.

3. **Fee module gaps** — `FeeFineRule`, `Scholarship`, `StudentScholarship` models exist but have no API endpoints.

4. **Homework module gaps** — `Assignment` and `AssignmentSubmission` models exist but have no API endpoints.

5. **StudentAttendanceSummary** model exists but is never populated — no endpoint or background job writes to it.

6. **House** model exists in Grade/Section module but has no CRUD endpoints.

7. **LessonPlan** model exists (`backend/app/models/school/lesson_plan.py`) but has no endpoint file and is not listed in the `__init__.py` exports.

8. **Student.promote** endpoint does not validate that the new grade/section/year exist or belong to the same tenant.

9. **No DELETE endpoints** exist for any School module — all deactivation is via `is_active = False` flags, but there are no deactivate/soft-delete endpoints either.

10. **Exam is imported but unused** in `school_dashboard.py:16` — the `Exam` model is imported but never queried in the dashboard endpoints.
