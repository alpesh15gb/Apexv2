"""Debug eSSL API calls directly."""
import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import select
from app.db.session import async_session_factory
from app.models.essl_server import EsslServer
from app.models.essl_mapping import EsslDeviceMapping, EsslEmployeeMapping
from app.models.device import Device


async def debug():
    async with async_session_factory() as db:
        r = await db.execute(select(EsslServer).where(EsslServer.is_active == True))
        server = r.scalar_one_or_none()
        if not server:
            print("No active server")
            return

        print(f"Server: {server.name} ({server.server_url})")

        from app.services.essl_soap import ESSLSoapService
        from app.services.essl_client import ESSLClient
        from app.core.encryption import decrypt_value

        password = decrypt_value(server.password_encrypted)
        soap = ESSLSoapService(server.server_url, server.username, password, server.timeout_seconds)
        client = ESSLClient(soap)

        # Step 1: Get raw SOAP response for GetDeviceList
        print("\n=== STEP 1: Raw SOAP GetDeviceList ===")
        raw = await soap.get_device_list()
        print(f"Success: {raw.get('success')}")
        data = raw.get("data")
        print(f"Data type: {type(data).__name__}")
        print(f"Data: {str(data)[:500]}")

        # Step 2: Get processed response from client
        print("\n=== STEP 2: Client get_devices() ===")
        result = await client.get_devices(bypass_cache=True)
        data = result.get("data", [])
        print(f"Data type: {type(data).__name__}")
        if isinstance(data, dict):
            items = data.get("items", [])
            print(f"Items type: {type(items).__name__}, count: {len(items)}")
            for i, item in enumerate(items[:3]):
                print(f"  [{i}] type={type(item).__name__}, value={str(item)[:200]}")
                if hasattr(item, 'model_dump'):
                    print(f"       dict={item.model_dump()}")
                elif isinstance(item, dict):
                    print(f"       keys={list(item.keys())}")

        # Step 3: Simulate sync_devices extraction
        print("\n=== STEP 3: Simulate sync extraction ===")
        all_essl_devices = []
        batch = result.get("data", [])
        if isinstance(batch, dict) and "items" in batch:
            batch = batch["items"]
        elif isinstance(batch, dict):
            batch = [batch]
        for d in batch:
            if isinstance(d, str):
                print(f"  SKIPPED string: {d[:50]}")
                continue
            if hasattr(d, 'model_dump'):
                all_essl_devices.append(d.model_dump())
            elif isinstance(d, dict):
                all_essl_devices.append(d)
            else:
                print(f"  SKIPPED unknown type: {type(d).__name__}")
        print(f"Extracted devices: {len(all_essl_devices)}")
        for d in all_essl_devices[:3]:
            print(f"  {d}")

        # Step 4: Test GetEmployeePunchLogs with wider date range
        print("\n=== STEP 4: GetEmployeePunchLogs (wide range) ===")
        r2 = await db.execute(select(EsslEmployeeMapping).where(EsslEmployeeMapping.essl_server_id == server.id))
        emp_maps = list(r2.scalars().all())
        if emp_maps:
            code = emp_maps[0].employee_code
            result = await client.get_employee_punch_logs(code, "2026-01-01", "2026-06-28")
            data = result.get("data", {})
            if isinstance(data, dict) and "items" in data:
                items = data["items"]
                print(f"Punches for {code}: {len(items)} items")
            else:
                print(f"Data type: {type(data).__name__}, value: {str(data)[:300]}")

        # Step 5: Test GetDeviceLogs SOAP directly (not DeviceCommand)
        print("\n=== STEP 5: Raw SOAP GetDeviceLogs ===")
        raw = await soap.get_device_list()
        raw_data = raw.get("data", "")
        if isinstance(raw_data, str) and ";" in raw_data:
            first_device = raw_data.split(";")[0].split(",")[1].strip()
            print(f"Testing device: {first_device}")
            logs = await soap.get_device_logs(first_device, "2026-06-01", "2026-06-28")
            print(f"Success: {logs.get('success')}")
            print(f"Error: {logs.get('error')}")
            log_data = logs.get("data")
            print(f"Data type: {type(log_data).__name__}")
            print(f"Data: {str(log_data)[:500]}")

        # Step 6: Raw SOAP GetEmployeePunchLogs for one day
        print("\n=== STEP 6: Raw SOAP GetEmployeePunchLogs ===")
        if emp_maps:
            code = emp_maps[0].employee_code
            raw = await soap._execute_soap_call(
                "GetEmployeePunchLogs",
                {"EmployeeCode": code, "AttendanceDate": "2026-06-27"}
            )
            print(f"Raw response for {code} on 2026-06-27:")
            print(f"  {str(raw)[:500]}")

        # Step 7: Check DeviceCommand_GetDeviceLogs
        print("\n=== STEP 7: DeviceCommand_GetDeviceLogs ===")
        if isinstance(raw_data, str) and ";" in raw_data:
            first_device = raw_data.split(";")[0].split(",")[1].strip()
            raw = await soap._execute_soap_call(
                "DeviceCommand_GetDeviceLogs",
                {"DeviceSerialNumber": first_device, "varFromDate": "2026-06-01", "varToDate": "2026-06-28"}
            )
            print(f"Raw response for {first_device}:")
            print(f"  {str(raw)[:500]}")


if __name__ == "__main__":
    asyncio.run(debug())
