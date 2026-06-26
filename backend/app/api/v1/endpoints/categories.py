"""Employee Category CRUD endpoints."""

import uuid
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.category import EmployeeCategory
from app.schemas.common import ResponseBase
from app.schemas.category import CategoryCreate, CategoryUpdate, CategoryResponse

router = APIRouter()


@router.get("/", response_model=List[CategoryResponse])
async def list_categories(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(EmployeeCategory).where(
        EmployeeCategory.tenant_id == current_user.tenant_id
    ).order_by(EmployeeCategory.name)
    result = await db.execute(stmt)
    return list(result.scalars().all())


@router.post("/", response_model=CategoryResponse, status_code=201)
async def create_category(
    data: CategoryCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    existing = select(EmployeeCategory).where(
        EmployeeCategory.tenant_id == current_user.tenant_id,
        EmployeeCategory.code == data.code,
    )
    if (await db.execute(existing)).scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Category with this code already exists")

    category = EmployeeCategory(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(category)
    await db.commit()
    await db.refresh(category)
    return category


@router.put("/{category_id}", response_model=CategoryResponse)
async def update_category(
    category_id: uuid.UUID,
    data: CategoryUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(EmployeeCategory).where(
        EmployeeCategory.id == category_id,
        EmployeeCategory.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    update_data = data.model_dump(exclude_unset=True)
    code = update_data.get("code")
    if code and code != category.code:
        dup = select(EmployeeCategory).where(
            EmployeeCategory.tenant_id == current_user.tenant_id,
            EmployeeCategory.code == code,
        )
        if (await db.execute(dup)).scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Category with this code already exists")

    for field, val in update_data.items():
        setattr(category, field, val)

    await db.commit()
    await db.refresh(category)
    return category


@router.delete("/{category_id}", response_model=ResponseBase)
async def delete_category(
    category_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(EmployeeCategory).where(
        EmployeeCategory.id == category_id,
        EmployeeCategory.tenant_id == current_user.tenant_id,
    )
    result = await db.execute(stmt)
    category = result.scalar_one_or_none()
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")

    await db.delete(category)
    await db.commit()
    return ResponseBase(message="Category deleted")
