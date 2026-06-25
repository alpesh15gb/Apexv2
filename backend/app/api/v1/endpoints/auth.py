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

settings = get_settings()
router = APIRouter()


@router.post("/register", response_model=RegisterResponse, status_code=status.HTTP_201_CREATED)
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
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Tenant registration failed: {str(e)}",
        )


@router.post("/login", response_model=LoginResponse)
async def login(
    login_data: LoginRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> LoginResponse:
    """Authenticate email and password, returning JWT access and refresh tokens."""
    # Find user. Multi-tenancy check: filter by resolved tenant_id if present
    tenant_id = getattr(request.state, "tenant_id", None)
    stmt = select(User).where(User.email == login_data.email)
    if tenant_id:
        stmt = stmt.where(User.tenant_id == tenant_id)

    result = await db.execute(stmt)
    user = result.scalar_one_or_none()

    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password.",
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is inactive.",
        )

    # Generate JWT tokens
    access_token = create_access_token(
        subject=user.id,
        tenant_id=user.tenant_id,
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

    # Check if the token has been revoked in Redis
    try:
        redis_client = Redis.from_url(settings.REDIS_URL, decode_responses=True)
        is_revoked = await redis_client.get(f"revoked_token:{token}")
        if is_revoked:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Refresh token has been revoked.",
            )
    except Exception as e:
        # Fallback if Redis is down
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
    )
    new_refresh_token = create_refresh_token(
        subject=user.id,
        tenant_id=user.tenant_id,
    )

    return LoginResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        user=UserResponse.model_validate(user),
    )


@router.post("/logout", response_model=StatusResponse)
async def logout(
    logout_data: RefreshTokenRequest,
) -> StatusResponse:
    """Revoke a refresh token, preventing its reuse."""
    token = logout_data.refresh_token
    payload = decode_token(token)
    if payload:
        exp = payload.get("exp")
        if exp:
            now = datetime.now(timezone.utc).timestamp()
            ttl = int(exp - now)
            if ttl > 0:
                try:
                    redis_client = Redis.from_url(settings.REDIS_URL, decode_responses=True)
                    await redis_client.setex(f"revoked_token:{token}", ttl, "1")
                except Exception:
                    # If Redis fails, log might not persist, but we avoid 500 error
                    pass

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
    db.add(current_user)
    await db.commit()

    return StatusResponse(
        status="success",
        message="Password changed successfully.",
    )
