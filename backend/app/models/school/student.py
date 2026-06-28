"""Student, Guardian, and related models."""

from sqlalchemy import Column, String, Boolean, Date, Integer, Text, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class Student(TenantModel):
    __tablename__ = "students"

    admission_number = Column(String(50), nullable=False)
    roll_number = Column(String(20))
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    middle_name = Column(String(100))
    date_of_birth = Column(Date, nullable=False)
    gender = Column(String(10), nullable=False)
    blood_group = Column(String(5))
    nationality = Column(String(50), default="Indian")
    religion = Column(String(50))
    caste = Column(String(50))
    category = Column(String(20))  # General/OBC/SC/ST/EWS
    aadhaar_number = Column(String(12))
    email = Column(String(255))
    phone = Column(String(20))
    address = Column(Text)
    city = Column(String(100))
    state = Column(String(100))
    pincode = Column(String(10))
    photo_url = Column(String(512))
    admission_date = Column(Date, nullable=False)
    admission_grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id"))
    current_grade_id = Column(UUID(as_uuid=True), ForeignKey("grades.id"), index=True)
    current_section_id = Column(UUID(as_uuid=True), ForeignKey("sections.id"), index=True)
    house_id = Column(UUID(as_uuid=True), ForeignKey("houses.id"))
    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id"), nullable=False, index=True)
    status = Column(String(20), default="active")  # active/transferred/graduated/dropped/expelled
    previous_school = Column(String(255))
    previous_grade = Column(String(50))
    transfer_certificate_number = Column(String(100))
    medical_conditions = Column(Text)
    allergies = Column(Text)
    emergency_contact_name = Column(String(255))
    emergency_contact_phone = Column(String(20))
    emergency_contact_relation = Column(String(50))
    transport_route_id = Column(UUID(as_uuid=True), ForeignKey("transport_routes.id"))
    hostel_room_id = Column(UUID(as_uuid=True), ForeignKey("hostel_rooms.id"))
    is_active = Column(Boolean, default=True)


class Guardian(TenantModel):
    __tablename__ = "guardians"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id"))
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    email = Column(String(255))
    phone = Column(String(20), nullable=False)
    alternate_phone = Column(String(20))
    occupation = Column(String(100))
    workplace = Column(String(255))
    annual_income = Column(Integer)
    education = Column(String(100))
    address = Column(Text)
    photo_url = Column(String(512))
    is_active = Column(Boolean, default=True)


class StudentGuardian(TenantModel):
    __tablename__ = "student_guardians"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    guardian_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    relationship = Column(String(30), nullable=False)  # father/mother/guardian
    is_primary = Column(Boolean, default=False)
    is_emergency_contact = Column(Boolean, default=False)
    can_pickup = Column(Boolean, default=True)


class StudentSibling(TenantModel):
    __tablename__ = "student_siblings"

    student_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
    sibling_id = Column(UUID(as_uuid=True), ForeignKey("students.id", ondelete="CASCADE"), nullable=False, index=True)
