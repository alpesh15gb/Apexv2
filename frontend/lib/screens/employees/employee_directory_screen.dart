import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../widgets/page_wrapper.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

enum ViewMode { grid, table }

final employeeDirectoryProvider = StateNotifierProvider<EmployeeDirectoryNotifier, EmployeeDirectoryState>((ref) {
  return EmployeeDirectoryNotifier(ref.read(dioProvider));
});

class EmployeeDirectoryState {
  final List<Map<String, dynamic>> employees;
  final bool loading;
  final String? error;
  final int page;
  final int total;
  final int totalPages;
  final String search;
  final String? departmentFilter;
  final String? branchFilter;
  final String? statusFilter;
  final ViewMode viewMode;

  EmployeeDirectoryState({
    this.employees = const [],
    this.loading = false,
    this.error,
    this.page = 1,
    this.total = 0,
    this.totalPages = 1,
    this.search = '',
    this.departmentFilter,
    this.branchFilter,
    this.statusFilter,
    this.viewMode = ViewMode.table,
  });

  EmployeeDirectoryState copyWith({
    List<Map<String, dynamic>>? employees,
    bool? loading,
    String? error,
    int? page,
    int? total,
    int? totalPages,
    String? search,
    String? departmentFilter,
    String? branchFilter,
    String? statusFilter,
    ViewMode? viewMode,
  }) {
    return EmployeeDirectoryState(
      employees: employees ?? this.employees,
      loading: loading ?? this.loading,
      error: error ?? this.error,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      departmentFilter: departmentFilter != null ? departmentFilter : (departmentFilter == null && this.departmentFilter != null ? this.departmentFilter : null),
      branchFilter: branchFilter != null ? branchFilter : (branchFilter == null && this.branchFilter != null ? this.branchFilter : null),
      statusFilter: statusFilter != null ? statusFilter : (statusFilter == null && this.statusFilter != null ? this.statusFilter : null),
      viewMode: viewMode ?? this.viewMode,
    );
  }
}

class EmployeeDirectoryNotifier extends StateNotifier<EmployeeDirectoryState> {
  final dynamic _dio;
  EmployeeDirectoryNotifier(this._dio) : super(EmployeeDirectoryState()) {
    fetch();
  }

  Future<void> fetch({int page = 1}) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final query = {
        'page': page,
        'page_size': 12,
        'search': state.search,
      };
      if (state.departmentFilter != null) query['department_id'] = state.departmentFilter!;
      if (state.branchFilter != null) query['branch_id'] = state.branchFilter!;
      if (state.statusFilter != null) query['status'] = state.statusFilter!;

      final res = await _dio.get('/employees/', queryParameters: query);
      final items = res.data['items'] as List;
      state = state.copyWith(
        employees: items.map((e) => Map<String, dynamic>.from(e)).toList(),
        loading: false,
        page: res.data['page'] ?? page,
        total: res.data['total'] ?? items.length,
        totalPages: res.data['pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String search) {
    state = EmployeeDirectoryState(
      search: search,
      viewMode: state.viewMode,
      departmentFilter: state.departmentFilter,
      branchFilter: state.branchFilter,
      statusFilter: state.statusFilter,
    );
    fetch();
  }

  void setFilter({String? department, String? branch, String? status}) {
    state = EmployeeDirectoryState(
      search: state.search,
      viewMode: state.viewMode,
      departmentFilter: department ?? state.departmentFilter,
      branchFilter: branch ?? state.branchFilter,
      statusFilter: status ?? state.statusFilter,
    );
    fetch();
  }

  void clearFilters() {
    state = EmployeeDirectoryState(
      search: state.search,
      viewMode: state.viewMode,
    );
    fetch();
  }

  void setViewMode(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }
}

class EmployeeDirectoryScreen extends ConsumerStatefulWidget {
  const EmployeeDirectoryScreen({super.key});

  @override
  ConsumerState<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends ConsumerState<EmployeeDirectoryScreen> {
  final _searchCtrl = TextEditingController();
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final dirState = ref.watch(employeeDirectoryProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: ApexPageWrapper(
        title: 'Employee List',
        description: 'Directory of all organizational employees and contractors.',
        showSearch: true,
        searchHint: 'Search employees...',
        searchController: _searchCtrl,
        onSearch: (v) => ref.read(employeeDirectoryProvider.notifier).setSearch(v),
        onRefresh: () => ref.read(employeeDirectoryProvider.notifier).fetch(page: dirState.page),
        onExport: () {},
        actions: [
          IconButton(
            icon: Icon(Icons.grid_view, color: dirState.viewMode == ViewMode.grid ? ApexColors.primary : ApexColors.neutral500),
            onPressed: () => ref.read(employeeDirectoryProvider.notifier).setViewMode(ViewMode.grid),
            tooltip: 'Grid view',
          ),
          IconButton(
            icon: Icon(Icons.view_list, color: dirState.viewMode == ViewMode.table ? ApexColors.primary : ApexColors.neutral500),
            onPressed: () => ref.read(employeeDirectoryProvider.notifier).setViewMode(ViewMode.table),
            tooltip: 'Table view',
          ),
          const SizedBox(width: 4),
          ApexButton(
            label: 'Add Employee',
            onPressed: () => context.push('/employees/create'),
            type: ApexButtonType.primary,
            icon: Icons.person_add_outlined,
          ),
        ],
        filterBar: _buildFilterBar(dirState, isMobile),
        isLoading: dirState.loading && dirState.employees.isEmpty,
        error: dirState.error,
        onRetry: () => ref.read(employeeDirectoryProvider.notifier).fetch(page: dirState.page),
        isEmpty: dirState.employees.isEmpty,
        emptyIcon: Icons.people_outline,
        emptyTitle: 'No Employees Found',
        emptySubtitle: 'Add your first employee or adjust filters.',
        pagination: dirState.totalPages > 1
            ? ApexPaginationBar(
                page: dirState.page,
                totalPages: dirState.totalPages,
                total: dirState.total,
                pageSize: 12,
                onPageChanged: (page) => ref.read(employeeDirectoryProvider.notifier).fetch(page: page),
              )
            : null,
        body: Column(
          children: [
            if (_selected.isNotEmpty) _buildBulkBar(),
            Expanded(
              child: dirState.viewMode == ViewMode.grid
                  ? _buildGridView(dirState)
                  : _buildTableView(dirState, isMobile),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(EmployeeDirectoryState dirState, bool isMobile) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _filterChip('Department', dirState.departmentFilter, () => _showDepartmentFilter()),
          _filterChip('Location', dirState.branchFilter, () => _showBranchFilter()),
          _filterChip('Status', dirState.statusFilter, () => _showStatusFilter()),
          if (dirState.departmentFilter != null || dirState.branchFilter != null || dirState.statusFilter != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => ref.read(employeeDirectoryProvider.notifier).clearFilters(),
              child: const Text('Clear Filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(value ?? label, style: ApexTypography.captionMedium.copyWith(color: value != null ? ApexColors.primary : ApexColors.neutral500)),
        onSelected: (_) => onTap(),
        selected: value != null,
        selectedColor: ApexColors.primary.withOpacity(0.1),
        side: BorderSide(color: value != null ? ApexColors.primary : ApexColors.neutral200),
      ),
    );
  }

  Widget _buildBulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      color: ApexColors.primary.withOpacity(0.05),
      child: Row(
        children: [
          Text('${_selected.length} selected', style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.primary)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _selected.clear()),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(EmployeeDirectoryState dirState) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.isDesktop(context) ? 4 : (Responsive.isTablet(context) ? 2 : 1),
        childAspectRatio: 1.4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: dirState.employees.length,
      itemBuilder: (context, i) => _EmployeeGridCard(
        employee: dirState.employees[i],
        isSelected: _selected.contains(dirState.employees[i]['id']),
        onSelect: (v) => setState(() {
          if (v) _selected.add(dirState.employees[i]['id']);
          else _selected.remove(dirState.employees[i]['id']);
        }),
        onTap: () => context.push('/employees/${dirState.employees[i]['id']}'),
      ),
    );
  }

  Widget _buildTableView(EmployeeDirectoryState dirState, bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        return SingleChildScrollView(
          child: SizedBox(
            width: availableWidth,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  color: Colors.white,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Checkbox(
                          value: _selected.length == dirState.employees.length && dirState.employees.isNotEmpty,
                          onChanged: (v) => setState(() {
                            if (v == true) _selected.addAll(dirState.employees.map((e) => e['id'] as String));
                            else _selected.clear();
                          }),
                        ),
                      ),
                      const SizedBox(width: 50),
                      SizedBox(
                        width: availableWidth * 0.18,
                        child: Text('EMPLOYEE', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('DEPARTMENT', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('DESIGNATION', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('BRANCH', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5)),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text('STATUS', style: ApexTypography.captionSmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral500, letterSpacing: 0.5)),
                      ),
                      const SizedBox(width: 60),
                    ],
                  ),
                ),
                ...List.generate(dirState.employees.length, (i) {
                  final emp = dirState.employees[i];
                  return _EmployeeTableRow(
                    employee: emp,
                    isSelected: _selected.contains(emp['id']),
                    onSelect: (v) => setState(() {
                      if (v) _selected.add(emp['id']);
                      else _selected.remove(emp['id']);
                    }),
                    onTap: () => context.push('/employees/${emp['id']}'),
                    index: i,
                    employeeWidth: availableWidth * 0.18,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDepartmentFilter() {
    showDialog(context: context, builder: (ctx) => _FilterDialog(
      title: 'Select Department',
      endpoint: '/employees/departments',
      onSelect: (id) => ref.read(employeeDirectoryProvider.notifier).setFilter(department: id),
    ));
  }

  void _showBranchFilter() {
    showDialog(context: context, builder: (ctx) => _FilterDialog(
      title: 'Select Location',
      endpoint: '/employees/branches',
      onSelect: (id) => ref.read(employeeDirectoryProvider.notifier).setFilter(branch: id),
    ));
  }

  void _showStatusFilter() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Select Status'),
      children: ['active', 'inactive', 'terminated', 'on_leave'].map((s) => SimpleDialogOption(
        child: Text(s.toUpperCase()),
        onPressed: () {
          Navigator.pop(ctx);
          ref.read(employeeDirectoryProvider.notifier).setFilter(status: s);
        },
      )).toList(),
    ));
  }
}

class _EmployeeGridCard extends StatelessWidget {
  final Map<String, dynamic> employee;
  final bool isSelected;
  final Function(bool) onSelect;
  final VoidCallback onTap;

  const _EmployeeGridCard({required this.employee, required this.isSelected, required this.onSelect, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final code = employee['employee_code'] ?? '';
    final dept = employee['department_name'] ?? '—';
    final desig = employee['designation_name'] ?? '—';
    final status = employee['status'] ?? 'active';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? ApexColors.primary : ApexColors.neutral200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: ApexColors.primary.withOpacity(0.1),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: ApexTypography.body.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Checkbox(value: isSelected, onChanged: (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 12),
            Text(name, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(code, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500)),
            const SizedBox(height: 8),
            Text(dept, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(desig, style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (status == 'active' ? ApexColors.success : ApexColors.neutral500).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status.toUpperCase(), style: ApexTypography.badge.copyWith(fontSize: 10, color: status == 'active' ? ApexColors.success : ApexColors.neutral500)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeTableRow extends StatelessWidget {
  final Map<String, dynamic> employee;
  final bool isSelected;
  final Function(bool) onSelect;
  final VoidCallback onTap;
  final int index;
  final double employeeWidth;

  const _EmployeeTableRow({required this.employee, required this.isSelected, required this.onSelect, required this.onTap, required this.index, this.employeeWidth = 160});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final code = employee['employee_code'] ?? '';
    final status = employee['status'] ?? 'active';

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: isSelected ? ApexColors.primary.withOpacity(0.03) : (index.isEven ? Colors.white : ApexColors.neutral50),
        child: Row(
          children: [
            SizedBox(width: 40, child: Checkbox(value: isSelected, onChanged: (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact)),
            CircleAvatar(
              radius: 16,
              backgroundColor: ApexColors.primary.withOpacity(0.1),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: employeeWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: ApexTypography.caption.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(code, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                ],
              ),
            ),
            Expanded(flex: 2, child: Text(employee['department_name'] ?? '—', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(employee['designation_name'] ?? '—', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900), overflow: TextOverflow.ellipsis)),
            Expanded(flex: 2, child: Text(employee['branch_name'] ?? '—', style: ApexTypography.caption.copyWith(color: ApexColors.neutral900), overflow: TextOverflow.ellipsis)),
            SizedBox(
              width: 80,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (status == 'active' ? ApexColors.success : ApexColors.neutral500).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status.toUpperCase(), style: ApexTypography.badge.copyWith(fontSize: 10, color: status == 'active' ? ApexColors.success : ApexColors.neutral500)),
              ),
            ),
            SizedBox(
              width: 60,
              child: PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 16, color: ApexColors.neutral500),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'view', child: Text('View Profile')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
                ],
                onSelected: (v) {
                  if (v == 'view') onTap();
                  if (v == 'edit') context.push('/employees/${employee['id']}/edit');
                  if (v == 'attendance') context.push('/attendance/detail?employeeId=${employee['id']}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDialog extends ConsumerStatefulWidget {
  final String title;
  final String endpoint;
  final Function(String?) onSelect;

  const _FilterDialog({required this.title, required this.endpoint, required this.onSelect});

  @override
  ConsumerState<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends ConsumerState<_FilterDialog> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(widget.endpoint, queryParameters: {'page': 1, 'page_size': 100});
      setState(() {
        _items = res.data['items'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text(widget.title),
      children: _loading
          ? [const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))]
          : [
              SimpleDialogOption(
                child: const Text('All'),
                onPressed: () {
                  widget.onSelect(null);
                  Navigator.pop(context);
                },
              ),
              ..._items.map((item) => SimpleDialogOption(
                    child: Text(item['name'] ?? item['code'] ?? ''),
                    onPressed: () {
                      widget.onSelect(item['id']);
                      Navigator.pop(context);
                    },
                  )),
            ],
    );
  }
}
