"""Tenant Settings endpoints."""

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.tenant_settings import TenantSettings
from app.schemas.tenant_settings import TenantSettingsUpdate, TenantSettingsResponse

router = APIRouter(dependencies=[Depends(require_permissions("settings.read"))])


@router.get("/", response_model=TenantSettingsResponse)
async def get_settings(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TenantSettings).where(TenantSettings.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    settings = result.scalar_one_or_none()
    if not settings:
        settings = TenantSettings(tenant_id=current_user.tenant_id)
        db.add(settings)
        await db.commit()
        await db.refresh(settings)
    return settings


@router.put("/", response_model=TenantSettingsResponse)
async def update_settings(
    data: TenantSettingsUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TenantSettings).where(TenantSettings.tenant_id == current_user.tenant_id)
    result = await db.execute(stmt)
    settings = result.scalar_one_or_none()
    if not settings:
        settings = TenantSettings(tenant_id=current_user.tenant_id)
        db.add(settings)
        await db.flush()

    update_data = data.model_dump(exclude_unset=True)
    for field, val in update_data.items():
        setattr(settings, field, val)

    await db.commit()
    await db.refresh(settings)
    return settings
