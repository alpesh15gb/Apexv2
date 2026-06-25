import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/responsive.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/spacing.dart';
import '../design_system/border_radius.dart';
import '../design_system/components/apex_search_bar.dart';
import '../design_system/components/apex_breadcrumb.dart';
import '../services/websocket_service.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({Key? key, required this.child}) : super(key: key);

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _sidebarExpanded = true;
  bool _searchOpen = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    ref.read(webSocketServiceProvider).connect();
    _setupKeyboardShortcuts();
  }

  @override
  void dispose() {
    ref.read(webSocketServiceProvider).disconnect();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    // Cmd+K / Ctrl+K for search
    HardwareKeyboard.instance.addHandler((event) {
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.keyK) &&
          (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
        setState(() => _searchOpen = true);
        _searchFocusNode.requestFocus();
        return true;
      }
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() => _searchOpen = false);
        _searchController.clear();
        return true;
      }
      return false;
    });
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/employees')) return 1;
    if (location.startsWith('/attendance')) return 2;
    if (location.startsWith('/shifts')) return 3;
    if (location.startsWith('/leaves')) return 4;
    if (location.startsWith('/visitors')) return 5;
    if (location.startsWith('/devices')) return 6;
    if (location.startsWith('/access')) return 7;
    if (location.startsWith('/reports')) return 8;
    if (location.startsWith('/settings')) return 9;
    return 0;
  }

  void _onNavItemTap(int index, BuildContext context) {
    switch (index) {
      case 0: context.go('/dashboard'); break;
      case 1: context.go('/employees'); break;
      case 2: context.go('/attendance'); break;
      case 3: context.go('/shifts'); break;
      case 4: context.go('/leaves'); break;
      case 5: context.go('/visitors'); break;
      case 6: context.go('/devices'); break;
      case 7: context.go('/access/zones'); break;
      case 8: context.go('/reports'); break;
      case 9: context.go('/settings'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar (desktop/tablet only)
          if (!isMobile) _buildSidebar(selectedIndex),
          // Main content
          Expanded(
            child: Column(
              children: [
                _buildAppBar(context, isMobile),
                if (_searchOpen) _buildSearchOverlay(context),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
      // Bottom navigation (mobile only)
      bottomNavigationBar: isMobile ? _buildBottomNav(selectedIndex) : null,
    );
  }

  Widget _buildSidebar(int selectedIndex) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarExpanded ? 240 : 64,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ApexColors.darkSurface
            : ApexColors.neutral0,
        border: const Border(
          right: BorderSide(color: ApexColors.neutral200),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ApexColors.primary,
                    borderRadius: ApexRadius.mdAll,
                  ),
                  child: const Center(
                    child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
                if (_sidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Apex HRMS',
                      style: ApexTypography.headingSmall.copyWith(
                        color: ApexColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', selectedIndex),
                _buildNavItem(1, Icons.people_outline, Icons.people, 'Employees', selectedIndex),
                _buildNavItem(2, Icons.calendar_today_outlined, Icons.calendar_today, 'Attendance', selectedIndex),
                _buildNavItem(3, Icons.schedule_outlined, Icons.schedule, 'Shifts', selectedIndex),
                _buildNavItem(4, Icons.event_busy_outlined, Icons.event_busy, 'Leaves', selectedIndex),
                _buildNavItem(5, Icons.card_membership_outlined, Icons.card_membership, 'Visitors', selectedIndex),
                _buildNavItem(6, Icons.biotech_outlined, Icons.biotech, 'Devices', selectedIndex),
                _buildNavItem(7, Icons.lock_outlined, Icons.lock, 'Access Control', selectedIndex),
                _buildNavItem(8, Icons.assessment_outlined, Icons.assessment, 'Reports', selectedIndex),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Divider(height: 1),
                ),
                _buildNavItem(9, Icons.settings_outlined, Icons.settings, 'Settings', selectedIndex),
              ],
            ),
          ),
          // Collapse button
          const Divider(height: 1),
          InkWell(
            onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: _sidebarExpanded
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.center,
                children: [
                  if (_sidebarExpanded)
                    Text(
                      'Collapse',
                      style: ApexTypography.bodySmall.copyWith(
                        color: ApexColors.neutral500,
                      ),
                    ),
                  Icon(
                    _sidebarExpanded ? Icons.chevron_left : Icons.chevron_right,
                    size: 20,
                    color: ApexColors.neutral500,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData selectedIcon, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: InkWell(
        onTap: () => _onNavItemTap(index, context),
        borderRadius: ApexRadius.mdAll,
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? ApexColors.primary50
                : Colors.transparent,
            borderRadius: ApexRadius.mdAll,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? selectedIcon : icon,
                size: 20,
                color: isSelected
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
                      color: isSelected
                          ? ApexColors.primary
                          : isDark
                              ? ApexColors.darkOnSurface
                              : ApexColors.neutral700,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isMobile) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: const Border(
          bottom: BorderSide(color: ApexColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          if (isMobile)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ApexColors.primary,
                borderRadius: ApexRadius.mdAll,
              ),
              child: const Center(
                child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          if (isMobile) const SizedBox(width: 12),
          // Breadcrumbs
          Expanded(
            child: _buildBreadcrumbs(context),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            onPressed: () {
              setState(() => _searchOpen = true);
              _searchFocusNode.requestFocus();
            },
            tooltip: 'Search (⌘K)',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          // User avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ApexColors.primary100,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, size: 18, color: ApexColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final items = <ApexBreadcrumbItem>[
      const ApexBreadcrumbItem(label: 'Home', onTap: null),
    ];

    if (location.startsWith('/dashboard')) {
      items.add(const ApexBreadcrumbItem(label: 'Dashboard'));
    } else if (location.startsWith('/employees')) {
      items.add(ApexBreadcrumbItem(label: 'Employees', onTap: () => context.go('/employees')));
      if (location.contains('/create')) {
        items.add(const ApexBreadcrumbItem(label: 'Create'));
      } else if (location.contains('/')) {
        items.add(const ApexBreadcrumbItem(label: 'Details'));
      }
    } else if (location.startsWith('/attendance')) {
      items.add(ApexBreadcrumbItem(label: 'Attendance', onTap: () => context.go('/attendance')));
    } else if (location.startsWith('/settings')) {
      items.add(ApexBreadcrumbItem(label: 'Settings', onTap: () => context.go('/settings')));
    }

    return ApexBreadcrumb(items: items);
  }

  Widget _buildSearchOverlay(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          width: 600,
          margin: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: ApexRadius.xlAll,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ApexSearchBar(
                  controller: _searchController,
                  hintText: 'Search employees, devices, reports...',
                  onSearch: (value) {
                    // TODO: Implement global search
                    setState(() => _searchOpen = false);
                  },
                  onChanged: (value) {
                    // TODO: Implement search suggestions
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Quick Actions', style: ApexTypography.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickAction(Icons.person_add, 'Add Employee', () {
                          setState(() => _searchOpen = false);
                          context.push('/employees/create');
                        }),
                        _buildQuickAction(Icons.calendar_today, 'Mark Attendance', () {
                          setState(() => _searchOpen = false);
                          context.push('/attendance/mark');
                        }),
                        _buildQuickAction(Icons.event_busy, 'Apply Leave', () {
                          setState(() => _searchOpen = false);
                          context.push('/leaves/apply');
                        }),
                        _buildQuickAction(Icons.assessment, 'Reports', () {
                          setState(() => _searchOpen = false);
                          context.push('/reports');
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ApexRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: ApexColors.neutral200),
          borderRadius: ApexRadius.mdAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: ApexColors.primary),
            const SizedBox(width: 8),
            Text(label, style: ApexTypography.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(int selectedIndex) {
    return NavigationBar(
      selectedIndex: selectedIndex > 3 ? 3 : selectedIndex,
      onDestinationSelected: (index) {
        if (index == 3) {
          // Show more menu
          _showMoreMenu(context);
        } else {
          _onNavItemTap(index, context);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Employees',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_today_outlined),
          selectedIcon: Icon(Icons.calendar_today),
          label: 'Attendance',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz_outlined),
          selectedIcon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoreItem(Icons.schedule, 'Shifts', () {
                Navigator.pop(context);
                context.go('/shifts');
              }),
              _buildMoreItem(Icons.event_busy, 'Leaves', () {
                Navigator.pop(context);
                context.go('/leaves');
              }),
              _buildMoreItem(Icons.card_membership, 'Visitors', () {
                Navigator.pop(context);
                context.go('/visitors');
              }),
              _buildMoreItem(Icons.biotech, 'Devices', () {
                Navigator.pop(context);
                context.go('/devices');
              }),
              _buildMoreItem(Icons.lock, 'Access Control', () {
                Navigator.pop(context);
                context.go('/access/zones');
              }),
              _buildMoreItem(Icons.assessment, 'Reports', () {
                Navigator.pop(context);
                context.go('/reports');
              }),
              _buildMoreItem(Icons.settings, 'Settings', () {
                Navigator.pop(context);
                context.go('/settings');
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoreItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
