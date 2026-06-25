"""Access control schemas."""

import uuid
from datetime import datetime, date
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class AccessZoneCreate(BaseModel):
    name: str = Field(..., max_length=200)
    description: Optional[str] = None
    branch_id: uuid.UUID
    is_restricted: bool = False
    access_level_required: int = Field(default=1, ge=1)


class AccessZoneResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    description: Optional[str] = None
    branch_id: uuid.UUID
    is_restricted: bool
    access_level_required: int
    created_at: datetime


class DoorCreate(BaseModel):
    name: str = Field(..., max_length=200)
    zone_id: uuid.UUID
    device_id: Optional[uuid.UUID] = None
    is_active: bool = True


class DoorResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    zone_id: uuid.UUID
    device_id: Optional[uuid.UUID] = None
    is_active: bool
    created_at: datetime


class UserAccessLevelCreate(BaseModel):
    employee_id: uuid.UUID
    zone_id: uuid.UUID
    access_level: int = Field(default=1, ge=1)
    valid_from: Optional[date] = None
    valid_to: Optional[date] = None


class UserAccessLevelResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    zone_id: uuid.UUID
    access_level: int
    granted_by: Optional[uuid.UUID] = None
    valid_from: Optional[date] = None
    valid_to: Optional[date] = None
    created_at: datetime
    employee_name: Optional[str] = None
    zone_name: Optional[str] = None


class AccessLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: Optional[uuid.UUID] = None
    visitor_id: Optional[uuid.UUID] = None
    door_id: uuid.UUID
    access_time: datetime
    access_type: str
    granted: bool
    denial_reason: Optional[str] = None
    door_name: Optional[str] = None
