from contextlib import asynccontextmanager
from fastapi import FastAPI, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import get_settings
from app.db.session import engine
from app.middleware.tenant import TenantMiddleware
from app.middleware.rate_limit import RateLimitMiddleware
from app.middleware.audit import AuditMiddleware
from app.api.v1.router import api_router

settings = get_settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Verify DB Connection
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        print("Database connection verified successfully.")
    except Exception as e:
        print(f"Database connection verification failed: {e}")
        raise e
    yield
    # Shutdown: Close DB Connections
    await engine.dispose()
    print("Database connections closed.")

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    docs_url="/docs",
    redoc_url="/redoc",
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

# Include API Router
app.include_router(api_router, prefix=settings.API_V1_PREFIX)

@app.get("/health", status_code=status.HTTP_200_OK, tags=["Health"])
async def health_check():
    """Health check endpoint to verify service status."""
    return {"status": "healthy", "message": "Service is running"}
