# Apex HRMS v1.0.0 — Enterprise Gap Analysis

## Platform Statistics

| Metric | Count |
|--------|-------|
| Database Tables | 85 |
| API Routers | 49 |
| Endpoint Files | 50 |
| Flutter Screens | 89 |
| GoRoute Entries | 90 |
| Providers | 10 |
| Services | 14 |
| Models (Flutter) | 11 |
| Migrations | 16 (linear chain) |
| Auth-Protected Endpoints | 343 |
| Middleware Layers | 4 |

---

## Feature Matrix vs Enterprise HRMS

### Core HR

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Employee Directory | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Employee Lifecycle | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Org Structure | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | High | Manager hierarchy missing |
| Bulk Import | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Bulk Export | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Document Management | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | Medium | No versioning |
| Onboarding Wizard | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Exit Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Employee Self Service | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Company Setup Wizard | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |

### Attendance & Time

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Biometric Integration | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |
| Shift Management | ✅ | ✅ | ✅ | ✅ | 🟡 | ✅ | — | — |
| Shift Roster | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |
| Overtime Management | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |
| GPS Attendance | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | High | Mobile workforce |
| Geofencing | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Medium | Field staff |
| Face Recognition | ❌ | ✅ | 🟡 | ❌ | ❌ | ❌ | Low | Premium feature |
| Attendance Regularization | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Attendance Calendar | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |

### Leave Management

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Leave Types | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Leave Policies | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | High | No policy builder |
| Leave Calendar | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Comp Off | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | High | Common requirement |
| Leave Encashment | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Medium | Payroll integration |
| Carry Forward | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | High | Annual rollover |
| Sandwich Leave | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ | Low | Regional feature |
| Multi-level Approval | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | High | Only 2-level |

### Payroll

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Salary Structures | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Payroll Processing | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | Critical | Manual steps |
| Payslip Generation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| PF/ESI/PT | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | High | Indian statutory |
| TDS/Form 16 | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | High | Indian statutory |
| Loan Management | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |
| Bank Advice | ❌ | ✅ | ✅ | ✅ | ❌ | ✅ | Medium | Bulk transfer |
| Multi-currency | ❌ | ✅ | ❌ | ✅ | ✅ | ✅ | Low | Global companies |

### Recruitment

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Job Requisitions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Candidate Pipeline | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Interview Scheduling | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Offer Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Resume Parsing | ❌ | ✅ | ✅ | ✅ | 🟡 | ✅ | Medium | Time saver |
| Career Portal | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | High | Candidate experience |
| Email Templates | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | Medium | Communication |

### Performance

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Review Cycles | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Goals/OKRs | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| 360 Feedback | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | High | Modern standard |
| Competency Framework | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |
| Calibration | ❌ | ✅ | ✅ | ❌ | ❌ | ✅ | Medium | Fair ratings |
| Promotion Recommendations | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ | — | — |

### SaaS & Admin

| Feature | Apex | Darwinbox | Keka | Zoho | BambooHR | Workday | Priority | Impact |
|---------|------|-----------|------|------|----------|---------|----------|--------|
| Multi-tenant | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | — | — |
| Subscription Management | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Feature Flags | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | — | — |
| Tenant Analytics | ✅ | ✅ | ❌ | ✅ | ❌ | ✅ | — | — |
| Import/Export | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| Backup/Restore | 🟡 | ✅ | ✅ | ✅ | ✅ | ✅ | High | No automated backup |
| API Platform | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ | High | Integration need |
| White Labeling | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | Low | Premium feature |

---

## Summary

| Category | ✅ Complete | 🟡 Partial | ❌ Missing | 🚫 Not Required |
|----------|------------|-----------|-----------|-----------------|
| Core HR | 7 | 2 | 0 | 0 |
| Attendance | 5 | 0 | 3 | 0 |
| Leave | 3 | 1 | 4 | 0 |
| Payroll | 4 | 1 | 3 | 0 |
| Recruitment | 4 | 0 | 2 | 0 |
| Performance | 4 | 0 | 2 | 0 |
| SaaS & Admin | 5 | 1 | 2 | 0 |
| **Total** | **32** | **5** | **16** | **0** |

**Completion Rate: 59% complete, 9% partial, 30% missing, 2% not required**
