"""Document schemas."""
import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class DocumentCreate(BaseModel):
    employee_id: Optional[uuid.UUID] = None
    doc_type: str = Field(default="other", max_length=50)
    title: str = Field(..., max_length=255)
    file_path: str = Field(..., max_length=512)
    file_name: str = Field(..., max_length=255)
    file_size: int = 0
    mime_type: Optional[str] = None
    is_confidential: bool = False
    expiry_date: Optional[date] = None
    description: Optional[str] = None


class DocumentUpdate(BaseModel):
    doc_type: Optional[str] = None
    title: Optional[str] = None
    is_confidential: Optional[bool] = None
    expiry_date: Optional[date] = None
    description: Optional[str] = None


class DocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: Optional[uuid.UUID] = None
    doc_type: str
    title: str
    file_path: str
    file_name: str
    file_size: int
    mime_type: Optional[str] = None
    is_confidential: bool
    expiry_date: Optional[date] = None
    description: Optional[str] = None
    created_at: datetime
    updated_at: datetime
