"""Medical and Discipline endpoints."""

import uuid
from typing import Optional
from datetime import date

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.models.school.medical import HealthRecord, DisciplineIncident
from app.models.school.student import Student

router = APIRouter()


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

medical_router = APIRouter(dependencies=[Depends(require_feature("school_medical"))])


@medical_router.get("/students/{student_id}")
async def get_health_records(
    student_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(HealthRecord).where(HealthRecord.student_id == student_id, HealthRecord.tenant_id == current_user.tenant_id).order_by(HealthRecord.date.desc())
    result = await db.execute(stmt)
    records = result.scalars().all()
    return [
        {"id": str(r.id), "record_type": r.record_type, "date": str(r.date), "description": r.description, "doctor_name": r.doctor_name, "medication": r.medication}
        for r in records
    ]


@medical_router.post("/")
async def create_health_record(
    data: HealthRecordCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    record = HealthRecord(tenant_id=current_user.tenant_id, recorded_by=current_user.id, **data.model_dump())
    db.add(record)
    await db.commit()
    return {"id": str(record.id)}


# ── Discipline ───────────────────────────────────────

discipline_router = APIRouter(dependencies=[Depends(require_feature("school_discipline"))])


@discipline_router.get("/")
async def list_incidents(
    student_id: Optional[uuid.UUID] = None,
    status: Optional[str] = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    stmt = select(DisciplineIncident, Student).join(Student, Student.id == DisciplineIncident.student_id).where(
        DisciplineIncident.tenant_id == current_user.tenant_id
    )
    if student_id:
        stmt = stmt.where(DisciplineIncident.student_id == student_id)
    if status:
        stmt = stmt.where(DisciplineIncident.status == status)
    stmt = stmt.order_by(DisciplineIncident.incident_date.desc())
    result = await db.execute(stmt)
    rows = result.all()
    return [
        {
            "id": str(d.id), "student_name": f"{s.first_name} {s.last_name}", "incident_date": str(d.incident_date),
            "incident_type": d.incident_type, "severity": d.severity, "description": d.description,
            "action_taken": d.action_taken, "status": d.status,
        }
        for d, s in rows
    ]


@discipline_router.post("/")
async def create_incident(
    data: DisciplineIncidentCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    incident = DisciplineIncident(tenant_id=current_user.tenant_id, reported_by=current_user.id, status="open", **data.model_dump())
    db.add(incident)
    await db.commit()
    return {"id": str(incident.id)}


@discipline_router.put("/{incident_id}/resolve")
async def resolve_incident(
    incident_id: uuid.UUID,
    data: dict,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    incident = await db.get(DisciplineIncident, incident_id)
    if not incident or incident.tenant_id != current_user.tenant_id:
        raise HTTPException(status_code=404, detail="Incident not found")
    incident.resolution = data.get("resolution")
    incident.status = "resolved"
    incident.resolved_by = current_user.id
    await db.commit()
    return {"id": str(incident.id)}
