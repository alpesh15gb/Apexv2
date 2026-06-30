import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation_config.dart';
import '../core/responsive.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../providers/auth_provider.dart';
import '../providers/favorites_provider.dart';

// ─── Shell ────────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Sidebar state
  bool _sidebarExpanded = true;
  final Set<String> _expandedModules = {};
  final Set<String> _expandedGroups  = {};
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Recent routes (in-memory, last 6 unique)
  final List<String> _recentRoutes = [];

  // Scaffold key for mobile drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  String get _currentRoute => GoRouterState.of(context).matchedLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncExpansion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncExpansion();
    _trackRecent(_currentRoute);
  }

  void _syncExpansion() {
    final route = _currentRoute;
    final moduleId = NavigationConfig.moduleIdFor(route);
    final groupId  = NavigationConfig.groupIdFor(route);
    setState(() {
      if (moduleId != null) _expandedModules.add(moduleId);
      if (groupId  != null) _expandedGroups.add(groupId);
    });
  }

  void _trackRecent(String route) {
    const ignoredPrefixes = ['/splash', '/login', '/register', '/admin'];
    if (ignoredPrefixes.any((p) => route.startsWith(p))) return;
    _recentRoutes.remove(route);
    _recentRoutes.insert(0, route);
    if (_recentRoutes.length > 6) _recentRoutes.removeLast();
  }

  void _navigate(String route) {
    context.go(route);
    _trackRecent(route);
    // On mobile, close drawer after navigation
    if (Responsive.isMobile(context)) {
      Navigator.of(context, rootNavigator: false).pop();
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final userAsync = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // On tablet, collapse sidebar by default
    if (isTablet && _sidebarExpanded && !_explicitlyExpanded) {
      _sidebarExpanded = false;
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: false,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? ApexColors.darkBackground : ApexColors.neutral50,
        drawer: isMobile
            ? Drawer(
                width: 280,
                child: _SidebarContent(
                  expanded: true,
                  searchCtrl: _searchCtrl,
                  searchQuery: _searchQuery,
                  onSearchChanged: _onSearchChanged,
                  expandedModules: _expandedModules,
                  expandedGroups: _expandedGroups,
                  onToggleModule: _toggleModule,
                  onToggleGroup: _toggleGroup,
                  onNavigate: _navigate,
                  recentRoutes: _recentRoutes,
                  currentRoute: _currentRoute,
                  userAsync: userAsync,
                  onLogout: _logout,
                  isDark: isDark,
                ),
              )
            : null,
        body: Row(
          children: [
            // Permanent sidebar (tablet / desktop)
            if (!isMobile)
              _PermanentSidebar(
                expanded: _sidebarExpanded,
                onToggleExpand: _toggleSidebar,
                searchCtrl: _searchCtrl,
                searchQuery: _searchQuery,
                onSearchChanged: _onSearchChanged,
                expandedModules: _expandedModules,
                expandedGroups: _expandedGroups,
                onToggleModule: _toggleModule,
                onToggleGroup: _toggleGroup,
                onNavigate: _navigate,
                recentRoutes: _recentRoutes,
                currentRoute: _currentRoute,
                userAsync: userAsync,
                onLogout: _logout,
                isDark: isDark,
              ),
            // Main content
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    isMobile: isMobile,
                    currentRoute: _currentRoute,
                    userAsync: userAsync,
                    isDark: isDark,
                    onMenuTap: isMobile
                        ? () => _scaffoldKey.currentState?.openDrawer()
                        : null,
                    onLogout: _logout,
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Track whether the user explicitly expanded the sidebar (so we don't auto-
  // collapse it on every rebuild).
  bool _explicitlyExpanded = false;

  void _toggleSidebar() {
    setState(() {
      _sidebarExpanded = !_sidebarExpanded;
      _explicitlyExpanded = _sidebarExpanded;
    });
  }

  void _toggleModule(String id) {
    setState(() {
      if (_expandedModules.contains(id)) {
        _expandedModules.remove(id);
      } else {
        _expandedModules.add(id);
      }
    });
  }

  void _toggleGroup(String id) {
    setState(() {
      if (_expandedGroups.contains(id)) {
        _expandedGroups.remove(id);
      } else {
        _expandedGroups.add(id);
      }
    });
  }

  void _onSearchChanged(String q) => setState(() => _searchQuery = q);

  void _logout() {
    ref.read(authProvider.notifier).logout();
    context.go('/login');
  }

  void _handleKeyEvent(KeyEvent e) {
    // Ctrl+K or Cmd+K → focus sidebar search
    if (e is KeyDownEvent &&
        e.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      _searchCtrl.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchCtrl.text.length,
      );
      _searchCtrl.clear();
    }
  }
}

// ─── Permanent Sidebar Wrapper ────────────────────────────────────────────────

class _PermanentSidebar extends StatelessWidget {
  const _PermanentSidebar({
    required this.expanded,
    required this.onToggleExpand,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.expandedModules,
    required this.expandedGroups,
    required this.onToggleModule,
    required this.onToggleGroup,
    required this.onNavigate,
    required this.recentRoutes,
    required this.currentRoute,
    required this.userAsync,
    required this.onLogout,
    required this.isDark,
  });

  final bool expanded;
  final VoidCallback onToggleExpand;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Set<String> expandedModules;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleModule;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onNavigate;
  final List<String> recentRoutes;
  final String currentRoute;
  final AsyncValue userAsync;
  final VoidCallback onLogout;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: expanded ? 256 : 72,
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: Border(
          right: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: Column(
        children: [
          _SidebarLogo(expanded: expanded, isDark: isDark),
          const Divider(height: 1),
          Expanded(
            child: _SidebarContent(
              expanded: expanded,
              searchCtrl: searchCtrl,
              searchQuery: searchQuery,
              onSearchChanged: onSearchChanged,
              expandedModules: expandedModules,
              expandedGroups: expandedGroups,
              onToggleModule: onToggleModule,
              onToggleGroup: onToggleGroup,
              onNavigate: onNavigate,
              recentRoutes: recentRoutes,
              currentRoute: currentRoute,
              userAsync: userAsync,
              onLogout: onLogout,
              isDark: isDark,
            ),
          ),
          // Collapse toggle
          _CollapseButton(expanded: expanded, onTap: onToggleExpand, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Sidebar Logo ─────────────────────────────────────────────────────────────

class _SidebarLogo extends StatelessWidget {
  const _SidebarLogo({required this.expanded, required this.isDark});
  final bool expanded;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ApexColors.primary600, ApexColors.primary500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text('A', style: ApexTypography.captionMedium.copyWith(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
                )),
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apex HRMS', style: ApexTypography.titleMedium.copyWith(
                      color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                    )),
                    Text('Enterprise Edition', style: ApexTypography.captionSmall.copyWith(
                      color: ApexColors.neutral400,
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sidebar Content (shared between permanent & drawer) ─────────────────────

class _SidebarContent extends StatelessWidget {
  const _SidebarContent({
    required this.expanded,
    required this.searchCtrl,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.expandedModules,
    required this.expandedGroups,
    required this.onToggleModule,
    required this.onToggleGroup,
    required this.onNavigate,
    required this.recentRoutes,
    required this.currentRoute,
    required this.userAsync,
    required this.onLogout,
    required this.isDark,
  });

  final bool expanded;
  final TextEditingController searchCtrl;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final Set<String> expandedModules;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleModule;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onNavigate;
  final List<String> recentRoutes;
  final String currentRoute;
  final AsyncValue userAsync;
  final VoidCallback onLogout;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        if (expanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: TextField(
              controller: searchCtrl,
              onChanged: onSearchChanged,
              style: ApexTypography.body,
              decoration: InputDecoration(
                hintText: 'Search navigation...',
                hintStyle: ApexTypography.body.copyWith(color: ApexColors.neutral400),
                prefixIcon: const Icon(Icons.search, size: 16, color: ApexColors.neutral400),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                filled: true,
                fillColor: isDark ? ApexColors.darkSurfaceVariant : ApexColors.neutral50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: isDark ? ApexColors.neutral700 : ApexColors.neutral200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ApexColors.primary600, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ] else ...[
          const SizedBox(height: 8),
          // Collapsed: show search icon only
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Icon(Icons.search, size: 20,
              color: isDark ? ApexColors.neutral400 : ApexColors.neutral500),
          ),
        ],

        Expanded(
          child: SingleChildScrollView(
            child: searchQuery.isNotEmpty
                ? _SearchResults(
                    query: searchQuery,
                    currentRoute: currentRoute,
                    onNavigate: onNavigate,
                    isDark: isDark,
                  )
                : _FullNavTree(
                    expanded: expanded,
                    expandedModules: expandedModules,
                    expandedGroups: expandedGroups,
                    onToggleModule: onToggleModule,
                    onToggleGroup: onToggleGroup,
                    onNavigate: onNavigate,
                    recentRoutes: recentRoutes,
                    currentRoute: currentRoute,
                    isDark: isDark,
                  ),
          ),
        ),
        // User info
        _UserInfo(userAsync: userAsync, expanded: expanded, onLogout: onLogout, isDark: isDark),
      ],
    );
  }
}

// ─── Search Results ───────────────────────────────────────────────────────────

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.currentRoute,
    required this.onNavigate,
    required this.isDark,
  });
  final String query;
  final String currentRoute;
  final ValueChanged<String> onNavigate;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final results = NavigationConfig.search(query);
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('No results for "$query"',
          style: ApexTypography.caption.copyWith(color: ApexColors.neutral400)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text('${results.length} result${results.length == 1 ? '' : 's'}',
            style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400)),
        ),
        ...results.map((leaf) => _NavLeafTile(
          leaf: leaf,
          isActive: currentRoute == leaf.route,
          onTap: () => onNavigate(leaf.route),
          isDark: isDark,
          showLabel: true,
        )),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Full Navigation Tree ─────────────────────────────────────────────────────

class _FullNavTree extends ConsumerWidget {
  const _FullNavTree({
    required this.expanded,
    required this.expandedModules,
    required this.expandedGroups,
    required this.onToggleModule,
    required this.onToggleGroup,
    required this.onNavigate,
    required this.recentRoutes,
    required this.currentRoute,
    required this.isDark,
  });

  final bool expanded;
  final Set<String> expandedModules;
  final Set<String> expandedGroups;
  final ValueChanged<String> onToggleModule;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onNavigate;
  final List<String> recentRoutes;
  final String currentRoute;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Favorites Section
        if (expanded && favorites.isNotEmpty) ...[
          _SectionHeader(label: 'FAVORITES', isDark: isDark),
          ...favorites.map((route) {
            final label = NavigationConfig.labelFor(route);
            final leaf = NavigationConfig.allLeaves.firstWhere(
              (l) => l.route == route,
              orElse: () => NavLeaf(
                id: 'fav_$route',
                label: label,
                route: route,
                icon: Icons.star_border,
              ),
            );
            return _NavLeafTile(
              leaf: leaf,
              isActive: currentRoute == route,
              onTap: () => onNavigate(route),
              isDark: isDark,
              showLabel: expanded,
            );
          }),
          const Divider(height: 16, indent: 12, endIndent: 12),
        ],

        // Recently visited
        if (recentRoutes.isNotEmpty && expanded) ...[
          _SectionHeader(label: 'RECENT', isDark: isDark),
          ...recentRoutes.take(4).map((route) {
            final label = NavigationConfig.labelFor(route);
            return _NavLeafTile(
              leaf: NavLeaf(id: 'recent_$route', label: label, route: route,
                icon: Icons.history_outlined),
              isActive: currentRoute == route,
              onTap: () => onNavigate(route),
              isDark: isDark,
              showLabel: expanded,
            );
          }),
          const Divider(height: 16, indent: 12, endIndent: 12),
        ],

        // Nav sections
        for (final section in NavigationConfig.sections) ...[
          if (expanded)
            _SectionHeader(label: section.label, isDark: isDark),
          for (final module in section.modules)
            _ModuleTile(
              module: module,
              isExpanded: expandedModules.contains(module.id),
              expandedGroups: expandedGroups,
              currentRoute: currentRoute,
              sidebarExpanded: expanded,
              onToggleModule: () => onToggleModule(module.id),
              onToggleGroup: onToggleGroup,
              onNavigate: onNavigate,
              isDark: isDark,
            ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        label,
        style: ApexTypography.captionSmall.copyWith(
          color: isDark ? ApexColors.neutral600 : ApexColors.neutral400,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Module Tile (expandable) ─────────────────────────────────────────────────

class _ModuleTile extends StatelessWidget {
  const _ModuleTile({
    required this.module,
    required this.isExpanded,
    required this.expandedGroups,
    required this.currentRoute,
    required this.sidebarExpanded,
    required this.onToggleModule,
    required this.onToggleGroup,
    required this.onNavigate,
    required this.isDark,
  });

  final NavModule module;
  final bool isExpanded;
  final Set<String> expandedGroups;
  final String currentRoute;
  final bool sidebarExpanded;
  final VoidCallback onToggleModule;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<String> onNavigate;
  final bool isDark;

  bool get _isModuleActive {
    if (module.rootRoute != null && currentRoute.startsWith(module.rootRoute!)) return true;
    return module.allLeaves.any(
      (l) => currentRoute == l.route || currentRoute.startsWith('${l.route}/'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _isModuleActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              hoverColor: isDark ? Colors.white.withOpacity(0.06) : ApexColors.neutral100,
              onTap: () {
                if (!sidebarExpanded && module.rootRoute != null) {
                  onNavigate(module.rootRoute!);
                } else {
                  onToggleModule();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active ? (isDark ? Colors.white.withOpacity(0.10) : ApexColors.primary50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      active ? module.activeIcon : module.icon,
                      size: 18,
                      color: active
                          ? (isDark ? Colors.white : ApexColors.primary600)
                          : (isDark ? ApexColors.neutral400 : ApexColors.neutral500),
                    ),
                    if (sidebarExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          module.label,
                          style: ApexTypography.bodyMedium.copyWith(
                            color: active
                                ? (isDark ? Colors.white : ApexColors.primary600)
                                : (isDark ? ApexColors.darkOnSurface : ApexColors.neutral700),
                            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: isDark ? ApexColors.neutral500 : ApexColors.neutral400,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Sub-groups (when expanded)
          if (isExpanded && sidebarExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: module.groups.map((group) => _GroupTile(
                  group: group,
                  isExpanded: expandedGroups.contains(group.id),
                  currentRoute: currentRoute,
                  onToggle: () => onToggleGroup(group.id),
                  onNavigate: onNavigate,
                  isDark: isDark,
                )).toList(),
              ),
            ),

          // Collapsed sidebar: show all leaves as icon-only on hover
          // (We skip flyouts for simplicity; user can expand the sidebar)
        ],
      ),
    );
  }
}

// ─── Group Tile ───────────────────────────────────────────────────────────────

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.isExpanded,
    required this.currentRoute,
    required this.onToggle,
    required this.onNavigate,
    required this.isDark,
  });

  final NavGroup group;
  final bool isExpanded;
  final String currentRoute;
  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;
  final bool isDark;

  bool get _isGroupActive =>
      group.items.any((l) => currentRoute == l.route || currentRoute.startsWith('${l.route}/'));

  @override
  Widget build(BuildContext context) {
    final active = _isGroupActive;

    return Column(
      children: [
        // Group header
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            hoverColor: isDark ? Colors.white.withOpacity(0.05) : ApexColors.neutral100,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    group.icon,
                    size: 16,
                    color: active
                        ? (isDark ? Colors.white : ApexColors.primary600)
                        : (isDark ? ApexColors.neutral500 : ApexColors.neutral400),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      group.label,
                      style: ApexTypography.captionMedium.copyWith(
                        color: active
                            ? (isDark ? Colors.white : ApexColors.primary600)
                            : (isDark ? ApexColors.neutral400 : ApexColors.neutral500),
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      Icons.expand_more,
                      size: 14,
                      color: isDark ? ApexColors.neutral600 : ApexColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Leaf items
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              children: group.items.map((leaf) => _NavLeafTile(
                leaf: leaf,
                isActive: currentRoute == leaf.route ||
                    currentRoute.startsWith('${leaf.route}/'),
                onTap: () => onNavigate(leaf.route),
                isDark: isDark,
                showLabel: true,
              )).toList(),
            ),
          ),
      ],
    );
  }
}

// ─── Nav Leaf Tile ────────────────────────────────────────────────────────────

class _NavLeafTile extends StatelessWidget {
  const _NavLeafTile({
    required this.leaf,
    required this.isActive,
    required this.onTap,
    required this.isDark,
    required this.showLabel,
  });

  final NavLeaf leaf;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          hoverColor: isDark ? Colors.white.withOpacity(0.05) : ApexColors.neutral100,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isActive ? (isDark ? Colors.white.withOpacity(0.08) : ApexColors.primary50) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isActive ? Border.all(color: isDark ? Colors.white.withOpacity(0.15) : ApexColors.primary200) : null,
            ),
            child: Row(
              children: [
                if (leaf.icon != null)
                  Icon(
                    leaf.icon,
                    size: 16,
                    color: isActive
                        ? (isDark ? Colors.white : ApexColors.primary600)
                        : (isDark ? ApexColors.neutral500 : ApexColors.neutral400),
                  )
                else
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isActive ? (isDark ? Colors.white : ApexColors.primary600) : ApexColors.neutral300,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (showLabel) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      leaf.label,
                      style: ApexTypography.bodyMedium.copyWith(
                        color: isActive
                            ? (isDark ? Colors.white : ApexColors.primary600)
                            : (isDark ? ApexColors.darkOnSurface : ApexColors.neutral700),
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Collapse Button ──────────────────────────────────────────────────────────

class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.expanded, required this.onTap, required this.isDark});
  final bool expanded;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisAlignment: expanded ? MainAxisAlignment.end : MainAxisAlignment.center,
            children: [
              if (expanded)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('Collapse',
                    style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400)),
                ),
              Padding(
                padding: EdgeInsets.only(right: expanded ? 14 : 0),
                child: Icon(
                  expanded ? Icons.chevron_left : Icons.chevron_right,
                  size: 18,
                  color: ApexColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── User Info ────────────────────────────────────────────────────────────────

class _UserInfo extends StatelessWidget {
  const _UserInfo({
    required this.userAsync,
    required this.expanded,
    required this.onLogout,
    required this.isDark,
  });
  final AsyncValue userAsync;
  final bool expanded;
  final VoidCallback onLogout;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return userAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: ApexColors.primary100,
              child: Text(
                (user?.fullName ?? 'U').isNotEmpty
                    ? (user?.fullName ?? 'U')[0].toUpperCase()
                    : 'U',
                style: ApexTypography.captionSmall.copyWith(
                  color: ApexColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.fullName ?? 'User',
                      style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral400),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral400),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'profile', child: Text('My Profile')),
                  const PopupMenuItem(value: 'settings', child: Text('Settings')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'logout', child: Text('Logout')),
                ],
                onSelected: (v) {
                  if (v == 'logout') onLogout();
                  if (v == 'profile') GoRouter.of(context).go('/settings/company');
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
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends ConsumerWidget {
  const _TopBar({
    required this.isMobile,
    required this.currentRoute,
    required this.userAsync,
    required this.isDark,
    this.onMenuTap,
    required this.onLogout,
  });

  final bool isMobile;
  final String currentRoute;
  final AsyncValue userAsync;
  final bool isDark;
  final VoidCallback? onMenuTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: Border(
          bottom: BorderSide(color: isDark ? ApexColors.neutral800 : ApexColors.neutral200),
        ),
      ),
      child: Row(
        children: [
          // Mobile hamburger + logo
          if (isMobile) ...[
            IconButton(
              icon: const Icon(Icons.menu, size: 22),
              onPressed: onMenuTap,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36),
            ),
            const SizedBox(width: 8),
          ],

          // Page title from breadcrumb (last segment)
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    NavigationConfig.labelFor(currentRoute),
                    style: ApexTypography.titleMedium.copyWith(
                      color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    ref.watch(favoritesProvider).contains(currentRoute)
                        ? Icons.star
                        : Icons.star_border,
                    size: 20,
                    color: ref.watch(favoritesProvider).contains(currentRoute)
                        ? Colors.amber
                        : (isDark ? ApexColors.neutral400 : ApexColors.neutral500),
                  ),
                  onPressed: () => ref.read(favoritesProvider.notifier).toggleFavorite(currentRoute),
                  tooltip: ref.watch(favoritesProvider).contains(currentRoute)
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),

          // Right actions
          if (!isMobile) ...[
            _TopBarQuickCreate(isDark: isDark),
            const SizedBox(width: 4),
          ],
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => GoRouter.of(context).go('/settings/notifications'),
            tooltip: 'Notifications',
            color: isDark ? ApexColors.neutral400 : ApexColors.neutral500,
          ),
          if (!isMobile)
            _TopBarUserChip(userAsync: userAsync, onLogout: onLogout, isDark: isDark),
        ],
      ),
    );
  }
}

// ─── Top Bar: Quick Create ────────────────────────────────────────────────────

class _TopBarQuickCreate extends StatelessWidget {
  const _TopBarQuickCreate({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Quick Create',
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ApexColors.primary,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.add, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text('Create', style: ApexTypography.captionMedium.copyWith(color: Colors.white)),
        ]),
      ),
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'employee', child: ListTile(
          leading: Icon(Icons.person_add_outlined, size: 18),
          title: Text('New Employee'), dense: true, contentPadding: EdgeInsets.zero,
        )),
        PopupMenuItem(value: 'attendance', child: ListTile(
          leading: Icon(Icons.edit_calendar_outlined, size: 18),
          title: Text('Mark Attendance'), dense: true, contentPadding: EdgeInsets.zero,
        )),
        PopupMenuItem(value: 'leave', child: ListTile(
          leading: Icon(Icons.event_busy_outlined, size: 18),
          title: Text('Apply Leave'), dense: true, contentPadding: EdgeInsets.zero,
        )),
        PopupMenuItem(value: 'visitor', child: ListTile(
          leading: Icon(Icons.badge_outlined, size: 18),
          title: Text('Register Visitor'), dense: true, contentPadding: EdgeInsets.zero,
        )),
      ],
      onSelected: (v) {
        switch (v) {
          case 'employee':  GoRouter.of(context).go('/employees/create'); break;
          case 'attendance':GoRouter.of(context).go('/attendance/mark');  break;
          case 'leave':     GoRouter.of(context).go('/attendance/leave/requests'); break;
          case 'visitor':   GoRouter.of(context).go('/visitors');         break;
        }
      },
    );
  }
}

// ─── Top Bar: User Chip ───────────────────────────────────────────────────────

class _TopBarUserChip extends StatelessWidget {
  const _TopBarUserChip({required this.userAsync, required this.onLogout, required this.isDark});
  final AsyncValue userAsync;
  final VoidCallback onLogout;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return userAsync.when(
      data: (user) => PopupMenuButton<String>(
        tooltip: 'Account',
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: ApexColors.primary100,
              child: Text(
                (user?.fullName ?? 'U').isNotEmpty ? (user?.fullName ?? 'U')[0].toUpperCase() : 'U',
                style: ApexTypography.captionSmall.copyWith(
                  color: ApexColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),
        itemBuilder: (_) => [
          PopupMenuItem(enabled: false, child: Text(user?.fullName ?? 'User',
            style: ApexTypography.captionMedium.copyWith(fontWeight: FontWeight.w600))),
          const PopupMenuDivider(),
          const PopupMenuItem(value: 'logout', child: Text('Logout')),
        ],
        onSelected: (v) { if (v == 'logout') onLogout(); },
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
