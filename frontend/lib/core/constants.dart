class ApiConstants {
  static const String baseUrl = '/api/v1';
  static const String desktopBaseUrl = 'https://next.apextime.in/api/v1';
  static String get wsUrl {
    final uri = Uri.base;
    final scheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return '${scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/api/v1/ws/dashboard';
  }

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Tenant endpoints
  static const String tenants = '/tenants';

  // Employee endpoints
  static const String employees = '/employees';
  static const String departments = '/employees/departments';
  static const String designations = '/employees/designations';
  static const String branches = '/employees/branches';
  static const String bulkImport = '/employees/bulk-import';

  // Device endpoints
  static const String devices = '/devices';
  static const String deviceHealth = '/devices/health';
  static const String deviceLogs = '/devices/logs';
  static const String deviceSync = '/devices/sync';

  // Attendance endpoints
  static const String attendance = '/attendance';
  static const String dailySummary = '/attendance/daily-summary';
  static const String employeeSummary = '/attendance/employee-summary';
  static const String processAttendance = '/attendance/process';
  static const String approveAttendance = '/attendance/approve';
  static const String punchLogs = '/attendance/punch-logs';

  // Shift endpoints
  static const String shifts = '/shifts';
  static const String assignShift = '/shifts/assign';
  static const String schedules = '/shifts/schedules';

  // Leave endpoints
  static const String leaveTypes = '/leaves/types';
  static const String leaveBalance = '/leaves/balance';
  static const String leaveRequests = '/leaves/requests';
  static const String leaveApply = '/leaves/apply';

  // Visitor endpoints
  static const String visitors = '/visitors';
  static const String visitorPasses = '/visitors/passes';
  static const String visitorCheckIn = '/visitors/check-in';
  static const String visitorCheckOut = '/visitors/check-out';
  static const String activeVisitors = '/visitors/active';
  static const String visitorHistory = '/visitors/history';

  // Access control endpoints
  static const String accessZones = '/access-control/zones';
  static const String accessDoors = '/access-control/doors';
  static const String accessGrant = '/access-control/grant';
  static const String accessRevoke = '/access-control/revoke';
  static const String accessCheck = '/access-control/check';
  static const String accessLogs = '/access-control/logs';

  // Command endpoints
  static const String commands = '/commands';
  static const String executeCommand = '/commands/execute';

  // Notification endpoints
  static const String notifications = '/notifications';
  static const String unreadCount = '/notifications/unread-count';
  static const String markRead = '/notifications/mark-read';

  // Report endpoints
  static const String reportsDaily = '/reports/attendance/daily';
  static const String reportsMonthly = '/reports/attendance/monthly';
  static const String reportsEmployee = '/reports/attendance/employee';
  static const String reportsLate = '/reports/attendance/late';
  static const String reportsOvertime = '/reports/attendance/overtime';
  static const String reportsAbsent = '/reports/attendance/absent';
  static const String reportsVisitors = '/reports/visitors';
  static const String reportsDevices = '/reports/devices';

  // Dashboard endpoints
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardChart = '/dashboard/attendance-chart';
  static const String dashboardRecentActivity = '/dashboard/recent-activity';
  static const String dashboardHeatmap = '/dashboard/attendance-heatmap';
  static const String dashboardLeaveCalendar = '/dashboard/leave-calendar';
  static const String dashboardBirthdays = '/dashboard/birthdays';
  static const String dashboardAnniversaries = '/dashboard/anniversaries';
  static const String dashboardDepartmentDistribution = '/dashboard/department-distribution';
  static const String dashboardMonthlyTrend = '/dashboard/monthly-trend';
  static const String dashboardSyncHealth = '/dashboard/sync-health';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userProfile = 'user_profile';
  static const String tenantSlug = 'tenant_slug';
}

class AppConstants {
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
