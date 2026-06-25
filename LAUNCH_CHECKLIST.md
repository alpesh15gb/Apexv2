# Launch Checklist

**Date**: 2026-06-26  
**Target**: Pilot Customer Deployment

---

## Pre-Launch Checklist

### Environment Setup
- [ ] Set `SECRET_KEY` to cryptographically random 32+ char string
- [ ] Set `ENCRYPTION_KEY` via `Fernet.generate_key()`
- [ ] Set `DEBUG=False`
- [ ] Set `DATABASE_URL` to production PostgreSQL
- [ ] Set `REDIS_URL` to production Redis
- [ ] Configure `CORS_ORIGINS` for production domain
- [ ] Set `ACCESS_TOKEN_EXPIRE_MINUTES=30`
- [ ] Set `REFRESH_TOKEN_EXPIRE_DAYS=7`

### Database
- [ ] Run Alembic migrations: `alembic upgrade head`
- [ ] Verify all tables created
- [ ] Verify all indexes created
- [ ] Set up database backups (daily)
- [ ] Configure connection pooling (20 + 10 overflow)

### Redis
- [ ] Configure persistence (AOF or RDB)
- [ ] Set maxmemory policy (allkeys-lru)
- [ ] Configure password authentication

### SSL/TLS
- [ ] Configure SSL certificate in Nginx
- [ ] Redirect HTTP to HTTPS
- [ ] Set HSTS headers
- [ ] Configure TLS 1.2+ only

---

## Application Setup

### Backend
- [ ] Set `DEBUG=False`
- [ ] Configure structured logging (JSON format)
- [ ] Set up log rotation
- [ ] Configure health check endpoint
- [ ] Set up metrics endpoint (Prometheus)

### Frontend
- [ ] Build for production: `flutter build web`
- [ ] Configure base URL for API
- [ ] Enable tree shaking
- [ ] Configure CDN for static assets

### Celery
- [ ] Set `worker_concurrency=4`
- [ ] Set `task_acks_late=True`
- [ ] Set `worker_prefetch_multiplier=1`
- [ ] Configure task time limits
- [ ] Set up Celery Flower for monitoring

---

## eSSL Configuration

### Per-Tenant Setup
- [ ] Create eSSL server configuration
- [ ] Set correct timezone (matches devices)
- [ ] Test connection
- [ ] Run initial sync (off-peak hours)
- [ ] Verify employee mappings
- [ ] Verify device mappings
- [ ] Verify attendance processing

### Monitoring
- [ ] Set up sync failure alerts
- [ ] Monitor raw log backlog
- [ ] Monitor processing lag
- [ ] Monitor error rates

---

## Security

- [ ] Change all default passwords
- [ ] Rotate encryption keys
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Set up intrusion detection
- [ ] Configure rate limiting
- [ ] Enable CORS for production domain only

---

## Monitoring & Alerting

### Metrics to Monitor
- [ ] API response times (p50, p95, p99)
- [ ] Error rates (4xx, 5xx)
- [ ] Database connection pool usage
- [ ] Redis memory usage
- [ ] Celery queue depth
- [ ] Sync success/failure rates
- [ ] Raw log backlog size

### Alerts
- [ ] API error rate > 1%
- [ ] Response time p95 > 1s
- [ ] Database connections > 80%
- [ ] Redis memory > 80%
- [ ] Celery queue depth > 1000
- [ ] Sync failure consecutive > 3
- [ ] Raw log backlog > 10000

---

## Disaster Recovery

- [ ] Database backup verification
- [ ] Redis backup verification
- [ ] Application state recovery procedure
- [ ] Rollback procedure documented
- [ ] Runbook for common failures

---

## Post-Launch

- [ ] Verify all endpoints accessible
- [ ] Verify login/registration works
- [ ] Verify eSSL sync starts
- [ ] Verify attendance processing
- [ ] Verify reports generation
- [ ] Verify dashboard loads
- [ ] Monitor logs for 24 hours
- [ ] Run smoke tests

---

## Pilot Customer Onboarding

### Day 1
- [ ] Create tenant account
- [ ] Configure eSSL server
- [ ] Run initial sync
- [ ] Verify employee data
- [ ] Verify attendance data

### Day 2-7
- [ ] Monitor sync stability
- [ ] Verify reports accuracy
- [ ] Train HR team
- [ ] Collect feedback

### Week 2-4
- [ ] Address feedback
- [ ] Optimize performance
- [ ] Document lessons learned

---

## Support

- [ ] Document common issues
- [ ] Create FAQ
- [ ] Set up support channel
- [ ] Define SLA

---

## Sign-Off

| Role | Name | Date | Status |
|------|------|------|--------|
| Technical Lead | | | |
| QA Lead | | | |
| Security Lead | | | |
| Operations Lead | | | |
