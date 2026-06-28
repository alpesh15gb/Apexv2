# Apex HRMS v1.0 — Rollback Guide

**Date**: 2026-06-28
**Purpose**: Step-by-step procedure to roll back a failed deployment

---

## When to Roll Back

Roll back if any of the following occur after deployment:
- API returns 5xx errors for more than 5 minutes
- Authentication is broken (cannot log in)
- Data corruption detected
- Critical business module non-functional (attendance, payroll, leave)
- Database migration fails mid-way

---

## Pre-Rollback Checklist

- [ ] Identify the last known good version (git tag or commit hash)
- [ ] Confirm a database backup exists from before the deployment
- [ ] Notify stakeholders of the rollback
- [ ] Document the issue that triggered the rollback

---

## Step-by-Step Rollback

### Phase 1: Frontend Rollback

```bash
# Option A: If you have a backup of the previous build
sudo rm -rf /var/www/apexhrms/frontend/build/web
sudo cp -r /backups/frontend_build_web /var/www/apexhrms/frontend/build/web
sudo chown -R www-data:www-data /var/www/apexhrms

# Option B: Rebuild from a previous git commit
cd /opt/Apexv2
git checkout <previous-commit-hash>
cd frontend
flutter pub get
flutter build web --release
sudo rm -rf /var/www/apexhrms/frontend/build/web
sudo cp -r build/web /var/www/apexhrms/frontend/build/web
sudo chown -R www-data:www-data /var/www/apexhrms
git checkout main
```

### Phase 2: Backend Rollback

```bash
cd /opt/Apexv2

# 1. Checkout the previous version
git checkout <previous-tag-or-commit>

# 2. Rebuild and restart backend services
docker compose up -d --build backend celery_worker celery_beat

# 3. Verify services are running
docker compose ps
docker compose logs --tail=20 backend
```

### Phase 3: Database Rollback

> **WARNING**: Database rollback is the riskiest step. Always ensure you have a backup before proceeding.

#### If the migration is reversible:
```bash
# Check current migration state
docker compose exec -T backend alembic current

# View migration history
docker compose exec -T backend alembic history

# Downgrade to the previous revision
docker compose exec -T backend alembic downgrade <previous-revision-id>

# Verify downgrade
docker compose exec -T backend alembic current
```

#### Migration Reference (current chain):
| Revision | Description | Downgrade Target |
|----------|-------------|-----------------|
| `a1b2c3d4e5f6` | Add missing indexes | `f7a8b9c0d1e2` |
| `f7a8b9c0d1e2` | Add super admin tables | `34d53d38e2ec` |
| `34d53d38e2ec` | Add dedup index | `ba139397b281` |
| `ba139397b281` | Fix raw logs dedup | `a6dacfc268bc` |
| `a6dacfc268bc` | Add sync progress | `caaacd017b3e` |
| `caaacd017b3e` | Fix eSSL tenant FKs | `0ff14a92da4a` |
| `0ff14a92da4a` | Add eSSL tables | `3b6cf98d123b` |
| `3b6cf98d123b` | Initial schema | (base) |

#### If the migration is NOT reversible (or downgrade fails):
```bash
# 1. Stop all services
docker compose down

# 2. Restore database from backup
docker compose up -d postgres
sleep 10

# Drop and recreate the database
docker compose exec postgres psql -U apex -c "DROP DATABASE apex_db;"
docker compose exec postgres psql -U apex -c "CREATE DATABASE apex_db;"

# Restore from backup
gunzip -c /backups/apex_db_YYYYMMDD.sql.gz | docker compose exec -T postgres psql -U apex -d apex_db

# 3. Start all services
docker compose up -d
```

### Phase 4: Verify Rollback

```bash
# 1. Check all services are running
docker compose ps

# 2. Check backend health
curl http://127.0.0.1:8001/api/v1/health

# 3. Check Nginx
sudo nginx -t
curl -I https://next.apextime.in

# 4. Smoke test
# - Login works
# - Dashboard loads
# - Core modules respond

# 5. Check logs for errors
docker compose logs --tail=50 backend
docker compose logs --tail=50 celery_worker
sudo tail -20 /var/log/nginx/error.log
```

### Phase 5: Post-Rollback

```bash
# Return to main branch (code only, not database)
cd /opt/Apexv2
git checkout main

# Document the rollback
echo "Rollback performed on $(date). Reason: <description>" >> /opt/Apexv2/ROLLBACK_LOG.md
```

---

## Emergency: Complete System Restore

If the entire system needs to be restored from scratch:

```bash
# 1. Stop everything
cd /opt/Apexv2
docker compose down -v  # WARNING: -v removes volumes

# 2. Restore volumes from backup
docker volume create apexv2_apex_postgres_data
docker run --rm -v apexv2_apex_postgres_data:/data -v /backups:/backup alpine tar xzf /backup/postgres_data_YYYYMMDD.tar.gz -C /data

docker volume create apexv2_apex_redis_data
docker run --rm -v apexv2_apex_redis_data:/data -v /backups:/backup alpine tar xzf /backup/redis_data_YYYYMMDD.tar.gz -C /data

docker volume create apexv2_apex_uploads_data
docker run --rm -v apexv2_apex_uploads_data:/data -v /backups:/backup alpine tar xzf /backup/uploads_YYYYMMDD.tar.gz -C /data

# 3. Checkout known good version
git checkout <known-good-tag>

# 4. Start services
docker compose up -d

# 5. Verify
docker compose ps
curl http://127.0.0.1:8001/api/v1/health
```

---

## Rollback Time Estimates

| Phase | Estimated Time |
|-------|---------------|
| Frontend rollback | 2-5 minutes |
| Backend rollback | 3-8 minutes (build time) |
| Database downgrade | 1-5 minutes |
| Database restore from backup | 5-30 minutes (depends on DB size) |
| Verification | 5-10 minutes |
| **Total (simple rollback)** | **10-20 minutes** |
| **Total (full restore)** | **20-60 minutes** |

---

**Guide prepared by**: MiMo Code Agent
**Date**: 2026-06-28
