"""Leave schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class LeaveTypeCreate(BaseModel):
    name: str = Field(..., max_length=100)
    code: str = Field(..., max_length=20)
    default_days: int = Field(..., ge=0)
    is_paid: bool = True
    carry_forward: bool = False
    max_consecutive: Optional[int] = None
    is_active: bool = True


class LeaveTypeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    code: str
    default_days: int
    is_paid: bool
    carry_forward: bool
    max_consecutive: Optional[int] = None
    is_active: bool
    created_at: datetime


class LeaveBalanceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    employee_id: uuid.UUID
    leave_type_id: uuid.UUID
    year: int
    total_days: float
    used_days: float
    pending_days: float
    carried_forward: float
    available_days: float = 0.0
    leave_type_name: Optional[str] = None


class LeaveRequestCreate(BaseModel):
    leave_type_id: uuid.UUID
    start_date: date
    end_date: date
    reason: Optional[str] = None


class LeaveRequestUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern="^(approved|rejected|cancelled)$")
    rejection_reason: Optional[str] = None


class LeaveRejectRequest(BaseModel):
    rejection_reason: Optional[str] = None


class LeaveRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    leave_type_id: uuid.UUID
    start_date: date
    end_date: date
    total_days: float
    reason: Optional[str] = None
    status: str
    approved_by: Optional[uuid.UUID] = None
    approved_at: Optional[datetime] = None
    rejection_reason: Optional[str] = None
    created_at: datetime
    employee_name: Optional[str] = None
    leave_type_name: Optional[str] = None
