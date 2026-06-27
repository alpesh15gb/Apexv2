"""Asset Management API endpoints."""

import uuid
from datetime import datetime, timezone, date
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.company_asset import CompanyAsset

router = APIRouter()


class AssetCreate(BaseModel):
    name: str
    asset_code: str
    category: str = "other"
    serial_number: Optional[str] = None
    model: Optional[str] = None
    brand: Optional[str] = None
    vendor: Optional[str] = None
    purchase_date: Optional[date] = None
    purchase_cost: Optional[float] = None
    warranty_start: Optional[date] = None
    warranty_end: Optional[date] = None
    location: Optional[str] = None
    description: Optional[str] = None


class AssetAssign(BaseModel):
    employee_id: uuid.UUID
    assigned_date: Optional[date] = None
    expected_return: Optional[date] = None
    condition: str = "good"
    remarks: Optional[str] = None


@router.get("/")
async def list_assets(
    category: Optional[str] = None,
    status: Optional[str] = None,
    assigned_to: Optional[uuid.UUID] = None,
    search: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(CompanyAsset).where(CompanyAsset.tenant_id == current_user.tenant_id)
    count_stmt = select(func.count(CompanyAsset.id)).where(CompanyAsset.tenant_id == current_user.tenant_id)

    if category:
        stmt = stmt.where(CompanyAsset.category == category)
        count_stmt = count_stmt.where(CompanyAsset.category == category)
    if status:
        stmt = stmt.where(CompanyAsset.status == status)
        count_stmt = count_stmt.where(CompanyAsset.status == status)
    if assigned_to:
        stmt = stmt.where(CompanyAsset.assigned_to == assigned_to)
        count_stmt = count_stmt.where(CompanyAsset.assigned_to == assigned_to)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(CompanyAsset.created_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    items = result.scalars().all()

    return {
        "items": [
            {
                "id": str(a.id),
                "name": a.name,
                "asset_code": a.asset_code,
                "category": a.category,
                "serial_number": a.serial_number,
                "model": a.model,
                "brand": a.brand,
                "vendor": a.vendor,
                "purchase_date": str(a.purchase_date) if a.purchase_date else None,
                "purchase_cost": a.purchase_cost,
                "warranty_start": str(a.warranty_start) if a.warranty_start else None,
                "warranty_end": str(a.warranty_end) if a.warranty_end else None,
                "location": a.location,
                "status": a.status,
                "assigned_to": str(a.assigned_to) if a.assigned_to else None,
                "description": a.description,
                "created_at": a.created_at.isoformat() if a.created_at else None,
            }
            for a in items
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": (total + page_size - 1) // page_size,
    }


@router.post("/")
async def create_asset(
    data: AssetCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    existing = await db.execute(
        select(CompanyAsset).where(
            CompanyAsset.tenant_id == current_user.tenant_id,
            CompanyAsset.asset_code == data.asset_code,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Asset code already exists")

    asset = CompanyAsset(
        tenant_id=current_user.tenant_id,
        status="available",
        **data.model_dump(),
    )
    db.add(asset)
    await db.commit()
    return {"id": str(asset.id), "asset_code": asset.asset_code, "status": asset.status}


@router.get("/{asset_id}")
async def get_asset(
    asset_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    asset = await db.get(CompanyAsset, asset_id)
    if not asset or asset.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Asset not found")
    return {
        "id": str(asset.id),
        "name": asset.name,
        "asset_code": asset.asset_code,
        "category": asset.category,
        "serial_number": asset.serial_number,
        "model": asset.model,
        "brand": asset.brand,
        "vendor": asset.vendor,
        "purchase_date": str(asset.purchase_date) if asset.purchase_date else None,
        "purchase_cost": asset.purchase_cost,
        "warranty_start": str(asset.warranty_start) if asset.warranty_start else None,
        "warranty_end": str(asset.warranty_end) if asset.warranty_end else None,
        "location": asset.location,
        "status": asset.status,
        "assigned_to": str(asset.assigned_to) if asset.assigned_to else None,
        "description": asset.description,
    }


@router.put("/{asset_id}")
async def update_asset(
    asset_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    asset = await db.get(CompanyAsset, asset_id)
    if not asset or asset.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Asset not found")
    for k, v in data.items():
        if hasattr(asset, k) and k not in ("id", "tenant_id"):
            setattr(asset, k, v)
    await db.commit()
    return {"id": str(asset.id), "status": asset.status}


@router.post("/{asset_id}/assign")
async def assign_asset(
    asset_id: uuid.UUID,
    data: AssetAssign,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    asset = await db.get(CompanyAsset, asset_id)
    if not asset or asset.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Asset not found")
    if asset.status != "available":
        raise HTTPException(status_code=400, detail=f"Asset is not available (current status: {asset.status})")

    asset.assigned_to = data.employee_id
    asset.status = "assigned"
    await db.commit()
    return {"id": str(asset.id), "status": "assigned", "assigned_to": str(data.employee_id)}


@router.post("/{asset_id}/return")
async def return_asset(
    asset_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    asset = await db.get(CompanyAsset, asset_id)
    if not asset or asset.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Asset not found")

    asset.assigned_to = None
    asset.status = data.get("condition", "available")
    await db.commit()
    return {"id": str(asset.id), "status": asset.status}


@router.post("/{asset_id}/maintenance")
async def send_to_maintenance(
    asset_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    asset = await db.get(CompanyAsset, asset_id)
    if not asset or asset.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Asset not found")

    asset.status = "maintenance"
    await db.commit()
    return {"id": str(asset.id), "status": "maintenance"}


@router.get("/stats")
async def asset_stats(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    tid = current_user.tenant_id

    total = (await db.execute(
        select(func.count(CompanyAsset.id)).where(CompanyAsset.tenant_id == tid)
    )).scalar() or 0

    assigned = (await db.execute(
        select(func.count(CompanyAsset.id)).where(CompanyAsset.tenant_id == tid, CompanyAsset.status == "assigned")
    )).scalar() or 0

    available = (await db.execute(
        select(func.count(CompanyAsset.id)).where(CompanyAsset.tenant_id == tid, CompanyAsset.status == "available")
    )).scalar() or 0

    maintenance = (await db.execute(
        select(func.count(CompanyAsset.id)).where(CompanyAsset.tenant_id == tid, CompanyAsset.status == "maintenance")
    )).scalar() or 0

    total_value = (await db.execute(
        select(func.sum(CompanyAsset.purchase_cost)).where(CompanyAsset.tenant_id == tid)
    )).scalar() or 0

    warranty_expiring = (await db.execute(
        select(func.count(CompanyAsset.id)).where(
            CompanyAsset.tenant_id == tid,
            CompanyAsset.warranty_end.isnot(None),
            CompanyAsset.warranty_end <= date.today().replace(month=date.today().month + 1 if date.today().month < 12 else 1),
        )
    )).scalar() or 0

    return {
        "total_assets": total,
        "assigned": assigned,
        "available": available,
        "maintenance": maintenance,
        "warranty_expiring": warranty_expiring,
        "total_value": total_value,
    }
