import httpx
from lxml import etree
import structlog
from datetime import datetime, date, timedelta
from typing import Any, Dict, List, Tuple, Optional
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from circuitbreaker import CircuitBreaker, CircuitBreakerError

logger = structlog.get_logger(__name__)


class ESSLSoapService:
    """
    SOAP integration layer for eSSL eBioserverNew.
    Communicates via raw XML SOAP 1.1 with error retries and circuit breaker.
    """

    def __init__(self, server_url: str, username: str, password: str, timeout: int = 30):
        self.url = server_url
        self.username = username
        self.password = password
        self.timeout = float(timeout)
        self.breaker = CircuitBreaker(
            failure_threshold=5,
            recovery_timeout=60,
            expected_exception=Exception
        )

    def _build_envelope(self, operation: str, params: Dict[str, Any]) -> bytes:
        """
        Manually constructs the SOAP 1.1 Envelope with tempuri.org namespace.
        """
        soap_ns = "http://schemas.xmlsoap.org/soap/envelope/"
        tempuri_ns = "http://tempuri.org/"

        # Create Root envelope element
        envelope = etree.Element(
            f"{{{soap_ns}}}Envelope",
            nsmap={
                "soap": soap_ns,
                "xsi": "http://www.w3.org/2001/XMLSchema-instance",
                "xsd": "http://www.w3.org/2001/XMLSchema"
            }
        )
        body = etree.SubElement(envelope, f"{{{soap_ns}}}Body")
        op_elem = etree.SubElement(body, f"{{{tempuri_ns}}}{operation}", nsmap={None: tempuri_ns})

        # Inject username and password for all operations except ValidateVisitorDesk
        if operation != "ValidateVisitorDesk":
            username_elem = etree.SubElement(op_elem, "UserName")
            username_elem.text = self.username
            password_elem = etree.SubElement(op_elem, "Password")
            password_elem.text = self.password

        # Inject parameters
        for key, val in params.items():
            child = etree.SubElement(op_elem, key)
            if val is None:
                child.text = ""
            elif isinstance(val, bool):
                child.text = "true" if val else "false"
            else:
                child.text = str(val)

        return etree.tostring(envelope, xml_declaration=True, encoding="utf-8")

    def _parse_response(self, operation: str, response_text: str) -> str:
        """
        Parses SOAP response and extracts result text.
        """
        try:
            root = etree.fromstring(response_text.encode("utf-8"))
            tempuri_ns = "http://tempuri.org/"

            # Attempt namespace match
            results = root.xpath(f"//tempuri:{operation}Result", namespaces={"tempuri": tempuri_ns})
            if not results:
                # Fallback to local-name match
                results = root.xpath(f"//*[local-name()='{operation}Result']")

            if results:
                return results[0].text or ""
            
            raise ValueError(f"Could not find {operation}Result element in response")
        except Exception as e:
            logger.error("Failed parsing SOAP XML response", error=str(e), operation=operation, response_preview=response_text[:500])
            raise ValueError(f"Response parsing failed: {str(e)}")

    def _node_to_dict_or_list(self, node: etree._Element) -> Any:
        """
        Helper that recursively converts XML node children to dict/list structures.
        """
        children = list(node)
        if not children:
            return node.text or ""

        tag_counts = {}
        for c in children:
            tag_counts[c.tag] = tag_counts.get(c.tag, 0) + 1

        # If a single tag repeated, or all children have same tag, parse as list
        is_list = len(tag_counts) == 1 or any(count > 1 for count in tag_counts.values())

        if is_list:
            return [self._node_to_dict_or_list(c) for c in children]
        else:
            res = {}
            for c in children:
                res[c.tag] = self._node_to_dict_or_list(c)
            return res

    def _xml_to_dict_or_list(self, xml_str: str) -> Any:
        """
        Safely attempts to parse result text string if it represents nested XML records.
        """
        if not xml_str:
            return ""
        
        trimmed = xml_str.strip()
        if not trimmed.startswith("<"):
            return trimmed

        try:
            root = etree.fromstring(trimmed.encode("utf-8"))
            return self._node_to_dict_or_list(root)
        except Exception:
            return trimmed

    def _evaluate_success(self, op: str, parsed_val: Any) -> Tuple[bool, Any, Optional[str]]:
        """
        Standardizes return checks based on result parsing.
        """
        if parsed_val == "error" or parsed_val == "0":
            return False, None, f"SOAP operation {op} failed with service error"
        return True, parsed_val, None

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=2, max=10),
        retry=retry_if_exception_type(httpx.RequestError),
        reraise=True
    )
    async def _send_request_raw(self, headers: Dict[str, str], payload: bytes) -> httpx.Response:
        """
        Fires async HTTP request with tenacity retries on request/network errors.
        """
        async with httpx.AsyncClient(timeout=self.timeout, follow_redirects=True, verify=False) as client:
            response = await client.post(self.url, headers=headers, content=payload)
            response.raise_for_status()
            return response

    async def _execute_soap_call(self, operation: str, params: Dict[str, Any]) -> str:
        async def _do_call() -> str:
            payload = self._build_envelope(operation, params)
            headers = {
                "Content-Type": "text/xml; charset=utf-8",
                "SOAPAction": f"http://tempuri.org/{operation}"
            }
            response = await self._send_request_raw(headers, payload)
            return self._parse_response(operation, response.text)
        return await self.breaker.call_async(_do_call)

    # ==========================================
    # DEVICE OPERATIONS
    # ==========================================

    async def get_device_list(self, location: str = "") -> Dict[str, Any]:
        """
        Retrieves device list from eBioserver.
        """
        try:
            raw = await self._execute_soap_call("GetDeviceList", {"Location": location})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("GetDeviceList", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_device_list", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_device_list failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def get_device_last_ping(self, device_id: str) -> Dict[str, Any]:
        """
        Gets device last ping info.
        """
        try:
            raw = await self._execute_soap_call("GetDeviceLastPing", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("GetDeviceLastPing", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_device_last_ping", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_device_last_ping failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def get_device_logs(self, device_id: str, from_date: Any, to_date: Any) -> Dict[str, Any]:
        """
        Retrieves device logs using date range via GetDeviceLogs API.
        """
        try:
            from_str = from_date.strftime("%Y-%m-%d") if isinstance(from_date, (datetime, date)) else str(from_date)
            to_str = to_date.strftime("%Y-%m-%d") if isinstance(to_date, (datetime, date)) else str(to_date)

            raw = await self._execute_soap_call(
                "GetDeviceLogs",
                {
                    "DeviceSerialNumber": device_id,
                    "FromDate": from_str,
                    "ToDate": to_str
                }
            )
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("GetDeviceLogs", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_device_logs", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_device_logs failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def update_device(self, device_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Updates device configuration on eBioserver.
        """
        try:
            params = {
                "DeviceSerialNumber": device_data.get("serial_number"),
                "DeviceName": device_data.get("device_name"),
                "DeviceDiretion": device_data.get("direction", "0"),
                "DeviceType": device_data.get("device_type", "0"),
                "TimeZone": device_data.get("timezone", "0"),
                "DeviceActivationCode": device_data.get("activation_code", ""),
                "Location": device_data.get("location", ""),
                "IsAttendanceDevice": "1" if device_data.get("is_attendance_device", True) else "0"
            }
            raw = await self._execute_soap_call("UpdateDevice", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("UpdateDevice", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for update_device", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP update_device failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def delete_device(self, device_id: str) -> Dict[str, Any]:
        """
        Deletes device from eBioserver.
        """
        try:
            raw = await self._execute_soap_call("DeleteDevice", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeleteDevice", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for delete_device", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP delete_device failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    # ==========================================
    # EMPLOYEE OPERATIONS
    # ==========================================

    async def get_employee_codes(self, location: str = "") -> Dict[str, Any]:
        """
        Retrieves list of employee codes.
        """
        try:
            raw = await self._execute_soap_call("GetEmployeeCodes", {"EmployeeLocation": location})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("GetEmployeeCodes", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_employee_codes", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_employee_codes failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def get_employee_details(self, employee_code: str) -> Dict[str, Any]:
        """
        Gets details of a single employee.
        """
        try:
            raw = await self._execute_soap_call("GetEmployeeDetails", {"EmployeeCode": employee_code})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("GetEmployeeDetails", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_employee_details", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_employee_details failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def get_employee_punch_logs(self, employee_code: str, from_date: Any, to_date: Any) -> Dict[str, Any]:
        """
        Gets employee punch logs over date range by querying day-by-day.
        """
        try:
            # Standardize date types
            if isinstance(from_date, str):
                from_date = datetime.strptime(from_date, "%Y-%m-%d").date()
            elif isinstance(from_date, datetime):
                from_date = from_date.date()

            if isinstance(to_date, str):
                to_date = datetime.strptime(to_date, "%Y-%m-%d").date()
            elif isinstance(to_date, datetime):
                to_date = to_date.date()

            current_date = from_date
            all_logs = []

            while current_date <= to_date:
                date_str = current_date.strftime("%Y-%m-%d")
                raw = await self._execute_soap_call(
                    "GetEmployeePunchLogs",
                    {"EmployeeCode": employee_code, "AttendanceDate": date_str}
                )
                parsed = self._xml_to_dict_or_list(raw)
                
                # Check for individual call success
                if parsed and parsed != "error" and parsed != "0":
                    if isinstance(parsed, list):
                        all_logs.extend(parsed)
                    elif isinstance(parsed, dict):
                        all_logs.append(parsed)
                    else:
                        pass # Ignore plain status codes
                current_date += timedelta(days=1)

            return {"success": True, "data": all_logs, "error": None}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for get_employee_punch_logs", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP get_employee_punch_logs failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def update_employee(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Creates/updates basic employee details.
        """
        try:
            params = {
                "EmployeeCode": employee_data.get("employee_code"),
                "EmployeeName": employee_data.get("name") or f"{employee_data.get('first_name', '')} {employee_data.get('last_name', '')}".strip(),
                "EmployeeLocation": employee_data.get("location", ""),
                "EmployeeRole": employee_data.get("role", "0"),
                "EmployeeVerificationType": employee_data.get("verification_type", "0")
            }
            raw = await self._execute_soap_call("UpdateEmployee", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("UpdateEmployee", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for update_employee", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP update_employee failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def update_employee_ex(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Updates employee details with extended parameters (dates, cards, photos).
        """
        try:
            params = {
                "EmployeeCode": employee_data.get("employee_code"),
                "EmployeeName": employee_data.get("name") or f"{employee_data.get('first_name', '')} {employee_data.get('last_name', '')}".strip(),
                "EmployeeLocation": employee_data.get("location", ""),
                "EmployeeRole": employee_data.get("role", "0"),
                "EmployeeVerificationType": employee_data.get("verification_type", "0"),
                "EmployeeExpiryFrom": employee_data.get("expiry_from", ""),
                "EmployeeExpiryTo": employee_data.get("expiry_to", ""),
                "EmployeeCardNumber": employee_data.get("card_number", ""),
                "GroupId": employee_data.get("group_id", "0"),
                "EmployeePhoto": employee_data.get("photo", "") # Base64 encoded string
            }
            raw = await self._execute_soap_call("UpdateEmployeeEx", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("UpdateEmployeeEx", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for update_employee_ex", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP update_employee_ex failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def update_employee_photo(self, employee_code: str, photo_data: str) -> Dict[str, Any]:
        """
        Uploads employee photo.
        """
        try:
            params = {
                "EmployeeCode": employee_code,
                "EmployeePhoto": photo_data # Base64 encoded photo
            }
            raw = await self._execute_soap_call("UpdateEmployeePhoto", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("UpdateEmployeePhoto", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for update_employee_photo", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP update_employee_photo failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def delete_employee(self, employee_code: str) -> Dict[str, Any]:
        """
        Deletes employee from eBioserver.
        """
        try:
            raw = await self._execute_soap_call("DeleteEmployee", {"EmployeeCode": employee_code})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeleteEmployee", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for delete_employee", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP delete_employee failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    # ==========================================
    # LOCATION OPERATIONS
    # ==========================================

    async def update_location(self, location_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Creates/updates location details.
        """
        try:
            params = {
                "LocationCode": location_data.get("location_code"),
                "LocationDescription": location_data.get("description", "")
            }
            raw = await self._execute_soap_call("UpdateLocation", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("UpdateLocation", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for update_location", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP update_location failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def delete_location(self, location_id: str) -> Dict[str, Any]:
        """
        Deletes location.
        """
        try:
            raw = await self._execute_soap_call("DeleteLocation", {"LocationCode": location_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeleteLocation", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for delete_location", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP delete_location failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    # ==========================================
    # DEVICE COMMANDS
    # ==========================================

    async def device_command_reboot(self, device_id: str) -> Dict[str, Any]:
        """
        Commands device to reboot.
        """
        try:
            raw = await self._execute_soap_call("DeviceCommand_Reboot", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_Reboot", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_reboot", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_reboot failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_clear_logs(self, device_id: str) -> Dict[str, Any]:
        """
        Clears transaction logs from device memory.
        """
        try:
            raw = await self._execute_soap_call("DeviceCommand_ClearLogs", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_ClearLogs", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_clear_logs", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_clear_logs failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_enroll_fp(self, device_id: str, employee_code: str) -> Dict[str, Any]:
        """
        Commands device to enroll fingerprint.
        """
        try:
            params = {
                "DeviceSerialNumber": device_id,
                "EmployeeCode": employee_code,
                "FPIndex": "0" # Default fingerprint index
            }
            raw = await self._execute_soap_call("DeviceCommand_EnrollFP", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_EnrollFP", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_enroll_fp", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_enroll_fp failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_enroll_face(self, device_id: str, employee_code: str) -> Dict[str, Any]:
        """
        Commands device to enroll face template.
        """
        try:
            params = {
                "DeviceSerialNumber": device_id,
                "EmployeeCode": employee_code
            }
            raw = await self._execute_soap_call("DeviceCommand_EnrollFace", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_EnrollFace", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_enroll_face", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_enroll_face failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_unlock_door(self, device_id: str) -> Dict[str, Any]:
        """
        Commands access control device to unlock door relay.
        """
        try:
            raw = await self._execute_soap_call("DeviceCommand_UnlockDoor", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_UnlockDoor", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_unlock_door", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_unlock_door failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_block_unblock_user(self, device_id: str, employee_code: str, block: bool) -> Dict[str, Any]:
        """
        Enables/disables access/biometrics for employee on specific device.
        """
        try:
            params = {
                "DeviceSerialNumber": device_id,
                "EmployeeCode": employee_code,
                "BlockUser": block
            }
            raw = await self._execute_soap_call("DeviceCommand_BlockUnBlockUser", params)
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_BlockUnBlockUser", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_block_unblock_user", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_block_unblock_user failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_reset_op_stamp(self, device_id: str) -> Dict[str, Any]:
        """
        Resets operator command stamp on device.
        """
        try:
            raw = await self._execute_soap_call("DeviceCommand_ResetOPStamp", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_ResetOPStamp", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_reset_op_stamp", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_reset_op_stamp failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    async def device_command_reset_transaction_stamp(self, device_id: str) -> Dict[str, Any]:
        """
        Resets transaction (log) sync stamp on device.
        """
        try:
            raw = await self._execute_soap_call("DeviceCommand_ResetTransactionStamp", {"DeviceSerialNumber": device_id})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("DeviceCommand_ResetTransactionStamp", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for device_command_reset_transaction_stamp", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP device_command_reset_transaction_stamp failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}

    # ==========================================
    # VISITOR
    # ==========================================

    async def validate_visitor_desk(self, visitor_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validates visitor pass.
        """
        try:
            uuid_val = visitor_data.get("uuid") or visitor_data.get("pass_number")
            raw = await self._execute_soap_call("ValidateVisitorDesk", {"UUID": uuid_val})
            parsed = self._xml_to_dict_or_list(raw)
            success, data, error = self._evaluate_success("ValidateVisitorDesk", parsed)
            return {"success": success, "data": data, "error": error}
        except CircuitBreakerError as e:
            logger.error("Circuit breaker open for validate_visitor_desk", error=str(e))
            return {"success": False, "data": None, "error": f"Circuit breaker open: {str(e)}"}
        except Exception as e:
            logger.error("SOAP validate_visitor_desk failed", error=str(e))
            return {"success": False, "data": None, "error": str(e)}
