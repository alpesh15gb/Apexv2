# Security Test Report — Apex HRMS

**Date**: 2026-06-28
**Scope**: Backend API security review (code audit, no live testing)
**Files Reviewed**: `security.py`, `deps.py`, `auth.py`, `tenant.py`, `test_security.py`, plus all endpoint files under `api/v1/endpoints/`

---

## 1. JWT Validation

**File**: `backend/app/core/security.py`

| Check | Status | Detail |
|-------|--------|--------|
| Algorithm pinning | ✅ PASS | `algorithms=[settings.ALGORITHM]` enforced in `decode_token()` (line 91). Prevents algorithm-switching attacks. |
| Expiration check | ✅ PASS | `jose.jwt.decode` validates `exp` by default. |
| Issued-at (`iat`) | ✅ PASS | Included in payload; used for user-level revocation comparison. |
| `sub` claim validation | ✅ PASS | `deps.py:76-82` checks `sub` exists and is valid UUID before DB lookup. |
| Secret key strength | ⚠️ MEDIUM | `config.py:12` has a hardcoded default `_DEFAULT_SECRET_KEY`. Dev fallback generates ephemeral key (`config.py:133`), but production must set `SECRET_KEY` via env. `validate_secrets()` raises `SystemExit` on startup in production if missing. Acceptable, but relies on operator discipline. |
| Token type claim | ⚠️ LOW | Access and refresh tokens share the same structure (no `type` claim). A stolen refresh token could theoretically be passed where an access token is expected — though `deps.py` uses `OAuth2PasswordBearer` which only looks at `Authorization: Bearer`, so the refresh endpoint accepts either. |

**Recommendation**: Add a `"type": "access"` / `"type": "refresh"` claim and validate it in `get_current_user()`.

---

## 2. Token Refresh

**File**: `backend/app/api/v1/endpoints/auth.py:202-272`

| Check | Status | Detail |
|-------|--------|--------|
| Decodes & validates JWT | ✅ PASS | `decode_token()` called; rejects invalid tokens. |
| Checks revocation | ✅ PASS | Redis lookup for `revoked_token:{token}` (line 220). |
| Checks user exists | ✅ PASS | DB lookup by `sub` claim (line 244). |
| Checks user active | ✅ PASS | Rejects inactive users (line 251). |
| Old refresh token revoked | ❌ FAIL | After issuing new tokens, the old refresh token is NOT revoked. An attacker with a stolen refresh token could keep using it. |
| Rate limiting | ✅ PASS | `@rate_limit(limit=10, period=60)` applied. |
| Redis failure handling | ⚠️ MEDIUM | `except Exception: pass` (line 227) silently ignores Redis failures, allowing revoked tokens to be used if Redis is down. |

**Recommendation**: Revoke the old refresh token after issuing new pair. Add circuit-breaker or fail-closed on Redis errors.

---

## 3. Token Revocation

**File**: `backend/app/core/security.py:98-150`, `backend/app/core/deps.py:54-74`

| Check | Status | Detail |
|-------|--------|--------|
| Per-token revocation | ✅ PASS | `revoke_token()` stores token in Redis with TTL matching token expiry. |
| User-level revocation | ✅ PASS | `revoke_all_user_tokens()` stores revocation timestamp; `is_user_revoked()` compares against `iat`. |
| Checked in auth dependency | ✅ PASS | `deps.py:55-70` checks both per-token and user-level revocation. |
| Logout revokes tokens | ✅ PASS | `auth.py:275-292` revokes both access and refresh tokens. |
| Logout-all | ✅ PASS | `auth.py:356-367` uses `revoke_all_user_tokens()`. |
| Password change invalidates sessions | ✅ PASS | `auth.py:344-348` sets user-level revocation timestamp. |
| Redis-only storage | ⚠️ MEDIUM | Revocation is entirely Redis-backed. If Redis loses data (restart without persistence), all revoked tokens become valid again. |

**Recommendation**: Persist revocation events to database as backup; implement Redis AOF persistence.

---

## 4. SQL Injection

| Check | Status | Detail |
|-------|--------|--------|
| ORM usage | ✅ PASS | All endpoints use SQLAlchemy ORM (`select()`, `.where()`, parameterized queries). No raw SQL string concatenation found. |
| `text()` usage | ✅ PASS | Single usage in `system.py:25`: `text("SELECT 1")` — hardcoded health check, no user input. |
| LIKE query escaping | ✅ PASS | `recruitment.py:342`, `admin/tenants.py:79`, `services/employee.py:155` all escape `%`, `_`, and `\` in search inputs before using `ilike()`. |
| Pydantic validation | ✅ PASS | All request bodies use Pydantic schemas with type validation. |

**Verdict**: No SQL injection vectors found.

---

## 5. XSS (Cross-Site Scripting)

| Check | Status | Detail |
|-------|--------|--------|
| Input sanitization | ❌ FAIL | No server-side HTML sanitization library (bleach, markupsafe, html.escape) is used anywhere in the codebase. User-supplied strings (names, descriptions, comments) are stored as-is. |
| Output encoding | ⚠️ N/A | API returns JSON; XSS prevention depends on frontend framework (React/Next.js auto-escapes by default). |
| Content-Type header | ✅ PASS | FastAPI sets `application/json` by default. |
| Stored XSS risk | ⚠️ MEDIUM | If any frontend renders API responses as raw HTML (e.g., rich text fields, admin panels), stored XSS is possible. Fields like `full_name`, `phone`, `avatar_url` (auth.py:310-315) accept arbitrary strings. |

**Recommendation**: Add server-side input validation (max length, character whitelist) on free-text fields. Sanitize any field that may be rendered as HTML.

---

## 6. IDOR (Insecure Direct Object Reference)

| Check | Status | Detail |
|-------|--------|--------|
| Tenant-scoped queries | ✅ PASS | Nearly all endpoints filter by `current_user.tenant_id` (172+ occurrences found). This prevents cross-tenant data access. |
| Resource ownership verification | ⚠️ MEDIUM | Some endpoints use `db.get(Model, id)` without tenant filtering, then rely on the model having a tenant_id check elsewhere. Examples: |
| | | `performance.py:92` — `await db.get(ReviewCycle, cycle_id)` without tenant filter |
| | | `performance.py:183` — `await db.get(Goal, goal_id)` without tenant filter |
| | | `assets.py:137-213` — `await db.get(CompanyAsset, asset_id)` without tenant filter |
| | | `notification_center.py:81` — `await db.get(Notification, notification_id)` without tenant filter |
| | | `billing.py:83-243` — Multiple `db.get()` calls without tenant filter |
| | | `recruitment.py:123-633` — Multiple `db.get()` calls without tenant filter |
| Path parameter ownership | ⚠️ MEDIUM | `leaves.py:45-56` — `get_leave_balance(employee_id)` passes `employee_id` from URL path without verifying the employee belongs to the current user's tenant (though the service layer may add this filter). |

**Recommendation**: Audit all `db.get()` calls to ensure tenant_id filtering is applied. Consider a base query helper that auto-filters by tenant.

---

## 7. Broken Access Control / RBAC

| Check | Status | Detail |
|-------|--------|--------|
| Router-level permissions | ✅ PASS | All routers use `dependencies=[Depends(require_permissions(...))]` at the module level. |
| Permission checking | ✅ PASS | `deps.py:138-157` — `require_permissions()` checks ALL specified codenames; superusers bypass. |
| Superuser guard | ✅ PASS | Admin endpoints use `get_current_superuser` dependency. |
| Feature gating | ✅ PASS | `require_feature()` checks tenant feature flags; superusers bypass. |
| Active user check | ✅ PASS | `get_current_active_user()` verifies `is_active` flag. |
| Cross-tenant header spoofing | ✅ PASS | `tenant.py:42-47` rejects `X-Tenant-ID` mismatches for non-superusers. |
| Missing write-level permissions | ⚠️ LOW | Some endpoints that modify data only have read-level router permissions. E.g., `assets.py` router may only require `asset.read` but expose write operations — individual endpoints may override with stricter deps, but this needs per-endpoint audit. |

**Verdict**: RBAC framework is solid. Permission enforcement is consistent across routers.

---

## 8. Sensitive Information Leakage

| Check | Status | Detail |
|-------|--------|--------|
| Exception detail in responses | ❌ FAIL | `auth.py:115` — `detail=f"Tenant registration failed: {str(e)}"` leaks internal error details to client. |
| | ❌ FAIL | `import_export.py:44` — `detail=f"Failed to parse file: {str(e)}"` leaks parsing internals. |
| | ❌ FAIL | `import_export.py:128,208` — Row-level errors include raw exception strings. |
| | ❌ FAIL | `operations.py:140` — `{"status": "error", "error": str(e)}` leaks backup errors. |
| | ❌ FAIL | `operations.py:138` — `result.stderr` returned directly to client. |
| Stack traces | ✅ PASS | No `traceback` module usage found in API responses. |
| Password in response | ✅ PASS | `hashed_password` excluded from `UserResponse` schema. |
| Debug mode | ✅ PASS | `DEBUG: bool = False` default. |
| Database credentials | ⚠️ MEDIUM | Default `DATABASE_URL` has hardcoded credentials (`apex:apex_secret`) — `config.py:13`. Only used when env var is missing. |
| Health check | ✅ PASS | `text("SELECT 1")` doesn't expose DB version or schema. |

**Recommendation**: Replace `str(e)` in error responses with generic messages. Log full errors server-side only.

---

## 9. Additional Findings

### 9.1 Rate Limiting
- ✅ Login: 5 attempts/60s
- ✅ Register: 3 attempts/60s
- ✅ Refresh: 10 attempts/60s
- ⚠️ Password change: No rate limit applied
- ⚠️ Other mutation endpoints: No per-endpoint rate limits beyond global default

### 9.2 bcrypt Monkeypatch
- `security.py:14-20` — Patches `bcrypt.hashpw` to truncate passwords >72 bytes. This is a known Python 3.12+ compatibility workaround but silently truncates long passwords without warning the user. Consider documenting this or enforcing a max password length in validation.

### 9.3 WebSocket Authentication
- `websocket.py:47` — Error handler logs `str(e)` but not returned to client. Acceptable.

### 9.4 Subprocess Usage
- `operations.py:131-133` — `subprocess.run(["pg_dump", ...])` for backups. Command is hardcoded (not user-controlled), but the endpoint is superuser-only. Low risk.

---

## Summary

| Category | Rating | Key Issue |
|----------|--------|-----------|
| JWT Validation | ✅ Good | Missing token type claim |
| Token Refresh | ⚠️ Fair | Old refresh token not revoked after use |
| Token Revocation | ✅ Good | Redis-only; no DB fallback |
| SQL Injection | ✅ Excellent | ORM-only, proper escaping |
| XSS | ⚠️ Fair | No server-side sanitization (relies on frontend) |
| IDOR | ⚠️ Fair | Several `db.get()` calls lack tenant filtering |
| Broken Access Control | ✅ Good | Consistent RBAC enforcement |
| Info Leakage | ❌ Poor | Raw exception strings in 5+ endpoints |

### Priority Fixes

1. **HIGH**: Remove `str(e)` from API error responses in `auth.py:115`, `import_export.py:44,128,208`, `operations.py:138,140`
2. **HIGH**: Revoke old refresh token after token rotation in `auth.py:267`
3. **MEDIUM**: Add `type` claim to JWTs (access vs refresh) and validate in `deps.py`
4. **MEDIUM**: Audit all `db.get()` calls in `performance.py`, `assets.py`, `billing.py`, `recruitment.py` for missing tenant filters
5. **MEDIUM**: Add input length validation on free-text fields
6. **LOW**: Add Redis persistence config or DB-backed revocation fallback
7. **LOW**: Add rate limiting to password change endpoint
