"""Employee API endpoints."""

import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user
from app.models.user import User
from app.schemas.common import PaginatedResponse, ResponseBase
from app.schemas.employee import (
    EmployeeCreate, EmployeeUpdate, EmployeeResponse,
    DepartmentCreate, DepartmentUpdate, DepartmentResponse,
    DesignationCreate, DesignationUpdate, DesignationResponse,
    BranchCreate, BranchUpdate, BranchResponse,
)
from app.services.employee import EmployeeService, DepartmentService, DesignationService, BranchService

router = APIRouter()


# ── Departments ──────────────────────────────────────
@router.get("/departments", response_model=PaginatedResponse[DepartmentResponse])
async def list_departments(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DepartmentService(db)
    items, total = await service.list_departments(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/departments", response_model=DepartmentResponse, status_code=201)
async def create_department(
    data: DepartmentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DepartmentService(db)
    return await service.create_department(current_user.tenant_id, data)


@router.put("/departments/{department_id}", response_model=DepartmentResponse)
async def update_department(
    department_id: uuid.UUID,
    data: DepartmentUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DepartmentService(db)
    return await service.update_department(department_id, current_user.tenant_id, data)


@router.delete("/departments/{department_id}", response_model=ResponseBase)
async def delete_department(
    department_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DepartmentService(db)
    await service.delete_department(department_id, current_user.tenant_id)
    return ResponseBase(message="Department deleted")


# ── Designations ─────────────────────────────────────
@router.get("/designations", response_model=PaginatedResponse[DesignationResponse])
async def list_designations(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DesignationService(db)
    items, total = await service.list_designations(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/designations", response_model=DesignationResponse, status_code=201)
async def create_designation(
    data: DesignationCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DesignationService(db)
    return await service.create_designation(current_user.tenant_id, data)


@router.put("/designations/{designation_id}", response_model=DesignationResponse)
async def update_designation(
    designation_id: uuid.UUID,
    data: DesignationUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DesignationService(db)
    return await service.update_designation(designation_id, current_user.tenant_id, data)


@router.delete("/designations/{designation_id}", response_model=ResponseBase)
async def delete_designation(
    designation_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = DesignationService(db)
    await service.delete_designation(designation_id, current_user.tenant_id)
    return ResponseBase(message="Designation deleted")


# ── Branches ─────────────────────────────────────────
@router.get("/branches", response_model=PaginatedResponse[BranchResponse])
async def list_branches(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = BranchService(db)
    items, total = await service.list_branches(current_user.tenant_id, page, page_size)
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/branches", response_model=BranchResponse, status_code=201)
async def create_branch(
    data: BranchCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = BranchService(db)
    return await service.create_branch(current_user.tenant_id, data)


@router.put("/branches/{branch_id}", response_model=BranchResponse)
async def update_branch(
    branch_id: uuid.UUID,
    data: BranchUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = BranchService(db)
    return await service.update_branch(branch_id, current_user.tenant_id, data)


@router.delete("/branches/{branch_id}", response_model=ResponseBase)
async def delete_branch(
    branch_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = BranchService(db)
    await service.delete_branch(branch_id, current_user.tenant_id)
    return ResponseBase(message="Branch deleted")


# ── Employees ────────────────────────────────────────
@router.get("/", response_model=PaginatedResponse[EmployeeResponse])
async def list_employees(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    search: str = Query(None),
    department_id: uuid.UUID = Query(None),
    designation_id: uuid.UUID = Query(None),
    branch_id: uuid.UUID = Query(None),
    status: str = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    items, total = await service.list_employees(
        current_user.tenant_id, page=page, page_size=page_size,
        search=search, department_id=department_id,
        designation_id=designation_id, branch_id=branch_id, status=status,
    )
    return PaginatedResponse(items=items, total=total, page=page, page_size=page_size,
                             total_pages=(total + page_size - 1) // page_size)


@router.post("/", response_model=EmployeeResponse, status_code=201)
async def create_employee(
    data: EmployeeCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    return await service.create_employee(current_user.tenant_id, data)


@router.post("/bulk-import", response_model=ResponseBase)
async def bulk_import(
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    content = await file.read()
    service = EmployeeService(db)
    count, errors = await service.bulk_import(current_user.tenant_id, content, file.filename)
    return ResponseBase(
        message=f"Imported {count} employees" + (f", {len(errors)} errors" if errors else ""),
        data={"created": count, "errors": errors},
    )


@router.get("/{employee_id}", response_model=EmployeeResponse)
async def get_employee(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    emp = await service.get_employee(employee_id, current_user.tenant_id)
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return emp


@router.put("/{employee_id}", response_model=EmployeeResponse)
async def update_employee(
    employee_id: uuid.UUID,
    data: EmployeeUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    return await service.update_employee(employee_id, current_user.tenant_id, data)


@router.delete("/{employee_id}", response_model=ResponseBase)
async def delete_employee(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    await service.delete_employee(employee_id, current_user.tenant_id)
    return ResponseBase(message="Employee deleted successfully")


@router.post("/{employee_id}/deactivate", response_model=EmployeeResponse)
async def deactivate_employee(
    employee_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = EmployeeService(db)
    return await service.update_employee(employee_id, current_user.tenant_id, EmployeeUpdate(status="inactive"))
