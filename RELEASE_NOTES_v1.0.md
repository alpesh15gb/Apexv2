# Apex HRMS v1.0 — Release Notes

**Release Date**: 2026-06-28
**Version**: 1.0.0
**Codename**: Apex

---

## Overview

Apex HRMS is a multi-tenant, web-based Human Resource Management System supporting both corporate HRMS and school ERP workflows. Built with FastAPI (backend) and Flutter (frontend), it provides biometric integration, RBAC security, and modular feature flags.

---

## Feature Summary

### Core HRMS Modules
- **Employee Management** — Full CRUD, profiles, documents, lifecycle (onboarding to exit)
- **Attendance** — Biometric (eSSL), manual, shift-based tracking with overtime/OD support
- **Shift Management** — Shifts, shift groups, rosters, department-wise shift assignment
- **Leave Management** — Leave types, requests, approvals, balance tracking
- **Payroll** — Salary structures, payslips, deductions, expense & benefits
- **Recruitment** — Job postings, applications, interview scheduling, offer management
- **Performance** — Reviews, goals, feedback, appraisal cycles
- **Asset Management** — Asset allocation, tracking, return management
- **Visitor Management** — Visitor registration, check-in/out, host notifications
- **Access Control** — Zone-based access, device-linked entry/exit
- **Notifications** — In-app, email, SMS notifications with real-time WebSocket delivery
- **Reports & Analytics** — Attendance, leave, payroll, headcount dashboards
- **Import/Export** — Bulk CSV import for employees, attendance, leave records

### School ERP Modules
- **Academic Year Management** — Year setup, terms, calendars
- **Grade & Section Management** — Classes, sections, subject assignment
- **Student Management** — Admission, profiles, parent linking
- **Student Attendance** — Class-wise daily attendance
- **Homework** — Assignment creation, submission, grading
- **Examinations** — Exam scheduling, marks entry, report cards
- **Fee Management** — Fee structures, collection, receipts, outstanding tracking
- **Transport** — Route management, vehicle tracking, student assignment
- **Hostel** — Room allocation, occupancy, visitor logs
- **Library** — Book catalog, issue/return, fine management
- **Timetable** — Period scheduling, teacher assignment
- **Communication** — Circulars, announcements, parent messaging
- **Medical** — Health records, incident tracking
- **Certificates** — TC, bonafide, custom certificate generation
- **Admission** — Application workflow, document verification

### Platform Features
- **Multi-Tenant Architecture** — Row-level tenant isolation on 40+ tables
- **RBAC Security** — 455 endpoints, 100% permission coverage, 57 feature flags
- **eSSL Biometric Integration** — Multi-location device sync, pull/push modes
- **Real-Time WebSocket** — Live dashboard updates, notifications
- **Celery Background Tasks** — Async processing for reports, sync, notifications
- **File Management** — Document uploads with tenant-scoped storage
- **Settings & Configuration** — Per-tenant settings, feature templates

### Infrastructure
- **Docker Compose** — 5-service stack (PostgreSQL, Redis, Backend, Celery Worker, Celery Beat)
- **Nginx Reverse Proxy** — Rate limiting, security headers, SSL termination, static file serving
- **Alembic Migrations** — 17-version migration chain with async PostgreSQL support
- **Automated Deployment** — `deploy.sh` for full VPS deployment

---

## Technical Specifications

| Component | Technology |
|-----------|-----------|
| Backend | Python 3.12, FastAPI, SQLAlchemy (async), Pydantic v2 |
| Frontend | Flutter 3.x (web, mobile, desktop) |
| Database | PostgreSQL 16 |
| Cache/Broker | Redis 7 |
| Task Queue | Celery 5.x with Redis broker |
| Auth | JWT (HS256), bcrypt, Fernet encryption |
| API | REST + WebSocket, OpenAPI 3.0 docs |
| Deployment | Docker Compose, Nginx, Let's Encrypt SSL |

---

## Security

- **455 API endpoints** audited and secured
- **100% RBAC coverage** — all protected endpoints enforce permissions
- **Tenant isolation** — verified with 12 automated tests
- **53 security tests** passing
- **69 regression tests** passing
- **Rate limiting** — 60 req/min API, 10 req/min auth
- **Account lockout** — after 5 failed login attempts
- **Token revocation** — Redis-based JWT blacklist

See `FINAL_PRODUCTION_SECURITY_REPORT.md` and `ENDPOINT_SECURITY_REPORT.md` for full details.

---

## Known Issues

### Low Priority
1. **File upload validation** — MIME type validation could be enhanced beyond extension checking
2. **API documentation** — `/docs` and `/redoc` are accessible in production; consider IP whitelisting
3. **Celery Beat** — Single-instance only; running multiple instances causes duplicate task execution

### Limitations
1. **eSSL devices** — Requires network connectivity to biometric devices; no offline queue
2. **Flutter web** — Large initial bundle size (~5 MB); uses cache-busting for updates
3. **Single-database** — Multi-tenant via row isolation, not database-per-tenant

---

## Upgrade Instructions

### Fresh Installation
Follow the deployment guide in `DEPLOYMENT_CHECKLIST.md`.

### Upgrading from Development/Staging
```bash
# 1. Backup database
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > pre_upgrade_$(date +%Y%m%d).sql.gz

# 2. Pull latest code
cd /opt/Apexv2
git pull origin main

# 3. Run migrations
docker compose up -d --build
docker compose exec -T backend alembic upgrade head

# 4. Rebuild frontend
cd frontend
flutter pub get
flutter build web --release
sudo cp -r build/web /var/www/apexhrms/frontend/build/web

# 5. Verify
curl https://next.apextime.in/api/v1/health
```

### Database Migrations
The release includes 17 migrations from initial schema to final index optimization. All migrations are forward-compatible. See `ROLLBACK_GUIDE.md` for downgrade procedures.

---

## Post-Release Tasks

- [ ] Monitor error rates for 24 hours
- [ ] Verify all integrations (eSSL, email, SMS)
- [ ] Run UAT with pilot customers
- [ ] Collect feedback on school ERP modules
- [ ] Schedule penetration testing
- [ ] Plan v1.1 feature backlog

---

## Contributors

- **Backend & Security**: MiMo Code Agent
- **Architecture**: Apex HRMS Team

---

**Release prepared by**: MiMo Code Agent
**Date**: 2026-06-28
