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
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _setupKeyboardShortcuts();
  }

  void _setupKeyboardShortcuts() {
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
    showDialog(
      context: context,
      builder: (context) => const _CommandPalette(),
    );
  }

  String _getCurrentRoute() {
    return GoRouterState.of(context).matchedLocation;
  }

  bool _isActive(String path) {
    final route = _getCurrentRoute();
    return route == path || route.startsWith('$path/');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(userAsync),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isMobile, userAsync),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isMobile ? _buildBottomNav() : null,
    );
  }

  Widget _buildSidebar(AsyncValue userAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarExpanded ? 260 : 72,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1419) : const Color(0xFFFAFBFC),
        border: Border(
          right: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          _buildLogoArea(isDark),
          const Divider(height: 1),
          // Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildNavSection('MAIN', [
                    _NavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', '/dashboard'),
                    _NavItem(Icons.people_outline, Icons.people, 'Employees', '/employees'),
                    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance', '/attendance'),
                  ], isDark),
                  _buildNavSection('MANAGEMENT', [
                    _NavItem(Icons.schedule_outlined, Icons.schedule, 'Shifts', '/shifts'),
                    _NavItem(Icons.event_busy_outlined, Icons.event_busy, 'Leaves', '/leaves'),
                    _NavItem(Icons.card_membership_outlined, Icons.card_membership, 'Visitors', '/visitors'),
                  ], isDark),
                  _buildNavSection('OPERATIONS', [
                    _NavItem(Icons.biotech_outlined, Icons.biotech, 'Devices', '/devices'),
                    _NavItem(Icons.lock_outlined, Icons.lock, 'Access Control', '/access/zones'),
                    _NavItem(Icons.assessment_outlined, Icons.assessment, 'Reports', '/reports'),
                  ], isDark),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildNavItem(Icons.settings_outlined, Icons.settings, 'Settings', '/settings', isDark),
                ],
              ),
            ),
          ),
          // Collapse button
          _buildCollapseButton(isDark),
          // User info
          _buildUserInfo(userAsync, isDark),
        ],
      ),
    );
  }

  Widget _buildLogoArea(bool isDark) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [ApexColors.primary, Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: ApexRadius.mdAll,
              boxShadow: [
                BoxShadow(
                  color: ApexColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ),
          if (_sidebarExpanded) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Apex HRMS',
                    style: ApexTypography.titleLarge.copyWith(
                      color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Enterprise Platform',
                    style: ApexTypography.captionSmall.copyWith(
                      color: ApexColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavSection(String title, List<_NavItem> items, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_sidebarExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: ApexTypography.captionSmall.copyWith(
                color: ApexColors.neutral500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ...items.map((item) => _buildNavItem(item.icon, item.activeIcon, item.label, item.route, isDark)),
      ],
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, String route, bool isDark) {
    final isActive = _isActive(route);
    final index = label.hashCode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredIndex = index),
        onExit: (_) => setState(() => _hoveredIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive
                ? ApexColors.primary.withOpacity(0.1)
                : _hoveredIndex == index
                    ? (isDark ? ApexColors.neutral800 : ApexColors.neutral100)
                    : Colors.transparent,
            borderRadius: ApexRadius.mdAll,
          ),
          child: InkWell(
            onTap: () => context.go(route),
            borderRadius: ApexRadius.mdAll,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(
                    isActive ? activeIcon : icon,
                    size: 20,
                    color: isActive
                        ? ApexColors.primary
                        : isDark
                            ? ApexColors.neutral400
                            : ApexColors.neutral500,
                  ),
                  if (_sidebarExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        style: ApexTypography.bodyMedium.copyWith(
                          color: isActive
                              ? ApexColors.primary
                              : isDark
                                  ? ApexColors.darkOnSurface
                                  : ApexColors.neutral700,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: ApexColors.primary,
                          borderRadius: ApexRadius.xsAll,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapseButton(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
        child: Center(
          child: Icon(
            _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
            size: 20,
            color: ApexColors.neutral500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(AsyncValue userAsync, bool isDark) {
    return userAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: ApexColors.primary100,
              child: Text(
                (user?.fullName ?? 'U')[0].toUpperCase(),
                style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary),
              ),
            ),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.fullName ?? 'User',
                      style: ApexTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: ApexColors.neutral500),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'profile', child: Text('Profile')),
                  const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    ref.read(authProvider.notifier).logout();
                    context.go('/login');
                  } else if (value == 'settings') {
                    context.go('/settings');
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

  Widget _buildTopBar(BuildContext context, bool isMobile, AsyncValue userAsync) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final route = _getCurrentRoute();

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: Border(
          bottom: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ApexColors.primary, Color(0xFF3B82F6)],
                ),
                borderRadius: ApexRadius.mdAll,
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          // Breadcrumbs
          Expanded(child: _buildBreadcrumbs(route)),
          // Actions
          if (!isMobile) ...[
            // Search
            InkWell(
              onTap: _showCommandPalette,
              borderRadius: ApexRadius.mdAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? ApexColors.neutral800 : ApexColors.neutral100,
                  borderRadius: ApexRadius.mdAll,
                  border: Border.all(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16, color: ApexColors.neutral500),
                    const SizedBox(width: 8),
                    Text('Search...', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? ApexColors.neutral700 : ApexColors.neutral200,
                        borderRadius: ApexRadius.xsAll,
                      ),
                      child: Text('⌘K', style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Notifications
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 22),
              onPressed: () => context.push('/notifications'),
              tooltip: 'Notifications',
            ),
            const SizedBox(width: 4),
            // Quick Create
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: ApexColors.primary,
                  borderRadius: ApexRadius.mdAll,
                ),
                child: const Icon(Icons.add, size: 18, color: Colors.white),
              ),
              tooltip: 'Quick Create',
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'employee', child: Text('New Employee')),
                const PopupMenuItem(value: 'attendance', child: Text('Mark Attendance')),
                const PopupMenuItem(value: 'leave', child: Text('Apply Leave')),
                const PopupMenuItem(value: 'visitor', child: Text('Register Visitor')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'employee': context.push('/employees/create'); break;
                  case 'attendance': context.push('/attendance/mark'); break;
                  case 'leave': context.push('/leaves/apply'); break;
                  case 'visitor': context.push('/visitors/register'); break;
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(String route) {
    final parts = route.split('/').where((p) => p.isNotEmpty).toList();
    final items = <Widget>[
      InkWell(
        onTap: () => context.go('/dashboard'),
        child: Text('Home', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
      ),
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
              color: isLast
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? ApexColors.darkOnSurface
                      : ApexColors.neutral900)
                  : ApexColors.neutral500,
              fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    return Row(children: items);
  }

  Widget _buildBottomNav() {
    final route = _getCurrentRoute();
    int selectedIndex = 0;
    if (route.startsWith('/employees')) selectedIndex = 1;
    if (route.startsWith('/attendance')) selectedIndex = 2;
    if (route.startsWith('/leaves') || route.startsWith('/visitors') || route.startsWith('/devices')) selectedIndex = 3;

    return NavigationBar(
      selectedIndex: selectedIndex > 3 ? 3 : selectedIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0: context.go('/dashboard'); break;
          case 1: context.go('/employees'); break;
          case 2: context.go('/attendance'); break;
          case 3: _showMoreMenu(); break;
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
        NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Employees'),
        NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Attendance'),
        NavigationDestination(icon: Icon(Icons.more_horiz_outlined), selectedIcon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMoreItem(Icons.schedule, 'Shifts', () { Navigator.pop(context); context.go('/shifts'); }),
            _buildMoreItem(Icons.event_busy, 'Leaves', () { Navigator.pop(context); context.go('/leaves'); }),
            _buildMoreItem(Icons.card_membership, 'Visitors', () { Navigator.pop(context); context.go('/visitors'); }),
            _buildMoreItem(Icons.biotech, 'Devices', () { Navigator.pop(context); context.go('/devices'); }),
            _buildMoreItem(Icons.assessment, 'Reports', () { Navigator.pop(context); context.go('/reports'); }),
            _buildMoreItem(Icons.settings, 'Settings', () { Navigator.pop(context); context.go('/settings'); }),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(label), onTap: onTap);
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavItem(this.icon, this.activeIcon, this.label, this.route);
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
    {'label': 'Shifts', 'route': '/shifts', 'icon': Icons.schedule},
    {'label': 'Leaves', 'route': '/leaves', 'icon': Icons.event_busy},
    {'label': 'Visitors', 'route': '/visitors', 'icon': Icons.card_membership},
    {'label': 'Devices', 'route': '/devices', 'icon': Icons.biotech},
    {'label': 'Reports', 'route': '/reports', 'icon': Icons.assessment},
    {'label': 'Settings', 'route': '/settings', 'icon': Icons.settings},
    {'label': 'Add Employee', 'route': '/employees/create', 'icon': Icons.person_add},
    {'label': 'Mark Attendance', 'route': '/attendance/mark', 'icon': Icons.add_task},
    {'label': 'Apply Leave', 'route': '/leaves/apply', 'icon': Icons.event_busy},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _commands
        : _commands.where((c) => c['label'].toString().toLowerCase().contains(_query.toLowerCase())).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: ApexRadius.xlAll),
      child: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 400),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search commands...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final cmd = filtered[index];
                  return ListTile(
                    leading: Icon(cmd['icon'] as IconData, size: 20),
                    title: Text(cmd['label'] as String),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(cmd['route'] as String);
                    },
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
