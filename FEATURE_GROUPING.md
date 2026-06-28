# Feature Flag Grouping — Apex HRMS

Refactoring plan for the 58 feature flags defined in `backend/app/core/feature_gate.py` (lines 128–188).

## Current State

All 58 flags live in a flat `DEFAULT_FEATURES` list with categories spanning both HRMS and School ERP domains. There is no tenant-type separation — every tenant sees every flag.

## Proposed Grouping

### 1. Core Features (shared by all tenants)

Platform infrastructure and cross-domain capabilities available to both HRMS and School ERP tenants.

| Code | Name | Current Category | sort_order |
|------|------|-----------------|------------|
| `api_access` | API Access | Platform | 70 |
| `webhooks` | Webhooks | Platform | 71 |
| `custom_branding` | Custom Branding | Platform | 72 |
| `white_label` | White Label | Platform | 73 |
| `reports` | Reports | Analytics | 60 |
| `analytics` | Analytics | Analytics | 61 |
| `ess` | Employee Self Service | Employee | 80 |
| `chat` | Chat | Communication | 90 |
| `helpdesk` | Helpdesk | Communication | 91 |
| `notification_templates` | Notification Templates | Communication | 92 |
| `access_control` | Access Control | Security | 31 |
| `biometric` | Biometric Integration | Integration | 40 |
| `device` | Device Management | Integration | 41 |

**Rationale**: These features are tenant-agnostic. Reporting, analytics, API access, branding, communication, security, and device integration are needed regardless of whether the tenant runs HRMS or School ERP. `ess` is shared because all tenants have staff who need self-service portals.

**Count**: 13

---

### 2. Corporate Features (HRMS only)

Employee lifecycle, HR operations, and corporate-specific capabilities.

| Code | Name | Current Category | sort_order |
|------|------|-----------------|------------|
| `attendance` | Attendance | Core HR | 1 |
| `leave` | Leave Management | Core HR | 2 |
| `shift` | Shift Management | Core HR | 3 |
| `overtime` | Overtime | Core HR | 4 |
| `outdoor_duty` | Outdoor Duty | Core HR | 5 |
| `payroll` | Payroll | Finance | 10 |
| `expense` | Expense Claims | Finance | 11 |
| `tax` | Tax Declarations | Finance | 12 |
| `benefits` | Benefits | Finance | 13 |
| `loans` | Loans | Finance | 14 |
| `travel` | Travel Requests | HR Operations | 20 |
| `assets` | Company Assets | HR Operations | 21 |
| `documents` | Documents | HR Operations | 22 |
| `onboarding` | Onboarding | HR Operations | 23 |
| `exit_management` | Exit Management | HR Operations | 24 |
| `announcements` | Announcements | HR Operations | 25 |
| `polls` | Polls | HR Operations | 26 |
| `visitor` | Visitor Management | Security | 30 |
| `gps_attendance` | GPS Attendance | Advanced | 50 |
| `face_recognition` | Face Recognition | Advanced | 51 |
| `geo_fencing` | Geo Fencing | Advanced | 52 |

**Rationale**: These features are tied to employee lifecycle (hire-to-retire), corporate finance (payroll, tax, benefits, loans), and HR-specific operations (travel, assets, onboarding, exit). Attendance here refers to employee attendance — the school equivalent is `student_attendance`. Advanced attendance modes (GPS, face, geo-fence) are corporate field-force features.

**Count**: 21

---

### 3. School Features (School ERP only)

Student lifecycle, academics, assessment, and school-specific operations.

| Code | Name | Current Category | sort_order |
|------|------|-----------------|------------|
| `student_management` | Student Management | School Core | 100 |
| `admissions` | Admissions | School Core | 101 |
| `academic_year` | Academic Year | School Core | 102 |
| `class_management` | Class Management | School Core | 103 |
| `subject_management` | Subject Management | School Core | 104 |
| `school_timetable` | Timetable | Academics | 110 |
| `homework` | Homework | Academics | 111 |
| `school_assignments` | Assignments | Academics | 112 |
| `lesson_planning` | Lesson Planning | Academics | 113 |
| `student_attendance` | Student Attendance | Academics | 114 |
| `examinations` | Examinations | Assessment | 120 |
| `report_cards` | Report Cards | Assessment | 121 |
| `grading_system` | Grading System | Assessment | 122 |
| `fee_management` | Fee Management | Finance | 130 |
| `scholarships` | Scholarships | Finance | 131 |
| `school_transport` | Transport | Operations | 140 |
| `school_hostel` | Hostel | Operations | 141 |
| `school_library` | Library | Operations | 142 |
| `school_events` | School Events | Communication | 150 |
| `school_circulars` | Circulars | Communication | 151 |
| `parent_portal` | Parent Portal | Communication | 152 |
| `school_medical` | Medical Records | Student Welfare | 160 |
| `school_discipline` | Discipline | Student Welfare | 161 |
| `school_certificates` | Certificates | Administration | 170 |

**Rationale**: All 24 features are prefixed with `school_` or are school-domain-only (student_management, admissions, academic_year, class_management, subject_management, examinations, report_cards, grading_system, homework, lesson_planning). These have no equivalent in corporate HRMS.

**Count**: 24

---

## Recommended Implementation Changes

### Add `tenant_type` filter to `FeatureGate`

Add a `tenant_scope` field to `DEFAULT_FEATURES`:

```python
# Values: "all", "corporate", "school"
{"name": "Attendance", "code": "attendance", ..., "tenant_scope": "corporate"},
{"name": "API Access", "code": "api_access", ..., "tenant_scope": "all"},
{"name": "Student Management", "code": "student_management", ..., "tenant_scope": "school"},
```

### Modify `get_tenant_features` to filter by scope

```python
@staticmethod
async def get_tenant_features(db: AsyncSession, tenant_id: uuid.UUID, tenant_type: str = "corporate") -> list[dict]:
    stmt = (
        select(FeatureFlag, TenantFeature.is_enabled)
        .outerjoin(...)
        .where(
            FeatureFlag.is_active == True,
            FeatureFlag.tenant_scope.in_(["all", tenant_type]),
        )
        .order_by(FeatureFlag.category, FeatureFlag.sort_order, FeatureFlag.name)
    )
```

### Add `tenant_scope` column to `FeatureFlag` model

```python
# In app/models/feature.py
tenant_scope = Column(String(20), default="all", nullable=False)  # "all" | "corporate" | "school"
```

### Migration

- Add `tenant_scope` column with default `"all"`
- Update existing rows based on the grouping above
- Seed new features with correct scope

---

## Summary

| Group | Count | Tenant Type |
|-------|-------|-------------|
| Core (shared) | 13 | all |
| Corporate (HRMS) | 21 | corporate |
| School (ERP) | 24 | school |
| **Total** | **58** | |

### Category-to-Group Mapping

| Current Category | Flags | Group |
|-----------------|-------|-------|
| Core HR | 5 | Corporate |
| Finance (HRMS) | 5 | Corporate |
| HR Operations | 7 | Corporate |
| Security | 2 | 1 Corporate + 1 Core |
| Integration | 2 | Core |
| Advanced | 3 | Corporate |
| Analytics | 2 | Core |
| Platform | 4 | Core |
| Employee | 1 | Core |
| Communication (HRMS) | 3 | Core |
| School Core | 5 | School |
| Academics | 5 | School |
| Assessment | 3 | School |
| Finance (School) | 2 | School |
| Operations | 3 | School |
| Communication (School) | 3 | School |
| Student Welfare | 2 | School |
| Administration | 1 | School |
