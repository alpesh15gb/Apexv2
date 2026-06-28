"""Health Records and Discipline models."""

from sqlalchemy import Column, String, Boolean, Date, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class HealthRecord(TenantModel):
    __tablename__ = "health_records"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    record_type = Column(String(30), default="checkup")  # checkup/vaccination/illness/injury
    date = Column(Date, nullable=False)
    description = Column(Text)
    doctor_name = Column(String(255))
    medication = Column(Text)
    next_followup = Column(Date)
    attachment_urls = Column(JSONB, default=[])
    recorded_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))


class DisciplineIncident(TenantModel):
    __tablename__ = "discipline_incidents"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    incident_date = Column(Date, nullable=False)
    incident_type = Column(String(30), default="misconduct")  # misconduct/bullying/absenteeism/uniform/other
    severity = Column(String(20), default="minor")  # minor/moderate/major/severe
    description = Column(Text, nullable=False)
    action_taken = Column(Text)
    reported_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    parent_informed = Column(Boolean, default=False)
    parent_meeting_date = Column(Date)
    status = Column(String(20), default="open")  # open/in_review/resolved/escalated
    resolution = Column(Text)
    resolved_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
