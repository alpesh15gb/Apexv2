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
    payroll,
    documents,
    onboarding,
    exit_requests,
    timeline,
    expense_benefits,
    hr_ops,
    ess,
    setup,
    lifecycle,
    recruitment,
    performance,
    assets,
    notification_center,
    settings_api,
    system,
    billing,
    analytics,
    import_export,
    operations,
)
from app.api.v1.endpoints.admin import auth as admin_auth, dashboard as admin_dashboard, tenants as admin_tenants, plans as admin_plans, features as admin_features
from app.api.v1.endpoints.school import (
    academic_year as school_academic_year,
    grade_section as school_grade_section,
    student as school_student,
    student_attendance as school_student_attendance,
    homework as school_homework,
    examination as school_examination,
    fee as school_fee,
    school_dashboard as school_dashboard_ep,
    transport as school_transport,
    hostel as school_hostel,
    library as school_library,
    timetable as school_timetable,
    communication as school_communication,
    medical as school_medical,
    certificate as school_certificate,
    admission as school_admission,
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
api_router.include_router(payroll.router, prefix="/payroll", tags=["Payroll"])
api_router.include_router(documents.router, prefix="/documents", tags=["Documents"])
api_router.include_router(onboarding.router, prefix="/onboarding", tags=["Onboarding"])
api_router.include_router(exit_requests.router, prefix="/exit-requests", tags=["Exit Requests"])
api_router.include_router(timeline.router, prefix="/timeline", tags=["Employee Timeline"])
api_router.include_router(expense_benefits.router, prefix="/finance", tags=["Expense & Benefits"])
api_router.include_router(hr_ops.router, prefix="/hr", tags=["HR Operations"])
api_router.include_router(ess.router, prefix="/ess", tags=["Employee Self Service"])
api_router.include_router(admin_auth.router, prefix="/admin/auth", tags=["Super Admin Auth"])
api_router.include_router(admin_dashboard.router, prefix="/admin/dashboard", tags=["Super Admin Dashboard"])
api_router.include_router(admin_tenants.router, prefix="/admin/tenants", tags=["Super Admin Tenants"])
api_router.include_router(admin_plans.router, prefix="/admin/plans", tags=["Super Admin Plans"])
api_router.include_router(admin_features.router, prefix="/admin/features", tags=["Super Admin Features"])
api_router.include_router(setup.router, prefix="/setup", tags=["Setup Wizard"])
api_router.include_router(lifecycle.router, prefix="/employees", tags=["Employee Lifecycle"])
api_router.include_router(recruitment.router, prefix="/recruitment", tags=["Recruitment"])
api_router.include_router(performance.router, prefix="/performance", tags=["Performance"])
api_router.include_router(assets.router, prefix="/assets", tags=["Assets"])
api_router.include_router(notification_center.router, prefix="/notifications", tags=["Notification Center"])
api_router.include_router(settings_api.router, prefix="/settings", tags=["System Settings"])
api_router.include_router(system.router, prefix="/system", tags=["System Health"])
api_router.include_router(billing.router, prefix="/admin/billing", tags=["Billing"])
api_router.include_router(analytics.router, prefix="/admin/analytics", tags=["Analytics"])
api_router.include_router(import_export.router, prefix="/data", tags=["Import/Export"])
api_router.include_router(operations.router, prefix="/ops", tags=["Operations"])
# School ERP routes
api_router.include_router(school_academic_year.router, prefix="/school/academic-years", tags=["School Academic Years"])
api_router.include_router(school_grade_section.router, prefix="/school", tags=["School Grades & Sections"])
api_router.include_router(school_grade_section.subjects_router, prefix="/school", tags=["School Subjects"])
api_router.include_router(school_grade_section.alloc_router, prefix="/school", tags=["School Teacher Allocation"])
api_router.include_router(school_student.router, prefix="/school/students", tags=["School Students"])
api_router.include_router(school_student_attendance.router, prefix="/school/student-attendance", tags=["School Student Attendance"])
api_router.include_router(school_homework.router, prefix="/school/homework", tags=["School Homework"])
api_router.include_router(school_examination.router, prefix="/school", tags=["School Examinations"])
api_router.include_router(school_fee.router, prefix="/school/fees", tags=["School Fees"])
api_router.include_router(school_dashboard_ep.router, prefix="/school/dashboard", tags=["School Dashboard"])
api_router.include_router(school_transport.router, prefix="/school/transport", tags=["School Transport"])
api_router.include_router(school_hostel.router, prefix="/school/hostel", tags=["School Hostel"])
api_router.include_router(school_library.router, prefix="/school/library", tags=["School Library"])
api_router.include_router(school_timetable.router, prefix="/school/timetable", tags=["School Timetable"])
api_router.include_router(school_communication.circular_router, prefix="/school/circulars", tags=["School Circulars"])
api_router.include_router(school_communication.event_router, prefix="/school/events", tags=["School Events"])
api_router.include_router(school_medical.medical_router, prefix="/school/health", tags=["School Medical"])
api_router.include_router(school_medical.discipline_router, prefix="/school/discipline", tags=["School Discipline"])
api_router.include_router(school_certificate.router, prefix="/school/certificates", tags=["School Certificates"])
api_router.include_router(school_admission.router, prefix="/school/admissions", tags=["School Admissions"])
