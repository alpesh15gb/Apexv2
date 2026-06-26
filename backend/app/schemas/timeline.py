"""Timeline schemas."""
import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class EmployeeEventCreate(BaseModel):
    employee_id: uuid.UUID
    event_type: str = Field(..., max_length=50)
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    event_date: date


class EmployeeEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    event_type: str
    title: str
    description: Optional[str] = None
    event_date: date
    created_by: Optional[uuid.UUID] = None
    created_at: str
    updated_at: str
