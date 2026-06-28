"""Certificate template and issuance models."""

from sqlalchemy import Column, String, Boolean, Date, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.base import TenantModel


class CertificateTemplate(TenantModel):
    __tablename__ = "certificate_templates"

    name = Column(String(100), nullable=False)
    template_type = Column(String(30), nullable=False)  # bonafide/transfer/conduct/character/study/custom
    template_html = Column(Text)
    template_json = Column(JSONB)
    is_default = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)


class IssuedCertificate(TenantModel):
    __tablename__ = "issued_certificates"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    template_id = Column(UUID(as_uuid=True), ForeignKey("certificate_templates.id"), nullable=False)
    certificate_number = Column(String(50), nullable=False)
    issue_date = Column(Date, nullable=False)
    purpose = Column(String(255))
    issued_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    pdf_url = Column(String(512))
    qr_code = Column(String(255))
