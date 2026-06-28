"""Super Admin authentication endpoint."""

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db
from app.core.security import verify_password, create_access_token, create_refresh_token
from app.middleware.rate_limit import rate_limit
from app.models.user import User

router = APIRouter()


class AdminLoginRequest(BaseModel):
    email: str
    password: str


@router.post("/login")
@rate_limit(limit=5, period=60)
async def admin_login(
    data: AdminLoginRequest,
    db: AsyncSession = Depends(get_db),
):
    """Super admin login. Only superusers can access."""
    stmt = (
        select(User)
        .options(selectinload(User.roles), selectinload(User.tenant))
        .where(User.email == data.email)
    )
    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(data.password, user.hashed_password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not user.is_superuser:
        raise HTTPException(status_code=403, detail="Not a super admin")

    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account disabled")

    from app.core.password_policy import check_account_lockout
    is_locked, lock_msg = check_account_lockout(
        user.failed_login_attempts or 0,
        user.locked_until,
    )
    if is_locked:
        raise HTTPException(status_code=423, detail=lock_msg)

    access_token = create_access_token(subject=str(user.id), tenant_id=str(user.tenant_id), is_superuser=True)
    refresh_token = create_refresh_token(subject=str(user.id), tenant_id=str(user.tenant_id))

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "user": {
            "id": str(user.id),
            "email": user.email,
            "full_name": user.full_name,
            "is_superuser": user.is_superuser,
        },
    }
