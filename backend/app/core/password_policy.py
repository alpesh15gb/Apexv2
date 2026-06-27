"""Password policy enforcement."""

import re
from typing import Tuple


def validate_password(password: str) -> Tuple[bool, str]:
    """Validate password against security policy.

    Returns (is_valid, error_message).
    """
    if len(password) < 8:
        return False, "Password must be at least 8 characters long"

    if len(password) > 128:
        return False, "Password must not exceed 128 characters"

    if not re.search(r'[A-Z]', password):
        return False, "Password must contain at least one uppercase letter"

    if not re.search(r'[a-z]', password):
        return False, "Password must contain at least one lowercase letter"

    if not re.search(r'[0-9]', password):
        return False, "Password must contain at least one digit"

    if not re.search(r'[!@#$%^&*(),.?":{}|<>]', password):
        return False, "Password must contain at least one special character"

    # Check for common passwords
    common_passwords = {
        'password', '123456', '12345678', 'qwerty', 'abc123',
        'password1', 'admin', 'letmein', 'welcome', 'monkey',
    }
    if password.lower() in common_passwords:
        return False, "Password is too common"

    return True, ""


def check_account_lockout(failed_attempts: int, locked_until) -> Tuple[bool, str]:
    """Check if account is locked.

    Returns (is_locked, error_message).
    """
    from datetime import datetime, timezone

    if locked_until and locked_until > datetime.now(timezone.utc):
        return True, f"Account is locked until {locked_until.isoformat()}. Try again later."

    if failed_attempts >= 5:
        return True, "Account is locked due to too many failed attempts. Try again in 30 minutes."

    return False, ""


def record_failed_login(user) -> None:
    """Record a failed login attempt."""
    from datetime import datetime, timezone, timedelta

    user.failed_login_attempts = (user.failed_login_attempts or 0) + 1
    if user.failed_login_attempts >= 5:
        user.locked_until = datetime.now(timezone.utc) + timedelta(minutes=30)


def reset_failed_login(user) -> None:
    """Reset failed login counter on successful login."""
    user.failed_login_attempts = 0
    user.locked_until = None
