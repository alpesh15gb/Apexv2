from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth,
    tenants,
    employees,
    devices,
    attendance,
    shifts,
    leaves,
    visitors,
    access_control,
    commands,
    notifications,
    reports,
    dashboard,
    websocket,
    essl_connector,
    essl_locations,
    holidays,
    categories,
    tenant_settings,
    shift_groups,
    shift_rosters,
    department_shifts,
    outdoor_duties,
    ot_register,
    work_codes,
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Auth"])
api_router.include_router(tenants.router, prefix="/tenants", tags=["Tenants"])
api_router.include_router(employees.router, prefix="/employees", tags=["Employees"])
api_router.include_router(devices.router, prefix="/devices", tags=["Devices"])
api_router.include_router(attendance.router, prefix="/attendance", tags=["Attendance"])
api_router.include_router(shifts.router, prefix="/shifts", tags=["Shifts"])
api_router.include_router(leaves.router, prefix="/leaves", tags=["Leaves"])
api_router.include_router(visitors.router, prefix="/visitors", tags=["Visitors"])
api_router.include_router(access_control.router, prefix="/access-control", tags=["Access Control"])
api_router.include_router(commands.router, prefix="/commands", tags=["Device Commands"])
api_router.include_router(notifications.router, prefix="/notifications", tags=["Notifications"])
api_router.include_router(reports.router, prefix="/reports", tags=["Reports"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["Dashboard"])
api_router.include_router(websocket.router, tags=["WebSockets"])
api_router.include_router(essl_connector.router, prefix="/essl", tags=["eSSL Connector"])
api_router.include_router(essl_locations.router, prefix="/essl", tags=["eSSL Locations"])
api_router.include_router(holidays.router, prefix="/holidays", tags=["Holidays"])
api_router.include_router(categories.router, prefix="/categories", tags=["Employee Categories"])
api_router.include_router(tenant_settings.router, prefix="/tenant-settings", tags=["Tenant Settings"])
api_router.include_router(shift_groups.router, prefix="/shift-groups", tags=["Shift Groups"])
api_router.include_router(shift_rosters.router, prefix="/shift-rosters", tags=["Shift Rosters"])
api_router.include_router(department_shifts.router, prefix="/department-shifts", tags=["Department Shifts"])
api_router.include_router(outdoor_duties.router, prefix="/outdoor-duties", tags=["Outdoor Duties"])
api_router.include_router(ot_register.router, prefix="/ot-register", tags=["OT Register"])
api_router.include_router(work_codes.router, prefix="/work-codes", tags=["Work Codes"])
