"""Employee Lifecycle Management API endpoints."""

import uuid
from datetime import date, datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.employee import Employee
from app.models.timeline import EmployeeEvent
from app.models.payroll import SalaryStructure

router = APIRouter(dependencies=[Depends(require_permissions("employee.read"))])


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


@router.post(
    "/{employee_id}/promote",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
async def promote_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Promote an employee."""
    if not data.new_designation_id and not data.new_salary:
        raise HTTPException(
            status_code=400,
            detail="At least one of new_designation_id or new_salary is required for promotion",
        )
    if data.new_salary is not None and data.new_salary <= 0:
        raise HTTPException(status_code=400, detail="New salary must be positive")

    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    old_designation = str(employee.designation_id) if employee.designation_id else None
    old_salary = None

    if data.new_designation_id:
        employee.designation_id = data.new_designation_id

    if data.new_salary is not None and data.new_salary > 0:
        stmt = select(SalaryStructure).where(
            SalaryStructure.tenant_id == current_user.tenant_id,
            SalaryStructure.employee_id == employee_id,
            SalaryStructure.is_active == True,
        )
        result = await db.execute(stmt)
        current_salary = result.scalar_one_or_none()
        if current_salary:
            old_salary = current_salary.basic
            current_salary.is_active = False
        new_structure = SalaryStructure(
            tenant_id=current_user.tenant_id,
            employee_id=employee_id,
            basic=data.new_salary,
            hra=current_salary.hra if current_salary else 0,
            da=current_salary.da if current_salary else 0,
            conveyance=current_salary.conveyance if current_salary else 0,
            medical=current_salary.medical if current_salary else 0,
            special=current_salary.special if current_salary else 0,
            effective_from=data.effective_date or data.event_date,
        )
        db.add(new_structure)

    desc_parts = []
    if data.new_designation_id:
        desc_parts.append(f"Designation changed from {old_designation} to {data.new_designation_id}")
    if data.new_salary is not None:
        desc_parts.append(f"Salary changed from {old_salary} to {data.new_salary}")
    description = data.description or f"Promoted on {data.event_date}. {'; '.join(desc_parts)}"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="promotion",
        title=data.title or "Employee Promoted",
        description=description,
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee promoted", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/transfer",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
async def transfer_employee(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Transfer an employee to a different department/branch."""
    if not data.new_department_id and not data.new_branch_id and not data.new_manager_id:
        raise HTTPException(
            status_code=400,
            detail="At least one of new_department_id, new_branch_id, or new_manager_id is required",
        )

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
        changes.append(f"manager to {data.new_manager_id}")

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="transfer",
        title=data.title or f"Transferred ({', '.join(changes)})",
        description=data.description or f"Transferred on {data.event_date}. Changes: {', '.join(changes)}",
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee transferred", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/confirm",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
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

    if employee.status == "terminated":
        raise HTTPException(status_code=400, detail="Cannot confirm a terminated employee")

    employee.status = "active"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="confirmation",
        title="Employee Confirmed",
        description=data.description or f"Confirmed from probation on {data.event_date}",
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee confirmed", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/resign",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
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

    if employee.status in ("terminated", "resigned"):
        raise HTTPException(
            status_code=400,
            detail=f"Cannot resign an employee with status '{employee.status}'",
        )

    employee.status = "resigned"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="resignation",
        title="Employee Resigned",
        description=data.description or f"Resignation submitted on {data.event_date}",
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Resignation recorded", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/terminate",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
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

    if employee.status == "terminated":
        raise HTTPException(status_code=400, detail="Employee is already terminated")

    employee.status = "terminated"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="termination",
        title="Employee Terminated",
        description=data.description or f"Terminated on {data.event_date}. Reason: {data.reason or 'Not specified'}",
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee terminated", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/reactivate",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
async def reactivate_employee(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Reactivate a terminated/resigned employee."""
    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    if employee.status == "active":
        raise HTTPException(status_code=400, detail="Employee is already active")

    employee.status = "active"

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="reactivation",
        title="Employee Reactivated",
        description=f"Reactivated on {date.today()}",
        event_date=date.today(),
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Employee reactivated", "event_id": str(event.id)}


@router.post(
    "/{employee_id}/salary-revision",
    dependencies=[Depends(require_permissions("employee.manage"))],
)
async def revise_salary(
    employee_id: uuid.UUID,
    data: LifecycleEventRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Record a salary revision."""
    if not data.new_salary or data.new_salary <= 0:
        raise HTTPException(status_code=400, detail="new_salary is required and must be positive")

    employee = await db.get(Employee, employee_id)
    if not employee or employee.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Employee not found")

    if employee.status == "terminated":
        raise HTTPException(status_code=400, detail="Cannot revise salary for a terminated employee")

    stmt = select(SalaryStructure).where(
        SalaryStructure.tenant_id == current_user.tenant_id,
        SalaryStructure.employee_id == employee_id,
        SalaryStructure.is_active == True,
    )
    result = await db.execute(stmt)
    current_salary = result.scalar_one_or_none()

    old_salary = current_salary.basic if current_salary else 0

    if current_salary:
        current_salary.is_active = False

    new_structure = SalaryStructure(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        basic=data.new_salary,
        hra=current_salary.hra if current_salary else 0,
        da=current_salary.da if current_salary else 0,
        conveyance=current_salary.conveyance if current_salary else 0,
        medical=current_salary.medical if current_salary else 0,
        special=current_salary.special if current_salary else 0,
        effective_from=data.effective_date or data.event_date,
    )
    db.add(new_structure)

    event = EmployeeEvent(
        tenant_id=current_user.tenant_id,
        employee_id=employee_id,
        event_type="salary_revision",
        title=data.title or "Salary Revised",
        description=data.description or f"Salary revised from {old_salary} to {data.new_salary} on {data.event_date}",
        event_date=data.event_date,
        created_by=current_user.id,
    )
    db.add(event)
    await db.commit()
    return {"message": "Salary revision recorded", "event_id": str(event.id)}
