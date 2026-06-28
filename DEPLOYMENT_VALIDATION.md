# Apex HRMS — Deployment Validation Guide

## Pre-Deployment Checklist

- [ ] Docker Desktop installed and running
- [ ] `.env` file created from `.env.example` with production values
- [ ] `SECRET_KEY` generated (min 32 chars): `python -c "import secrets; print(secrets.token_urlsafe(48))"`
- [ ] `ENCRYPTION_KEY` set in `.env`
- [ ] `POSTGRES_PASSWORD` changed from default
- [ ] `CORS_ORIGINS` updated to production domain
- [ ] `DEBUG=false` in `.env`
- [ ] SSL certificates provisioned (Let's Encrypt)
- [ ] DNS A record for `next.apextime.in` points to VPS IP
- [ ] Ports 80, 443, 8001, 5434, 6380 available
- [ ] Flutter SDK installed (for frontend build)
- [ ] Nginx installed on host

---

## Services (docker-compose.yml)

| Service | Image | Container | Port (host) | Healthcheck |
|---|---|---|---|---|
| postgres | postgres:16-alpine | apex_postgres | 127.0.0.1:5434 | pg_isready |
| redis | redis:7-alpine | apex_redis | 127.0.0.1:6380 | redis-cli ping |
| backend | custom (Python 3.12) | apex_backend | 127.0.0.1:8001 | — |
| celery_worker | custom (Python 3.12) | apex_celery_worker | — | — |
| celery_beat | custom (Python 3.12) | apex_celery_beat | — | — |

---

## Step-by-Step Deployment Commands

### 1. Clone and configure

```bash
cd /opt
sudo git clone https://github.com/alpesh15gb/Apexv2.git
sudo chown -R $USER:$USER /opt/Apexv2
cd /opt/Apexv2
cp .env.example .env
# Edit .env with production values
nano .env
```

### 2. Build and start containers

```bash
cd /opt/Apexv2
docker compose up -d --build
```

### 3. Wait for healthy services

```bash
# Wait for postgres and redis healthchecks to pass
docker compose ps
# All services should show "Up" or "Up (healthy)"
```

### 4. Run database migrations

```bash
docker compose exec -T backend alembic upgrade head
```

### 5. Build Flutter frontend

```bash
cd /opt/Apexv2/frontend
flutter pub get
flutter build web --release
```

### 6. Deploy frontend to Nginx

```bash
sudo mkdir -p /var/www/apexhrms/frontend/build
sudo cp -r /opt/Apexv2/frontend/build/web /var/www/apexhrms/frontend/build/web
sudo chown -R www-data:www-data /var/www/apexhrms
```

### 7. Configure Nginx

```bash
sudo cp /opt/Apexv2/nginx/apex.conf /etc/nginx/sites-available/apexhrms.conf
sudo ln -s /etc/nginx/sites-available/apexhrms.conf /etc/nginx/sites-enabled/apexhrms.conf
sudo nginx -t
sudo systemctl reload nginx
```

---

## Post-Deployment Verification

### Container status

```bash
docker compose ps
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
```

### API health check

```bash
curl -s http://127.0.0.1:8001/api/v1/health | jq .
```

### Frontend access

```bash
curl -sI https://next.apextime.in
```

### Database connectivity

```bash
docker compose exec postgres pg_isready -U apex -d apex_db
docker compose exec postgres psql -U apex -d apex_db -c "SELECT version();"
```

### Redis connectivity

```bash
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli info server | grep redis_version
```

### SSL certificate

```bash
openssl s_client -connect next.apextime.in:443 -servername next.apextime.in </dev/null 2>/dev/null | openssl x509 -noout -dates
```

### Celery workers

```bash
docker compose exec celery_worker celery -A app.tasks.celery_app inspect ping
docker compose exec celery_worker celery -A app.tasks.celery_app inspect active
```

---

## Container Health Check Commands

```bash
# All containers
docker ps --filter "name=apex_" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Postgres health
docker inspect --format='{{.State.Health.Status}}' apex_postgres

# Redis health
docker inspect --format='{{.State.Health.Status}}' apex_redis

# Backend logs (last 50 lines)
docker compose logs --tail=50 backend

# Celery worker logs
docker compose logs --tail=50 celery_worker

# Celery beat logs
docker compose logs --tail=50 celery_beat
```

---

## Common Issues

| Issue | Fix |
|---|---|
| Backend won't start | Check `.env` values, especially `DATABASE_URL` and `SECRET_KEY` |
| Postgres unhealthy | Check `POSTGRES_PASSWORD` matches in `.env` and `docker-compose.yml` |
| Redis connection refused | Ensure Redis container is healthy: `docker compose ps redis` |
| Migration fails | Check backend logs: `docker compose logs backend` |
| 502 Bad Gateway | Backend not running or wrong port in nginx config |
| SSL errors | Run `sudo certbot renew` and reload nginx |
