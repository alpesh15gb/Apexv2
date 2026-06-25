import uuid
from typing import Any, Dict, List, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.tenant import Tenant, SubscriptionPlan

class TenantService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_tenant(self, name: str, slug: str, plan: str) -> Tenant:
        stmt = select(Tenant).where(Tenant.slug == slug)
        res = await self.db.execute(stmt)
        if res.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Tenant slug already exists"
            )
        tenant = Tenant(name=name, slug=slug, subscription_plan=plan)
        self.db.add(tenant)
        await self.db.commit()
        await self.db.refresh(tenant)
        return tenant

    async def get_tenant(self, tenant_id: uuid.UUID) -> Tenant:
        stmt = select(Tenant).where(Tenant.id == tenant_id)
        res = await self.db.execute(stmt)
        tenant = res.scalar_one_or_none()
        if not tenant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Tenant not found"
            )
        return tenant

    async def update_tenant(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Tenant:
        tenant = await self.get_tenant(tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        for field, val in data.items():
            if hasattr(tenant, field):
                setattr(tenant, field, val)

        await self.db.commit()
        await self.db.refresh(tenant)
        return tenant

    async def list_tenants(self, page: int = 1, page_size: int = 20) -> Tuple[List[Tenant], int]:
        count_stmt = select(func.count(Tenant.id))
        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = select(Tenant).offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        tenants = list(res.scalars().all())
        return tenants, total

    async def deactivate_tenant(self, tenant_id: uuid.UUID) -> Tenant:
        tenant = await self.get_tenant(tenant_id)
        tenant.is_active = False
        await self.db.commit()
        await self.db.refresh(tenant)
        return tenant
