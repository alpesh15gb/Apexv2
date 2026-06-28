"""Grade, Section, and House models."""

from sqlalchemy import Column, String, Boolean, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class Grade(TenantModel):
    __tablename__ = "grades"

    name = Column(String(100), nullable=False)
    code = Column(String(20), nullable=False)
    sort_order = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)


class Section(TenantModel):
    __tablename__ = "sections"

    grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(50), nullable=False)
    capacity = Column(Integer, default=40)
    room_id = Column(UUID(as_uuid=True), ForeignKey("rooms.id"))
    class_teacher_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    is_active = Column(Boolean, default=True)


class House(TenantModel):
    __tablename__ = "houses"

    name = Column(String(100), nullable=False)
    code = Column(String(20))
    color = Column(String(20))
    house_master_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    is_active = Column(Boolean, default=True)
