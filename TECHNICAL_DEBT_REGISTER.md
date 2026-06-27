# Apex HRMS — Technical Debt Register

## Critical (Fix Before GA)

| # | Issue | Effort | Impact | Dependencies | Sprint |
|---|-------|--------|--------|--------------|--------|
| 1 | 51 ForeignKey columns missing indexes | 2h | High - Seq scans on JOINs | None | v1.0.1 |
| 2 | No token revocation/blacklist | 4h | High - Stolen tokens valid until expiry | Redis | v1.0.1 |
| 3 | No file upload validation | 3h | High - Malicious uploads possible | None | v1.0.1 |
| 4 | Zero test coverage | 40h | Critical - No regression protection | None | v1.1 |
| 5 | No password complexity enforcement | 2h | High - Weak passwords allowed | None | v1.0.1 |
| 6 | No account lockout | 3h | High - Brute force possible | Redis | v1.0.1 |

## High (Fix in v1.1)

| # | Issue | Effort | Impact | Dependencies | Sprint |
|---|-------|--------|--------|--------------|--------|
| 7 | N+1 queries in list endpoints | 8h | Medium - Slow responses at scale | None | v1.1 |
| 8 | No response compression | 2h | Medium - Larger payloads | Nginx config | v1.1 |
| 9 | No database query monitoring | 4h | Medium - Can't identify slow queries | None | v1.1 |
| 10 | No CI/CD pipeline | 8h | High - Manual deployment risk | GitHub Actions | v1.1 |
| 11 | No API documentation | 4h | Medium - Developer experience | None | v1.1 |
| 12 | 16 modules have no unit tests | 24h | High - No regression protection | None | v1.1 |
| 13 | No backup automation | 4h | High - Data loss risk | Cron/pg_dump | v1.1 |

## Medium (Fix in v1.2)

| # | Issue | Effort | Impact | Dependencies | Sprint |
|---|-------|--------|--------|--------------|--------|
| 14 | No dark mode | 16h | Low - UX preference | None | v1.2 |
| 15 | No global search | 8h | Medium - Navigation friction | Elasticsearch | v1.2 |
| 16 | No PDF report generation | 8h | Medium - Report export limitation | WeasyPrint | v1.2 |
| 17 | No scheduled reports | 6h | Medium - Manual report generation | Celery | v1.2 |
| 18 | No webhook support | 6h | Medium - Integration limitation | None | v1.2 |
| 19 | No API key authentication | 4h | Medium - External integration | None | v1.2 |
| 20 | No event-driven architecture | 16h | Medium - Tight coupling | Redis Streams | v1.2 |

## Low (Backlog)

| # | Issue | Effort | Impact | Dependencies | Sprint |
|---|-------|--------|--------|--------------|--------|
| 21 | No keyboard shortcuts | 8h | Low - Power user feature | None | Backlog |
| 22 | No undo/redo | 16h | Low - UX enhancement | None | Backlog |
| 23 | No multi-currency support | 8h | Low - Niche requirement | None | Backlog |
| 24 | No white-labeling | 16h | Low - Premium feature | None | Backlog |
| 25 | No offline mode | 24h | Low - Mobile only | IndexedDB | Backlog |

---

## Summary

| Severity | Count | Total Effort |
|----------|-------|-------------|
| Critical | 6 | 54h |
| High | 7 | 54h |
| Medium | 7 | 66h |
| Low | 5 | 72h |
| **Total** | **25** | **246h** |
