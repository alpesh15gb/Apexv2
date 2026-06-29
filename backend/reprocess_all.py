import asyncio
from sqlalchemy import select
from app.db.session import async_session_factory
from app.models.essl_server import EsslServer
from app.services.attendance_processor import AttendanceProcessor

async def run():
    async with async_session_factory() as db:
        stmt = select(EsslServer.tenant_id).limit(1)
        tenant_id = (await db.execute(stmt)).scalar()
        if not tenant_id:
            print("No tenant/server configured!")
            return
        processor = AttendanceProcessor(db)
        print(f"Starting reprocessing for tenant: {tenant_id}...")
        res = await processor.reprocess(tenant_id=tenant_id)
        print(f"Reprocessing finished: {res}")

if __name__ == "__main__":
    asyncio.run(run())
