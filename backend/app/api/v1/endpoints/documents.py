"""Document CRUD endpoints."""
import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.document import Document
from app.schemas.common import ResponseBase
from app.schemas.document import DocumentCreate, DocumentUpdate, DocumentResponse

router = APIRouter(dependencies=[Depends(require_feature("documents"))])


@router.get("/", response_model=List[DocumentResponse])
async def list_documents(
    employee_id: Optional[uuid.UUID] = Query(None),
    doc_type: Optional[str] = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(Document).where(Document.tenant_id == current_user.tenant_id)
    if employee_id:
        stmt = stmt.where(Document.employee_id == employee_id)
    if doc_type:
        stmt = stmt.where(Document.doc_type == doc_type)
    stmt = stmt.order_by(Document.created_at.desc())
    return list((await db.execute(stmt)).scalars().all())


@router.post("/", response_model=DocumentResponse, status_code=201)
async def create_document(data: DocumentCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    doc = Document(tenant_id=current_user.tenant_id, uploaded_by=current_user.id, **data.model_dump())
    db.add(doc)
    await db.commit()
    await db.refresh(doc)
    return doc


@router.put("/{doc_id}", response_model=DocumentResponse)
async def update_document(doc_id: uuid.UUID, data: DocumentUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(Document).where(Document.id == doc_id, Document.tenant_id == current_user.tenant_id)
    doc = (await db.execute(stmt)).scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    for field, val in data.model_dump(exclude_unset=True).items():
        setattr(doc, field, val)
    await db.commit()
    await db.refresh(doc)
    return doc


@router.delete("/{doc_id}", response_model=ResponseBase)
async def delete_document(doc_id: uuid.UUID, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(Document).where(Document.id == doc_id, Document.tenant_id == current_user.tenant_id)
    doc = (await db.execute(stmt)).scalar_one_or_none()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    await db.delete(doc)
    await db.commit()
    return ResponseBase(message="Document deleted")
