"""Tenant Setup Wizard API endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.models.tenant import Tenant
from app.models.employee import Department, Designation, Branch
from app.models.shift import Shift
from app.models.leave import LeaveType
from app.models.category import EmployeeCategory

router = APIRouter()


class CompanyInfoRequest(BaseModel):
    name: Optional[str] = None
    email: Optional[str] = None
    mobile: Optional[str] = None
    address: Optional[str] = None
    gst_number: Optional[str] = None
    pan_number: Optional[str] = None
    timezone: str = "Asia/Kolkata"
    currency: str = "INR"
    fy_start: str = "04-01"


class BranchItem(BaseModel):
    name: str
    code: str
    is_default: bool = False


class BranchesRequest(BaseModel):
    branches: List[BranchItem]


class DepartmentItem(BaseModel):
    name: str
    code: str


class DepartmentsRequest(BaseModel):
    departments: List[DepartmentItem]


class DesignationItem(BaseModel):
    name: str
    code: str


class DesignationsRequest(BaseModel):
    designations: List[DesignationItem]


class ShiftItem(BaseModel):
    name: str
    start: str = "09:00"
    end: str = "18:00"
    grace: int = 10


class ShiftsRequest(BaseModel):
    shifts: List[ShiftItem]


class LeaveTypeItem(BaseModel):
    name: str
    code: str
    days: int = 12
    carry: bool = False


class LeavesRequest(BaseModel):
    leave_types: List[LeaveTypeItem]


class AttendanceRequest(BaseModel):
    weekly_off_1: str = "Saturday"
    weekly_off_2: str = "Sunday"
    auto_shift: bool = True
    biometric_enabled: bool = False


@router.get("/progress")
async def get_setup_progress(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Get setup wizard progress."""
    tenant_id = current_user.tenant_id

    has_branches = (await db.execute(
        select(Branch.id).where(Branch.tenant_id == tenant_id).limit(1)
    )).scalar_one_or_none() is not None

    has_departments = (await db.execute(
        select(Department.id).where(Department.tenant_id == tenant_id).limit(1)
    )).scalar_one_or_none() is not None

    has_designations = (await db.execute(
        select(Designation.id).where(Designation.tenant_id == tenant_id).limit(1)
    )).scalar_one_or_none() is not None

    has_shifts = (await db.execute(
        select(Shift.id).where(Shift.tenant_id == tenant_id).limit(1)
    )).scalar_one_or_none() is not None

    has_leave_types = (await db.execute(
        select(LeaveType.id).where(LeaveType.tenant_id == tenant_id).limit(1)
    )).scalar_one_or_none() is not None

    steps = []
    if has_branches:
        steps.append("company")
        steps.append("branches")
    if has_departments:
        steps.append("departments")
    if has_designations:
        steps.append("designations")
    if has_shifts:
        steps.append("shifts")
    if has_leave_types:
        steps.append("leaves")

    return {
        "completed_steps": steps,
        "current_step": len(steps),
        "is_complete": len(steps) >= 5,
    }


@router.post("/company")
async def setup_company(
    data: CompanyInfoRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Save company information."""
    tenant = await db.get(Tenant, current_user.tenant_id)
    if not tenant:
        raise HTTPException(status_code=404, detail="Tenant not found")

    if data.name:
        tenant.name = data.name
    if data.email:
        tenant.email = data.email
    if data.mobile:
        tenant.mobile = data.mobile
    if data.address:
        pass
    if data.gst_number:
        tenant.gst_number = data.gst_number
    if data.pan_number:
        tenant.pan_number = data.pan_number
    tenant.timezone = data.timezone
    tenant.currency = data.currency
    tenant.financial_year_start = data.fy_start

    await db.commit()
    return {"message": "Company info saved"}


@router.post("/branches")
async def setup_branches(
    data: BranchesRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create branches."""
    for item in data.branches:
        existing = await db.execute(
            select(Branch).where(
                Branch.tenant_id == current_user.tenant_id,
                Branch.code == item.code,
            )
        )
        if not existing.scalar_one_or_none():
            db.add(Branch(
                tenant_id=current_user.tenant_id,
                name=item.name,
                code=item.code,
                is_active=True,
            ))
    await db.commit()
    return {"message": f"{len(data.branches)} branches created"}


@router.post("/departments")
async def setup_departments(
    data: DepartmentsRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create departments."""
    for item in data.departments:
        existing = await db.execute(
            select(Department).where(
                Department.tenant_id == current_user.tenant_id,
                Department.code == item.code,
            )
        )
        if not existing.scalar_one_or_none():
            db.add(Department(
                tenant_id=current_user.tenant_id,
                name=item.name,
                code=item.code,
                is_active=True,
            ))
    await db.commit()
    return {"message": f"{len(data.departments)} departments created"}


@router.post("/designations")
async def setup_designations(
    data: DesignationsRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create designations."""
    for item in data.designations:
        existing = await db.execute(
            select(Designation).where(
                Designation.tenant_id == current_user.tenant_id,
                Designation.code == item.code,
            )
        )
        if not existing.scalar_one_or_none():
            db.add(Designation(
                tenant_id=current_user.tenant_id,
                name=item.name,
                code=item.code,
                is_active=True,
            ))
    await db.commit()
    return {"message": f"{len(data.designations)} designations created"}


@router.post("/shifts")
async def setup_shifts(
    data: ShiftsRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create shifts."""
    for item in data.shifts:
        existing = await db.execute(
            select(Shift).where(
                Shift.tenant_id == current_user.tenant_id,
                Shift.name == item.name,
            )
        )
        if not existing.scalar_one_or_none():
            db.add(Shift(
                tenant_id=current_user.tenant_id,
                name=item.name,
                start_time=item.start,
                end_time=item.end,
                grace_period_minutes=item.grace,
                is_active=True,
            ))
    await db.commit()
    return {"message": f"{len(data.shifts)} shifts created"}


@router.post("/leaves")
async def setup_leaves(
    data: LeavesRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create leave types."""
    for item in data.leave_types:
        existing = await db.execute(
            select(LeaveType).where(
                LeaveType.tenant_id == current_user.tenant_id,
                LeaveType.code == item.code,
            )
        )
        if not existing.scalar_one_or_none():
            db.add(LeaveType(
                tenant_id=current_user.tenant_id,
                name=item.name,
                code=item.code,
                default_days=item.days,
                is_active=True,
            ))
    await db.commit()
    return {"message": f"{len(data.leave_types)} leave types created"}


@router.post("/attendance")
async def setup_attendance(
    data: AttendanceRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Save attendance settings."""
    from app.models.tenant_settings import TenantSettings
    existing = await db.execute(
        select(TenantSettings).where(TenantSettings.tenant_id == current_user.tenant_id)
    )
    settings = existing.scalar_one_or_none()
    if not settings:
        settings = TenantSettings(tenant_id=current_user.tenant_id)
        db.add(settings)

    settings.auto_shift_if_no_schedule = data.auto_shift
    await db.commit()
    return {"message": "Attendance settings saved"}
