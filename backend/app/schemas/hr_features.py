"""Schemas for Expense, Tax, Benefits, Asset, Travel, Announcement, Poll, Notification."""
import uuid
from datetime import date, datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


# Expense
class ExpenseCategoryCreate(BaseModel):
    name: str; code: str; description: Optional[str] = None; is_active: bool = True
class ExpenseCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; name: str; code: str; description: Optional[str] = None; is_active: bool; created_at: str; updated_at: str

class ExpenseClaimCreate(BaseModel):
    employee_id: uuid.UUID; category_id: Optional[uuid.UUID] = None; amount: float; date: date; description: Optional[str] = None
class ExpenseClaimUpdate(BaseModel):
    status: Optional[str] = None; approved_by: Optional[uuid.UUID] = None
class ExpenseClaimResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; employee_id: uuid.UUID; category_id: Optional[uuid.UUID] = None; amount: float; date: date; description: Optional[str] = None; status: str; approved_by: Optional[uuid.UUID] = None; approved_at: Optional[datetime] = None; created_at: str; updated_at: str


# Tax
class TaxDeclarationCreate(BaseModel):
    employee_id: uuid.UUID; financial_year: str; hra_received: float = 0; rent_paid: float = 0; section_80c: float = 0; section_80d: float = 0; home_loan_interest: float = 0; other_exemptions: float = 0
class TaxDeclarationUpdate(BaseModel):
    hra_received: Optional[float] = None; rent_paid: Optional[float] = None; section_80c: Optional[float] = None; section_80d: Optional[float] = None; home_loan_interest: Optional[float] = None; other_exemptions: Optional[float] = None; status: Optional[str] = None
class TaxDeclarationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; employee_id: uuid.UUID; financial_year: str; hra_received: float; rent_paid: float; section_80c: float; section_80d: float; home_loan_interest: float; other_exemptions: float; status: str; created_at: str; updated_at: str


# Benefits
class BenefitCreate(BaseModel):
    name: str; type: str = "allowance"; amount: float = 0; frequency: str = "monthly"; is_taxable: bool = True
class BenefitResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; name: str; type: str; amount: float; frequency: str; is_taxable: bool; is_active: bool; created_at: str; updated_at: str

class EmployeeBenefitCreate(BaseModel):
    employee_id: uuid.UUID; benefit_id: uuid.UUID; amount: float; effective_from: date
class EmployeeBenefitResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; employee_id: uuid.UUID; benefit_id: uuid.UUID; amount: float; effective_from: date; is_active: bool; created_at: str; updated_at: str


# Assets
class CompanyAssetCreate(BaseModel):
    name: str; asset_code: str; category: str = "other"; serial_number: Optional[str] = None; purchase_date: Optional[date] = None; warranty_expiry: Optional[date] = None; description: Optional[str] = None
class CompanyAssetUpdate(BaseModel):
    name: Optional[str] = None; assigned_to: Optional[uuid.UUID] = None; status: Optional[str] = None; description: Optional[str] = None
class CompanyAssetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; name: str; asset_code: str; category: str; serial_number: Optional[str] = None; assigned_to: Optional[uuid.UUID] = None; status: str; description: Optional[str] = None; created_at: str; updated_at: str


# Travel
class TravelRequestCreate(BaseModel):
    employee_id: uuid.UUID; destination: str; purpose: Optional[str] = None; from_date: date; to_date: date; estimated_cost: float = 0
class TravelRequestUpdate(BaseModel):
    status: Optional[str] = None; approved_by: Optional[uuid.UUID] = None
class TravelRequestResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; employee_id: uuid.UUID; destination: str; purpose: Optional[str] = None; from_date: date; to_date: date; estimated_cost: float; status: str; approved_by: Optional[uuid.UUID] = None; created_at: str; updated_at: str


# Announcements
class AnnouncementCreate(BaseModel):
    title: str; body: str; priority: str = "normal"; publish_at: Optional[datetime] = None; expires_at: Optional[datetime] = None
class AnnouncementResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; title: str; body: str; priority: str; publish_at: Optional[datetime] = None; expires_at: Optional[datetime] = None; is_active: bool; created_at: str; updated_at: str


# Polls
class PollCreate(BaseModel):
    question: str; options: list; expires_at: Optional[datetime] = None; is_anonymous: bool = False
class PollResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; question: str; options: list; expires_at: Optional[datetime] = None; is_anonymous: bool; is_active: bool; created_at: str; updated_at: str

class PollVoteCreate(BaseModel):
    selected_option: int


# Notification Templates
class NotificationTemplateCreate(BaseModel):
    name: str; event_type: str; channel: str = "in_app"; subject_template: Optional[str] = None; body_template: str
class NotificationTemplateResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID; tenant_id: uuid.UUID; name: str; event_type: str; channel: str; subject_template: Optional[str] = None; body_template: str; is_active: bool; created_at: str; updated_at: str
