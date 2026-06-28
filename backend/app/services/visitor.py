import uuid
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.visitor import Visitor, VisitorPass, VisitorPassStatus

class VisitorService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def register_visitor(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Visitor:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        visitor = Visitor(tenant_id=tenant_id, **data)
        self.db.add(visitor)
        await self.db.commit()
        await self.db.refresh(visitor)
        return visitor

    async def create_visitor_pass(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> VisitorPass:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        # Generate unique pass number
        while True:
            pass_num = f"PASS-{uuid.uuid4().hex[:8].upper()}"
            stmt = select(VisitorPass).where(VisitorPass.tenant_id == tenant_id, VisitorPass.pass_number == pass_num)
            res = await self.db.execute(stmt)
            if not res.scalar_one_or_none():
                break

        data["pass_number"] = pass_num
        data["status"] = VisitorPassStatus.PENDING.value

        # Parse date if passed as string
        expected_date = data.get("expected_date")
        if isinstance(expected_date, str):
            data["expected_date"] = date.fromisoformat(expected_date)

        visitor_pass = VisitorPass(tenant_id=tenant_id, **data)
        self.db.add(visitor_pass)
        await self.db.commit()
        await self.db.refresh(visitor_pass)
        return visitor_pass

    async def check_in_visitor(self, pass_id: uuid.UUID, tenant_id: uuid.UUID) -> VisitorPass:
        stmt = select(VisitorPass).where(VisitorPass.id == pass_id, VisitorPass.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        visitor_pass = res.scalar_one_or_none()
        if not visitor_pass:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Visitor pass not found")

        visitor_pass.check_in_time = datetime.now(timezone.utc)
        visitor_pass.status = VisitorPassStatus.CHECKED_IN.value

        # Optionally call ValidateVisitorDesk SOAP API
        try:
            from app.services.essl_soap import ESSLSoapService
            from app.models.essl_server import EsslServer
            stmt_server = select(EsslServer).where(EsslServer.tenant_id == tenant_id, EsslServer.is_active == True)
            server_result = await self.db.execute(stmt_server)
            server = server_result.scalar_one_or_none()
            if not server:
                raise HTTPException(status_code=400, detail="No active eSSL server configured")
            soap_service = ESSLSoapService(server.server_url, server.username, server.password_encrypted)
            soap_res = await soap_service.validate_visitor_desk({
                "uuid": str(visitor_pass.id),
                "pass_number": visitor_pass.pass_number
            })
            if soap_res.get("success"):
                visitor_pass.visitor_desk_validated = True
        except Exception:
            # Log SOAP failure but allow check-in to succeed for resilience
            pass

        await self.db.commit()
        await self.db.refresh(visitor_pass)
        return visitor_pass

    async def check_out_visitor(self, pass_id: uuid.UUID, tenant_id: uuid.UUID) -> VisitorPass:
        stmt = select(VisitorPass).where(VisitorPass.id == pass_id, VisitorPass.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        visitor_pass = res.scalar_one_or_none()
        if not visitor_pass:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Visitor pass not found")

        visitor_pass.check_out_time = datetime.now(timezone.utc)
        visitor_pass.status = VisitorPassStatus.CHECKED_OUT.value

        await self.db.commit()
        await self.db.refresh(visitor_pass)
        return visitor_pass

    async def list_visitors(
        self,
        tenant_id: uuid.UUID,
        filters: Optional[Union[Dict[str, Any], Any]] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[Visitor], int]:
        count_stmt = select(func.count(Visitor.id)).where(Visitor.tenant_id == tenant_id)
        stmt = select(Visitor).where(Visitor.tenant_id == tenant_id)

        if filters:
            if not isinstance(filters, dict):
                filters = filters.model_dump(exclude_unset=True)
            search = filters.get("search")
            if search:
                search_filter = or_(
                    Visitor.name.ilike(f"%{search}%"),
                    Visitor.phone.ilike(f"%{search}%"),
                    Visitor.email.ilike(f"%{search}%")
                )
                count_stmt = count_stmt.where(search_filter)
                stmt = stmt.where(search_filter)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        visitors = list(res.scalars().all())
        return visitors, total

    async def list_active_visitors(self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 50) -> Tuple[List[VisitorPass], int]:
        count_stmt = select(func.count(VisitorPass.id)).where(
            VisitorPass.tenant_id == tenant_id,
            VisitorPass.status == VisitorPassStatus.CHECKED_IN.value,
        )
        stmt = select(VisitorPass).where(
            VisitorPass.tenant_id == tenant_id,
            VisitorPass.status == VisitorPassStatus.CHECKED_IN.value,
        ).options(selectinload(VisitorPass.visitor), selectinload(VisitorPass.host_employee))
        total = (await self.db.execute(count_stmt)).scalar() or 0
        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        return list(res.scalars().all()), total

    async def get_visitor_history(
        self,
        tenant_id: uuid.UUID,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[VisitorPass], int]:
        count_stmt = select(func.count(VisitorPass.id)).where(VisitorPass.tenant_id == tenant_id)
        stmt = select(VisitorPass).where(VisitorPass.tenant_id == tenant_id).options(
            selectinload(VisitorPass.visitor),
            selectinload(VisitorPass.host_employee)
        )

        if from_date:
            count_stmt = count_stmt.where(VisitorPass.expected_date >= from_date)
            stmt = stmt.where(VisitorPass.expected_date >= from_date)
        if to_date:
            count_stmt = count_stmt.where(VisitorPass.expected_date <= to_date)
            stmt = stmt.where(VisitorPass.expected_date <= to_date)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.order_by(VisitorPass.expected_date.desc()).offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        passes = list(res.scalars().all())
        return passes, total

    async def list_passes(
        self,
        tenant_id: uuid.UUID,
        page: int = 1,
        page_size: int = 20,
        status: Optional[str] = None,
        host_employee_id: Optional[uuid.UUID] = None,
    ) -> Tuple[List[VisitorPass], int]:
        """List visitor passes with optional filtering."""
        stmt = select(VisitorPass).where(VisitorPass.tenant_id == tenant_id)
        count_stmt = select(func.count(VisitorPass.id)).where(VisitorPass.tenant_id == tenant_id)

        if status:
            stmt = stmt.where(VisitorPass.status == status)
            count_stmt = count_stmt.where(VisitorPass.status == status)
        if host_employee_id:
            stmt = stmt.where(VisitorPass.host_employee_id == host_employee_id)
            count_stmt = count_stmt.where(VisitorPass.host_employee_id == host_employee_id)

        total = (await self.db.execute(count_stmt)).scalar() or 0
        offset = (page - 1) * page_size
        result = await self.db.execute(
            stmt.order_by(VisitorPass.created_at.desc()).offset(offset).limit(page_size)
        )
        items = list(result.scalars().all())
        return items, total
