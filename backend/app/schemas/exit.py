"""Exit schemas."""
import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class ExitRequestCreate(BaseModel):
    employee_id: uuid.UUID
    resignation_date: date
    last_working_date: Optional[date] = None
    reason: Optional[str] = None


class ExitRequestUpdate(BaseModel):
    status: Optional[str] = None
    approved_by: Optional[uuid.UUID] = None
    last_working_date: Optional[date] = None
    exit_interview_notes: Optional[str] = None
    clearance_status: Optional[str] = None


class ExitRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    resignation_date: date
    last_working_date: Optional[date] = None
    reason: Optional[str] = None
    status: str
    approved_by: Optional[uuid.UUID] = None
    approved_at: Optional[datetime] = None
    exit_interview_notes: Optional[str] = None
    clearance_status: str
    created_at: str
    updated_at: str
