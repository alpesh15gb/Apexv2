"""Pydantic schemas for authentication and registration."""

import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, ConfigDict, Field


class LoginRequest(BaseModel):
    """Schema for login request."""
    email: EmailStr
    password: str


class TokenPayload(BaseModel):
    """Schema for JWT token payload claims."""
    sub: str  # user_id
    tenant_id: str
    exp: int
    iat: int
    is_superuser: bool = False


class UserResponse(BaseModel):
    """Schema for user profile response."""
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    tenant_id: uuid.UUID
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    avatar_url: Optional[str] = None
    is_active: bool
    is_superuser: bool
    tenant_type: str = "corporate"
    created_at: datetime
    updated_at: datetime


class LoginResponse(BaseModel):
    """Schema for login response containing access and refresh tokens."""
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: UserResponse


class RegisterRequest(BaseModel):
    """Schema for tenant and admin user registration."""
    tenant_name: str = Field(..., min_length=2, max_length=255)
    tenant_slug: str = Field(..., min_length=2, max_length=255, pattern="^[a-z0-9-]+$")
    admin_email: EmailStr
    admin_password: str = Field(..., min_length=8)
    admin_full_name: str = Field(..., min_length=2, max_length=255)


class RegisterResponse(BaseModel):
    """Schema for registration response."""
    tenant_id: uuid.UUID
    tenant_name: str
    tenant_slug: str
    admin_user: UserResponse


class UserUpdate(BaseModel):
    """Schema for updating user profile."""
    full_name: Optional[str] = Field(None, min_length=2, max_length=255)
    phone: Optional[str] = Field(None, max_length=50)
    avatar_url: Optional[str] = Field(None, max_length=512)


class PasswordChange(BaseModel):
    """Schema for changing password."""
    old_password: str
    new_password: str = Field(..., min_length=8)


class RefreshTokenRequest(BaseModel):
    """Schema for refreshing access token."""
    refresh_token: str
