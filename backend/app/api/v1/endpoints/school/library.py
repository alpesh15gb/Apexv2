"""Library management endpoints."""

import uuid
from typing import Optional
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.library_service import LibraryService

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
    svc = LibraryService(db)
    items, total = await svc.list_books(
        tenant_id=current_user.tenant_id,
        search=search,
        category=category,
        page=page,
        page_size=page_size,
    )
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.post("/books")
async def add_book(
    data: BookCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = LibraryService(db)
    book = await svc.add_book(tenant_id=current_user.tenant_id, data=data)
    return {"id": str(book.id)}


@router.post("/issue")
async def issue_book(
    data: IssueBook,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = LibraryService(db)
    transaction = await svc.issue_book(
        tenant_id=current_user.tenant_id,
        issued_by=current_user.id,
        data=data,
    )
    return {"id": str(transaction.id)}


@router.post("/return")
async def return_book(
    data: ReturnBook,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = LibraryService(db)
    transaction = await svc.return_book(
        tenant_id=current_user.tenant_id,
        returned_to=current_user.id,
        data=data,
    )
    return {"id": str(transaction.id)}


@router.get("/transactions")
async def list_transactions(
    borrower_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = LibraryService(db)
    return await svc.list_transactions(
        tenant_id=current_user.tenant_id,
        borrower_id=borrower_id,
        txn_status=status,
    )
