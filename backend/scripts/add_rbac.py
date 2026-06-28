"""Script to add RBAC enforcement to all endpoint files.

This script reads each endpoint file and adds appropriate permission checks.
"""

# Permission mapping for each module
PERMISSION_MAP = {
    # Module: (read_perm, write_perm)
    "employees": ("employee.read", "employee.create"),
    "attendance": ("attendance.read", "attendance.manage"),
    "shifts": ("shift.read", "shift.manage"),
    "shift_groups": ("shift.read", "shift.manage"),
    "shift_rosters": ("shift.read", "shift.manage"),
    "department_shifts": ("shift.read", "shift.manage"),
    "leaves": ("leave.read", "leave.approve"),
    "visitors": ("visitor.read", "visitor.manage"),
    "access_control": ("access_control.read", "access_control.manage"),
    "devices": ("device.read", "device.manage"),
    "commands": ("device.read", "device.manage"),
    "payroll": ("payroll.read", "payroll.manage"),
    "expense_benefits": ("expense.read", "expense.manage"),
    "documents": ("document.read", "document.manage"),
    "onboarding": ("onboarding.read", "onboarding.manage"),
    "exit_requests": ("exit.read", "exit.manage"),
    "timeline": ("employee.read", "employee.manage"),
    "lifecycle": ("employee.read", "employee.manage"),
    "recruitment": ("recruitment.read", "recruitment.manage"),
    "performance": ("performance.read", "performance.manage"),
    "assets": ("asset.read", "asset.manage"),
    "hr_ops": ("hr.read", "hr.manage"),
    "ess": ("ess.read", "ess.manage"),
    "reports": ("report.read", "report.read"),
    "dashboard": ("dashboard.read", "dashboard.read"),
    "holiday": ("holiday.read", "holiday.manage"),
    "categories": ("category.read", "category.manage"),
    "tenant_settings": ("settings.read", "settings.manage"),
    "work_codes": ("work_code.read", "work_code.manage"),
    "notifications": ("notification.read", "notification.manage"),
    "notification_center": ("notification.read", "notification.manage"),
    "settings_api": ("settings.read", "settings.manage"),
    "operations": ("operations.read", "operations.manage"),
    "import_export": ("import_export.read", "import_export.manage"),
    "billing": ("billing.read", "billing.manage"),
    "analytics": ("analytics.read", "analytics.read"),
    "tenants": ("tenant.read", "tenant.manage"),
    "setup": ("setup.read", "setup.manage"),
    "system": ("system.read", "system.read"),
    "websocket": ("dashboard.read", "dashboard.read"),
}

# School module permissions
SCHOOL_PERMISSION_MAP = {
    "academic_year": ("academic_year.read", "academic_year.manage"),
    "grade_section": ("class.read", "class.manage"),
    "student": ("student.read", "student.manage"),
    "student_attendance": ("student_attendance.read", "student_attendance.mark"),
    "homework": ("homework.read", "homework.create"),
    "examination": ("exam.read", "exam.manage"),
    "fee": ("fee.read", "fee.manage"),
    "school_dashboard": ("student.read", "student.read"),
    "transport": ("transport.read", "transport.manage"),
    "hostel": ("hostel.read", "hostel.manage"),
    "library": ("library.read", "library.manage"),
    "timetable": ("timetable.read", "timetable.manage"),
    "communication": ("circular.read", "circular.publish"),
    "medical": ("medical.read", "medical.manage"),
    "discipline": ("discipline.read", "discipline.manage"),
    "certificate": ("certificate.read", "certificate.issue"),
    "admission": ("admission.read", "admission.manage"),
}

print("Permission map defined. Use this to update each endpoint file.")
print(f"Total modules: {len(PERMISSION_MAP) + len(SCHOOL_PERMISSION_MAP)}")
