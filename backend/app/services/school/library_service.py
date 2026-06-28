import uuid
from typing import Any, Dict, List, Optional, Tuple, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.library import LibraryBook, LibraryTransaction


class LibraryService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_books(
        self,
        tenant_id: uuid.UUID,
        search: Optional[str] = None,
        category: Optional[str] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        stmt = select(LibraryBook).where(LibraryBook.tenant_id == tenant_id, LibraryBook.is_active == True)
        count_stmt = select(func.count(LibraryBook.id)).where(LibraryBook.tenant_id == tenant_id, LibraryBook.is_active == True)
        if search:
            search_filter = LibraryBook.title.ilike(f"%{search}%") | LibraryBook.author.ilike(f"%{search}%")
            stmt = stmt.where(search_filter)
            count_stmt = count_stmt.where(search_filter)
        if category:
            stmt = stmt.where(LibraryBook.category == category)
            count_stmt = count_stmt.where(LibraryBook.category == category)

        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.order_by(LibraryBook.title).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        books = result.scalars().all()
        items = [
            {
                "id": str(b.id), "title": b.title, "author": b.author, "isbn": b.isbn,
                "category": b.category, "total_copies": b.total_copies,
                "available_copies": b.available_copies, "shelf_location": b.shelf_location,
            }
            for b in books
        ]
        return items, total

    async def add_book(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> LibraryBook:
        if not isinstance(data, dict):
            data = data.model_dump()
        book = LibraryBook(tenant_id=tenant_id, available_copies=data.get("total_copies", 1), **data)
        self.db.add(book)
        await self.db.commit()
        await self.db.refresh(book)
        return book

    async def issue_book(
        self, tenant_id: uuid.UUID, issued_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> LibraryTransaction:
        if not isinstance(data, dict):
            data = data.model_dump()
        book = await self.db.get(LibraryBook, data["book_id"])
        if not book or book.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")
        if book.available_copies <= 0:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No copies available")

        transaction = LibraryTransaction(
            tenant_id=tenant_id,
            issued_by=issued_by,
            status="issued",
            **data,
        )
        self.db.add(transaction)
        book.available_copies -= 1
        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def return_book(
        self, tenant_id: uuid.UUID, returned_to: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> LibraryTransaction:
        if not isinstance(data, dict):
            data = data.model_dump()
        transaction = await self.db.get(LibraryTransaction, data["transaction_id"])
        if not transaction or transaction.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transaction not found")

        transaction.return_date = data["return_date"]
        transaction.fine_amount = data.get("fine_amount", 0)
        transaction.returned_to = returned_to
        transaction.status = "returned"

        book = await self.db.get(LibraryBook, transaction.book_id)
        if not book or book.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Book not found")
        book.available_copies += 1

        await self.db.commit()
        await self.db.refresh(transaction)
        return transaction

    async def list_transactions(
        self,
        tenant_id: uuid.UUID,
        borrower_id: Optional[uuid.UUID] = None,
        txn_status: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        stmt = select(LibraryTransaction).where(LibraryTransaction.tenant_id == tenant_id)
        if borrower_id:
            stmt = stmt.where(LibraryTransaction.borrower_id == borrower_id)
        if txn_status:
            stmt = stmt.where(LibraryTransaction.status == txn_status)
        stmt = stmt.order_by(LibraryTransaction.issue_date.desc())
        result = await self.db.execute(stmt)
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
