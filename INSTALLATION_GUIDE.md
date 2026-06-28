# Apex HRMS v1.0.0 — Installation Guide

**Date**: 2026-06-28
**Version**: 1.0.0

---

## Prerequisites

### Hardware
| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU | 2 vCPU | 4 vCPU |
| RAM | 4 GB | 8 GB |
| Storage | 40 GB SSD | 80 GB SSD |
| Network | 100 Mbps | 1 Gbps |

### Operating System
- Ubuntu 24.04 LTS (recommended)
- Any Linux distribution with Docker support

### Required Software
| Software | Version | Install Command |
|----------|---------|-----------------|
| Docker | 24.x+ | `curl -fsSL https://get.docker.com \| sh` |
| Docker Compose | v2.x | Included with Docker Desktop; or `apt install docker-compose-plugin` |
| Nginx | 1.24+ | `apt install nginx` |
| Git | 2.x+ | `apt install git` |
| Flutter SDK | 3.x | [flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install) (build machine only) |

### Network Requirements
- Ports 22 (SSH), 80 (HTTP), 443 (HTTPS) open
- DNS A record for your domain pointing to server IP
- Internal network access to eSSL biometric devices (if using attendance)

---

## Step-by-Step Installation

### Step 1: Clone Repository

```bash
sudo mkdir -p /opt/Apexv2
sudo chown $USER:$USER /opt/Apexv2
git clone <repository-url> /opt/Apexv2
cd /opt/Apexv2
```

### Step 2: Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with production values:

```bash
# Required: Generate secrets
SECRET_KEY=$(openssl rand -hex 32)
ENCRYPTION_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")

# Required: Database
POSTGRES_USER=apex
POSTGRES_PASSWORD=<strong-random-password>
POSTGRES_DB=apex_db
DATABASE_URL=postgresql+asyncpg://apex:<password>@postgres:5432/apex_db

# Required: Redis
REDIS_URL=redis://redis:6379/0
CELERY_BROKER_URL=redis://redis:6379/1
CELERY_RESULT_BACKEND=redis://redis:6379/2

# Required: Security
DEBUG=false
CORS_ORIGINS=["https://your-domain.com"]

# Required: Email
SMTP_HOST=smtp.your-provider.com
SMTP_PORT=587
SMTP_USER=your-email@domain.com
SMTP_PASSWORD=your-smtp-password
SMTP_FROM_EMAIL=noreply@your-domain.com

# Optional: eSSL Biometric
EBIOSERVER_URL=http://<essl-ip>:8080/eBioServerNew/services/eWebService
EBIOSERVER_USERNAME=admin
EBIOSERVER_PASSWORD=<encrypted-password>
```

### Step 3: Build and Start Services

```bash
docker compose up -d --build
```

Wait for all containers to become healthy:

```bash
docker compose ps
```

Expected output: 5 containers (postgres, redis, backend, celery_worker, celery_beat) all running.

### Step 4: Initialize Database

```bash
# Run migrations
docker compose exec -T backend alembic upgrade head

# Verify migration state
docker compose exec -T backend alembic current
```

### Step 5: Seed Initial Data

```bash
# Create super admin tenant and user
docker compose exec -T backend python -m app.scripts.seed_superadmin

# Seed feature flags
docker compose exec -T backend python -m app.scripts.seed_feature_flags

# Seed default roles and permissions
docker compose exec -T backend python -m app.scripts.seed_rbac
```

### Step 6: Build and Deploy Frontend

On a machine with Flutter SDK:

```bash
cd /opt/Apexv2/frontend
flutter pub get
flutter build web --release
```

Copy build output to server:

```bash
# On the server
sudo mkdir -p /var/www/apexhrms/frontend/build
sudo cp -r <flutter-build-output>/web /var/www/apexhrms/frontend/build/web
sudo chown -R www-data:www-data /var/www/apexhrms
```

### Step 7: Configure Nginx

```bash
sudo cp /opt/Apexv2/nginx/apex.conf /etc/nginx/sites-available/apexhrms.conf
sudo ln -sf /etc/nginx/sites-available/apexhrms.conf /etc/nginx/sites-enabled/apexhrms.conf

# Test configuration
sudo nginx -t

# Reload Nginx
sudo systemctl reload nginx
```

### Step 8: Configure SSL

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com

# Verify auto-renewal
sudo systemctl status certbot.timer
```

---

## Configuration

### Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY` | Yes | — | JWT signing key (min 32 chars) |
| `ENCRYPTION_KEY` | Yes | — | Fernet key for eSSL passwords |
| `DATABASE_URL` | Yes | — | Async PostgreSQL connection string |
| `REDIS_URL` | Yes | — | Redis connection string |
| `POSTGRES_USER` | Yes | — | PostgreSQL username |
| `POSTGRES_PASSWORD` | Yes | — | PostgreSQL password |
| `POSTGRES_DB` | Yes | — | Database name |
| `CORS_ORIGINS` | Yes | — | Allowed CORS origins (JSON array) |
| `SMTP_HOST` | Yes | — | SMTP server hostname |
| `SMTP_PORT` | No | 587 | SMTP port |
| `SMTP_USER` | Yes | — | SMTP username |
| `SMTP_PASSWORD` | Yes | — | SMTP password |
| `DEBUG` | No | `false` | Enable debug mode |
| `DATABASE_POOL_SIZE` | No | 20 | Connection pool size |
| `DATABASE_MAX_OVERFLOW` | No | 10 | Extra connections beyond pool |
| `RATE_LIMIT_PER_MINUTE` | No | 60 | API rate limit per IP |
| `MAX_UPLOAD_SIZE_MB` | No | 10 | Max file upload size (MB) |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | No | 30 | JWT access token TTL |
| `REFRESH_TOKEN_EXPIRE_DAYS` | No | 7 | JWT refresh token TTL |

### Docker Services

| Service | Internal Port | Purpose |
|---------|--------------|---------|
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Cache, Celery broker, token blacklist |
| backend | 8000 | FastAPI application (4 workers) |
| celery_worker | — | Background task processing |
| celery_beat | — | Scheduled task scheduler |

---

## Verification

### Health Checks

```bash
# Backend health
curl http://127.0.0.1:8001/api/v1/health

# Full stack (via Nginx)
curl https://your-domain.com/api/v1/health

# Database
docker compose exec postgres pg_isready -U apex -d apex_db

# Redis
docker compose exec redis redis-cli ping
```

### Smoke Tests

- [ ] Frontend loads at `https://your-domain.com`
- [ ] Login page renders correctly
- [ ] Admin login works
- [ ] API responds at `/api/v1/health`
- [ ] WebSocket connection establishes
- [ ] Dashboard loads with data
- [ ] Employee list loads
- [ ] Attendance module works
- [ ] Leave module works
- [ ] Reports generate

### Security Verification

- [ ] HTTP redirects to HTTPS
- [ ] Security headers present (`curl -I https://your-domain.com`)
- [ ] Invalid JWT returns 401
- [ ] Rate limiting active on auth endpoints
- [ ] Cross-tenant access returns 403

### Log Verification

```bash
# Check for errors
docker compose logs --tail=50 backend
docker compose logs --tail=50 celery_worker
sudo tail -20 /var/log/nginx/error.log
```

---

## Troubleshooting

### Services won't start
```bash
docker compose logs backend
# Common: DATABASE_URL incorrect, PostgreSQL not ready
```

### Migration failures
```bash
docker compose exec -T backend alembic current
docker compose exec -T backend alembic history
# Check migration chain and database connectivity
```

### Frontend not loading
```bash
# Verify build exists
ls -la /var/www/apexhrms/frontend/build/web/
# Verify Nginx config
sudo nginx -t
sudo systemctl status nginx
```

### Database connection refused
```bash
docker compose exec postgres pg_isready -U apex -d apex_db
docker compose logs postgres
# Check POSTGRES_PASSWORD matches in .env and docker-compose.yml
```

---

**Guide prepared by**: MiMo Code Agent
**Date**: 2026-06-28
