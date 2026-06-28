"""Visitor API endpoints."""

import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions, require_permissions
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.visitor import (
    VisitorCreate, VisitorResponse,
    VisitorPassCreate, VisitorPassResponse,
    VisitorCheckIn, VisitorCheckOut,
)
from app.services.visitor import VisitorService

router = APIRouter(dependencies=[Depends(require_feature("visitor")), Depends(require_permissions("visitor.read"))])


@router.get("/", response_model=PaginatedResponse[VisitorResponse])
async def list_visitors(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str = Query(None),
    from_date: date = Query(None),
    to_date: date = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    items, total = await service.list_visitors(
        current_user.tenant_id, page=page, page_size=page_size,
        search=search, from_date=from_date, to_date=to_date,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=VisitorResponse, status_code=201)
async def register_visitor(
    data: VisitorCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    return await service.register_visitor(current_user.tenant_id, data)


@router.post("/passes", response_model=VisitorPassResponse, status_code=201)
async def create_visitor_pass(
    data: VisitorPassCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    return await service.create_visitor_pass(current_user.tenant_id, data)


@router.post("/passes/{pass_id}/check-in", response_model=VisitorPassResponse)
async def check_in_visitor(
    pass_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    return await service.check_in_visitor(pass_id, current_user.tenant_id)


@router.post("/passes/{pass_id}/check-out", response_model=VisitorPassResponse)
async def check_out_visitor(
    pass_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    return await service.check_out_visitor(pass_id, current_user.tenant_id)


@router.get("/active", response_model=list[VisitorPassResponse])
async def list_active_visitors(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    return await service.list_active_visitors(current_user.tenant_id)


@router.get("/passes", response_model=PaginatedResponse[VisitorPassResponse])
async def list_visitor_passes(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    status: str = Query(None),
    host_employee_id: uuid.UUID = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    items, total = await service.list_passes(
        current_user.tenant_id,
        page=page,
        page_size=page_size,
        status=status,
        host_employee_id=host_employee_id,
    )
    return PaginatedResponse(
        items=items, total=total, page=page, page_size=page_size,
        total_pages=(total + page_size - 1) // page_size,
    )


@router.get("/history", response_model=PaginatedResponse[VisitorPassResponse])
async def visitor_history(
    from_date: date = Query(None),
    to_date: date = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = VisitorService(db)
    items, total = await service.get_visitor_history(
        current_user.tenant_id, from_date=from_date, to_date=to_date,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)
