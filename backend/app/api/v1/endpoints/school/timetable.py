"""Timetable management endpoints."""

import uuid
from typing import Optional, List
from datetime import time, date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.timetable_service import TimetableService

router = APIRouter(dependencies=[Depends(require_feature("school_timetable")), Depends(require_permissions("school.settings"))])


class PeriodCreate(BaseModel):
    name: str = Field(..., max_length=50)
    start_time: str
    end_time: str
    period_type: str = "period"
    sort_order: int = 0


class TimetableEntryCreate(BaseModel):
    section_id: uuid.UUID
    subject_id: Optional[uuid.UUID] = None
    employee_id: Optional[uuid.UUID] = None
    room_id: Optional[uuid.UUID] = None
    period_definition_id: uuid.UUID
    day_of_week: int
    academic_year_id: uuid.UUID


class SubstitutionCreate(BaseModel):
    original_employee_id: uuid.UUID
    substitute_employee_id: uuid.UUID
    timetable_entry_id: uuid.UUID
    date: date
    reason: Optional[str] = None


@router.get("/periods")
async def list_periods(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    return await svc.list_periods(tenant_id=current_user.tenant_id)


@router.post("/periods")
async def create_period(
    data: PeriodCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    period = await svc.create_period(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(period.id)}


@router.get("/section/{section_id}")
async def get_section_timetable(
    section_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    return await svc.get_section_timetable(
        section_id=section_id,
        tenant_id=current_user.tenant_id,
        academic_year_id=academic_year_id,
    )


@router.post("/section/{section_id}")
async def set_timetable(
    section_id: uuid.UUID,
    data: List[TimetableEntryCreate],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    count = await svc.set_timetable(
        section_id=section_id,
        tenant_id=current_user.tenant_id,
        entries=data,
    )
    return {"saved": count}


@router.get("/teacher/{employee_id}")
async def get_teacher_timetable(
    employee_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    return await svc.get_teacher_timetable(
        employee_id=employee_id,
        tenant_id=current_user.tenant_id,
        academic_year_id=academic_year_id,
    )


@router.post("/substitutions")
async def create_substitution(
    data: SubstitutionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    sub = await svc.create_substitution(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(sub.id)}


@router.get("/substitutions")
async def list_substitutions(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = TimetableService(db)
    return await svc.list_substitutions(
        tenant_id=current_user.tenant_id,
        date_from=date_from,
        date_to=date_to,
    )
