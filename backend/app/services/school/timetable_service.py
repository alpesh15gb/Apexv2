import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import time, date

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.timetable import PeriodDefinition, TimetableEntry, Substitution


class TimetableService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_periods(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(PeriodDefinition).where(PeriodDefinition.tenant_id == tenant_id).order_by(PeriodDefinition.sort_order)
        result = await self.db.execute(stmt)
        periods = result.scalars().all()
        return [
            {
                "id": str(p.id), "name": p.name, "start_time": str(p.start_time),
                "end_time": str(p.end_time), "period_type": p.period_type,
            }
            for p in periods
        ]

    async def create_period(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> PeriodDefinition:
        if not isinstance(data, dict):
            data = data.model_dump()
        period = PeriodDefinition(
            tenant_id=tenant_id,
            name=data["name"],
            start_time=time.fromisoformat(data["start_time"]),
            end_time=time.fromisoformat(data["end_time"]),
            period_type=data.get("period_type", "period"),
            sort_order=data.get("sort_order", 0),
        )
        self.db.add(period)
        await self.db.commit()
        await self.db.refresh(period)
        return period

    async def get_section_timetable(
        self, section_id: uuid.UUID, tenant_id: uuid.UUID, academic_year_id: Optional[uuid.UUID] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(TimetableEntry, PeriodDefinition).join(
            PeriodDefinition, PeriodDefinition.id == TimetableEntry.period_definition_id
        ).where(
            TimetableEntry.section_id == section_id,
            TimetableEntry.tenant_id == tenant_id,
            TimetableEntry.is_active == True,
        )
        if academic_year_id:
            stmt = stmt.where(TimetableEntry.academic_year_id == academic_year_id)
        stmt = stmt.order_by(TimetableEntry.day_of_week, PeriodDefinition.sort_order)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(e.id), "day_of_week": e.day_of_week,
                "subject_id": str(e.subject_id) if e.subject_id else None,
                "employee_id": str(e.employee_id) if e.employee_id else None,
                "room_id": str(e.room_id) if e.room_id else None,
                "period_name": p.name, "start_time": str(p.start_time), "end_time": str(p.end_time),
            }
            for e, p in rows
        ]

    async def set_timetable(
        self, section_id: uuid.UUID, tenant_id: uuid.UUID, entries: List[Any]
    ) -> int:
        count = 0
        for entry in entries:
            entry_data = entry if isinstance(entry, dict) else entry.model_dump()
            existing_stmt = select(TimetableEntry).where(
                TimetableEntry.section_id == section_id,
                TimetableEntry.day_of_week == entry_data["day_of_week"],
                TimetableEntry.period_definition_id == entry_data["period_definition_id"],
                TimetableEntry.academic_year_id == entry_data["academic_year_id"],
                TimetableEntry.tenant_id == tenant_id,
            )
            result = await self.db.execute(existing_stmt)
            existing = result.scalar_one_or_none()

            if existing:
                existing.subject_id = entry_data.get("subject_id")
                existing.employee_id = entry_data.get("employee_id")
                existing.room_id = entry_data.get("room_id")
            else:
                te = TimetableEntry(tenant_id=tenant_id, section_id=section_id, **entry_data)
                self.db.add(te)
            count += 1

        await self.db.commit()
        return count

    async def get_teacher_timetable(
        self, employee_id: uuid.UUID, tenant_id: uuid.UUID, academic_year_id: Optional[uuid.UUID] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(TimetableEntry, PeriodDefinition).join(
            PeriodDefinition, PeriodDefinition.id == TimetableEntry.period_definition_id
        ).where(
            TimetableEntry.employee_id == employee_id,
            TimetableEntry.tenant_id == tenant_id,
            TimetableEntry.is_active == True,
        )
        if academic_year_id:
            stmt = stmt.where(TimetableEntry.academic_year_id == academic_year_id)
        stmt = stmt.order_by(TimetableEntry.day_of_week, PeriodDefinition.sort_order)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(e.id), "day_of_week": e.day_of_week, "section_id": str(e.section_id),
                "subject_id": str(e.subject_id) if e.subject_id else None,
                "period_name": p.name, "start_time": str(p.start_time), "end_time": str(p.end_time),
            }
            for e, p in rows
        ]

    async def create_substitution(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Substitution:
        if not isinstance(data, dict):
            data = data.model_dump()
        sub = Substitution(tenant_id=tenant_id, **data)
        self.db.add(sub)
        await self.db.commit()
        await self.db.refresh(sub)
        return sub

    async def list_substitutions(
        self, tenant_id: uuid.UUID, date_from: Optional[date] = None, date_to: Optional[date] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(Substitution).where(Substitution.tenant_id == tenant_id)
        if date_from:
            stmt = stmt.where(Substitution.date >= date_from)
        if date_to:
            stmt = stmt.where(Substitution.date <= date_to)
        stmt = stmt.order_by(Substitution.date.desc())
        result = await self.db.execute(stmt)
        subs = result.scalars().all()
        return [
            {
                "id": str(s.id), "original_employee_id": str(s.original_employee_id),
                "substitute_employee_id": str(s.substitute_employee_id), "date": str(s.date),
                "reason": s.reason, "status": s.status,
            }
            for s in subs
        ]
