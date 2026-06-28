"""Academic Year, Term, and Holiday endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.academic_year import AcademicYear, AcademicTerm, SchoolHoliday

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
    stmt = select(AcademicYear).where(AcademicYear.tenant_id == current_user.tenant_id).order_by(AcademicYear.start_date.desc())
    result = await db.execute(stmt)
    years = result.scalars().all()
    return [
        {
            "id": str(y.id), "name": y.name, "start_date": str(y.start_date),
            "end_date": str(y.end_date), "is_current": y.is_current, "status": y.status,
        }
        for y in years
    ]


@router.post("/")
async def create_academic_year(
    data: AcademicYearCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    year = AcademicYear(
        tenant_id=current_user.tenant_id,
        name=data.name,
        start_date=data.start_date,
        end_date=data.end_date,
        status="planning",
    )
    db.add(year)
    await db.commit()
    return {"id": str(year.id), "name": year.name}


@router.put("/{year_id}")
async def update_academic_year(
    year_id: uuid.UUID,
    data: AcademicYearUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    year = await db.get(AcademicYear, year_id)
    if not year or year.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Academic year not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(year, field, value)
    await db.commit()
    return {"id": str(year.id)}


@router.post("/{year_id}/set-current")
async def set_current_academic_year(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    year = await db.get(AcademicYear, year_id)
    if not year or year.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Academic year not found")
    stmt = select(AcademicYear).where(AcademicYear.tenant_id == current_user.tenant_id, AcademicYear.is_current == True)
    result = await db.execute(stmt)
    for y in result.scalars().all():
        y.is_current = False
    year.is_current = True
    year.status = "active"
    await db.commit()
    return {"id": str(year.id), "is_current": True}


@router.get("/{year_id}/terms")
async def list_terms(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(AcademicTerm).where(AcademicTerm.academic_year_id == year_id, AcademicTerm.tenant_id == current_user.tenant_id).order_by(AcademicTerm.sort_order)
    result = await db.execute(stmt)
    terms = result.scalars().all()
    return [{"id": str(t.id), "name": t.name, "start_date": str(t.start_date), "end_date": str(t.end_date)} for t in terms]


@router.post("/{year_id}/terms")
async def create_term(
    year_id: uuid.UUID,
    data: TermCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    term = AcademicTerm(
        tenant_id=current_user.tenant_id,
        academic_year_id=year_id,
        name=data.name,
        start_date=data.start_date,
        end_date=data.end_date,
        sort_order=data.sort_order,
    )
    db.add(term)
    await db.commit()
    return {"id": str(term.id)}


@router.get("/{year_id}/holidays")
async def list_holidays(
    year_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(SchoolHoliday).where(SchoolHoliday.academic_year_id == year_id, SchoolHoliday.tenant_id == current_user.tenant_id).order_by(SchoolHoliday.date)
    result = await db.execute(stmt)
    holidays = result.scalars().all()
    return [{"id": str(h.id), "name": h.name, "date": str(h.date), "type": h.type} for h in holidays]


@router.post("/{year_id}/holidays")
async def create_holiday(
    year_id: uuid.UUID,
    data: HolidayCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    holiday = SchoolHoliday(
        tenant_id=current_user.tenant_id,
        academic_year_id=year_id,
        name=data.name,
        date=data.date,
        type=data.type,
    )
    db.add(holiday)
    await db.commit()
    return {"id": str(holiday.id)}
