"""Background Jobs & Enterprise Branding API endpoints."""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, get_current_superuser
from app.models.user import User
from app.models.tenant import Tenant

router = APIRouter()


# ---- Background Jobs ----

@router.get("/jobs")
async def list_jobs(
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List background jobs (placeholder - integrates with Celery)."""
    return {
        "jobs": [
            {"name": "attendance_sync", "schedule": "*/5 * * * *", "status": "active", "last_run": None},
            {"name": "payroll_process", "schedule": "0 1 1 * *", "status": "active", "last_run": None},
            {"name": "notification_queue", "schedule": "* * * * *", "status": "active", "last_run": None},
            {"name": "backup_daily", "schedule": "0 2 * * *", "status": "active", "last_run": None},
            {"name": "report_cleanup", "schedule": "0 3 * * 0", "status": "active", "last_run": None},
            {"name": "subscription_check", "schedule": "0 0 * * *", "status": "active", "last_run": None},
        ],
        "total": 6,
    }


@router.get("/jobs/{job_name}/status")
async def job_status(
    job_name: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Get status of a specific background job."""
    return {
        "name": job_name,
        "status": "active",
        "last_run": None,
        "next_run": None,
        "queue_length": 0,
    }


# ---- Enterprise Branding ----

class BrandingUpdate(BaseModel):
    logo_url: Optional[str] = None
    primary_color: Optional[str] = None
    secondary_color: Optional[str] = None
    login_background: Optional[str] = None
    company_name: Optional[str] = None


@router.get("/branding")
async def get_branding(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get tenant branding settings."""
    tenant = await db.get(Tenant, current_user.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    settings = tenant.settings or {}
    branding = settings.get("branding", {})

    return {
        "logo_url": tenant.logo_url,
        "company_name": tenant.name,
        "primary_color": branding.get("primary_color", "#2563EB"),
        "secondary_color": branding.get("secondary_color", "#1E293B"),
        "login_background": branding.get("login_background", ""),
    }


@router.put("/branding")
async def update_branding(
    data: BrandingUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Update tenant branding settings."""
    tenant = await db.get(Tenant, current_user.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    if data.logo_url is not None:
        tenant.logo_url = data.logo_url
    if data.company_name is not None:
        tenant.name = data.company_name

    settings = tenant.settings or {}
    branding = settings.get("branding", {})
    if data.primary_color:
        branding["primary_color"] = data.primary_color
    if data.secondary_color:
        branding["secondary_color"] = data.secondary_color
    if data.login_background:
        branding["login_background"] = data.login_background
    settings["branding"] = branding
    tenant.settings = settings

    await db.commit()
    return {"message": "Branding updated"}


# ---- Backup Operations ----

@router.post("/backup")
async def create_backup(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Trigger a manual backup."""
    import subprocess
    try:
        timestamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        filename = f"apex_backup_{timestamp}.sql"
        result = subprocess.run(
            ["pg_dump", "-h", "postgres", "-U", "apex", "-d", "apex_db", "-f", f"/backups/{filename}"],
            capture_output=True, text=True, timeout=300,
        )
        if result.returncode == 0:
            return {"status": "success", "filename": filename}
        else:
            return {"status": "error", "error": result.stderr}
    except Exception as e:
        return {"status": "error", "error": str(e)}


@router.get("/backup/history")
async def backup_history(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List backup history."""
    return {
        "backups": [],
        "total": 0,
    }
