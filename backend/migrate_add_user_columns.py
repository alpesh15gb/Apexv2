"""Add missing columns to users table."""

import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import engine


async def migrate():
    columns = [
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_password_change TIMESTAMPTZ",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ",
    ]
    async with engine.begin() as conn:
        for sql in columns:
            await conn.execute(text(sql))
            print(f"  done: {sql.split('NOT EXISTS ')[1]}")
    print("Migration complete: added missing user columns")


if __name__ == "__main__":
    asyncio.run(migrate())
