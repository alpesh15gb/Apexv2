"""Medical and Discipline endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature, require_permissions
from app.models.user import User
from app.services.school.medical_service import MedicalService

router = APIRouter(dependencies=[Depends(require_permissions("medical.manage"))])


class HealthRecordCreate(BaseModel):
    student_id: uuid.UUID
    record_type: str = "checkup"
    date: date
    description: Optional[str] = None
    doctor_name: Optional[str] = None
    medication: Optional[str] = None
    next_followup: Optional[date] = None


class DisciplineIncidentCreate(BaseModel):
    student_id: uuid.UUID
    incident_date: date
    incident_type: str = "misconduct"
    severity: str = "minor"
    description: str
    action_taken: Optional[str] = None


# ── Medical ──────────────────────────────────────────

medical_router = APIRouter(dependencies=[Depends(require_feature("school_medical")), Depends(require_permissions("medical.manage"))])


@medical_router.get("/students/{student_id}")
async def get_health_records(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = MedicalService(db)
    return await svc.get_health_records(student_id=student_id, tenant_id=current_user.tenant_id)


@medical_router.post("/")
async def create_health_record(
    data: HealthRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = MedicalService(db)
    record = await svc.create_health_record(
        tenant_id=current_user.tenant_id,
        recorded_by=current_user.id,
        data=data,
    )
    return {"id": str(record.id)}


# ── Discipline ───────────────────────────────────────

discipline_router = APIRouter(dependencies=[Depends(require_feature("school_discipline")), Depends(require_permissions("discipline.manage"))])


@discipline_router.get("/")
async def list_incidents(
    student_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = MedicalService(db)
    return await svc.list_incidents(
        tenant_id=current_user.tenant_id,
        student_id=student_id,
        incident_status=status,
    )


@discipline_router.post("/")
async def create_incident(
    data: DisciplineIncidentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = MedicalService(db)
    incident = await svc.create_incident(
        tenant_id=current_user.tenant_id,
        reported_by=current_user.id,
        data=data,
    )
    return {"id": str(incident.id)}


@discipline_router.put("/{incident_id}/resolve")
async def resolve_incident(
    incident_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    svc = MedicalService(db)
    incident = await svc.resolve_incident(
        incident_id=incident_id,
        tenant_id=current_user.tenant_id,
        resolved_by=current_user.id,
        resolution=data.get("resolution"),
    )
    return {"id": str(incident.id)}
