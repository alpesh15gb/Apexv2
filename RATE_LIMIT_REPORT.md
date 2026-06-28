# Rate Limiting Implementation Report

## Overview

Rate limiting has been applied to critical authentication and import endpoints using the existing `@rate_limit` decorator and `RateLimitMiddleware` (Redis-backed, sliding window via Lua script).

## How It Works

- **Decorator**: `@rate_limit(limit=N, period=60)` sets `_rate_limit_limit` and `_rate_limit_period` attributes on endpoint functions.
- **Middleware**: `RateLimitMiddleware` reads these attributes during request dispatch, increments a Redis counter per `rate_limit:{identifier}:{method}:{path}`, and returns HTTP 429 with `Retry-After` header when exceeded.
- **Client identification**: Authenticated requests keyed by `user:{user_id}`, unauthenticated by `ip:{client_ip}`.
- **Fail-open**: If Redis is unavailable, requests proceed (logged as error).

## Endpoints Protected

| Endpoint | File | Limit | Period |
|---|---|---|---|
| `POST /auth/register` | `backend/app/api/v1/endpoints/auth.py` | 3/min | 60s |
| `POST /auth/login` | `backend/app/api/v1/endpoints/auth.py` | 5/min | 60s |
| `POST /auth/refresh` | `backend/app/api/v1/endpoints/auth.py` | 10/min | 60s |
| `POST /admin/auth/login` | `backend/app/api/v1/endpoints/admin/auth.py` | 5/min | 60s |
| `POST /import/employees` | `backend/app/api/v1/endpoints/import_export.py` | 10/min | 60s |
| `POST /import/leave-balances` | `backend/app/api/v1/endpoints/import_export.py` | 10/min | 60s |

## Missing Endpoint

`POST /forgot-password` was **not found** in the codebase. This endpoint does not exist yet. When implemented, it should receive `@rate_limit(limit=3, period=60)`.

## Files Modified

- `backend/app/api/v1/endpoints/auth.py` — added import + decorators on `register`, `login`, `refresh`
- `backend/app/api/v1/endpoints/admin/auth.py` — added import + decorator on `admin_login`
- `backend/app/api/v1/endpoints/import_export.py` — added import + decorators on `import_employees`, `import_leave_balances`

## Verification

```
cd backend && python -c "from app.api.v1.router import api_router; print('OK')"
# Output: OK
```

## Testing Recommendations

1. **Unit test**: Call each protected endpoint more than its limit within 60s and assert HTTP 429 with `Retry-After` header.
2. **Redis down**: Mock Redis connection failure and verify endpoints still respond (fail-open).
3. **Key isolation**: Verify rate limits are per-user (authenticated) and per-IP (unauthenticated) — two different users should each get their own limit.
4. **Unauthenticated login/register**: Send 6 rapid `POST /auth/login` requests from the same IP — the 6th should return 429.
5. **Import endpoints**: Verify that 11 rapid import requests return 429 on the 11th.
