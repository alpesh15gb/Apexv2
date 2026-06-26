"""Document model — employee document storage."""

import enum
from sqlalchemy import Column, String, Integer, Boolean, Date, Text, ForeignKey, DateTime
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import TenantModel


class DocumentType(str, enum.Enum):
    OFFER_LETTER = "offer_letter"
    EXPERIENCE_LETTER = "experience_letter"
    ID_PROOF = "id_proof"
    ADDRESS_PROOF = "address_proof"
    CERTIFICATE = "certificate"
    POLICY = "policy"
    OTHER = "other"


class Document(TenantModel):
    __tablename__ = "documents"

    tenant_id = Column(UUID(as_uuid=True), ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    employee_id = Column(UUID(as_uuid=True), ForeignKey("employees.id", ondelete="CASCADE"), nullable=True, index=True)
    doc_type = Column(String(50), default=DocumentType.OTHER, nullable=False)
    title = Column(String(255), nullable=False)
    file_path = Column(String(512), nullable=False)
    file_name = Column(String(255), nullable=False)
    file_size = Column(Integer, default=0)
    mime_type = Column(String(100), nullable=True)
    uploaded_by = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    is_confidential = Column(Boolean, default=False, nullable=False)
    expiry_date = Column(Date, nullable=True)
    description = Column(Text, nullable=True)

    employee = relationship("Employee")
    uploader = relationship("User")
