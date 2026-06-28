# Admin Panel Architecture: Tenant Feature Assignment

## Current Design

### File
`frontend/lib/screens/admin/admin_tenant_detail_screen.dart` — `_FeaturesTab` (lines 398–497)

### Current Layout
The Features tab displays all features in a **flat, ungrouped list** with:
- A search text field and a category dropdown filter at the top
- Each row shows: feature name, category label, feature code, and a toggle `Switch`
- Features are filtered by `tenant_type` — school features (`module == 'school'`) only appear for school tenants
- Toggling a switch calls `PUT /admin/tenants/{id}/features` with `{ feature_codes: [code], enabled: bool }`

### Current Data Model

| Table | Key Columns |
|---|---|
| `feature_flags` | `id`, `name`, `code`, `module`, `category`, `sort_order`, `is_active` |
| `tenant_features` | `tenant_id`, `feature_id`, `is_enabled`, `enabled_at`, `enabled_by` |

The API returns features ordered by `(category, sort_order, name)`.

### Current Backend Templates (`tenant_templates.py`)

| Template | Features |
|---|---|
| **CORE_FEATURES** (all tenants) | `attendance`, `leave`, `shift`, `overtime`, `outdoor_duty`, `payroll`, `expense`, `tax`, `benefits`, `loans`, `travel`, `assets`, `documents`, `onboarding`, `exit_management`, `announcements`, `polls`, `visitor`, `access_control`, `biometric`, `device`, `reports`, `analytics`, `ess`, `notification_templates` |
| **CORPORATE_FEATURES** | `recruitment`, `performance` |
| **SCHOOL_FEATURES** | 24 features: `student_management` through `school_certificates` |

### Current Problems
1. **No visual grouping** — all 47 features appear as a flat list; admin must scan every row
2. **No distinction between always-on and optional** — core features look identical to optional ones; admin can accidentally disable critical features
3. **Category labels are too granular** — backend categories like "Core HR", "Finance", "HR Operations", "Security", "Integration", "Advanced", "Analytics", "Platform", "Employee", "Communication" create 10+ micro-groups that don't match the mental model
4. **Search is the only discovery mechanism** — without grouping, finding a specific feature requires typing or scrolling
5. **No "enable all" / "disable all" per group** — admin must toggle features one by one

---

## Proposed Grouped Design

### Feature Groups

#### Group 1: Core Features (Always Enabled)

These features are fundamental to every tenant. They are **always on** and their toggles are **locked in the ON position** with no user-accessible switch. Displayed with a lock icon and a "Always enabled" badge.

| Display Name | Feature Code |
|---|---|
| Dashboard | `reports` |
| Notifications | `notification_templates` |
| Documents | `documents` |
| Settings | `ess` |
| Reports | `reports` |
| Analytics | `analytics` |

> **Note:** The current backend `CORE_FEATURES` list has 25 items. The above 6 are the minimal "platform essentials" that should never be disabled. The remaining 19 current core features (attendance, leave, shift, payroll, etc.) move to the Corporate Modules group as optional toggles.

#### Group 2: Corporate Modules

Optional HR/ERP modules for corporate-type tenants. Each has a toggle switch. Group is visible for all tenant types but school-only features are hidden.

| Display Name | Feature Code | Backend Category |
|---|---|---|
| Employee Management | `onboarding` | HR Operations |
| Attendance & Shifts | `attendance`, `shift` | Core HR |
| Leave Management | `leave` | Core HR |
| Payroll | `payroll` | Finance |
| Recruitment | `recruitment` | HR Operations |
| Performance | `performance` | HR Operations |
| Assets | `assets` | HR Operations |
| Visitors | `visitor` | Security |
| eSSL Integration | `biometric`, `device` | Integration |

**Additional corporate features** (expandable sub-section):
- Overtime (`overtime`)
- Outdoor Duty (`outdoor_duty`)
- Expense Claims (`expense`)
- Tax Declarations (`tax`)
- Benefits (`benefits`)
- Loans (`loans`)
- Travel Requests (`travel`)
- Exit Management (`exit_management`)
- Announcements (`announcements`)
- Polls (`polls`)
- Access Control (`access_control`)
- GPS Attendance (`gps_attendance`)
- Face Recognition (`face_recognition`)
- Geo Fencing (`geo_fencing`)
- API Access (`api_access`)
- Webhooks (`webhooks`)
- Custom Branding (`custom_branding`)
- White Label (`white_label`)
- Chat (`chat`)
- Helpdesk (`helpdesk`)
- Employee Self Service (`ess`)

#### Group 3: School Modules

Visible only when `tenant_type == 'school'`. Each has a toggle switch.

| Display Name | Feature Code | Backend Category |
|---|---|---|
| Student Management | `student_management` | School Core |
| Admissions | `admissions` | School Core |
| Academic Year | `academic_year` | School Core |
| Classes & Subjects | `class_management`, `subject_management` | School Core |
| Timetable | `school_timetable` | Academics |
| Homework & Assignments | `homework`, `school_assignments` | Academics |
| Examinations | `examinations`, `report_cards`, `grading_system` | Assessment |
| Fee Management | `fee_management`, `scholarships` | Finance |
| Transport | `school_transport` | Operations |
| Hostel | `school_hostel` | Operations |
| Library | `school_library` | Operations |
| Communication | `school_events`, `school_circulars`, `parent_portal` | Communication |
| Medical & Discipline | `school_medical`, `school_discipline` | Student Welfare |
| Certificates | `school_certificates` | Administration |

---

## Feature Assignment UX

### Visual Layout

```
┌─────────────────────────────────────────────────────────────┐
│  [Search features...                          🔍]  [Filter▾]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ── Core Features ──────────────────────── Always enabled ──│
│  ┌─────────────────────────────────────────────────────────┐│
│  │ 🔒 Dashboard                              [● Always On] ││
│  │ 🔒 Notifications                          [● Always On] ││
│  │ 🔒 Documents                              [● Always On] ││
│  │ 🔒 Settings                               [● Always On] ││
│  │ 🔒 Reports                                [● Always On] ││
│  │ 🔒 Analytics                              [● Always On] ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ── Corporate Modules ──────────────── 8/28 enabled ────────│
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Employee Management               [━━━━━━━●] ON         ││
│  │ Attendance & Shifts               [━━━━━━━●] ON         ││
│  │ Leave Management                  [━━━━━━━●] ON         ││
│  │ Payroll                           [━━━━━━━●] ON         ││
│  │ Recruitment                       [━━━━━━━○] OFF        ││
│  │ Performance                       [━━━━━━━○] OFF        ││
│  │ Assets                            [━━━━━━━●] ON         ││
│  │ Visitors                          [━━━━━━━●] ON         ││
│  │ eSSL Integration                  [━━━━━━━○] OFF        ││
│  │                                                             ││
│  │ ▶ Show 19 more features...                                ││
│  └─────────────────────────────────────────────────────────┘│
│                                                             │
│  ── School Modules ──────────────────── 5/14 enabled ───────│
│  ┌─────────────────────────────────────────────────────────┐│
│  │ Student Management                [━━━━━━━●] ON         ││
│  │ Admissions                        [━━━━━━━●] ON         ││
│  │ Academic Year                     [━━━━━━━●] ON         ││
│  │ Classes & Subjects                [━━━━━━━●] ON         ││
│  │ Timetable                         [━━━━━━━●] ON         ││
│  │ Homework & Assignments            [━━━━━━━○] OFF        ││
│  │ Examinations                      [━━━━━━━○] OFF        ││
│  │ ...                                                         ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Interaction Patterns

#### 1. Group Header
- Shows group name, icon, and a summary badge: `"X/Y enabled"`
- Clicking the group header collapses/expands the feature list
- Each group is an expandable `ExpansionTile` or custom collapsible card

#### 2. Core Features Group
- No toggle switches — features are locked ON
- Each row shows a lock icon (🔒) and an "Always On" pill badge
- Visual distinction: muted background tint (e.g., `primary600.withOpacity(0.04)`)
- Tooltip on hover/tap: "Core features cannot be disabled"

#### 3. Corporate Modules Group
- Each row has a standard `Switch` toggle
- Primary modules shown by default (9 items from the table above)
- Remaining features behind a "Show N more features..." expand link
- Toggling sends the same `PUT /admin/tenants/{id}/features` API call

#### 4. School Modules Group
- Only visible when `tenant_type == 'school'`
- Same toggle behavior as Corporate Modules
- Primary modules shown by default (14 items)
- Sub-features (e.g., "Examinations" bundles `examinations` + `report_cards` + `grading_system`) toggled together as a unit

#### 5. Search
- Search filters across all visible groups simultaneously
- Matching features are highlighted; non-matching rows are hidden
- Group headers remain visible even if only one feature matches

#### 6. Category Filter Dropdown
- Replaced with group filter: "All Groups", "Core Features", "Corporate Modules", "School Modules"
- Selecting a group scrolls to and expands that group

### Bundle Toggle Behavior

Some display items map to **multiple backend feature codes**. When toggling a bundle:

| Display Item | Codes Toggled | Behavior |
|---|---|---|
| Attendance & Shifts | `attendance`, `shift` | Both enabled/disabled together |
| Classes & Subjects | `class_management`, `subject_management` | Both together |
| Homework & Assignments | `homework`, `school_assignments` | Both together |
| Examinations | `examinations`, `report_cards`, `grading_system` | All three together |
| Fee Management | `fee_management`, `scholarships` | Both together |
| Communication (School) | `school_events`, `school_circulars`, `parent_portal` | All three together |
| Medical & Discipline | `school_medical`, `school_discipline` | Both together |
| eSSL Integration | `biometric`, `device` | Both together |

The API call uses `feature_codes: [code1, code2, ...]` which already supports arrays.

---

## Toggle Behavior

### Enable Flow
1. Admin flips switch to ON
2. Frontend calls `PUT /admin/tenants/{id}/features` with `{ feature_codes: [...], enabled: true }`
3. Backend `FeatureGate.bulk_set_features()` iterates codes, creates/updates `TenantFeature` rows
4. Frontend reloads feature list via `GET /admin/tenants/{id}/features`
5. Group summary badge updates: "X/Y enabled"

### Disable Flow
1. Admin flips switch to OFF
2. Frontend shows confirmation dialog if the feature has dependent data (optional enhancement)
3. Same API call with `enabled: false`
4. Backend sets `is_enabled = false`, clears `enabled_at` and `enabled_by`
5. Frontend reloads and updates badge

### Bulk Operations
- **Enable all in group**: Group header gets a "..." menu with "Enable all" option
- **Disable all in group**: Same menu, "Disable all" — sends all codes in one API call
- Confirmation dialog for "Disable all" to prevent accidental mass-disable

### Edge Cases
| Scenario | Behavior |
|---|---|
| Core feature toggle attempt | Switch is disabled; tooltip explains why |
| API error on toggle | SnackBar error message; switch reverts to previous state |
| Concurrent admin changes | Full list reload after each toggle ensures consistency |
| Feature dependency (e.g., payroll needs attendance) | No hard dependency enforcement in UI; backend feature gate handles access |

---

## Implementation Notes

### Frontend Changes Required (`admin_tenant_detail_screen.dart`)

1. **Replace `_FeaturesTab`** with a new grouped implementation
2. **Data structure**: Define a `_FeatureGroup` model:
   ```dart
   class _FeatureGroup {
     final String title;
     final IconData icon;
     final bool alwaysEnabled;
     final bool visible;  // false for school groups on corporate tenants
     final List<_FeatureBundle> bundles;
   }
   class _FeatureBundle {
     final String displayName;
     final List<String> codes;
     final String description;
     bool get isEnabled;  // computed from all codes being enabled
   }
   ```
3. **Group definitions**: Hardcode the group/bundle mapping in the widget (matches the tables above)
4. **API**: No backend changes needed — existing `GET` and `PUT` endpoints support this layout
5. **Bundle toggle**: Map each display item to its list of codes; toggle sends all codes at once

### Backend Changes Required

**None.** The existing API supports:
- `GET /admin/tenants/{id}/features` — returns all features with `is_enabled` status
- `PUT /admin/tenants/{id}/features` — accepts `feature_codes: [str]` array and `enabled: bool`

The grouping and bundling logic lives entirely in the frontend.

### Optional Future Enhancements
1. **Feature dependency graph**: Backend could enforce that disabling "Attendance" also disables "Overtime", "GPS Attendance", etc.
2. **Audit trail**: Log which admin toggled which feature and when (already partially supported by `enabled_by` column)
3. **Plan-based constraints**: Features could be locked based on subscription plan (e.g., "White Label" only available on Enterprise plan)
4. **Feature presets**: Quick-apply templates like "Basic HR", "Full ERP", "School Standard"

---

## API Response Shape (Current)

```json
[
  {
    "id": "uuid",
    "name": "Attendance",
    "code": "attendance",
    "description": null,
    "module": "attendance",
    "category": "Core HR",
    "is_enabled": true
  },
  ...
]
```

The frontend groups this response by mapping `code` values to the group/bundle definitions defined above.
