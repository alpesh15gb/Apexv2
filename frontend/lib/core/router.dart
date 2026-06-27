import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/employees/employee_list_screen.dart';
import '../screens/employees/employee_detail_screen.dart';
import '../screens/employees/employee_create_screen.dart';
import '../screens/employees/department_screen.dart';
import '../screens/employees/branch_screen.dart';
import '../screens/employees/designation_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../screens/devices/device_detail_screen.dart';
import '../screens/devices/device_health_screen.dart';
import '../screens/attendance/attendance_list_screen.dart';
import '../screens/attendance/attendance_detail_screen.dart';
import '../screens/attendance/daily_summary_screen.dart';
import '../screens/attendance/mark_attendance_screen.dart';
import '../screens/shifts/shift_list_screen.dart';
import '../screens/shifts/shift_create_screen.dart';
import '../screens/shifts/shift_assign_screen.dart';
import '../screens/leaves/leave_balance_screen.dart';
import '../screens/leaves/leave_apply_screen.dart';
import '../screens/leaves/leave_requests_screen.dart';
import '../screens/visitors/visitor_list_screen.dart';
import '../screens/visitors/visitor_register_screen.dart';
import '../screens/visitors/visitor_pass_screen.dart';
import '../screens/visitors/active_visitors_screen.dart';
import '../screens/access_control/zone_list_screen.dart';
import '../screens/access_control/door_list_screen.dart';
import '../screens/access_control/access_logs_screen.dart';
import '../screens/commands/command_center_screen.dart';
import '../screens/notifications/notification_list_screen.dart';
import '../screens/reports/report_selection_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/settings/essl_server_list_screen.dart';
import '../screens/settings/essl_server_form_screen.dart';
import '../screens/settings/essl_sync_history_screen.dart';
import '../screens/settings/essl_initial_sync_screen.dart';
import '../screens/settings/essl_dashboard_screen.dart';
import '../screens/settings/essl_reprocess_screen.dart';
import '../screens/settings/essl_locations_screen.dart';
import '../screens/holidays/holiday_calendar_screen.dart';
import '../screens/settings/category_screen.dart';
import '../screens/settings/tenant_settings_screen.dart';
import '../screens/finance/expense_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_tenant_list_screen.dart';
import '../screens/admin/admin_tenant_detail_screen.dart';
import '../screens/admin/admin_plan_screen.dart';
import '../screens/admin/admin_feature_screen.dart';
import '../screens/admin/admin_analytics_screen.dart';
import '../screens/ess/ess_dashboard_screen.dart';
import '../screens/ess/ess_attendance_screen.dart';
import '../screens/ess/ess_leave_screen.dart';
import '../screens/ess/ess_profile_screen.dart';
import '../screens/setup/setup_wizard_screen.dart';
import '../screens/employees/employee_directory_screen.dart';
import '../screens/employees/employee_create_wizard.dart';
import '../screens/attendance/attendance_dashboard_screen.dart';
import '../screens/attendance/regularization_screen.dart';
import '../screens/shifts/shift_management_screen.dart';
import '../screens/ess/ess_attendance_calendar_screen.dart';
import '../screens/leaves/leave_dashboard_screen.dart';
import '../screens/leaves/leave_types_screen.dart';
import '../screens/leaves/leave_calendar_screen.dart';
import '../screens/payroll/payroll_dashboard_screen.dart';
import '../screens/payroll/salary_structures_screen.dart';
import '../screens/payroll/loans_screen.dart';
import '../screens/recruitment/recruitment_dashboard_screen.dart';
import '../screens/recruitment/candidates_screen.dart';
import '../screens/recruitment/interviews_screen.dart';
import '../screens/performance/performance_dashboard_screen.dart';
import '../screens/performance/goals_screen.dart';
import '../screens/assets/asset_dashboard_screen.dart';
import '../screens/system/notification_center_screen.dart';
import '../screens/system/settings_screen.dart';
import '../screens/system/health_screen.dart';
import '../screens/shifts/shift_group_screen.dart';
import '../screens/shifts/shift_roster_screen.dart';
import '../screens/shifts/department_shift_screen.dart';
import '../screens/attendance/outdoor_duty_screen.dart';
import '../screens/attendance/ot_register_screen.dart';
import '../screens/settings/work_code_screen.dart';
import '../screens/payroll/payroll_screen.dart';
import '../screens/hr/document_screen.dart';
import '../screens/hr/exit_request_screen.dart';
import '../screens/hr/asset_screen.dart';
import '../screens/hr/travel_screen.dart';
import '../screens/hr/announcement_screen.dart';
import 'secure_storage.dart';
import 'constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final token = await secureStorage.read(StorageKeys.accessToken);
      final loggedIn = token != null && token.isNotEmpty;
      
      final goingToSplash = state.matchedLocation == '/splash';
      final goingToLogin = state.matchedLocation == '/login';
      final goingToRegister = state.matchedLocation == '/register';
      final goingToAdmin = state.matchedLocation.startsWith('/admin');

      if (!loggedIn && !goingToLogin && !goingToRegister && !goingToSplash && !goingToAdmin) {
        return '/login';
      }

      if (loggedIn && (goingToLogin || goingToRegister || goingToSplash)) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      // Setup Wizard
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      // Super Admin routes
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/tenants',
        builder: (context, state) => const AdminTenantListScreen(),
      ),
      GoRoute(
        path: '/admin/tenants/:tenantId',
        builder: (context, state) => AdminTenantDetailScreen(tenantId: state.pathParameters['tenantId']!),
      ),
      GoRoute(
        path: '/admin/plans',
        builder: (context, state) => const AdminPlanScreen(),
      ),
      GoRoute(
        path: '/admin/features',
        builder: (context, state) => const AdminFeatureScreen(),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const AdminAnalyticsScreen(),
      ),
      // ESS routes
      GoRoute(
        path: '/ess/dashboard',
        builder: (context, state) => const EssDashboardScreen(),
      ),
      GoRoute(
        path: '/ess/attendance',
        builder: (context, state) => const EssAttendanceCalendarScreen(),
      ),
          GoRoute(
            path: '/leaves',
            builder: (context, state) => const LeaveDashboardScreen(),
          ),
          GoRoute(
            path: '/leaves/types',
            builder: (context, state) => const LeaveTypesScreen(),
          ),
          GoRoute(
            path: '/leaves/calendar',
            builder: (context, state) => const LeaveCalendarScreen(),
          ),
      GoRoute(
        path: '/ess/profile',
        builder: (context, state) => const EssProfileScreen(),
      ),
      GoRoute(
        path: '/ess/payslips',
        builder: (context, state) => const EssPayslipScreen(),
      ),
      GoRoute(
        path: '/ess/documents',
        builder: (context, state) => const EssDocumentScreen(),
      ),
      GoRoute(
        path: '/ess/notifications',
        builder: (context, state) => const EssNotificationScreen(),
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/payroll',
            builder: (context, state) => const PayrollDashboardScreen(),
          ),
          GoRoute(
            path: '/payroll/salary-structures',
            builder: (context, state) => const SalaryStructuresScreen(),
          ),
          GoRoute(
            path: '/payroll/loans',
            builder: (context, state) => const LoansScreen(),
          ),
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeDirectoryScreen(),
          ),
          GoRoute(
            path: '/employees/create',
            builder: (context, state) => const EmployeeCreateWizard(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceDashboardScreen(),
          ),
          GoRoute(
            path: '/attendance/regularization',
            builder: (context, state) => const AttendanceRegularizationScreen(),
          ),
          GoRoute(
            path: '/shifts',
            builder: (context, state) => const ShiftManagementScreen(),
          ),
        ],
      ),
      // Employees sub-routes
      GoRoute(
        path: '/employees/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EmployeeCreateScreen(),
      ),
      GoRoute(
        path: '/employees/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeDetailScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/departments',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DepartmentScreen(),
      ),
      GoRoute(
        path: '/branches',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const BranchScreen(),
      ),
      GoRoute(
        path: '/designations',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DesignationScreen(),
      ),
      // Holiday routes
      GoRoute(
        path: '/holidays',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HolidayCalendarScreen(),
      ),
      // Devices routes
      GoRoute(
        path: '/devices',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DeviceListScreen(),
      ),
      GoRoute(
        path: '/devices/health',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DeviceHealthScreen(),
      ),
      GoRoute(
        path: '/devices/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DeviceDetailScreen(deviceId: id);
        },
      ),
      // Attendance sub-routes
      GoRoute(
        path: '/attendance/detail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final employeeId = state.uri.queryParameters['employeeId']!;
          return AttendanceDetailScreen(employeeId: employeeId);
        },
      ),
      GoRoute(
        path: '/attendance/summary',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DailySummaryScreen(),
      ),
      GoRoute(
        path: '/attendance/mark',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MarkAttendanceScreen(),
      ),
      // Shifts routes
      GoRoute(
        path: '/shifts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShiftListScreen(),
      ),
      GoRoute(
        path: '/shifts/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShiftCreateScreen(),
      ),
      GoRoute(
        path: '/shifts/assign',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShiftAssignScreen(),
      ),
      // Leaves routes
      GoRoute(
        path: '/leaves',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LeaveRequestsScreen(),
      ),
      GoRoute(
        path: '/leaves/balance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LeaveBalanceScreen(),
      ),
      GoRoute(
        path: '/leaves/apply',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LeaveApplyScreen(),
      ),
      GoRoute(
        path: '/leaves/requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const LeaveRequestsScreen(),
      ),
      // Visitors routes
      GoRoute(
        path: '/visitors',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VisitorListScreen(),
      ),
      GoRoute(
        path: '/visitors/register',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const VisitorRegisterScreen(),
      ),
      GoRoute(
        path: '/visitors/pass',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final passId = state.uri.queryParameters['passId']!;
          return VisitorPassScreen(passId: passId);
        },
      ),
      GoRoute(
        path: '/visitors/active',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ActiveVisitorsScreen(),
      ),
      // Access Control routes
      GoRoute(
        path: '/access/zones',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ZoneListScreen(),
      ),
      GoRoute(
        path: '/access/doors',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DoorListScreen(),
      ),
      GoRoute(
        path: '/access/logs',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccessLogsScreen(),
      ),
      // Command Center routes
      GoRoute(
        path: '/commands',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CommandCenterScreen(),
      ),
      // Notifications routes
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationListScreen(),
      ),
      // Recruitment routes
      GoRoute(
        path: '/recruitment',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const RecruitmentDashboardScreen(),
      ),
      GoRoute(
        path: '/recruitment/candidates',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CandidatesScreen(),
      ),
      GoRoute(
        path: '/recruitment/interviews',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const InterviewsScreen(),
      ),
      // Performance routes
      GoRoute(
        path: '/performance',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PerformanceDashboardScreen(),
      ),
      GoRoute(
        path: '/performance/goals',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const GoalsScreen(),
      ),
      // Asset routes
      GoRoute(
        path: '/assets',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AssetDashboardScreen(),
      ),
      // System routes
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SystemSettingsScreen(),
      ),
      GoRoute(
        path: '/health',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const HealthDashboardScreen(),
      ),
      // Reports routes
      GoRoute(
        path: '/reports',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportSelectionScreen(),
      ),
      // Finance routes
      GoRoute(
        path: '/expenses',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExpenseScreen(),
      ),
      // eSSL Connector routes
      GoRoute(
        path: '/settings/essl',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EsslServerListScreen(),
      ),
      GoRoute(
        path: '/settings/essl/create',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EsslServerFormScreen(),
      ),
      GoRoute(
        path: '/settings/essl/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EsslServerFormScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/settings/essl/:id/history',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EsslSyncHistoryScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/settings/essl/:id/locations',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EsslLocationsScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/settings/essl/:id/initial-sync',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EsslInitialSyncScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/settings/essl/:id/reprocess',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EsslReprocessScreen(serverId: id);
        },
      ),
      GoRoute(
        path: '/settings/categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoryScreen(),
      ),
      GoRoute(
        path: '/settings/tenant-settings',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TenantSettingsScreen(),
      ),
      GoRoute(
        path: '/shift-groups',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShiftGroupScreen(),
      ),
      GoRoute(
        path: '/shift-rosters',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ShiftRosterScreen(),
      ),
      GoRoute(
        path: '/department-shifts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DepartmentShiftScreen(),
      ),
      GoRoute(
        path: '/attendance/ot',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OTRegisterScreen(),
      ),
      GoRoute(
        path: '/attendance/outdoor-duty',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OutdoorDutyScreen(),
      ),
      GoRoute(
        path: '/settings/work-codes',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WorkCodeScreen(),
      ),
      GoRoute(
        path: '/payroll',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PayrollScreen(),
      ),
      GoRoute(
        path: '/documents',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const DocumentScreen(),
      ),
      GoRoute(
        path: '/exit-requests',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ExitRequestScreen(),
      ),
      GoRoute(
        path: '/assets',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AssetScreen(),
      ),
      GoRoute(
        path: '/travel',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const TravelScreen(),
      ),
      GoRoute(
        path: '/announcements',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AnnouncementScreen(),
      ),
      GoRoute(
        path: '/settings/essl/dashboard',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EsslDashboardScreen(),
      ),
    ],
  );
});
