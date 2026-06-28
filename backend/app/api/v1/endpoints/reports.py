"""Report API endpoints - generates PDF/Excel/CSV reports."""

import uuid
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.deps import get_db, get_current_active_user, require_feature
from app.models.user import User
from app.services.report import ReportService

router = APIRouter(dependencies=[Depends(require_feature("reports"))])


def _file_response(content: bytes, filename: str, fmt: str) -> StreamingResponse:
    content_types = {
        "pdf": "application/pdf",
        "excel": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        "csv": "text/csv",
    }
    return StreamingResponse(
        iter([content]),
        media_type=content_types.get(fmt, "application/octet-stream"),
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


@router.get("/attendance/daily")
async def daily_attendance_report(
    date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_daily_attendance_report(current_user.tenant_id, date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"daily_attendance_{date}.{ext}", format)


@router.get("/attendance/monthly")
async def monthly_attendance_report(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_monthly_attendance_report(current_user.tenant_id, month, year, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"monthly_attendance_{year}_{month:02d}.{ext}", format)


@router.get("/attendance/employee/{employee_id}")
async def employee_attendance_report(
    employee_id: uuid.UUID,
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_employee_attendance_report(
        current_user.tenant_id, employee_id, from_date, to_date, format
    )
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"employee_attendance_{employee_id}.{ext}", format)


@router.get("/attendance/late")
async def late_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_late_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"late_report_{from_date}_{to_date}.{ext}", format)


@router.get("/attendance/overtime")
async def overtime_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_overtime_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"overtime_report_{from_date}_{to_date}.{ext}", format)


@router.get("/attendance/absent")
async def absent_report(
    date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_absent_report(current_user.tenant_id, date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"absent_report_{date}.{ext}", format)


@router.get("/visitors")
async def visitor_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_visitor_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"visitor_report_{from_date}_{to_date}.{ext}", format)


@router.get("/devices")
async def device_status_report(
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_device_status_report(current_user.tenant_id, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"device_status_report.{ext}", format)


@router.get("/attendance/early-going")
async def early_going_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_early_going_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"early_going_report_{from_date}_{to_date}.{ext}", format)


@router.get("/attendance/missed-punch")
async def missed_punch_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_missed_punch_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"missed_punch_report_{from_date}_{to_date}.{ext}", format)


@router.get("/attendance/department-summary")
async def department_summary_report(
    from_date: date = Query(...),
    to_date: date = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_department_summary_report(current_user.tenant_id, from_date, to_date, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"dept_summary_{from_date}_{to_date}.{ext}", format)


@router.get("/attendance/ot-summary")
async def ot_summary_report(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_ot_summary_report(current_user.tenant_id, month, year, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"ot_summary_{year}_{month:02d}.{ext}", format)


@router.get("/attendance/muster-roll")
async def muster_roll_report(
    month: int = Query(..., ge=1, le=12),
    year: int = Query(...),
    format: str = Query("pdf", regex="^(pdf|excel|csv)$"),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    service = ReportService(db)
    content = await service.generate_muster_roll_report(current_user.tenant_id, month, year, format)
    ext = {"pdf": "pdf", "excel": "xlsx", "csv": "csv"}[format]
    return _file_response(content, f"muster_roll_{year}_{month:02d}.{ext}", format)


@router.post("/attendance/recalculate")
async def recalculate_attendance(
    from_date: date = Query(...),
    to_date: date = Query(...),
    department_id: uuid.UUID = Query(None),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    from app.services.attendance_processor import AttendanceProcessor
    processor = AttendanceProcessor(db)
    result = await processor.reprocess(
        tenant_id=current_user.tenant_id,
        from_date=from_date,
        to_date=to_date,
        department_id=department_id,
    )
    return result
