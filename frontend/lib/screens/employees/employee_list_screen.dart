import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_table.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_search_bar.dart';
import '../../design_system/components/apex_filter_bar.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../design_system/components/apex_button.dart';
import '../../providers/employee_provider.dart';

enum _ViewMode { table, grid }

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  _ViewMode _viewMode = _ViewMode.table;
  String _searchQuery = '';
  int _sortColumnIndex = 1;
  bool _sortAscending = true;
  Set<dynamic> _selectedEmployees = {};

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(employeeListProvider);
    final departmentsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);
    final padding = Responsive.contentPadding(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          // View toggle
          if (!Responsive.isMobile(context))
            SegmentedButton<_ViewMode>(
              segments: const [
                ButtonSegment(
                  value: _ViewMode.table,
                  icon: Icon(Icons.view_list, size: 18),
                  label: Text('Table'),
                ),
                ButtonSegment(
                  value: _ViewMode.grid,
                  icon: Icon(Icons.grid_view, size: 18),
                  label: Text('Cards'),
                ),
              ],
              selected: {_viewMode},
              onSelectionChanged: (value) => setState(() => _viewMode = value.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(borderRadius: ApexRadius.mdAll),
                ),
              ),
            ),
          if (!Responsive.isMobile(context)) const SizedBox(width: 8),
          // Actions
          IconButton(
            icon: const Icon(Icons.domain),
            tooltip: 'Departments',
            onPressed: () => context.push('/departments'),
          ),
          IconButton(
            icon: const Icon(Icons.store),
            tooltip: 'Branches',
            onPressed: () => context.push('/branches'),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export',
            onPressed: _exportEmployees,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                ApexSearchBar(
                  hintText: 'Search employees by name, code, email...',
                  onSearch: (val) {
                    setState(() => _searchQuery = val);
                    ref.read(employeeListProvider.notifier).setSearch(val);
                  },
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    ref.read(employeeListProvider.notifier).setSearch(val);
                  },
                ),
                const SizedBox(height: 12),
                _buildFilterBar(listState),
              ],
            ),
          ),
          const Divider(height: 1),

          // Bulk actions bar
          if (_selectedEmployees.isNotEmpty)
            _buildBulkActionsBar(),

          // Content
          Expanded(
            child: listState.employees.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return const ApexEmptyState(
                    icon: Icons.people_outline,
                    title: 'No Employees Found',
                    description: 'Try adjusting your filters or add a new employee.',
                    actionLabel: 'Add Employee',
                  );
                }
                return _viewMode == _ViewMode.table
                    ? _buildTableView(employees)
                    : _buildGridView(employees);
              },
              loading: () => ApexLoadingSkeleton(
                count: 8,
                type: _viewMode == _ViewMode.table
                    ? ApexSkeletonType.table
                    : ApexSkeletonType.list,
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: ApexColors.error),
                    const SizedBox(height: 16),
                    Text('Error: ${err.toString()}', style: ApexTypography.bodyMedium),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/employees/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar(dynamic listState) {
    final departmentsAsync = ref.watch(departmentsProvider);
    final branchesAsync = ref.watch(branchesProvider);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Department filter
          departmentsAsync.maybeWhen(
            data: (deps) => _buildDropdown(
              hint: 'Department',
              value: listState.departmentId,
              items: [
                const DropdownMenuItem(value: '', child: Text('All Departments')),
                ...deps.map((d) => DropdownMenuItem(value: d.id, child: Text(d.name))),
              ],
              onChanged: (val) {
                ref.read(employeeListProvider.notifier).setFilter(
                  departmentId: val == '' ? null : val,
                  branchId: listState.branchId,
                  status: listState.status,
                );
              },
            ),
            orElse: () => const SizedBox(),
          ),
          const SizedBox(width: 12),

          // Branch filter
          branchesAsync.maybeWhen(
            data: (branches) => _buildDropdown(
              hint: 'Branch',
              value: listState.branchId,
              items: [
                const DropdownMenuItem(value: '', child: Text('All Branches')),
                ...branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
              ],
              onChanged: (val) {
                ref.read(employeeListProvider.notifier).setFilter(
                  departmentId: listState.departmentId,
                  branchId: val == '' ? null : val,
                  status: listState.status,
                );
              },
            ),
            orElse: () => const SizedBox(),
          ),
          const SizedBox(width: 12),

          // Status filter
          _buildDropdown(
            hint: 'Status',
            value: listState.status ?? '',
            items: const [
              DropdownMenuItem(value: '', child: Text('All Statuses')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
            ],
            onChanged: (val) {
              ref.read(employeeListProvider.notifier).setFilter(
                departmentId: listState.departmentId,
                branchId: listState.branchId,
                status: val == '' ? null : val,
              );
            },
          ),

          // Clear filters
          if (listState.departmentId != null || listState.branchId != null || listState.status != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => ref.read(employeeListProvider.notifier).clearFilters(),
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: ApexColors.neutral200),
        borderRadius: ApexRadius.mdAll,
      ),
      child: DropdownButton<String>(
        value: value,
        hint: Text(hint, style: ApexTypography.bodySmall),
        underline: const SizedBox(),
        items: items,
        onChanged: onChanged,
        style: ApexTypography.bodySmall.copyWith(
          color: ApexColors.neutral700,
        ),
      ),
    );
  }

  Widget _buildBulkActionsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: ApexColors.primary50,
      child: Row(
        children: [
          Text(
            '${_selectedEmployees.length} selected',
            style: ApexTypography.titleMedium.copyWith(color: ApexColors.primary),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _bulkDeactivate,
            icon: const Icon(Icons.person_off, size: 18),
            label: const Text('Deactivate'),
          ),
          TextButton.icon(
            onPressed: _exportSelected,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Export'),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedEmployees = {}),
            child: const Text('Clear Selection'),
          ),
        ],
      ),
    );
  }

  Widget _buildTableView(List<dynamic> employees) {
    return ApexTable(
      columns: [
        ApexTableColumn(id: 'employee', label: 'Employee', width: 200),
        ApexTableColumn(id: 'code', label: 'Code', width: 100),
        ApexTableColumn(id: 'department', label: 'Department', width: 150),
        ApexTableColumn(id: 'designation', label: 'Designation', width: 150),
        ApexTableColumn(id: 'shift', label: 'Shift', width: 120),
        ApexTableColumn(id: 'status', label: 'Status', width: 100),
        ApexTableColumn(id: 'branch', label: 'Branch', width: 120),
        ApexTableColumn(id: 'actions', label: 'Actions', width: 80, sortable: false),
      ],
      data: employees,
      showCheckbox: true,
      selectedItems: _selectedEmployees,
      onSelectionChanged: (selected) => setState(() => _selectedEmployees = selected),
      onRowTap: (emp) => context.push('/employees/${emp.id}'),
      rowBuilder: (context, emp, index) {
        return Row(
          children: [
            // Employee name + avatar
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                      child: emp.photoUrl == null
                          ? Text(
                              emp.firstName[0].toUpperCase(),
                              style: ApexTypography.captionLarge,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.fullName,
                            style: ApexTypography.titleSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (emp.email != null)
                            Text(
                              emp.email!,
                              style: ApexTypography.captionSmall.copyWith(
                                color: ApexColors.neutral500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Code
            SizedBox(
              width: 100,
              child: Text(emp.employeeCode, style: ApexTypography.bodySmall),
            ),
            // Department
            SizedBox(
              width: 150,
              child: Text(
                emp.departmentName ?? '—',
                style: ApexTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Designation
            SizedBox(
              width: 150,
              child: Text(
                emp.designationName ?? '—',
                style: ApexTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Shift
            SizedBox(
              width: 120,
              child: Text(
                emp.shiftName ?? '—',
                style: ApexTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Status
            SizedBox(
              width: 100,
              child: ApexBadge(
                status: emp.status,
                category: 'employee',
              ),
            ),
            // Branch
            SizedBox(
              width: 120,
              child: Text(
                emp.branchName ?? '—',
                style: ApexTypography.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Actions
            SizedBox(
              width: 80,
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () => _showEmployeeActions(context, emp),
              ),
            ),
          ],
        );
      },
      emptyState: const ApexEmptyState(
        icon: Icons.people_outline,
        title: 'No Employees Found',
        description: 'Try adjusting your filters or add a new employee.',
        actionLabel: 'Add Employee',
      ),
    );
  }

  Widget _buildGridView(List<dynamic> employees) {
    final columns = Responsive.gridColumns(context);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 2.5,
      ),
      itemCount: employees.length,
      itemBuilder: (context, index) {
        final emp = employees[index];
        return _buildEmployeeCard(emp);
      },
    );
  }

  Widget _buildEmployeeCard(dynamic emp) {
    return InkWell(
      onTap: () => context.push('/employees/${emp.id}'),
      borderRadius: ApexRadius.lgAll,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: ApexColors.neutral200),
          borderRadius: ApexRadius.lgAll,
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
              child: emp.photoUrl == null
                  ? Text(emp.firstName[0].toUpperCase(), style: ApexTypography.titleMedium)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.fullName,
                    style: ApexTypography.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${emp.employeeCode} • ${emp.departmentName ?? 'No Department'}',
                    style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ApexBadge(status: emp.status, category: 'employee'),
          ],
        ),
      ),
    );
  }

  void _showEmployeeActions(BuildContext context, dynamic emp) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/employees/${emp.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('View Attendance'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/attendance/detail?employeeId=${emp.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_off, color: ApexColors.error),
                title: const Text('Deactivate', style: TextStyle(color: ApexColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Deactivate employee
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _exportEmployees() {
    // TODO: Implement export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon')),
    );
  }

  void _bulkDeactivate() {
    // TODO: Implement bulk deactivate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk deactivate feature coming soon')),
    );
  }

  void _exportSelected() {
    // TODO: Implement export selected
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export selected feature coming soon')),
    );
  }
}
