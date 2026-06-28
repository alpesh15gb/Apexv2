# JWT Security Report - is_superuser Claim Fix

## Problem

`TenantMiddleware` in `backend/app/middleware/tenant.py:33` reads `is_superuser` from the JWT payload:

```python
is_superuser = payload.get("is_superuser", False)
```

However, `create_access_token()` in `backend/app/core/security.py` did **not** include `is_superuser` in the token payload. This caused the middleware to always resolve `is_superuser = False`, breaking cross-tenant access for superusers.

## Root Cause

The `create_access_token` function only accepted `subject` and `tenant_id` parameters and never encoded `is_superuser` into the JWT payload.

## Fix Summary

### 1. `backend/app/core/security.py`
- Added `is_superuser: bool = False` parameter to `create_access_token()`
- Added `"is_superuser": is_superuser` to the JWT payload (`to_encode` dict)

### 2. `backend/app/api/v1/endpoints/auth.py`
- **Login endpoint** (line ~171): passes `is_superuser=user.is_superuser` to `create_access_token`
- **Refresh endpoint** (line ~253): passes `is_superuser=user.is_superuser` to `create_access_token`

### 3. `backend/app/api/v1/endpoints/admin/auth.py`
- **Admin login** (line ~52): passes `is_superuser=True` to `create_access_token` (already guards with `if not user.is_superuser: 403`)

### 4. `backend/app/middleware/tenant.py`
- **No changes needed** - already correctly reads `is_superuser` from JWT payload at line 33

## Token Payload (after fix)

```json
{
  "sub": "<user_id>",
  "tenant_id": "<tenant_id>",
  "is_superuser": true|false,
  "iat": 1735689600,
  "exp": 1735693200
}
```

## Behavioral Impact

| Scenario | Before | After |
|---|---|---|
| Superuser cross-tenant access via X-Tenant-ID header | Blocked (403) | Allowed |
| Regular user cross-tenant access | Blocked (403) | Blocked (403) |
| Admin login token | Missing claim | `is_superuser: true` |
| Regular user login token | Missing claim | `is_superuser: false` |
