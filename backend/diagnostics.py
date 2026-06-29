import os
import sys
import asyncio
from datetime import datetime, timezone

# Add backend directory to path
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

from sqlalchemy import select, func
from app.core.config import get_settings
from app.db.session import async_session_factory
from app.models.attendance import AttendanceRawLog, Attendance
from app.models.essl_server import EsslServer
from app.models.essl_sync import EsslSyncHistory, EsslSyncError
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.employee import Employee

async def run_diagnostics():
    settings = get_settings()
    print("=== APEX VPS DIAGNOSTIC REPORT ===")
    print(f"Database URL: {settings.DATABASE_URL.split('@')[-1]} (masked)")
    print(f"Redis URL: {settings.REDIS_URL}")
    print("--------------------------------")
    
    async with async_session_factory() as session:
        # 1. Check Tenants and Configured Servers
        srv_stmt = select(EsslServer)
        srv_res = await session.execute(srv_stmt)
        servers = list(srv_res.scalars().all())
        print(f"Configured eSSL Servers: {len(servers)}")
        for idx, s in enumerate(servers):
            print(f"  [{idx}] Server ID: {s.id}")
            print(f"      Name: {s.name}")
            print(f"      URL: {s.server_url}")
            print(f"      Timezone: {s.timezone}")
            print(f"      Auto Sync: {s.auto_sync_enabled}")
            print(f"      Employee Conflict Policy: {s.employee_conflict_policy}")
            print(f"      Device Conflict Policy: {s.device_conflict_policy}")

        # 2. Check employee and device mappings
        emp_maps_stmt = select(func.count(EsslEmployeeMapping.id))
        emp_maps_res = await session.execute(emp_maps_stmt)
        print(f"Mapped Employees: {emp_maps_res.scalar()}")

        dev_maps_stmt = select(func.count(EsslDeviceMapping.id))
        dev_maps_res = await session.execute(dev_maps_stmt)
        print(f"Mapped Devices: {dev_maps_res.scalar()}")

        # 3. Check raw logs count and status
        raw_total_stmt = select(func.count(AttendanceRawLog.id))
        raw_total_res = await session.execute(raw_total_stmt)
        total_raw = raw_total_res.scalar()
        print(f"Total Raw Logs: {total_raw}")

        p_stmt = select(AttendanceRawLog.processed, func.count(AttendanceRawLog.id)).group_by(AttendanceRawLog.processed)
        p_res = await session.execute(p_stmt)
        processed_groups = {row[0]: row[1] for row in p_res.all()}
        print(f"Raw Logs Status (processed):")
        print(f"  Processed (True): {processed_groups.get(True, 0)}")
        print(f"  Unprocessed (False): {processed_groups.get(False, 0)}")

        # Check raw logs with processing errors
        err_stmt = select(AttendanceRawLog.processing_error, func.count(AttendanceRawLog.id)).where(AttendanceRawLog.processing_error.isnot(None)).group_by(AttendanceRawLog.processing_error)
        err_res = await session.execute(err_stmt)
        errors = err_res.all()
        print(f"Raw Logs with Processing Errors: {len(errors)}")
        for err_msg, count in errors:
            print(f"  - '{err_msg}': {count} logs")

        # 4. Check actual Attendance records
        att_total_stmt = select(func.count(Attendance.id))
        att_total_res = await session.execute(att_total_stmt)
        print(f"Total Attendance Records: {att_total_res.scalar()}")

        # Check first and last attendance dates/ranges
        if total_raw > 0:
            min_raw_stmt = select(func.min(AttendanceRawLog.punch_time))
            max_raw_stmt = select(func.max(AttendanceRawLog.punch_time))
            min_raw = (await session.execute(min_raw_stmt)).scalar()
            max_raw = (await session.execute(max_raw_stmt)).scalar()
            print(f"Raw Logs Date Range: {min_raw} to {max_raw}")

        # 5. Check sync history details
        sync_total_stmt = select(func.count(EsslSyncHistory.id))
        sync_total_res = await session.execute(sync_total_stmt)
        print(f"Sync History Jobs Run: {sync_total_res.scalar()}")

        history_status_stmt = select(EsslSyncHistory.status, func.count(EsslSyncHistory.id)).group_by(EsslSyncHistory.status)
        history_status_res = await session.execute(history_status_stmt)
        statuses = history_status_res.all()
        print("Sync History Job Statuses:")
        for status, count in statuses:
            print(f"  - {status}: {count}")

        # Let's list the most recent sync job errors
        recent_sync_errors_stmt = select(EsslSyncError).order_by(EsslSyncError.occurred_at.desc()).limit(10)
        recent_sync_errors_res = await session.execute(recent_sync_errors_stmt)
        sync_errors = list(recent_sync_errors_res.scalars().all())
        print(f"Recent Sync Errors (Last 10): {len(sync_errors)}")
        for se in sync_errors:
            print(f"  - {se.occurred_at}: {se.entity_type} {se.entity_identifier} -> {se.error_message}")

        # Connect to eSSL SOAP if server configured
        if servers:
            from app.services.essl_connector import EsslConnectorService
            for s in servers:
                print(f"\nTesting Connection for server: {s.name}...")
                connector = EsslConnectorService(session, s)
                try:
                    conn_test = await connector.test_connection()
                    print(f"  Test Result: {conn_test}")
                except Exception as e:
                    print(f"  Test Failed: {e}")

if __name__ == "__main__":
    asyncio.run(run_diagnostics())
