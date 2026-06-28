# Refresh Token Security

## What Was Changed

### 1. Token Type Claim (`backend/app/core/security.py`)
- `create_access_token` now includes `"type": "access"` in the JWT payload
- `create_refresh_token` now includes `"type": "refresh"` in the JWT payload
- This prevents cross-use: a refresh token cannot be used as an access token and vice versa

### 2. Old Token Revocation on Rotation (`backend/app/api/v1/endpoints/auth.py`)
- The `/refresh` endpoint now revokes the old refresh token **after** issuing new tokens
- Uses Redis `setex` with TTL matching the token's remaining lifetime
- Revocation is wrapped in try/except so a Redis failure doesn't block the refresh flow

### 3. Token Type Validation in `get_current_user` (`backend/app/core/deps.py`)
- `get_current_user` now checks `payload.get("type") != "access"` and rejects non-access tokens
- This means refresh tokens are rejected if someone tries to use them as Bearer tokens

### 4. Token Type Validation in Refresh Endpoint (`backend/app/api/v1/endpoints/auth.py`)
- The `/refresh` endpoint now checks `payload.get("type") != "refresh"` and rejects non-refresh tokens
- This means access tokens are rejected if someone tries to use them for token refresh

## How Rotation Works Now

```
1. Client sends POST /auth/refresh with { refresh_token: "..." }
2. Server decodes and validates the token:
   - Must be a valid JWT (correct signature, not expired)
   - Must have type="refresh" (not an access token)
   - Must not be in Redis revocation blacklist
3. Server looks up the user and checks is_active
4. Server issues new token pair (access + refresh)
5. Server revokes the OLD refresh token in Redis (prevents replay)
6. Server returns new tokens to client
```

## Replay Prevention

| Attack Vector | Protection |
|---|---|
| Reuse old refresh token after rotation | Old token is revoked in Redis; second use returns 401 |
| Use refresh token as access token | `type` claim check in `get_current_user` rejects it |
| Use access token as refresh token | `type` claim check in `/refresh` rejects it |
| Stolen token after logout | `revoke_token` blacklists both access and refresh in Redis |
| All sessions compromised | `logout-all` sets `revoked_user:{id}` timestamp; any token issued before that time is rejected |

## Existing Protections (Unchanged)

- **Logout** (`POST /auth/logout`): Revokes both the refresh token (from body) and access token (from Authorization header) in Redis
- **Logout All** (`POST /auth/logout-all`): Sets a user-level revocation timestamp in Redis; `get_current_user` checks `is_user_revoked` and rejects any token issued before that timestamp
- **Password Change**: Also triggers user-level revocation, invalidating all sessions
- **Rate Limiting**: Refresh endpoint is rate-limited to 10 requests per 60 seconds

## Test Cases

### Token Type Enforcement
1. **Access token rejected by /refresh**: Send an access token to POST /auth/refresh -> expect 401 "Invalid token type"
2. **Refresh token rejected by protected endpoints**: Send a refresh token as Bearer to GET /auth/me -> expect 401 "Invalid token type"
3. **Correct token types work**: Login, use access token for /me, use refresh token for /refresh -> both succeed

### Rotation Replay Prevention
4. **Old refresh token revoked after rotation**: Call /refresh, then call /refresh again with the OLD token -> expect 401 "Refresh token has been revoked"
5. **New refresh token works after rotation**: Call /refresh, then call /refresh with the NEW token -> expect 200 with fresh tokens

### Logout
6. **Logout revokes both tokens**: Call /logout with refresh token in body + access token in Authorization header -> both tokens are blacklisted in Redis
7. **Revoked access token rejected**: After logout, use the same access token on /me -> expect 401
8. **Revoked refresh token rejected**: After logout, use the same refresh token on /refresh -> expect 401

### Logout All
9. **Logout-all invalidates all sessions**: Login on two devices, call /logout-all from device 1 -> device 2's tokens are also rejected
10. **New login works after logout-all**: After /logout-all, a fresh login succeeds with new tokens

### Edge Cases
11. **Expired token rejected**: Wait for token expiry (or use a pre-expired token) -> expect 401
12. **Tampered token rejected**: Modify one character in the token -> expect 401
13. **Redis down**: If Redis is unavailable, refresh still issues new tokens (revocation is best-effort) but old token won't be blacklisted
