"""Shift Roster schemas."""

import uuid
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class ShiftRosterCreate(BaseModel):
    name: str = Field(..., max_length=255)
    description: Optional[str] = None
    rotation_pattern: str = Field(default="weekly", max_length=50)
    weekly_off_1: int = Field(default=6, ge=0, le=6)
    weekly_off_2: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2_week: str = Field(default="every", max_length=50)
    entries: List[dict] = []  # [{day_number: 1, shift_id: uuid}, ...]


class ShiftRosterUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    rotation_pattern: Optional[str] = Field(None, max_length=50)
    weekly_off_1: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2: Optional[int] = Field(None, ge=0, le=6)
    weekly_off_2_week: Optional[str] = Field(None, max_length=50)
    is_active: Optional[bool] = None
    entries: Optional[List[dict]] = None


class ShiftRosterResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    description: Optional[str] = None
    rotation_pattern: str
    weekly_off_1: int
    weekly_off_2: Optional[int] = None
    weekly_off_2_week: str
    is_active: bool
    created_at: datetime
    updated_at: datetime
