import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.access_control import AccessZone, Door, UserAccessLevel, AccessLog
from app.models.employee import Employee

class AccessControlService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # ACCESS ZONE CRUD
    async def create_access_zone(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AccessZone:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        name = data.get("name")
        branch_id = data.get("branch_id")
        if not name or not branch_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="name and branch_id are required")

        # Check unique constraint
        stmt = select(AccessZone).where(
            AccessZone.tenant_id == tenant_id,
            AccessZone.branch_id == branch_id,
            AccessZone.name == name
        )
        if (await self.db.execute(stmt)).scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Access zone with this name already exists in this branch"
            )

        zone = AccessZone(tenant_id=tenant_id, **data)
        self.db.add(zone)
        await self.db.commit()
        await self.db.refresh(zone)
        return zone

    async def get_access_zone(self, zone_id: uuid.UUID, tenant_id: uuid.UUID) -> AccessZone:
        stmt = select(AccessZone).where(AccessZone.id == zone_id, AccessZone.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        zone = res.scalar_one_or_none()
        if not zone:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Access zone not found")
        return zone

    async def update_access_zone(self, zone_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> AccessZone:
        zone = await self.get_access_zone(zone_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        name = data.get("name", zone.name)
        branch_id = data.get("branch_id", zone.branch_id)

        if (name != zone.name) or (branch_id != zone.branch_id):
            stmt = select(AccessZone).where(
                AccessZone.tenant_id == tenant_id,
                AccessZone.branch_id == branch_id,
                AccessZone.name == name
            )
            if (await self.db.execute(stmt)).scalar_one_or_none():
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Access zone with this name already exists in this branch"
                )

        for field, val in data.items():
            if hasattr(zone, field):
                setattr(zone, field, val)

        await self.db.commit()
        await self.db.refresh(zone)
        return zone

    async def delete_access_zone(self, zone_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        zone = await self.get_access_zone(zone_id, tenant_id)
        await self.db.delete(zone)
        await self.db.commit()

    async def list_access_zones(self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 20) -> Tuple[List[AccessZone], int]:
        count_stmt = select(func.count(AccessZone.id)).where(AccessZone.tenant_id == tenant_id)
        stmt = select(AccessZone).where(AccessZone.tenant_id == tenant_id).offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        zones = list(res.scalars().all())
        return zones, total

    # DOOR CRUD
    async def create_door(self, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Door:
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        door = Door(tenant_id=tenant_id, **data)
        self.db.add(door)
        await self.db.commit()
        await self.db.refresh(door)
        return door

    async def get_door(self, door_id: uuid.UUID, tenant_id: uuid.UUID) -> Door:
        stmt = select(Door).where(Door.id == door_id, Door.tenant_id == tenant_id)
        res = await self.db.execute(stmt)
        door = res.scalar_one_or_none()
        if not door:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Door not found")
        return door

    async def update_door(self, door_id: uuid.UUID, tenant_id: uuid.UUID, data: Union[Dict[str, Any], Any]) -> Door:
        door = await self.get_door(door_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        for field, val in data.items():
            if hasattr(door, field):
                setattr(door, field, val)

        await self.db.commit()
        await self.db.refresh(door)
        return door

    async def delete_door(self, door_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        door = await self.get_door(door_id, tenant_id)
        await self.db.delete(door)
        await self.db.commit()

    async def list_doors(self, tenant_id: uuid.UUID, page: int = 1, page_size: int = 20) -> Tuple[List[Door], int]:
        count_stmt = select(func.count(Door.id)).where(Door.tenant_id == tenant_id)
        stmt = select(Door).where(Door.tenant_id == tenant_id).options(
            selectinload(Door.zone),
            selectinload(Door.device)
        ).offset((page - 1) * page_size).limit(page_size)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        res = await self.db.execute(stmt)
        doors = list(res.scalars().all())
        return doors, total

    # ACCESS MGT
    async def grant_access(
        self,
        tenant_id: uuid.UUID,
        employee_id: uuid.UUID,
        zone_id: uuid.UUID,
        access_level: int,
        granted_by: Optional[uuid.UUID] = None,
        valid_from: Optional[datetime] = None,
        valid_to: Optional[datetime] = None
    ) -> UserAccessLevel:
        # verify employee exists
        stmt_emp = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_emp)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        # verify zone exists
        stmt_zone = select(AccessZone).where(AccessZone.id == zone_id, AccessZone.tenant_id == tenant_id)
        if not (await self.db.execute(stmt_zone)).scalar_one_or_none():
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Access zone not found")

        # Check unique constraint (employee_id, zone_id)
        stmt_ac = select(UserAccessLevel).where(
            UserAccessLevel.employee_id == employee_id,
            UserAccessLevel.zone_id == zone_id,
            UserAccessLevel.tenant_id == tenant_id
        )
        ac = (await self.db.execute(stmt_ac)).scalar_one_or_none()

        if ac:
            ac.access_level = access_level
            ac.granted_by = granted_by
            ac.valid_from = valid_from
            ac.valid_to = valid_to
        else:
            ac = UserAccessLevel(
                tenant_id=tenant_id,
                employee_id=employee_id,
                zone_id=zone_id,
                access_level=access_level,
                granted_by=granted_by,
                valid_from=valid_from,
                valid_to=valid_to
            )
            self.db.add(ac)

        await self.db.commit()
        await self.db.refresh(ac)
        return ac

    async def revoke_access(self, access_level_id: uuid.UUID, tenant_id: uuid.UUID) -> None:
        stmt = select(UserAccessLevel).where(UserAccessLevel.id == access_level_id, UserAccessLevel.tenant_id == tenant_id)
        ac = (await self.db.execute(stmt)).scalar_one_or_none()
        if not ac:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Access grant not found")
        await self.db.delete(ac)
        await self.db.commit()

    async def check_access(self, tenant_id: uuid.UUID, employee_id: uuid.UUID, door_id: uuid.UUID) -> Tuple[bool, str]:
        # Get door
        stmt_door = select(Door).where(Door.id == door_id, Door.tenant_id == tenant_id)
        door = (await self.db.execute(stmt_door)).scalar_one_or_none()
        if not door:
            return False, "Door not found"
        if not door.is_active:
            return False, "Door is inactive"

        # Get access zone
        stmt_zone = select(AccessZone).where(AccessZone.id == door.zone_id, AccessZone.tenant_id == tenant_id)
        zone = (await self.db.execute(stmt_zone)).scalar_one_or_none()
        if not zone:
            return False, "Access zone not found"

        if not zone.is_restricted:
            return True, "Zone is unrestricted"

        # Check user access levels
        now = datetime.now(timezone.utc)
        stmt_ac = select(UserAccessLevel).where(
            UserAccessLevel.employee_id == employee_id,
            UserAccessLevel.zone_id == zone.id,
            UserAccessLevel.tenant_id == tenant_id,
            or_(UserAccessLevel.valid_from == None, UserAccessLevel.valid_from <= now),
            or_(UserAccessLevel.valid_to == None, UserAccessLevel.valid_to >= now)
        )
        ac = (await self.db.execute(stmt_ac)).scalar_one_or_none()

        if not ac:
            return False, "No access level granted for this zone"

        if ac.access_level >= zone.access_level_required:
            return True, "Access granted"

        return False, f"Insufficient access level. Required: {zone.access_level_required}, User has: {ac.access_level}"

    # ACCESS LOGGING
    async def log_access(
        self,
        tenant_id: uuid.UUID,
        door_id: uuid.UUID,
        access_type: str,
        granted: bool,
        employee_id: Optional[uuid.UUID] = None,
        visitor_id: Optional[uuid.UUID] = None,
        visitor_pass_id: Optional[uuid.UUID] = None,
        denial_reason: Optional[str] = None
    ) -> AccessLog:
        log = AccessLog(
            tenant_id=tenant_id,
            door_id=door_id,
            access_type=access_type,
            granted=granted,
            employee_id=employee_id,
            visitor_id=visitor_id,
            visitor_pass_id=visitor_pass_id,
            access_time=datetime.now(timezone.utc),
            denial_reason=denial_reason
        )
        self.db.add(log)
        await self.db.commit()
        await self.db.refresh(log)
        return log

    async def list_access_logs(
        self,
        tenant_id: uuid.UUID,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None,
        employee_id: Optional[uuid.UUID] = None,
        door_id: Optional[uuid.UUID] = None,
        page: int = 1,
        page_size: int = 20
    ) -> Tuple[List[AccessLog], int]:
        count_stmt = select(func.count(AccessLog.id)).where(AccessLog.tenant_id == tenant_id)
        stmt = select(AccessLog).where(AccessLog.tenant_id == tenant_id).options(
            selectinload(AccessLog.employee),
            selectinload(AccessLog.door),
            selectinload(AccessLog.visitor_pass)
        ).order_by(AccessLog.access_time.desc())

        if from_date:
            count_stmt = count_stmt.where(AccessLog.access_time >= from_date)
            stmt = stmt.where(AccessLog.access_time >= from_date)
        if to_date:
            count_stmt = count_stmt.where(AccessLog.access_time <= to_date)
            stmt = stmt.where(AccessLog.access_time <= to_date)
        if employee_id:
            count_stmt = count_stmt.where(AccessLog.employee_id == employee_id)
            stmt = stmt.where(AccessLog.employee_id == employee_id)
        if door_id:
            count_stmt = count_stmt.where(AccessLog.door_id == door_id)
            stmt = stmt.where(AccessLog.door_id == door_id)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        logs = list(res.scalars().all())
        return logs, total
