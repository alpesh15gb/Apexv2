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
        # Get server
        r = await db.execute(select(EsslServer).where(EsslServer.is_active == True))
        server = r.scalar_one_or_none()
        if not server:
            print("No active server")
            return

        print(f"Server: {server.name} ({server.server_url})")
        print()

        # Get device mappings
        r = await db.execute(select(EsslDeviceMapping).where(EsslDeviceMapping.essl_server_id == server.id))
        dev_maps = list(r.scalars().all())
        print(f"Device mappings in DB: {len(dev_maps)}")
        for m in dev_maps:
            print(f"  {m.serial_number} -> {m.device_id}")

        # Get devices
        r = await db.execute(select(Device).where(Device.tenant_id == server.tenant_id))
        devices = list(r.scalars().all())
        print(f"\nDevices in DB: {len(devices)}")
        for d in devices:
            print(f"  {d.serial_number}: {d.device_name}")

        # Get employee mappings
        r = await db.execute(select(EsslEmployeeMapping).where(EsslEmployeeMapping.essl_server_id == server.id))
        emp_maps = list(r.scalars().all())
        print(f"\nEmployee mappings in DB: {len(emp_maps)}")
        for m in emp_maps[:5]:
            print(f"  {m.employee_code} -> {m.employee_id}")

        # Call GetDeviceList API
        print("\n=== Calling GetDeviceList ===")
        from app.services.essl_soap import ESSLSoapService
        from app.services.essl_client import ESSLClient
        from app.core.encryption import decrypt_value
        password = decrypt_value(server.password_encrypted)
        soap = ESSLSoapService(server.server_url, server.username, password, server.timeout_seconds)
        client = ESSLClient(soap)
        result = await client.get_devices(bypass_cache=True)
        print(f"Success: {result.get('success')}")
        print(f"Error: {result.get('error')}")
        data = result.get("data", [])
        if isinstance(data, dict):
            data = [data]
        print(f"Devices returned: {len(data)}")
        for d in data[:3]:
            print(f"  {d}")

        # Call GetEmployeeCodes
        print("\n=== Calling GetEmployeeCodes ===")
        result = await client.get_employee_codes()
        print(f"Success: {result.get('success')}")
        data = result.get("data", [])
        if isinstance(data, dict):
            data = [data]
        print(f"Employee codes returned: {len(data)}")
        for e in data[:5]:
            print(f"  {e}")

        # Call GetDeviceLogs for first device
        if dev_maps:
            serial = dev_maps[0].serial_number
            print(f"\n=== Calling GetDeviceLogs for {serial} ===")
            result = await client.soap.get_device_logs(serial, "2026-06-01", "2026-06-28")
            print(f"Success: {result.get('success')}")
            print(f"Error: {result.get('error')}")
            data = result.get("data", [])
            if isinstance(data, dict):
                data = [data]
            print(f"Logs returned: {len(data)}")
            for l in data[:3]:
                print(f"  {l}")
        elif devices:
            serial = devices[0].serial_number
            print(f"\n=== Calling GetDeviceLogs for {serial} (from devices table) ===")
            result = await client.soap.get_device_logs(serial, "2026-06-01", "2026-06-28")
            print(f"Success: {result.get('success')}")
            print(f"Error: {result.get('error')}")
            data = result.get("data", [])
            if isinstance(data, dict):
                data = [data]
            print(f"Logs returned: {len(data)}")
            for l in data[:3]:
                print(f"  {l}")

        # Call GetEmployeePunchLogs for first employee
        if emp_maps:
            code = emp_maps[0].employee_code
            print(f"\n=== Calling GetEmployeePunchLogs for {code} ===")
            result = await client.get_employee_punch_logs(code, "2026-06-25", "2026-06-28")
            print(f"Success: {result.get('success')}")
            print(f"Error: {result.get('error')}")
            data = result.get("data", [])
            if isinstance(data, dict):
                data = [data]
            print(f"Punches returned: {len(data)}")
            for p in data[:5]:
                print(f"  {p}")


if __name__ == "__main__":
    asyncio.run(debug())
