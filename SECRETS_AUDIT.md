# Secrets Audit — Apex HRMS

**Date:** 2026-06-28

## Findings

### CRITICAL — Hardcoded SECRET_KEY default (FIXED)

| Field | Before | After |
|-------|--------|-------|
| `config.py` SECRET_KEY | `"change-this-to-a-random-secret-key-in-production"` | `""` (empty — dev gets ephemeral key, prod aborts) |
| `.env` / `.env.example` SECRET_KEY | Same hardcoded placeholder | Empty; comment shows generation command |

**Risk:** Any deployment using the default SECRET_KEY allowed JWT forgery — an attacker could sign arbitrary tokens and impersonate any user.

### HIGH — Hardcoded eBioserver password in .env.example (FIXED)

| Field | Before | After |
|-------|--------|-------|
| `.env.example` EBIOSERVER_PASSWORD | `Keystone@999` | Empty |
| `.env.example` EBIOSERVER_URL | `http://keystoneinfra.ddns.net:8080/...` | `http://your-essl-server:8080/...` |
| `.env.example` EBIOSERVER_USERNAME | `essl` | Empty |

**Risk:** Leaked production eSSL server credentials in a public/committed example file.

### MEDIUM — Hardcoded database credentials in config.py default (ACKNOWLEDGED)

| Field | Value |
|-------|-------|
| `config.py` DATABASE_URL default | `postgresql+asyncpg://apex:apex_secret@localhost:5432/apex_db` |

**Status:** Kept as default for local dev convenience. `validate_secrets()` warns if this exact default is still in use at startup. The `.env` files override it for real deployments.

### LOW — ENCRYPTION_KEY empty by default (VALIDATED)

The Fernet encryption key for eSSL device passwords defaults to empty. `validate_secrets()` now warns on startup and **raises SystemExit in production** if missing, since encrypted passwords in the DB become unreadable without it.

### INFORMATIONAL — Other secrets in .env.example

These are placeholder/template values, not real credentials:
- `SMTP_USER=your-email@gmail.com` / `SMTP_PASSWORD=your-app-password`
- `POSTGRES_PASSWORD=apex_secret` (Docker local dev)
- `SMS_API_KEY=` (empty)

## Changes Made

### `backend/app/core/config.py`
- `SECRET_KEY` default changed from hardcoded string to `""` (empty)
- Added `_is_dev_environment()` — checks `ENVIRONMENT`/`ENV` env vars
- Added `validate_secrets()` — validates SECRET_KEY, ENCRYPTION_KEY, DATABASE_URL
  - **Dev mode:** warns, generates ephemeral key if SECRET_KEY is empty
  - **Production:** raises `SystemExit` if SECRET_KEY or ENCRYPTION_KEY are missing/default
- `get_settings()` generates ephemeral `secrets.token_urlsafe(48)` in dev when SECRET_KEY is empty

### `backend/app/main.py`
- Replaced ad-hoc `"change-this" in` check with `validate_secrets(settings, on_startup=True)`
- Issues are printed on startup; production aborts on critical findings

### `.env.example` / `.env` / `backend/.env`
- `SECRET_KEY` cleared (empty) with generation command in comment
- eBioserver credentials removed from `.env.example`

## How to Generate Secrets

```bash
# SECRET_KEY (JWT signing)
python -c "import secrets; print(secrets.token_urlsafe(48))"

# ENCRYPTION_KEY (Fernet — for eSSL passwords)
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

## Remaining Items (not addressed — out of scope)

- `docker-compose.yml` still uses `apex_secret` as default Postgres password (acceptable for local Docker dev)
- `.github/workflows/ci.yml` has `apex_secret` for CI test database (standard practice for CI)
- `POSTGRES_PASSWORD=apex_secret` in `.env` files (user must change for production)
