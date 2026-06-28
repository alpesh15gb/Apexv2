"""Test multiple employee codes across all locations."""
import asyncio
import sys
import httpx
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

        # Test employees from each location prefix
        test_codes = [
            "DW0001", "DW0004", "DW0006",  # DWARKA
            "HO001", "HO009", "HO115",      # HEAD OFFICE
            "BLR0002", "BLR0005",            # BANGLORE
            "GN0001", "GN0003",              # GURGAON
        ]

        async with httpx.AsyncClient(timeout=30, verify=False) as client:
            for code in test_codes:
                soap_body = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetEmployeePunchLogs xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <EmployeeCode>{code}</EmployeeCode>
      <AttendanceDate>2026-06-27</AttendanceDate>
    </GetEmployeePunchLogs>
  </soap:Body>
</soap:Envelope>"""

                headers = {
                    "Content-Type": "text/xml; charset=utf-8",
                    "SOAPAction": "http://tempuri.org/GetEmployeePunchLogs"
                }

                resp = await client.post(url, content=soap_body.encode("utf-8"), headers=headers)
                # Extract result
                result = resp.text
                start = result.find("<GetEmployeePunchLogsResult>")
                end = result.find("</GetEmployeePunchLogsResult>")
                if start != -1 and end != -1:
                    data = result[start + len("<GetEmployeePunchLogsResult>"):end]
                else:
                    data = "PARSE_ERROR"
                
                status = "HAS DATA" if data and data != ";;" and data != "error" else "EMPTY"
                print(f"{code}: {status} -> {data[:100]}")

        # Also try different dates
        print("\n=== Try different dates for DW0001 ===")
        for date in ["2026-06-28", "2026-06-27", "2026-06-26", "2026-06-25", "2026-06-20", "2026-06-15", "2026-06-01"]:
            soap_body = f"""<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetEmployeePunchLogs xmlns="http://tempuri.org/">
      <UserName>{username}</UserName>
      <Password>{password}</Password>
      <EmployeeCode>DW0001</EmployeeCode>
      <AttendanceDate>{date}</AttendanceDate>
    </GetEmployeePunchLogs>
  </soap:Body>
</soap:Envelope>"""

            headers = {
                "Content-Type": "text/xml; charset=utf-8",
                "SOAPAction": "http://tempuri.org/GetEmployeePunchLogs"
            }

            resp = await client.post(url, content=soap_body.encode("utf-8"), headers=headers)
            result = resp.text
            start = result.find("<GetEmployeePunchLogsResult>")
            end = result.find("</GetEmployeePunchLogsResult>")
            if start != -1 and end != -1:
                data = result[start + len("<GetEmployeePunchLogsResult>"):end]
            else:
                data = "PARSE_ERROR"
            
            status = "HAS DATA" if data and data != ";;" and data != "error" else "EMPTY"
            print(f"  {date}: {status} -> {data[:100]}")


if __name__ == "__main__":
    asyncio.run(test())
