import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/main_shell.dart';
import '../screens/dashboard/dashboard_screen.dart';

import '../screens/employees/employee_detail_screen.dart';
import '../screens/employees/employee_create_screen.dart';
import '../screens/employees/employee_edit_screen.dart';
import '../screens/employees/department_screen.dart';
import '../screens/employees/branch_screen.dart';
import '../screens/employees/designation_screen.dart';
import '../screens/devices/device_list_screen.dart';
import '../screens/devices/device_detail_screen.dart';
import '../screens/devices/device_health_screen.dart';
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
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Page not found', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(state.uri.toString(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
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
        path: '/admin/tenants/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AdminTenantDetailScreen(tenantId: id);
        },
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
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
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
            path: '/holidays',
            builder: (context, state) => const HolidayCalendarScreen(),
          ),
          GoRoute(
            path: '/devices',
            builder: (context, state) => const DeviceListScreen(),
          ),
          GoRoute(
            path: '/devices/health',
            builder: (context, state) => const DeviceHealthScreen(),
          ),
          GoRoute(
            path: '/devices/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return DeviceDetailScreen(deviceId: id);
            },
          ),
          GoRoute(
            path: '/visitors',
            builder: (context, state) => const VisitorListScreen(),
          ),
          GoRoute(
            path: '/visitors/register',
            builder: (context, state) => const VisitorRegisterScreen(),
          ),
          GoRoute(
            path: '/visitors/pass',
            builder: (context, state) {
              final passId = state.uri.queryParameters['passId']!;
              return VisitorPassScreen(passId: passId);
            },
          ),
          GoRoute(
            path: '/visitors/active',
            builder: (context, state) => const ActiveVisitorsScreen(),
          ),
          GoRoute(
            path: '/access/zones',
            builder: (context, state) => const ZoneListScreen(),
          ),
          GoRoute(
            path: '/access/doors',
            builder: (context, state) => const DoorListScreen(),
          ),
          GoRoute(
            path: '/access/logs',
            builder: (context, state) => const AccessLogsScreen(),
          ),
          GoRoute(
            path: '/commands',
            builder: (context, state) => const CommandCenterScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationListScreen(),
          ),
          GoRoute(
            path: '/recruitment',
            builder: (context, state) => const RecruitmentDashboardScreen(),
          ),
          GoRoute(
            path: '/recruitment/candidates',
            builder: (context, state) => const CandidatesScreen(),
          ),
          GoRoute(
            path: '/recruitment/interviews',
            builder: (context, state) => const InterviewsScreen(),
          ),
          GoRoute(
            path: '/performance',
            builder: (context, state) => const PerformanceDashboardScreen(),
          ),
          GoRoute(
            path: '/performance/goals',
            builder: (context, state) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/assets',
            builder: (context, state) => const AssetDashboardScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportSelectionScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpenseScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
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
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EsslServerFormScreen(serverId: id);
            },
          ),
          GoRoute(
            path: '/settings/essl/:id/history',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EsslSyncHistoryScreen(serverId: id);
            },
          ),
          GoRoute(
            path: '/settings/essl/:id/locations',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EsslLocationsScreen(serverId: id);
            },
          ),
          GoRoute(
            path: '/settings/essl/:id/initial-sync',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EsslInitialSyncScreen(serverId: id);
            },
          ),
          GoRoute(
            path: '/settings/essl/:id/reprocess',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return EsslReprocessScreen(serverId: id);
            },
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
          // School ERP routes
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
            builder: (context, state) => StudentDetailScreen(studentId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/school/students/:id/edit',
            builder: (context, state) => StudentEditScreen(studentId: state.pathParameters['id']!),
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
      GoRoute(
        path: '/employees/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeDetailScreen(employeeId: id);
        },
      ),
      GoRoute(
        path: '/employees/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EmployeeEditScreen(employeeId: id);
        },
      ),
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
      GoRoute(
        path: '/shifts/:id/edit',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShiftCreateScreen(shiftId: id);
        },
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
    ],
  );
});
