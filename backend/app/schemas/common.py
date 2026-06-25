"""Common Pydantic schemas used across the platform."""

import uuid
from datetime import datetime
from typing import Any, Generic, TypeVar, Optional
from pydantic import BaseModel, Field, ConfigDict

T = TypeVar("T")


class ResponseBase(BaseModel, Generic[T]):
    """Standard API response wrapper."""
    success: bool = True
    message: str = "Success"
    data: Optional[T] = None


class PaginatedResponse(BaseModel, Generic[T]):
    """Paginated list response."""
    success: bool = True
    message: str = "Success"
    items: list[T] = []
    total: int = 0
    page: int = 1
    page_size: int = 20
    total_pages: int = 0


class PaginationParams(BaseModel):
    page: int = Field(default=1, ge=1)
    page_size: int = Field(default=20, ge=1, le=100)
    search: Optional[str] = None
    sort_by: Optional[str] = None
    sort_order: Optional[str] = Field(default="desc", pattern="^(asc|desc)$")


class IDResponse(BaseModel):
    id: uuid.UUID


class StatusResponse(BaseModel):
    status: str
    message: str


class ErrorResponse(BaseModel):
    success: bool = False
    message: str
    error_code: Optional[str] = None
    details: Optional[dict[str, Any]] = None


class DateRangeParams(BaseModel):
    from_date: datetime
    to_date: datetime
