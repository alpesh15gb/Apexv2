# Apex HRMS v1.0.0 — Known Limitations

**Date**: 2026-06-28
**Version**: 1.0.0

---

## Current Limitations

### 1. eSSL Biometric Device Integration
- **Limitation**: Requires real-time network connectivity to eSSL/eBioserver devices. No offline queue for punch logs when devices are unreachable.
- **Impact**: Attendance data gaps if network or devices go down during working hours.
- **Workaround**: Run manual sync when connectivity is restored. Monitor sync status via admin dashboard. Use the sync diagnostic script (`scripts/`) to troubleshoot.
- **Roadmap**: v1.1 — Add offline punch queue with automatic retry on reconnect.

### 2. Celery Beat Single-Instance
- **Limitation**: Celery Beat must run as a single instance. Running multiple instances causes duplicate scheduled task execution.
- **Impact**: Cannot horizontally scale the scheduler for high availability.
- **Workaround**: Use Docker Compose (single celery_beat container). Monitor with `docker compose logs celery_beat`.
- **Roadmap**: v1.2 — Evaluate Redbeat or similar distributed scheduler.

### 3. Flutter Web Bundle Size
- **Limitation**: Initial Flutter web bundle is ~5 MB. First-load time on slow connections may be noticeable.
- **Impact**: Slower initial page load on low-bandwidth networks.
- **Workaround**: Nginx gzip compression is enabled. Service worker caching reduces subsequent loads. Use CDN for static assets if serving geographically distributed users.
- **Roadmap**: v1.1 — Evaluate Flutter deferred loading and tree-shaking improvements.

### 4. Single-Database Multi-Tenancy
- **Limitation**: All tenants share a single PostgreSQL database with row-level `tenant_id` isolation. Not database-per-tenant.
- **Impact**: Noisy-neighbor risk at scale; database-level backup/restore affects all tenants.
- **Workaround**: Monitor query performance per tenant. Use database connection pooling (20 + 10 overflow). Consider read replicas for reporting workloads.
- **Roadmap**: v2.0 — Evaluate schema-per-tenant or database-per-tenant for enterprise customers.

### 5. API Documentation Exposure
- **Limitation**: OpenAPI docs (`/docs`, `/redoc`) are accessible in production.
- **Impact**: API surface is publicly visible; potential information disclosure.
- **Workaround**: Configure Nginx to restrict `/docs` and `/redoc` to trusted IP ranges. Disable entirely by setting `DOCS_URL=None` in FastAPI config.
- **Roadmap**: v1.1 — Add IP whitelist middleware for docs endpoints.

### 6. File Upload Validation
- **Limitation**: File upload validation primarily checks file extensions, not deep content-type inspection.
- **Impact**: Potentially malicious files could be uploaded with spoofed extensions.
- **Workaround**: Limit upload size via `MAX_UPLOAD_SIZE_MB` (default 10 MB). Scan uploaded files with external antivirus if handling untrusted input. Restrict allowed extensions in tenant settings.
- **Roadmap**: v1.1 — Add python-magic based MIME type validation.

### 7. WebSocket Scalability
- **Limitation**: WebSocket connections are stateful and tied to a single backend instance. No built-in horizontal scaling for WebSocket across multiple backend containers.
- **Impact**: Real-time notifications limited to single-backend capacity.
- **Workaround**: Use Redis pub/sub for cross-instance message broadcasting (partially implemented). Scale vertically for WebSocket-heavy workloads.
- **Roadmap**: v1.2 — Add Redis-backed WebSocket scaling with channels.

### 8. Reporting Performance
- **Limitation**: Large report generation (10,000+ records) may be slow due to synchronous query processing.
- **Impact**: Report generation can take 10-30 seconds for large datasets.
- **Workaround**: Use date range filters to limit data. Export in background via Celery for very large datasets.
- **Roadmap**: v1.1 — Add async report generation with progress tracking.

### 9. Email/SMS Delivery
- **Limitation**: Email and SMS delivery depends on external SMTP/SMS gateway configuration. No built-in retry or dead-letter queue for failed deliveries.
- **Impact**: Notifications may be silently lost if the external service is down.
- **Workaround**: Monitor SMTP/SMS gateway health externally. Configure alerts for delivery failures.
- **Roadmap**: v1.1 — Add retry queue and delivery status tracking.

### 10. No Offline Mode
- **Limitation**: Apex HRMS is entirely web-based and requires continuous network connectivity.
- **Impact**: Cannot be used in offline or low-connectivity environments.
- **Workaround**: None. This is an architectural limitation.
- **Roadmap**: v2.0 — Evaluate PWA capabilities for limited offline support.

---

## Future Roadmap

### v1.1 (Planned)
- Offline punch queue for eSSL devices
- Enhanced file upload validation (MIME type checking)
- IP whitelisting for API docs
- Async report generation with progress tracking
- Notification delivery retry queue
- Flutter deferred loading optimization

### v1.2 (Planned)
- Distributed Celery Beat scheduler (Redbeat)
- Redis-backed WebSocket horizontal scaling
- Advanced audit logging and compliance reports
- Bulk operations API for large data imports

### v2.0 (Future)
- Schema-per-tenant or database-per-tenant for enterprise
- PWA offline capabilities
- Mobile app (Flutter native)
- Advanced analytics and BI dashboard
- API versioning strategy

---

**Document prepared by**: MiMo Code Agent
**Date**: 2026-06-28
