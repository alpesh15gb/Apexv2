# Apex HRMS v1.1 Product Backlog

## Sprint 1 — Security Hardening (1 week)
- [ ] Add 51 missing database indexes
- [ ] Implement Redis-based token blacklist
- [ ] Add file upload validation (type, size, content)
- [ ] Implement password complexity enforcement
- [ ] Add account lockout after 5 failed attempts
- [ ] Add rate limiting per endpoint
- [ ] Add CSRF protection
- [ ] Security headers (HSTS, X-Frame-Options, CSP)

## Sprint 2 — Testing Foundation (2 weeks)
- [ ] Set up pytest + fixtures
- [ ] Unit tests for auth service
- [ ] Unit tests for employee service
- [ ] Unit tests for attendance service
- [ ] Unit tests for leave service
- [ ] Unit tests for payroll service
- [ ] Integration tests for all API endpoints
- [ ] CI/CD pipeline (GitHub Actions)

## Sprint 3 — Leave & Payroll Completion (1 week)
- [ ] Comp Off management
- [ ] Leave encashment
- [ ] Carry forward rules
- [ ] Multi-level approval workflow
- [ ] PF/ESI/PT calculation engine
- [ ] TDS/Form 16 generation
- [ ] Bank advice file generation
- [ ] Payroll locking mechanism

## Sprint 4 — Attendance Enhancement (1 week)
- [ ] GPS attendance (mobile)
- [ ] Geofencing
- [ ] WiFi-based attendance
- [ ] Attendance regularization workflow
- [ ] Missing punch auto-detection

## Sprint 5 — Performance & Optimization (1 week)
- [ ] Add response compression (gzip)
- [ ] Fix N+1 queries with eager loading
- [ ] Add query result caching
- [ ] Add database query monitoring
- [ ] Optimize Flutter bundle size
- [ ] Add CDN for static assets

## Sprint 6 — Documentation (1 week)
- [ ] API Reference (OpenAPI + examples)
- [ ] Admin Guide
- [ ] User Guide
- [ ] Deployment Guide
- [ ] Architecture Documentation
- [ ] Troubleshooting Guide

## Sprint 7 — Mobile App (4 weeks)
- [ ] Flutter mobile app (iOS + Android)
- [ ] Push notifications (FCM)
- [ ] Offline mode for ESS
- [ ] GPS attendance
- [ ] Camera integration
- [ ] Biometric authentication

## Sprint 8 — Advanced Features (2 weeks)
- [ ] PDF report generation
- [ ] Scheduled reports
- [ ] Custom report builder
- [ ] Webhook support
- [ ] API key authentication
- [ ] 360-degree feedback
- [ ] Career portal for recruitment

---

## Effort Estimate

| Sprint | Duration | Effort |
|--------|----------|--------|
| Security Hardening | 1 week | 40h |
| Testing Foundation | 2 weeks | 80h |
| Leave & Payroll | 1 week | 40h |
| Attendance | 1 week | 40h |
| Performance | 1 week | 40h |
| Documentation | 1 week | 40h |
| Mobile App | 4 weeks | 160h |
| Advanced Features | 2 weeks | 80h |
| **Total** | **14 weeks** | **520h** |
