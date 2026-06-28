import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/border_radius.dart';
import '../providers/auth_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler((event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.keyK) &&
          (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
        _showCommandPalette();
        return true;
      }
      return false;
    });
  }

  void _showCommandPalette() {
    showDialog(context: context, builder: (context) => const _CommandPalette());
  }

  String _currentRoute() => GoRouterState.of(context).matchedLocation;
  bool _isActive(String path) => _currentRoute() == path || _currentRoute().startsWith('$path/');

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final userAsync = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(userAsync, isDark),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isMobile, userAsync, isDark),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  Widget _buildSidebar(AsyncValue userAsync, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarExpanded ? 240 : 64,
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkBackground : ApexColors.neutral50,
        border: Border(right: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200)),
      ),
      child: Column(
        children: [
          _buildLogo(isDark),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authProvider);
                  final user = authState.value;
                  final isSchool = user?.isSchool ?? false;

                  return Column(
                    children: [
                      _navSection('WORKSPACE', [
                        _nav(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', '/dashboard'),
                        _nav(Icons.people_outline, Icons.people, 'Employees', '/employees'),
                        _nav(Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance', '/attendance'),
                      ], isDark),
                      _navSection('MANAGEMENT', [
                        _nav(Icons.event_busy_outlined, Icons.event_busy, 'Leave', '/leaves'),
                        _nav(Icons.calendar_month_outlined, Icons.calendar_month, 'Holidays', '/holidays'),
                        _nav(Icons.card_membership_outlined, Icons.card_membership, 'Visitors', '/visitors'),
                        _nav(Icons.campaign_outlined, Icons.campaign, 'Announcements', '/announcements'),
                        _nav(Icons.exit_to_app_outlined, Icons.exit_to_app, 'Exit Requests', '/exit-requests'),
                      ], isDark),
                      if (!isSchool) ...[
                        _navSection('OPERATIONS', [
                          _nav(Icons.schedule_outlined, Icons.schedule, 'Shifts', '/shifts'),
                          _nav(Icons.biotech_outlined, Icons.biotech, 'Devices', '/devices'),
                          _nav(Icons.directions_walk_outlined, Icons.directions_walk, 'Outdoor Duty', '/attendance/outdoor-duty'),
                          _nav(Icons.access_time_filled_outlined, Icons.access_time_filled, 'OT Register', '/attendance/ot'),
                          _nav(Icons.flight_outlined, Icons.flight, 'Travel', '/travel'),
                          _nav(Icons.inventory_2_outlined, Icons.inventory_2, 'Assets', '/assets'),
                          _nav(Icons.assessment_outlined, Icons.assessment, 'Reports', '/reports'),
                        ], isDark),
                        _navSection('FINANCE', [
                          _nav(Icons.payments_outlined, Icons.payments, 'Payroll', '/payroll'),
                          _nav(Icons.receipt_long_outlined, Icons.receipt_long, 'Expenses', '/expenses'),
                          _nav(Icons.folder_outlined, Icons.folder, 'Documents', '/documents'),
                        ], isDark),
                      ],
                      if (isSchool) ...[
                        _navSection('SCHOOL', [
                          _nav(Icons.school_outlined, Icons.school, 'School Dashboard', '/school/dashboard'),
                          _nav(Icons.person_search_outlined, Icons.person_search, 'Students', '/school/students'),
                          _nav(Icons.app_registration_outlined, Icons.app_registration, 'Admissions', '/school/admissions'),
                          _nav(Icons.fact_check_outlined, Icons.fact_check, 'Attendance', '/school/attendance/mark'),
                          _nav(Icons.schedule_outlined, Icons.schedule, 'Timetable', '/school/timetable'),
                          _nav(Icons.assignment_outlined, Icons.assignment, 'Homework', '/school/homework'),
                          _nav(Icons.quiz_outlined, Icons.quiz, 'Examinations', '/school/exams'),
                          _nav(Icons.payment_outlined, Icons.payment, 'Fee Collection', '/school/fees'),
                          _nav(Icons.directions_bus_outlined, Icons.directions_bus, 'Transport', '/school/transport'),
                          _nav(Icons.home_work_outlined, Icons.home_work, 'Hostel', '/school/hostel'),
                          _nav(Icons.library_books_outlined, Icons.library_books, 'Library', '/school/library'),
                          _nav(Icons.class_outlined, Icons.class_, 'Classes', '/school/classes'),
                          _nav(Icons.calendar_month_outlined, Icons.calendar_month, 'Academic Year', '/school/academic-years'),
                        ], isDark),
                      ],
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _nav(Icons.settings_outlined, Icons.settings, 'Administration', '/settings', isDark),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildCollapseBtn(isDark),
          _buildUserInfo(userAsync, isDark),
        ],
      ),
    );
  }

  Widget _buildLogo(bool isDark) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 32,
            height: 32,
            fit: BoxFit.contain,
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 10),
            Text('Apex HRMS', style: ApexTypography.titleMedium.copyWith(
              color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
            )),
          ],
        ],
      ),
    );
  }

  Widget _navSection(String title, List<Widget> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sidebarExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title, style: ApexTypography.captionSmall.copyWith(
              color: ApexColors.neutral500, letterSpacing: 1.2,
            )),
          ),
        ...items,
      ],
    );
  }

  Widget _nav(IconData icon, IconData activeIcon, String label, String route, [bool? isDark]) {
    final isActive = _isActive(route);
    final dark = isDark ?? Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: InkWell(
        onTap: () => context.go(route),
        borderRadius: ApexRadius.smAll,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive ? ApexColors.primary.withOpacity(0.1) : null,
            borderRadius: ApexRadius.smAll,
          ),
          child: Row(
            children: [
              Icon(isActive ? activeIcon : icon, size: 18,
                color: isActive ? ApexColors.primary : (dark ? ApexColors.neutral400 : ApexColors.neutral500)),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 10),
                Expanded(child: Text(label, style: ApexTypography.bodyMedium.copyWith(
                  color: isActive ? ApexColors.primary : (dark ? ApexColors.darkOnSurface : ApexColors.neutral700),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ))),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseBtn(bool isDark) {
    return Container(
      height: 40,
      decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200))),
      child: InkWell(
        onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
        child: Center(child: Icon(_sidebarExpanded ? Icons.chevron_left : Icons.chevron_right, size: 18, color: ApexColors.neutral500)),
      ),
    );
  }

  Widget _buildUserInfo(AsyncValue userAsync, bool isDark) {
    return userAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200))),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: ApexColors.primary100,
              child: Text((user?.fullName ?? 'U')[0].toUpperCase(), style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary)),
            ),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(user?.fullName ?? 'User', style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                    Text(user?.email ?? '', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
                onSelected: (v) {
                  if (v == 'logout') {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  }
                },
              ),
            ],
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isMobile, AsyncValue userAsync, bool isDark) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: Border(bottom: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [ApexColors.primary, ApexColors.primary500]),
                borderRadius: ApexRadius.smAll,
              ),
              child: Center(child: Text('A', style: ApexTypography.captionMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(child: _buildBreadcrumbs()),
          if (!isMobile) ...[
            InkWell(
              onTap: _showCommandPalette,
              borderRadius: ApexRadius.smAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? ApexColors.neutral800 : ApexColors.neutral100,
                  borderRadius: ApexRadius.smAll,
                  border: Border.all(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 14, color: ApexColors.neutral500),
                    const SizedBox(width: 6),
                    Text('Search...', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200, borderRadius: ApexRadius.xsAll),
                      child: Text('⌘K', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.notifications_outlined, size: 20), onPressed: () => context.push('/notifications'), tooltip: 'Notifications'),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: ApexColors.primary, borderRadius: ApexRadius.smAll),
                child: const Icon(Icons.add, size: 16, color: Colors.white),
              ),
              tooltip: 'Quick Create',
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'employee', child: Text('New Employee')),
                const PopupMenuItem(value: 'attendance', child: Text('Mark Attendance')),
                const PopupMenuItem(value: 'leave', child: Text('Apply Leave')),
              ],
              onSelected: (v) {
                if (v == 'employee') context.push('/employees/create');
                if (v == 'attendance') context.push('/attendance/mark');
                if (v == 'leave') context.push('/leaves/apply');
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    final route = _currentRoute();
    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    final items = <Widget>[
      InkWell(onTap: () => context.go('/dashboard'), child: Text('Home', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500))),
    ];
    for (int i = 0; i < parts.length; i++) {
      items.add(Icon(Icons.chevron_right, size: 14, color: ApexColors.neutral400));
      final path = '/${parts.sublist(0, i + 1).join('/')}';
      final isLast = i == parts.length - 1;
      items.add(
        InkWell(
          onTap: isLast ? null : () => context.go(path),
          child: Text(
            parts[i][0].toUpperCase() + parts[i].substring(1),
            style: ApexTypography.bodySmall.copyWith(
              color: isLast ? (Theme.of(context).brightness == Brightness.dark ? ApexColors.darkOnSurface : ApexColors.neutral900) : ApexColors.neutral500,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }
    return Row(children: items);
  }

  Widget _buildBottomNav() {
    final route = _currentRoute();
    final authState = ref.read(authProvider);
    final user = authState.value;
    final isSchool = user?.isSchool ?? false;

    int idx = 0;
    if (isSchool) {
      if (route.startsWith('/school/students')) idx = 1;
      if (route.startsWith('/school/attendance')) idx = 2;
      if (route.startsWith('/school/exams')) idx = 3;
    } else {
      if (route.startsWith('/employees')) idx = 1;
      if (route.startsWith('/attendance')) idx = 2;
      if (route.startsWith('/leaves')) idx = 3;
    }

    final destinations = isSchool
        ? const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Students'),
            NavigationDestination(icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Attendance'),
            NavigationDestination(icon: Icon(Icons.quiz_outlined), selectedIcon: Icon(Icons.quiz), label: 'Exams'),
            NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
          ]
        : const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Employees'),
            NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Attendance'),
            NavigationDestination(icon: Icon(Icons.event_busy_outlined), selectedIcon: Icon(Icons.event_busy), label: 'Leave'),
            NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
          ];

    return NavigationBar(
      selectedIndex: idx > 4 ? 4 : idx,
      onDestinationSelected: (i) {
        if (isSchool) {
          if (i == 0) context.go('/dashboard');
          if (i == 1) context.go('/school/students');
          if (i == 2) context.go('/school/attendance/mark');
          if (i == 3) context.go('/school/exams');
          if (i == 4) _showMoreMenu();
        } else {
          if (i == 0) context.go('/dashboard');
          if (i == 1) context.go('/employees');
          if (i == 2) context.go('/attendance');
          if (i == 3) context.go('/leaves');
          if (i == 4) _showMoreMenu();
        }
      },
      destinations: destinations,
    );
  }

  void _showMoreMenu() {
    final authState = ref.read(authProvider);
    final user = authState.value;
    final isSchool = user?.isSchool ?? false;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (isSchool) ...[
            ListTile(leading: const Icon(Icons.payment), title: const Text('Fees'), onTap: () { Navigator.pop(context); context.go('/school/fees'); }),
            ListTile(leading: const Icon(Icons.directions_bus), title: const Text('Transport'), onTap: () { Navigator.pop(context); context.go('/school/transport'); }),
            ListTile(leading: const Icon(Icons.home_work), title: const Text('Hostel'), onTap: () { Navigator.pop(context); context.go('/school/hostel'); }),
            ListTile(leading: const Icon(Icons.library_books), title: const Text('Library'), onTap: () { Navigator.pop(context); context.go('/school/library'); }),
            ListTile(leading: const Icon(Icons.schedule), title: const Text('Timetable'), onTap: () { Navigator.pop(context); context.go('/school/timetable'); }),
            ListTile(leading: const Icon(Icons.assignment), title: const Text('Homework'), onTap: () { Navigator.pop(context); context.go('/school/homework'); }),
            ListTile(leading: const Icon(Icons.app_registration), title: const Text('Admissions'), onTap: () { Navigator.pop(context); context.go('/school/admissions'); }),
            ListTile(leading: const Icon(Icons.class_), title: const Text('Classes'), onTap: () { Navigator.pop(context); context.go('/school/classes'); }),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Academic Year'), onTap: () { Navigator.pop(context); context.go('/school/academic-years'); }),
          ] else ...[
            ListTile(leading: const Icon(Icons.event_busy), title: const Text('Leave'), onTap: () { Navigator.pop(context); context.go('/leaves'); }),
            ListTile(leading: const Icon(Icons.card_membership), title: const Text('Visitors'), onTap: () { Navigator.pop(context); context.go('/visitors'); }),
            ListTile(leading: const Icon(Icons.biotech), title: const Text('Devices'), onTap: () { Navigator.pop(context); context.go('/devices'); }),
            ListTile(leading: const Icon(Icons.schedule), title: const Text('Shifts'), onTap: () { Navigator.pop(context); context.go('/shifts'); }),
            ListTile(leading: const Icon(Icons.payments), title: const Text('Payroll'), onTap: () { Navigator.pop(context); context.go('/payroll'); }),
            ListTile(leading: const Icon(Icons.assessment), title: const Text('Reports'), onTap: () { Navigator.pop(context); context.go('/reports'); }),
          ],
          const Divider(),
          ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () { Navigator.pop(context); context.go('/settings'); }),
          ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: () { Navigator.pop(context); ref.read(authProvider.notifier).logout(); context.go('/login'); }),
        ]),
      ),
    );
  }
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette();
  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final _controller = TextEditingController();
  String _query = '';
  final _commands = [
    {'label': 'Dashboard', 'route': '/dashboard', 'icon': Icons.dashboard},
    {'label': 'Employees', 'route': '/employees', 'icon': Icons.people},
    {'label': 'Attendance', 'route': '/attendance', 'icon': Icons.calendar_today},
    {'label': 'Leave', 'route': '/leaves', 'icon': Icons.event_busy},
    {'label': 'Visitors', 'route': '/visitors', 'icon': Icons.card_membership},
    {'label': 'Devices', 'route': '/devices', 'icon': Icons.biotech},
    {'label': 'Reports', 'route': '/reports', 'icon': Icons.assessment},
    {'label': 'Administration', 'route': '/settings', 'icon': Icons.settings},
    {'label': 'Add Employee', 'route': '/employees/create', 'icon': Icons.person_add},
    {'label': 'Mark Attendance', 'route': '/attendance/mark', 'icon': Icons.add_task},
    {'label': 'Apply Leave', 'route': '/leaves/apply', 'icon': Icons.event_busy},
    // School ERP
    {'label': 'School Dashboard', 'route': '/school/dashboard', 'icon': Icons.school},
    {'label': 'Students', 'route': '/school/students', 'icon': Icons.person_search},
    {'label': 'Mark Student Attendance', 'route': '/school/attendance/mark', 'icon': Icons.fact_check},
    {'label': 'Homework', 'route': '/school/homework', 'icon': Icons.assignment},
    {'label': 'Examinations', 'route': '/school/exams', 'icon': Icons.quiz},
    {'label': 'Fee Collection', 'route': '/school/fees', 'icon': Icons.payment},
    {'label': 'Transport', 'route': '/school/transport', 'icon': Icons.directions_bus},
    {'label': 'Hostel', 'route': '/school/hostel', 'icon': Icons.home_work},
    {'label': 'Library', 'route': '/school/library', 'icon': Icons.library_books},
    {'label': 'Timetable', 'route': '/school/timetable', 'icon': Icons.schedule},
    {'label': 'Admissions', 'route': '/school/admissions', 'icon': Icons.app_registration},
    {'label': 'Classes & Sections', 'route': '/school/classes', 'icon': Icons.class_},
    {'label': 'Academic Years', 'route': '/school/academic-years', 'icon': Icons.calendar_month},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty ? _commands : _commands.where((c) => c['label'].toString().toLowerCase().contains(_query.toLowerCase())).toList();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.lgAll),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 360),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Search commands...', prefixIcon: Icon(Icons.search), border: InputBorder.none),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final cmd = filtered[i];
                  return ListTile(
                    leading: Icon(cmd['icon'] as IconData, size: 18),
                    title: Text(cmd['label'] as String, style: ApexTypography.bodyMedium),
                    dense: true,
                    onTap: () { Navigator.pop(context); context.go(cmd['route'] as String); },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
