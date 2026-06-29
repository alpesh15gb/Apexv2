import asyncio
from sqlalchemy import select
from app.db.session import async_session_factory
from app.models.essl_server import EsslServer
from app.services.essl_connector import EsslConnectorService

async def run():
    async with async_session_factory() as db:
        stmt = select(EsslServer).limit(1)
        server = (await db.execute(stmt)).scalar_one_or_none()
        if not server:
            print("No server configured!")
            return
        connector = EsslConnectorService(db, server)
        print(f"Starting sync for server: {server.name}...")
        res = await connector.sync_attendance(triggered_by="manual")
        print(f"Sync finished. Status: {res.status}")
        print(f"Fetched: {res.records_fetched}, Created: {res.records_created}, Skipped: {res.records_skipped}, Failed: {res.records_failed}")

if __name__ == "__main__":
    asyncio.run(run())
