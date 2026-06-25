"""Tenant resolution and isolation middleware."""

import uuid
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response, JSONResponse

from app.core.security import decode_token


class TenantMiddleware(BaseHTTPMiddleware):
    """ASGI middleware that extracts tenant context, verifies tenant alignment

    for authenticated requests, and sets tenant_id on request state.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # 1. Extract tenant ID from header
        tenant_header = request.headers.get("X-Tenant-ID") or request.headers.get("x-tenant-id")

        # 2. Extract JWT token from Authorization header
        auth_header = request.headers.get("Authorization")
        token_tenant_id = None
        is_superuser = False

        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
            payload = decode_token(token)
            if payload:
                token_tenant_id = payload.get("tenant_id")
                is_superuser = payload.get("is_superuser", False)
                request.state.user_id = payload.get("sub")

        # Determine and validate the tenant context
        resolved_tenant_id = None

        if token_tenant_id:
            # Authenticated request context
            if tenant_header:
                # Reject if there is a cross-tenant access attempt (mismatch) and not superuser
                if tenant_header != token_tenant_id and not is_superuser:
                    return JSONResponse(
                        status_code=403,
                        content={"detail": "Cross-tenant access denied."},
                    )
                resolved_tenant_id = tenant_header
            else:
                resolved_tenant_id = token_tenant_id
        else:
            # Unauthenticated request context (e.g. login, register, public endpoints)
            if tenant_header:
                resolved_tenant_id = tenant_header

        # Set tenant_id on request state
        if resolved_tenant_id:
            try:
                request.state.tenant_id = uuid.UUID(resolved_tenant_id)
            except ValueError:
                return JSONResponse(
                    status_code=400,
                    content={"detail": "Invalid Tenant ID format in X-Tenant-ID header."},
                )
        else:
            request.state.tenant_id = None

        return await call_next(request)
