"""Diagnose eSSL sync issues. Run inside backend container."""
import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import async_session_factory


async def diagnose():
    async with async_session_factory() as db:
        print("=== eSSL SYNC DIAGNOSTIC ===\n")

        # 1. Raw logs
        r = await db.execute(text("SELECT COUNT(*) FROM attendance_raw_logs"))
        total = r.scalar()
        r = await db.execute(text("SELECT COUNT(*) FROM attendance_raw_logs WHERE processed = false"))
        unproc = r.scalar()
        print(f"Raw logs: {total} total, {unproc} unprocessed")

        # 2. Employee mappings
        r = await db.execute(text("SELECT COUNT(*) FROM essl_employee_mappings"))
        emp_maps = r.scalar()
        print(f"Employee mappings: {emp_maps}")

        r = await db.execute(text("SELECT COUNT(*) FROM essl_employee_mappings WHERE employee_id IS NOT NULL"))
        mapped = r.scalar()
        print(f"Mapped to internal employees: {mapped}")

        # 3. Device mappings
        r = await db.execute(text("SELECT COUNT(*) FROM essl_device_mappings"))
        dev_maps = r.scalar()
        print(f"Device mappings: {dev_maps}")

        # 4. Attendance records
        r = await db.execute(text("SELECT COUNT(*) FROM attendances"))
        att = r.scalar()
        print(f"Attendance records: {att}")

        # 5. Recent raw logs with mapping status
        r = await db.execute(text("""
            SELECT employee_code, employee_id IS NOT NULL as mapped, COUNT(*) as punches
            FROM attendance_raw_logs
            GROUP BY employee_code, employee_id IS NOT NULL
            ORDER BY punches DESC
            LIMIT 10
        """))
        rows = r.all()
        if rows:
            print("\nRecent raw log employees:")
            for row in rows:
                status = "MAPPED" if row[1] else "UNMAPPED"
                print(f"  {row[0]}: {row[2]} punches ({status})")

        # 6. Check if processors would find data
        r = await db.execute(text("""
            SELECT COUNT(*) FROM attendance_raw_logs
            WHERE processed = false AND employee_id IS NOT NULL
        """))
        processable = r.scalar()
        print(f"\nProcessable (unprocessed + mapped): {processable}")

        # 7. Sync history
        r = await db.execute(text("""
            SELECT sync_type, status, records_fetched, records_created, started_at
            FROM essl_sync_history
            ORDER BY started_at DESC
            LIMIT 5
        """))
        rows = r.all()
        if rows:
            print("\nRecent syncs:")
            for row in rows:
                print(f"  {row[0]} | {row[1]} | fetched:{row[2]} created:{row[3]} | {row[4]}")

    print("\n=== DIAGNOSIS ===")
    if total == 0:
        print("PROBLEM: No raw logs at all. eSSL server is not returning punch data.")
        print("FIX: Check eSSL server connectivity and GetDeviceLogs SOAP call.")
    elif unproc > 0 and mapped == 0:
        print("PROBLEM: Raw logs exist but no employee mappings.")
        print("FIX: Run employee sync first, or manually map eSSL codes to employees.")
    elif unproc > 0 and processable > 0:
        print("PROBLEM: Processable logs exist but haven't been processed.")
        print("FIX: Run processor manually or wait for next celery beat cycle.")
    elif unproc == 0 and att == 0:
        print("PROBLEM: All logs processed but no attendance records created.")
        print("FIX: Check processor logic - employees may not match.")
    elif att > 0:
        print("OK: Attendance records exist. Sync is working.")


if __name__ == "__main__":
    asyncio.run(diagnose())
