"""Academic Year, Term, and Holiday models."""

from sqlalchemy import Column, String, Boolean, Date, Integer, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class AcademicYear(TenantModel):
    __tablename__ = "academic_years"

    name = Column(String(50), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    is_current = Column(Boolean, default=False)
    promotion_date = Column(Date)
    status = Column(String(20), default="planning")  # planning/active/closed/archived


class AcademicTerm(TenantModel):
    __tablename__ = "academic_terms"

    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(50), nullable=False)
    start_date = Column(Date, nullable=False)
    end_date = Column(Date, nullable=False)
    sort_order = Column(Integer, default=0)


class SchoolHoliday(TenantModel):
    __tablename__ = "school_holidays"

    academic_year_id = Column(UUID(as_uuid=True), ForeignKey("academic_years.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    date = Column(Date, nullable=False)
    type = Column(String(30), default="holiday")  # holiday/exam/vacation/event
