"""Library management endpoints."""

import uuid
from typing import Optional
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.models.school.library import LibraryBook, LibraryTransaction

router = APIRouter(dependencies=[Depends(require_feature("school_library")), Depends(require_permissions("library.manage"))])


class BookCreate(BaseModel):
    title: str = Field(..., max_length=500)
    author: Optional[str] = None
    isbn: Optional[str] = None
    publisher: Optional[str] = None
    category: Optional[str] = None
    subject: Optional[str] = None
    edition: Optional[str] = None
    year_published: Optional[int] = None
    total_copies: int = 1
    shelf_location: Optional[str] = None
    barcode: Optional[str] = None
    price: Optional[float] = None


class IssueBook(BaseModel):
    book_id: uuid.UUID
    borrower_type: str = "student"
    borrower_id: uuid.UUID
    issue_date: date
    due_date: date


class ReturnBook(BaseModel):
    transaction_id: uuid.UUID
    return_date: date
    fine_amount: float = 0


@router.get("/books")
async def list_books(
    search: Optional[str] = None,
    category: Optional[str] = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(50, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(LibraryBook).where(LibraryBook.tenant_id == current_user.tenant_id, LibraryBook.is_active == True)
    count_stmt = select(func.count(LibraryBook.id)).where(LibraryBook.tenant_id == current_user.tenant_id, LibraryBook.is_active == True)
    if search:
        stmt = stmt.where(LibraryBook.title.ilike(f"%{search}%") | LibraryBook.author.ilike(f"%{search}%"))
        count_stmt = count_stmt.where(LibraryBook.title.ilike(f"%{search}%") | LibraryBook.author.ilike(f"%{search}%"))
    if category:
        stmt = stmt.where(LibraryBook.category == category)
        count_stmt = count_stmt.where(LibraryBook.category == category)

    total = (await db.execute(count_stmt)).scalar() or 0
    stmt = stmt.order_by(LibraryBook.title).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(stmt)
    books = result.scalars().all()
    return {
        "items": [
            {"id": str(b.id), "title": b.title, "author": b.author, "isbn": b.isbn, "category": b.category, "total_copies": b.total_copies, "available_copies": b.available_copies, "shelf_location": b.shelf_location}
            for b in books
        ],
        "total": total,
        "page": page,
        "page_size": page_size,
    }


@router.post("/books")
async def add_book(
    data: BookCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    book = LibraryBook(tenant_id=current_user.tenant_id, available_copies=data.total_copies, **data.model_dump())
    db.add(book)
    await db.commit()
    return {"id": str(book.id)}


@router.post("/issue")
async def issue_book(
    data: IssueBook,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    book = await db.get(LibraryBook, data.book_id)
    if not book or book.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Book not found")
    if book.available_copies <= 0:
        raise HTTPException(status_code=400, detail="No copies available")

    transaction = LibraryTransaction(
        tenant_id=current_user.tenant_id,
        issued_by=current_user.id,
        status="issued",
        **data.model_dump(),
    )
    db.add(transaction)
    book.available_copies -= 1
    await db.commit()
    return {"id": str(transaction.id)}


@router.post("/return")
async def return_book(
    data: ReturnBook,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    transaction = await db.get(LibraryTransaction, data.transaction_id)
    if not transaction or transaction.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Transaction not found")

    transaction.return_date = data.return_date
    transaction.fine_amount = data.fine_amount
    transaction.returned_to = current_user.id
    transaction.status = "returned"

    book = await db.get(LibraryBook, transaction.book_id)
    if not book or book.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Book not found")
    book.available_copies += 1

    await db.commit()
    return {"id": str(transaction.id)}


@router.get("/transactions")
async def list_transactions(
    borrower_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(LibraryTransaction).where(LibraryTransaction.tenant_id == current_user.tenant_id)
    if borrower_id:
        stmt = stmt.where(LibraryTransaction.borrower_id == borrower_id)
    if status:
        stmt = stmt.where(LibraryTransaction.status == status)
    stmt = stmt.order_by(LibraryTransaction.issue_date.desc())
    result = await db.execute(stmt)
    transactions = result.scalars().all()
    return [
        {
            "id": str(t.id), "book_id": str(t.book_id), "borrower_type": t.borrower_type,
            "borrower_id": str(t.borrower_id), "issue_date": str(t.issue_date), "due_date": str(t.due_date),
            "return_date": str(t.return_date) if t.return_date else None,
            "fine_amount": float(t.fine_amount), "status": t.status,
        }
        for t in transactions
    ]
