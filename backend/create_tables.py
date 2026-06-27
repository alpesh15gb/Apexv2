"""Create all database tables from models."""

import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import engine, Base
from app.models import *  # noqa: import all models to register them


async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print("All tables created successfully")


if __name__ == "__main__":
    asyncio.run(create_tables())
