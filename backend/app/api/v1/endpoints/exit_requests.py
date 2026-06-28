"""Exit request CRUD endpoints."""
import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.exit import ExitRequest
from app.schemas.common import ResponseBase
from app.schemas.exit import ExitRequestCreate, ExitRequestUpdate, ExitRequestResponse

router = APIRouter(dependencies=[Depends(require_feature("exit_management"))])


@router.get("/", response_model=List[ExitRequestResponse])
async def list_exit_requests(
    employee_id: Optional[uuid.UUID] = Query(None),
    status: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(ExitRequest).where(ExitRequest.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(ExitRequest.employee_id == employee_id)
    if status:
        stmt = stmt.where(ExitRequest.status == status)
    stmt = stmt.order_by(ExitRequest.created_at.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=ExitRequestResponse, status_code=201)
async def create_exit_request(data: ExitRequestCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    req = ExitRequest(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(req)
    await db.commit()
    await db.refresh(req)
    return req


@router.put("/{req_id}", response_model=ExitRequestResponse)
async def update_exit_request(req_id: uuid.UUID, data: ExitRequestUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ExitRequest).where(ExitRequest.id == req_id, ExitRequest.tenant_id == current_user.tenant_id)
    req = (await db.execute(stmt)).scalar_one_or_none()
    if not req:
        raise HTTPException(status_code=404, detail="Exit request not found")
    update_data = data.model_dump(exclude_unset=True)
    if 'status' in update_data and update_data['status'] == 'approved':
        update_data['approved_at'] = datetime.now(timezone.utc)
    for field, val in update_data.items():
        setattr(req, field, val)
    await db.commit()
    await db.refresh(req)
    return req
