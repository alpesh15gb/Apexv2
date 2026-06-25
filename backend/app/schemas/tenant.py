import uuid
from datetime import datetime
from typing import Optional, Any, Dict
from pydantic import BaseModel, Field, ConfigDict
from app.models.tenant import SubscriptionPlan

class TenantBase(BaseModel):
    name: str = Field(..., max_length=255)
    slug: str = Field(..., max_length=255)
    domain: Optional[str] = Field(None, max_length=255)
    logo_url: Optional[str] = Field(None, max_length=512)
    max_employees: Optional[int] = None
    subscription_plan: SubscriptionPlan = SubscriptionPlan.FREE
    settings: Dict[str, Any] = Field(default_factory=dict)

class TenantCreate(TenantBase):
    pass

class TenantUpdate(BaseModel):
    name: Optional[str] = Field(None, max_length=255)
    slug: Optional[str] = Field(None, max_length=255)
    domain: Optional[str] = Field(None, max_length=255)
    logo_url: Optional[str] = Field(None, max_length=512)
    is_active: Optional[bool] = None
    max_employees: Optional[int] = None
    subscription_plan: Optional[SubscriptionPlan] = None
    subscription_expires_at: Optional[datetime] = None
    settings: Optional[Dict[str, Any]] = None

class TenantResponse(TenantBase):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    is_active: bool
    subscription_expires_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime
