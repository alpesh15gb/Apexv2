"""Academic Year, Term, and Holiday endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.academic_year_service import AcademicYearService

router = APIRouter(dependencies=[Depends(require_feature("academic_year")), Depends(require_permissions("school.settings"))])


class AcademicYearCreate(BaseModel):
    name: str = Field(..., max_length=50)
    start_date: date
    end_date: date


class AcademicYearUpdate(BaseModel):
    name: Optional[str] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    status: Optional[str] = None


class TermCreate(BaseModel):
    name: str = Field(..., max_length=50)
    start_date: date
    end_date: date
    sort_order: int = 0


class HolidayCreate(BaseModel):
    name: str = Field(..., max_length=255)
    date: date
    type: str = "holiday"


@router.get("/")
async def list_academic_years(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    return await svc.list_academic_years(tenant_id=current_user.tenant_id)


@router.post("/")
async def create_academic_year(
    data: AcademicYearCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    year = await svc.create_academic_year(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(year.id), "name": year.name}


@router.put("/{year_id}")
async def update_academic_year(
    year_id: uuid.UUID,
    data: AcademicYearUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    year = await svc.update_academic_year(year_id=year_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(year.id)}


@router.post("/{year_id}/set-current")
async def set_current_academic_year(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    year = await svc.set_current_academic_year(year_id=year_id, tenant_id=current_user.tenant_id)
    return {"id": str(year.id), "is_current": True}


@router.get("/{year_id}/terms")
async def list_terms(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    return await svc.list_terms(year_id=year_id, tenant_id=current_user.tenant_id)


@router.post("/{year_id}/terms")
async def create_term(
    year_id: uuid.UUID,
    data: TermCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    term = await svc.create_term(year_id=year_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(term.id)}


@router.get("/{year_id}/holidays")
async def list_holidays(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    return await svc.list_holidays(year_id=year_id, tenant_id=current_user.tenant_id)


@router.post("/{year_id}/holidays")
async def create_holiday(
    year_id: uuid.UUID,
    data: HolidayCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = AcademicYearService(db)
    holiday = await svc.create_holiday(year_id=year_id, tenant_id=current_user.tenant_id, data=data)
    return {"id": str(holiday.id)}
