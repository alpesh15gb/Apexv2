"""Outdoor Duty schemas."""

import uuid
from datetime import date, time, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class OutdoorDutyCreate(BaseModel):
    employee_id: uuid.UUID
    date: date
    from_time: Optional[time] = None
    to_time: Optional[time] = None
    reason: Optional[str] = None
    location: Optional[str] = None


class OutdoorDutyUpdate(BaseModel):
    status: Optional[str] = None
    approved_by: Optional[uuid.UUID] = None


class OutdoorDutyResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    date: date
    from_time: Optional[time] = None
    to_time: Optional[time] = None
    reason: Optional[str] = None
    location: Optional[str] = None
    status: str
    approved_by: Optional[uuid.UUID] = None
    approved_at: Optional[datetime] = None
    created_at: str
    updated_at: str
