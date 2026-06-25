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
