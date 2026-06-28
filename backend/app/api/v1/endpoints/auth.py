"""Authentication and registration API endpoints."""

import uuid
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status, Request
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from redis.asyncio import Redis

from app.core.config import get_settings
from app.core.security import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    decode_token,
    revoke_token,
    revoke_all_user_tokens,
)
from app.core.deps import get_current_active_user, get_db
from app.models.user import User
from app.models.tenant import Tenant
from app.schemas.auth import (
    LoginRequest,
    LoginResponse,
    RegisterRequest,
    RegisterResponse,
    UserResponse,
    UserUpdate,
    PasswordChange,
    RefreshTokenRequest,
)
from app.schemas.common import StatusResponse
from app.middleware.rate_limit import rate_limit
import structlog

logger = structlog.get_logger(__name__)
settings = get_settings()
router = APIRouter()

_redis = None
def get_redis():
    global _redis
    if _redis is None:
        _redis = Redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
@rate_limit(limit=3, period=60)
async def register(
    register_data: RegisterRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> RegisterResponse:
    """Create a new tenant and its primary administrator user."""
    # Check if tenant slug is already taken
    existing_tenant = (await db.execute(
        select(Tenant).where(Tenant.slug == register_data.tenant_slug)
    )).scalar_one_or_none()

    if existing_tenant:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tenant with this slug already exists.",
        )

    try:
        # Create tenant
        tenant = Tenant(
            name=register_data.tenant_name,
            slug=register_data.tenant_slug,
        )
        db.add(tenant)
        await db.flush()

        # Create default roles & permissions
        from app.core.rbac import create_default_roles, assign_role_to_user
        roles = await create_default_roles(db, tenant.id)
        super_admin_role = next((r for r in roles if r.name == "Super Admin"), None)

        # Create admin user
        admin_user = User(
            tenant_id=tenant.id,
            email=register_data.admin_email,
            hashed_password=hash_password(register_data.admin_password),
            full_name=register_data.admin_full_name,
            is_active=True,
            is_superuser=False,
        )
        db.add(admin_user)
        await db.flush()

        # Assign Super Admin role to the user
        if super_admin_role:
            await assign_role_to_user(db, admin_user.id, super_admin_role.id)

        await db.flush()
        await db.refresh(admin_user)
        await db.commit()

        # Set request state to enable audit logging of this action
        request.state.tenant_id = tenant.id
        request.state.user_id = admin_user.id

        return RegisterResponse(
            tenant_id=tenant.id,
            tenant_name=tenant.name,
            tenant_slug=tenant.slug,
            admin_user=UserResponse.model_validate(admin_user),
        )

    except Exception as e:
        await db.rollback()
        logger.error("tenant_registration_failed", error=str(e), slug=register_data.tenant_slug)
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tenant registration failed. Please try again.",
        )


@router.post("/login", response_model=LoginResponse)
@rate_limit(limit=5, period=60)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    """Authenticate email and password, returning JWT access and refresh tokens."""
    from app.core.password_policy import check_account_lockout, record_failed_login, reset_failed_login

    # Find user. Multi-tenancy check: filter by resolved tenant_id if present
    tenant_id = getattr(request.state, "tenant_id", None)
    stmt = select(User).where(User.email == login_data.email)
    if tenant_id:
        stmt = stmt.where(User.tenant_id == tenant_id)

    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    # Check account lockout
    is_locked, lock_msg = check_account_lockout(
        user.failed_login_attempts or 0,
        user.locked_until,
    )
    if is_locked:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail=lock_msg,
        )

    if not verify_password(login_data.password, user.hashed_password):
        # Record failed attempt
        record_failed_login(user)
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive.",
        )

    # Reset failed login counter
    reset_failed_login(user)

    # Generate JWT tokens
    access_token = create_access_token(
        subject=user.id,
        tenant_id=user.tenant_id,
        is_superuser=user.is_superuser,
    )
    refresh_token = create_refresh_token(
        subject=user.id,
        tenant_id=user.tenant_id,
    )

    # Update last login timestamp
    user.last_login_at = datetime.now(timezone.utc)
    db.add(user)
    await db.flush()
    await db.refresh(user)
    await db.commit()

    # Set request state to enable audit logging of this action
    request.state.tenant_id = user.tenant_id
    request.state.user_id = user.id

    return LoginResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        user=UserResponse.model_validate(user),
    )


@router.post("/refresh", response_model=LoginResponse)
@rate_limit(limit=10, period=60)
async def refresh_token(
    refresh_data: RefreshTokenRequest,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    """Validate a refresh token and issue a new access/refresh token pair."""
    token = refresh_data.refresh_token
    payload = decode_token(token)
    if not payload:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token.",
        )

    # Validate token type — only refresh tokens allowed
    if payload.get("type") != "refresh":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token type. Expected refresh token.",
        )

    # Check if the token has been revoked in Redis
    try:
        redis_client = get_redis()
        is_revoked = await redis_client.get(f"revoked_token:{token}")
        if is_revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has been revoked.",
            )
    except Exception as e:
        pass

    sub = payload.get("sub")
    if not sub:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload.",
        )

    try:
        user_id = uuid.UUID(sub)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid user ID format in token.",
        )

    user = await db.get(User, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive.",
        )

    # Issue new token pair
    access_token = create_access_token(
        subject=user.id,
        tenant_id=user.tenant_id,
        is_superuser=user.is_superuser,
    )
    new_refresh_token = create_refresh_token(
        subject=user.id,
        tenant_id=user.tenant_id,
    )

    # Revoke the old refresh token to prevent replay
    try:
        redis_client = get_redis()
        await revoke_token(token, redis_client)
    except Exception:
        pass

    return LoginResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        user=UserResponse.model_validate(user),
    )


@router.post("/logout", response_model=StatusResponse)
async def logout(
    logout_data: RefreshTokenRequest,
    request: Request,
) -> StatusResponse:
    """Revoke access and refresh tokens, preventing their reuse."""
    redis_client = get_redis()
    await revoke_token(logout_data.refresh_token, redis_client)

    auth_header = request.headers.get("authorization", "")
    if auth_header.startswith("Bearer "):
        access_token = auth_header[7:]
        await revoke_token(access_token, redis_client)

    return StatusResponse(
        status="success",
        message="Successfully logged out.",
    )


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_active_user),
) -> UserResponse:
    """Retrieve the current user's profile details."""
    return UserResponse.model_validate(current_user)


@router.put("/me", response_model=UserResponse)
async def update_me(
    update_data: UserUpdate,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    """Update the current user's profile information."""
    if update_data.full_name is not None:
        current_user.full_name = update_data.full_name
    if update_data.phone is not None:
        current_user.phone = update_data.phone
    if update_data.avatar_url is not None:
        current_user.avatar_url = update_data.avatar_url

    db.add(current_user)
    await db.flush()
    await db.refresh(current_user)
    await db.commit()

    return UserResponse.model_validate(current_user)


@router.post("/change-password", response_model=StatusResponse)
async def change_password(
    change_data: PasswordChange,
    current_user: User = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db),
) -> StatusResponse:
    """Change the current user's password."""
    if not verify_password(change_data.old_password, current_user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect old password.",
        )

    current_user.hashed_password = hash_password(change_data.new_password)
    current_user.last_password_change = datetime.now(timezone.utc)
    db.add(current_user)
    await db.commit()

    # Invalidate all sessions for this user
    try:
        redis_client = get_redis()
        await redis_client.set(f"revoked_user:{current_user.id}", datetime.now(timezone.utc).isoformat())
    except Exception:
        pass

    return StatusResponse(
        status="success",
        message="Password changed successfully.",
    )


@router.post("/logout-all", response_model=StatusResponse)
async def logout_all_devices(
    current_user: User = Depends(get_current_active_user),
) -> StatusResponse:
    """Revoke all tokens for the current user across all devices."""
    redis_client = get_redis()
    await revoke_all_user_tokens(str(current_user.id), redis_client)

    return StatusResponse(
        status="success",
        message="All sessions revoked. Please login again.",
    )
