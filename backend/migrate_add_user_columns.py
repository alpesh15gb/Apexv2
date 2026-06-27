"""Add missing columns to database tables."""

import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import engine


async def migrate():
    statements = [
        # Users table
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS must_change_password BOOLEAN NOT NULL DEFAULT false",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS last_password_change TIMESTAMPTZ",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS failed_login_attempts INTEGER NOT NULL DEFAULT 0",
        "ALTER TABLE users ADD COLUMN IF NOT EXISTS locked_until TIMESTAMPTZ",
        # Tenants table
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS subscription_status VARCHAR(50) NOT NULL DEFAULT 'trial'",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS trial_ends_at TIMESTAMPTZ",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS company_code VARCHAR(50)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS gst_number VARCHAR(20)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS pan_number VARCHAR(20)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS contact_person VARCHAR(255)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS email VARCHAR(255)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS mobile VARCHAR(20)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS timezone VARCHAR(100)",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS currency VARCHAR(10) NOT NULL DEFAULT 'INR'",
        "ALTER TABLE tenants ADD COLUMN IF NOT EXISTS financial_year_start VARCHAR(10) NOT NULL DEFAULT '04-01'",
        # Employees table
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS category_id UUID",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS shift_group_id UUID",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS shift_roster_id UUID",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS date_of_birth DATE",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS gender VARCHAR(50)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS address VARCHAR(512)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS city VARCHAR(100)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS state VARCHAR(100)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS pincode VARCHAR(20)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS emergency_contact_name VARCHAR(255)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS emergency_contact_phone VARCHAR(50)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS blood_group VARCHAR(20)",
        "ALTER TABLE employees ADD COLUMN IF NOT EXISTS photo_url VARCHAR(512)",
    ]
    async with engine.begin() as conn:
        for sql in statements:
            col = sql.split("IF NOT EXISTS ")[1].split(" ")[0]
            try:
                await conn.execute(text(sql))
                print(f"  added: {col}")
            except Exception as e:
                if "already exists" in str(e):
                    print(f"  exists: {col}")
                else:
                    print(f"  error on {col}: {e}")
    print("Migration complete")


if __name__ == "__main__":
    asyncio.run(migrate())
