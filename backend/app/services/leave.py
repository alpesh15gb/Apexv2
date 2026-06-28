import uuid
from datetime import date, datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.leave import LeaveType, LeaveBalance, LeaveRequest, LeaveRequestStatus
from app.models.employee import Employee

class LeaveService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_leave_type(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> LeaveType:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        code = data.get("code")
        if not code:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="code is required")

        stmt = select(LeaveType).where(LeaveType.tenant_id == tenant_id, LeaveType.code == code)
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Leave type with this code already exists in this tenant"
            )

        lt = LeaveType(tenant_id=tenant_id, **data)
        self.db.add(lt)
        await self.db.commit()
        await self.db.refresh(lt)
        return lt

    async def get_leave_type(self, leave_type_id: uuid.UUID, tenant_id: uuid.UUID) -> LeaveType:
        stmt = select(LeaveType).where(LeaveType.id == leave_type_id, LeaveType.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        lt = res.scalar_one_or_none()
        if not lt:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave type not found")
        return lt

    async def update_leave_type(self, leave_type_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> LeaveType:
        lt = await self.get_leave_type(leave_type_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        code = data.get("code")
        if code and code != lt.code:
            stmt = select(LeaveType).where(LeaveType.tenant_id == tenant_id, LeaveType.code == code)
            if (await self.db.execute(stmt)).scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Leave type with this code already exists in this tenant"
                )

        for field, val in data.items():
            if hasattr(lt, field):
                setattr(lt, field, val)

        await self.db.commit()
        await self.db.refresh(lt)
        return lt

    async def delete_leave_type(self, leave_type_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        lt = await self.get_leave_type(leave_type_id, tenant_id)
        await self.db.delete(lt)
        await self.db.commit()

    async def list_leave_types(self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 20) -> Tuple[List[LeaveType], int]:
        count_stmt = select(func.count(LeaveType.id)).where(LeaveType.tenant_id == tenant_id)
        stmt = select(LeaveType).where(LeaveType.tenant_id == tenant_id).offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        lts = list(res.scalars().all())
        return lts, total

    async def initialize_leave_balances(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, year: int) -> None:
        stmt_emp = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_emp)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        stmt_types = select(LeaveType).where(LeaveType.tenant_id == tenant_id, LeaveType.is_active == True)
        leave_types = (await self.db.execute(stmt_types)).scalars().all()

        existing_stmt = select(LeaveBalance.leave_type_id).where(
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.employee_id == employee_id,
            LeaveBalance.year == year,
        )
        existing_ids = set((await self.db.execute(existing_stmt)).scalars().all())

        for lt in leave_types:
            if lt.id not in existing_ids:
                bal = LeaveBalance(
                    tenant_id=tenant_id,
                    employee_id=employee_id,
                    leave_type_id=lt.id,
                    year=year,
                    total_days=float(lt.default_days),
                    used_days=0.0,
                    pending_days=0.0,
                    carried_forward=0.0
                )
                self.db.add(bal)
        await self.db.commit()

    async def get_leave_balance(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, year: int) -> List[LeaveBalance]:
        # verify employee
        stmt_emp = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_emp)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        stmt = select(LeaveBalance).where(
            LeaveBalance.employee_id == employee_id,
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.year == year
        ).options(selectinload(LeaveBalance.leave_type))
        res = await self.db.execute(stmt)
        return list(res.scalars().all())

    async def apply_leave(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> LeaveRequest:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        leave_type_id = data.get("leave_type_id")
        start_date = data.get("start_date")
        end_date = data.get("end_date")

        if not leave_type_id or not start_date or not end_date:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="leave_type_id, start_date, and end_date are required"
            )

        if isinstance(start_date, str):
            start_date = date.fromisoformat(start_date)
        if isinstance(end_date, str):
            end_date = date.fromisoformat(end_date)

        lt_stmt = select(LeaveType).where(LeaveType.id == leave_type_id, LeaveType.tenant_id == tenant_id, LeaveType.is_active == True)
        if not (await self.db.execute(lt_stmt)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave type not found or inactive")

        if start_date > end_date:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="start_date cannot be after end_date")

        total_days = data.get("total_days")
        if total_days is None:
            total_days = 0.0
            current = start_date
            while current <= end_date:
                if current.weekday() < 5:
                    total_days += 1.0
                current = date.fromordinal(current.toordinal() + 1)
        else:
            total_days = float(total_days)

        # Retrieve or initialize leave balance for start_date's year
        year = start_date.year
        stmt_bal = select(LeaveBalance).where(
            LeaveBalance.employee_id == employee_id,
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.leave_type_id == leave_type_id,
            LeaveBalance.year == year
        )
        res_bal = await self.db.execute(stmt_bal)
        balance = res_bal.scalar_one_or_none()

        if not balance:
            await self.initialize_leave_balances(tenant_id, employee_id, year)
            res_bal = await self.db.execute(stmt_bal)
            balance = res_bal.scalar_one_or_none()
            if not balance:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Leave balance not initialized and could not be created"
                )

        # Validate balance availability
        available_days = balance.total_days - balance.used_days - balance.pending_days
        if total_days > available_days:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Insufficient leave balance. Available: {available_days}, Requested: {total_days}"
            )

        # Check for overlapping leave requests
        overlap_stmt = select(LeaveRequest).where(
            LeaveRequest.employee_id == employee_id,
            LeaveRequest.tenant_id == tenant_id,
            LeaveRequest.status.in_(["pending", "approved"]),
            LeaveRequest.start_date <= end_date,
            LeaveRequest.end_date >= start_date,
        )
        if (await self.db.execute(overlap_stmt)).scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Overlapping leave request exists for this period"
            )

        # Create leave request
        request = LeaveRequest(
            tenant_id=tenant_id,
            employee_id=employee_id,
            leave_type_id=leave_type_id,
            start_date=start_date,
            end_date=end_date,
            total_days=total_days,
            reason=data.get("reason"),
            status=LeaveRequestStatus.PENDING.value
        )
        self.db.add(request)

        # Update pending days
        balance.pending_days += total_days

        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def approve_leave(self, request_id: uuid.UUID, tenant_id: uuid.UUID, approver_id: uuid.UUID) -> LeaveRequest:
        stmt = select(LeaveRequest).where(LeaveRequest.id == request_id, LeaveRequest.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        request = res.scalar_one_or_none()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found")

        if request.status != LeaveRequestStatus.PENDING.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot approve a leave request with status: {request.status}"
            )

        # Get leave balance
        year = request.start_date.year
        stmt_bal = select(LeaveBalance).where(
            LeaveBalance.employee_id == request.employee_id,
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.leave_type_id == request.leave_type_id,
            LeaveBalance.year == year
        )
        balance = (await self.db.execute(stmt_bal)).scalar_one_or_none()
        if not balance:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Leave balance not found")

        # Update request
        request.status = LeaveRequestStatus.APPROVED.value
        request.approved_by = approver_id
        request.approved_at = datetime.now(timezone.utc)

        # Deduct from pending, add to used
        balance.pending_days = max(0.0, balance.pending_days - request.total_days)
        balance.used_days += request.total_days

        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def reject_leave(self, request_id: uuid.UUID, tenant_id: uuid.UUID, approver_id: uuid.UUID, reason: Optional[str] = None) -> LeaveRequest:
        stmt = select(LeaveRequest).where(LeaveRequest.id == request_id, LeaveRequest.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        request = res.scalar_one_or_none()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found")

        if request.status != LeaveRequestStatus.PENDING.value:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot reject a leave request with status: {request.status}"
            )

        year = request.start_date.year
        stmt_bal = select(LeaveBalance).where(
            LeaveBalance.employee_id == request.employee_id,
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.leave_type_id == request.leave_type_id,
            LeaveBalance.year == year
        )
        balance = (await self.db.execute(stmt_bal)).scalar_one_or_none()
        if not balance:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Leave balance not found")

        # Update request
        request.status = LeaveRequestStatus.REJECTED.value
        request.approved_by = approver_id
        request.approved_at = datetime.now(timezone.utc)
        request.rejection_reason = reason

        # Restore pending
        balance.pending_days = max(0.0, balance.pending_days - request.total_days)

        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def cancel_leave(self, request_id: uuid.UUID, tenant_id: uuid.UUID, employee_id: uuid.UUID) -> LeaveRequest:
        stmt = select(LeaveRequest).where(
            LeaveRequest.id == request_id,
            LeaveRequest.tenant_id == tenant_id,
            LeaveRequest.employee_id == employee_id
        )
        res = await self.db.execute(stmt)
        request = res.scalar_one_or_none()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Leave request not found")

        if request.status in [LeaveRequestStatus.CANCELLED.value, LeaveRequestStatus.REJECTED.value]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Cannot cancel a leave request with status: {request.status}"
            )

        year = request.start_date.year
        stmt_bal = select(LeaveBalance).where(
            LeaveBalance.employee_id == request.employee_id,
            LeaveBalance.tenant_id == tenant_id,
            LeaveBalance.leave_type_id == request.leave_type_id,
            LeaveBalance.year == year
        )
        balance = (await self.db.execute(stmt_bal)).scalar_one_or_none()
        if not balance:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Leave balance not found")

        old_status = request.status
        request.status = LeaveRequestStatus.CANCELLED.value

        if old_status == LeaveRequestStatus.PENDING.value:
            balance.pending_days = max(0.0, balance.pending_days - request.total_days)
        elif old_status == LeaveRequestStatus.APPROVED.value:
            balance.used_days = max(0.0, balance.used_days - request.total_days)

        await self.db.commit()
        await self.db.refresh(request)
        return request

    async def list_leave_requests(
        self,
        tenant_id: uuid.UUID,
        employee_id: Optional[uuid.UUID] = None,
        status_val: Optional[str] = None,
        from_date: Optional[date] = None,
        to_date: Optional[date] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[LeaveRequest], int]:
        count_stmt = select(func.count(LeaveRequest.id)).where(LeaveRequest.tenant_id == tenant_id)
        stmt = select(LeaveRequest).where(LeaveRequest.tenant_id == tenant_id).options(
            selectinload(LeaveRequest.employee),
            selectinload(LeaveRequest.leave_type)
        )

        if employee_id:
            count_stmt = count_stmt.where(LeaveRequest.employee_id == employee_id)
            stmt = stmt.where(LeaveRequest.employee_id == employee_id)
        if status_val:
            count_stmt = count_stmt.where(LeaveRequest.status == status_val)
            stmt = stmt.where(LeaveRequest.status == status_val)
        if from_date:
            count_stmt = count_stmt.where(LeaveRequest.start_date >= from_date)
            stmt = stmt.where(LeaveRequest.start_date >= from_date)
        if to_date:
            count_stmt = count_stmt.where(LeaveRequest.end_date <= to_date)
            stmt = stmt.where(LeaveRequest.end_date <= to_date)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        requests = list(res.scalars().all())
        return requests, total
