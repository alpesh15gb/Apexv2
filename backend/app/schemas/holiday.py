"""Holiday schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class HolidayCreate(BaseModel):
    name: str = Field(..., max_length=255)
    date: date
    type: str = Field(default="company", max_length=50)
    description: Optional[str] = None
    is_active: bool = True


class HolidayUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    date: Optional[date] = None
    type: Optional[str] = Field(None, max_length=50)
    description: Optional[str] = None
    is_active: Optional[bool] = None


class HolidayResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    date: date
    type: str
    description: Optional[str] = None
    is_active: bool
    created_at: datetime
    updated_at: datetime
