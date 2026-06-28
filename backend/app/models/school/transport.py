"""Transport management models."""

from sqlalchemy import Column, String, Boolean, Integer, Date, Time, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class TransportRoute(TenantModel):
    __tablename__ = "transport_routes"

    name = Column(String(255), nullable=False)
    code = Column(String(50))
    vehicle_number = Column(String(20))
    vehicle_type = Column(String(30))  # bus/van/minibus
    capacity = Column(Integer, default=40)
    driver_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    helper_id = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    is_active = Column(Boolean, default=True)


class TransportStop(TenantModel):
    __tablename__ = "transport_stops"

    route_id = Column(UUID(as_uuid=True), ForeignKey("transport_routes.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    sequence = Column(Integer, nullable=False)
    pickup_time = Column(Time)
    drop_time = Column(Time)
    latitude = Column(Numeric(10, 8))
    longitude = Column(Numeric(11, 8))


class StudentTransport(TenantModel):
    __tablename__ = "student_transport"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    route_id = Column(UUID(as_uuid=True), ForeignKey("transport_routes.id"), nullable=False, index=True)
    stop_id = Column(UUID(as_uuid=True), ForeignKey("transport_stops.id"), nullable=False)
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    pickup_type = Column(String(10), default="pickup")  # pickup/drop/both
    fee_amount = Column(Numeric(10, 2), default=0)
    is_active = Column(Boolean, default=True)
