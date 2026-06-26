"""Notification Template model."""
from sqlalchemy import Column, String, Boolean, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from app.db.base import TenantModel


class NotificationTemplate(TenantModel):
    __tablename__ = "notification_templates"
    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    event_type = Column(String(100), nullable=False)
    channel = Column(String(50), default="in_app", nullable=False)
    subject_template = Column(String(500), nullable=True)
    body_template = Column(Text, nullable=False)
    is_active = Column(Boolean, default=True)
