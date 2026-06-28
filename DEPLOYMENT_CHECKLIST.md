# Apex HRMS v1.0 — Deployment Checklist

**Date**: 2026-06-28
**Target**: Ubuntu 24.04 VPS (next.apextime.in)

---

## 1. Pre-Deployment

### Infrastructure
- [ ] VPS provisioned (Ubuntu 24.04, minimum 2 vCPU / 4 GB RAM / 40 GB SSD)
- [ ] Docker and Docker Compose installed
- [ ] Nginx installed
- [ ] Domain DNS A record pointing to VPS IP (next.apextime.in)
- [ ] SSL certificate issued (Let's Encrypt via certbot)
- [ ] Firewall configured (allow ports 22, 80, 443)
- [ ] Swap file configured (2 GB recommended for 4 GB RAM)

### Repository & Environment
- [ ] Repository cloned to `/opt/Apexv2`
- [ ] `.env` file created from `.env.example`
- [ ] `SECRET_KEY` set to a random 64-character hex string
- [ ] `ENCRYPTION_KEY` set to a valid Fernet key
- [ ] `DATABASE_URL` pointing to production PostgreSQL
- [ ] `REDIS_URL` pointing to production Redis
- [ ] `CORS_ORIGINS` set to `["https://next.apextime.in"]`
- [ ] `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` configured
- [ ] `DEBUG=false` confirmed
- [ ] `EBIOSERVER_URL` updated for production eSSL device

### Database
- [ ] PostgreSQL 16 accessible and healthy
- [ ] Database `apex_db` created
- [ ] Database user `apex` created with strong password
- [ ] Database backup taken (if upgrading existing instance)

### Security
- [ ] All security tests passing (53/53 — see FINAL_PRODUCTION_SECURITY_REPORT.md)
- [ ] All regression tests passing (69/69)
- [ ] RBAC coverage verified at 100% (455/455 endpoints)
- [ ] Tenant isolation verified
- [ ] Feature flags seeded

### Frontend
- [ ] Flutter SDK installed on build machine
- [ ] Frontend builds successfully (`flutter build web --release`)
- [ ] No build warnings or errors

---

## 2. Deployment Steps

### Step 1: Pull Latest Code
```bash
cd /opt/Apexv2
git pull origin main
```

### Step 2: Verify Environment
```bash
# Confirm .env exists and has production values
grep -E "^(SECRET_KEY|DATABASE_URL|DEBUG)" .env
```

### Step 3: Build & Start Docker Services
```bash
docker compose up -d --build
```

### Step 4: Wait for Health Checks
```bash
# Wait for PostgreSQL to be healthy
docker compose exec postgres pg_isready -U apex -d apex_db

# Wait for Redis to be healthy
docker compose exec redis redis-cli ping

# Verify backend is running
docker compose ps
```

### Step 5: Run Database Migrations
```bash
docker compose exec -T backend alembic upgrade head
```

### Step 6: Verify Migration State
```bash
docker compose exec -T backend alembic current
# Should show the latest revision: a1b2c3d4e5f6
```

### Step 7: Build & Deploy Frontend
```bash
cd /opt/Apexv2/frontend
flutter pub get
flutter build web --release

# Copy to Nginx web root
sudo mkdir -p /var/www/apexhrms/frontend/build
sudo rm -rf /var/www/apexhrms/frontend/build/web
sudo cp -r build/web /var/www/apexhrms/frontend/build/web
sudo chown -R www-data:www-data /var/www/apexhrms
```

### Step 8: Configure Nginx
```bash
sudo cp /opt/Apexv2/nginx/apex.conf /etc/nginx/sites-available/apexhrms.conf
sudo ln -sf /etc/nginx/sites-available/apexhrms.conf /etc/nginx/sites-enabled/apexhrms.conf
sudo nginx -t
sudo systemctl reload nginx
```

### Step 9: Verify SSL
```bash
# Confirm SSL is working
curl -I https://next.apextime.in
# Should return 200 with security headers
```

---

## 3. Post-Deployment Verification

### Smoke Tests
- [ ] Frontend loads at `https://next.apextime.in`
- [ ] Login page renders correctly
- [ ] Admin login works (superadmin credentials)
- [ ] API responds at `https://next.apextime.in/api/v1/health`
- [ ] WebSocket connection establishes (`wss://next.apextime.in/ws/`)
- [ ] Dashboard loads with data
- [ ] Employee list loads
- [ ] Attendance module works
- [ ] Leave module works
- [ ] Payroll module loads
- [ ] Reports generate
- [ ] File upload works (profile picture, documents)
- [ ] Notifications are received
- [ ] Multi-tenant switching works (if applicable)

### Performance Checks
- [ ] API response time < 500ms for standard endpoints
- [ ] Page load time < 3 seconds
- [ ] No 5xx errors in Nginx logs (`/var/log/nginx/error.log`)
- [ ] No errors in Docker logs (`docker compose logs --tail=50`)
- [ ] Database connection pool not exhausted

### Security Verification
- [ ] HTTP redirects to HTTPS
- [ ] Security headers present (X-Frame-Options, X-Content-Type-Options, CSP)
- [ ] `/docs` and `/redoc` accessible only from trusted networks (or disabled)
- [ ] Rate limiting active on auth endpoints
- [ ] Invalid JWT tokens return 401
- [ ] Cross-tenant access returns 403

### Monitoring
- [ ] Docker container health checks passing
- [ ] Log rotation configured
- [ ] Disk usage monitored (especially `/var/lib/docker/volumes/`)
- [ ] Database backup cron job configured

---

## 4. Rollback Procedure

> See [ROLLBACK_GUIDE.md](ROLLBACK_GUIDE.md) for detailed step-by-step instructions.

### Quick Rollback Summary
1. **Frontend**: Restore previous build from backup
2. **Backend**: `git checkout <previous-tag>` then `docker compose up -d --build`
3. **Database**: `docker compose exec -T backend alembic downgrade <previous-revision>`
4. **Verify**: Smoke test the rolled-back version

---

## 5. Emergency Contacts & Resources

| Resource | Location |
|----------|----------|
| Docker logs | `docker compose logs -f` |
| Nginx access log | `/var/log/nginx/access.log` |
| Nginx error log | `/var/log/nginx/error.log` |
| Application logs | `docker compose logs backend` |
| Celery logs | `docker compose logs celery_worker` |
| Database shell | `docker compose exec postgres psql -U apex -d apex_db` |
| Redis shell | `docker compose exec redis redis-cli` |
| Migration history | `docker compose exec -T backend alembic history` |

---

**Checklist prepared by**: MiMo Code Agent
**Date**: 2026-06-28
