# Apex HRMS v1.0.0 — Administrator Guide

**Date**: 2026-06-28
**Version**: 1.0.0

---

## Tenant Management

### Creating a Tenant

1. Log in as superadmin
2. Navigate to **Super Admin > Tenants**
3. Click **Add Tenant**
4. Fill in:
   - **Tenant Name**: Organization name
   - **Tenant Type**: `corporate` or `school`
   - **Subdomain**: Unique subdomain identifier
   - **Admin Email**: Primary admin contact
   - **Plan**: Select subscription plan
5. Click **Create**

The system automatically:
- Creates a tenant record with a unique `tenant_id`
- Assigns default feature flags based on tenant type
- Creates an admin user for the tenant
- Sets up default roles and permissions

### Managing Tenants

- **Edit Tenant**: Update name, type, plan, or status
- **Suspend Tenant**: Temporarily disable access (reversible)
- **Delete Tenant**: Permanently removes tenant and all associated data (irreversible)
- **Assign Plan**: Change subscription plan to enable/disable features
- **View Analytics**: Monitor tenant usage, user count, and activity

### Tenant Types

| Type | Available Modules |
|------|------------------|
| `corporate` | All 33 core HRMS modules |
| `school` | All 33 core + 24 school ERP modules |

### Tenant Isolation

All data is isolated at the row level via `tenant_id` on 40+ tables. Users can only access data belonging to their tenant. Cross-tenant access returns HTTP 403.

---

## User Management

### Creating Users

Users are created within a tenant context:

1. Log in as tenant admin
2. Navigate to **Admin > Users**
3. Click **Add User**
4. Fill in:
   - **Name**: Full name
   - **Email**: Login email (unique per tenant)
   - **Role**: Assign one or more roles
   - **Department**: Optional department assignment
5. Click **Create**

An invitation email is sent with a temporary password.

### User Roles

Roles are permission bundles. Default roles:

| Role | Description |
|------|-------------|
| `superadmin` | Full system access across all tenants |
| `admin` | Full access within a tenant |
| `hr_manager` | HR module access (employees, leave, payroll) |
| `manager` | Team-level access (attendance, leave approvals) |
| `employee` | Self-service access (profile, leave requests) |
| `teacher` | School-specific: academic modules |
| `student` | School-specific: limited self-service |

### Custom Roles

1. Navigate to **Admin > Roles**
2. Click **Create Role**
3. Select permissions from the permission matrix (455 endpoints)
4. Assign role to users

### Account Lockout

Accounts are locked after 5 consecutive failed login attempts. To unlock:
- Wait 15 minutes for automatic unlock, or
- Admin unlocks via **Admin > Users > [User] > Unlock Account**

---

## Feature Flags

### Overview

Apex HRMS uses 57 feature flags (33 core + 24 school) to control module visibility. Flags are enforced at the API level via `require_feature` dependency.

### Managing Feature Flags

1. Navigate to **Super Admin > Feature Flags**
2. View all flags grouped by category
3. Toggle flags per tenant or globally

### Flag Categories

| Category | Count | Examples |
|----------|-------|---------|
| Core HR | 8 | `employee_management`, `attendance`, `leave`, `payroll` |
| Recruitment | 4 | `job_postings`, `applications`, `interviews`, `offers` |
| Performance | 3 | `reviews`, `goals`, `appraisals` |
| Admin | 5 | `asset_management`, `visitor_management`, `access_control` |
| Reports | 6 | `attendance_reports`, `payroll_reports`, `headcount_analytics` |
| School | 24 | `academic_year`, `student_management`, `examinations`, `fees`, `transport`, `hostel`, `library`, `timetable` |

### Tenant Templates

Predefined feature flag templates for quick tenant setup:

- **Corporate Basic**: Core HR, attendance, leave, reports
- **Corporate Full**: All 33 core modules
- **School Basic**: Core HR + academic + student management
- **School Full**: All 57 modules

---

## Monitoring

### Health Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /api/v1/health` | Backend health check |
| `GET /health` (Nginx) | Full stack health |
| PostgreSQL `pg_isready` | Database connectivity |
| Redis `PING` | Cache/broker connectivity |

### Docker Health Checks

```bash
# Check all container status
docker compose ps

# View resource usage
docker stats --no-stream
```

### Log Monitoring

| Service | Command |
|---------|---------|
| Backend | `docker compose logs -f backend` |
| Celery Worker | `docker compose logs -f celery_worker` |
| Celery Beat | `docker compose logs -f celery_beat` |
| PostgreSQL | `docker compose logs -f postgres` |
| Redis | `docker compose logs -f redis` |
| Nginx Access | `tail -f /var/log/nginx/access.log` |
| Nginx Error | `tail -f /var/log/nginx/error.log` |

### Key Metrics

| Metric | Healthy | Warning | Critical |
|--------|---------|---------|----------|
| API Response Time | < 200ms | 200-500ms | > 500ms |
| Error Rate (5xx) | 0% | < 1% | > 1% |
| CPU Usage | < 60% | 60-80% | > 80% |
| Memory Usage | < 70% | 70-85% | > 85% |
| Disk Usage | < 70% | 70-80% | > 80% |
| DB Connections | < 60% | 60-80% | > 80% of pool |
| Celery Queue | < 50 | 50-100 | > 100 |

### Recommended Monitoring Stack

| Tool | Purpose |
|------|---------|
| Uptime Kuma | HTTP/TCP uptime monitoring |
| Prometheus + Grafana | Metrics collection and dashboards |
| pgAdmin / DBeaver | Database administration |
| Redis Commander | Redis inspection |

---

## Backup and Restore

See [BACKUP_RESTORE_GUIDE.md](BACKUP_RESTORE_GUIDE.md) for detailed procedures.

### Quick Reference

```bash
# Manual database backup
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore from backup
gunzip -c backup.sql.gz | docker compose exec -T postgres psql -U apex -d apex_db
```

### Automated Backups

Add to crontab (`crontab -e`):
```bash
# Daily backup at 2 AM, retain 30 days
0 2 * * * docker compose -f /opt/Apexv2/docker-compose.yml exec -T postgres pg_dump -U apex -d apex_db | gzip > /backups/apex_db_$(date +\%Y\%m\%d).sql.gz
0 3 * * * find /backups -name "apex_db_*.sql.gz" -mtime +30 -delete
```

---

## Common Admin Tasks

### Restart All Services
```bash
cd /opt/Apexv2
docker compose restart
```

### Restart Single Service
```bash
docker compose restart backend
```

### View Database Migrations
```bash
docker compose exec -T backend alembic current
docker compose exec -T backend alembic history
```

### Access Database Shell
```bash
docker compose exec postgres psql -U apex -d apex_db
```

### Access Redis Shell
```bash
docker compose exec redis redis-cli
```

### Clear Redis Cache
```bash
docker compose exec redis redis-cli FLUSHDB
```

### Update SSL Certificate
```bash
sudo certbot renew
sudo systemctl reload nginx
```

### View Disk Usage
```bash
df -h
du -sh /var/lib/docker/volumes/
docker system df
```

---

**Guide prepared by**: MiMo Code Agent
**Date**: 2026-06-28
