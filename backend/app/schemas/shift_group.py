"""Shift Group schemas."""

import uuid
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class ShiftGroupCreate(BaseModel):
    name: str = Field(..., max_length=255)
    description: Optional[str] = None
    shift_ids: List[uuid.UUID] = []


class ShiftGroupUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    is_active: Optional[bool] = None
    shift_ids: Optional[List[uuid.UUID]] = None


class ShiftGroupResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    name: str
    description: Optional[str] = None
    is_active: bool
    created_at: str
    updated_at: str
