# Apex HRMS v1.0.0 — Release Notes

## Release Date
June 27, 2026

## Overview
Apex HRMS is a complete multi-tenant SaaS Human Resource Management System designed for enterprise deployment. This release represents the first production-ready version with full HR operations, biometric integration, payroll processing, recruitment, performance management, and employee self-service capabilities.

## Architecture
- **Backend**: FastAPI (Python 3.12) + SQLAlchemy async + PostgreSQL 16 + Alembic
- **Frontend**: Flutter Web + Riverpod + GoRouter
- **Infrastructure**: Docker Compose + Nginx + Redis + Celery
- **Authentication**: JWT with refresh tokens
- **Multi-tenancy**: Row-level tenant isolation

## Database
- **Total Tables**: 80+
- **Migrations**: 16 linear Alembic migrations
- **Models**: 44 SQLAlchemy model files

## API Endpoints
- **Total Routes**: 46 registered routers
- **Authentication**: JWT with access/refresh tokens
- **Authorization**: RBAC with role-permission mapping
- **Tenant Isolation**: Every query scoped by tenant_id

## Frontend Screens
- **Total Screens**: 50+ Flutter screens
- **Admin Portal**: 6 screens (login, dashboard, tenants, plans, features, tenant detail)
- **ESS Portal**: 7 screens (dashboard, attendance, leaves, profile, payslips, documents, notifications)
- **HR Modules**: 30+ screens (employees, attendance, shifts, leave, payroll, recruitment, performance, assets)
- **System**: 3 screens (notifications, settings, health)

## Modules Delivered

### 1. Super Admin Portal
- Multi-tenant management dashboard
- Subscription plan management (4 plans: Starter, Professional, Enterprise, Unlimited)
- Feature flag engine (33 features across 10 categories)
- Resource limit management per tenant
- Tenant CRUD with suspend/activate

### 2. Company Setup Wizard
- 8-step onboarding wizard
- Company info, branches, departments, designations, shifts, leave policy, attendance settings
- Resumable and idempotent

### 3. Employee Management
- Employee directory with grid/table view, filters, search
- 7-step creation wizard with auto-login generation
- Employee lifecycle (promote, transfer, confirm, resign, terminate, reactivate)
- Timeline tracking

### 4. Attendance & Shift Management
- Attendance dashboard with live stats
- Daily attendance register
- Shift management with night shift support
- Attendance regularization (5 request types)
- ESS attendance calendar with clock in/out

### 5. Leave Management
- Leave dashboard with KPI cards
- Leave type management with configurable policies
- Leave calendar with holiday markers
- Leave approval workflow

### 6. Payroll Management
- Payroll dashboard with month selector
- Salary structure management
- Loan and advance tracking
- Payroll processing workflow

### 7. Recruitment & ATS
- Recruitment dashboard with pipeline visualization
- Job opening management
- Candidate management with stage tracking
- Interview scheduling with feedback

### 8. Performance Management
- Performance dashboard with review cycles
- Goal/OKR management with progress tracking
- Review cycle management
- Competency framework

### 9. Asset Management
- Asset dashboard with category/status tracking
- Asset CRUD with assignment/return/maintenance
- Category-based organization

### 10. Employee Self Service
- Dashboard with attendance summary
- Leave application and balance
- Payslip viewing
- Document management
- Notification center

### 11. System Administration
- Company settings management
- System health monitoring
- Notification center with read/unread tracking

## Security
- JWT authentication with refresh tokens
- RBAC with 4 default roles per tenant
- Tenant isolation on all queries
- CORS restricted to known origins
- API docs disabled in production
- Password hashing with bcrypt

## Known Limitations
- Email/SMS notifications require SMTP/SMS gateway configuration
- File upload requires volume mount configuration
- Some report exports require additional setup
- Dark mode not fully implemented across all screens

## Deployment
```bash
cd /opt/Apexv2
git pull origin main
docker compose up -d --build
docker exec apex_backend alembic upgrade head
cd frontend && flutter clean && flutter pub get && flutter build web
cp -r build/web/* /var/www/apexhrms/frontend/build/web/
systemctl restart nginx
```

## Environment Variables Required
```
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
SECRET_KEY=<random-32-byte-key>
ENCRYPTION_KEY=<fernet-key>
REDIS_URL=redis://localhost:6379/0
CORS_ORIGINS=["https://yourdomain.com"]
```
