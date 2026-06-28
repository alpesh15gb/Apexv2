import uuid
from datetime import date, time
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.shift import Shift, ShiftSchedule
from app.models.employee import Employee

class ShiftService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_shift(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Shift:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        name = data.get("name")
        if not name:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="name is required")

        # Parse string times if passed
        for time_field in ["start_time", "end_time"]:
            if time_field in data and isinstance(data[time_field], str):
                data[time_field] = time.fromisoformat(data[time_field])

        shift = Shift(tenant_id=tenant_id, **data)
        self.db.add(shift)
        await self.db.commit()
        await self.db.refresh(shift)
        return shift

    async def get_shift(self, shift_id: uuid.UUID, tenant_id: uuid.UUID) -> Shift:
        stmt = select(Shift).where(Shift.id == shift_id, Shift.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        shift = res.scalar_one_or_none()
        if not shift:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shift not found")
        return shift

    async def update_shift(self, shift_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Shift:
        shift = await self.get_shift(shift_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        # Parse string times if passed
        for time_field in ["start_time", "end_time"]:
            if time_field in data and isinstance(data[time_field], str):
                data[time_field] = time.fromisoformat(data[time_field])

        for field, val in data.items():
            if hasattr(shift, field):
                setattr(shift, field, val)

        await self.db.commit()
        await self.db.refresh(shift)
        return shift

    async def delete_shift(self, shift_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        shift = await self.get_shift(shift_id, tenant_id)
        await self.db.delete(shift)
        await self.db.commit()

    async def list_shifts(self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 20) -> Tuple[List[Shift], int]:
        count_stmt = select(func.count(Shift.id)).where(Shift.tenant_id == tenant_id)
        stmt = select(Shift).where(Shift.tenant_id == tenant_id).offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        shifts = list(res.scalars().all())
        return shifts, total

    async def assign_shift(
        self,
        tenant_id: uuid.UUID,
        data: Any,
    ) -> ShiftSchedule:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        employee_id = data.get("employee_id")
        shift_id = data.get("shift_id")
        effective_from = data.get("effective_from")
        effective_to = data.get("effective_to")
        day_of_week = data.get("day_of_week")

        if not employee_id or not shift_id or not effective_from:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="employee_id, shift_id, and effective_from are required")

        if isinstance(employee_id, str):
            employee_id = uuid.UUID(employee_id)
        if isinstance(shift_id, str):
            shift_id = uuid.UUID(shift_id)

        # Check if shift exists
        stmt_shift = select(Shift).where(Shift.id == shift_id, Shift.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_shift)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Shift not found")

        # Check if employee exists
        stmt_emp = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_emp)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        # Parse string dates if passed
        if isinstance(effective_from, str):
            effective_from = date.fromisoformat(effective_from)
        if isinstance(effective_to, str):
            effective_to = date.fromisoformat(effective_to)

        schedule = ShiftSchedule(
            tenant_id=tenant_id,
            employee_id=employee_id,
            shift_id=shift_id,
            effective_from=effective_from,
            effective_to=effective_to,
            day_of_week=day_of_week
        )
        self.db.add(schedule)
        await self.db.commit()
        await self.db.refresh(schedule)
        return schedule

    async def get_employee_shift(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, shift_date: date) -> Shift:
        # Parse string dates if passed
        if isinstance(shift_date, str):
            shift_date = date.fromisoformat(shift_date)

        weekday = shift_date.weekday()  # 0 = Monday, 6 = Sunday

        # 1. Look up active ShiftSchedule for date/weekday
        stmt = select(ShiftSchedule).where(
            ShiftSchedule.employee_id == employee_id,
            ShiftSchedule.tenant_id == tenant_id,
            ShiftSchedule.effective_from <= shift_date,
            (ShiftSchedule.effective_to == None) | (ShiftSchedule.effective_to >= shift_date)
        ).where(
            (ShiftSchedule.day_of_week == None) | (ShiftSchedule.day_of_week == weekday)
        ).order_by(ShiftSchedule.day_of_week.desc(), ShiftSchedule.effective_from.desc())

        res = await self.db.execute(stmt)
        schedule = res.scalar_one_or_none()

        if schedule:
            shift_stmt = select(Shift).where(Shift.id == schedule.shift_id, Shift.tenant_id == tenant_id)
            shift = (await self.db.execute(shift_stmt)).scalar_one_or_none()
            if shift:
                return shift

        # 2. Fall back to Employee default shift
        emp_stmt = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        emp_res = await self.db.execute(emp_stmt)
        employee = emp_res.scalar_one_or_none()
        
        if employee and employee.shift_id:
            shift_stmt = select(Shift).where(Shift.id == employee.shift_id, Shift.tenant_id == tenant_id)
            shift = (await self.db.execute(shift_stmt)).scalar_one_or_none()
            if shift:
                return shift

        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No active shift schedule or default shift found for this employee"
        )

    async def list_shift_schedules(
        self,
        tenant_id: uuid.UUID,
        employee_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[ShiftSchedule], int]:
        count_stmt = select(func.count(ShiftSchedule.id)).where(
            ShiftSchedule.tenant_id == tenant_id
        )
        stmt = select(ShiftSchedule).where(
            ShiftSchedule.tenant_id == tenant_id
        ).options(selectinload(ShiftSchedule.shift))
        if employee_id:
            count_stmt = count_stmt.where(ShiftSchedule.employee_id == employee_id)
            stmt = stmt.where(ShiftSchedule.employee_id == employee_id)
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        schedules = list(res.scalars().all())
        return schedules, total
