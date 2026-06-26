"""Onboarding schemas."""
import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class OnboardingTaskCreate(BaseModel):
    employee_id: uuid.UUID
    title: str = Field(..., max_length=255)
    description: Optional[str] = None
    assigned_to: Optional[uuid.UUID] = None
    due_date: Optional[date] = None
    order_index: int = 0


class OnboardingTaskUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    assigned_to: Optional[uuid.UUID] = None
    due_date: Optional[date] = None
    status: Optional[str] = None
    order_index: Optional[int] = None


class OnboardingTaskResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    title: str
    description: Optional[str] = None
    assigned_to: Optional[uuid.UUID] = None
    due_date: Optional[date] = None
    status: str
    completed_at: Optional[datetime] = None
    order_index: int
    created_at: str
    updated_at: str
