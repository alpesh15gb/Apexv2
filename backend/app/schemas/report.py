"""Report schemas."""

from datetime import date
from typing import Optional
from pydantic import BaseModel, Field


class ReportRequest(BaseModel):
    format: str = Field(default="pdf", pattern="^(pdf|excel|csv)$")
    from_date: Optional[date] = None
    to_date: Optional[date] = None
    date: Optional[date] = None
    month: Optional[int] = Field(None, ge=1, le=12)
    year: Optional[int] = None
    employee_id: Optional[str] = None
    department_id: Optional[str] = None
