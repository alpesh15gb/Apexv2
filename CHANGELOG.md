# Changelog

All notable changes to Apex HRMS are documented in this file.

Format based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [1.0.0] — 2026-06-28

### Features
- **T9 Critical Security** — Token revocation, JWT claims hardening, secrets management, high-severity vulnerability fixes (`a0478e8`)
- **T7 Complete RBAC** — 100% endpoint coverage, 455 routes protected, all reports secured (`9ea9af2`)
- **T6 Security Sprint** — Permission matrix, security audit, test suite, regression report (`ed2cac9`)
- **Parallel Sprint** — Performance optimizations, frontend polish, QA reports, DevOps documentation (`b5db690`)
- **Production Hardening** — Tenant templates, dashboard switching, sidebar filtering, tenant_type in auth (`8b806ad`)
- **Admin & Tenant Type** — Admin signout button, tenant type (corporate/school), feature filtering by tenant type (`4c82179`)
- **Phase 1 School ERP** — 40 models, 120+ endpoints, 24 feature flags (`806ba7b`)
- **Phase 2 School ERP** — 9 Flutter screens, sidebar navigation, command palette (`26588bb`)
- **Phase 3-7 School ERP** — Transport, hostel, library, timetable, communication, medical, discipline, certificates, admissions (`9b10742`)
- **Feature Flags Enforcement** — `require_feature` dependency on 18 gated modules (`c874a91`)
- **eSSL Biometric Integration** — Multi-location device sync, eBioserver SOAP/HTTP API, punch log parsing (`017cb8e`, `ea630a2`, `7755322`)
- **Sync Diagnostic Script** — Database diagnostic and sync troubleshooting tool (`7755322`)

### Bug Fixes
- **Frontend UI/UX Polish** — 100 design system violations fixed across 24 screens (`8bc044a`)
- **Superadmin Audit** — Tenant users endpoint, plan dialog, assign plan, audit filter, analytics link (`9809150`)
- **Superadmin Panel** — Add tenant form, fix feature toggle, fix analytics double-prefix (`e512ccc`)
- **Admin Typography** — Use ApexTypography design tokens (`6ba6f07`)
- **Route Fixes** — Route superuser/superadmin to admin dashboard after login (`3321389`, `e52d164`)
- **Attendance Date Filter** — Use `date_type` alias consistently, `from_date/to_date` parameters (`f2f620a`, `eed2fbb`)
- **Punch Time Handling** — Store punch times as-is without UTC conversion (`46751bf`)
- **Attendance Deduplication** — Deduplicate punches, validate time format, handle edge cases (`01079f7`)
- **Attendance Model** — Add `employee_name` and `employee_code` computed properties (`72814a2`)
- **eSSL Sync** — Use savepoints to prevent rollback destroying all raw logs (`7c2ec71`)
- **eSSL API** — Handle paginated responses and Pydantic model objects (`a300717`)
- **eBioserver Format** — Parse semicolon-delimited punch log format (`a3e0bf5`)
- **Table Creation** — Explicit model imports to ensure all tables created (`e65802b`)
- **Attendance Summary** — Missing employee_name/code, remove duplicate processor call (`3e2c8c8`)
- **Compilation Errors** — `_selected` rename, `ApexBadge` import and const (`60744f6`)

### Security
- **53/53 security tests** passing — 0 critical, 0 high, 0 medium findings
- **69/69 regression tests** passing
- **RBAC** — 455/455 endpoints protected (100% coverage)
- **Tenant Isolation** — Row-level `tenant_id` filtering on 40+ tables, verified with 12 automated tests
- **Rate Limiting** — 60 req/min API, 10 req/min auth via Nginx
- **Account Lockout** — After 5 failed login attempts
- **Token Revocation** — Redis-based JWT blacklist
- **UUID Primary Keys** — Prevents ID enumeration across all tables

### Performance
- **Database Indexes** — Missing indexes added for query optimization (`a1b2c3d4e5f6`)
- **Connection Pooling** — SQLAlchemy async pool (20 connections + 10 overflow)
- **Redis Caching** — Token blacklist, session data, Celery broker
- **Celery Workers** — Background processing for reports, sync, notifications
- **Flutter Web** — Release build optimization with cache-busting

---

## Migration History

| # | Revision | Description |
|---|----------|-------------|
| 1 | `3b6cf98d123b` | Initial schema |
| 2 | `0ff14a92da4a` | eSSL connector tables |
| 3 | `caaacd017b3e` | Fix eSSL tenant foreign keys |
| 4 | `a6dacfc268bc` | Add sync progress fields |
| 5 | `34d53d38e2ec` | Add dedup index |
| 6 | `ba139397b281` | Fix raw logs dedup constraint |
| 7 | `b1a2c3d4e5f6` | Add eSSL location |
| 8 | `c2d3e4f5a6b7` | Multi-location eSSL |
| 9 | `d3e4f5a6b7c8` | Add holidays |
| 10 | `e4f5a6b7c8d9` | Add categories & settings |
| 11 | `f5a6b7c8d9e0` | Add shift groups & rosters |
| 12 | `a6b7c8d9e0f1` | Add OD/OT work codes |
| 13 | `b7c8d9e0f1a2` | Add payroll |
| 14 | `c8d9e0f1a2b3` | Add core HR |
| 15 | `d9e0f1a2b3c4` | Add remaining features |
| 16 | `f7a8b9c0d1e2` | Add super admin tables |
| 17 | `a1b2c3d4e5f6` | Add missing indexes (HEAD) |
