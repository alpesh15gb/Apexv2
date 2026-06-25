import uuid
from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict

class NotificationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    user_id: uuid.UUID
    title: str
    message: str
    notification_type: str
    channel: Optional[str] = None
    status: str
    sent_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    metadata_: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime


class UnreadCountResponse(BaseModel):
    count: int = 0
