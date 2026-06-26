"""Employee schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, EmailStr, ConfigDict


class EmployeeBase(BaseModel):
    employee_code: str = Field(..., max_length=50)
    first_name: str = Field(..., max_length=100)
    last_name: str = Field(..., max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=20)
    department_id: Optional[uuid.UUID] = None
    designation_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    shift_id: Optional[uuid.UUID] = None
    joining_date: date
    date_of_birth: Optional[date] = None
    gender: Optional[str] = Field(None, max_length=10)
    address: Optional[str] = None
    city: Optional[str] = Field(None, max_length=100)
    state: Optional[str] = Field(None, max_length=100)
    pincode: Optional[str] = Field(None, max_length=10)
    emergency_contact_name: Optional[str] = Field(None, max_length=200)
    emergency_contact_phone: Optional[str] = Field(None, max_length=20)
    blood_group: Optional[str] = Field(None, max_length=5)
    status: str = "active"


class EmployeeCreate(EmployeeBase):
    device_user_id: Optional[str] = None


class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = Field(None, max_length=100)
    last_name: Optional[str] = Field(None, max_length=100)
    email: Optional[EmailStr] = None
    phone: Optional[str] = Field(None, max_length=20)
    department_id: Optional[uuid.UUID] = None
    designation_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    shift_id: Optional[uuid.UUID] = None
    joining_date: Optional[date] = None
    date_of_birth: Optional[date] = None
    gender: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    pincode: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    blood_group: Optional[str] = None
    status: Optional[str] = None
    device_user_id: Optional[str] = None


class EmployeeResponse(EmployeeBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    photo_url: Optional[str] = None
    device_user_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime
    department_name: Optional[str] = None
    designation_name: Optional[str] = None
    branch_name: Optional[str] = None
    shift_name: Optional[str] = None


class EmployeeBulkImport(BaseModel):
    file_content: bytes
    filename: str


class EmployeeFilter(BaseModel):
    department_id: Optional[uuid.UUID] = None
    designation_id: Optional[uuid.UUID] = None
    branch_id: Optional[uuid.UUID] = None
    status: Optional[str] = None
    search: Optional[str] = None


class DepartmentCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    is_active: bool = True


class DepartmentUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    code: Optional[str] = Field(None, max_length=20)
    is_active: Optional[bool] = None


class DepartmentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    code: str
    is_active: bool
    created_at: datetime


class DesignationCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    is_active: bool = True


class DesignationUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    code: Optional[str] = Field(None, max_length=20)
    is_active: Optional[bool] = None


class DesignationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    code: str
    is_active: bool
    created_at: datetime


class BranchCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    address: Optional[str] = None
    city: Optional[str] = None
    is_active: bool = True


class BranchUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    code: Optional[str] = Field(None, max_length=20)
    address: Optional[str] = None
    city: Optional[str] = None
    is_active: Optional[bool] = None


class BranchResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    code: str
    address: Optional[str] = None
    city: Optional[str] = None
    is_active: bool
    created_at: datetime
