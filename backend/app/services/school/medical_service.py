import uuid
from typing import Any, Dict, List, Optional, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.medical import HealthRecord, DisciplineIncident
from app.models.school.student import Student


class MedicalService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_health_records(self, student_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(HealthRecord).where(
            HealthRecord.student_id == student_id, HealthRecord.tenant_id == tenant_id
        ).order_by(HealthRecord.date.desc())
        result = await self.db.execute(stmt)
        records = result.scalars().all()
        return [
            {
                "id": str(r.id), "record_type": r.record_type, "date": str(r.date),
                "description": r.description, "doctor_name": r.doctor_name, "medication": r.medication,
            }
            for r in records
        ]

    async def create_health_record(
        self, tenant_id: uuid.UUID, recorded_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> HealthRecord:
        if not isinstance(data, dict):
            data = data.model_dump()
        record = HealthRecord(tenant_id=tenant_id, recorded_by=recorded_by, **data)
        self.db.add(record)
        await self.db.commit()
        await self.db.refresh(record)
        return record

    async def list_incidents(
        self,
        tenant_id: uuid.UUID,
        student_id: Optional[uuid.UUID] = None,
        incident_status: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        stmt = select(DisciplineIncident, Student).join(
            Student, Student.id == DisciplineIncident.student_id
        ).where(DisciplineIncident.tenant_id == tenant_id)
        if student_id:
            stmt = stmt.where(DisciplineIncident.student_id == student_id)
        if incident_status:
            stmt = stmt.where(DisciplineIncident.status == incident_status)
        stmt = stmt.order_by(DisciplineIncident.incident_date.desc())
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(d.id), "student_name": f"{s.first_name} {s.last_name}",
                "incident_date": str(d.incident_date), "incident_type": d.incident_type,
                "severity": d.severity, "description": d.description,
                "action_taken": d.action_taken, "status": d.status,
            }
            for d, s in rows
        ]

    async def create_incident(
        self, tenant_id: uuid.UUID, reported_by: uuid.UUID, data: Union[Dict[str, Any], Any]
    ) -> DisciplineIncident:
        if not isinstance(data, dict):
            data = data.model_dump()
        incident = DisciplineIncident(tenant_id=tenant_id, reported_by=reported_by, status="open", **data)
        self.db.add(incident)
        await self.db.commit()
        await self.db.refresh(incident)
        return incident

    async def resolve_incident(
        self, incident_id: uuid.UUID, tenant_id: uuid.UUID, resolved_by: uuid.UUID, resolution: Optional[str] = None
    ) -> DisciplineIncident:
        incident = await self.db.get(DisciplineIncident, incident_id)
        if not incident or incident.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Incident not found")
        incident.resolution = resolution
        incident.status = "resolved"
        incident.resolved_by = resolved_by
        await self.db.commit()
        await self.db.refresh(incident)
        return incident
