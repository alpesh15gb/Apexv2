"""Create all database tables from models."""

import asyncio
import sys
sys.path.insert(0, "/app")

from sqlalchemy import text
from app.db.session import engine, Base

# Explicitly import every model to ensure registration
from app.models.tenant import Tenant
from app.models.user import User, UserRole, user_roles
from app.models.role import Role, Permission, RolePermission, role_permissions
from app.models.audit_log import AuditLog
from app.models.employee import Department, Designation, Branch, Employee, EmployeeStatus
from app.models.device import Device, DeviceLog, DeviceStatus, DeviceType, CommunicationMode
from app.models.attendance import Attendance, PunchLog, AttendanceRawLog
from app.models.shift import Shift, ShiftSchedule
from app.models.leave import LeaveType, LeaveBalance, LeaveRequest
from app.models.visitor import Visitor, VisitorPass
from app.models.access_control import AccessZone, Door, UserAccessLevel, AccessLog
from app.models.command import DeviceCommand
from app.models.notification import Notification
from app.models.essl_server import EsslServer
from app.models.essl_sync import EsslSyncHistory, EsslSyncJob, EsslSyncError
from app.models.essl_mapping import EsslEmployeeMapping, EsslDeviceMapping
from app.models.essl_cursor import EsslSyncCursor
from app.models.essl_location import EsslLocation
from app.models.subscription import SubscriptionPlan, TenantSubscription, ResourceLimit
from app.models.feature import FeatureFlag, TenantFeature
from app.models.approval import ApprovalWorkflow, ApprovalStep, ApprovalRequest, ApprovalHistory, LoginHistory, SuperAdminLog
from app.models.announcement import Announcement, Poll, PollResponse
from app.models.benefit import Benefit, EmployeeBenefit
from app.models.category import EmployeeCategory
from app.models.department_shift import DepartmentShift
from app.models.document import Document
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


async def create_tables():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    print(f"Created {len(Base.metadata.tables)} tables")


if __name__ == "__main__":
    asyncio.run(create_tables())
