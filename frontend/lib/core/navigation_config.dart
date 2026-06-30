import 'package:flutter/material.dart';

// ─── Navigation Models ────────────────────────────────────────────────────────

class NavLeaf {
  final String id;
  final String label;
  final String route;
  final IconData? icon;
  const NavLeaf({required this.id, required this.label, required this.route, this.icon});
}

class NavGroup {
  final String id;
  final String label;
  final IconData icon;
  final List<NavLeaf> items;
  const NavGroup({required this.id, required this.label, required this.icon, required this.items});
}

class NavModule {
  final String id;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String? rootRoute;
  final List<NavGroup> groups;
  const NavModule({
    required this.id,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.rootRoute,
    required this.groups,
  });

  List<NavLeaf> get allLeaves => groups.expand((g) => g.items).toList();
}

class NavSection {
  final String label;
  final List<NavModule> modules;
  const NavSection({required this.label, required this.modules});
}

class BreadcrumbEntry {
  final String label;
  final String route;
  const BreadcrumbEntry({required this.label, required this.route});
}

// ─── Navigation Configuration ─────────────────────────────────────────────────

class NavigationConfig {
  NavigationConfig._();

  static const List<NavSection> sections = [
    // ── WORKSPACE ────────────────────────────────────────────────────────────
    NavSection(label: 'WORKSPACE', modules: [
      NavModule(
        id: 'dashboard',
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
        rootRoute: '/dashboard',
        groups: [
          NavGroup(id: 'dashboard_main', label: 'Overview', icon: Icons.home_outlined, items: [
            NavLeaf(id: 'dashboard_home', label: 'Dashboard', route: '/dashboard', icon: Icons.analytics_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'approvals',
        label: 'Approvals',
        icon: Icons.check_circle_outline,
        activeIcon: Icons.check_circle,
        rootRoute: '/approvals',
        groups: [
          NavGroup(id: 'app_pending', label: 'Pending Approvals', icon: Icons.inbox_outlined, items: [
            NavLeaf(id: 'app_leave',        label: 'Leave',               route: '/approvals/leave',                icon: Icons.event_busy_outlined),
            NavLeaf(id: 'app_attendance',   label: 'Attendance',          route: '/approvals/attendance',           icon: Icons.calendar_today_outlined),
            NavLeaf(id: 'app_missed',       label: 'Missed Punch',        route: '/approvals/missed-punch',         icon: Icons.fingerprint),
            NavLeaf(id: 'app_compoff',      label: 'Comp Off',            route: '/approvals/comp-off',             icon: Icons.swap_horiz_outlined),
            NavLeaf(id: 'app_outdoor',      label: 'Outdoor Duty',        route: '/approvals/outdoor-duty',         icon: Icons.directions_walk_outlined),
            NavLeaf(id: 'app_payroll',      label: 'Payroll',             route: '/approvals/payroll',              icon: Icons.payments_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'ess',
        label: 'Self Service',
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        rootRoute: '/ess',
        groups: [
          NavGroup(id: 'ess_portal', label: 'ESS Portal', icon: Icons.account_circle_outlined, items: [
            NavLeaf(id: 'ess_profile',    label: 'My Profile',          route: '/ess/profile',                    icon: Icons.badge_outlined),
            NavLeaf(id: 'ess_clock',      label: 'Clock In/Out',        route: '/ess/attendance',                 icon: Icons.fingerprint),
            NavLeaf(id: 'ess_attendance', label: 'My Attendance',       route: '/ess/attendance/calendar',        icon: Icons.calendar_month_outlined),
            NavLeaf(id: 'ess_leaves',     label: 'My Leaves',           route: '/ess/leaves',                     icon: Icons.event_busy_outlined),
            NavLeaf(id: 'ess_payslips',   label: 'My Payslips',         route: '/ess/payslips',                   icon: Icons.description_outlined),
          ]),
        ],
      ),
    ]),

    // ── HRMS OPERATIONS ───────────────────────────────────────────────────────
    NavSection(label: 'HRMS OPERATIONS', modules: [
      NavModule(
        id: 'employees',
        label: 'Employees',
        icon: Icons.people_outline,
        activeIcon: Icons.people,
        rootRoute: '/employees',
        groups: [
          NavGroup(id: 'emp_records', label: 'Employee Records', icon: Icons.badge_outlined, items: [
            NavLeaf(id: 'emp_list',     label: 'Employee List',       route: '/employees',                  icon: Icons.format_list_bulleted_outlined),
            NavLeaf(id: 'emp_add',      label: 'Add Employee',        route: '/employees/create',           icon: Icons.person_add_outlined),
            NavLeaf(id: 'emp_docs',     label: 'Employee Documents',  route: '/employees/documents',        icon: Icons.folder_outlined),
            NavLeaf(id: 'emp_assets',   label: 'Employee Assets',     route: '/employees/assets',           icon: Icons.inventory_2_outlined),
            NavLeaf(id: 'emp_timeline', label: 'Employee Timeline',   route: '/employees/timeline',         icon: Icons.timeline_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'attendance',
        label: 'Attendance',
        icon: Icons.calendar_today_outlined,
        activeIcon: Icons.calendar_today,
        rootRoute: '/attendance',
        groups: [
          NavGroup(id: 'att_ops', label: 'Operations', icon: Icons.fact_check_outlined, items: [
            NavLeaf(id: 'att_live',        label: 'Live Attendance',     route: '/attendance/live',                icon: Icons.sensors),
            NavLeaf(id: 'att_register',    label: 'Attendance Register', route: '/attendance/register',            icon: Icons.table_chart_outlined),
            NavLeaf(id: 'att_manual',      label: 'Manual Attendance',   route: '/attendance/mark',                icon: Icons.edit_calendar_outlined),
            NavLeaf(id: 'att_corrections', label: 'Corrections',         route: '/attendance/corrections',         icon: Icons.edit_note_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'leave',
        label: 'Leave',
        icon: Icons.event_busy_outlined,
        activeIcon: Icons.event_busy,
        rootRoute: '/attendance/leave',
        groups: [
          NavGroup(id: 'lv_ops', label: 'Leave Ledger', icon: Icons.inbox_outlined, items: [
            NavLeaf(id: 'att_lv_requests',  label: 'Leave Requests',     route: '/attendance/leave/requests',      icon: Icons.inbox_outlined),
            NavLeaf(id: 'att_lv_balance',   label: 'Leave Balance',      route: '/attendance/leave/balance',       icon: Icons.account_balance_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'payroll',
        label: 'Payroll',
        icon: Icons.payments_outlined,
        activeIcon: Icons.payments,
        rootRoute: '/payroll',
        groups: [
          NavGroup(id: 'pay_processing', label: 'Processing', icon: Icons.receipt_long_outlined, items: [
            NavLeaf(id: 'pay_run',         label: 'Payroll Run',         route: '/payroll/run',                    icon: Icons.play_circle_outline),
            NavLeaf(id: 'pay_proc',        label: 'Salary Processing',   route: '/payroll/processing',             icon: Icons.settings_outlined),
            NavLeaf(id: 'pay_lock',        label: 'Lock Payroll',        route: '/payroll/lock',                   icon: Icons.lock_outline),
            NavLeaf(id: 'pay_slip_gen',   label: 'Generate Payslips',    route: '/payroll/payslips',               icon: Icons.note_add_outlined),
          ]),
        ],
      ),
      NavModule(
        id: 'visitors',
        label: 'Visitors',
        icon: Icons.badge_outlined,
        activeIcon: Icons.badge,
        rootRoute: '/visitors',
        groups: [
          NavGroup(id: 'vis_main', label: 'Visitor Management', icon: Icons.supervisor_account_outlined, items: [
            NavLeaf(id: 'vis_logs',      label: 'Visitor Logs',          route: '/visitors',                             icon: Icons.format_list_bulleted_outlined),
            NavLeaf(id: 'vis_passes',    label: 'Visitor Passes',        route: '/visitors/passes',                      icon: Icons.confirmation_number_outlined),
          ]),
        ],
      ),
    ]),

    // ── REPORT CENTER ────────────────────────────────────────────────────────
    NavSection(label: 'REPORT CENTER', modules: [
      NavModule(
        id: 'reports',
        label: 'Reports',
        icon: Icons.assessment_outlined,
        activeIcon: Icons.assessment,
        rootRoute: '/reports',
        groups: [
          NavGroup(id: 'rep_attendance', label: 'Attendance Reports', icon: Icons.calendar_today_outlined, items: [
            NavLeaf(id: 'rep_att_daily',   label: 'Daily Attendance',    route: '/reports/attendance/daily',             icon: Icons.today_outlined),
            NavLeaf(id: 'rep_att_monthly', label: 'Monthly Attendance',  route: '/reports/attendance/monthly',           icon: Icons.calendar_month_outlined),
            NavLeaf(id: 'rep_att_reg',     label: 'Attendance Register', route: '/reports/attendance/register',          icon: Icons.table_chart_outlined),
            NavLeaf(id: 'rep_att_punch',   label: 'Punch Report',        route: '/reports/attendance/punch',             icon: Icons.fingerprint),
            NavLeaf(id: 'rep_att_late',    label: 'Late Coming',         route: '/reports/attendance/late',              icon: Icons.watch_later_outlined),
            NavLeaf(id: 'rep_att_early',   label: 'Early Going',         route: '/reports/attendance/early',             icon: Icons.exit_to_app_outlined),
            NavLeaf(id: 'rep_att_absent',  label: 'Absent Report',       route: '/reports/attendance/absent',            icon: Icons.person_off_outlined),
            NavLeaf(id: 'rep_att_ot',      label: 'Overtime Report',     route: '/reports/attendance/overtime',          icon: Icons.more_time_outlined),
          ]),
          NavGroup(id: 'rep_leave', label: 'Leave Reports', icon: Icons.event_busy_outlined, items: [
            NavLeaf(id: 'rep_lv_summary', label: 'Leave Summary',        route: '/reports/leave/summary',                icon: Icons.summarize_outlined),
            NavLeaf(id: 'rep_lv_reg',     label: 'Leave Register',       route: '/reports/leave/register',               icon: Icons.app_registration_outlined),
            NavLeaf(id: 'rep_lv_balance', label: 'Leave Balance',        route: '/reports/leave/balance',                icon: Icons.account_balance_outlined),
            NavLeaf(id: 'rep_lv_history', label: 'Leave History',        route: '/reports/leave/history',                icon: Icons.history_outlined),
          ]),
          NavGroup(id: 'rep_payroll', label: 'Payroll Reports', icon: Icons.payments_outlined, items: [
            NavLeaf(id: 'rep_pay_sal',  label: 'Salary Register',        route: '/reports/payroll/salary',               icon: Icons.receipt_long_outlined),
            NavLeaf(id: 'rep_pay_bank', label: 'Bank Transfer',          route: '/reports/payroll/bank',                 icon: Icons.account_balance_outlined),
            NavLeaf(id: 'rep_pay_slip', label: 'Payslip Report',         route: '/reports/payroll/payslip',              icon: Icons.description_outlined),
            NavLeaf(id: 'rep_pay_pf',   label: 'PF Report',              route: '/reports/payroll/pf',                   icon: Icons.savings_outlined),
            NavLeaf(id: 'rep_pay_esi',  label: 'ESI Report',             route: '/reports/payroll/esi',                  icon: Icons.health_and_safety_outlined),
            NavLeaf(id: 'rep_pay_tds',  label: 'TDS Report',             route: '/reports/payroll/tds',                  icon: Icons.percent_outlined),
          ]),
          NavGroup(id: 'rep_device', label: 'Device Reports', icon: Icons.devices_outlined, items: [
            NavLeaf(id: 'rep_dev_logs',   label: 'Device Logs',          route: '/reports/device/logs',                  icon: Icons.list_alt_outlined),
            NavLeaf(id: 'rep_dev_health', label: 'Device Health',        route: '/reports/device/health',                icon: Icons.monitor_heart_outlined),
            NavLeaf(id: 'rep_dev_sync',   label: 'Sync Status',          route: '/reports/device/sync',                  icon: Icons.sync_outlined),
          ]),
        ],
      ),
    ]),

    // ── CONFIGURATION ────────────────────────────────────────────────────────
    NavSection(label: 'CONFIGURATION', modules: [
      NavModule(
        id: 'configuration',
        label: 'Configuration',
        icon: Icons.settings_suggest_outlined,
        activeIcon: Icons.settings_suggest,
        rootRoute: '/settings/config',
        groups: [
          NavGroup(id: 'cfg_org', label: 'Organization', icon: Icons.corporate_fare_outlined, items: [
            NavLeaf(id: 'emp_branches', label: 'Branches',            route: '/employees/branches',         icon: Icons.store_outlined),
            NavLeaf(id: 'emp_locs',     label: 'Locations',           route: '/employees/locations',        icon: Icons.location_on_outlined),
            NavLeaf(id: 'emp_depts',    label: 'Departments',         route: '/employees/departments',      icon: Icons.business_outlined),
            NavLeaf(id: 'emp_desig',    label: 'Designations',        route: '/employees/designations',     icon: Icons.work_outline),
            NavLeaf(id: 'emp_types',    label: 'Employment Types',    route: '/employees/employment-types', icon: Icons.category_outlined),
          ]),
          NavGroup(id: 'cfg_attendance', label: 'Attendance', icon: Icons.tune_outlined, items: [
            NavLeaf(id: 'att_shift_types',  label: 'Shifts',             route: '/attendance/shifts',              icon: Icons.access_time_outlined),
            NavLeaf(id: 'att_weekly_off',   label: 'Weekly Off',         route: '/attendance/shifts/weekly-off',   icon: Icons.weekend_outlined),
            NavLeaf(id: 'att_hol_groups', label: 'Holiday Groups',       route: '/attendance/holidays/groups',     icon: Icons.group_work_outlined),
            NavLeaf(id: 'att_lv_policies',  label: 'Leave Policies',     route: '/attendance/leave/policies',      icon: Icons.policy_outlined),
            NavLeaf(id: 'att_set_grace',    label: 'Grace Rules',        route: '/attendance/settings/grace',       icon: Icons.timer_outlined),
            NavLeaf(id: 'att_set_auto',     label: 'Auto Shift',          route: '/attendance/settings/auto-shift',  icon: Icons.auto_mode_outlined),
            NavLeaf(id: 'att_set_geo',      label: 'Geofencing',          route: '/attendance/settings/geofencing',  icon: Icons.my_location_outlined),
            NavLeaf(id: 'att_set_ot',       label: 'Overtime',            route: '/attendance/settings/overtime',    icon: Icons.access_alarm_outlined),
          ]),
          NavGroup(id: 'cfg_payroll', label: 'Payroll', icon: Icons.payments_outlined, items: [
            NavLeaf(id: 'pay_components', label: 'Pay Components',      route: '/payroll/pay-components',           icon: Icons.extension_outlined),
            NavLeaf(id: 'pay_grades',     label: 'Pay Grades',          route: '/payroll/pay-grades',               icon: Icons.leaderboard_outlined),
            NavLeaf(id: 'pay_cycles',      label: 'Pay Cycles',          route: '/payroll/cycles',                 icon: Icons.loop_outlined),
            NavLeaf(id: 'pay_stat_pf',     label: 'Statutory PF',        route: '/payroll/statutory/pf',           icon: Icons.savings_outlined),
            NavLeaf(id: 'pay_structures', label: 'Salary Templates',    route: '/payroll/salary-structures',        icon: Icons.layers_outlined),
          ]),
          NavGroup(id: 'cfg_devices', label: 'Devices', icon: Icons.devices_other_outlined, items: [
            NavLeaf(id: 'adm_essl_list', label: 'eSSL Servers',           route: '/settings/essl',                      icon: Icons.dns_outlined),
            NavLeaf(id: 'dev_groups',  label: 'Device Groups',            route: '/devices/groups',                       icon: Icons.device_hub_outlined),
            NavLeaf(id: 'dev_emp_map',  label: 'Employee Mapping',        route: '/devices/employees/mapping',            icon: Icons.compare_arrows_outlined),
          ]),
        ],
      ),
    ]),

    // ── ADMINISTRATION ───────────────────────────────────────────────────────
    NavSection(label: 'ADMINISTRATION', modules: [
      NavModule(
        id: 'administration',
        label: 'Administration',
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
        rootRoute: '/settings/company',
        groups: [
          NavGroup(id: 'adm_company', label: 'Company', icon: Icons.business_outlined, items: [
            NavLeaf(id: 'adm_comp',    label: 'Company Settings',         route: '/settings/company',                   icon: Icons.settings_outlined),
            NavLeaf(id: 'adm_org',     label: 'Organisation',             route: '/settings/organization',              icon: Icons.account_tree_outlined),
            NavLeaf(id: 'adm_license', label: 'License & Subscription',   route: '/settings/license',                   icon: Icons.verified_outlined),
          ]),
          NavGroup(id: 'adm_users', label: 'Users & Roles', icon: Icons.manage_accounts_outlined, items: [
            NavLeaf(id: 'adm_roles',  label: 'User Roles',                route: '/settings/roles',                     icon: Icons.shield_outlined),
            NavLeaf(id: 'adm_perms',  label: 'Permissions',               route: '/settings/permissions',               icon: Icons.lock_outline),
            NavLeaf(id: 'adm_audit',  label: 'Audit Logs',                route: '/settings/audit',                     icon: Icons.history_outlined),
          ]),
          NavGroup(id: 'adm_workflow', label: 'Workflow', icon: Icons.account_tree_outlined, items: [
            NavLeaf(id: 'adm_approval', label: 'Approval Workflow',       route: '/settings/approval-workflow',         icon: Icons.check_circle_outline),
            NavLeaf(id: 'adm_notif',    label: 'Notification Settings',   route: '/settings/notifications',             icon: Icons.notifications_outlined),
          ]),
          NavGroup(id: 'adm_data', label: 'Data Tools', icon: Icons.storage_outlined, items: [
            NavLeaf(id: 'util_backup',  label: 'Backup',                  route: '/utilities/data/backup',              icon: Icons.backup_outlined),
            NavLeaf(id: 'util_restore', label: 'Restore',                 route: '/utilities/data/restore',             icon: Icons.restore_outlined),
            NavLeaf(id: 'util_webhooks', label: 'Webhooks',               route: '/utilities/webhooks',                 icon: Icons.webhook_outlined),
            NavLeaf(id: 'util_api_int',  label: 'API Integrations',       route: '/utilities/integrations',             icon: Icons.api_outlined),
          ]),
        ],
      ),
    ]),
  ];

  // ─── Route → label map for breadcrumbs ───────────────────────────────────

  static const Map<String, String> routeLabels = {
    '/approvals/leave':                     'Leave Approvals',
    '/approvals/attendance':                'Attendance Approvals',
    '/approvals/missed-punch':              'Missed Punch Approvals',
    '/approvals/comp-off':                  'Comp Off Approvals',
    '/approvals/outdoor-duty':              'Outdoor Duty Approvals',
    '/approvals/payroll':                   'Payroll Approvals',
    '/ess/profile':                         'My Profile',
    '/ess/attendance/calendar':             'My Attendance',
    '/ess/leaves':                          'My Leaves',
    '/ess/payslips':                        'My Payslips',
    '/ess/documents':                       'My Documents',
    '/ess/notifications':                   'My Notifications',
    '/dashboard':                           'Dashboard',
    '/employees':                           'Employee List',
    '/employees/create':                    'Add Employee',
    '/employees/documents':                 'Employee Documents',
    '/employees/assets':                    'Employee Assets',
    '/employees/timeline':                  'Employee Timeline',
    '/employees/departments':               'Departments',
    '/employees/designations':              'Designations',
    '/employees/branches':                  'Branches',
    '/employees/locations':                 'Locations',
    '/employees/employment-types':          'Employment Types',
    '/attendance':                          'Attendance',
    '/attendance/live':                     'Live Attendance',
    '/attendance/register':                 'Attendance Register',
    '/attendance/mark':                     'Manual Attendance',
    '/attendance/corrections':              'Corrections',
    '/attendance/approvals':                'Approvals',
    '/attendance/shifts':                   'Shift Types',
    '/attendance/shifts/schedule':          'Shift Schedule',
    '/attendance/shifts/rotation':          'Shift Rotation',
    '/attendance/shifts/weekly-off':        'Weekly Off',
    '/attendance/holidays':                 'Holiday Calendar',
    '/attendance/holidays/groups':          'Holiday Groups',
    '/attendance/leave':                    'Leave',
    '/attendance/leave/types':              'Leave Types',
    '/attendance/leave/policies':           'Leave Policies',
    '/attendance/leave/requests':           'Leave Requests',
    '/attendance/leave/approvals':          'Leave Approvals',
    '/attendance/leave/balance':            'Leave Balance',
    '/attendance/duty':                     'Duty',
    '/attendance/duty/outdoor':             'Out Duty',
    '/attendance/duty/comp-off':            'Comp Off',
    '/attendance/duty/missed-punch':        'Missed Punch',
    '/attendance/duty/regularization':      'Regularization',
    '/attendance/settings':                 'Attendance Settings',
    '/attendance/settings/policies':        'Attendance Policies',
    '/attendance/settings/grace':           'Grace Time',
    '/attendance/settings/overtime':        'Overtime Rules',
    '/attendance/settings/auto-shift':      'Auto Shift',
    '/attendance/settings/geofencing':      'Geofencing',
    '/attendance/settings/biometric':       'Biometric Settings',
    '/payroll':                             'Payroll',
    '/payroll/salary-structures':           'Salary Structures',
    '/payroll/pay-components':              'Pay Components',
    '/payroll/pay-grades':                  'Pay Grades',
    '/payroll/policies':                    'Payroll Policies',
    '/payroll/run':                         'Payroll Run',
    '/payroll/cycles':                      'Pay Cycles',
    '/payroll/processing':                  'Salary Processing',
    '/payroll/lock':                        'Lock Payroll',
    '/payroll/payslips':                    'Generate Payslips',
    '/payroll/payslips/bulk-download':      'Bulk Download',
    '/payroll/payslips/email':              'Email Payslips',
    '/payroll/statutory':                   'Statutory',
    '/payroll/statutory/pf':               'PF',
    '/payroll/statutory/esi':              'ESI',
    '/payroll/statutory/pt':               'Professional Tax',
    '/payroll/statutory/tds':              'TDS',
    '/devices':                             'Device List',
    '/devices/add':                         'Add Device',
    '/devices/status':                      'Device Status',
    '/devices/groups':                      'Device Groups',
    '/devices/locations':                   'Location List',
    '/devices/locations/branch-mapping':    'Branch Mapping',
    '/devices/commands':                    'Commands',
    '/devices/commands/sync-users':         'Sync Users',
    '/devices/commands/sync-time':          'Sync Time',
    '/devices/commands/restart':            'Restart Device',
    '/devices/commands/clear-logs':         'Clear Logs',
    '/devices/commands/download-logs':      'Download Logs',
    '/devices/logs':                        'Device Logs',
    '/devices/logs/illegal':                'Illegal Logs',
    '/devices/logs/op':                     'OP Logs',
    '/devices/logs/sync-history':           'Sync History',
    '/devices/employees':                   'Device Employees',
    '/devices/employees/push':              'Push Employees',
    '/devices/employees/pull':              'Pull Employees',
    '/devices/employees/mapping':           'Employee Mapping',
    '/visitors':                            'Visitor Logs',
    '/visitors/passes':                     'Visitor Passes',
    '/visitors/cards':                      'Visitor Cards',
    '/visitors/desks':                      'Visitor Desks',
    '/visitors/blacklist':                  'Blacklist',
    '/visitors/analytics':                  'Visitor Analytics',
    '/reports':                             'Reports',
    '/reports/attendance':                  'Attendance Reports',
    '/reports/attendance/daily':            'Daily Attendance',
    '/reports/attendance/monthly':          'Monthly Attendance',
    '/reports/attendance/register':         'Attendance Register',
    '/reports/attendance/punch':            'Punch Report',
    '/reports/attendance/late':             'Late Coming',
    '/reports/attendance/early':            'Early Going',
    '/reports/attendance/absent':           'Absent Report',
    '/reports/attendance/overtime':         'Overtime Report',
    '/reports/leave':                       'Leave Reports',
    '/reports/leave/summary':               'Leave Summary',
    '/reports/leave/register':              'Leave Register',
    '/reports/leave/balance':               'Leave Balance Report',
    '/reports/leave/history':               'Leave History',
    '/reports/duty':                        'Duty Reports',
    '/reports/duty/outdoor':                'Out Duty Report',
    '/reports/duty/comp-off':               'Comp Off Report',
    '/reports/duty/missed-punch':           'Missed Punch Report',
    '/reports/payroll':                     'Payroll Reports',
    '/reports/payroll/salary':              'Salary Register',
    '/reports/payroll/bank':                'Bank Transfer Report',
    '/reports/payroll/payslip':             'Payslip Report',
    '/reports/payroll/pf':                  'PF Report',
    '/reports/payroll/esi':                 'ESI Report',
    '/reports/payroll/tds':                 'TDS Report',
    '/reports/device':                      'Device Reports',
    '/reports/device/logs':                 'Device Logs Report',
    '/reports/device/health':               'Device Health Report',
    '/reports/device/sync':                 'Sync Status Report',
    '/reports/analytics':                   'Analytics',
    '/reports/analytics/employee':          'Employee Analytics',
    '/reports/analytics/attendance':        'Attendance Trends',
    '/reports/analytics/department':        'Department Summary',
    '/utilities':                           'Utilities',
    '/utilities/import':                    'Import',
    '/utilities/import/employees':          'Import Employees',
    '/utilities/import/devices':            'Import Devices',
    '/utilities/import/attendance':         'Import Attendance',
    '/utilities/import/holidays':           'Import Holidays',
    '/utilities/import/shifts':             'Import Shifts',
    '/utilities/export':                    'Export',
    '/utilities/export/employees':          'Export Employees',
    '/utilities/export/devices':            'Export Devices',
    '/utilities/export/attendance':         'Export Attendance',
    '/utilities/export/payroll':            'Export Payroll',
    '/utilities/bulk':                      'Bulk Operations',
    '/utilities/bulk/shift-assignment':     'Bulk Shift Assignment',
    '/utilities/bulk/leave-credit':         'Bulk Leave Credit',
    '/utilities/bulk/employee-update':      'Bulk Employee Update',
    '/utilities/data':                      'Data Tools',
    '/utilities/data/backup':               'Backup',
    '/utilities/data/restore':              'Restore',
    '/utilities/data/archive':              'Archive',
    '/utilities/webhooks':                  'Webhooks',
    '/utilities/integrations':              'API Integrations',
    '/settings':                            'Administration',
    '/settings/company':                    'Company Settings',
    '/settings/organization':               'Organisation',
    '/settings/license':                    'License & Subscription',
    '/settings/roles':                      'User Roles',
    '/settings/permissions':               'Permissions',
    '/settings/audit':                      'Audit Logs',
    '/settings/approval-workflow':          'Approval Workflow',
    '/settings/notifications':              'Notification Settings',
    '/settings/essl':                       'eSSL Servers',
    '/settings/essl/dashboard':             'Sync Dashboard',
    '/settings/categories':                 'Categories',
    '/settings/tenant-settings':            'Tenant Settings',
    '/settings/work-codes':                 'Work Codes',
  };

  /// Human-readable label for any route, including dynamic segments.
  static String labelFor(String route) {
    if (routeLabels.containsKey(route)) return routeLabels[route]!;
    final stripped = route.endsWith('/') ? route.substring(0, route.length - 1) : route;
    if (routeLabels.containsKey(stripped)) return routeLabels[stripped]!;
    // Dynamic segment patterns
    if (RegExp(r'^/employees/[^/]+/edit$').hasMatch(route)) return 'Edit Employee';
    if (RegExp(r'^/employees/[^/]+$').hasMatch(route)) return 'Employee Detail';
    if (RegExp(r'^/devices/[^/]+$').hasMatch(route)) return 'Device Detail';
    if (RegExp(r'^/settings/essl/[^/]+/history$').hasMatch(route)) return 'Sync History';
    if (RegExp(r'^/settings/essl/[^/]+/locations$').hasMatch(route)) return 'eSSL Locations';
    if (RegExp(r'^/settings/essl/[^/]+/initial-sync$').hasMatch(route)) return 'Initial Sync';
    if (RegExp(r'^/settings/essl/[^/]+/reprocess$').hasMatch(route)) return 'Reprocess';
    if (RegExp(r'^/settings/essl/[^/]+$').hasMatch(route)) return 'Edit eSSL Server';
    if (RegExp(r'^/school/students/[^/]+/edit$').hasMatch(route)) return 'Edit Student';
    if (RegExp(r'^/school/students/[^/]+$').hasMatch(route)) return 'Student Detail';
    // Fallback: capitalise last path segment, replace hyphens
    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Home';
    return parts.last
        .split('-')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '')
        .join(' ');
  }

  /// Builds a breadcrumb trail for a given route.
  static List<BreadcrumbEntry> breadcrumbsFor(String route) {
    final result = <BreadcrumbEntry>[
      const BreadcrumbEntry(label: 'Home', route: '/dashboard'),
    ];
    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    for (int i = 0; i < parts.length; i++) {
      final path = '/${parts.sublist(0, i + 1).join('/')}';
      result.add(BreadcrumbEntry(label: labelFor(path), route: path));
    }
    return result;
  }

  /// Returns the NavModule id that owns the given route.
  static String? moduleIdFor(String route) {
    for (final section in sections) {
      for (final module in section.modules) {
        if (module.rootRoute != null && route.startsWith(module.rootRoute!)) {
          return module.id;
        }
        for (final group in module.groups) {
          for (final leaf in group.items) {
            if (route == leaf.route || route.startsWith('${leaf.route}/')) {
              return module.id;
            }
          }
        }
      }
    }
    return null;
  }

  /// Returns the NavGroup id that owns the given route.
  static String? groupIdFor(String route) {
    for (final section in sections) {
      for (final module in section.modules) {
        for (final group in module.groups) {
          for (final leaf in group.items) {
            if (route == leaf.route || route.startsWith('${leaf.route}/')) {
              return group.id;
            }
          }
        }
      }
    }
    return null;
  }

  /// All leaf items flattened — used for sidebar search.
  static List<NavLeaf> get allLeaves =>
      sections.expand((s) => s.modules).expand((m) => m.groups).expand((g) => g.items).toList();

  /// Search leaves by query string (case-insensitive).
  static List<NavLeaf> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return allLeaves.where((l) => l.label.toLowerCase().contains(q)).toList();
  }
}
