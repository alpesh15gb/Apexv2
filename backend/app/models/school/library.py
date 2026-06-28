"""Library management models."""

from sqlalchemy import Column, String, Boolean, Integer, Date, Numeric, ForeignKey
from sqlalchemy.dialects.postgresql import UUID

from app.db.base import TenantModel


class LibraryBook(TenantModel):
    __tablename__ = "library_books"

    isbn = Column(String(20))
    title = Column(String(500), nullable=False)
    author = Column(String(255))
    publisher = Column(String(255))
    category = Column(String(100))
    subject = Column(String(100))
    edition = Column(String(50))
    year_published = Column(Integer)
    total_copies = Column(Integer, default=1)
    available_copies = Column(Integer, default=1)
    shelf_location = Column(String(50))
    barcode = Column(String(50))
    price = Column(Numeric(10, 2))
    is_active = Column(Boolean, default=True)


class LibraryTransaction(TenantModel):
    __tablename__ = "library_transactions"

    book_id = Column(UUID(as_uuid=True), ForeignKey("library_books.id", ondelete="CASCADE"), nullable=False, index=True)
    borrower_type = Column(String(20), default="student")  # student/employee
    borrower_id = Column(UUID(as_uuid=True), nullable=False, index=True)
    issue_date = Column(Date, nullable=False)
    due_date = Column(Date, nullable=False)
    return_date = Column(Date)
    fine_amount = Column(Numeric(10, 2), default=0)
    fine_paid = Column(Boolean, default=False)
    issued_by = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    returned_to = Column(UUID(as_uuid=True), ForeignKey("employees.id"))
    status = Column(String(20), default="issued")  # issued/returned/overdue/lost
