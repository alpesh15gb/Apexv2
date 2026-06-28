"""Direct HTTP test against eBioserver API."""
import asyncio
import sys
import httpx
import base64
sys.path.insert(0, "/app")

from sqlalchemy import select
from app.db.session import async_session_factory
from app.models.essl_server import EsslServer
from app.core.encryption import decrypt_value


async def test():
    async with async_session_factory() as db:
        r = await db.execute(select(EsslServer).where(EsslServer.is_active == True))
        server = r.scalar_one_or_none()
        password = decrypt_value(server.password_encrypted)

        url = server.server_url
        username = server.username

        # Test GetEmployeePunchLogs with raw HTTP
        soap_body = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetEmployeePunchLogs xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <EmployeeCode>DW0006</EmployeeCode>
      <AttendanceDate>2026-06-27</AttendanceDate>
    </GetEmployeePunchLogs>
  </soap:Body>
</soap:Envelope>"""

        headers = {
            "Content-Type": "text/xml; charset=utf-8",
            "SOAPAction": "http://tempuri.org/GetEmployeePunchLogs"
        }

        print(f"URL: {url}")
        print(f"Username: {username}")
        print(f"Password: {password}")
        print(f"\nSending GetEmployeePunchLogs for DW0006 on 2026-06-27...")
        
        async with httpx.AsyncClient(timeout=30, verify=False) as client:
            resp = await client.post(url, content=soap_body.encode("utf-8"), headers=headers)
            print(f"Status: {resp.status_code}")
            print(f"Response:\n{resp.text[:2000]}")

        # Also try with Location parameter
        print("\n\n=== Try with Location parameter ===")
        soap_body2 = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetEmployeePunchLogs xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <EmployeeCode>DW0006</EmployeeCode>
      <AttendanceDate>2026-06-27</AttendanceDate>
      <Location>DW</Location>
    </GetEmployeePunchLogs>
  </soap:Body>
</soap:Envelope>"""
        
        async with httpx.AsyncClient(timeout=30, verify=False) as client:
            resp = await client.post(url, content=soap_body2.encode("utf-8"), headers=headers)
            print(f"Status: {resp.status_code}")
            print(f"Response:\n{resp.text[:2000]}")

        # Try GetDeviceLogs
        print("\n\n=== Try GetDeviceLogs ===")
        soap_body3 = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetDeviceLogs xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <DeviceSerialNumber>CGKK231461798</DeviceSerialNumber>
      <FromDate>2026-06-01</FromDate>
      <ToDate>2026-06-28</ToDate>
    </GetDeviceLogs>
  </soap:Body>
</soap:Envelope>"""
        
        async with httpx.AsyncClient(timeout=30, verify=False) as client:
            resp = await client.post(url, content=soap_body3.encode("utf-8"), headers=headers)
            print(f"Status: {resp.status_code}")
            print(f"Response:\n{resp.text[:2000]}")

        # Try GetEmployeeDetails
        print("\n\n=== Try GetEmployeeDetails ===")
        soap_body4 = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetEmployeeDetails xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <EmployeeCode>DW0006</EmployeeCode>
    </GetEmployeeDetails>
  </soap:Body>
</soap:Envelope>"""
        
        async with httpx.AsyncClient(timeout=30, verify=False) as client:
            resp = await client.post(url, content=soap_body4.encode("utf-8"), headers=headers)
            print(f"Status: {resp.status_code}")
            print(f"Response:\n{resp.text[:2000]}")


if __name__ == "__main__":
    asyncio.run(test())
