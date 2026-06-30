from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import get_settings, validate_secrets
from app.db.session import engine
from app.middleware.tenant import TenantMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.middleware.audit import AuditMiddleware
from app.middleware.security_headers import SecurityHeadersMiddleware
from app.api.v1.router import api_router
import structlog

logger = structlog.get_logger(__name__)
settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Validate secrets
    issues = validate_secrets(settings, on_startup=True)
    for issue in issues:
        logger.warning("secret_issue", issue=issue)

    # Startup: Verify DB Connection
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        logger.info("database_connection_verified")
    except Exception as e:
        logger.error("db_connection_failed", error=str(e))
        raise

    yield
    # Shutdown: Close DB Connections
    await engine.dispose()
    logger.info("database_connections_closed")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs" if settings.DEBUG else None,
    redoc_url="/redoc" if settings.DEBUG else None,
    openapi_url="/openapi.json" if settings.DEBUG else None,
    lifespan=lifespan,
)

# Add Middlewares
# CORS Middleware (innermost on request, outermost on response)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Audit Middleware
app.add_middleware(AuditMiddleware)

# Rate Limiting Middleware
app.add_middleware(RateLimitMiddleware)

# Tenant Middleware (outermost on request, innermost on response)
app.add_middleware(TenantMiddleware)

# Security Headers Middleware
app.add_middleware(SecurityHeadersMiddleware)

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
async def health_check():
    """Health check endpoint to verify service status."""
    db_ok = False
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        pass
    return {
        "status": "healthy" if db_ok else "degraded",
        "database": "connected" if db_ok else "disconnected",
        "version": settings.VERSION,
    }

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Global exception handler - prevents leaking tracebacks."""
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"},
    )
