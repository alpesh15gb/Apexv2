"""Asset, Travel, Announcement, Poll, Notification Template CRUD endpoints."""
import uuid
from typing import List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.asset_travel import CompanyAsset, TravelRequest
from app.models.announcement import Announcement, Poll, PollResponse
from app.models.notification_template import NotificationTemplate
from app.schemas.common import ResponseBase
from app.schemas.hr_features import (
    CompanyAssetCreate, CompanyAssetUpdate, CompanyAssetResponse,
    TravelRequestCreate, TravelRequestUpdate, TravelRequestResponse,
    AnnouncementCreate, AnnouncementResponse,
    PollCreate, PollResponse as PollResp, PollVoteCreate,
    NotificationTemplateCreate, NotificationTemplateResponse,
)

router = APIRouter(dependencies=[Depends(require_permissions("hr.read"))])


# ── Company Assets ──────────────────────────────────────
@router.get("/assets", response_model=List[CompanyAssetResponse])
async def list_assets(status: Optional[str] = Query(None), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(CompanyAsset).where(CompanyAsset.tenant_id == current_user.tenant_id)
    if status: stmt = stmt.where(CompanyAsset.status == status)
    return list((await db.execute(stmt)).scalars().all())

@router.post("/assets", response_model=CompanyAssetResponse, status_code=201)
async def create_asset(data: CompanyAssetCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    asset = CompanyAsset(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(asset); await db.commit(); await db.refresh(asset)
    return asset

@router.put("/assets/{asset_id}", response_model=CompanyAssetResponse)
async def update_asset(asset_id: uuid.UUID, data: CompanyAssetUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(CompanyAsset).where(CompanyAsset.id == asset_id, CompanyAsset.tenant_id == current_user.tenant_id)
    asset = (await db.execute(stmt)).scalar_one_or_none()
    if not asset: raise HTTPException(status_code=404, detail="Asset not found")
    for field, val in data.model_dump(exclude_unset=True).items(): setattr(asset, field, val)
    await db.commit(); await db.refresh(asset)
    return asset

@router.delete("/assets/{asset_id}", response_model=ResponseBase)
async def delete_asset(asset_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(CompanyAsset).where(CompanyAsset.id == asset_id, CompanyAsset.tenant_id == current_user.tenant_id)
    asset = (await db.execute(stmt)).scalar_one_or_none()
    if not asset: raise HTTPException(status_code=404, detail="Asset not found")
    await db.delete(asset); await db.commit()
    return ResponseBase(message="Asset deleted")


# ── Travel Requests ─────────────────────────────────────
@router.get("/travel", response_model=List[TravelRequestResponse])
async def list_travel_requests(employee_id: Optional[uuid.UUID] = Query(None), status: Optional[str] = Query(None), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(TravelRequest).where(TravelRequest.tenant_id == current_user.tenant_id)
    if employee_id: stmt = stmt.where(TravelRequest.employee_id == employee_id)
    if status: stmt = stmt.where(TravelRequest.status == status)
    return list((await db.execute(stmt.order_by(TravelRequest.created_at.desc()))).scalars().all())

@router.post("/travel", response_model=TravelRequestResponse, status_code=201)
async def create_travel_request(data: TravelRequestCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    tr = TravelRequest(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(tr); await db.commit(); await db.refresh(tr)
    return tr

@router.put("/travel/{tr_id}", response_model=TravelRequestResponse)
async def update_travel_request(tr_id: uuid.UUID, data: TravelRequestUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(TravelRequest).where(TravelRequest.id == tr_id, TravelRequest.tenant_id == current_user.tenant_id)
    tr = (await db.execute(stmt)).scalar_one_or_none()
    if not tr: raise HTTPException(status_code=404, detail="Travel request not found")
    update_data = data.model_dump(exclude_unset=True)
    if 'status' in update_data and update_data['status'] == 'approved':
        update_data['approved_at'] = datetime.now(timezone.utc)
    for field, val in update_data.items(): setattr(tr, field, val)
    await db.commit(); await db.refresh(tr)
    return tr


# ── Announcements ───────────────────────────────────────
@router.get("/announcements", response_model=List[AnnouncementResponse])
async def list_announcements(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    return list((await db.execute(select(Announcement).where(Announcement.tenant_id == current_user.tenant_id, Announcement.is_active == True).order_by(Announcement.created_at.desc()))).scalars().all())

@router.post("/announcements", response_model=AnnouncementResponse, status_code=201)
async def create_announcement(data: AnnouncementCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    ann = Announcement(tenant_id=current_user.tenant_id, created_by=current_user.id, **data.model_dump())
    db.add(ann); await db.commit(); await db.refresh(ann)
    return ann

@router.delete("/announcements/{ann_id}", response_model=ResponseBase)
async def delete_announcement(ann_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(Announcement).where(Announcement.id == ann_id, Announcement.tenant_id == current_user.tenant_id)
    ann = (await db.execute(stmt)).scalar_one_or_none()
    if not ann: raise HTTPException(status_code=404, detail="Announcement not found")
    await db.delete(ann); await db.commit()
    return ResponseBase(message="Announcement deleted")


# ── Polls ───────────────────────────────────────────────
@router.get("/polls", response_model=List[PollResp])
async def list_polls(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    return list((await db.execute(select(Poll).where(Poll.tenant_id == current_user.tenant_id, Poll.is_active == True).order_by(Poll.created_at.desc()))).scalars().all())

@router.post("/polls", response_model=PollResp, status_code=201)
async def create_poll(data: PollCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    poll = Poll(tenant_id=current_user.tenant_id, created_by=current_user.id, **data.model_dump())
    db.add(poll); await db.commit(); await db.refresh(poll)
    return poll

@router.post("/polls/{poll_id}/vote")
async def vote_poll(poll_id: uuid.UUID, data: PollVoteCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    from app.models.employee import Employee
    emp_stmt = select(Employee).where(Employee.tenant_id == current_user.tenant_id, Employee.email == current_user.email)
    emp = (await db.execute(emp_stmt)).scalar_one_or_none()
    if not emp: raise HTTPException(status_code=404, detail="Employee not found")
    existing = select(PollResponse).where(PollResponse.poll_id == poll_id, PollResponse.employee_id == emp.id)
    if (await db.execute(existing)).scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Already voted")
    resp = PollResponse(tenant_id=current_user.tenant_id, poll_id=poll_id, employee_id=emp.id, selected_option=data.selected_option)
    db.add(resp); await db.commit()
    return {"message": "Vote recorded"}


# ── Notification Templates ──────────────────────────────
@router.get("/notification-templates", response_model=List[NotificationTemplateResponse])
async def list_notification_templates(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    return list((await db.execute(select(NotificationTemplate).where(NotificationTemplate.tenant_id == current_user.tenant_id))).scalars().all())

@router.post("/notification-templates", response_model=NotificationTemplateResponse, status_code=201)
async def create_notification_template(data: NotificationTemplateCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    tmpl = NotificationTemplate(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(tmpl); await db.commit(); await db.refresh(tmpl)
    return tmpl

@router.put("/notification-templates/{tmpl_id}", response_model=NotificationTemplateResponse)
async def update_notification_template(tmpl_id: uuid.UUID, data: NotificationTemplateCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(NotificationTemplate).where(NotificationTemplate.id == tmpl_id, NotificationTemplate.tenant_id == current_user.tenant_id)
    tmpl = (await db.execute(stmt)).scalar_one_or_none()
    if not tmpl: raise HTTPException(status_code=404, detail="Template not found")
    for field, val in data.model_dump(exclude_unset=True).items():
        if hasattr(tmpl, field): setattr(tmpl, field, val)
    await db.commit(); await db.refresh(tmpl)
    return tmpl
