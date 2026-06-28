"""Leave API endpoints."""

import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_feature
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.leave import (
    LeaveTypeCreate, LeaveTypeResponse,
    LeaveBalanceResponse, LeaveRequestCreate, LeaveRequestUpdate, LeaveRejectRequest, LeaveRequestResponse,
)
from app.services.leave import LeaveService

router = APIRouter(dependencies=[Depends(require_permissions("leave.read"))])


# ── Leave Types ──────────────────────────────────────
@router.get("/types", response_model=PaginatedResponse[LeaveTypeResponse])
async def list_leave_types(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = LeaveService(db)
    items, total = await service.list_leave_types(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/types", response_model=LeaveTypeResponse, status_code=201)
async def create_leave_type(
    data: LeaveTypeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("leave.approve")),
):
    service = LeaveService(db)
    return await service.create_leave_type(current_user.tenant_id, data)


# ── Leave Balance ────────────────────────────────────
@router.get("/balance/{employee_id}", response_model=list[LeaveBalanceResponse])
async def get_leave_balance(
    employee_id: uuid.UUID,
    year: int = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = LeaveService(db)
    if not year:
        from datetime import date as dt
        year = dt.today().year
    return await service.get_leave_balance(current_user.tenant_id, employee_id, year)


# ── Leave Requests ───────────────────────────────────
@router.post("/apply", response_model=LeaveRequestResponse, status_code=201)
async def apply_leave(
    data: LeaveRequestCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("leave.approve")),
):
    service = LeaveService(db)
    # Find employee record for current user
    from app.models.employee import Employee
    from sqlalchemy import select
    stmt = select(Employee).where(
        Employee.tenant_id == current_user.tenant_id,
        Employee.email == current_user.email,
    )
    result = await db.execute(stmt)
    employee = result.scalar_one_or_none()
    if not employee:
        raise HTTPException(status_code=404, detail="Employee record not found")
    return await service.apply_leave(current_user.tenant_id, employee.id, data)


@router.get("/requests", response_model=PaginatedResponse[LeaveRequestResponse])
async def list_leave_requests(
    employee_id: uuid.UUID = Query(None),
    status: str = Query(None),
    from_date: date = Query(None),
    to_date: date = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = LeaveService(db)
    items, total = await service.list_leave_requests(
        current_user.tenant_id, employee_id=employee_id,
        status_val=status, from_date=from_date, to_date=to_date,
        page=page, page_size=page_size,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.put("/requests/{request_id}/approve", response_model=LeaveRequestResponse)
async def approve_leave(
    request_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("leave.approve")),
):
    service = LeaveService(db)
    return await service.approve_leave(request_id, current_user.tenant_id, current_user.id)


@router.put("/requests/{request_id}/reject", response_model=LeaveRequestResponse)
async def reject_leave(
    request_id: uuid.UUID,
    data: LeaveRejectRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("leave.approve")),
):
    service = LeaveService(db)
    return await service.reject_leave(request_id, current_user.tenant_id, current_user.id, data.rejection_reason)


@router.put("/requests/{request_id}/cancel", response_model=LeaveRequestResponse)
async def cancel_leave(
    request_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(require_permissions("leave.approve")),
):
    service = LeaveService(db)
    return await service.cancel_leave(request_id, current_user.tenant_id, current_user.id)
