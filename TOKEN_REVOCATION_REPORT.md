# Token Revocation Fix Report

## Problem

Token revocation was structurally present but non-functional:

1. **`get_current_user` in `deps.py`** decoded and validated JWTs but **never checked the Redis revocation blacklist**. Revoked tokens were accepted as valid.
2. **`logout` in `auth.py`** only revoked the refresh token body (duplicated inline Redis logic). The **access token** passed in the `Authorization` header was **never revoked**, so it remained usable until natural expiry.
3. **`logout-all` in `auth.py`** wrote directly to Redis instead of using the `revoke_all_user_tokens` helper from `security.py`, duplicating logic.
4. **`is_user_revoked` in `security.py`** accepted a `token_iat` parameter but **never compared it** to the revocation timestamp — it always returned `True` if any revocation record existed, regardless of when the token was issued.

## Changes Made

### `backend/app/core/security.py`

- **`is_user_revoked`** (line 136): Now parses the stored ISO revocation timestamp and compares it against `token_iat`. Only tokens issued **before** the revocation are rejected. Tokens issued after (e.g., from a fresh login) are allowed through.

### `backend/app/core/deps.py`

- Added imports: `is_token_revoked`, `is_user_revoked` from `app.core.security`.
- Added `_get_redis()` helper (lazy singleton using `redis.asyncio`) to obtain a Redis client.
- **`get_current_user`** (line 54–74): After decoding the JWT payload, now performs two Redis checks before the DB lookup:
  1. `is_token_revoked(token)` — rejects if this specific token is on the blacklist.
  2. `is_user_revoked(sub, iat)` — rejects if a blanket user-level revocation was issued after the token's `iat`.
  - Redis connection failures are silently tolerated (token validation degrades gracefully to the previous behavior).

### `backend/app/api/v1/endpoints/auth.py`

- Added imports: `revoke_token`, `revoke_all_user_tokens` from `app.core.security`.
- **`logout`** (line 269): Now accepts the `Request` object, uses `revoke_token()` to revoke **both** the refresh token (from body) and the access token (from `Authorization` header). Replaced inline Redis logic with the centralized `revoke_token` helper.
- **`logout-all`** (line 350): Now uses `revoke_all_user_tokens(str(current_user.id), redis_client)` instead of inline Redis `set()`.

## Verification

```
$ python -c "from app.api.v1.router import api_router; print('OK')"
OK
```

All modified modules import cleanly. The `api_router` (which mounts all endpoint routers) loads without errors.

## Token Revocation Flow (After Fix)

```
Client                          Server (deps.py)              Redis
  │                                  │                          │
  ├─ Authorization: Bearer <token> ─►│                          │
  │                                  ├─ decode_token()          │
  │                                  ├─ is_token_revoked() ────►│ GET revoked_token:<token>
  │                                  │◄─────────────────────────┤
  │                                  ├─ is_user_revoked()  ────►│ GET revoked_user:<uid>
  │                                  │◄─────────────────────────┤
  │                                  ├─ DB lookup               │
  │◄───────── 200 or 401 ───────────┤                          │

Client                          Server (auth.py /logout)       Redis
  │                                  │                          │
  ├─ POST /logout                    │                          │
  │   {refresh_token: "..."}         │                          │
  │   Authorization: Bearer <access> │                          │
  │                                  ├─ revoke_token(refresh)──►│ SETEX revoked_token:<rt>
  │                                  ├─ revoke_token(access) ──►│ SETEX revoked_token:<at>
  │◄───────── {status: "success"} ──┤                          │
```
