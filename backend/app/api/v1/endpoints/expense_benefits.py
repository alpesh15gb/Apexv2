"""Expense, Tax, Benefits CRUD endpoints."""
import uuid
from typing import List, Optional
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_permissions, require_permissions, require_feature
from app.models.user import User
from app.models.expense import ExpenseCategory, ExpenseClaim
from app.models.tax import TaxDeclaration
from app.models.benefit import Benefit, EmployeeBenefit
from app.schemas.common import ResponseBase
from app.schemas.hr_features import (
    ExpenseCategoryCreate, ExpenseCategoryResponse,
    ExpenseClaimCreate, ExpenseClaimUpdate, ExpenseClaimResponse,
    TaxDeclarationCreate, TaxDeclarationUpdate, TaxDeclarationResponse,
    BenefitCreate, BenefitResponse,
    EmployeeBenefitCreate, EmployeeBenefitResponse,
)

router = APIRouter(dependencies=[Depends(require_feature("expense")), Depends(require_permissions("expense.read"))])


# ── Expense Categories ──────────────────────────────────
@router.get("/expense-categories", response_model=List[ExpenseCategoryResponse])
async def list_expense_categories(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    return list((await db.execute(select(ExpenseCategory).where(ExpenseCategory.tenant_id == current_user.tenant_id))).scalars().all())

@router.post("/expense-categories", response_model=ExpenseCategoryResponse, status_code=201)
async def create_expense_category(data: ExpenseCategoryCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    cat = ExpenseCategory(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(cat); await db.commit(); await db.refresh(cat)
    return cat


# ── Expense Claims ──────────────────────────────────────
@router.get("/expense-claims", response_model=List[ExpenseClaimResponse])
async def list_expense_claims(employee_id: Optional[uuid.UUID] = Query(None), status: Optional[str] = Query(None), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ExpenseClaim).where(ExpenseClaim.tenant_id == current_user.tenant_id)
    if employee_id: stmt = stmt.where(ExpenseClaim.employee_id == employee_id)
    if status: stmt = stmt.where(ExpenseClaim.status == status)
    return list((await db.execute(stmt.order_by(ExpenseClaim.created_at.desc()))).scalars().all())

@router.post("/expense-claims", response_model=ExpenseClaimResponse, status_code=201)
async def create_expense_claim(data: ExpenseClaimCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    claim = ExpenseClaim(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(claim); await db.commit(); await db.refresh(claim)
    return claim

@router.put("/expense-claims/{claim_id}", response_model=ExpenseClaimResponse)
async def update_expense_claim(claim_id: uuid.UUID, data: ExpenseClaimUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(ExpenseClaim).where(ExpenseClaim.id == claim_id, ExpenseClaim.tenant_id == current_user.tenant_id)
    claim = (await db.execute(stmt)).scalar_one_or_none()
    if not claim: raise HTTPException(status_code=404, detail="Claim not found")
    update_data = data.model_dump(exclude_unset=True)
    if 'status' in update_data and update_data['status'] == 'approved':
        update_data['approved_at'] = datetime.now(timezone.utc)
    for field, val in update_data.items(): setattr(claim, field, val)
    await db.commit(); await db.refresh(claim)
    return claim


# ── Tax Declarations ────────────────────────────────────
@router.get("/tax-declarations", response_model=List[TaxDeclarationResponse])
async def list_tax_declarations(employee_id: Optional[uuid.UUID] = Query(None), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(TaxDeclaration).where(TaxDeclaration.tenant_id == current_user.tenant_id)
    if employee_id: stmt = stmt.where(TaxDeclaration.employee_id == employee_id)
    return list((await db.execute(stmt)).scalars().all())

@router.post("/tax-declarations", response_model=TaxDeclarationResponse, status_code=201)
async def create_tax_declaration(data: TaxDeclarationCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    td = TaxDeclaration(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(td); await db.commit(); await db.refresh(td)
    return td

@router.put("/tax-declarations/{td_id}", response_model=TaxDeclarationResponse)
async def update_tax_declaration(td_id: uuid.UUID, data: TaxDeclarationUpdate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(TaxDeclaration).where(TaxDeclaration.id == td_id, TaxDeclaration.tenant_id == current_user.tenant_id)
    td = (await db.execute(stmt)).scalar_one_or_none()
    if not td: raise HTTPException(status_code=404, detail="Tax declaration not found")
    for field, val in data.model_dump(exclude_unset=True).items(): setattr(td, field, val)
    await db.commit(); await db.refresh(td)
    return td


# ── Benefits ────────────────────────────────────────────
@router.get("/benefits", response_model=List[BenefitResponse])
async def list_benefits(db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    return list((await db.execute(select(Benefit).where(Benefit.tenant_id == current_user.tenant_id))).scalars().all())

@router.post("/benefits", response_model=BenefitResponse, status_code=201)
async def create_benefit(data: BenefitCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    b = Benefit(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(b); await db.commit(); await db.refresh(b)
    return b

@router.get("/employee-benefits", response_model=List[EmployeeBenefitResponse])
async def list_employee_benefits(employee_id: Optional[uuid.UUID] = Query(None), db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    stmt = select(EmployeeBenefit).where(EmployeeBenefit.tenant_id == current_user.tenant_id)
    if employee_id: stmt = stmt.where(EmployeeBenefit.employee_id == employee_id)
    return list((await db.execute(stmt)).scalars().all())

@router.post("/employee-benefits", response_model=EmployeeBenefitResponse, status_code=201)
async def assign_benefit(data: EmployeeBenefitCreate, db: AsyncSession = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    eb = EmployeeBenefit(tenant_id=current_user.tenant_id, **data.model_dump())
    db.add(eb); await db.commit(); await db.refresh(eb)
    return eb
