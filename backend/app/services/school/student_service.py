import uuid
from typing import Any, Dict, List, Optional, Tuple, Union
from datetime import date

from fastapi import HTTPException, status
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.school.student import Student, Guardian, StudentGuardian


class StudentService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def list_students(
        self,
        tenant_id: uuid.UUID,
        grade_id: Optional[uuid.UUID] = None,
        section_id: Optional[uuid.UUID] = None,
        student_status: Optional[str] = None,
        search: Optional[str] = None,
        page: int = 1,
        page_size: int = 50,
    ) -> Tuple[List[Dict[str, Any]], int]:
        stmt = select(Student).where(Student.tenant_id == tenant_id, Student.is_active == True)
        count_stmt = select(func.count(Student.id)).where(Student.tenant_id == tenant_id, Student.is_active == True)

        if grade_id:
            stmt = stmt.where(Student.current_grade_id == grade_id)
            count_stmt = count_stmt.where(Student.current_grade_id == grade_id)
        if section_id:
            stmt = stmt.where(Student.current_section_id == section_id)
            count_stmt = count_stmt.where(Student.current_section_id == section_id)
        if student_status:
            stmt = stmt.where(Student.status == student_status)
            count_stmt = count_stmt.where(Student.status == student_status)
        if search:
            search_filter = (
                Student.first_name.ilike(f"%{search}%")
                | Student.last_name.ilike(f"%{search}%")
                | Student.admission_number.ilike(f"%{search}%")
            )
            stmt = stmt.where(search_filter)
            count_stmt = count_stmt.where(search_filter)

        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.order_by(Student.admission_number).offset((page - 1) * page_size).limit(page_size)
        result = await self.db.execute(stmt)
        students = result.scalars().all()

        items = [
            {
                "id": str(s.id),
                "admission_number": s.admission_number,
                "roll_number": s.roll_number,
                "first_name": s.first_name,
                "last_name": s.last_name,
                "gender": s.gender,
                "current_grade_id": str(s.current_grade_id) if s.current_grade_id else None,
                "current_section_id": str(s.current_section_id) if s.current_section_id else None,
                "status": s.status,
                "admission_date": str(s.admission_date),
            }
            for s in students
        ]
        return items, total

    async def create_student(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Student:
        if not isinstance(data, dict):
            data = data.model_dump()

        existing = await self.db.execute(
            select(Student).where(Student.tenant_id == tenant_id, Student.admission_number == data["admission_number"])
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Admission number already exists")

        student = Student(tenant_id=tenant_id, **data)
        self.db.add(student)
        await self.db.commit()
        await self.db.refresh(student)
        return student

    async def get_student(self, student_id: uuid.UUID, tenant_id: uuid.UUID) -> Student:
        student = await self.db.get(Student, student_id)
        if not student or student.tenant_id != tenant_id:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Student not found")
        return student

    async def update_student(self, student_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Student:
        student = await self.get_student(student_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        for field, value in data.items():
            if hasattr(student, field):
                setattr(student, field, value)

        await self.db.commit()
        await self.db.refresh(student)
        return student

    async def add_guardian(self, student_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Guardian:
        await self.get_student(student_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump()

        guardian = Guardian(
            tenant_id=tenant_id,
            first_name=data["first_name"],
            last_name=data["last_name"],
            email=data.get("email"),
            phone=data["phone"],
            occupation=data.get("occupation"),
        )
        self.db.add(guardian)
        await self.db.flush()

        link = StudentGuardian(
            tenant_id=tenant_id,
            student_id=student_id,
            guardian_id=guardian.id,
            relationship=data.get("relationship", "guardian"),
            is_primary=data.get("is_primary", False),
        )
        self.db.add(link)
        await self.db.commit()
        await self.db.refresh(guardian)
        return guardian

    async def list_guardians(self, student_id: uuid.UUID, tenant_id: uuid.UUID) -> List[Dict[str, Any]]:
        stmt = (
            select(StudentGuardian, Guardian)
            .join(Guardian, Guardian.id == StudentGuardian.guardian_id)
            .where(StudentGuardian.student_id == student_id, StudentGuardian.tenant_id == tenant_id)
        )
        result = await self.db.execute(stmt)
        rows = result.all()
        return [
            {
                "id": str(g.id),
                "first_name": g.first_name,
                "last_name": g.last_name,
                "phone": g.phone,
                "email": g.email,
                "relationship": sg.relationship,
                "is_primary": sg.is_primary,
            }
            for sg, g in rows
        ]

    async def promote_student(
        self,
        student_id: uuid.UUID,
        tenant_id: uuid.UUID,
        new_grade_id: uuid.UUID,
        new_section_id: uuid.UUID,
        new_academic_year_id: uuid.UUID,
    ) -> Student:
        student = await self.get_student(student_id, tenant_id)
        student.current_grade_id = new_grade_id
        student.current_section_id = new_section_id
        student.academic_year_id = new_academic_year_id
        await self.db.commit()
        await self.db.refresh(student)
        return student
