"""Application configuration."""

import logging
import os
import secrets

from pydantic_settings import BaseSettings
from functools import lru_cache

logger = logging.getLogger(__name__)

_DEFAULT_SECRET_KEY = "change-this-to-a-random-secret-key-in-production"
_DEFAULT_DATABASE_URL = "postgresql+asyncpg://apex:apex_secret@localhost:5432/apex_db"


class Settings(BaseSettings):
    PROJECT_NAME: str = "Apex Attendance Platform"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = _DEFAULT_DATABASE_URL
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"
    CELERY_BROKER_URL: str = "redis://localhost:6379/1"
    CELERY_RESULT_BACKEND: str = "redis://localhost:6379/2"

    # JWT — no safe default; falls back to an ephemeral key in dev only
    SECRET_KEY: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    CORS_ORIGINS: list[str] = ["https://next.apextime.in", "http://localhost:3000", "http://localhost:8080"]

    # Encryption (Fernet key for eSSL passwords)
    ENCRYPTION_KEY: str = ""

    # Email (SMTP)
    SMTP_HOST: str = ""
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""
    SMTP_FROM_EMAIL: str = ""

    # SMS
    SMS_API_URL: str = ""
    SMS_API_KEY: str = ""

    # File Storage
    UPLOAD_DIR: str = "./uploads"
    MAX_UPLOAD_SIZE_MB: int = 10

    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 60

    # WebSocket
    WS_HEARTBEAT_INTERVAL: int = 30

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


def _is_dev_environment() -> bool:
    """Return True when running outside a production deployment."""
    env = os.getenv("ENVIRONMENT", os.getenv("ENV", "development")).lower()
    return env in ("development", "dev", "test", "testing", "local")


def validate_secrets(settings: Settings, *, on_startup: bool = False) -> list[str]:
    """Validate that critical secrets are not using insecure defaults.

    Returns a list of warning/error messages. When *on_startup* is True the
    function will CRITICAL-log blocking issues and, in production, refuse to
    start by raising ``SystemExit``.
    """
    issues: list[str] = []
    is_dev = _is_dev_environment()

    # --- SECRET_KEY ---
    if not settings.SECRET_KEY or settings.SECRET_KEY == _DEFAULT_SECRET_KEY:
        if is_dev:
            issues.append(
                "SECRET_KEY is empty or uses the insecure default. "
                "A random ephemeral key has been generated for this session — "
                "set a real value in .env for production."
            )
        else:
            msg = (
                "CRITICAL: SECRET_KEY is not set or still uses the insecure default. "
                "Set a unique, random SECRET_KEY (>= 32 chars) in your .env file."
            )
            logger.critical(msg)
            if on_startup:
                raise SystemExit(msg)
            issues.append(msg)

    # --- ENCRYPTION_KEY ---
    if not settings.ENCRYPTION_KEY:
        msg = (
            "ENCRYPTION_KEY is not set. eSSL device passwords stored in the "
            "database cannot be encrypted/decrypted. Generate one with: "
            "python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
        )
        if is_dev:
            issues.append(msg)
        else:
            logger.critical(msg)
            if on_startup:
                raise SystemExit(msg)
            issues.append(msg)

    # --- DATABASE_URL with embedded credentials ---
    if settings.DATABASE_URL == _DEFAULT_DATABASE_URL:
        issues.append(
            "DATABASE_URL uses the example default (apex:apex_secret). "
            "Override it in .env with real credentials."
        )

    return issues


def get_settings() -> Settings:
    settings = Settings()

    # Dev-only ephemeral fallback so imports never break
    if not settings.SECRET_KEY:
        if _is_dev_environment():
            settings.SECRET_KEY = secrets.token_urlsafe(48)
            logger.warning(
                "SECRET_KEY was empty — generated ephemeral dev key. "
                "This will change on every restart. Set SECRET_KEY in .env."
            )
        # Production: leave empty; validate_secrets(on_startup=True) will abort

    return settings
