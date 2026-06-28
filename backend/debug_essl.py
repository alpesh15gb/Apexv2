"""Debug eSSL API calls directly."""
import asyncio
import sys
import base64
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

        # Get employee mappings
        r2 = await db.execute(select(EsslEmployeeMapping).where(EsslEmployeeMapping.essl_server_id == server.id))
        emp_maps = list(r2.scalars().all())
        code = emp_maps[0].employee_code if emp_maps else "DW0006"

        # Step 1: Raw SOAP with plain password
        print(f"\n=== STEP 1: GetEmployeePunchLogs with PLAIN password for {code} ===")
        raw = await soap._execute_soap_call(
            "GetEmployeePunchLogs",
            {"EmployeeCode": code, "AttendanceDate": "2026-06-27"}
        )
        print(f"  Response: {str(raw)[:500]}")

        # Step 2: Raw SOAP with Base64 password
        print(f"\n=== STEP 2: GetEmployeePunchLogs with BASE64 password for {code} ===")
        b64_password = base64.b64encode(password.encode()).decode()
        soap_b64 = ESSLSoapService(server.server_url, server.username, b64_password, server.timeout_seconds)
        raw = await soap_b64._execute_soap_call(
            "GetEmployeePunchLogs",
            {"EmployeeCode": code, "AttendanceDate": "2026-06-27"}
        )
        print(f"  Response: {str(raw)[:500]}")

        # Step 3: Try different date formats
        print(f"\n=== STEP 3: Different date formats for {code} ===")
        for date_fmt in ["2026-06-27", "27/06/2026", "06/27/2026", "27-06-2026", "2026/06/27"]:
            raw = await soap._execute_soap_call(
                "GetEmployeePunchLogs",
                {"EmployeeCode": code, "AttendanceDate": date_fmt}
            )
            result_str = str(raw)[:200]
            print(f"  {date_fmt}: {result_str}")

        # Step 4: Try GetDeviceLogs with Base64 password
        print(f"\n=== STEP 4: GetDeviceLogs with BASE64 password ===")
        raw_dev = await soap.get_device_list()
        raw_data = raw_dev.get("data", "")
        if isinstance(raw_data, str) and ";" in raw_data:
            first_device = raw_data.split(";")[0].split(",")[1].strip()
            print(f"  Testing device: {first_device}")
            
            # Try plain password
            logs = await soap.get_device_logs(first_device, "2026-06-01", "2026-06-28")
            print(f"  Plain password - Success: {logs.get('success')}, Error: {logs.get('error')}")
            
            # Try Base64 password
            logs = await soap_b64.get_device_logs(first_device, "2026-06-01", "2026-06-28")
            print(f"  Base64 password - Success: {logs.get('success')}, Error: {logs.get('error')}")
            if logs.get('data'):
                print(f"  Data: {str(logs.get('data'))[:500]}")

        # Step 5: Try to get punch data from device logs
        print(f"\n=== STEP 5: DeviceCommand_GetDeviceLogs with Base64 password ===")
        if isinstance(raw_data, str) and ";" in raw_data:
            first_device = raw_data.split(";")[0].split(",")[1].strip()
            raw = await soap_b64._execute_soap_call(
                "DeviceCommand_GetDeviceLogs",
                {"DeviceSerialNumber": first_device, "varFromDate": "2026-06-01", "varToDate": "2026-06-28"}
            )
            print(f"  Response: {str(raw)[:500]}")


if __name__ == "__main__":
    asyncio.run(debug())
