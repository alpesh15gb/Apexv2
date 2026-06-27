"""Department Shift schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class DepartmentShiftCreate(BaseModel):
    department_id: uuid.UUID
    shift_id: uuid.UUID
    effective_from: date
    effective_to: Optional[date] = None


class DepartmentShiftResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    department_id: uuid.UUID
    shift_id: uuid.UUID
    effective_from: date
    effective_to: Optional[date] = None
    created_at: datetime
    updated_at: datetime
