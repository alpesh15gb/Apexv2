# Apex HRMS v1.0.0 — Backup & Restore Guide

**Date**: 2026-06-28
**Version**: 1.0.0

---

## Backup Procedures

### Database Backup

#### Automated Daily Backup

Add to crontab (`crontab -e`):

```bash
# Daily compressed backup at 2:00 AM
0 2 * * * docker compose -f /opt/Apexv2/docker-compose.yml exec -T postgres pg_dump -U apex -d apex_db | gzip > /backups/apex_db_$(date +\%Y\%m\%d).sql.gz

# Retain last 30 days, delete older backups
0 3 * * * find /backups -name "apex_db_*.sql.gz" -mtime +30 -delete
```

#### Manual Database Backup

```bash
# Full backup (uncompressed)
docker compose exec -T postgres pg_dump -U apex -d apex_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Full backup (compressed — recommended)
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Backup with verbose logging
docker compose exec -T postgres pg_dump -U apex -d apex_db -v 2>backup_log.txt | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz
```

#### Pre-Deployment Backup

Always take a backup before deployments or upgrades:

```bash
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > pre_deploy_$(date +%Y%m%d_%H%M%S).sql.gz
```

### Volume Backups

#### PostgreSQL Data Volume

```bash
# Stop PostgreSQL to ensure consistency
docker compose stop postgres

# Backup the volume
docker run --rm \
  -v apexv2_apex_postgres_data:/data \
  -v /backups:/backup \
  alpine tar czf /backup/postgres_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# Restart PostgreSQL
docker compose start postgres
```

#### Redis Data Volume

```bash
# Stop Redis
docker compose stop redis

# Backup the volume
docker run --rm \
  -v apexv2_apex_redis_data:/data \
  -v /backups:/backup \
  alpine tar czf /backup/redis_data_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .

# Restart Redis
docker compose start redis
```

#### Uploads Volume

```bash
# No downtime needed for uploads
docker run --rm \
  -v apexv2_apex_uploads_data:/data \
  -v /backups:/backup \
  alpine tar czf /backup/uploads_$(date +%Y%m%d_%H%M%S).tar.gz -C /data .
```

### Full System Backup

```bash
#!/bin/bash
# full_backup.sh — Complete system backup

BACKUP_DIR="/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Starting full backup..."

# 1. Database
echo "Backing up database..."
docker compose exec -T postgres pg_dump -U apex -d apex_db | gzip > "$BACKUP_DIR/database.sql.gz"

# 2. Environment and config
echo "Backing up configuration..."
cp /opt/Apexv2/.env "$BACKUP_DIR/env.bak"
cp /opt/Apexv2/docker-compose.yml "$BACKUP_DIR/docker-compose.yml"
cp -r /opt/Apexv2/nginx/ "$BACKUP_DIR/nginx/"

# 3. Uploads
echo "Backing up uploads..."
docker run --rm \
  -v apexv2_apex_uploads_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/uploads.tar.gz -C /data .

# 4. Git state
echo "Recording git state..."
cd /opt/Apexv2
git log --oneline -5 > "$BACKUP_DIR/git_state.txt"
git rev-parse HEAD >> "$BACKUP_DIR/git_state.txt"

echo "Backup complete: $BACKUP_DIR"
ls -lh "$BACKUP_DIR"
```

### Off-Site Backup

#### Sync to Remote Server

```bash
# Add to crontab after daily backup
0 4 * * * rsync -avz /backups/ user@remote-server:/backups/apexhrms/
```

#### Sync to S3

```bash
# Install AWS CLI
apt install awscli

# Configure credentials
aws configure

# Sync backups
0 4 * * * aws s3 sync /backups/ s3://your-bucket/apexhrms/backups/ --storage-class STANDARD_IA
```

---

## Restore Procedures

### Database Restore

#### From Compressed Backup

```bash
# Stop backend services to prevent writes
docker compose stop backend celery_worker celery_beat

# Restore database
gunzip -c /backups/apex_db_YYYYMMDD.sql.gz | docker compose exec -T postgres psql -U apex -d apex_db

# Restart services
docker compose start backend celery_worker celery_beat
```

#### From Uncompressed Backup

```bash
# Stop backend services
docker compose stop backend celery_worker celery_beat

# Restore
docker compose exec -T postgres psql -U apex -d apex_db < /backups/backup_YYYYMMDD_HHMMSS.sql

# Restart services
docker compose start backend celery_worker celery_beat
```

#### Full Database Reset and Restore

Use this when the database is corrupted and cannot accept incremental restore:

```bash
# 1. Stop all services
docker compose down

# 2. Start only PostgreSQL
docker compose up -d postgres
sleep 10

# 3. Drop and recreate database
docker compose exec postgres psql -U apex -c "DROP DATABASE IF EXISTS apex_db;"
docker compose exec postgres psql -U apex -c "CREATE DATABASE apex_db;"

# 4. Restore from backup
gunzip -c /backups/apex_db_YYYYMMDD.sql.gz | docker compose exec -T postgres psql -U apex -d apex_db

# 5. Start all services
docker compose up -d

# 6. Verify
docker compose ps
curl http://127.0.0.1:8001/api/v1/health
```

### Volume Restore

#### PostgreSQL Volume

```bash
# Stop PostgreSQL
docker compose stop postgres

# Restore volume
docker run --rm \
  -v apexv2_apex_postgres_data:/data \
  -v /backups:/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/postgres_data_YYYYMMDD_HHMMSS.tar.gz -C /data"

# Start PostgreSQL
docker compose start postgres
```

#### Redis Volume

```bash
# Stop Redis
docker compose stop redis

# Restore volume
docker run --rm \
  -v apexv2_apex_redis_data:/data \
  -v /backups:/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/redis_data_YYYYMMDD_HHMMSS.tar.gz -C /data"

# Start Redis
docker compose start redis
```

#### Uploads Volume

```bash
docker run --rm \
  -v apexv2_apex_uploads_data:/data \
  -v /backups:/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/uploads_YYYYMMDD_HHMMSS.tar.gz -C /data"
```

### Full System Restore

```bash
#!/bin/bash
# full_restore.sh — Complete system restore from backup

BACKUP_DIR=$1  # Pass backup directory as argument

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 /backups/YYYYMMDD_HHMMSS"
  exit 1
fi

echo "Starting full restore from $BACKUP_DIR..."

# 1. Stop everything
cd /opt/Apexv2
docker compose down

# 2. Restore configuration
cp "$BACKUP_DIR/env.bak" /opt/Apexv2/.env

# 3. Restore volumes
echo "Restoring PostgreSQL volume..."
docker volume create apexv2_apex_postgres_data 2>/dev/null
docker run --rm \
  -v apexv2_apex_postgres_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/postgres_data_*.tar.gz -C /data" 2>/dev/null || true

# Try database restore if volume backup not available
if [ -f "$BACKUP_DIR/database.sql.gz" ]; then
  echo "Restoring database from SQL dump..."
  docker compose up -d postgres
  sleep 10
  docker compose exec postgres psql -U apex -c "DROP DATABASE IF EXISTS apex_db;"
  docker compose exec postgres psql -U apex -c "CREATE DATABASE apex_db;"
  gunzip -c "$BACKUP_DIR/database.sql.gz" | docker compose exec -T postgres psql -U apex -d apex_db
fi

echo "Restoring uploads..."
docker run --rm \
  -v apexv2_apex_uploads_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine sh -c "rm -rf /data/* && tar xzf /backup/uploads.tar.gz -C /data" 2>/dev/null || true

# 4. Start all services
echo "Starting services..."
docker compose up -d

# 5. Verify
sleep 15
docker compose ps
curl -s http://127.0.0.1:8001/api/v1/health || echo "WARNING: Backend health check failed"

echo "Restore complete."
```

---

## Verification

### After Database Restore

```bash
# 1. Check service status
docker compose ps

# 2. Verify database connectivity
docker compose exec postgres pg_isready -U apex -d apex_db

# 3. Check record counts
docker compose exec postgres psql -U apex -d apex_db -c "
  SELECT 'tenants' as tbl, count(*) FROM tenants
  UNION ALL SELECT 'users', count(*) FROM users
  UNION ALL SELECT 'employees', count(*) FROM employees;
"

# 4. Verify API health
curl http://127.0.0.1:8001/api/v1/health

# 5. Test login
curl -X POST http://127.0.0.1:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"your-password"}'

# 6. Check application logs
docker compose logs --tail=50 backend
```

### After Volume Restore

```bash
# Verify file counts in uploads
docker compose exec backend ls -la /app/uploads/ | wc -l

# Verify Redis data
docker compose exec redis redis-cli DBSIZE
```

### Backup Integrity Check

```bash
# Verify compressed backup is valid
gunzip -t /backups/apex_db_YYYYMMDD.sql.gz
echo $?  # 0 = valid

# Check backup contents
gunzip -c /backups/apex_db_YYYYMMDD.sql.gz | head -50

# Count INSERT statements (approximate record count)
gunzip -c /backups/apex_db_YYYYMMDD.sql.gz | grep -c "INSERT INTO"
```

---

## Backup Schedule Recommendations

| Backup Type | Frequency | Retention | Storage |
|-------------|-----------|-----------|---------|
| Database (compressed) | Daily at 2 AM | 30 days | Local + off-site |
| PostgreSQL volume | Weekly (Sunday 3 AM) | 4 weeks | Local + off-site |
| Redis volume | Weekly (Sunday 3 AM) | 4 weeks | Local |
| Uploads volume | Daily at 4 AM | 30 days | Local + off-site |
| Full system | Before each deployment | 90 days | Off-site |

### Disaster Recovery Objectives

| Metric | Target |
|--------|--------|
| Recovery Time Objective (RTO) | < 1 hour |
| Recovery Point Objective (RPO) | < 24 hours |
| Backup Verification | Monthly test restore |

---

**Guide prepared by**: MiMo Code Agent
**Date**: 2026-06-28
