"""Redis-based rate limiting middleware."""

import logging
import uuid
from typing import Any, Callable
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response, JSONResponse
from starlette.types import ASGIApp
from starlette.routing import Match
from redis.asyncio import Redis

from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

# Lua script to atomicity increment and check rate limit.
# Returns {current_count, TTL}
LUA_SCRIPT = """
local key = KEYS[1]
local limit = tonumber(ARGV[1])
local period = tonumber(ARGV[2])

local current = tonumber(redis.call('get', key) or "0")
if current >= limit then
    return {current + 1, redis.call('ttl', key)}
else
    local newVal = redis.call('incr', key)
    if newVal == 1 then
        redis.call('expire', key, period)
    end
    return {newVal, redis.call('ttl', key)}
end
"""


def rate_limit(limit: int, period: int = 60) -> Callable:
    """Decorator to set custom rate limit on an endpoint.

    Example:
        @router.post("/heavy-action")
        @rate_limit(limit=5, period=60)
        async def heavy_action():
            ...
    """
    def decorator(func: Callable) -> Callable:
        func._rate_limit_limit = limit
        func._rate_limit_period = period
        return func
    return decorator


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Redis-backed rate limiting middleware with configurable per-endpoint limits."""

    def __init__(self, app: ASGIApp):
        super().__init__(app)
        self.redis = Redis.from_url(settings.REDIS_URL, decode_responses=True)
        self.script = self.redis.register_script(LUA_SCRIPT)

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Determine default limits
        limit = settings.RATE_LIMIT_PER_MINUTE
        period = 60

        path = request.url.path
        method = request.method

        # 1. Match route and check for custom rate limit attributes
        if hasattr(request.app, "routes"):
            for route in request.app.routes:
                match, _ = route.matches(request.scope)
                if match == Match.FULL:
                    endpoint = getattr(route, "endpoint", None)
                    if endpoint:
                        limit = getattr(endpoint, "_rate_limit_limit", limit)
                        period = getattr(endpoint, "_rate_limit_period", period)
                    break

        # 2. Identify the client: user ID if authenticated, else IP address
        user_id = getattr(request.state, "user_id", None)
        if user_id:
            identifier = f"user:{user_id}"
        else:
            client_ip = request.client.host if request.client else "unknown"
            identifier = f"ip:{client_ip}"

        # 3. Apply rate limiting via Redis
        key = f"rate_limit:{identifier}:{method}:{path}"
        try:
            count, ttl = await self.script(keys=[key], args=[limit, period])
            if count > limit:
                retry_after = ttl if ttl and ttl > 0 else period
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too Many Requests. Rate limit exceeded."},
                    headers={"Retry-After": str(retry_after)},
                )
        except Exception as e:
            # Fail-open to avoid disrupting service if Redis is down
            logger.error(f"Rate limiting failure (fail-open): {e}")

        return await call_next(request)
