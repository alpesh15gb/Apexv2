import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.user import User
from app.schemas.tenant import TenantCreate, TenantUpdate, TenantResponse
from app.schemas.common import PaginatedResponse
from app.services.tenant import TenantService

router = APIRouter()

@router.get("/", response_model=PaginatedResponse[TenantResponse])
async def list_tenants(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
) -> PaginatedResponse[TenantResponse]:
    """List all tenants (superuser only)."""
    service = TenantService(db)
    tenants, total = await service.list_tenants(page=page, page_size=page_size)
    total_pages = (total + page_size - 1) // page_size
    return PaginatedResponse(
        success=True,
        message="Tenants retrieved successfully",
        items=tenants,
        total=total,
        page=page,
        page_size=page_size,
        total_pages=total_pages,
    )

@router.post("/", response_model=TenantResponse, status_code=status.HTTP_201_CREATED)
async def create_tenant(
    tenant_data: TenantCreate,
    db: AsyncSession = Depends(get_db),
) -> TenantResponse:
    """Create a new tenant."""
    service = TenantService(db)
    tenant = await service.create_tenant(
        name=tenant_data.name,
        slug=tenant_data.slug,
        plan=tenant_data.subscription_plan,
    )
    return tenant

@router.get("/{tenant_id}", response_model=TenantResponse)
async def get_tenant(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
) -> TenantResponse:
    """Get a tenant by ID."""
    service = TenantService(db)
    tenant = await service.get_tenant(tenant_id)
    return tenant

@router.put("/{tenant_id}", response_model=TenantResponse)
async def update_tenant(
    tenant_id: uuid.UUID,
    tenant_data: TenantUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
) -> TenantResponse:
    """Update a tenant."""
    service = TenantService(db)
    tenant = await service.update_tenant(tenant_id, tenant_data)
    return tenant

@router.delete("/{tenant_id}", response_model=TenantResponse)
async def deactivate_tenant(
    tenant_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
) -> TenantResponse:
    """Deactivate a tenant."""
    service = TenantService(db)
    tenant = await service.deactivate_tenant(tenant_id)
    return tenant
