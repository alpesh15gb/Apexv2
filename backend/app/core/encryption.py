"""Fernet symmetric encryption for sensitive data like eSSL passwords."""

import logging
from cryptography.fernet import Fernet
from app.core.config import get_settings

logger = logging.getLogger(__name__)


def _get_fernet() -> Fernet:
    settings = get_settings()
    key = settings.ENCRYPTION_KEY
    if not key or not key.strip():
        raise ValueError(
            "ENCRYPTION_KEY not configured. Set it in your .env file. "
            "Generate one with: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
        )
    key = key.strip()
    try:
        return Fernet(key.encode() if isinstance(key, str) else key)
    except ValueError:
        logger.error("ENCRYPTION_KEY is invalid. Key length: %d, repr: %r", len(key), key)
        raise ValueError(
            f"ENCRYPTION_KEY is not a valid Fernet key (got {len(key)} chars). "
            "It must be exactly 32 url-safe base64-encoded bytes. "
            "Generate a new one with: python -c \"from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())\""
        )


def encrypt_value(plaintext: str) -> str:
    """Encrypt a plaintext string. Returns base64-encoded ciphertext."""
    f = _get_fernet()
    return f.encrypt(plaintext.encode()).decode()


def decrypt_value(ciphertext: str) -> str:
    """Decrypt a Fernet ciphertext string. Returns plaintext."""
    f = _get_fernet()
    return f.decrypt(ciphertext.encode()).decode()


def generate_key() -> str:
    """Generate a new Fernet encryption key. Use once during setup."""
    return Fernet.generate_key().decode()
