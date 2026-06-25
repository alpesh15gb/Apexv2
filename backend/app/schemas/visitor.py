"""Visitor schemas."""

import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class VisitorCreate(BaseModel):
    name: str = Field(..., max_length=200)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = None
    id_proof_type: Optional[str] = Field(None, max_length=50)
    id_proof_number: Optional[str] = Field(None, max_length=50)
    company: Optional[str] = Field(None, max_length=200)
    address: Optional[str] = None


class VisitorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    photo_url: Optional[str] = None
    id_proof_type: Optional[str] = None
    id_proof_number: Optional[str] = None
    company: Optional[str] = None
    address: Optional[str] = None
    created_at: datetime


class VisitorPassCreate(BaseModel):
    visitor_id: uuid.UUID
    host_employee_id: uuid.UUID
    purpose: str = Field(..., max_length=500)
    expected_date: date
    zone_access: Optional[str] = None


class VisitorPassResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    visitor_id: uuid.UUID
    host_employee_id: uuid.UUID
    purpose: str
    expected_date: date
    check_in_time: Optional[datetime] = None
    check_out_time: Optional[datetime] = None
    pass_number: str
    status: str
    badge_number: Optional[str] = None
    zone_access: Optional[str] = None
    visitor_desk_validated: bool = False
    created_at: datetime
    visitor_name: Optional[str] = None
    host_name: Optional[str] = None


class VisitorCheckIn(BaseModel):
    pass_id: uuid.UUID


class VisitorCheckOut(BaseModel):
    pass_id: uuid.UUID


class VisitorFilter(BaseModel):
    from_date: Optional[date] = None
    to_date: Optional[date] = None
    status: Optional[str] = None
    host_employee_id: Optional[uuid.UUID] = None
    search: Optional[str] = None
