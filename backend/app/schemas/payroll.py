"""Payroll schemas."""

import uuid
from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class SalaryStructureCreate(BaseModel):
    employee_id: uuid.UUID
    basic: float = 0
    hra: float = 0
    da: float = 0
    conveyance: float = 0
    medical: float = 0
    special: float = 0
    pf_employee: float = 0
    pf_employer: float = 0
    esi_employee: float = 0
    esi_employer: float = 0
    professional_tax: float = 0
    income_tax: float = 0
    effective_from: date


class SalaryStructureUpdate(BaseModel):
    basic: Optional[float] = None
    hra: Optional[float] = None
    da: Optional[float] = None
    conveyance: Optional[float] = None
    medical: Optional[float] = None
    special: Optional[float] = None
    pf_employee: Optional[float] = None
    pf_employer: Optional[float] = None
    esi_employee: Optional[float] = None
    esi_employer: Optional[float] = None
    professional_tax: Optional[float] = None
    income_tax: Optional[float] = None
    is_active: Optional[bool] = None


class SalaryStructureResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    basic: float
    hra: float
    da: float
    conveyance: float
    medical: float
    special: float
    pf_employee: float
    pf_employer: float
    esi_employee: float
    esi_employer: float
    professional_tax: float
    income_tax: float
    effective_from: date
    is_active: bool
    created_at: str
    updated_at: str


class PaySlipResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    month: int
    year: int
    basic: float
    hra: float
    da: float
    conveyance: float
    medical: float
    special: float
    gross_earnings: float
    pf: float
    esi: float
    pt: float
    it: float
    total_deductions: float
    net_pay: float
    working_days: int
    present_days: int
    absent_days: int
    leave_days: int
    ot_hours: float
    ot_amount: float
    lop_days: int
    lop_amount: float
    status: str
    generated_at: Optional[datetime] = None
    created_at: str
    updated_at: str


class LoanCreate(BaseModel):
    employee_id: uuid.UUID
    loan_type: str = Field(..., max_length=100)
    amount: float = Field(gt=0)
    emi_amount: float = Field(gt=0)
    start_date: date
    total_installments: int = Field(gt=0)


class LoanResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    tenant_id: uuid.UUID
    employee_id: uuid.UUID
    loan_type: str
    amount: float
    emi_amount: float
    start_date: date
    total_installments: int
    paid_installments: int
    status: str
    created_at: str
    updated_at: str
