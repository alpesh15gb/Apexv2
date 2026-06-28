"""Models initialization file exposing all SQLAlchemy models."""

from app.models.tenant import Tenant
from app.models.user import User, UserRole, user_roles
from app.models.role import Role, Permission, RolePermission, role_permissions
from app.models.audit_log import AuditLog
from app.models.employee import Department, Designation, Branch, Employee, EmployeeStatus
from app.models.device import Device, DeviceLog, DeviceStatus, DeviceType, CommunicationMode
from app.models.attendance import Attendance, PunchLog, AttendanceStatus, PunchType, PunchSource
from app.models.shift import Shift, ShiftSchedule
from app.models.leave import LeaveType, LeaveBalance, LeaveRequest, LeaveRequestStatus
from app.models.visitor import Visitor, VisitorPass, VisitorPassStatus
from app.models.access_control import AccessZone, Door, UserAccessLevel, AccessLog
from app.models.command import DeviceCommand, CommandType, CommandStatus
from app.models.notification import Notification, NotificationType, NotificationStatus
from app.models.essl_server import EsslServer, EsslServerStatus, ConflictPolicy
from app.models.essl_sync import EsslSyncHistory, EsslSyncJob, EsslSyncError, SyncStatus, SyncType
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.essl_cursor import EsslSyncCursor
from app.models.attendance import AttendanceRawLog
from app.models.subscription import SubscriptionPlan, TenantSubscription, ResourceLimit
from app.models.feature import FeatureFlag, TenantFeature
from app.models.approval import ApprovalWorkflow, ApprovalStep, ApprovalRequest, ApprovalHistory, LoginHistory, SuperAdminLog
from app.models.announcement import Announcement, Poll, PollResponse
from app.models.benefit import Benefit, EmployeeBenefit
from app.models.category import EmployeeCategory
from app.models.department_shift import DepartmentShift
from app.models.document import Document
from app.models.essl_location import EsslLocation
from app.models.exit import ExitRequest
from app.models.expense import ExpenseCategory, ExpenseClaim
from app.models.holiday import Holiday
from app.models.notification_template import NotificationTemplate
from app.models.onboarding import OnboardingTask
from app.models.ot_register import OTRegister
from app.models.outdoor_duty import OutdoorDuty
from app.models.payroll import SalaryStructure, PaySlip, Loan
from app.models.performance import ReviewCycle, Goal, PerformanceReview, Competency, PerformanceRecommendation
from app.models.recruitment import JobRequisition, JobOpening, Candidate, Interview, Offer
from app.models.shift_group import ShiftGroup, ShiftGroupMember
from app.models.shift_roster import ShiftRoster, ShiftRosterEntry
from app.models.tax import TaxDeclaration
from app.models.tenant_settings import TenantSettings
from app.models.timeline import EmployeeEvent
from app.models.work_code import WorkCode
from app.models.asset_travel import CompanyAsset, TravelRequest

# School ERP models
from app.models.school import (
    AcademicYear, AcademicTerm, SchoolHoliday,
    Campus, Building, Room,
    Grade, Section, House,
    Student, Guardian, StudentGuardian, StudentSibling,
    Subject, GradeSubject, TeacherAllocation,
    PeriodDefinition, TimetableEntry, Substitution,
    StudentAttendance, StudentAttendanceSummary,
    Homework, HomeworkSubmission, Assignment, AssignmentSubmission,
    ExamType, Exam, ExamSchedule, ExamMark, GradingScale, GradingScaleDetail,
    FeeCategory, FeeStructure, StudentFee, FeePayment, FeeFineRule, Scholarship, StudentScholarship,
    TransportRoute, TransportStop, StudentTransport,
    Hostel, HostelRoom, HostelAllocation,
    LibraryBook, LibraryTransaction,
    LessonPlan,
    SchoolEvent, Circular,
    HealthRecord, DisciplineIncident,
    CertificateTemplate, IssuedCertificate,
    AdmissionInquiry, AdmissionApplication,
)

__all__ = [
    "Tenant",
    "User",
    "UserRole",
    "user_roles",
    "Role",
    "Permission",
    "RolePermission",
    "role_permissions",
    "AuditLog",
    "Department",
    "Designation",
    "Branch",
    "Employee",
    "EmployeeStatus",
    "Device",
    "DeviceLog",
    "DeviceStatus",
    "DeviceType",
    "CommunicationMode",
    "Attendance",
    "PunchLog",
    "AttendanceStatus",
    "PunchType",
    "PunchSource",
    "Shift",
    "ShiftSchedule",
    "LeaveType",
    "LeaveBalance",
    "LeaveRequest",
    "LeaveRequestStatus",
    "Visitor",
    "VisitorPass",
    "VisitorPassStatus",
    "AccessZone",
    "Door",
    "UserAccessLevel",
    "AccessLog",
    "DeviceCommand",
    "CommandType",
    "CommandStatus",
    "Notification",
    "NotificationType",
    "NotificationStatus",
    "EsslServer",
    "EsslServerStatus",
    "ConflictPolicy",
    "EsslSyncHistory",
    "EsslSyncJob",
    "EsslSyncError",
    "SyncStatus",
    "SyncType",
    "EsslEmployeeMapping",
    "EsslDeviceMapping",
    "EsslSyncCursor",
    "AttendanceRawLog",
    "SubscriptionPlan",
    "TenantSubscription",
    "ResourceLimit",
    "FeatureFlag",
    "TenantFeature",
    "ApprovalWorkflow",
    "ApprovalStep",
    "ApprovalRequest",
    "ApprovalHistory",
    "LoginHistory",
    "SuperAdminLog",
    "Announcement",
    "Poll",
    "PollResponse",
    "Benefit",
    "EmployeeBenefit",
    "EmployeeCategory",
    "DepartmentShift",
    "Document",
    "EsslLocation",
    "ExitRequest",
    "ExpenseCategory",
    "ExpenseClaim",
    "Holiday",
    "NotificationTemplate",
    "OnboardingTask",
    "OTRegister",
    "OutdoorDuty",
    "SalaryStructure",
    "PaySlip",
    "Loan",
    "ReviewCycle",
    "Goal",
    "PerformanceReview",
    "Competency",
    "PerformanceRecommendation",
    "JobRequisition",
    "JobOpening",
    "Candidate",
    "Interview",
    "Offer",
    "ShiftGroup",
    "ShiftGroupMember",
    "ShiftRoster",
    "ShiftRosterEntry",
    "TaxDeclaration",
    "TenantSettings",
    "EmployeeEvent",
    "WorkCode",
    "CompanyAsset",
    "TravelRequest",
    # School ERP
    "AcademicYear", "AcademicTerm", "SchoolHoliday",
    "Campus", "Building", "Room",
    "Grade", "Section", "House",
    "Student", "Guardian", "StudentGuardian", "StudentSibling",
    "Subject", "GradeSubject", "TeacherAllocation",
    "PeriodDefinition", "TimetableEntry", "Substitution",
    "StudentAttendance", "StudentAttendanceSummary",
    "Homework", "HomeworkSubmission", "Assignment", "AssignmentSubmission",
    "ExamType", "Exam", "ExamSchedule", "ExamMark", "GradingScale", "GradingScaleDetail",
    "FeeCategory", "FeeStructure", "StudentFee", "FeePayment", "FeeFineRule", "Scholarship", "StudentScholarship",
    "TransportRoute", "TransportStop", "StudentTransport",
    "Hostel", "HostelRoom", "HostelAllocation",
    "LibraryBook", "LibraryTransaction",
    "LessonPlan",
    "SchoolEvent", "Circular",
    "HealthRecord", "DisciplineIncident",
    "CertificateTemplate", "IssuedCertificate",
    "AdmissionInquiry", "AdmissionApplication",
]
