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
    final padding = Responsive.contentPadding(context);

    return Scaffold(
      body: Column(
        children: [
          // Header with search and actions
          _buildHeader(context, isDark, padding),
          const Divider(height: 1),
          // Filters
          _buildFilters(context, departmentsAsync, isDark, padding),
          const Divider(height: 1),
          // Bulk actions bar
          if (_selectedEmployees.isNotEmpty) _buildBulkBar(),
          // Table
          Expanded(
            child: listState.employees.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return const ApexEmptyState(
                    icon: Icons.people_outline,
                    title: 'No Employees Found',
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
                    const Icon(Icons.error_outline, size: 48, color: ApexColors.error),
                    const SizedBox(height: 16),
                    Text('Error: ${err.toString()}'),
                    const SizedBox(height: 16),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/employees/create'),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, double padding) {
    return Container(
      padding: EdgeInsets.fromLTRB(padding, 16, padding, 12),
      color: isDark ? ApexColors.darkSurface : ApexColors.neutral0,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employees', style: ApexTypography.headingMedium.copyWith(
                  color: isDark ? ApexColors.darkOnSurface : ApexColors.neutral900,
                )),
                const SizedBox(height: 4),
                Text(
                  'Manage your workforce',
                  style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500),
                ),
              ],
            ),
          ),
          // Search
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, code, email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: ApexRadius.mdAll,
                  borderSide: BorderSide(color: ApexColors.neutral300),
                ),
                isDense: true,
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v);
                ref.read(employeeListProvider.notifier).setSearch(v);
              },
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          IconButton(
            icon: const Icon(Icons.domain, size: 20),
            tooltip: 'Departments',
            onPressed: () => context.push('/departments'),
          ),
          IconButton(
            icon: const Icon(Icons.store, size: 20),
            tooltip: 'Branches',
            onPressed: () => context.push('/branches'),
          ),
          IconButton(
            icon: const Icon(Icons.download, size: 20),
            tooltip: 'Export',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context, AsyncValue departmentsAsync, bool isDark, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: 8),
      color: isDark ? ApexColors.darkSurface : ApexColors.neutral50,
      child: Row(
        children: [
          departmentsAsync.maybeWhen(
            data: (deps) => _buildFilterChip(
              'Department',
              _departmentFilter != null
                  ? deps.firstWhere((d) => d.id == _departmentFilter, orElse: () => deps.first).name
                  : null,
              () => _showDepartmentPicker(deps),
            ),
            orElse: () => const SizedBox(),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            'Status',
            _statusFilter,
            () => _showStatusPicker(),
          ),
          if (_departmentFilter != null || _statusFilter != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _departmentFilter = null;
                  _statusFilter = null;
                });
                ref.read(employeeListProvider.notifier).clearFilters();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: ApexRadius.mdAll,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: value != null ? ApexColors.primary50 : null,
          border: Border.all(
            color: value != null ? ApexColors.primary : ApexColors.neutral300,
          ),
          borderRadius: ApexRadius.mdAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: ApexTypography.bodySmall.copyWith(
                color: value != null ? ApexColors.primary : ApexColors.neutral600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              value != null ? Icons.close : Icons.arrow_drop_down,
              size: 16,
              color: value != null ? ApexColors.primary : ApexColors.neutral500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ApexColors.primary50,
      child: Row(
        children: [
          Text('${_selectedEmployees.length} selected', style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
          const Spacer(),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export'),
          ),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_off, size: 18),
            label: const Text('Deactivate'),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedEmployees = {}),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<dynamic> employees, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1200),
        child: Column(
          children: [
            // Header
            Container(
              height: 44,
              color: isDark ? ApexColors.neutral800 : ApexColors.neutral50,
              child: Row(
                children: [
                  _buildHeaderCell(48, '', isDark),
                  _buildHeaderCell(200, 'Employee', isDark),
                  _buildHeaderCell(100, 'Code', isDark),
                  _buildHeaderCell(150, 'Department', isDark),
                  _buildHeaderCell(150, 'Designation', isDark),
                  _buildHeaderCell(120, 'Branch', isDark),
                  _buildHeaderCell(100, 'Status', isDark),
                  _buildHeaderCell(80, 'Actions', isDark),
                ],
              ),
            ),
            // Rows
            Expanded(
              child: ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final emp = employees[index];
                  final isSelected = _selectedEmployees.contains(emp.id);
                  return _buildRow(context, emp, isSelected, isDark, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(double width, String label, bool isDark) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          label,
          style: ApexTypography.captionLarge.copyWith(
            color: ApexColors.neutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, dynamic emp, bool isSelected, bool isDark, int index) {
    return InkWell(
      onTap: () => context.push('/employees/${emp.id}'),
      child: Container(
        height: 52,
        color: isSelected
            ? ApexColors.primary50
            : index.isEven
                ? (isDark ? ApexColors.darkSurface : ApexColors.neutral0)
                : (isDark ? ApexColors.neutral900 : ApexColors.neutral50),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedEmployees.add(emp.id);
                    } else {
                      _selectedEmployees.remove(emp.id);
                    }
                  });
                },
              ),
            ),
            SizedBox(
              width: 200,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                    child: emp.photoUrl == null
                        ? Text(emp.firstName[0].toUpperCase(), style: ApexTypography.captionLarge)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(emp.fullName, style: ApexTypography.titleSmall, overflow: TextOverflow.ellipsis),
                        if (emp.email != null)
                          Text(emp.email!, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 100, child: Text(emp.employeeCode, style: ApexTypography.bodySmall)),
            SizedBox(width: 150, child: Text(emp.departmentName ?? '—', style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 150, child: Text(emp.designationName ?? '—', style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 120, child: Text(emp.branchName ?? '—', style: ApexTypography.bodySmall, overflow: TextOverflow.ellipsis)),
            SizedBox(width: 100, child: ApexBadge(status: emp.status, category: 'employee')),
            SizedBox(
              width: 80,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View')),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'attendance', child: Text('Attendance')),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view': context.push('/employees/${emp.id}'); break;
                    case 'attendance': context.push('/attendance/detail?employeeId=${emp.id}'); break;
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDepartmentPicker(List<dynamic> departments) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Department'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: departments.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('All Departments'),
                  onTap: () {
                    setState(() => _departmentFilter = null);
                    ref.read(employeeListProvider.notifier).setFilter(departmentId: null);
                    Navigator.pop(context);
                  },
                );
              }
              final dept = departments[index - 1];
              return ListTile(
                title: Text(dept.name),
                onTap: () {
                  setState(() => _departmentFilter = dept.id);
                  ref.read(employeeListProvider.notifier).setFilter(departmentId: dept.id);
                  Navigator.pop(context);
                },
              );
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
        title: const Text('Select Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Statuses'),
              onTap: () {
                setState(() => _statusFilter = null);
                ref.read(employeeListProvider.notifier).setFilter(status: null);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Active'),
              onTap: () {
                setState(() => _statusFilter = 'active');
                ref.read(employeeListProvider.notifier).setFilter(status: 'active');
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Inactive'),
              onTap: () {
                setState(() => _statusFilter = 'inactive');
                ref.read(employeeListProvider.notifier).setFilter(status: 'inactive');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
