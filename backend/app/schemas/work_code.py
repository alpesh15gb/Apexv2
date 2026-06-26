"""Work Code schemas."""

import uuid
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class WorkCodeCreate(BaseModel):
    code: str = Field(..., max_length=50)
    name: str = Field(..., max_length=255)
    description: Optional[str] = None
    is_active: bool = True


class WorkCodeUpdate(BaseModel):
    code: Optional[str] = Field(None, max_length=50)
    name: Optional[str] = Field(None, max_length=255)
    description: Optional[str] = None
    is_active: Optional[bool] = None


class WorkCodeResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    code: str
    name: str
    description: Optional[str] = None
    is_active: bool
    created_at: str
    updated_at: str
