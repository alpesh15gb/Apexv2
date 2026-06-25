"""Shift schemas."""

import uuid
from datetime import time, date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class ShiftBase(BaseModel):
    name: str = Field(..., max_length=100)
    start_time: time
    end_time: time
    grace_period_minutes: int = Field(default=10, ge=0)
    late_rule_minutes: int = Field(default=15, ge=0)
    early_rule_minutes: int = Field(default=15, ge=0)
    overtime_threshold_minutes: int = Field(default=30, ge=0)
    is_night_shift: bool = False
    is_active: bool = True


class ShiftCreate(ShiftBase):
    pass


class ShiftUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=100)
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    grace_period_minutes: Optional[int] = None
    late_rule_minutes: Optional[int] = None
    early_rule_minutes: Optional[int] = None
    overtime_threshold_minutes: Optional[int] = None
    is_night_shift: Optional[bool] = None
    is_active: Optional[bool] = None


class ShiftResponse(ShiftBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    created_at: datetime
    updated_at: datetime


class ShiftScheduleCreate(BaseModel):
    employee_id: uuid.UUID
    shift_id: uuid.UUID
    effective_from: date
    effective_to: Optional[date] = None
    day_of_week: Optional[int] = None


class ShiftScheduleResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    shift_id: uuid.UUID
    effective_from: date
    effective_to: Optional[date] = None
    day_of_week: Optional[int] = None
    shift_name: Optional[str] = None
    created_at: datetime
