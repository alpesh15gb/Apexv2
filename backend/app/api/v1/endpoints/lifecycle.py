"""Employee Lifecycle Management API endpoints."""

import uuid
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.employee import Employee
from app.models.timeline import EmployeeEvent

router = APIRouter()


class LifecycleEventRequest(BaseModel):
    event_type: str = Field(..., max_length=50)
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    event_date: date
    effective_date: Optional[date] = None
    new_department_id: Optional[uuid.UUID] = None
    new_designation_id: Optional[uuid.UUID] = None
    new_branch_id: Optional[uuid.UUID] = None
    new_manager_id: Optional[uuid.UUID] = None
    new_salary: Optional[float] = None
    reason: Optional[str] = None


@router.get("/{employee_id}/timeline")
async def get_employee_timeline(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get complete employee timeline/history."""
    stmt = (
        select(EmployeeEvent)
        .where(
            EmployeeEvent.tenant_id == current_user.tenant_id,
            EmployeeEvent.employee_id == employee_id,
        )
        .order_by(EmployeeEvent.event_date.desc())
    )
    result = await db.execute(stmt)
    events = result.scalars().all()
    return [
        {
            "id": str(e.id),
            "event_type": e.event_type,
            "title": e.title,
            "description": e.description,
            "event_date": str(e.event_date),
            "created_at": e.created_at.isoformat() if e.created_at else None,
        }
        for e in events
    ]


@router.post("/{employee_id}/promote")
async def promote_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Promote an employee."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    old_designation = str(employee.designation_id) if employee.designation_id else None

    if data.new_designation_id:
        employee.designation_id = data.new_designation_id
    if data.new_salary:
        pass

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="promotion",
        title=data.title or "Employee Promoted",
        description=data.description or f"Promoted on {data.event_date}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee promoted", "event_id": str(event.id)}


@router.post("/{employee_id}/transfer")
async def transfer_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Transfer an employee to a different department/branch."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    changes = []
    if data.new_department_id:
        employee.department_id = data.new_department_id
        changes.append("department")
    if data.new_branch_id:
        employee.branch_id = data.new_branch_id
        changes.append("branch")
    if data.new_manager_id:
        changes.append("manager")

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="transfer",
        title=data.title or f"Transferred ({', '.join(changes)})",
        description=data.description or f"Transferred on {data.event_date}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee transferred", "event_id": str(event.id)}


@router.post("/{employee_id}/confirm")
async def confirm_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Confirm an employee from probation."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="confirmation",
        title="Employee Confirmed",
        description=data.description or f"Confirmed from probation on {data.event_date}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee confirmed", "event_id": str(event.id)}


@router.post("/{employee_id}/resign")
async def resign_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Record employee resignation."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    employee.status = "resigned"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="resignation",
        title="Employee Resigned",
        description=data.description or f"Resignation submitted on {data.event_date}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Resignation recorded", "event_id": str(event.id)}


@router.post("/{employee_id}/terminate")
async def terminate_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Terminate an employee."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    employee.status = "terminated"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="termination",
        title="Employee Terminated",
        description=data.description or f"Terminated on {data.event_date}. Reason: {data.reason or 'Not specified'}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee terminated", "event_id": str(event.id)}


@router.post("/{employee_id}/reactivate")
async def reactivate_employee(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Reactivate a terminated/resigned employee."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    employee.status = "active"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="reactivation",
        title="Employee Reactivated",
        description=f"Reactivated on {date.today()}",
        event_date=date.today(),
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee reactivated", "event_id": str(event.id)}


@router.post("/{employee_id}/salary-revision")
async def revise_salary(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Record a salary revision."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="salary_revision",
        title=data.title or "Salary Revised",
        description=data.description or f"New salary: {data.new_salary}",
        event_date=data.event_date,
    )
    db.add(event)
    await db.commit()
    return {"message": "Salary revision recorded", "event_id": str(event.id)}
