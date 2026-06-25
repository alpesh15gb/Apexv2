"""Fernet symmetric encryption for sensitive data like eSSL passwords."""

from cryptography.fernet import Fernet
from app.core.config import get_settings


def _get_fernet() -> Fernet:
    settings = get_settings()
    key = settings.ENCRYPTION_KEY
    if not key:
        raise ValueError("ENCRYPTION_KEY not configured in settings")
    return Fernet(key.encode() if isinstance(key, str) else key)


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
