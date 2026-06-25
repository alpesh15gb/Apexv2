import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.models.role import Role
from app.core.security import hash_password

class UserService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def create_user(
        self,
        tenant_id: uuid.UUID,
        email: str,
        password: str,
        full_name: str,
        role_ids: Optional[List[uuid.UUID]] = None
    ) -> User:
        # Check if email exists for this tenant
        stmt = select(User).where(User.tenant_id == tenant_id, User.email == email)
        res = await self.db.execute(stmt)
        if res.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User with this email already exists in this tenant"
            )

        hashed = hash_password(password)
        user = User(
            tenant_id=tenant_id,
            email=email,
            hashed_password=hashed,
            full_name=full_name,
            is_active=True
        )

        if role_ids:
            stmt_roles = select(Role).where(Role.id.in_(role_ids), Role.tenant_id == tenant_id)
            roles_res = await self.db.execute(stmt_roles)
            roles = list(roles_res.scalars().all())
            user.roles = roles

        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def get_user(self, user_id: uuid.UUID, tenant_id: uuid.UUID) -> User:
        stmt = select(User).where(User.id == user_id, User.tenant_id == tenant_id).options(selectinload(User.roles))
        res = await self.db.execute(stmt)
        user = res.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        return user

    async def get_user_by_email(self, email: str, tenant_id: uuid.UUID) -> User:
        stmt = select(User).where(User.email == email, User.tenant_id == tenant_id).options(selectinload(User.roles))
        res = await self.db.execute(stmt)
        user = res.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        return user

    async def update_user(
        self,
        user_id: uuid.UUID,
        tenant_id: uuid.UUID,
        data: Union[Dict[str, Any], Any]
    ) -> User:
        user = await self.get_user(user_id, tenant_id)
        if not isinstance(data, dict):
            data = data.model_dump(exclude_unset=True)

        # Handle password hashing
        if "password" in data:
            user.hashed_password = hash_password(data.pop("password"))

        # Handle role_ids
        if "role_ids" in data:
            role_ids = data.pop("role_ids")
            if role_ids:
                stmt_roles = select(Role).where(Role.id.in_(role_ids), Role.tenant_id == tenant_id)
                roles_res = await self.db.execute(stmt_roles)
                roles = list(roles_res.scalars().all())
                user.roles = roles
            else:
                user.roles = []

        for field, val in data.items():
            if hasattr(user, field):
                setattr(user, field, val)

        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def list_users(
        self,
        tenant_id: uuid.UUID,
        page: int = 1,
        page_size: int = 20,
        search: Optional[str] = None
    ) -> Tuple[List[User], int]:
        count_stmt = select(func.count(User.id)).where(User.tenant_id == tenant_id)
        stmt = select(User).where(User.tenant_id == tenant_id).options(selectinload(User.roles))

        if search:
            search_filter = or_(
                User.email.ilike(f"%{search}%"),
                User.full_name.ilike(f"%{search}%")
            )
            count_stmt = count_stmt.where(search_filter)
            stmt = stmt.where(search_filter)

        total_res = await self.db.execute(count_stmt)
        total = total_res.scalar() or 0

        stmt = stmt.offset((page - 1) * page_size).limit(page_size)
        res = await self.db.execute(stmt)
        users = list(res.scalars().all())
        return users, total

    async def deactivate_user(self, user_id: uuid.UUID, tenant_id: uuid.UUID) -> User:
        user = await self.get_user(user_id, tenant_id)
        user.is_active = False
        await self.db.commit()
        await self.db.refresh(user)
        return user

    async def update_last_login(self, user_id: uuid.UUID) -> User:
        stmt = select(User).where(User.id == user_id)
        res = await self.db.execute(stmt)
        user = res.scalar_one_or_none()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found"
            )
        user.last_login_at = datetime.now(timezone.utc)
        await self.db.commit()
        await self.db.refresh(user)
        return user
