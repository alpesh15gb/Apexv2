"""OT Register schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class OTRegisterCreate(BaseModel):
    employee_id: uuid.UUID
    date: date
    ot_hours: float = Field(ge=0)
    ot_type: str = Field(default="normal", max_length=50)
    remarks: Optional[str] = None


class OTRegisterUpdate(BaseModel):
    status: Optional[str] = None
    approved_by: Optional[uuid.UUID] = None
    remarks: Optional[str] = None


class OTRegisterResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    date: date
    ot_hours: float
    ot_type: str
    status: str
    approved_by: Optional[uuid.UUID] = None
    remarks: Optional[str] = None
    created_at: str
    updated_at: str
