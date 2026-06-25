import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../providers/employee_provider.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _searchQuery = '';
  String? _departmentFilter;
  String? _statusFilter;
  Set<dynamic> _selectedEmployees = {};

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(employeeListProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = Responsive.isMobile(context) ? 16.0 : 24.0;

    return Scaffold(
      body: Column(
        children: [
          // Compact header
          _buildHeader(context, isDark, padding),
          // Filter chips
          _buildFilters(context, departmentsAsync, isDark, padding),
          // Bulk bar
          if (_selectedEmployees.isNotEmpty) _buildBulkBar(),
          // Table
          Expanded(
            child: listState.employees.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return const ApexEmptyState(
                    icon: Icons.people_outline,
                    title: 'No Employees',
                    description: 'Add your first employee or import from eSSL.',
                    actionLabel: 'Add Employee',
                  );
                }
                return _buildTable(context, employees, isDark);
              },
              loading: () => const ApexLoadingSkeleton(count: 10, type: ApexSkeletonType.table),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                    const SizedBox(height: 12),
                    Text('Error: ${err.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(employeeListProvider.notifier).fetchEmployees(isRefresh: true),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/employees/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double padding) {
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 8),
      decoration: BoxDecoration(
        color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
        border: const Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Text('Employees', style: ApexTypography.pageTitle.copyWith(
            color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
          )),
          const Spacer(),
          // Search
          SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: ApexRadius.smAll,
                  borderSide: const BorderSide(color: ApexColors.neutral300),
                ),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                ref.read(employeeListProvider.notifier).setSearch(v);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.download, size: 18), tooltip: 'Export', onPressed: () {}),
          IconButton(icon: const Icon(Icons.domain, size: 18), tooltip: 'Departments', onPressed: () => context.push('/departments')),
          IconButton(icon: const Icon(Icons.store, size: 18), tooltip: 'Branches', onPressed: () => context.push('/branches')),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, AsyncValue departmentsAsync, bool isDark, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 6),
      color: isDark ? ApexColors.neutral900 : ApexColors.neutral50,
      child: Row(
        children: [
          departmentsAsync.maybeWhen(
            data: (deps) => _buildChip('Department', _departmentFilter != null
                ? deps.firstWhere((d) => d.id == _departmentFilter, orElse: () => deps.first).name
                : null, () => _showDeptPicker(deps)),
            orElse: () => const SizedBox(),
          ),
          const SizedBox(width: 8),
          _buildChip('Status', _statusFilter, () => _showStatusPicker()),
          if (_departmentFilter != null || _statusFilter != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() { _departmentFilter = null; _statusFilter = null; });
                ref.read(employeeListProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear'),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ApexRadius.smAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: value != null ? ApexColors.primary50 : null,
          border: Border.all(color: value != null ? ApexColors.primary : ApexColors.neutral300),
          borderRadius: ApexRadius.smAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: ApexTypography.captionLarge.copyWith(
              color: value != null ? ApexColors.primary : ApexColors.neutral600,
            )),
            const SizedBox(width: 4),
            Icon(value != null ? Icons.close : Icons.arrow_drop_down, size: 14,
              color: value != null ? ApexColors.primary : ApexColors.neutral500),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: ApexColors.primary50,
      child: Row(
        children: [
          Text('${_selectedEmployees.length} selected', style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
          const Spacer(),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Export')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.person_off, size: 16), label: const Text('Deactivate')),
          TextButton(onPressed: () => setState(() => _selectedEmployees = {}), child: const Text('Clear')),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> employees, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1100),
        child: Column(
          children: [
            // Header
            Container(
              height: 36,
              color: isDark ? ApexColors.neutral800 : ApexColors.neutral50,
              child: Row(
                children: [
                  _buildHdr(40, ''),
                  _buildHdr(200, 'EMPLOYEE'),
                  _buildHdr(90, 'CODE'),
                  _buildHdr(130, 'DEPARTMENT'),
                  _buildHdr(130, 'DESIGNATION'),
                  _buildHdr(110, 'BRANCH'),
                  _buildHdr(90, 'STATUS'),
                  _buildHdr(70, 'ACTIONS'),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, i) => _buildRow(context, employees[i], i, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHdr(double w, String label) {
    return SizedBox(
      width: w,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(label, style: ApexTypography.tableHeader),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, dynamic emp, int index, bool isDark) {
    final isSelected = _selectedEmployees.contains(emp.id);
    return InkWell(
      onTap: () => context.push('/employees/${emp.id}'),
      child: Container(
        height: 44,
        color: isSelected
            ? ApexColors.primary50
            : index.isEven
                ? (isDark ? ApexColors.darkSurface : ApexColors.neutral0)
                : (isDark ? ApexColors.neutral900 : const Color(0xFFFAFBFC)),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => setState(() {
                  v == true ? _selectedEmployees.add(emp.id) : _selectedEmployees.remove(emp.id);
                }),
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                    child: emp.photoUrl == null ? Text(emp.firstName[0].toUpperCase(), style: ApexTypography.captionSmall) : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp.fullName, style: ApexTypography.tableCell.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                        if (emp.email != null)
                          Text(emp.email!, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 90, child: Text(emp.employeeCode, style: ApexTypography.tableCell)),
            SizedBox(width: 130, child: Text(emp.departmentName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 130, child: Text(emp.designationName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 110, child: Text(emp.branchName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 90, child: ApexBadge(status: emp.status, category: 'employee')),
            SizedBox(
              width: 70,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
                ],
                onSelected: (v) {
                  if (v == 'view') context.push('/employees/${emp.id}');
                  if (v == 'attendance') context.push('/attendance/detail?employeeId=${emp.id}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeptPicker(List<dynamic> deps) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Department'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: deps.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return ListTile(title: const Text('All'), onTap: () {
                setState(() => _departmentFilter = null);
                ref.read(employeeListProvider.notifier).setFilter(departmentId: null);
                Navigator.pop(context);
              });
              final d = deps[i - 1];
              return ListTile(title: Text(d.name), onTap: () {
                setState(() => _departmentFilter = d.id);
                ref.read(employeeListProvider.notifier).setFilter(departmentId: d.id);
                Navigator.pop(context);
              });
            },
          ),
        ),
      ),
    );
  }

  void _showStatusPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('All'), onTap: () {
              setState(() => _statusFilter = null);
              ref.read(employeeListProvider.notifier).setFilter(status: null);
              Navigator.pop(context);
            }),
            ListTile(title: const Text('Active'), onTap: () {
              setState(() => _statusFilter = 'active');
              ref.read(employeeListProvider.notifier).setFilter(status: 'active');
              Navigator.pop(context);
            }),
            ListTile(title: const Text('Inactive'), onTap: () {
              setState(() => _statusFilter = 'inactive');
              ref.read(employeeListProvider.notifier).setFilter(status: 'inactive');
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }
}
