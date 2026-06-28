"""Campus, Building, and Room models."""

from sqlalchemy import Column, String, Boolean, Integer, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class Campus(TenantModel):
    __tablename__ = "campuses"

    branch_id = Column(UUID(as_uuid=True), ForeignKey("branches.id"))
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=False)
    address = Column(String)
    phone = Column(String(20))
    email = Column(String(255))
    latitude = Column(Numeric(10, 8))
    longitude = Column(Numeric(11, 8))
    is_active = Column(Boolean, default=True)


class Building(TenantModel):
    __tablename__ = "buildings"

    campus_id = Column(UUID(as_uuid=True), ForeignKey("campuses.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    code = Column(String(50))
    floors = Column(Integer, default=1)
    is_active = Column(Boolean, default=True)


class Room(TenantModel):
    __tablename__ = "rooms"

    building_id = Column(UUID(as_uuid=True), ForeignKey("buildings.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    room_number = Column(String(50))
    floor = Column(Integer, default=0)
    room_type = Column(String(30), default="classroom")  # classroom/lab/library/office/hall/hostel
    capacity = Column(Integer, default=40)
    has_projector = Column(Boolean, default=False)
    has_ac = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
