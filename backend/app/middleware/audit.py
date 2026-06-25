"""Audit logging middleware for mutating requests."""

import logging
import uuid
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.db.session import async_session_factory
from app.models.audit_log import AuditLog

logger = logging.getLogger(__name__)


class AuditMiddleware(BaseHTTPMiddleware):
    """ASGI middleware that logs all mutating requests (POST, PUT, PATCH, DELETE)

    to the database audit_logs table.
    """

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Run the request first
        response = await call_next(request)

        # Audit only mutating requests and successful or semi-successful operations
        if request.method in ("POST", "PUT", "PATCH", "DELETE"):
            # Extract tenant_id from request state
            tenant_id = getattr(request.state, "tenant_id", None)

            # If tenant_id is not yet UUID, try to cast it
            if tenant_id and not isinstance(tenant_id, uuid.UUID):
                try:
                    tenant_id = uuid.UUID(str(tenant_id))
                except ValueError:
                    tenant_id = None

            # Skip logging if there is no resolved tenant context, since tenant_id is non-nullable in AuditLog
            if not tenant_id:
                return response

            # Extract user_id from request state
            user_id = getattr(request.state, "user_id", None)
            if user_id and not isinstance(user_id, uuid.UUID):
                try:
                    user_id = uuid.UUID(str(user_id))
                except ValueError:
                    user_id = None

            # Parse action and resource
            action = request.method
            parts = [p for p in request.url.path.split("/") if p]
            resource_type = "unknown"
            resource_id = None

            if len(parts) >= 3:  # e.g., /api/v1/employees/1234
                resource_type = parts[2]
                if len(parts) >= 4:
                    resource_id = parts[3]
            elif len(parts) >= 2:
                resource_type = parts[1]
            elif len(parts) >= 1:
                resource_type = parts[0]

            ip_address = request.client.host if request.client else None
            user_agent = request.headers.get("user-agent") or request.headers.get("User-Agent")

            # Store the log entry asynchronously in the database
            try:
                async with async_session_factory() as db:
                    audit_log = AuditLog(
                        tenant_id=tenant_id,
                        user_id=user_id,
                        action=action,
                        resource_type=resource_type,
                        resource_id=resource_id,
                        ip_address=ip_address,
                        user_agent=user_agent,
                        new_values={"status_code": response.status_code},
                    )
                    db.add(audit_log)
                    await db.commit()
            except Exception as e:
                # Log audit database failure without disrupting the client response
                logger.error(f"Audit log insertion failed: {e}")

        return response
