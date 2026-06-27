import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../widgets/apex_app_bar.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      error: error,
      page: page ?? this.page,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      departmentFilter: departmentFilter ?? this.departmentFilter,
      branchFilter: branchFilter ?? this.branchFilter,
      statusFilter: statusFilter ?? this.statusFilter,
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
    state = state.copyWith(loading: true, error: null, page: page);
    try {
      final params = <String, dynamic>{'page': page, 'page_size': 20};
      if (state.search.isNotEmpty) params['search'] = state.search;
      if (state.departmentFilter != null) params['department_id'] = state.departmentFilter;
      if (state.branchFilter != null) params['branch_id'] = state.branchFilter;
      if (state.statusFilter != null) params['status'] = state.statusFilter;

      final res = await _dio.get('/employees/', queryParameters: params);
      final data = res.data;
      final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
      state = state.copyWith(
        employees: items,
        loading: false,
        total: data['total'] ?? 0,
        totalPages: data['total_pages'] ?? 1,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void setSearch(String v) {
    state = state.copyWith(search: v);
    fetch();
  }

  void setFilter({String? department, String? branch, String? status}) {
    state = state.copyWith(departmentFilter: department, branchFilter: branch, statusFilter: status);
    fetch();
  }

  void clearFilters() {
    state = state.copyWith(departmentFilter: null, branchFilter: null, statusFilter: null, search: '');
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
      backgroundColor: _bg,
      appBar: const ApexAppBar(title: 'Employee Directory'),
      body: Column(
        children: [
          _buildToolbar(dirState, isMobile),
          if (_selected.isNotEmpty) _buildBulkBar(),
          Expanded(
            child: dirState.loading && dirState.employees.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : dirState.error != null
                    ? Center(child: Text('Error: ${dirState.error}', style: const TextStyle(color: _danger)))
                    : dirState.employees.isEmpty
                        ? _buildEmptyState()
                        : dirState.viewMode == ViewMode.grid
                            ? _buildGridView(dirState)
                            : _buildTableView(dirState, isMobile),
          ),
          if (dirState.totalPages > 1) _buildPagination(dirState),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employees/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Employee'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildToolbar(EmployeeDirectoryState dirState, bool isMobile) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: _surface, border: Border(bottom: BorderSide(color: _border))),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, code, email, phone...',
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, size: 16), onPressed: () { _searchCtrl.clear(); ref.read(employeeDirectoryProvider.notifier).setSearch(''); })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => ref.read(employeeDirectoryProvider.notifier).setSearch(v),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 12),
            _filterChip('Department', dirState.departmentFilter, () => _showDepartmentFilter()),
            _filterChip('Branch', dirState.branchFilter, () => _showBranchFilter()),
            _filterChip('Status', dirState.statusFilter, () => _showStatusFilter()),
            if (dirState.departmentFilter != null || dirState.branchFilter != null || dirState.statusFilter != null)
              TextButton(onPressed: () => ref.read(employeeDirectoryProvider.notifier).clearFilters(), child: const Text('Clear')),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(Icons.grid_view, color: dirState.viewMode == ViewMode.grid ? _primary : _muted),
            onPressed: () => ref.read(employeeDirectoryProvider.notifier).setViewMode(ViewMode.grid),
          ),
          IconButton(
            icon: Icon(Icons.view_list, color: dirState.viewMode == ViewMode.table ? _primary : _muted),
            onPressed: () => ref.read(employeeDirectoryProvider.notifier).setViewMode(ViewMode.table),
          ),
          IconButton(icon: const Icon(Icons.download, color: _muted), onPressed: _exportEmployees),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String? value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(value ?? label, style: TextStyle(fontSize: 12, color: value != null ? _primary : _muted)),
        onSelected: (_) => onTap(),
        selected: value != null,
        selectedColor: _primary.withOpacity(0.1),
        side: BorderSide(color: value != null ? _primary : _border),
      ),
    );
  }

  Widget _buildBulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _primary.withOpacity(0.05),
      child: Row(children: [
        Text('${_selected.length} selected', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
        const Spacer(),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Export Selected')),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.email, size: 16), label: const Text('Send Email')),
        TextButton.icon(onPressed: () => setState(() => _selected.clear()), icon: const Icon(Icons.close, size: 16), label: const Text('Clear')),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: _muted.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No Employees Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          const Text('Add your first employee or adjust filters', style: TextStyle(fontSize: 13, color: _muted)),
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
        return SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: _surface,
                    child: Row(children: [
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
                      const SizedBox(width: 160, child: Text('EMPLOYEE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 120, child: Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 120, child: Text('DESIGNATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 100, child: Text('BRANCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 80, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 60),
                    ]),
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
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPagination(EmployeeDirectoryState dirState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(color: _surface, border: Border(top: BorderSide(color: _border))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${dirState.total} employees', style: const TextStyle(fontSize: 13, color: _muted)),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: dirState.page > 1 ? () => ref.read(employeeDirectoryProvider.notifier).fetch(page: dirState.page - 1) : null,
          ),
          Text('Page ${dirState.page} of ${dirState.totalPages}', style: const TextStyle(fontSize: 13, color: _text)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: dirState.page < dirState.totalPages ? () => ref.read(employeeDirectoryProvider.notifier).fetch(page: dirState.page + 1) : null,
          ),
        ],
      ),
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
      title: 'Select Branch',
      endpoint: '/employees/branches',
      onSelect: (id) => ref.read(employeeDirectoryProvider.notifier).setFilter(branch: id),
    ));
  }

  void _showStatusFilter() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Select Status'),
      children: ['active', 'inactive', 'terminated', 'on_leave'].map((s) => SimpleDialogOption(
        child: Text(s.toUpperCase()),
        onPressed: () { Navigator.pop(ctx); ref.read(employeeDirectoryProvider.notifier).setFilter(status: s); },
      )).toList(),
    ));
  }

  void _exportEmployees() {
    showDialog(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Export Employees'),
      children: [
        SimpleDialogOption(child: const Text('Export as Excel'), onPressed: () => Navigator.pop(ctx)),
        SimpleDialogOption(child: const Text('Export as PDF'), onPressed: () => Navigator.pop(ctx)),
        SimpleDialogOption(child: const Text('Export as CSV'), onPressed: () => Navigator.pop(ctx)),
      ],
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
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? _primary : _border, width: isSelected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: _primary.withOpacity(0.1),
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                const Spacer(),
                Checkbox(value: isSelected, onChanged: (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(code, style: const TextStyle(fontSize: 12, color: _muted)),
            const SizedBox(height: 8),
            Text(dept, style: const TextStyle(fontSize: 12, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(desig, style: const TextStyle(fontSize: 12, color: _muted), maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (status == 'active' ? _success : _muted).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'active' ? _success : _muted)),
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

  const _EmployeeTableRow({required this.employee, required this.isSelected, required this.onSelect, required this.onTap, required this.index});

  @override
  Widget build(BuildContext context) {
    final name = '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim();
    final code = employee['employee_code'] ?? '';
    final status = employee['status'] ?? 'active';

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: isSelected ? _primary.withOpacity(0.03) : (index.isEven ? _surface : _bg),
        child: Row(children: [
          SizedBox(width: 40, child: Checkbox(value: isSelected, onChanged: (v) => onSelect(v ?? false), visualDensity: VisualDensity.compact)),
          CircleAvatar(
            radius: 16,
            backgroundColor: _primary.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 14),
          SizedBox(width: 160, child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _text), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(code, style: const TextStyle(fontSize: 11, color: _muted)),
            ],
          )),
          SizedBox(width: 120, child: Text(employee['department_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 120, child: Text(employee['designation_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 100, child: Text(employee['branch_name'] ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 80,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (status == 'active' ? _success : _muted).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: status == 'active' ? _success : _muted)),
            ),
          ),
          SizedBox(
            width: 60,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 16, color: _muted),
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'view', child: Text('View Profile')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
              ],
              onSelected: (v) {
                if (v == 'view') onTap();
              },
            ),
          ),
        ]),
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(widget.endpoint, queryParameters: {'page': 1, 'page_size': 100});
      setState(() { _items = res.data['items'] ?? []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
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
                onPressed: () { widget.onSelect(null); Navigator.pop(context); },
              ),
              ..._items.map((item) => SimpleDialogOption(
                child: Text(item['name'] ?? item['code'] ?? ''),
                onPressed: () { widget.onSelect(item['id']); Navigator.pop(context); },
              )),
            ],
    );
  }
}
