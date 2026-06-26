"""Employee Category schemas."""

import uuid
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class CategoryCreate(BaseModel):
    name: str = Field(..., max_length=255)
    code: str = Field(..., max_length=100)
    is_active: bool = True
    ot_formula: str = Field(default="out_punch", max_length=50)
    min_ot_minutes: int = Field(default=0, ge=0)
    max_ot_minutes: int = Field(default=0, ge=0)
    grace_minutes: int = Field(default=0, ge=0)
    half_day_threshold_minutes: int = Field(default=240, ge=0)
    absent_threshold_minutes: int = Field(default=0, ge=0)
    late_absent_minutes: int = Field(default=0, ge=0)
    late_occurrences_absent_count: int = Field(default=0, ge=0)
    weekly_off_1: int = Field(default=6, ge=0, le=6)
    weekly_off_2: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2_week: str = Field(default="every", max_length=50)
    consider_first_last_punch: bool = True
    neglect_last_in_on_missed_out: bool = False
    consider_early_coming: bool = True
    consider_late_going: bool = True
    deduct_break_hours: bool = True
    mark_wo_holiday_absent_if_prefix_absent: bool = False


class CategoryUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    code: Optional[str] = Field(None, max_length=100)
    is_active: Optional[bool] = None
    ot_formula: Optional[str] = Field(None, max_length=50)
    min_ot_minutes: Optional[int] = Field(None, ge=0)
    max_ot_minutes: Optional[int] = Field(None, ge=0)
    grace_minutes: Optional[int] = Field(None, ge=0)
    half_day_threshold_minutes: Optional[int] = Field(None, ge=0)
    absent_threshold_minutes: Optional[int] = Field(None, ge=0)
    late_absent_minutes: Optional[int] = Field(None, ge=0)
    late_occurrences_absent_count: Optional[int] = Field(None, ge=0)
    weekly_off_1: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2_week: Optional[str] = Field(None, max_length=50)
    consider_first_last_punch: Optional[bool] = None
    neglect_last_in_on_missed_out: Optional[bool] = None
    consider_early_coming: Optional[bool] = None
    consider_late_going: Optional[bool] = None
    deduct_break_hours: Optional[bool] = None
    mark_wo_holiday_absent_if_prefix_absent: Optional[bool] = None


class CategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    code: str
    is_active: bool
    ot_formula: str
    min_ot_minutes: int
    max_ot_minutes: int
    grace_minutes: int
    half_day_threshold_minutes: int
    absent_threshold_minutes: int
    late_absent_minutes: int
    late_occurrences_absent_count: int
    weekly_off_1: int
    weekly_off_2: Optional[int] = None
    weekly_off_2_week: str
    consider_first_last_punch: bool
    neglect_last_in_on_missed_out: bool
    consider_early_coming: bool
    consider_late_going: bool
    deduct_break_hours: bool
    mark_wo_holiday_absent_if_prefix_absent: bool
    created_at: str
    updated_at: str
