# Apex HRMS — Health Check & Monitoring Report

## Health Check Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `GET /api/v1/health` | GET | Backend API health status |
| `GET https://next.apextime.in` | GET | Frontend availability |
| `GET /api/v1/docs` | GET | Swagger UI (API docs) |

```bash
# Backend health
curl -s http://127.0.0.1:8001/api/v1/health

# Frontend availability
curl -sI https://next.apextime.in

# API docs
curl -s http://127.0.0.1:8001/api/v1/docs -o /dev/null -w "%{http_code}"
```

---

## Container Status Commands

```bash
# Overview
docker compose ps

# Detailed status with health
docker ps --filter "name=apex_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

# Individual health inspections
docker inspect --format='{{.State.Health.Status}}' apex_postgres
docker inspect --format='{{.State.Health.Status}}' apex_redis
docker inspect --format='{{.State.Status}}' apex_backend
docker inspect --format='{{.State.Status}}' apex_celery_worker
docker inspect --format='{{.State.Status}}' apex_celery_beat

# Resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" \
  apex_postgres apex_redis apex_backend apex_celery_worker apex_celery_beat
```

---

## Log Monitoring Commands

```bash
# All services (follow)
docker compose logs -f

# Individual services
docker compose logs -f backend
docker compose logs -f celery_worker
docker compose logs -f celery_beat
docker compose logs -f postgres
docker compose logs -f redis

# Last N lines
docker compose logs --tail=100 backend
docker compose logs --tail=100 celery_worker

# Filter errors
docker compose logs backend 2>&1 | grep -i error
docker compose logs celery_worker 2>&1 | grep -i error

# Timestamps
docker compose logs -t --tail=50 backend

# Since specific time
docker compose logs --since="2025-01-01T00:00:00" backend
```

---

## Performance Monitoring

### Database

```bash
# Connection count
docker compose exec postgres psql -U apex -d apex_db -c \
  "SELECT count(*) FROM pg_stat_activity;"

# Active queries
docker compose exec postgres psql -U apex -d apex_db -c \
  "SELECT pid, now() - pg_stat_activity.query_start AS duration, query \
   FROM pg_stat_activity WHERE state = 'active' ORDER BY duration DESC;"

# Database size
docker compose exec postgres psql -U apex -d apex_db -c \
  "SELECT pg_size_pretty(pg_database_size('apex_db'));"

# Table sizes
docker compose exec postgres psql -U apex -d apex_db -c \
  "SELECT relname, pg_size_pretty(pg_total_relation_size(relid)) \
   FROM pg_catalog.pg_statio_user_tables ORDER BY pg_total_relation_size(relid) DESC;"
```

### Redis

```bash
# Memory usage
docker compose exec redis redis-cli info memory | grep -E "used_memory_human|maxmemory_human"

# Key count
docker compose exec redis redis-cli dbsize

# Connected clients
docker compose exec redis redis-cli info clients | grep connected_clients

# Slow queries
docker compose exec redis redis-cli slowlog get 10
```

### Backend (Uvicorn)

```bash
# Check worker count
docker compose exec backend ps aux | grep uvicorn

# Process stats
docker compose exec backend ps aux
```

### Celery

```bash
# Worker status
docker compose exec celery_worker celery -A app.tasks.celery_app inspect ping

# Active tasks
docker compose exec celery_worker celery -A app.tasks.celery_app inspect active

# Scheduled tasks
docker compose exec celery_worker celery -A app.tasks.celery_app inspect scheduled

# Reserved tasks
docker compose exec celery_worker celery -A app.tasks.celery_app inspect reserved

# Stats
docker compose exec celery_worker celery -A app.tasks.celery_app inspect stats
```

---

## Quick Diagnostic Script

Run this to get a full snapshot:

```bash
echo "=== Container Status ==="
docker compose ps

echo ""
echo "=== Health Status ==="
for c in apex_postgres apex_redis; do
  echo "$c: $(docker inspect --format='{{.State.Health.Status}}' $c)"
done

echo ""
echo "=== Resource Usage ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

echo ""
echo "=== Backend Health ==="
curl -s http://127.0.0.1:8001/api/v1/health

echo ""
echo "=== Redis Ping ==="
docker compose exec redis redis-cli ping

echo ""
echo "=== Postgres Ready ==="
docker compose exec postgres pg_isready -U apex -d apex_db
```
