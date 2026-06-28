# Apex HRMS v1.0.0 — Release Notes

**Release Date**: 2026-06-28
**Version**: 1.0.0
**Codename**: Apex

---

## Product Overview

Apex HRMS is a multi-tenant, web-based Human Resource Management System supporting both corporate HRMS and school ERP workflows. Built with FastAPI (backend) and Flutter (frontend), it provides biometric integration, RBAC security, and modular feature flags for organizations of all sizes.

---

## Key Features

### Core HRMS
- Employee management with full lifecycle (onboarding to exit)
- Biometric attendance via eSSL devices (multi-location sync)
- Shift management with groups, rosters, and department-wise assignment
- Leave management with types, approvals, and balance tracking
- Payroll with salary structures, payslips, deductions, and benefits
- Recruitment pipeline (postings, applications, interviews, offers)
- Performance reviews, goals, feedback, and appraisal cycles
- Asset management, visitor management, and access control
- Real-time notifications via WebSocket (in-app, email, SMS)
- Reports and analytics dashboards
- Bulk CSV import/export for employees, attendance, and leave

### School ERP
- Academic year, grade, section, and subject management
- Student admission, profiles, and parent linking
- Homework, examinations, report cards, and fee management
- Transport, hostel, library, and timetable modules
- Communication (circulars, announcements, parent messaging)
- Medical records, discipline tracking, and certificate generation

### Platform
- Multi-tenant architecture with row-level isolation on 40+ tables
- RBAC security: 455 endpoints, 100% permission coverage
- 57 feature flags (33 core + 24 school) with enforcement
- Celery background tasks for async processing
- Docker Compose deployment (5 services)

---

## System Requirements

### Minimum
| Resource | Specification |
|----------|--------------|
| CPU | 2 vCPU |
| RAM | 4 GB |
| Storage | 40 GB SSD |
| OS | Ubuntu 24.04 LTS |
| Network | 100 Mbps |

### Recommended
| Resource | Specification |
|----------|--------------|
| CPU | 4 vCPU |
| RAM | 8 GB |
| Storage | 80 GB SSD |
| OS | Ubuntu 24.04 LTS |
| Network | 1 Gbps |

### Software Stack
| Component | Version |
|-----------|---------|
| Docker | 24.x+ |
| Docker Compose | v2.x |
| Nginx | 1.24+ |
| PostgreSQL | 16 |
| Redis | 7 |
| Python | 3.12 |
| Flutter | 3.x |

---

## Installation Instructions

See [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md) for full instructions.

**Quick Start**:
```bash
git clone <repository-url> /opt/Apexv2
cd /opt/Apexv2
cp .env.example .env  # Edit with production values
docker compose up -d --build
docker compose exec -T backend alembic upgrade head
```

---

## Known Issues

### Low Priority
1. **File upload validation** — MIME type validation uses extension checking; content-type sniffing recommended as enhancement
2. **API documentation exposure** — `/docs` and `/redoc` accessible in production; IP whitelisting recommended
3. **Celery Beat single-instance** — Running multiple instances causes duplicate task execution

### Limitations
1. **eSSL devices** — Requires network connectivity to biometric devices; no offline queue
2. **Flutter web bundle** — Large initial bundle size (~5 MB); uses cache-busting for updates
3. **Single-database multi-tenancy** — Row-level isolation, not database-per-tenant

See [KNOWN_LIMITATIONS.md](KNOWN_LIMITATIONS.md) for complete list and workarounds.

---

## Upgrade Notes

### From Development/Staging
```bash
# Backup
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > pre_upgrade_$(date +%Y%m%d).sql.gz

# Update
cd /opt/Apexv2
git pull origin main
docker compose up -d --build
docker compose exec -T backend alembic upgrade head

# Rebuild frontend
cd frontend && flutter pub get && flutter build web --release
sudo cp -r build/web /var/www/apexhrms/frontend/build/web
```

### Database Migrations
17 migrations from initial schema to final index optimization. All forward-compatible. See [ROLLBACK_GUIDE.md](ROLLBACK_GUIDE.md) for downgrade procedures.

### Breaking Changes
None. This is the initial release.

---

## Post-Release Tasks
- Monitor error rates for 24 hours
- Verify all integrations (eSSL, email, SMS)
- Run UAT with pilot customers
- Collect feedback on school ERP modules
- Schedule penetration testing
- Plan v1.1 feature backlog

---

**Release prepared by**: MiMo Code Agent
**Date**: 2026-06-28
