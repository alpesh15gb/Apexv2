"""Device schemas."""

import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class DeviceBase(BaseModel):
    serial_number: str = Field(..., max_length=100)
    device_name: str = Field(..., max_length=200)
    model: Optional[str] = Field(None, max_length=100)
    firmware_version: Optional[str] = Field(None, max_length=50)
    ip_address: Optional[str] = Field(None, max_length=45)
    port: Optional[int] = None
    location: Optional[str] = Field(None, max_length=200)
    branch_id: Optional[uuid.UUID] = None
    device_type: str = "biometric"
    communication_mode: str = "tcp/ip"


class DeviceCreate(DeviceBase):
    pass


class DeviceUpdate(BaseModel):
    device_name: Optional[str] = Field(None, max_length=200)
    model: Optional[str] = None
    firmware_version: Optional[str] = None
    ip_address: Optional[str] = None
    port: Optional[int] = None
    location: Optional[str] = None
    branch_id: Optional[uuid.UUID] = None
    device_type: Optional[str] = None
    communication_mode: Optional[str] = None
    is_active: Optional[bool] = None


class DeviceResponse(DeviceBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    last_ping: Optional[datetime] = None
    last_sync: Optional[datetime] = None
    status: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
    branch_name: Optional[str] = None


class DeviceCommandCreate(BaseModel):
    device_id: uuid.UUID
    command_type: str
    parameters: Optional[dict] = None


class DeviceCommandResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    device_id: uuid.UUID
    command_type: str
    parameters: Optional[dict] = None
    status: str
    requested_by: uuid.UUID
    requested_at: datetime
    sent_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    response_data: Optional[dict] = None
    error_message: Optional[str] = None


class DeviceLogResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    device_id: uuid.UUID
    log_type: str
    message: Optional[str] = None
    raw_data: Optional[dict] = None
    created_at: datetime


class DeviceHealthResponse(BaseModel):
    total_devices: int = 0
    online: int = 0
    offline: int = 0
    inactive: int = 0
    error: int = 0
