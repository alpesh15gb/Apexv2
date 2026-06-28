"""Timetable management endpoints."""

import uuid
from typing import Optional, List
from datetime import time, date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.timetable import PeriodDefinition, TimetableEntry, Substitution

router = APIRouter(dependencies=[Depends(require_feature("school_timetable"))])


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
    stmt = select(PeriodDefinition).where(PeriodDefinition.tenant_id == current_user.tenant_id).order_by(PeriodDefinition.sort_order)
    result = await db.execute(stmt)
    periods = result.scalars().all()
    return [{"id": str(p.id), "name": p.name, "start_time": str(p.start_time), "end_time": str(p.end_time), "period_type": p.period_type} for p in periods]


@router.post("/periods")
async def create_period(
    data: PeriodCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    period = PeriodDefinition(
        tenant_id=current_user.tenant_id,
        name=data.name,
        start_time=time.fromisoformat(data.start_time),
        end_time=time.fromisoformat(data.end_time),
        period_type=data.period_type,
        sort_order=data.sort_order,
    )
    db.add(period)
    await db.commit()
    return {"id": str(period.id)}


@router.get("/section/{section_id}")
async def get_section_timetable(
    section_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TimetableEntry, PeriodDefinition).join(
        PeriodDefinition, PeriodDefinition.id == TimetableEntry.period_definition_id
    ).where(
        TimetableEntry.section_id == section_id, TimetableEntry.tenant_id == current_user.tenant_id, TimetableEntry.is_active == True
    )
    if academic_year_id:
        stmt = stmt.where(TimetableEntry.academic_year_id == academic_year_id)
    stmt = stmt.order_by(TimetableEntry.day_of_week, PeriodDefinition.sort_order)
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(e.id), "day_of_week": e.day_of_week, "subject_id": str(e.subject_id) if e.subject_id else None,
            "employee_id": str(e.employee_id) if e.employee_id else None, "room_id": str(e.room_id) if e.room_id else None,
            "period_name": p.name, "start_time": str(p.start_time), "end_time": str(p.end_time),
        }
        for e, p in rows
    ]


@router.post("/section/{section_id}")
async def set_timetable(
    section_id: uuid.UUID,
    data: List[TimetableEntryCreate],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    count = 0
    for entry in data:
        existing_stmt = select(TimetableEntry).where(
            TimetableEntry.section_id == section_id,
            TimetableEntry.day_of_week == entry.day_of_week,
            TimetableEntry.period_definition_id == entry.period_definition_id,
            TimetableEntry.academic_year_id == entry.academic_year_id,
            TimetableEntry.tenant_id == current_user.tenant_id,
        )
        result = await db.execute(existing_stmt)
        existing = result.scalar_one_or_none()

        if existing:
            existing.subject_id = entry.subject_id
            existing.employee_id = entry.employee_id
            existing.room_id = entry.room_id
        else:
            te = TimetableEntry(tenant_id=current_user.tenant_id, section_id=section_id, **entry.model_dump())
            db.add(te)
        count += 1

    await db.commit()
    return {"saved": count}


@router.get("/teacher/{employee_id}")
async def get_teacher_timetable(
    employee_id: uuid.UUID,
    academic_year_id: Optional[uuid.UUID] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(TimetableEntry, PeriodDefinition).join(
        PeriodDefinition, PeriodDefinition.id == TimetableEntry.period_definition_id
    ).where(
        TimetableEntry.employee_id == employee_id, TimetableEntry.tenant_id == current_user.tenant_id, TimetableEntry.is_active == True
    )
    if academic_year_id:
        stmt = stmt.where(TimetableEntry.academic_year_id == academic_year_id)
    stmt = stmt.order_by(TimetableEntry.day_of_week, PeriodDefinition.sort_order)
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(e.id), "day_of_week": e.day_of_week, "section_id": str(e.section_id),
            "subject_id": str(e.subject_id) if e.subject_id else None,
            "period_name": p.name, "start_time": str(p.start_time), "end_time": str(p.end_time),
        }
        for e, p in rows
    ]


@router.post("/substitutions")
async def create_substitution(
    data: SubstitutionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    sub = Substitution(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(sub)
    await db.commit()
    return {"id": str(sub.id)}


@router.get("/substitutions")
async def list_substitutions(
    date_from: Optional[date] = None,
    date_to: Optional[date] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Substitution).where(Substitution.tenant_id == current_user.tenant_id)
    if date_from:
        stmt = stmt.where(Substitution.date >= date_from)
    if date_to:
        stmt = stmt.where(Substitution.date <= date_to)
    stmt = stmt.order_by(Substitution.date.desc())
    result = await db.execute(stmt)
    subs = result.scalars().all()
    return [
        {
            "id": str(s.id), "original_employee_id": str(s.original_employee_id),
            "substitute_employee_id": str(s.substitute_employee_id), "date": str(s.date),
            "reason": s.reason, "status": s.status,
        }
        for s in subs
    ]
