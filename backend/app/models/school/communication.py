"""School Events and Circular models."""

from sqlalchemy import Column, String, Boolean, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class SchoolEvent(TenantModel):
    __tablename__ = "school_events"

    title = Column(String(255), nullable=False)
    description = Column(Text)
    event_type = Column(String(30), default="general")  # sports/academic/cultural/ptm/holiday/general
    start_date = Column(DateTime(timezone=True), nullable=False)
    end_date = Column(DateTime(timezone=True))
    venue = Column(String(255))
    organizer_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    target_audience = Column(JSONB, default=[])
    is_public = Column(Boolean, default=False)
    attachment_urls = Column(JSONB, default=[])


class Circular(TenantModel):
    __tablename__ = "circulars"

    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    circular_type = Column(String(30), default="general")  # general/academic/fee/event/emergency
    target_audience = Column(JSONB, default=[])
    attachment_urls = Column(JSONB, default=[])
    published_at = Column(DateTime(timezone=True))
    published_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    is_active = Column(Boolean, default=True)
