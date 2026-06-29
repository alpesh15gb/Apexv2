import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/colors.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/phase_screen.dart';
import '../screens/employees/employee_timeline_screen.dart';
import '../screens/employees/locations_screen.dart';
import '../screens/employees/employment_types_screen.dart';
import '../screens/attendance/live_attendance_screen.dart';
import '../screens/attendance/attendance_approvals_screen.dart';
import '../screens/attendance/weekly_off_screen.dart';
import '../screens/attendance/holiday_groups_screen.dart';
import '../screens/attendance/leave_policies_screen.dart';
import '../screens/attendance/comp_off_screen.dart';
import '../screens/attendance/missed_punch_screen.dart';
import '../screens/attendance/attendance_policies_screen.dart';
import '../screens/attendance/grace_time_screen.dart';
import '../screens/attendance/overtime_rules_screen.dart';
import '../screens/attendance/auto_shift_screen.dart';
import '../screens/attendance/geofencing_screen.dart';
import '../screens/attendance/biometric_settings_screen.dart';

import '../screens/employees/employee_detail_screen.dart';
import '../screens/employees/employee_create_screen.dart';
import '../screens/employees/employee_edit_screen.dart';
import '../screens/employees/department_screen.dart';
import '../screens/employees/branch_screen.dart';
import '../screens/employees/designation_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../screens/devices/device_detail_screen.dart';
import '../screens/devices/device_health_screen.dart';
import '../screens/devices/add_device_screen.dart';
import '../screens/devices/device_groups_screen.dart';
import '../screens/devices/branch_mapping_screen.dart';
import '../screens/devices/illegal_logs_screen.dart';
import '../screens/devices/op_logs_screen.dart';
import '../screens/devices/push_employees_screen.dart';
import '../screens/devices/pull_employees_screen.dart';
import '../screens/devices/employee_mapping_screen.dart';
import '../screens/payroll/pay_components_screen.dart';
import '../screens/payroll/pay_grades_screen.dart';
import '../screens/payroll/payroll_policies_screen.dart';
import '../screens/payroll/payroll_run_screen.dart';
import '../screens/payroll/pay_cycles_screen.dart';
import '../screens/payroll/lock_payroll_screen.dart';
import '../screens/payroll/payslips_bulk_download_screen.dart';
import '../screens/payroll/payslips_email_screen.dart';
import '../screens/payroll/pf_settings_screen.dart';
import '../screens/payroll/esi_settings_screen.dart';
import '../screens/payroll/pt_settings_screen.dart';
import '../screens/payroll/tds_settings_screen.dart';
import '../screens/attendance/attendance_detail_screen.dart';
import '../screens/attendance/daily_summary_screen.dart';
import '../screens/attendance/mark_attendance_screen.dart';
import '../screens/shifts/shift_create_screen.dart';
import '../screens/shifts/shift_assign_screen.dart';
import '../screens/leaves/leave_balance_screen.dart';
import '../screens/leaves/leave_apply_screen.dart';
import '../screens/leaves/leave_requests_screen.dart';
import '../screens/visitors/visitor_list_screen.dart';
import '../screens/visitors/visitor_register_screen.dart';
import '../screens/visitors/visitor_pass_screen.dart';
import '../screens/visitors/active_visitors_screen.dart';
import '../screens/visitors/visitor_cards_screen.dart';
import '../screens/visitors/visitor_desks_screen.dart';
import '../screens/visitors/visitor_blacklist_screen.dart';
import '../screens/visitors/visitor_analytics_screen.dart';
import '../screens/access_control/zone_list_screen.dart';
import '../screens/access_control/door_list_screen.dart';
import '../screens/access_control/access_logs_screen.dart';
import '../screens/commands/command_center_screen.dart';
import '../screens/notifications/notification_list_screen.dart';
import '../screens/reports/report_selection_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/system/utilities_screen.dart';
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
import '../screens/school/school_dashboard_screen.dart';
import '../screens/school/student_list_screen.dart';
import '../screens/school/student_detail_screen.dart';
import '../screens/school/student_edit_screen.dart';
import '../screens/school/academic_year_screen.dart';
import '../screens/school/grade_section_screen.dart';
import '../screens/school/attendance_mark_screen.dart';
import '../screens/school/homework_screen.dart';
import '../screens/school/exam_list_screen.dart';
import '../screens/school/fee_collection_screen.dart';
import '../screens/school/transport_screen.dart';
import '../screens/school/hostel_screen.dart';
import '../screens/school/library_screen.dart';
import '../screens/school/timetable_screen.dart';
import '../screens/school/admission_screen.dart';
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
import '../screens/attendance/attendance_list_screen.dart';
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
      final isAdmin = await secureStorage.read('is_admin') == 'true';
      
      final goingToSplash = state.matchedLocation == '/splash';
      final goingToLogin = state.matchedLocation == '/login';
      final goingToRegister = state.matchedLocation == '/register';
      final goingToAdmin = state.matchedLocation.startsWith('/admin');
      final goingToAdminLogin = state.matchedLocation == '/admin/login';

      if (!loggedIn && !goingToLogin && !goingToRegister && !goingToSplash && !goingToAdmin) {
        return '/login';
      }

      if (loggedIn && (goingToLogin || goingToRegister || goingToSplash || goingToAdminLogin)) {
        if (isAdmin) {
          return '/admin/dashboard';
        } else {
          return '/dashboard';
        }
      }

      if (loggedIn && isAdmin && !goingToAdmin) {
        return '/admin/dashboard';
      }

      if (loggedIn && !isAdmin && goingToAdmin && !goingToAdminLogin) {
        return '/dashboard';
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: ApexColors.neutral400),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: ApexColors.neutral400)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      // ─── Standalone public / auth routes ──────────────────────────────────
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
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupWizardScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // ─── Main Shell (All app content & sub-shells render inside this) ──────
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          // ─── Super Admin (Admin Portal) ───
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: '/admin/tenants',
            builder: (context, state) => const AdminTenantListScreen(),
          ),
          GoRoute(
            path: '/admin/tenants/:id',
            builder: (context, state) => AdminTenantDetailScreen(
              tenantId: state.pathParameters['id']!,
            ),
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

          // ─── Workspace & Dashboards ───
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),

          // ─── Employees Module ───
          GoRoute(
            path: '/employees',
            builder: (context, state) => const EmployeeDirectoryScreen(),
          ),
          GoRoute(
            path: '/employees/create',
            builder: (context, state) => const EmployeeCreateWizard(),
          ),
          GoRoute(
            path: '/employees/documents',
            builder: (context, state) => const DocumentScreen(),
          ),
          GoRoute(
            path: '/employees/assets',
            builder: (context, state) => const AssetDashboardScreen(),
          ),
          GoRoute(
            path: '/employees/timeline',
            builder: (context, state) => const EmployeeTimelineScreen(),
          ),
          GoRoute(
            path: '/employees/departments',
            builder: (context, state) => const DepartmentScreen(),
          ),
          GoRoute(
            path: '/employees/designations',
            builder: (context, state) => const DesignationScreen(),
          ),
          GoRoute(
            path: '/employees/branches',
            builder: (context, state) => const BranchScreen(),
          ),
          GoRoute(
            path: '/employees/locations',
            builder: (context, state) => const LocationsScreen(),
          ),
          GoRoute(
            path: '/employees/employment-types',
            builder: (context, state) => const EmploymentTypesScreen(),
          ),
          GoRoute(
            path: '/employees/:id',
            builder: (context, state) => EmployeeDetailScreen(
              employeeId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/employees/:id/edit',
            builder: (context, state) => EmployeeEditScreen(
              employeeId: state.pathParameters['id']!,
            ),
          ),

          // ─── Attendance Module ───
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceDashboardScreen(),
          ),
          GoRoute(
            path: '/attendance/live',
            builder: (context, state) => const LiveAttendanceScreen(),
          ),
          GoRoute(
            path: '/attendance/register',
            builder: (context, state) => const AttendanceListScreen(),
          ),
          GoRoute(
            path: '/attendance/mark',
            builder: (context, state) => const MarkAttendanceScreen(),
          ),
          GoRoute(
            path: '/attendance/corrections',
            builder: (context, state) => const AttendanceRegularizationScreen(),
          ),
          GoRoute(
            path: '/attendance/approvals',
            builder: (context, state) => const AttendanceApprovalsScreen(),
          ),
          GoRoute(
            path: '/attendance/shifts',
            builder: (context, state) => const ShiftManagementScreen(),
          ),
          GoRoute(
            path: '/attendance/shifts/schedule',
            builder: (context, state) => const ShiftRosterScreen(),
          ),
          GoRoute(
            path: '/attendance/shifts/rotation',
            builder: (context, state) => const ShiftGroupScreen(),
          ),
          GoRoute(
            path: '/attendance/shifts/weekly-off',
            builder: (context, state) => const WeeklyOffScreen(),
          ),
          GoRoute(
            path: '/attendance/holidays',
            builder: (context, state) => const HolidayCalendarScreen(),
          ),
          GoRoute(
            path: '/attendance/holidays/groups',
            builder: (context, state) => const HolidayGroupsScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/types',
            builder: (context, state) => const LeaveTypesScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/policies',
            builder: (context, state) => const LeavePoliciesScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/requests',
            builder: (context, state) => const LeaveRequestsScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/approvals',
            builder: (context, state) => const LeaveDashboardScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/balance',
            builder: (context, state) => const LeaveBalanceScreen(),
          ),
          GoRoute(
            path: '/attendance/leave/apply',
            builder: (context, state) => const LeaveApplyScreen(),
          ),
          GoRoute(
            path: '/attendance/duty/outdoor',
            builder: (context, state) => const OutdoorDutyScreen(),
          ),
          GoRoute(
            path: '/attendance/duty/comp-off',
            builder: (context, state) => const CompOffScreen(),
          ),
          GoRoute(
            path: '/attendance/duty/missed-punch',
            builder: (context, state) => const MissedPunchScreen(),
          ),
          GoRoute(
            path: '/attendance/duty/regularization',
            builder: (context, state) => const AttendanceRegularizationScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/policies',
            builder: (context, state) => const AttendancePoliciesScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/grace',
            builder: (context, state) => const GraceTimeScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/overtime',
            builder: (context, state) => const OvertimeRulesScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/auto-shift',
            builder: (context, state) => const AutoShiftScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/geofencing',
            builder: (context, state) => const GeofencingScreen(),
          ),
          GoRoute(
            path: '/attendance/settings/biometric',
            builder: (context, state) => const BiometricSettingsScreen(),
          ),
          GoRoute(
            path: '/attendance/summary',
            builder: (context, state) => const DailySummaryScreen(),
          ),
          GoRoute(
            path: '/attendance/detail',
            builder: (context, state) => AttendanceDetailScreen(
              employeeId: state.uri.queryParameters['employeeId']!,
            ),
          ),

          // ─── Shifts (Redirects / standalone paths) ───
          GoRoute(
            path: '/shifts/create',
            builder: (context, state) => const ShiftCreateScreen(),
          ),
          GoRoute(
            path: '/shifts/assign',
            builder: (context, state) => const ShiftAssignScreen(),
          ),
          GoRoute(
            path: '/shifts/:id/edit',
            builder: (context, state) => ShiftCreateScreen(
              shiftId: state.pathParameters['id']!,
            ),
          ),

          // ─── Payroll Module ───
          GoRoute(
            path: '/payroll',
            builder: (context, state) => const PayrollDashboardScreen(),
          ),
          GoRoute(
            path: '/payroll/salary-structures',
            builder: (context, state) => const SalaryStructuresScreen(),
          ),
          GoRoute(
            path: '/payroll/pay-components',
            builder: (context, state) => const PayComponentsScreen(),
          ),
          GoRoute(
            path: '/payroll/pay-grades',
            builder: (context, state) => const PayGradesScreen(),
          ),
          GoRoute(
            path: '/payroll/policies',
            builder: (context, state) => const PayrollPoliciesScreen(),
          ),
          GoRoute(
            path: '/payroll/run',
            builder: (context, state) => const PayrollRunScreen(),
          ),
          GoRoute(
            path: '/payroll/cycles',
            builder: (context, state) => const PayCyclesScreen(),
          ),
          GoRoute(
            path: '/payroll/processing',
            builder: (context, state) => const PayrollScreen(),
          ),
          GoRoute(
            path: '/payroll/lock',
            builder: (context, state) => const LockPayrollScreen(),
          ),
          GoRoute(
            path: '/payroll/payslips',
            builder: (context, state) => const PayrollDashboardScreen(),
          ),
          GoRoute(
            path: '/payroll/payslips/bulk-download',
            builder: (context, state) => const PayslipsBulkDownloadScreen(),
          ),
          GoRoute(
            path: '/payroll/payslips/email',
            builder: (context, state) => const PayslipsEmailScreen(),
          ),
          GoRoute(
            path: '/payroll/loans',
            builder: (context, state) => const LoansScreen(),
          ),
          GoRoute(
            path: '/payroll/statutory/pf',
            builder: (context, state) => const PFSettingsScreen(),
          ),
          GoRoute(
            path: '/payroll/statutory/esi',
            builder: (context, state) => const ESISettingsScreen(),
          ),
          GoRoute(
            path: '/payroll/statutory/pt',
            builder: (context, state) => const PTSettingsScreen(),
          ),
          GoRoute(
            path: '/payroll/statutory/tds',
            builder: (context, state) => const TDSSettingsScreen(),
          ),

          // ─── Devices Module ───
          GoRoute(
            path: '/devices',
            builder: (context, state) => const DeviceListScreen(),
          ),
          GoRoute(
            path: '/devices/add',
            builder: (context, state) => const AddDeviceScreen(),
          ),
          GoRoute(
            path: '/devices/status',
            builder: (context, state) => const DeviceHealthScreen(),
          ),
          GoRoute(
            path: '/devices/groups',
            builder: (context, state) => const DeviceGroupsScreen(),
          ),
          GoRoute(
            path: '/devices/locations',
            builder: (context, state) => const EsslLocationsScreen(serverId: 'default'),
          ),
          GoRoute(
            path: '/devices/locations/branch-mapping',
            builder: (context, state) => const BranchMappingScreen(),
          ),
          GoRoute(
            path: '/devices/commands/sync-users',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/devices/commands/sync-time',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/devices/commands/restart',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/devices/commands/clear-logs',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/devices/commands/download-logs',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/devices/logs',
            builder: (context, state) => const DeviceListScreen(),
          ),
          GoRoute(
            path: '/devices/logs/illegal',
            builder: (context, state) => const IllegalLogsScreen(),
          ),
          GoRoute(
            path: '/devices/logs/op',
            builder: (context, state) => const OpLogsScreen(),
          ),
          GoRoute(
            path: '/devices/logs/sync-history',
            builder: (context, state) => const EsslSyncHistoryScreen(serverId: 'default'),
          ),
          GoRoute(
            path: '/devices/employees/push',
            builder: (context, state) => const PushEmployeesScreen(),
          ),
          GoRoute(
            path: '/devices/employees/pull',
            builder: (context, state) => const PullEmployeesScreen(),
          ),
          GoRoute(
            path: '/devices/employees/mapping',
            builder: (context, state) => const EmployeeMappingScreen(),
          ),
          GoRoute(
            path: '/devices/:id',
            builder: (context, state) => DeviceDetailScreen(
              deviceId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/devices/health',
            builder: (context, state) => const DeviceHealthScreen(),
          ),

          // ─── Visitors Module ───
          GoRoute(
            path: '/visitors',
            builder: (context, state) => const VisitorListScreen(),
          ),
          GoRoute(
            path: '/visitors/passes',
            builder: (context, state) => VisitorPassScreen(
              passId: state.uri.queryParameters['passId'] ?? 'default',
            ),
          ),
          GoRoute(
            path: '/visitors/cards',
            builder: (context, state) => const VisitorCardsScreen(),
          ),
          GoRoute(
            path: '/visitors/desks',
            builder: (context, state) => const VisitorDesksScreen(),
          ),
          GoRoute(
            path: '/visitors/blacklist',
            builder: (context, state) => const VisitorBlacklistScreen(),
          ),
          GoRoute(
            path: '/visitors/analytics',
            builder: (context, state) => const VisitorAnalyticsScreen(),
          ),
          GoRoute(
            path: '/visitors/register',
            builder: (context, state) => const VisitorRegisterScreen(),
          ),
          GoRoute(
            path: '/visitors/active',
            builder: (context, state) => const ActiveVisitorsScreen(),
          ),

          // ─── Reports Module ───
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/daily',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/monthly',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/register',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/punch',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/late',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/early',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/absent',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/attendance/overtime',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/leave/summary',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/leave/register',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/leave/balance',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/leave/history',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/duty/outdoor',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/duty/comp-off',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/duty/missed-punch',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/salary',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/bank',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/payslip',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/pf',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/esi',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/payroll/tds',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/device/logs',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/device/health',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/device/sync',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/analytics/employee',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/analytics/attendance',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/reports/analytics/department',
            builder: (context, state) => const ReportSelectionScreen(),
          ),

          // ─── Utilities Module ───
          GoRoute(
            path: '/utilities/import/employees',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/import/devices',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/import/attendance',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/import/holidays',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/import/shifts',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/export/employees',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/export/devices',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/export/attendance',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/export/payroll',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/bulk/shift-assignment',
            builder: (context, state) => const ShiftAssignScreen(),
          ),
          GoRoute(
            path: '/utilities/bulk/leave-credit',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/bulk/employee-update',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/data/backup',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/data/restore',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/data/archive',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/webhooks',
            builder: (context, state) => const UtilitiesScreen(),
          ),
          GoRoute(
            path: '/utilities/integrations',
            builder: (context, state) => const UtilitiesScreen(),
          ),

          // ─── Administration / Settings Module ───
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/company',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/organization',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/license',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/roles',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/permissions',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/audit',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/approval-workflow',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/settings/notifications',
            builder: (context, state) => const NotificationListScreen(),
          ),
          GoRoute(
            path: '/settings/essl',
            builder: (context, state) => const EsslServerListScreen(),
          ),
          GoRoute(
            path: '/settings/essl/create',
            builder: (context, state) => const EsslServerFormScreen(),
          ),
          GoRoute(
            path: '/settings/essl/:id',
            builder: (context, state) => EsslServerFormScreen(
              serverId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/settings/essl/:id/history',
            builder: (context, state) => EsslSyncHistoryScreen(
              serverId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/settings/essl/:id/locations',
            builder: (context, state) => EsslLocationsScreen(
              serverId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/settings/essl/:id/initial-sync',
            builder: (context, state) => EsslInitialSyncScreen(
              serverId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/settings/essl/:id/reprocess',
            builder: (context, state) => EsslReprocessScreen(
              serverId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/settings/essl/dashboard',
            builder: (context, state) => const EsslDashboardScreen(),
          ),
          GoRoute(
            path: '/settings/categories',
            builder: (context, state) => const CategoryScreen(),
          ),
          GoRoute(
            path: '/settings/tenant-settings',
            builder: (context, state) => const TenantSettingsScreen(),
          ),
          GoRoute(
            path: '/settings/work-codes',
            builder: (context, state) => const WorkCodeScreen(),
          ),
          GoRoute(
            path: '/departments',
            builder: (context, state) => const DepartmentScreen(),
          ),
          GoRoute(
            path: '/branches',
            builder: (context, state) => const BranchScreen(),
          ),
          GoRoute(
            path: '/designations',
            builder: (context, state) => const DesignationScreen(),
          ),
          GoRoute(
            path: '/documents',
            builder: (context, state) => const DocumentScreen(),
          ),
          GoRoute(
            path: '/exit-requests',
            builder: (context, state) => const ExitRequestScreen(),
          ),
          GoRoute(
            path: '/travel',
            builder: (context, state) => const TravelScreen(),
          ),
          GoRoute(
            path: '/announcements',
            builder: (context, state) => const AnnouncementScreen(),
          ),
          GoRoute(
            path: '/health',
            builder: (context, state) => const HealthDashboardScreen(),
          ),
          GoRoute(
            path: '/shift-groups',
            builder: (context, state) => const ShiftGroupScreen(),
          ),
          GoRoute(
            path: '/shift-rosters',
            builder: (context, state) => const ShiftRosterScreen(),
          ),
          GoRoute(
            path: '/department-shifts',
            builder: (context, state) => const DepartmentShiftScreen(),
          ),
          GoRoute(
            path: '/attendance/ot',
            builder: (context, state) => const OTRegisterScreen(),
          ),
          GoRoute(
            path: '/attendance/outdoor-duty',
            builder: (context, state) => const OutdoorDutyScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseScreen(),
          ),
          // Legacy assets redirect to employee assets
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetDashboardScreen(),
          ),

          // ─── ESS Portal Routes (Moved inside ShellRoute for global navigation) ─
          GoRoute(
            path: '/ess/dashboard',
            builder: (context, state) => const EssDashboardScreen(),
          ),
          GoRoute(
            path: '/ess/attendance',
            builder: (context, state) => const EssAttendanceCalendarScreen(),
          ),
          GoRoute(
            path: '/ess/attendance/calendar',
            builder: (context, state) => const EssAttendanceCalendarScreen(),
          ),
          GoRoute(
            path: '/ess/leaves',
            builder: (context, state) => const EssLeaveScreen(),
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

          // ─── School ERP Routes (Moved inside ShellRoute for global navigation) ─
          GoRoute(
            path: '/school/dashboard',
            builder: (context, state) => const SchoolDashboardScreen(),
          ),
          GoRoute(
            path: '/school/students',
            builder: (context, state) => const StudentListScreen(),
          ),
          GoRoute(
            path: '/school/students/:id',
            builder: (context, state) => StudentDetailScreen(
              studentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/school/students/:id/edit',
            builder: (context, state) => StudentEditScreen(
              studentId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/school/academic-years',
            builder: (context, state) => const AcademicYearScreen(),
          ),
          GoRoute(
            path: '/school/classes',
            builder: (context, state) => const GradeSectionScreen(),
          ),
          GoRoute(
            path: '/school/attendance/mark',
            builder: (context, state) => const AttendanceMarkScreen(),
          ),
          GoRoute(
            path: '/school/homework',
            builder: (context, state) => const HomeworkScreen(),
          ),
          GoRoute(
            path: '/school/exams',
            builder: (context, state) => const ExamListScreen(),
          ),
          GoRoute(
            path: '/school/fees',
            builder: (context, state) => const FeeCollectionScreen(),
          ),
          GoRoute(
            path: '/school/transport',
            builder: (context, state) => const TransportScreen(),
          ),
          GoRoute(
            path: '/school/hostel',
            builder: (context, state) => const HostelScreen(),
          ),
          GoRoute(
            path: '/school/library',
            builder: (context, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: '/school/timetable',
            builder: (context, state) => const TimetableScreen(),
          ),
          GoRoute(
            path: '/school/admissions',
            builder: (context, state) => const AdmissionScreen(),
          ),
        ],
      ),
    ],
  );
});
