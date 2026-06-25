import uuid
import io
import csv
import calendar
from datetime import date, datetime, time, timezone
from typing import Any, Dict, List, Optional, Tuple, Union
from fastapi import HTTPException, status
from sqlalchemy import select, func, or_
from sqlalchemy.orm import selectinload
from sqlalchemy.ext.asyncio import AsyncSession

import openpyxl
from reportlab.lib.pagesizes import letter
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors

from app.db.session import get_db
from app.models.attendance import Attendance, AttendanceStatus
from app.models.employee import Employee, Department
from app.models.device import Device
from app.models.visitor import VisitorPass
from app.models.shift import Shift

class ReportService:
    def __init__(self, db: AsyncSession):
        self.db = db

    # Helper format dispatchers
    def _export_report(self, title: str, headers: List[str], rows: List[List[Any]], format_val: str) -> bytes:
        fmt = format_val.lower()
        if fmt == "csv":
            return self._generate_csv(headers, rows)
        elif fmt == "excel":
            return self._generate_excel(title, headers, rows)
        elif fmt == "pdf":
            return self._generate_pdf(title, headers, rows)
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unsupported report format: {format_val}"
            )

    def _generate_csv(self, headers: List[str], rows: List[List[Any]]) -> bytes:
        output = io.StringIO()
        writer = csv.writer(output)
        writer.writerow(headers)
        writer.writerows(rows)
        return output.getvalue().encode("utf-8")

    def _generate_excel(self, title: str, headers: List[str], rows: List[List[Any]]) -> bytes:
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = title[:30]

        ws.append(headers)
        for r in rows:
            # Normalize cell values for Excel writer
            ws.append([str(c) if c is not None else "" for c in r])

        output = io.BytesIO()
        wb.save(output)
        return output.getvalue()

    def _generate_pdf(self, title: str, headers: List[str], rows: List[List[Any]]) -> bytes:
        output = io.BytesIO()
        doc = SimpleDocTemplate(
            output,
            pagesize=letter,
            rightMargin=36,
            leftMargin=36,
            topMargin=36,
            bottomMargin=36
        )
        styles = getSampleStyleSheet()

        story = []

        # Title
        title_style = ParagraphStyle(
            "ReportTitle",
            parent=styles["Heading1"],
            fontSize=16,
            spaceAfter=20,
            alignment=1  # Center
        )
        story.append(Paragraph(title, title_style))
        story.append(Spacer(1, 10))

        # Styles
        cell_style = ParagraphStyle(
            "TableCell",
            parent=styles["Normal"],
            fontSize=7
        )
        header_style = ParagraphStyle(
            "TableHeader",
            parent=styles["Normal"],
            fontSize=8,
            textColor=colors.whitesmoke,
            fontName="Helvetica-Bold"
        )

        table_data = []
        table_data.append([Paragraph(h, header_style) for h in headers])

        for r in rows:
            table_data.append([Paragraph(str(cell) if cell is not None else "", cell_style) for cell in r])

        # Width distribution
        col_width = 540 / len(headers) if headers else 540
        col_widths = [col_width] * len(headers)

        t = Table(table_data, colWidths=col_widths)
        t.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2C3E50")),
            ("ALIGN", (0, 0), (-1, -1), "LEFT"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("BOTTOMPADDING", (0, 0), (-1, 0), 4),
            ("TOPPADDING", (0, 0), (-1, 0), 4),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8F9F9")])
        ]))

        story.append(t)
        doc.build(story)
        return output.getvalue()

    # REPORT GENERATORS
    async def generate_daily_attendance_report(self, tenant_id: uuid.UUID, report_date: date, format_val: str) -> bytes:
        if isinstance(report_date, str):
            report_date = date.fromisoformat(report_date)

        # Get all attendances
        stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date == report_date
        ).options(
            selectinload(Attendance.employee).selectinload(Employee.department),
            selectinload(Attendance.shift)
        )
        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Emp Code", "Employee Name", "Department", "Shift", "Punch In", "Punch Out", "Total Hours", "Status", "Late (Min)", "Early Out (Min)"]
        rows = []
        for r in records:
            name = f"{r.employee.first_name} {r.employee.last_name}" if r.employee else "N/A"
            dept = r.employee.department.name if r.employee and r.employee.department else "N/A"
            shift_name = r.shift.name if r.shift else "N/A"
            in_str = r.punch_in.strftime("%Y-%m-%d %H:%M") if r.punch_in else "N/A"
            out_str = r.punch_out.strftime("%Y-%m-%d %H:%M") if r.punch_out else "N/A"
            rows.append([
                r.employee.employee_code if r.employee else "N/A",
                name,
                dept,
                shift_name,
                in_str,
                out_str,
                round(r.total_hours, 2) if r.total_hours is not None else 0.0,
                r.status,
                r.late_minutes,
                r.early_out_minutes
            ])

        title = f"Daily Attendance Report - {report_date}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_monthly_attendance_report(self, tenant_id: uuid.UUID, month: int, year: int, format_val: str) -> bytes:
        # Determine start/end of month
        from_date = date(year, month, 1)
        to_date = date(year, month, calendar.monthrange(year, month)[1])

        stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date >= from_date,
            Attendance.date <= to_date
        ).options(
            selectinload(Attendance.employee),
            selectinload(Attendance.shift)
        ).order_by(Attendance.date.asc())

        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Date", "Emp Code", "Employee Name", "Shift", "Punch In", "Punch Out", "Total Hours", "Status"]
        rows = []
        for r in records:
            name = f"{r.employee.first_name} {r.employee.last_name}" if r.employee else "N/A"
            shift_name = r.shift.name if r.shift else "N/A"
            in_str = r.punch_in.strftime("%Y-%m-%d %H:%M") if r.punch_in else "N/A"
            out_str = r.punch_out.strftime("%Y-%m-%d %H:%M") if r.punch_out else "N/A"
            rows.append([
                r.date.strftime("%Y-%m-%d"),
                r.employee.employee_code if r.employee else "N/A",
                name,
                shift_name,
                in_str,
                out_str,
                round(r.total_hours, 2) if r.total_hours is not None else 0.0,
                r.status
            ])

        title = f"Monthly Attendance Report - {year}/{month:02d}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_employee_attendance_report(
        self,
        tenant_id: uuid.UUID,
        employee_id: uuid.UUID,
        from_date: date,
        to_date: date,
        format_val: str
    ) -> bytes:
        if isinstance(from_date, str):
            from_date = date.fromisoformat(from_date)
        if isinstance(to_date, str):
            to_date = date.fromisoformat(to_date)

        # Get employee info
        emp_stmt = select(Employee).where(Employee.id == employee_id, Employee.tenant_id == tenant_id)
        emp_res = await self.db.execute(emp_stmt)
        employee = emp_res.scalar_one_or_none()
        if not employee:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Employee not found")

        stmt = select(Attendance).where(
            Attendance.employee_id == employee_id,
            Attendance.tenant_id == tenant_id,
            Attendance.date >= from_date,
            Attendance.date <= to_date
        ).options(selectinload(Attendance.shift)).order_by(Attendance.date.asc())

        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Date", "Shift", "Punch In", "Punch Out", "Total Hours", "Status", "Late (Min)", "Early Out (Min)", "Overtime (Hrs)"]
        rows = []
        for r in records:
            shift_name = r.shift.name if r.shift else "N/A"
            in_str = r.punch_in.strftime("%Y-%m-%d %H:%M") if r.punch_in else "N/A"
            out_str = r.punch_out.strftime("%Y-%m-%d %H:%M") if r.punch_out else "N/A"
            rows.append([
                r.date.strftime("%Y-%m-%d"),
                shift_name,
                in_str,
                out_str,
                round(r.total_hours, 2) if r.total_hours is not None else 0.0,
                r.status,
                r.late_minutes,
                r.early_out_minutes,
                round(r.overtime_hours, 2) if r.overtime_hours is not None else 0.0
            ])

        title = f"Attendance Report: {employee.first_name} {employee.last_name} ({employee.employee_code})"
        return self._export_report(title, headers, rows, format_val)

    async def generate_late_report(self, tenant_id: uuid.UUID, from_date: date, to_date: date, format_val: str) -> bytes:
        if isinstance(from_date, str):
            from_date = date.fromisoformat(from_date)
        if isinstance(to_date, str):
            to_date = date.fromisoformat(to_date)

        stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date >= from_date,
            Attendance.date <= to_date,
            Attendance.is_late == True
        ).options(
            selectinload(Attendance.employee),
            selectinload(Attendance.shift)
        ).order_by(Attendance.date.asc())

        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Date", "Emp Code", "Employee Name", "Shift", "Punch In", "Shift Start", "Late Minutes"]
        rows = []
        for r in records:
            name = f"{r.employee.first_name} {r.employee.last_name}" if r.employee else "N/A"
            shift_name = r.shift.name if r.shift else "N/A"
            in_str = r.punch_in.strftime("%Y-%m-%d %H:%M") if r.punch_in else "N/A"
            start_str = r.shift.start_time.strftime("%H:%M") if r.shift else "N/A"
            rows.append([
                r.date.strftime("%Y-%m-%d"),
                r.employee.employee_code if r.employee else "N/A",
                name,
                shift_name,
                in_str,
                start_str,
                r.late_minutes
            ])

        title = f"Late Arrivals Report: {from_date} to {to_date}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_overtime_report(self, tenant_id: uuid.UUID, from_date: date, to_date: date, format_val: str) -> bytes:
        if isinstance(from_date, str):
            from_date = date.fromisoformat(from_date)
        if isinstance(to_date, str):
            to_date = date.fromisoformat(to_date)

        stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date >= from_date,
            Attendance.date <= to_date,
            Attendance.overtime_hours > 0.0
        ).options(
            selectinload(Attendance.employee),
            selectinload(Attendance.shift)
        ).order_by(Attendance.date.asc())

        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Date", "Emp Code", "Employee Name", "Shift", "Punch Out", "Shift End", "Overtime (Hrs)"]
        rows = []
        for r in records:
            name = f"{r.employee.first_name} {r.employee.last_name}" if r.employee else "N/A"
            shift_name = r.shift.name if r.shift else "N/A"
            out_str = r.punch_out.strftime("%Y-%m-%d %H:%M") if r.punch_out else "N/A"
            end_str = r.shift.end_time.strftime("%H:%M") if r.shift else "N/A"
            rows.append([
                r.date.strftime("%Y-%m-%d"),
                r.employee.employee_code if r.employee else "N/A",
                name,
                shift_name,
                out_str,
                end_str,
                round(r.overtime_hours, 2)
            ])

        title = f"Overtime Report: {from_date} to {to_date}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_absent_report(self, tenant_id: uuid.UUID, report_date: date, format_val: str) -> bytes:
        if isinstance(report_date, str):
            report_date = date.fromisoformat(report_date)

        # Get all active employees
        emp_stmt = select(Employee).where(
            Employee.tenant_id == tenant_id,
            Employee.status == "active"
        ).options(selectinload(Employee.department))
        employees = (await self.db.execute(emp_stmt)).scalars().all()

        # Get attendance records for this date
        att_stmt = select(Attendance).where(
            Attendance.tenant_id == tenant_id,
            Attendance.date == report_date
        )
        attendances = {a.employee_id: a for a in (await self.db.execute(att_stmt)).scalars().all()}

        headers = ["Emp Code", "Employee Name", "Department", "Remarks"]
        rows = []
        for emp in employees:
            att = attendances.get(emp.id)
            if not att or att.status == AttendanceStatus.ABSENT.value:
                remarks = att.remarks if (att and att.remarks) else "No attendance marked"
                rows.append([
                    emp.employee_code,
                    f"{emp.first_name} {emp.last_name}",
                    emp.department.name if emp.department else "N/A",
                    remarks
                ])

        title = f"Absent Report - {report_date}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_visitor_report(self, tenant_id: uuid.UUID, from_date: date, to_date: date, format_val: str) -> bytes:
        if isinstance(from_date, str):
            from_date = date.fromisoformat(from_date)
        if isinstance(to_date, str):
            to_date = date.fromisoformat(to_date)

        stmt = select(VisitorPass).where(
            VisitorPass.tenant_id == tenant_id,
            VisitorPass.expected_date >= from_date,
            VisitorPass.expected_date <= to_date
        ).options(
            selectinload(VisitorPass.visitor),
            selectinload(VisitorPass.host_employee)
        ).order_by(VisitorPass.expected_date.asc())

        res = await self.db.execute(stmt)
        records = res.scalars().all()

        headers = ["Pass No", "Visitor Name", "Company", "Host Employee", "Purpose", "Expected Date", "Check In", "Check Out", "Status"]
        rows = []
        for r in records:
            visitor_name = r.visitor.name if r.visitor else "N/A"
            company = r.visitor.company if r.visitor else "N/A"
            host_name = f"{r.host_employee.first_name} {r.host_employee.last_name}" if r.host_employee else "N/A"
            in_str = r.check_in_time.strftime("%Y-%m-%d %H:%M") if r.check_in_time else "N/A"
            out_str = r.check_out_time.strftime("%Y-%m-%d %H:%M") if r.check_out_time else "N/A"
            rows.append([
                r.pass_number,
                visitor_name,
                company,
                host_name,
                r.purpose,
                r.expected_date.strftime("%Y-%m-%d"),
                in_str,
                out_str,
                r.status
            ])

        title = f"Visitor Report: {from_date} to {to_date}"
        return self._export_report(title, headers, rows, format_val)

    async def generate_device_status_report(self, tenant_id: uuid.UUID, format_val: str) -> bytes:
        stmt = select(Device).where(Device.tenant_id == tenant_id).order_by(Device.device_name.asc())
        res = await self.db.execute(stmt)
        devices = res.scalars().all()

        headers = ["Serial Number", "Device Name", "Model", "IP Address", "Location", "Last Ping", "Status"]
        rows = []
        for d in devices:
            ping_str = d.last_ping.strftime("%Y-%m-%d %H:%M") if d.last_ping else "N/A"
            rows.append([
                d.serial_number,
                d.device_name,
                d.model or "N/A",
                d.ip_address or "N/A",
                d.location or "N/A",
                ping_str,
                d.status
            ])

        title = "Device Status Report"
        return self._export_report(title, headers, rows, format_val)
