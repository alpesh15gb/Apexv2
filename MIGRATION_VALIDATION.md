# School ERP Migration Validation Report

**Migration**: `backend/alembic/versions/b2c3d4e5f6a7_add_school_erp_tables.py`
**Revision**: `b2c3d4e5f6a7` (depends on `a1b2c3d4e5f6`)
**Date validated**: 2026-06-28

---

## 1. Table Count

| Criterion | Expected | Actual | Status |
|-----------|----------|--------|--------|
| Total `op.create_table` calls | 55 | 55 | PASS |
| Tables in `downgrade()` list | 55 | 54 | **FAIL** |

**Issue: `subjects` table is MISSING from the `downgrade()` function.**

The `subjects` table is created at line 251 of the migration but does not appear in the `tables` list inside `downgrade()` (lines 686-704). Running `alembic downgrade` will fail with a foreign-key-constraint error because `grade_subjects`, `exam_schedules`, `homework`, `assignments`, `lesson_plans`, `timetable_entries`, and `teacher_allocations` all hold FKs referencing `subjects`.

### Complete table inventory (55 tables)

| # | Table | Phase |
|---|-------|-------|
| 1 | academic_years | 1 |
| 2 | grades | 1 |
| 3 | campuses | 1 |
| 4 | fee_categories | 1 |
| 5 | exam_types | 1 |
| 6 | grading_scales | 1 |
| 7 | scholarships | 1 |
| 8 | transport_routes | 1 |
| 9 | period_definitions | 1 |
| 10 | certificate_templates | 1 |
| 11 | library_books | 1 |
| 12 | guardians | 1 |
| 13 | academic_terms | 2 |
| 14 | school_holidays | 2 |
| 15 | buildings | 2 |
| 16 | hostels | 2 |
| 17 | transport_stops | 2 |
| 18 | grading_scale_details | 2 |
| 19 | fee_fine_rules | 2 |
| 20 | school_events | 2 |
| 21 | circulars | 2 |
| 22 | admission_inquiries | 2 |
| 23 | subjects | 2 |
| 24 | rooms | 3 |
| 25 | houses | 3 |
| 26 | hostel_rooms | 3 |
| 27 | sections | 3 |
| 28 | fee_structures | 3 |
| 29 | grade_subjects | 3 |
| 30 | exams | 3 |
| 31 | students | 4 |
| 32 | student_guardians | 5 |
| 33 | student_siblings | 5 |
| 34 | admission_applications | 5 |
| 35 | issued_certificates | 5 |
| 36 | health_records | 5 |
| 37 | discipline_incidents | 5 |
| 38 | student_fees | 5 |
| 39 | fee_payments | 5 |
| 40 | student_scholarships | 5 |
| 41 | hostel_allocations | 5 |
| 42 | student_transport | 5 |
| 43 | student_attendance | 5 |
| 44 | student_attendance_summary | 5 |
| 45 | teacher_allocations | 6 |
| 46 | timetable_entries | 6 |
| 47 | exam_schedules | 6 |
| 48 | exam_marks | 6 |
| 49 | homework | 6 |
| 50 | homework_submissions | 6 |
| 51 | assignments | 6 |
| 52 | assignment_submissions | 6 |
| 53 | lesson_plans | 6 |
| 54 | library_transactions | 6 |
| 55 | substitutions | 6 |

---

## 2. Foreign Key Ordering

All 6 phases respect dependency ordering. No table references a table created in the same or a later phase (except for cross-references within the same phase that are already valid).

| Phase | FK targets | Status |
|-------|-----------|--------|
| 1 | External only (`tenants`, `branches`, `employees`, `users`, `departments`) | PASS |
| 2 | Phase 1 + external | PASS |
| 3 | Phase 1 + Phase 2 + external | PASS |
| 4 | Phase 1 + Phase 3 + external | PASS |
| 5 | Phase 1 + Phase 3 + Phase 4 + external | PASS |
| 6 | Phase 1 + Phase 3 + Phase 4 + Phase 5 + external | PASS |

### Downgrade FK ordering

The `downgrade()` function drops tables in reverse-dependency order (children before parents). With the exception of the missing `subjects` entry, all other 54 tables are correctly ordered. Specifically:

- `substitutions` (depends on `timetable_entries`) is dropped before `timetable_entries`
- `homework_submissions` (depends on `homework`) is dropped before `homework`
- `student_fees` (depends on `fee_structures`) is dropped before `fee_structures`
- `students` (depends on `sections`, `grades`, `houses`) is dropped before all three
- `sections` (depends on `rooms`, `grades`) is dropped before `rooms`
- `rooms` (depends on `buildings`) is dropped before `buildings`

**Status: PASS (once `subjects` is added in the correct position)**

The correct position for `subjects` in the downgrade list is after `grade_subjects` (which depends on it) and before `sections` / `rooms`. Specifically, it should be inserted between `grade_subjects` and `fee_structures` in the existing list, or anywhere after all tables that reference it have been dropped. Safe insertion point:

```python
# After grade_subjects, before fee_structures
'grade_subjects', 'subjects', 'fee_structures', 'sections',
```

---

## 3. Column Matching (Migration vs Model Definitions)

Every column in every model was compared against the corresponding `op.create_table` call. All 55 tables match exactly on:

- Column names
- Column types (String lengths, Numeric precision, UUID, Date, Time, DateTime, Boolean, Text, JSONB)
- Nullable constraints
- Foreign key targets and ondelete behavior
- Server defaults vs model defaults (migration uses `server_default` for DB-level defaults, models use `default` for ORM-level defaults — this is correct SQLAlchemy practice)

### Tables with composite indexes

| Table | Index Name | Columns | Migration | Model | Status |
|-------|-----------|---------|-----------|-------|--------|
| students | `ix_students_tenant_active` | `tenant_id`, `is_active` | line 375 | student.py:52 | PASS |
| students | `ix_students_tenant_grade_section` | `tenant_id`, `current_grade_id`, `current_section_id` | line 376 | student.py:53 | PASS |
| student_fees | `ix_student_fees_tenant_status` | `tenant_id`, `status` | line 467 | fee.py:44 | PASS |
| student_attendance | `ix_student_attendance_tenant_date_status` | `tenant_id`, `date`, `status` | line 524 | student_attendance.py:24 | PASS |

**Status: PASS**

### Notes on soft references (no FK constraint)

Two columns use UUID references without a formal `ForeignKey` constraint:

| Table | Column | Referenced Table | Reason |
|-------|--------|-----------------|--------|
| `student_guardians` | `guardian_id` | `guardians` | Soft reference — model and migration match (no FK) |
| `library_transactions` | `borrower_id` | (polymorphic) | Polymorphic reference to either `students` or `employees` — no FK by design |

Both model and migration are consistent. These are intentional design choices.

---

## 4. Unique Constraints

No explicit `UniqueConstraint` or `unique=True` columns are defined in any school model beyond the primary key. The migration matches — no `op.create_unique_constraint` calls exist.

**Status: PASS (N/A — no unique constraints defined)**

---

## 5. Model Imports

### `backend/app/models/school/__init__.py`

All 55 model classes are imported from their respective submodules. Cross-checked against the 18 model files:

| File | Models Exported | Count |
|------|----------------|-------|
| academic_year.py | AcademicYear, AcademicTerm, SchoolHoliday | 3 |
| campus.py | Campus, Building, Room | 3 |
| grade.py | Grade, Section, House | 3 |
| student.py | Student, Guardian, StudentGuardian, StudentSibling | 4 |
| subject.py | Subject, GradeSubject, TeacherAllocation | 3 |
| timetable.py | PeriodDefinition, TimetableEntry, Substitution | 3 |
| student_attendance.py | StudentAttendance, StudentAttendanceSummary | 2 |
| homework.py | Homework, HomeworkSubmission, Assignment, AssignmentSubmission | 4 |
| examination.py | ExamType, Exam, ExamSchedule, ExamMark, GradingScale, GradingScaleDetail | 6 |
| fee.py | FeeCategory, FeeStructure, StudentFee, FeePayment, FeeFineRule, Scholarship, StudentScholarship | 7 |
| transport.py | TransportRoute, TransportStop, StudentTransport | 3 |
| hostel.py | Hostel, HostelRoom, HostelAllocation | 3 |
| library.py | LibraryBook, LibraryTransaction | 2 |
| lesson_plan.py | LessonPlan | 1 |
| communication.py | SchoolEvent, Circular | 2 |
| medical.py | HealthRecord, DisciplineIncident | 2 |
| certificate.py | CertificateTemplate, IssuedCertificate | 2 |
| admission.py | AdmissionInquiry, AdmissionApplication | 2 |
| **Total** | | **55** |

**Status: PASS**

### `backend/app/models/__init__.py`

All 55 school models are re-exported in both the import block (lines 49-68) and the `__all__` list (lines 178-195).

**Status: PASS**

---

## 6. Summary

| Check | Result |
|-------|--------|
| 55 tables created | PASS |
| FK ordering (upgrade) | PASS |
| FK ordering (downgrade) | **FAIL** — `subjects` missing |
| Column matching | PASS |
| Indexes | PASS |
| Unique constraints | PASS (N/A) |
| school/__init__.py imports | PASS |
| models/__init__.py re-exports | PASS |

### Issues Found

1. **CRITICAL — Missing `subjects` in downgrade** (`b2c3d4e5f6a7_add_school_erp_tables.py:686-704`)
   - The `subjects` table is created at line 251 but omitted from the `downgrade()` table list.
   - Downgrading will fail because 7 other tables have FK constraints pointing to `subjects`.
   - **Fix**: Add `'subjects'` to the downgrade list between `'grade_subjects'` and `'fee_structures'`.
