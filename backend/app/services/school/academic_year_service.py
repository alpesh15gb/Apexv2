import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.academic_year import AcademicYear, AcademicTerm, SchoolHoliday


class AcademicYearService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_academic_years(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(AcademicYear).where(AcademicYear.tenant_id == tenant_id).order_by(AcademicYear.start_date.desc())
        result = await self.db.execute(stmt)
        years = result.scalars().all()
        return [
            {
                "id": str(y.id), "name": y.name, "start_date": str(y.start_date),
                "end_date": str(y.end_date), "is_current": y.is_current, "status": y.status,
            }
            for y in years
        ]

    async def create_academic_year(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AcademicYear:
        if not isinstance(data, dict):
            data = data.model_dump()
        year = AcademicYear(
            tenant_id=tenant_id,
            name=data["name"],
            start_date=data["start_date"],
            end_date=data["end_date"],
            status="planning",
        )
        self.db.add(year)
        await self.db.commit()
        await self.db.refresh(year)
        return year

    async def update_academic_year(self, year_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AcademicYear:
        year = await self.db.get(AcademicYear, year_id)
        if not year or year.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academic year not found")
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)
        for field, value in data.items():
            if hasattr(year, field):
                setattr(year, field, value)
        await self.db.commit()
        await self.db.refresh(year)
        return year

    async def set_current_academic_year(self, year_id: uuid.UUID, tenant_id: uuid.UUID) -> AcademicYear:
        year = await self.db.get(AcademicYear, year_id)
        if not year or year.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Academic year not found")
        stmt = select(AcademicYear).where(AcademicYear.tenant_id == tenant_id, AcademicYear.is_current == True)
        result = await self.db.execute(stmt)
        for y in result.scalars().all():
            y.is_current = False
        year.is_current = True
        year.status = "active"
        await self.db.commit()
        await self.db.refresh(year)
        return year

    async def list_terms(self, year_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(AcademicTerm).where(
            AcademicTerm.academic_year_id == year_id, AcademicTerm.tenant_id == tenant_id
        ).order_by(AcademicTerm.sort_order)
        result = await self.db.execute(stmt)
        terms = result.scalars().all()
        return [
            {"id": str(t.id), "name": t.name, "start_date": str(t.start_date), "end_date": str(t.end_date)}
            for t in terms
        ]

    async def create_term(self, year_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AcademicTerm:
        if not isinstance(data, dict):
            data = data.model_dump()
        term = AcademicTerm(
            tenant_id=tenant_id,
            academic_year_id=year_id,
            name=data["name"],
            start_date=data["start_date"],
            end_date=data["end_date"],
            sort_order=data.get("sort_order", 0),
        )
        self.db.add(term)
        await self.db.commit()
        await self.db.refresh(term)
        return term

    async def list_holidays(self, year_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(SchoolHoliday).where(
            SchoolHoliday.academic_year_id == year_id, SchoolHoliday.tenant_id == tenant_id
        ).order_by(SchoolHoliday.date)
        result = await self.db.execute(stmt)
        holidays = result.scalars().all()
        return [
            {"id": str(h.id), "name": h.name, "date": str(h.date), "type": h.type}
            for h in holidays
        ]

    async def create_holiday(self, year_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> SchoolHoliday:
        if not isinstance(data, dict):
            data = data.model_dump()
        holiday = SchoolHoliday(
            tenant_id=tenant_id,
            academic_year_id=year_id,
            name=data["name"],
            date=data["date"],
            type=data.get("type", "holiday"),
        )
        self.db.add(holiday)
        await self.db.commit()
        await self.db.refresh(holiday)
        return holiday
