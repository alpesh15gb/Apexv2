"""Tenant Settings schemas."""

import uuid
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class TenantSettingsUpdate(BaseModel):
    attendance_year_start_month: Optional[int] = Field(None, ge=1, le=12)
    attendance_year_start_day: Optional[int] = Field(None, ge=1, le=31)
    min_punch_difference_minutes: Optional[int] = Field(None, ge=0)
    punch_begin_before_minutes: Optional[int] = Field(None, ge=0)
    auto_shift_if_no_schedule: Optional[bool] = None
    fixed_shift_mode: Optional[bool] = None


class TenantSettingsResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    attendance_year_start_month: int
    attendance_year_start_day: int
    min_punch_difference_minutes: int
    punch_begin_before_minutes: int
    auto_shift_if_no_schedule: bool
    fixed_shift_mode: bool
    created_at: str
    updated_at: str
