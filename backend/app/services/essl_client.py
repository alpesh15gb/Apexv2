import orjson
import structlog
from typing import Any, Dict, List, Optional
from datetime import datetime, date
from pydantic import BaseModel, Field
from redis.asyncio import Redis

from app.services.essl_soap import ESSLSoapService

logger = structlog.get_logger(__name__)


# ==========================================
# TYPED RESULT OBJECTS
# ==========================================

class ESSLDevice(BaseModel):
    serial_number: str
    device_name: str
    location: Optional[str] = None
    status: Optional[str] = None
    last_ping: Optional[str] = None

    model_config = {"extra": "ignore"}


class ESSLEmployee(BaseModel):
    employee_code: str
    name: str
    location: Optional[str] = None
    role: Optional[str] = None
    verification_type: Optional[str] = None
    card_number: Optional[str] = None
    expiry_from: Optional[str] = None
    expiry_to: Optional[str] = None

    model_config = {"extra": "ignore"}


class ESSLPunchLog(BaseModel):
    employee_code: str
    punch_time: datetime
    punch_type: Optional[str] = None
    device_serial: Optional[str] = None

    model_config = {"extra": "ignore"}


# ==========================================
# UTILITY FUNCTIONS
# ==========================================

def normalize_keys(data: Any) -> Any:
    """
    Recursively converts SOAP PascalCase dictionary keys to snake_case.
    """
    if isinstance(data, list):
        return [normalize_keys(item) for item in data]
    if isinstance(data, dict):
        new_dict = {}
        for k, v in data.items():
            # Conversion mapping
            key_map = {
                "DeviceSerialNumber": "serial_number",
                "DeviceName": "device_name",
                "Location": "location",
                "Status": "status",
                "LastPingTime": "last_ping",
                "EmployeeCode": "employee_code",
                "EmployeeName": "name",
                "EmployeeLocation": "location",
                "EmployeeRole": "role",
                "EmployeeVerificationType": "verification_type",
                "EmployeeCardNumber": "card_number",
                "EmployeeExpiryFrom": "expiry_from",
                "EmployeeExpiryTo": "expiry_to",
                "PunchTime": "punch_time",
                "PunchType": "punch_type",
                "LogDate": "log_date",
                "LogType": "log_type",
                "UUID": "uuid",
            }
            new_key = key_map.get(k, k.lower())
            new_dict[new_key] = normalize_keys(v)
        return new_dict
    return data


class ESSLClient:
    """
    Higher-level ESSL client wrapping ESSLSoapService.
    Adds Redis caching for lists and details, pagination, and typed Pydantic structures.
    """

    def __init__(self, soap_service: ESSLSoapService, redis_url: Optional[str] = None):
        self.soap = soap_service
        self.redis_url = redis_url

    async def _get_redis(self) -> Optional[Redis]:
        if not self.redis_url:
            return None
        try:
            return Redis.from_url(self.redis_url, decode_responses=True)
        except Exception as e:
            logger.warning("Redis is unavailable; caching will be bypassed", error=str(e))
            return None

    def _paginate(self, items: List[Any], page: Optional[int], page_size: Optional[int]) -> Dict[str, Any]:
        """
        Slices a list based on page and page_size parameters.
        """
        if not page or not page_size:
            return {
                "items": items,
                "total": len(items),
                "page": 1,
                "page_size": len(items),
                "total_pages": 1
            }

        total = len(items)
        start = (page - 1) * page_size
        end = start + page_size
        sliced = items[start:end]

        return {
            "items": sliced,
            "total": total,
            "page": page,
            "page_size": page_size,
            "total_pages": (total + page_size - 1) // page_size if total > 0 else 0
        }

    # ==========================================
    # DEVICE OPERATIONS
    # ==========================================

    async def get_devices(self, bypass_cache: bool = False, page: Optional[int] = None, page_size: Optional[int] = None, location: str = "") -> Dict[str, Any]:
        """
        Gets all devices with Redis caching and pagination.
        Returns Dict with success, data (items, total, page, page_size, total_pages), error.
        """
        redis = await self._get_redis()
        cache_key = "essl:device_list"
        cached_data = None

        if redis and not bypass_cache:
            try:
                cached_data = await redis.get(cache_key)
            except Exception as e:
                logger.error("Failed to read device cache", error=str(e))

        devices_dict_list = []
        if cached_data:
            try:
                devices_dict_list = orjson.loads(cached_data)
            except Exception as e:
                logger.error("Failed to parse cached device list", error=str(e))
                cached_data = None

        if not cached_data:
            res = await self.soap.get_device_list(location=location)
            if not res["success"]:
                return res

            raw_items = res["data"]
            # Ensure it is a list
            if isinstance(raw_items, dict):
                raw_items = [raw_items]
            elif not isinstance(raw_items, list):
                raw_items = []

            devices_dict_list = normalize_keys(raw_items)

            if redis:
                try:
                    await redis.setex(cache_key, 300, orjson.dumps(devices_dict_list)) # 5 min TTL
                except Exception as e:
                    logger.error("Failed to write device cache", error=str(e))

        # Map to Pydantic objects
        typed_devices = []
        for d in devices_dict_list:
            try:
                typed_devices.append(ESSLDevice(**d))
            except Exception as e:
                logger.warn("Skipped malformed device dictionary", data=d, error=str(e))

        paginated = self._paginate(typed_devices, page, page_size)
        return {"success": True, "data": paginated, "error": None}

    async def get_device_last_ping(self, device_id: str) -> Dict[str, Any]:
        """
        Delegates last ping retrieval.
        """
        res = await self.soap.get_device_last_ping(device_id)
        if res["success"]:
            res["data"] = normalize_keys(res["data"])
        return res

    async def get_device_logs(self, device_id: str, from_date: Any, to_date: Any, page: Optional[int] = None, page_size: Optional[int] = None) -> Dict[str, Any]:
        """
        Gets device log events with pagination support.
        """
        res = await self.soap.get_device_logs(device_id, from_date, to_date)
        if not res["success"]:
            return res

        raw_logs = res["data"]
        if isinstance(raw_logs, dict):
            raw_logs = [raw_logs]
        elif not isinstance(raw_logs, list):
            raw_logs = []

        normalized = normalize_keys(raw_logs)
        paginated = self._paginate(normalized, page, page_size)
        return {"success": True, "data": paginated, "error": None}

    async def update_device(self, device_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Delegates update and clears device cache.
        """
        res = await self.soap.update_device(device_data)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete("essl:device_list")
        return res

    async def delete_device(self, device_id: str) -> Dict[str, Any]:
        """
        Delegates delete and clears device cache.
        """
        res = await self.soap.delete_device(device_id)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete("essl:device_list")
        return res

    # ==========================================
    # EMPLOYEE OPERATIONS
    # ==========================================

    async def get_employee_codes(self, page: Optional[int] = None, page_size: Optional[int] = None, location: str = "") -> Dict[str, Any]:
        """
        Gets all employee codes.
        """
        res = await self.soap.get_employee_codes(location=location)
        if not res["success"]:
            return res

        raw_codes = res["data"]
        if isinstance(raw_codes, str):
            raw_codes = [{"employee_code": c.strip()} for c in raw_codes.split(",") if c.strip()]
        elif isinstance(raw_codes, dict):
            raw_codes = [raw_codes]
        elif not isinstance(raw_codes, list):
            raw_codes = []

        normalized = normalize_keys(raw_codes)
        # Codes are usually a list of dicts like [{"employee_code": "..."}]
        codes = [item.get("employee_code") for item in normalized if "employee_code" in item]

        paginated = self._paginate(codes, page, page_size)
        return {"success": True, "data": paginated, "error": None}

    async def get_employee_details(self, employee_code: str, bypass_cache: bool = False) -> Dict[str, Any]:
        """
        Gets employee details with Redis caching.
        """
        redis = await self._get_redis()
        cache_key = f"essl:employee_details:{employee_code}"
        cached_data = None

        if redis and not bypass_cache:
            try:
                cached_data = await redis.get(cache_key)
            except Exception as e:
                logger.error("Failed to read employee cache", error=str(e))

        emp_dict = None
        if cached_data:
            try:
                emp_dict = orjson.loads(cached_data)
            except Exception as e:
                logger.error("Failed to parse cached employee details", error=str(e))
                cached_data = None

        if not cached_data:
            res = await self.soap.get_employee_details(employee_code)
            if not res["success"]:
                return res

            raw_data = res["data"]
            if isinstance(raw_data, str) and "=" in raw_data:
                raw_data = {k.strip(): v.strip() for k, v in
                            (pair.split("=", 1) for pair in raw_data.split(",") if "=" in pair)}
            if isinstance(raw_data, dict) and "EmployeeCode" not in raw_data and "employee_code" not in raw_data:
                raw_data["EmployeeCode"] = employee_code
            emp_dict = normalize_keys(raw_data)

            if redis and emp_dict:
                try:
                    await redis.setex(cache_key, 600, orjson.dumps(emp_dict)) # 10 min TTL
                except Exception as e:
                    logger.error("Failed to write employee cache", error=str(e))

        if not emp_dict:
            return {"success": False, "data": None, "error": "Employee details not found"}

        try:
            typed_employee = ESSLEmployee(**emp_dict)
            return {"success": True, "data": typed_employee, "error": None}
        except Exception as e:
            logger.error("Failed parsing employee object", error=str(e))
            return {"success": False, "data": None, "error": f"Data validation error: {str(e)}"}

    async def get_employee_punch_logs(self, employee_code: str, from_date: Any, to_date: Any, page: Optional[int] = None, page_size: Optional[int] = None) -> Dict[str, Any]:
        """
        Retrieves employee punch logs and validates them as ESSLPunchLog types.
        """
        res = await self.soap.get_employee_punch_logs(employee_code, from_date, to_date)
        if not res["success"]:
            return res

        raw_logs = res["data"]
        normalized = normalize_keys(raw_logs)

        typed_logs = []
        for log in normalized:
            try:
                # SOAP returns punch times in standard strings. Map appropriately.
                typed_logs.append(ESSLPunchLog(**log))
            except Exception as e:
                logger.warn("Skipped malformed punch log", data=log, error=str(e))

        paginated = self._paginate(typed_logs, page, page_size)
        return {"success": True, "data": paginated, "error": None}

    async def update_employee(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Delegates update and clears employee cache.
        """
        res = await self.soap.update_employee(employee_data)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete(f"essl:employee_details:{employee_data.get('employee_code')}")
        return res

    async def update_employee_ex(self, employee_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Delegates extended update and clears employee cache.
        """
        res = await self.soap.update_employee_ex(employee_data)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete(f"essl:employee_details:{employee_data.get('employee_code')}")
        return res

    async def update_employee_photo(self, employee_code: str, photo_data: str) -> Dict[str, Any]:
        """
        Delegates photo update and clears employee cache.
        """
        res = await self.soap.update_employee_photo(employee_code, photo_data)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete(f"essl:employee_details:{employee_code}")
        return res

    async def delete_employee(self, employee_code: str) -> Dict[str, Any]:
        """
        Delegates delete and clears employee cache.
        """
        res = await self.soap.delete_employee(employee_code)
        if res["success"]:
            redis = await self._get_redis()
            if redis:
                await redis.delete(f"essl:employee_details:{employee_code}")
        return res

    # ==========================================
    # LOCATION OPERATIONS
    # ==========================================

    async def update_location(self, location_data: Dict[str, Any]) -> Dict[str, Any]:
        return await self.soap.update_location(location_data)

    async def delete_location(self, location_id: str) -> Dict[str, Any]:
        return await self.soap.delete_location(location_id)

    # ==========================================
    # DEVICE COMMANDS
    # ==========================================

    async def device_command_reboot(self, device_id: str) -> Dict[str, Any]:
        return await self.soap.device_command_reboot(device_id)

    async def device_command_clear_logs(self, device_id: str) -> Dict[str, Any]:
        return await self.soap.device_command_clear_logs(device_id)

    async def device_command_enroll_fp(self, device_id: str, employee_code: str) -> Dict[str, Any]:
        return await self.soap.device_command_enroll_fp(device_id, employee_code)

    async def device_command_enroll_face(self, device_id: str, employee_code: str) -> Dict[str, Any]:
        return await self.soap.device_command_enroll_face(device_id, employee_code)

    async def device_command_unlock_door(self, device_id: str) -> Dict[str, Any]:
        return await self.soap.device_command_unlock_door(device_id)

    async def device_command_block_unblock_user(self, device_id: str, employee_code: str, block: bool) -> Dict[str, Any]:
        return await self.soap.device_command_block_unblock_user(device_id, employee_code, block)

    async def device_command_reset_op_stamp(self, device_id: str) -> Dict[str, Any]:
        return await self.soap.device_command_reset_op_stamp(device_id)

    async def device_command_reset_transaction_stamp(self, device_id: str) -> Dict[str, Any]:
        return await self.soap.device_command_reset_transaction_stamp(device_id)

    # ==========================================
    # VISITOR
    # ==========================================

    async def validate_visitor_desk(self, visitor_data: Dict[str, Any]) -> Dict[str, Any]:
        res = await self.soap.validate_visitor_desk(visitor_data)
        if res["success"]:
            res["data"] = normalize_keys(res["data"])
        return res
