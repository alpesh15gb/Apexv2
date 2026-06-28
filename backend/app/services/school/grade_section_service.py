import uuid
from typing import Any, Dict, List, Optional, Union

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.grade import Grade, Section, House
from app.models.school.subject import Subject, GradeSubject, TeacherAllocation
from app.models.school.student import Student


class GradeSectionService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_grades(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(Grade).where(Grade.tenant_id == tenant_id, Grade.is_active == True).order_by(Grade.sort_order)
        result = await self.db.execute(stmt)
        grades = result.scalars().all()
        return [{"id": str(g.id), "name": g.name, "code": g.code, "sort_order": g.sort_order} for g in grades]

    async def create_grade(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Grade:
        if not isinstance(data, dict):
            data = data.model_dump()
        grade = Grade(tenant_id=tenant_id, **data)
        self.db.add(grade)
        await self.db.commit()
        await self.db.refresh(grade)
        return grade

    async def update_grade(self, grade_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Grade:
        grade = await self.db.get(Grade, grade_id)
        if not grade or grade.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Grade not found")
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)
        for field, value in data.items():
            if hasattr(grade, field):
                setattr(grade, field, value)
        await self.db.commit()
        await self.db.refresh(grade)
        return grade

    async def list_sections(
        self, grade_id: uuid.UUID, tenant_id: uuid.UUID, academic_year_id: Optional[uuid.UUID] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(Section).where(
            Section.grade_id == grade_id, Section.tenant_id == tenant_id, Section.is_active == True
        )
        if academic_year_id:
            stmt = stmt.where(Section.academic_year_id == academic_year_id)
        result = await self.db.execute(stmt)
        sections = result.scalars().all()
        return [
            {
                "id": str(s.id), "name": s.name, "capacity": s.capacity,
                "class_teacher_id": str(s.class_teacher_id) if s.class_teacher_id else None,
            }
            for s in sections
        ]

    async def create_section(self, grade_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Section:
        if not isinstance(data, dict):
            data = data.model_dump()
        section = Section(tenant_id=tenant_id, grade_id=grade_id, **data)
        self.db.add(section)
        await self.db.commit()
        await self.db.refresh(section)
        return section

    async def list_section_students(self, section_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(Student).where(
            Student.current_section_id == section_id,
            Student.tenant_id == tenant_id,
            Student.is_active == True,
        ).order_by(Student.roll_number, Student.first_name)
        result = await self.db.execute(stmt)
        students = result.scalars().all()
        return [
            {
                "id": str(s.id), "admission_number": s.admission_number, "roll_number": s.roll_number,
                "first_name": s.first_name, "last_name": s.last_name, "gender": s.gender, "status": s.status,
            }
            for s in students
        ]

    async def list_subjects(self, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = select(Subject).where(Subject.tenant_id == tenant_id, Subject.is_active == True)
        result = await self.db.execute(stmt)
        subjects = result.scalars().all()
        return [
            {"id": str(s.id), "name": s.name, "code": s.code, "subject_type": s.subject_type, "max_marks": s.max_marks}
            for s in subjects
        ]

    async def create_subject(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Subject:
        if not isinstance(data, dict):
            data = data.model_dump()
        subject = Subject(tenant_id=tenant_id, **data)
        self.db.add(subject)
        await self.db.commit()
        await self.db.refresh(subject)
        return subject

    async def update_subject(self, subject_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Subject:
        subject = await self.db.get(Subject, subject_id)
        if not subject or subject.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Subject not found")
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)
        for field, value in data.items():
            if hasattr(subject, field):
                setattr(subject, field, value)
        await self.db.commit()
        await self.db.refresh(subject)
        return subject

    async def list_grade_subjects(
        self, grade_id: uuid.UUID, tenant_id: uuid.UUID, academic_year_id: Optional[uuid.UUID] = None
    ) -> List[Dict[str, Any]]:
        stmt = select(GradeSubject, Subject).join(Subject, Subject.id == GradeSubject.subject_id).where(
            GradeSubject.grade_id == grade_id, GradeSubject.tenant_id == tenant_id
        )
        if academic_year_id:
            stmt = stmt.where(GradeSubject.academic_year_id == academic_year_id)
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(gs.id), "subject_id": str(gs.subject_id), "subject_name": s.name,
                "subject_code": s.code, "is_compulsory": gs.is_compulsory,
            }
            for gs, s in rows
        ]

    async def assign_subjects_to_grade(
        self, grade_id: uuid.UUID, tenant_id: uuid.UUID, subject_ids: List[str], academic_year_id: Optional[uuid.UUID] = None
    ) -> int:
        for sid in subject_ids:
            gs = GradeSubject(
                tenant_id=tenant_id,
                grade_id=grade_id,
                subject_id=sid,
                academic_year_id=academic_year_id,
            )
            self.db.add(gs)
        await self.db.commit()
        return len(subject_ids)

    async def list_teacher_allocations(
        self,
        tenant_id: uuid.UUID,
        section_id: Optional[uuid.UUID] = None,
        employee_id: Optional[uuid.UUID] = None,
        academic_year_id: Optional[uuid.UUID] = None,
    ) -> List[Dict[str, Any]]:
        stmt = select(TeacherAllocation).where(TeacherAllocation.tenant_id == tenant_id)
        if section_id:
            stmt = stmt.where(TeacherAllocation.section_id == section_id)
        if employee_id:
            stmt = stmt.where(TeacherAllocation.employee_id == employee_id)
        if academic_year_id:
            stmt = stmt.where(TeacherAllocation.academic_year_id == academic_year_id)
        result = await self.db.execute(stmt)
        allocs = result.scalars().all()
        return [
            {
                "id": str(a.id), "employee_id": str(a.employee_id), "subject_id": str(a.subject_id),
                "section_id": str(a.section_id), "academic_year_id": str(a.academic_year_id),
                "periods_per_week": a.periods_per_week,
            }
            for a in allocs
        ]

    async def create_teacher_allocation(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> TeacherAllocation:
        if not isinstance(data, dict):
            data = data.model_dump()
        alloc = TeacherAllocation(tenant_id=tenant_id, **data)
        self.db.add(alloc)
        await self.db.commit()
        await self.db.refresh(alloc)
        return alloc
