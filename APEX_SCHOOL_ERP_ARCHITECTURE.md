# Apex School ERP — Complete Architecture Blueprint

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Reuse Strategy](#2-reuse-strategy)
3. [Database Schema](#3-database-schema)
4. [Entity Relationship Diagram](#4-entity-relationship-diagram)
5. [Module Dependency Diagram](#5-module-dependency-diagram)
6. [Navigation Structure](#6-navigation-structure)
7. [Information Architecture](#7-information-architecture)
8. [User Journeys by Role](#8-user-journeys-by-role)
9. [API Specification](#9-api-specification)
10. [Backend Architecture](#10-backend-architecture)
11. [Frontend Architecture](#11-frontend-architecture)
12. [Flutter Screen Inventory](#12-flutter-screen-inventory)
13. [React Admin Panel Inventory](#13-react-admin-panel-inventory)
14. [Permission Matrix](#14-permission-matrix)
15. [Feature Flags](#15-feature-flags)
16. [Notification Flow](#16-notification-flow)
17. [Fee Workflow](#17-fee-workflow)
18. [Admission Workflow](#18-admission-workflow)
19. [Attendance Workflow](#19-attendance-workflow)
20. [Examination Workflow](#20-examination-workflow)
21. [Result Processing Workflow](#21-result-processing-workflow)
22. [Deployment Architecture](#22-deployment-architecture)
23. [Security Architecture](#23-security-architecture)
24. [Testing Strategy](#24-testing-strategy)
25. [Migration Strategy](#25-migration-strategy)
26. [Production Rollout Plan](#26-production-rollout-plan)

---

## 1. Product Overview

**Apex School ERP** is a module within the existing Apex ecosystem that adds school management capabilities to the existing HRMS platform. It is NOT a separate application — it extends the existing multi-tenant architecture with education-specific entities while reusing authentication, RBAC, attendance, payroll, notifications, documents, and accounting.

### Key Principles
- **Single codebase**: Same backend, same frontend, same database
- **Single source of truth**: Teachers are employees, students are a new entity
- **Feature-flagged**: School modules hidden behind feature flags, invisible to non-school tenants
- **Multi-campus**: Supports school groups with multiple campuses
- **Premium UX**: Same Apex Design System, Material 3, dark mode, responsive

---

## 2. Reuse Strategy

### Modules REUSED Without Changes
| Module | How Reused |
|--------|------------|
| Authentication | Login, JWT, refresh tokens, password reset, MFA |
| RBAC | Core permission engine — add school-specific roles |
| Employee | Teachers, drivers, support staff are all employees |
| Payroll | Teacher salaries, staff salaries, no changes needed |
| Leave | Extend with student absence type |
| Documents | Student docs, certificates, marksheets |
| Notifications | SMS, email, push, WhatsApp |
| Audit Logs | No changes |
| Reports Engine | Add school report templates |
| Accounting (ApexBooks) | Fee collection, expenses, GST |
| Visitor Management | Gate pass, visitor logs |
| Assets | School assets, lab equipment |

### Modules EXTENDED
| Module | Extension |
|--------|-----------|
| Attendance Engine | Add student attendance types (daily, period-wise, bus) |
| RBAC | Add 12 school-specific roles |
| Organization | Add campus, building, floor, classroom, lab |
| Dashboard | Add education widgets |
| Feature Flags | Add 25+ school features |
| Holiday Calendar | Academic year integration |

### NEW Modules (School-Specific)
| Module | Purpose |
|--------|---------|
| Academic Year | Sessions, terms, promotion rules |
| Admissions | Inquiry → Application → Enrollment |
| Student Management | Student master, guardians, medical |
| Class Management | Grades, sections, houses |
| Subject Management | Subjects, electives, credits |
| Teacher Allocation | Subject-section-teacher mapping |
| Timetable | Period-wise schedule, substitution |
| Homework/Assignments | Create, submit, evaluate |
| Lesson Planning | Unit plans, progress tracking |
| Examinations | Exam types, hall tickets, seating |
| Report Cards | Templates, grades, PDF generation |
| Fees Management | Fee structure, collection, receipts |
| Transport | Routes, vehicles, GPS |
| Hostel | Rooms, mess, attendance |
| Library | Books, issue, return, fine |
| Communication | Circulars, parent portal |
| Events | Calendar, competitions |
| Medical | Health records, vaccination |
| Discipline | Incidents, counselling |
| Certificates | TC, bonafide, custom templates |

---

## 3. Database Schema

### Naming Convention
- All new tables use `TenantModel` base (tenant_id FK)
- UUID primary keys everywhere
- `created_at` and `updated_at` timestamps
- Snake_case for columns, plural for table names
- Indexes on all foreign keys and frequently queried columns

### 3.1 Academic Year & Structure

```sql
-- Academic Year / Session
CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,           -- "2025-2026"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT false,
    promotion_date DATE,
    status VARCHAR(20) DEFAULT 'planning', -- planning/active/closed/archived
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, name)
);

-- Terms / Semesters within an academic year
CREATE TABLE academic_terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,           -- "Term 1", "Semester 1"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Holiday calendar linked to academic year
CREATE TABLE school_holidays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    date DATE NOT NULL,
    type VARCHAR(30) DEFAULT 'holiday',  -- holiday/exam/vacation/event
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.2 Campus & Infrastructure

```sql
-- Campus (extends branches concept)
CREATE TABLE campuses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES branches(id),  -- link to existing branch
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(255),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, code)
);

CREATE TABLE buildings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    campus_id UUID NOT NULL REFERENCES campuses(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    floors INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    building_id UUID NOT NULL REFERENCES buildings(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    room_number VARCHAR(50),
    floor INTEGER DEFAULT 0,
    room_type VARCHAR(30) DEFAULT 'classroom', -- classroom/lab/library/office/hall/hostel
    capacity INTEGER DEFAULT 40,
    has_projector BOOLEAN DEFAULT false,
    has_ac BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.3 Class & Section Management

```sql
-- Grade / Class (e.g., "Class 1", "Grade 10")
CREATE TABLE grades (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,          -- "Class 10"
    code VARCHAR(20) NOT NULL,           -- "10"
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, code)
);

-- Section within a grade
CREATE TABLE sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    grade_id UUID NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,           -- "A", "B", "Science"
    capacity INTEGER DEFAULT 40,
    room_id UUID REFERENCES rooms(id),
    class_teacher_id UUID REFERENCES employees(id),  -- FK to HRMS employee
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, grade_id, name, academic_year_id)
);

-- Houses (for house system / sports)
CREATE TABLE houses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,          -- "Red House", "Shivaji House"
    code VARCHAR(20),
    color VARCHAR(20),
    house_master_id UUID REFERENCES employees(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.4 Student Management

```sql
-- Student Master
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    admission_number VARCHAR(50) NOT NULL,
    roll_number VARCHAR(20),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    middle_name VARCHAR(100),
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    blood_group VARCHAR(5),
    nationality VARCHAR(50) DEFAULT 'Indian',
    religion VARCHAR(50),
    caste VARCHAR(50),
    category VARCHAR(20),                -- General/OBC/SC/ST/EWS
    aadhaar_number VARCHAR(12),
    email VARCHAR(255),
    phone VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(100),
    pincode VARCHAR(10),
    photo_url VARCHAR(512),
    admission_date DATE NOT NULL,
    admission_grade_id UUID REFERENCES grades(id),
    current_grade_id UUID REFERENCES grades(id),
    current_section_id UUID REFERENCES sections(id),
    house_id UUID REFERENCES houses(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    status VARCHAR(20) DEFAULT 'active', -- active/transferred/graduated/dropped/expelled
    previous_school VARCHAR(255),
    previous_grade VARCHAR(50),
    transfer_certificate_number VARCHAR(100),
    medical_conditions TEXT,
    allergies TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    emergency_contact_relation VARCHAR(50),
    transport_route_id UUID,             -- FK added later
    hostel_room_id UUID,                 -- FK added later
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, admission_number)
);

-- Student-Guardian relationship (many-to-many)
CREATE TABLE student_guardians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL,            -- FK to guardians table
    relationship VARCHAR(30) NOT NULL,    -- father/mother/guardian/step-father/step-mother
    is_primary BOOLEAN DEFAULT false,
    is_emergency_contact BOOLEAN DEFAULT false,
    can_pickup BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(student_id, guardian_id, relationship)
);

-- Guardians / Parents
CREATE TABLE guardians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id),   -- for parent portal login
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    alternate_phone VARCHAR(20),
    occupation VARCHAR(100),
    workplace VARCHAR(255),
    annual_income DECIMAL(12, 2),
    education VARCHAR(100),
    address TEXT,
    photo_url VARCHAR(512),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Sibling links
CREATE TABLE student_siblings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    sibling_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(student_id, sibling_id)
);
```

### 3.5 Subject Management

```sql
-- Subjects
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) NOT NULL,
    subject_type VARCHAR(30) DEFAULT 'core', -- core/elective/practical/language/extracurricular
    department_id UUID REFERENCES departments(id),
    credits DECIMAL(4, 1) DEFAULT 0,
    max_marks INTEGER DEFAULT 100,
    pass_marks INTEGER DEFAULT 33,
    has_practical BOOLEAN DEFAULT false,
    practical_max_marks INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, code)
);

-- Subject-Grade mapping (which subjects in which grade)
CREATE TABLE grade_subjects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    grade_id UUID NOT NULL REFERENCES grades(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    is_compulsory BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(grade_id, subject_id, academic_year_id)
);

-- Teacher-Subject-Section allocation
CREATE TABLE teacher_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE, -- teacher
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    periods_per_week INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(employee_id, subject_id, section_id, academic_year_id)
);
```

### 3.6 Timetable

```sql
-- Period definitions
CREATE TABLE period_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(50) NOT NULL,           -- "Period 1", "Morning Break"
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    period_type VARCHAR(20) DEFAULT 'period', -- period/break/assembly/lunch
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Timetable entries
CREATE TABLE timetable_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    subject_id UUID REFERENCES subjects(id),
    employee_id UUID REFERENCES employees(id), -- teacher
    room_id UUID REFERENCES rooms(id),
    period_definition_id UUID NOT NULL REFERENCES period_definitions(id),
    day_of_week INTEGER NOT NULL,        -- 1=Monday, 7=Sunday
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, section_id, day_of_week, period_definition_id, academic_year_id)
);

-- Substitution management
CREATE TABLE substitutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    original_employee_id UUID NOT NULL REFERENCES employees(id),
    substitute_employee_id UUID NOT NULL REFERENCES employees(id),
    timetable_entry_id UUID NOT NULL REFERENCES timetable_entries(id),
    date DATE NOT NULL,
    reason VARCHAR(255),
    status VARCHAR(20) DEFAULT 'pending', -- pending/approved/rejected
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.7 Student Attendance (extends existing attendance engine)

```sql
-- Student attendance records
CREATE TABLE student_attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    status VARCHAR(20) NOT NULL,         -- present/absent/late/half-day/excused
    check_in_time TIME,
    check_out_time TIME,
    remarks VARCHAR(255),
    marked_by UUID REFERENCES employees(id),
    attendance_type VARCHAR(20) DEFAULT 'daily', -- daily/period/bus
    period_definition_id UUID REFERENCES period_definitions(id), -- for period-wise
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, student_id, date, attendance_type, period_definition_id)
);

-- Student attendance summary (materialized for performance)
CREATE TABLE student_attendance_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    month INTEGER NOT NULL,
    year INTEGER NOT NULL,
    total_days INTEGER DEFAULT 0,
    present_days INTEGER DEFAULT 0,
    absent_days INTEGER DEFAULT 0,
    late_days INTEGER DEFAULT 0,
    half_days INTEGER DEFAULT 0,
    excused_days INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, student_id, academic_year_id, month, year)
);
```

### 3.8 Homework & Assignments

```sql
CREATE TABLE homework (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id), -- teacher
    title VARCHAR(255) NOT NULL,
    description TEXT,
    due_date DATE NOT NULL,
    attachment_urls JSONB DEFAULT '[]',
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE homework_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    homework_id UUID NOT NULL REFERENCES homework(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    submitted_at TIMESTAMPTZ,
    attachment_urls JSONB DEFAULT '[]',
    remarks TEXT,
    marks DECIMAL(5, 2),
    grade VARCHAR(10),
    status VARCHAR(20) DEFAULT 'pending', -- pending/submitted/reviewed/late
    reviewed_by UUID REFERENCES employees(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(homework_id, student_id)
);

CREATE TABLE assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    section_id UUID NOT NULL REFERENCES sections(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assignment_type VARCHAR(30) DEFAULT 'online', -- online/offline/project
    max_marks DECIMAL(5, 2),
    rubric JSONB,
    due_date DATE NOT NULL,
    attachment_urls JSONB DEFAULT '[]',
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE assignment_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    submitted_at TIMESTAMPTZ,
    attachment_urls JSONB DEFAULT '[]',
    marks DECIMAL(5, 2),
    grade VARCHAR(10),
    feedback TEXT,
    status VARCHAR(20) DEFAULT 'pending',
    evaluated_by UUID REFERENCES employees(id),
    evaluated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(assignment_id, student_id)
);
```

### 3.9 Examinations

```sql
-- Exam types / categories
CREATE TABLE exam_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,          -- "Unit Test 1", "Mid-Term", "Final"
    code VARCHAR(30) NOT NULL,
    weightage DECIMAL(5, 2) DEFAULT 0,   -- percentage weightage in final grade
    exam_category VARCHAR(30) DEFAULT 'internal', -- internal/external/practical/unit/final
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, code)
);

-- Exam / Exam Event
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    exam_type_id UUID NOT NULL REFERENCES exam_types(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    academic_term_id UUID REFERENCES academic_terms(id),
    name VARCHAR(255) NOT NULL,          -- "Unit Test 1 - 2025-26"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) DEFAULT 'draft',  -- draft/scheduled/ongoing/completed/results_published
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Exam schedule (which subject, which date/time, which room)
CREATE TABLE exam_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    exam_id UUID NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
    subject_id UUID NOT NULL REFERENCES subjects(id),
    grade_id UUID NOT NULL REFERENCES grades(id),
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_marks INTEGER DEFAULT 100,
    pass_marks INTEGER DEFAULT 33,
    room_ids JSONB DEFAULT '[]',         -- assigned rooms
    invigilator_ids JSONB DEFAULT '[]',  -- assigned invigilators
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Student exam marks
CREATE TABLE exam_marks (
    id UUID PRIMARY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    exam_schedule_id UUID NOT NULL REFERENCES exam_schedules(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    marks_obtained DECIMAL(6, 2),
    practical_marks DECIMAL(6, 2),
    grade VARCHAR(10),                   -- A+, A, B+, B, C, D, F
    is_absent BOOLEAN DEFAULT false,
    is_exempted BOOLEAN DEFAULT false,
    remarks VARCHAR(255),
    entered_by UUID REFERENCES employees(id),
    verified_by UUID REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(exam_schedule_id, student_id)
);

-- Grading scale
CREATE TABLE grading_scales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    scale_type VARCHAR(20) DEFAULT 'percentage', -- percentage/grade/points
    is_default BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE grading_scale_details (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    grading_scale_id UUID NOT NULL REFERENCES grading_scales(id) ON DELETE CASCADE,
    grade VARCHAR(10) NOT NULL,
    min_percentage DECIMAL(5, 2) NOT NULL,
    max_percentage DECIMAL(5, 2) NOT NULL,
    gpa DECIMAL(3, 1),
    description VARCHAR(50),
    sort_order INTEGER DEFAULT 0
);
```

### 3.10 Fees Management

```sql
-- Fee categories
CREATE TABLE fee_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,          -- "Tuition Fee", "Transport Fee"
    code VARCHAR(30) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, code)
);

-- Fee structure (template)
CREATE TABLE fee_structures (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    grade_id UUID NOT NULL REFERENCES grades(id),
    fee_category_id UUID NOT NULL REFERENCES fee_categories(id),
    amount DECIMAL(12, 2) NOT NULL,
    frequency VARCHAR(20) DEFAULT 'monthly', -- monthly/quarterly/half-yearly/annual/one-time
    due_day INTEGER DEFAULT 10,          -- day of month when due
    is_mandatory BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, academic_year_id, grade_id, fee_category_id, frequency)
);

-- Student fee assignment (links student to their fee structure)
CREATE TABLE student_fees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    fee_structure_id UUID NOT NULL REFERENCES fee_structures(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    amount DECIMAL(12, 2) NOT NULL,
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    scholarship_amount DECIMAL(12, 2) DEFAULT 0,
    final_amount DECIMAL(12, 2) NOT NULL,
    due_date DATE,
    status VARCHAR(20) DEFAULT 'pending', -- pending/partial/paid/overdue/waived
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Fee collection (payments)
CREATE TABLE fee_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    student_fee_id UUID NOT NULL REFERENCES student_fees(id),
    amount DECIMAL(12, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(30) DEFAULT 'cash', -- cash/card/upi/cheque/neft/online
    reference_number VARCHAR(100),
    receipt_number VARCHAR(50),
    collected_by UUID REFERENCES employees(id),
    remarks TEXT,
    status VARCHAR(20) DEFAULT 'completed', -- completed/refunded/cancelled
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Late fee / fine rules
CREATE TABLE fee_fine_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    fee_category_id UUID NOT NULL REFERENCES fee_categories(id),
    days_after_due INTEGER NOT NULL,
    fine_type VARCHAR(20) DEFAULT 'fixed', -- fixed/percentage
    fine_amount DECIMAL(10, 2) NOT NULL,
    max_fine DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Scholarships / Discounts
CREATE TABLE scholarships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    scholarship_type VARCHAR(20) DEFAULT 'percentage', -- percentage/fixed
    value DECIMAL(10, 2) NOT NULL,
    max_amount DECIMAL(12, 2),
    applicable_fee_categories JSONB DEFAULT '[]', -- null = all
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE student_scholarships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    scholarship_id UUID NOT NULL REFERENCES scholarships(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.11 Transport

```sql
CREATE TABLE transport_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50),
    vehicle_number VARCHAR(20),
    vehicle_type VARCHAR(30),            -- bus/van/minibus
    capacity INTEGER DEFAULT 40,
    driver_id UUID REFERENCES employees(id),
    helper_id UUID REFERENCES employees(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE transport_stops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES transport_routes(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    sequence INTEGER NOT NULL,
    pickup_time TIME,
    drop_time TIME,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Student transport assignment
CREATE TABLE student_transport (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    route_id UUID NOT NULL REFERENCES transport_routes(id),
    stop_id UUID NOT NULL REFERENCES transport_stops(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    pickup_type VARCHAR(10) DEFAULT 'pickup', -- pickup/drop/both
    fee_amount DECIMAL(10, 2) DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.12 Hostel

```sql
CREATE TABLE hostels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    campus_id UUID REFERENCES campuses(id),
    name VARCHAR(255) NOT NULL,
    hostel_type VARCHAR(20) DEFAULT 'boys', -- boys/girls/staff
    warden_id UUID REFERENCES employees(id),
    capacity INTEGER DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE hostel_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    hostel_id UUID NOT NULL REFERENCES hostels(id) ON DELETE CASCADE,
    room_number VARCHAR(50) NOT NULL,
    floor INTEGER DEFAULT 0,
    room_type VARCHAR(20) DEFAULT 'dormitory', -- dormitory/single/double/triple/quadruple
    capacity INTEGER DEFAULT 4,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE hostel_allocations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    hostel_id UUID NOT NULL REFERENCES hostels(id),
    room_id UUID NOT NULL REFERENCES hostel_rooms(id),
    bed_number INTEGER,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(20) DEFAULT 'active', -- active/vacated/expelled
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.13 Library

```sql
CREATE TABLE library_books (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    isbn VARCHAR(20),
    title VARCHAR(500) NOT NULL,
    author VARCHAR(255),
    publisher VARCHAR(255),
    category VARCHAR(100),
    subject VARCHAR(100),
    edition VARCHAR(50),
    year_published INTEGER,
    total_copies INTEGER DEFAULT 1,
    available_copies INTEGER DEFAULT 1,
    shelf_location VARCHAR(50),
    barcode VARCHAR(50),
    price DECIMAL(10, 2),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE library_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    book_id UUID NOT NULL REFERENCES library_books(id) ON DELETE CASCADE,
    borrower_type VARCHAR(20) DEFAULT 'student', -- student/employee
    borrower_id UUID NOT NULL,           -- student_id or employee_id
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    fine_amount DECIMAL(10, 2) DEFAULT 0,
    fine_paid BOOLEAN DEFAULT false,
    issued_by UUID REFERENCES employees(id),
    returned_to UUID REFERENCES employees(id),
    status VARCHAR(20) DEFAULT 'issued', -- issued/returned/overdue/lost
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.14 Lesson Planning

```sql
CREATE TABLE lesson_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    employee_id UUID NOT NULL REFERENCES employees(id),
    section_id UUID NOT NULL REFERENCES sections(id),
    subject_id UUID NOT NULL REFERENCES subjects(id),
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    unit_number INTEGER,
    lesson_number INTEGER,
    planned_date DATE,
    actual_date DATE,
    duration_periods INTEGER DEFAULT 1,
    learning_objectives TEXT,
    teaching_methods TEXT,
    resources TEXT,
    homework TEXT,
    status VARCHAR(20) DEFAULT 'planned', -- planned/in_progress/completed/cancelled
    completion_percentage INTEGER DEFAULT 0,
    remarks TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.15 Events & Communication

```sql
CREATE TABLE school_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    event_type VARCHAR(30) DEFAULT 'general', -- sports/academic/cultural/ptm/holiday/general
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    venue VARCHAR(255),
    organizer_id UUID REFERENCES employees(id),
    target_audience JSONB DEFAULT '[]',  -- grades/sections/roles
    is_public BOOLEAN DEFAULT false,
    attachment_urls JSONB DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE circulars (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    circular_type VARCHAR(30) DEFAULT 'general', -- general/academic/fee/event/emergency
    target_audience JSONB DEFAULT '[]',
    attachment_urls JSONB DEFAULT '[]',
    published_at TIMESTAMPTZ,
    published_by UUID REFERENCES employees(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.16 Medical & Discipline

```sql
CREATE TABLE health_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    record_type VARCHAR(30) DEFAULT 'checkup', -- checkup/vaccination/illness/injury
    date DATE NOT NULL,
    description TEXT,
    doctor_name VARCHAR(255),
    medication TEXT,
    next_followup DATE,
    attachment_urls JSONB DEFAULT '[]',
    recorded_by UUID REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE discipline_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    incident_date DATE NOT NULL,
    incident_type VARCHAR(30) DEFAULT 'misconduct', -- misconduct/bullying/absenteeism/uniform/other
    severity VARCHAR(20) DEFAULT 'minor', -- minor/moderate/major/severe
    description TEXT NOT NULL,
    action_taken TEXT,
    reported_by UUID REFERENCES employees(id),
    witnessed_by UUID,
    parent_informed BOOLEAN DEFAULT false,
    parent_meeting_date DATE,
    status VARCHAR(20) DEFAULT 'open', -- open/in_review/resolved/escalated
    resolution TEXT,
    resolved_by UUID REFERENCES employees(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.17 Certificates

```sql
CREATE TABLE certificate_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    template_type VARCHAR(30) NOT NULL,  -- bonafide/transfer/conduct/character/study/custom
    template_html TEXT,
    template_json JSONB,                 -- structured template
    is_default BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE issued_certificates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    template_id UUID NOT NULL REFERENCES certificate_templates(id),
    certificate_number VARCHAR(50) NOT NULL,
    issue_date DATE NOT NULL,
    purpose VARCHAR(255),
    issued_by UUID REFERENCES employees(id),
    pdf_url VARCHAR(512),
    qr_code VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);
```

### 3.18 Admissions

```sql
CREATE TABLE admission_inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    student_name VARCHAR(255) NOT NULL,
    parent_name VARCHAR(255),
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    grade_applying VARCHAR(50),
    academic_year_id UUID REFERENCES academic_years(id),
    source VARCHAR(50),                  -- walk-in/website/referral/agent
    status VARCHAR(20) DEFAULT 'new',    -- new/contacted/visited/applied/admitted/rejected
    notes TEXT,
    assigned_to UUID REFERENCES employees(id),
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE admission_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    inquiry_id UUID REFERENCES admission_inquiries(id),
    application_number VARCHAR(50) NOT NULL,
    student_name VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender VARCHAR(10) NOT NULL,
    grade_applying VARCHAR(50) NOT NULL,
    parent_name VARCHAR(255) NOT NULL,
    parent_phone VARCHAR(20) NOT NULL,
    parent_email VARCHAR(255),
    previous_school VARCHAR(255),
    previous_grade VARCHAR(50),
    address TEXT,
    documents JSONB DEFAULT '[]',
    academic_year_id UUID NOT NULL REFERENCES academic_years(id),
    status VARCHAR(20) DEFAULT 'submitted', -- submitted/under_review/interview_scheduled/selected/rejected/enrolled
    interview_date TIMESTAMPTZ,
    interview_score DECIMAL(5, 2),
    remarks TEXT,
    reviewed_by UUID REFERENCES employees(id),
    reviewed_at TIMESTAMPTZ,
    student_id UUID REFERENCES students(id), -- set when enrolled
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(tenant_id, application_number)
);
```

---

## 4. Entity Relationship Diagram (Textual)

```
TENANT (1) ──────┬── CAMPUS (N) ──── BUILDING (N) ──── ROOM (N)
                 │
                 ├── ACADEMIC_YEAR (N) ──── TERM (N)
                 │        │
                 │        ├── GRADE (N) ──── SECTION (N) ──── STUDENT (N)
                 │        │                      │
                 │        │                      ├── TIMETABLE_ENTRY (N)
                 │        │                      ├── HOMEWORK (N)
                 │        │                      └── CLASS_TEACHER → EMPLOYEE
                 │        │
                 │        ├── SUBJECT (N) ──── GRADE_SUBJECT (N)
                 │        │                      │
                 │        │                      └── TEACHER_ALLOCATION (N) → EMPLOYEE
                 │        │
                 │        ├── EXAM (N) ──── EXAM_SCHEDULE (N) ──── EXAM_MARKS (N)
                 │        │
                 │        ├── FEE_STRUCTURE (N)
                 │        │
                 │        └── STUDENT_ATTENDANCE (N)
                 │
                 ├── EMPLOYEE (N) ← REUSES HRMS
                 │        │
                 │        ├── TEACHER_ALLOCATION (N)
                 │        ├── HOMEWORK (N)
                 │        ├── LESSON_PLAN (N)
                 │        └── TIMETABLE_ENTRY (N)
                 │
                 ├── STUDENT (N) ──── STUDENT_GUARDIAN (N) ──── GUARDIAN (N)
                 │        │
                 │        ├── STUDENT_ATTENDANCE (N)
                 │        ├── HOMEWORK_SUBMISSION (N)
                 │        ├── ASSIGNMENT_SUBMISSION (N)
                 │        ├── EXAM_MARKS (N)
                 │        ├── STUDENT_FEE (N) ──── FEE_PAYMENT (N)
                 │        ├── STUDENT_TRANSPORT (N)
                 │        ├── HOSTEL_ALLOCATION (N)
                 │        ├── LIBRARY_TRANSACTION (N)
                 │        ├── HEALTH_RECORD (N)
                 │        ├── DISCIPLINE_INCIDENT (N)
                 │        └── ISSUED_CERTIFICATE (N)
                 │
                 ├── TRANSPORT_ROUTE (N) ──── TRANSPORT_STOP (N)
                 │
                 ├── HOSTEL (N) ──── HOSTEL_ROOM (N)
                 │
                 ├── LIBRARY_BOOK (N) ──── LIBRARY_TRANSACTION (N)
                 │
                 ├── FEE_CATEGORY (N) ──── FEE_FINE_RULE (N)
                 │
                 ├── SCHOLARSHIP (N)
                 │
                 ├── EXAM_TYPE (N)
                 │
                 ├── GRADING_SCALE (N) ──── GRADING_SCALE_DETAIL (N)
                 │
                 ├── CERTIFICATE_TEMPLATE (N)
                 │
                 └── SCHOOL_EVENT (N), CIRCULAR (N)
```

---

## 5. Module Dependency Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     SHARED APEX PLATFORM                        │
│  Auth │ RBAC │ Employees │ Payroll │ Notifications │ Documents  │
│  Audit │ Accounting │ Reports │ Visitors │ Assets │ Leave       │
└───────────────────────────┬─────────────────────────────────────┘
                            │
┌───────────────────────────┴─────────────────────────────────────┐
│                    SCHOOL ERP CORE                               │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │ Academic Year │  │   Campus &   │  │    Class &   │           │
│  │ & Terms       │  │ Infrastructure│  │   Section    │           │
│  └──────┬───────┘  └──────────────┘  └──────┬───────┘           │
│         │                                     │                   │
│  ┌──────┴─────────────────────────────────────┴───────┐           │
│  │              Student Management                     │           │
│  │  (Admissions → Enrollment → Guardians → Status)     │           │
│  └──────┬──────────────────────────────────────────────┘           │
│         │                                                          │
│  ┌──────┴───────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Subject &  │  │  Timetable   │  │  Attendance  │           │
│  │  Allocation  │  │  Engine      │  │  (Students)  │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  Homework &  │  │  Lesson      │  │ Examination  │           │
│  │ Assignments  │  │  Planning    │  │ & Results    │           │
│  └──────────────┘  └──────────────┘  └──────┬───────┘           │
│                                              │                   │
│                                       ┌──────┴───────┐           │
│                                       │  Report Card │           │
│                                       └──────────────┘           │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │    Fees &    │  │  Transport   │  │   Hostel     │           │
│  │ Billing      │  │  Management  │  │  Management  │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Library    │  │  Events &    │  │ Medical &    │           │
│  │  Management  │  │ Circulars    │  │ Discipline   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────┐                                                │
│  │ Certificates │                                                │
│  └──────────────┘                                                │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. Navigation Structure

### Sidebar Menu (Teacher Role)
```
📚 Dashboard
👨‍🎓 Students
  ├── Student Directory
  ├── Admissions
  └── Attendance
📅 Academics
  ├── Timetable
  ├── Homework
  ├── Assignments
  ├── Lesson Plans
  └── Subjects
📝 Examinations
  ├── Exams
  ├── Marks Entry
  └── Report Cards
💰 Fees
  ├── Fee Collection
  ├── Pending Dues
  └── Receipts
🚌 Transport
📚 Library
🏫 Hostel
📢 Communication
  ├── Announcements
  ├── Circulars
  └── Events
📊 Reports
⚙️ Settings
  ├── Academic Year
  ├── Classes & Sections
  ├── Fee Structure
  ├── Grading Scale
  └── Certificate Templates
```

### Sidebar Menu (Parent Role)
```
🏠 Dashboard
👨‍👧 My Children
📅 Attendance
📝 Homework & Assignments
📊 Report Cards
💰 Fee History
📢 Circulars & Events
🏥 Health Records
💬 Communication
```

---

## 7. Information Architecture

### Data Hierarchy
```
Tenant (School)
  └── Academic Year (2025-2026)
       ├── Terms (Term 1, Term 2)
       ├── Grades (Class 1 ... Class 12)
       │    └── Sections (A, B, C)
       │         └── Students (40 per section)
       ├── Subjects (Math, Science, English...)
       │    └── Teacher Allocations
       ├── Exams (Unit Test 1, Mid-Term, Final)
       │    └── Exam Schedules
       │         └── Exam Marks
       ├── Fee Structures
       └── Timetables
```

---

## 8. User Journeys by Role

### Principal
1. Login → Dashboard (school overview: enrollment, attendance %, fee collection, upcoming exams)
2. View all classes and sections → drill into any class
3. Approve admission applications
4. View exam results and school performance analytics
5. Publish circulars and announcements
6. View teacher performance and workload
7. Manage school events calendar

### Teacher / Class Teacher
1. Login → Dashboard (my classes, today's schedule, pending homework reviews)
2. Mark student attendance (daily or period-wise)
3. Create homework and assignments for my subjects
4. Enter exam marks for my subjects
5. View my timetable and substitutions
6. Create lesson plans and track progress
7. View student profiles in my sections

### Accountant
1. Login → Dashboard (fee collection summary, pending dues, overdue)
2. Define fee structures per grade
3. Collect fee payments and generate receipts
4. View fee defaulters report
5. Process scholarships and discounts
6. Generate fee collection reports

### Parent
1. Login → Dashboard (child's attendance, upcoming fees, recent circulars)
2. View child's attendance calendar
3. View homework and assignments (with submission status)
4. View exam results and report cards
5. View fee history and pay online
6. View school circulars and events
7. Communicate with teachers

### Student (Senior)
1. Login → Dashboard (today's schedule, pending homework, attendance summary)
2. View timetable
3. Submit homework and assignments
4. View exam results
5. View library books issued
6. View fee status

---

## 9. API Specification

### Base URL
`/api/v1/school/`

### Endpoints

#### Academic Year
| Method | Path | Description |
|--------|------|-------------|
| GET | `/academic-years` | List academic years |
| POST | `/academic-years` | Create academic year |
| PUT | `/academic-years/{id}` | Update academic year |
| POST | `/academic-years/{id}/set-current` | Set as current year |
| POST | `/academic-years/{id}/close` | Close academic year |
| GET | `/academic-years/{id}/terms` | List terms |
| POST | `/academic-years/{id}/terms` | Create term |

#### Campus & Infrastructure
| Method | Path | Description |
|--------|------|-------------|
| GET | `/campuses` | List campuses |
| POST | `/campuses` | Create campus |
| PUT | `/campuses/{id}` | Update campus |
| GET | `/campuses/{id}/buildings` | List buildings |
| POST | `/campuses/{id}/buildings` | Create building |
| GET | `/buildings/{id}/rooms` | List rooms |
| POST | `/buildings/{id}/rooms` | Create room |

#### Classes & Sections
| Method | Path | Description |
|--------|------|-------------|
| GET | `/grades` | List grades |
| POST | `/grades` | Create grade |
| PUT | `/grades/{id}` | Update grade |
| GET | `/grades/{id}/sections` | List sections |
| POST | `/grades/{id}/sections` | Create section |
| PUT | `/sections/{id}` | Update section |
| GET | `/sections/{id}/students` | List students in section |

#### Students
| Method | Path | Description |
|--------|------|-------------|
| GET | `/students` | List students (paginated, filterable) |
| POST | `/students` | Enroll student |
| GET | `/students/{id}` | Student detail |
| PUT | `/students/{id}` | Update student |
| POST | `/students/{id}/promote` | Promote to next grade |
| POST | `/students/{id}/transfer` | Transfer to another section |
| POST | `/students/{id}/graduate` | Mark as graduated |
| POST | `/students/{id}/dropout` | Mark as dropped out |
| GET | `/students/{id}/guardians` | List guardians |
| POST | `/students/{id}/guardians` | Add guardian |
| GET | `/students/{id}/siblings` | List siblings |

#### Guardians
| Method | Path | Description |
|--------|------|-------------|
| GET | `/guardians` | List guardians |
| POST | `/guardians` | Create guardian |
| PUT | `/guardians/{id}` | Update guardian |
| POST | `/guardians/{id}/create-login` | Create parent portal login |

#### Subjects & Allocation
| Method | Path | Description |
|--------|------|-------------|
| GET | `/subjects` | List subjects |
| POST | `/subjects` | Create subject |
| PUT | `/subjects/{id}` | Update subject |
| GET | `/grades/{id}/subjects` | Subjects for a grade |
| POST | `/grades/{id}/subjects` | Assign subjects to grade |
| GET | `/teacher-allocations` | List allocations |
| POST | `/teacher-allocations` | Create allocation |

#### Timetable
| Method | Path | Description |
|--------|------|-------------|
| GET | `/period-definitions` | List periods |
| POST | `/period-definitions` | Create period |
| GET | `/timetable/{section_id}` | Get section timetable |
| POST | `/timetable/{section_id}` | Set timetable entries |
| GET | `/timetable/teacher/{employee_id}` | Teacher timetable |
| POST | `/substitutions` | Create substitution |
| GET | `/substitutions` | List substitutions |

#### Student Attendance
| Method | Path | Description |
|--------|------|-------------|
| POST | `/student-attendance/mark` | Mark attendance |
| POST | `/student-attendance/bulk-mark` | Bulk mark for section |
| GET | `/student-attendance` | Get attendance records |
| GET | `/student-attendance/summary/{student_id}` | Student summary |
| GET | `/student-attendance/daily-summary` | Daily summary |

#### Homework & Assignments
| Method | Path | Description |
|--------|------|-------------|
| GET | `/homework` | List homework |
| POST | `/homework` | Create homework |
| PUT | `/homework/{id}` | Update homework |
| GET | `/homework/{id}/submissions` | List submissions |
| POST | `/homework/{id}/submit` | Student submits |
| PUT | `/homework/submissions/{id}/review` | Teacher reviews |
| GET | `/assignments` | List assignments |
| POST | `/assignments` | Create assignment |
| POST | `/assignments/{id}/submit` | Student submits |
| PUT | `/assignments/submissions/{id}/evaluate` | Teacher evaluates |

#### Examinations
| Method | Path | Description |
|--------|------|-------------|
| GET | `/exam-types` | List exam types |
| POST | `/exam-types` | Create exam type |
| GET | `/exams` | List exams |
| POST | `/exams` | Create exam |
| PUT | `/exams/{id}` | Update exam |
| POST | `/exams/{id}/publish` | Publish results |
| GET | `/exams/{id}/schedules` | Exam schedules |
| POST | `/exams/{id}/schedules` | Create schedule |
| POST | `/exam-marks/enter` | Enter marks |
| POST | `/exam-marks/bulk-enter` | Bulk marks entry |
| GET | `/exam-marks/{exam_id}/{student_id}` | Student marks |
| GET | `/exam-marks/subject/{schedule_id}` | Subject marks |

#### Report Cards
| Method | Path | Description |
|--------|------|-------------|
| GET | `/report-cards/{student_id}/{exam_id}` | Generate report card |
| GET | `/report-cards/{student_id}/all` | All report cards |
| POST | `/report-cards/bulk-generate` | Bulk generate PDFs |
| GET | `/grading-scales` | List grading scales |
| POST | `/grading-scales` | Create grading scale |

#### Fees
| Method | Path | Description |
|--------|------|-------------|
| GET | `/fee-categories` | List categories |
| POST | `/fee-categories` | Create category |
| GET | `/fee-structures` | List structures |
| POST | `/fee-structures` | Create structure |
| POST | `/fee-structures/bulk-assign` | Assign to all students |
| GET | `/students/{id}/fees` | Student fee summary |
| POST | `/fee-payments` | Record payment |
| GET | `/fee-payments` | List payments |
| GET | `/fee-reports/collection` | Collection report |
| GET | `/fee-reports/dues` | Pending dues |
| GET | `/fee-reports/defaulters` | Defaulters list |

#### Transport
| Method | Path | Description |
|--------|------|-------------|
| GET | `/transport/routes` | List routes |
| POST | `/transport/routes` | Create route |
| GET | `/transport/routes/{id}/stops` | List stops |
| POST | `/transport/students/{id}/assign` | Assign student to route |

#### Hostel
| Method | Path | Description |
|--------|------|-------------|
| GET | `/hostels` | List hostels |
| POST | `/hostels` | Create hostel |
| GET | `/hostels/{id}/rooms` | List rooms |
| POST | `/hostel-allocations` | Allocate student |

#### Library
| Method | Path | Description |
|--------|------|-------------|
| GET | `/library/books` | List books |
| POST | `/library/books` | Add book |
| POST | `/library/issue` | Issue book |
| POST | `/library/return` | Return book |
| GET | `/library/transactions` | List transactions |

#### Certificates
| Method | Path | Description |
|--------|------|-------------|
| GET | `/certificate-templates` | List templates |
| POST | `/certificate-templates` | Create template |
| POST | `/certificates/issue` | Issue certificate |
| GET | `/certificates/student/{id}` | Student certificates |

#### Communication
| Method | Path | Description |
|--------|------|-------------|
| GET | `/circulars` | List circulars |
| POST | `/circulars` | Publish circular |
| GET | `/events` | List events |
| POST | `/events` | Create event |

#### Medical & Discipline
| Method | Path | Description |
|--------|------|-------------|
| GET | `/students/{id}/health` | Health records |
| POST | `/students/{id}/health` | Add record |
| GET | `/discipline` | List incidents |
| POST | `/discipline` | Report incident |
| PUT | `/discipline/{id}/resolve` | Resolve incident |

#### Admissions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/admissions/inquiries` | List inquiries |
| POST | `/admissions/inquiries` | Create inquiry |
| GET | `/admissions/applications` | List applications |
| POST | `/admissions/applications` | Submit application |
| PUT | `/admissions/applications/{id}/review` | Review application |
| POST | `/admissions/applications/{id}/enroll` | Enroll (create student) |

#### Dashboard & Reports
| Method | Path | Description |
|--------|------|-------------|
| GET | `/school/dashboard/stats` | School dashboard stats |
| GET | `/school/dashboard/attendance-overview` | Attendance overview |
| GET | `/school/dashboard/fee-collection` | Fee collection summary |
| GET | `/school/reports/attendance` | Attendance report |
| GET | `/school/reports/fee-defaulters` | Fee defaulters |
| GET | `/school/reports/student-list` | Student list |
| GET | `/school/reports/teacher-workload` | Teacher workload |

---

## 10. Backend Architecture

### Directory Structure
```
backend/app/
├── api/v1/endpoints/school/
│   ├── __init__.py
│   ├── academic_year.py
│   ├── campus.py
│   ├── grade_section.py
│   ├── student.py
│   ├── guardian.py
│   ├── subject.py
│   ├── timetable.py
│   ├── student_attendance.py
│   ├── homework.py
│   ├── assignment.py
│   ├── examination.py
│   ├── report_card.py
│   ├── fee.py
│   ├── transport.py
│   ├── hostel.py
│   ├── library.py
│   ├── lesson_plan.py
│   ├── communication.py
│   ├── medical.py
│   ├── discipline.py
│   ├── certificate.py
│   ├── admission.py
│   └── school_dashboard.py
├── models/school/
│   ├── __init__.py
│   ├── academic_year.py
│   ├── campus.py
│   ├── grade.py
│   ├── section.py
│   ├── student.py
│   ├── guardian.py
│   ├── subject.py
│   ├── timetable.py
│   ├── student_attendance.py
│   ├── homework.py
│   ├── examination.py
│   ├── fee.py
│   ├── transport.py
│   ├── hostel.py
│   ├── library.py
│   ├── lesson_plan.py
│   ├── communication.py
│   ├── medical.py
│   ├── discipline.py
│   ├── certificate.py
│   └── admission.py
├── schemas/school/
│   └── (mirror of models)
├── services/school/
│   ├── academic_year.py
│   ├── student.py
│   ├── attendance.py      # extends existing
│   ├── examination.py
│   ├── report_card.py
│   ├── fee.py
│   ├── admission.py
│   └── promotion.py
└── core/
    └── school_constants.py
```

### Service Layer Pattern
Each module follows the existing pattern:
```
endpoint → validates (Pydantic schema) → delegates to service → service calls DB
```

---

## 11. Frontend Architecture

### Directory Structure
```
frontend/lib/
├── screens/school/
│   ├── dashboard/
│   │   └── school_dashboard_screen.dart
│   ├── students/
│   │   ├── student_list_screen.dart
│   │   ├── student_detail_screen.dart
│   │   ├── student_create_screen.dart
│   │   └── student_promote_screen.dart
│   ├── admissions/
│   │   ├── inquiry_list_screen.dart
│   │   ├── application_list_screen.dart
│   │   └── application_review_screen.dart
│   ├── academics/
│   │   ├── grade_section_screen.dart
│   │   ├── subject_screen.dart
│   │   ├── timetable_screen.dart
│   │   ├── homework_screen.dart
│   │   ├── assignment_screen.dart
│   │   └── lesson_plan_screen.dart
│   ├── attendance/
│   │   ├── student_attendance_screen.dart
│   │   └── attendance_mark_screen.dart
│   ├── examinations/
│   │   ├── exam_list_screen.dart
│   │   ├── marks_entry_screen.dart
│   │   └── report_card_screen.dart
│   ├── fees/
│   │   ├── fee_structure_screen.dart
│   │   ├── fee_collection_screen.dart
│   │   └── fee_report_screen.dart
│   ├── transport/
│   │   └── transport_screen.dart
│   ├── hostel/
│   │   └── hostel_screen.dart
│   ├── library/
│   │   └── library_screen.dart
│   ├── communication/
│   │   ├── circular_screen.dart
│   │   └── event_screen.dart
│   ├── medical/
│   │   └── health_record_screen.dart
│   ├── discipline/
│   │   └── discipline_screen.dart
│   ├── certificates/
│   │   └── certificate_screen.dart
│   └── settings/
│       ├── academic_year_screen.dart
│       ├── grading_scale_screen.dart
│       └── fee_category_screen.dart
├── models/school/
│   ├── student.dart
│   ├── guardian.dart
│   ├── grade.dart
│   ├── section.dart
│   ├── subject.dart
│   ├── timetable.dart
│   ├── homework.dart
│   ├── examination.dart
│   ├── fee.dart
│   ├── transport.dart
│   ├── hostel.dart
│   ├── library.dart
│   └── admission.dart
├── services/school/
│   ├── student_service.dart
│   ├── admission_service.dart
│   ├── attendance_service.dart  # extends existing
│   ├── examination_service.dart
│   ├── fee_service.dart
│   ├── timetable_service.dart
│   ├── homework_service.dart
│   ├── library_service.dart
│   └── transport_service.dart
└── providers/school/
    ├── student_provider.dart
    ├── attendance_provider.dart
    ├── examination_provider.dart
    └── fee_provider.dart
```

---

## 12. Flutter Screen Inventory

| # | Screen | Role Access | Priority |
|---|--------|-------------|----------|
| 1 | School Dashboard | Principal, Teacher | P0 |
| 2 | Student List | All staff | P0 |
| 3 | Student Detail | All staff | P0 |
| 4 | Student Create/Edit | Office Admin | P0 |
| 5 | Admission Inquiry List | Office Admin | P0 |
| 6 | Application Review | Principal, Office | P0 |
| 7 | Grade & Section Management | Admin | P0 |
| 8 | Subject Management | Admin | P0 |
| 9 | Teacher Allocation | Admin | P0 |
| 10 | Timetable View | Teacher, Student | P0 |
| 11 | Timetable Builder | Admin | P0 |
| 12 | Student Attendance Mark | Class Teacher | P0 |
| 13 | Student Attendance Report | All staff | P0 |
| 14 | Homework Create | Teacher | P0 |
| 15 | Homework List (Student) | Student, Parent | P0 |
| 16 | Assignment Create | Teacher | P1 |
| 17 | Assignment Submit | Student | P1 |
| 18 | Exam List | Admin | P0 |
| 19 | Exam Schedule | Admin | P0 |
| 20 | Marks Entry | Teacher | P0 |
| 21 | Report Card View | Student, Parent | P0 |
| 22 | Fee Structure | Accountant | P0 |
| 23 | Fee Collection | Accountant | P0 |
| 24 | Fee Receipt | Accountant | P0 |
| 25 | Fee Reports | Accountant, Principal | P0 |
| 26 | Transport Routes | Transport Mgr | P1 |
| 27 | Hostel Management | Hostel Warden | P1 |
| 28 | Library Books | Librarian | P1 |
| 29 | Library Issue/Return | Librarian | P1 |
| 30 | Circular Create | Admin | P0 |
| 31 | Event Calendar | All | P1 |
| 32 | Health Records | Medical | P1 |
| 33 | Discipline Incidents | Admin | P1 |
| 34 | Certificate Issue | Office Admin | P1 |
| 35 | Academic Year Settings | Admin | P0 |
| 36 | Grading Scale Config | Admin | P0 |
| 37 | Lesson Plan | Teacher | P1 |
| 38 | Parent Dashboard | Parent | P0 |
| 39 | Student Dashboard | Student | P1 |
| 40 | School Reports | Principal | P0 |

---

## 13. React Admin Panel Inventory

The school module integrates into the existing Flutter web app. No separate React panel needed. All screens listed in section 12 serve as the admin panel.

---

## 14. Permission Matrix

| Permission | Super Admin | Principal | VP | Coordinator | Office Admin | Accountant | Teacher | Class Teacher | Librarian | Transport | Hostel Warden | Parent | Student |
|------------|:-----------:|:---------:|:--:|:-----------:|:------------:|:----------:|:-------:|:-------------:|:---------:|:---------:|:--------------:|:------:|:-------:|
| student.create | ✓ | ✓ | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| student.read | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | own | own |
| student.update | ✓ | ✓ | ✓ | ✓ | ✓ | - | - | partial | - | - | - | - | - |
| student.delete | ✓ | ✓ | - | - | - | - | - | - | - | - | - | - | - |
| attendance.mark | ✓ | ✓ | - | - | - | - | ✓ | ✓ | - | - | - | - | - |
| attendance.read | ✓ | ✓ | ✓ | ✓ | ✓ | - | own | own | - | - | - | own | own |
| exam.manage | ✓ | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - | - |
| marks.enter | ✓ | ✓ | - | - | - | - | own | own | - | - | - | - | - |
| marks.read | ✓ | ✓ | ✓ | ✓ | - | - | own | own | - | - | - | own | own |
| fee.manage | ✓ | ✓ | - | - | ✓ | ✓ | - | - | - | - | - | - | - |
| fee.collect | ✓ | - | - | - | ✓ | ✓ | - | - | - | - | - | - | - |
| fee.read | ✓ | ✓ | - | - | ✓ | ✓ | - | - | - | - | - | own | own |
| homework.create | ✓ | - | - | - | - | - | ✓ | ✓ | - | - | - | - | - |
| homework.read | ✓ | ✓ | ✓ | ✓ | - | - | own | own | - | - | - | own | own |
| library.manage | ✓ | - | - | - | - | - | - | - | ✓ | - | - | - | - |
| transport.manage | ✓ | - | - | - | - | - | - | - | - | ✓ | - | - | - |
| hostel.manage | ✓ | - | - | - | - | - | - | - | - | - | ✓ | - | - |
| admission.manage | ✓ | ✓ | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| report.read | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | partial | partial | partial | partial | partial | - | - |
| certificate.issue | ✓ | ✓ | - | - | ✓ | - | - | - | - | - | - | - | - |
| discipline.manage | ✓ | ✓ | ✓ | - | - | - | - | ✓ | - | - | - | - | - |
| circular.publish | ✓ | ✓ | ✓ | ✓ | ✓ | - | - | - | - | - | - | - | - |
| settings.manage | ✓ | ✓ | - | - | - | - | - | - | - | - | - | - | - |

---

## 15. Feature Flags

New feature flags to add to the existing `feature_gate.py`:

```python
SCHOOL_FEATURES = [
    # Core School
    {"name": "Student Management", "code": "student_management", "module": "school", "category": "School Core"},
    {"name": "Admissions", "code": "admissions", "module": "school", "category": "School Core"},
    {"name": "Academic Year", "code": "academic_year", "module": "school", "category": "School Core"},
    {"name": "Class Management", "code": "class_management", "module": "school", "category": "School Core"},
    {"name": "Subject Management", "code": "subject_management", "module": "school", "category": "School Core"},
    {"name": "Timetable", "code": "school_timetable", "module": "school", "category": "Academics"},
    {"name": "Homework", "code": "homework", "module": "school", "category": "Academics"},
    {"name": "Assignments", "code": "school_assignments", "module": "school", "category": "Academics"},
    {"name": "Lesson Planning", "code": "lesson_planning", "module": "school", "category": "Academics"},
    {"name": "Student Attendance", "code": "student_attendance", "module": "school", "category": "Academics"},
    {"name": "Examinations", "code": "examinations", "module": "school", "category": "Assessment"},
    {"name": "Report Cards", "code": "report_cards", "module": "school", "category": "Assessment"},
    {"name": "Grading System", "code": "grading_system", "module": "school", "category": "Assessment"},
    {"name": "Fee Management", "code": "fee_management", "module": "school", "category": "Finance"},
    {"name": "Scholarships", "code": "scholarships", "module": "school", "category": "Finance"},
    {"name": "Transport", "code": "school_transport", "module": "school", "category": "Operations"},
    {"name": "Hostel", "code": "school_hostel", "module": "school", "category": "Operations"},
    {"name": "Library", "code": "school_library", "module": "school", "category": "Operations"},
    {"name": "School Events", "code": "school_events", "module": "school", "category": "Communication"},
    {"name": "Circulars", "code": "school_circulars", "module": "school", "category": "Communication"},
    {"name": "Parent Portal", "code": "parent_portal", "module": "school", "category": "Communication"},
    {"name": "Medical Records", "code": "school_medical", "module": "school", "category": "Student Welfare"},
    {"name": "Discipline", "code": "school_discipline", "module": "school", "category": "Student Welfare"},
    {"name": "Certificates", "code": "school_certificates", "module": "school", "category": "Administration"},
]
```

---

## 16. Notification Flow

### Triggers
| Event | Recipients | Channel |
|-------|-----------|---------|
| Student absent | Parent | Push + SMS |
| Fee due reminder | Parent | Push + SMS + Email |
| Fee payment received | Parent | Push + Email |
| Homework assigned | Student + Parent | Push |
| Assignment due tomorrow | Student + Parent | Push |
| Exam schedule published | Student + Parent | Push + Email |
| Results published | Student + Parent | Push + Email |
| Circular published | All targeted | Push + Email |
| Event reminder | All targeted | Push |
| Late fee applied | Parent | Push + SMS |
| Discipline incident | Parent | Push + SMS + Email |
| Admission status change | Applicant | SMS + Email |
| Substitution assigned | Teacher | Push |

### Implementation
Reuse existing `notification_center.py` and `notification.py` service. Add school-specific notification types to the notification template system.

---

## 17. Fee Workflow

```
1. Admin creates Fee Categories (Tuition, Transport, Hostel, Exam, Library)
2. Admin creates Fee Structure per Grade per Academic Year
   - Amount, frequency (monthly/quarterly/annual), due day
3. System bulk-assigns fee structures to all enrolled students
   - Creates StudentFee records with calculated amounts
4. Admin can apply discounts/scholarships per student
5. System calculates late fees based on Fine Rules
6. Accountant collects payments
   - Records payment method, reference, receipt number
   - Updates StudentFee status (pending → partial → paid)
7. System generates receipts (PDF)
8. Dashboard shows collection summary, pending dues, defaulters
9. Reports: collection report, due report, defaulters list, class-wise summary
```

---

## 18. Admission Workflow

```
1. Inquiry (walk-in/website/referral)
   - Record student name, parent name, phone, grade applying
   - Assign to staff member for follow-up
   - Status: new → contacted → visited

2. Application
   - Parent fills application form (online or offline)
   - Upload documents (birth certificate, photos, previous school TC)
   - Status: submitted

3. Review
   - Admin reviews application and documents
   - Schedule interview/test if required
   - Status: under_review → interview_scheduled

4. Selection
   - Enter interview score
   - Mark as selected or rejected
   - Status: selected / rejected

5. Enrollment
   - On confirmation, system creates Student record
   - Generates admission number
   - Creates guardian records
   - Assigns to section
   - Status: enrolled
   - Student is now in the system
```

---

## 19. Attendance Workflow

```
1. Daily Attendance (Class Teacher)
   - Opens attendance screen for their section
   - Marks each student: Present / Absent / Late / Half-day / Excused
   - Bulk mark all as present, then toggle absent students
   - Saves → creates StudentAttendance records

2. Period-wise Attendance (Subject Teacher)
   - Teacher marks attendance for their period
   - System aggregates into daily summary

3. Bus Attendance (Transport)
   - RFID/QR scan at bus entry/exit
   - Records pickup and drop times

4. Parent Notification
   - If student marked absent, automatic SMS/push to parent
   - Daily summary email to parents (optional)

5. Analytics
   - Class-wise attendance percentage
   - Student attendance trends
   - Defaulters list (students below threshold)
   - Monthly/yearly reports
```

---

## 20. Examination Workflow

```
1. Setup
   - Create Exam Type (Unit Test, Mid-Term, Final)
   - Create Exam event with date range
   - Create Exam Schedule (subject × date × time × room)
   - Assign invigilators

2. Hall Ticket Generation (optional)
   - System generates hall tickets with exam schedule
   - Printable PDF

3. Conduct
   - Exams conducted as per schedule
   - Seating arrangement (manual or auto)

4. Marks Entry
   - Teachers enter marks for their subjects
   - Bulk entry via spreadsheet upload
   - Marks can be: obtained marks, grade, absent, exempted

5. Verification
   - HOD/Coordinator verifies marks
   - Lock marks (no further editing)

6. Result Processing
   - Calculate totals, percentages, grades
   - Apply grading scale
   - Calculate GPA/CGPA if applicable
   - Rank students (within class, within school)

7. Report Card Generation
   - Apply template
   - Fill in marks, grades, attendance, remarks
   - Generate PDF with digital signature
   - QR code for verification

8. Publication
   - Publish results
   - Parents/students can view in portal
   - SMS notification to parents
```

---

## 21. Result Processing Workflow

```
Input: Exam marks for all students in all subjects

Steps:
1. Fetch exam schedule (subjects, max marks, pass marks)
2. Fetch student marks for each subject
3. For each student:
   a. Calculate total marks obtained
   b. Calculate percentage = (total_obtained / total_max) × 100
   c. Apply grading scale:
      - 90-100% → A+ (GPA 10)
      - 80-89% → A (GPA 9)
      - 70-79% → B+ (GPA 8)
      - 60-69% → B (GPA 7)
      - 50-59% → C (GPA 6)
      - 40-49% → D (GPA 5)
      - <40% → F (GPA 0) — FAIL
   d. Check pass criteria:
      - Must pass each subject individually (≥ pass marks)
      - Must pass overall (≥ overall pass percentage)
   e. Calculate rank within section and grade
   f. Generate remarks based on performance

Output: Processed results with grades, ranks, pass/fail status
```

---

## 22. Deployment Architecture

### Shared with Existing Platform
- Same PostgreSQL database (school tables added via Alembic migration)
- Same Redis instance
- Same Docker Compose stack
- Same Nginx configuration
- Same Flutter web build

### New Components
- Celery tasks for:
  - Fee reminder notifications (daily)
  - Attendance summary aggregation (daily)
  - Report card generation (batch)
  - Bulk student promotion (annual)
  - Library overdue reminders (daily)

### Database Migration
```bash
# Single Alembic migration adding all school tables
alembic revision --autogenerate -m "add_school_erp_tables"
alembic upgrade head
```

---

## 23. Security Architecture

### Data Isolation
- All school tables have `tenant_id` FK (row-level isolation)
- School feature flags control module visibility
- RBAC permissions control action access

### Sensitive Data
- Student medical records: encrypted at rest
- Guardian PII: masked in logs
- Fee payment references: encrypted
- Health records: separate permission scope

### API Security
- All school endpoints require authentication
- Permission checks via `require_permissions` dependency
- Rate limiting on admission form submissions
- File upload validation (type, size) for documents

---

## 24. Testing Strategy

### Unit Tests
- Service layer tests for each school module
- Fee calculation tests (discounts, scholarships, late fees)
- Grade calculation tests (percentage, GPA, ranking)
- Attendance aggregation tests

### Integration Tests
- Admission → Student enrollment flow
- Fee structure → Collection → Receipt flow
- Exam → Marks → Report card flow
- Student promotion workflow

### E2E Tests
- Teacher marks attendance → Parent receives notification
- Parent pays fee → Receipt generated
- Admin creates exam → Teacher enters marks → Results published

---

## 25. Migration Strategy

### Phase 1: Schema (Week 1)
- Add all school tables via Alembic migration
- Seed default data (exam types, fee categories, grading scales)
- Add school feature flags

### Phase 2: Core Modules (Week 2-3)
- Academic year management
- Grade, section, subject management
- Student management (CRUD + guardians)
- Teacher allocation

### Phase 3: Academic Modules (Week 4-5)
- Timetable engine
- Student attendance
- Homework and assignments
- Lesson planning

### Phase 4: Assessment (Week 6-7)
- Examination system
- Marks entry
- Report card generation

### Phase 5: Finance (Week 8-9)
- Fee structure and collection
- Scholarships and discounts
- Fee reports

### Phase 6: Operations (Week 10-11)
- Transport management
- Hostel management
- Library management

### Phase 7: Communication & Welfare (Week 12)
- Circulars and events
- Medical records
- Discipline management
- Certificates

### Phase 8: Parent Portal (Week 13-14)
- Parent login and dashboard
- Student self-service portal
- Mobile app integration

---

## 26. Production Rollout Plan

### Pre-Launch
1. Feature flags set to OFF for all school features
2. Run migration on production database
3. Seed default data
4. Test with one pilot school

### Pilot School
1. Enable school features for pilot tenant
2. Import existing students via CSV
3. Set up academic year, grades, sections
4. Configure fee structures
5. Train staff (2-day workshop)
6. Run parallel with existing system for 2 weeks

### General Availability
1. Enable school features for all school tenants
2. Onboarding wizard for new school tenants
3. Documentation and video tutorials
4. Support team trained on school modules

### Monitoring
- Track feature adoption via analytics
- Monitor API performance for school endpoints
- Track error rates on fee payment processing
- Monitor parent portal usage

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| New database tables | 40+ |
| New API endpoints | 120+ |
| New Flutter screens | 40+ |
| New feature flags | 24 |
| New RBAC roles | 12 |
| Reused modules | 12 |
| New services | 15+ |
| New Celery tasks | 5+ |
| Estimated development | 14 weeks (phased) |
