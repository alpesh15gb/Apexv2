"""Security utilities for hashing and JWT token operations."""

import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
from jose import jwt, JWTError
from passlib.context import CryptContext

from app.core.config import get_settings

# Apply monkeypatch to fix passlib + bcrypt compatibility issue in Python 3.12+
import bcrypt
_original_hashpw = bcrypt.hashpw
def _patched_hashpw(password, salt):
    if isinstance(password, bytes) and len(password) > 72:
        password = password[:72]
    elif isinstance(password, str) and len(password.encode("utf-8")) > 72:
        password = password.encode("utf-8")[:72].decode("utf-8", errors="ignore")
    return _original_hashpw(password, salt)
bcrypt.hashpw = _patched_hashpw

settings = get_settings()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """Hash a password using bcrypt."""
    return pwd_context.hash(password)


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against the hashed version."""
    return pwd_context.verify(plain_password, hashed_password)


def create_access_token(
    subject: str | uuid.UUID,
    tenant_id: str | uuid.UUID,
    expires_delta: Optional[timedelta] = None,
    is_superuser: bool = False,
) -> str:
    """Create a JWT access token containing subject (user_id), tenant_id, and is_superuser."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )
    to_encode = {
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "sub": str(subject),
        "tenant_id": str(tenant_id),
        "is_superuser": is_superuser,
    }
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(
    subject: str | uuid.UUID,
    tenant_id: str | uuid.UUID,
    expires_delta: Optional[timedelta] = None,
) -> str:
    """Create a JWT refresh token containing subject (user_id) and tenant_id."""
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(
            days=settings.REFRESH_TOKEN_EXPIRE_DAYS
        )
    to_encode = {
        "exp": expire,
        "iat": datetime.now(timezone.utc),
        "sub": str(subject),
        "tenant_id": str(tenant_id),
    }
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def decode_token(token: str) -> Optional[Dict[str, Any]]:
    """Decode a JWT token and return the payload."""
    try:
        decoded_token = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        return decoded_token
    except JWTError:
        return None


async def revoke_token(token: str, redis_client=None) -> bool:
    """Add a token to the revocation blacklist in Redis."""
    if not redis_client:
        return False
    try:
        payload = decode_token(token)
        if not payload:
            return False
        exp = payload.get("exp", 0)
        now = datetime.now(timezone.utc).timestamp()
        ttl = max(int(exp - now), 60)  # At least 60 seconds TTL
        await redis_client.setex(f"revoked_token:{token}", ttl, "1")
        return True
    except Exception:
        return False


async def is_token_revoked(token: str, redis_client=None) -> bool:
    """Check if a token has been revoked."""
    if not redis_client:
        return False
    try:
        result = await redis_client.get(f"revoked_token:{token}")
        return result is not None
    except Exception:
        return False


async def revoke_all_user_tokens(user_id: str, redis_client=None) -> bool:
    """Revoke all tokens for a user by adding user_id to revocation set."""
    if not redis_client:
        return False
    try:
        # Store user revocation timestamp
        await redis_client.set(f"revoked_user:{user_id}", datetime.now(timezone.utc).isoformat())
        return True
    except Exception:
        return False


async def is_user_revoked(user_id: str, token_iat: int = 0, redis_client=None) -> bool:
    """Check if all user tokens were revoked after the token was issued."""
    if not redis_client:
        return False
    try:
        revocation_time = await redis_client.get(f"revoked_user:{user_id}")
        if not revocation_time:
            return False
        from datetime import datetime as _dt
        revoked_at = _dt.fromisoformat(revocation_time).timestamp()
        return token_iat < revoked_at
    except Exception:
        return False
