"""Super Admin Feature Management endpoints."""

import uuid
from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_superuser
from app.models.user import User
from app.models.feature import FeatureFlag
from app.core.feature_gate import DEFAULT_FEATURES, seed_feature_flags

router = APIRouter()


class FeatureCreateRequest(BaseModel):
    name: str = Field(..., max_length=255)
    code: str = Field(..., max_length=100)
    description: Optional[str] = None
    module: str = "general"
    category: str = "core"
    is_active: bool = True
    sort_order: int = 0


class FeatureUpdateRequest(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    module: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None
    sort_order: Optional[int] = None


@router.get("/")
async def list_features(
    category: Optional[str] = None,
    module: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List all feature flags."""
    stmt = select(FeatureFlag)
    if category:
        stmt = stmt.where(FeatureFlag.category == category)
    if module:
        stmt = stmt.where(FeatureFlag.module == module)
    stmt = stmt.order_by(FeatureFlag.category, FeatureFlag.sort_order, FeatureFlag.name)

    result = await db.execute(stmt)
    features = result.scalars().all()
    return [
        {
            "id": str(f.id),
            "name": f.name,
            "code": f.code,
            "description": f.description,
            "module": f.module,
            "category": f.category,
            "is_active": f.is_active,
            "sort_order": f.sort_order,
        }
        for f in features
    ]


@router.get("/categories")
async def list_categories(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """List all feature categories."""
    stmt = select(FeatureFlag.category).distinct().order_by(FeatureFlag.category)
    result = await db.execute(stmt)
    return [row[0] for row in result.all()]


@router.post("/")
async def create_feature(
    data: FeatureCreateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Create a new feature flag."""
    existing = await db.execute(select(FeatureFlag).where(FeatureFlag.code == data.code))
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Feature code already exists")

    feature = FeatureFlag(**data.model_dump())
    db.add(feature)
    await db.commit()
    return {"id": str(feature.id), "code": feature.code}


@router.put("/{feature_id}")
async def update_feature(
    feature_id: uuid.UUID,
    data: FeatureUpdateRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Update a feature flag."""
    feature = await db.get(FeatureFlag, feature_id)
    if not feature:
        raise HTTPException(status_code=404, detail="Feature not found")

    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(feature, field, value)
    await db.commit()
    return {"id": str(feature.id), "code": feature.code}


@router.post("/seed")
async def seed_features(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_superuser),
):
    """Seed default feature flags."""
    await seed_feature_flags(db)
    return {"message": "Feature flags seeded successfully", "count": len(DEFAULT_FEATURES)}
