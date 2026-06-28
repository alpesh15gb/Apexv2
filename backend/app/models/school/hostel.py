"""Hostel management models."""

from sqlalchemy import Column, String, Boolean, Integer, Date, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class Hostel(TenantModel):
    __tablename__ = "hostels"

    campus_id = Column(UUID(as_uuid=True), ForeignKey("campuses.id"))
    name = Column(String(255), nullable=False)
    hostel_type = Column(String(20), default="boys")  # boys/girls/staff
    warden_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    capacity = Column(Integer, default=100)
    is_active = Column(Boolean, default=True)


class HostelRoom(TenantModel):
    __tablename__ = "hostel_rooms"

    hostel_id = Column(UUID(as_uuid=True), ForeignKey("hostels.id", ondelete="CASCADE"), nullable=False, index=True)
    room_number = Column(String(50), nullable=False)
    floor = Column(Integer, default=0)
    room_type = Column(String(20), default="dormitory")  # dormitory/single/double/triple/quadruple
    capacity = Column(Integer, default=4)
    is_active = Column(Boolean, default=True)


class HostelAllocation(TenantModel):
    __tablename__ = "hostel_allocations"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    hostel_id = Column(UUID(as_uuid=True), ForeignKey("hostels.id"), nullable=False, index=True)
    room_id = Column(UUID(as_uuid=True), ForeignKey("hostel_rooms.id"), nullable=False)
    bed_number = Column(Integer)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date)
    status = Column(String(20), default="active")  # active/vacated/expelled
