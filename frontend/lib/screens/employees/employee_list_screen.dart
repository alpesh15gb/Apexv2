import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  String _search = '';
  String? _deptFilter;
  String? _statusFilter;
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(employeeListProvider);
    final deptsAsync = ref.watch(departmentsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          _Header(isMobile: isMobile),
          _Toolbar(
            search: _search,
            onSearch: (v) {
              setState(() => _search = v);
              ref.read(employeeListProvider.notifier).setSearch(v);
            },
            deptFilter: _deptFilter,
            statusFilter: _statusFilter,
            onDeptChanged: (v) {
              setState(() => _deptFilter = v);
              ref.read(employeeListProvider.notifier).setFilter(departmentId: v);
            },
            onStatusChanged: (v) {
              setState(() => _statusFilter = v);
              ref.read(employeeListProvider.notifier).setFilter(status: v);
            },
            onClear: () {
              setState(() { _deptFilter = null; _statusFilter = null; });
              ref.read(employeeListProvider.notifier).clearFilters();
            },
            deptsAsync: deptsAsync,
          ),
          if (_selected.isNotEmpty) _BulkBar(count: _selected.length, onClear: () => setState(() => _selected.clear())),
          Expanded(
            child: listState.employees.when(
              data: (employees) {
                if (employees.isEmpty) {
                  return _EmptyState(
                    icon: Icons.people_outline,
                    title: 'No Employees',
                    description: 'Import employees from eSSL or add manually.',
                    actionLabel: 'Add Employee',
                    onAction: () => context.push('/employees/create'),
                  );
                }
                return Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: ApexColors.neutral200, width: 1)),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 50),
                      Expanded(flex: 3, child: Text('EMPLOYEE', style: ApexTypography.tableHeader)),
                      Expanded(flex: 2, child: Text('DEPARTMENT', style: ApexTypography.tableHeader)),
                      Expanded(flex: 2, child: Text('DESIGNATION', style: ApexTypography.tableHeader)),
                      Expanded(child: Text('BRANCH', style: ApexTypography.tableHeader)),
                      SizedBox(width: 70, child: Text('STATUS', style: ApexTypography.tableHeader)),
                      const SizedBox(width: 40),
                    ]),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: employees.length,
                      itemBuilder: (context, i) {
                        final emp = employees[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: i.isEven ? Colors.white : ApexColors.neutral50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => context.push('/employees/${emp.id}'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: ApexColors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '?',
                                    style: TextStyle(color: ApexColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(flex: 3, child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.fullName, style: ApexTypography.body.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
                                    const SizedBox(height: 2),
                                    Text(emp.employeeCode, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
                                  ],
                                )),
                                Expanded(flex: 2, child: Text(emp.departmentName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 2, child: Text(emp.designationName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
                                Expanded(child: Text(emp.branchName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis)),
                                emp.status == 'active' ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE'),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward_ios, size: 14, color: ApexColors.neutral500),
                                  onPressed: () => context.push('/employees/${emp.id}'),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
              },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                        const SizedBox(height: 12),
                        Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                        const SizedBox(height: 12),
                        ApexButton(
                          label: 'Retry',
                          onPressed: () => ref.read(employeeListProvider.notifier).fetchEmployees(isRefresh: true),
                          type: ApexButtonType.primary,
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
        backgroundColor: ApexColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 12, isMobile ? 16 : 20, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Text('Employees', style: ApexTypography.pageTitle.copyWith(color: ApexColors.neutral900)),
          const Spacer(),
          if (!isMobile) ...[
            IconButton(icon: const Icon(Icons.download, size: 18), tooltip: 'Export', onPressed: () {}),
            IconButton(icon: const Icon(Icons.upload, size: 18), tooltip: 'Import', onPressed: () {}),
            IconButton(icon: const Icon(Icons.domain, size: 18), tooltip: 'Departments', onPressed: () => context.push('/departments')),
          ],
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  final String search;
  final ValueChanged<String> onSearch;
  final String? deptFilter;
  final String? statusFilter;
  final ValueChanged<String?> onDeptChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;
  final AsyncValue deptsAsync;

  const _Toolbar({
    required this.search,
    required this.onSearch,
    required this.deptFilter,
    required this.statusFilter,
    required this.onDeptChanged,
    required this.onStatusChanged,
    required this.onClear,
    required this.deptsAsync,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, code, email...',
                prefixIcon: Icon(Icons.search, size: 18, color: ApexColors.neutral400),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: ApexColors.neutral200),
                ),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          deptsAsync.maybeWhen(
            data: (deps) => _FilterChip(
              label: 'Department',
              value: deptFilter != null
                  ? deps.firstWhere((d) => d.id == deptFilter, orElse: () => deps.first).name
                  : null,
              onTap: () => _showDeptPicker(context, deps),
            ),
            orElse: () => const SizedBox(),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Status',
            value: statusFilter,
            onTap: () => _showStatusPicker(context),
          ),
          if (deptFilter != null || statusFilter != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onClear,
              icon: Icon(Icons.clear, size: 14, color: ApexColors.neutral500),
              label: Text('Clear', style: TextStyle(color: ApexColors.neutral500)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
            ),
          ],
        ],
      ),
    );
  }

  void _showDeptPicker(BuildContext context, List<dynamic> deps) {
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
                onDeptChanged(null);
                Navigator.pop(context);
              });
              final d = deps[i - 1];
              return ListTile(title: Text(d.name), onTap: () {
                onDeptChanged(d.id);
                Navigator.pop(context);
              });
            },
          ),
        ),
      ),
    );
  }

  void _showStatusPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: const Text('All'), onTap: () { onStatusChanged(null); Navigator.pop(context); }),
            ListTile(title: const Text('Active'), onTap: () { onStatusChanged('active'); Navigator.pop(context); }),
            ListTile(title: const Text('Inactive'), onTap: () { onStatusChanged('inactive'); Navigator.pop(context); }),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _FilterChip({required this.label, this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value != null ? ApexColors.primary.withValues(alpha: 0.1) : null,
          border: Border.all(color: value != null ? ApexColors.primary : ApexColors.neutral200),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: ApexTypography.captionLarge.copyWith(
              color: value != null ? ApexColors.primary : ApexColors.neutral500,
            )),
            const SizedBox(width: 4),
            Icon(value != null ? Icons.close : Icons.arrow_drop_down, size: 14,
              color: value != null ? ApexColors.primary : ApexColors.neutral500),
          ],
        ),
      ),
    );
  }
}

class _BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _BulkBar({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: ApexColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          Text('$count selected', style: ApexTypography.titleSmall.copyWith(color: ApexColors.primary)),
          const Spacer(),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Export')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.person_off, size: 16), label: const Text('Deactivate')),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

class _EmployeeTable extends StatelessWidget {
  final List<dynamic> employees;
  final Set<String> selected;
  final void Function(String, bool) onSelect;
  final void Function(bool) onSelectAll;
  final void Function(dynamic) onTap;

  const _EmployeeTable({
    required this.employees,
    required this.selected,
    required this.onSelect,
    required this.onSelectAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 1000),
        child: Column(
          children: [
            Container(
              height: 36,
              color: ApexColors.neutral50,
              child: Row(
                children: [
                  _hdr(40, '', isCheckbox: true),
                  _hdr(180, 'EMPLOYEE'),
                  _hdr(90, 'CODE'),
                  _hdr(120, 'DEPARTMENT'),
                  _hdr(120, 'DESIGNATION'),
                  _hdr(100, 'BRANCH'),
                  _hdr(80, 'STATUS'),
                  _hdr(60, ''),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: employees.length,
                itemBuilder: (context, i) => _EmployeeRow(
                  employee: employees[i],
                  index: i,
                  isSelected: selected.contains(employees[i].id),
                  onSelect: (v) => onSelect(employees[i].id, v),
                  onTap: () => onTap(employees[i]),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _hdr(double width, String label, {bool isCheckbox = false}) {
    return SizedBox(
      width: width,
      child: isCheckbox
          ? Checkbox(
              value: false,
              onChanged: (v) => onSelectAll(v ?? false),
              visualDensity: VisualDensity.compact,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label, style: ApexTypography.tableHeader),
              ),
            ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  final dynamic employee;
  final int index;
  final bool isSelected;
  final ValueChanged<bool> onSelect;
  final VoidCallback onTap;

  const _EmployeeRow({
    required this.employee,
    required this.index,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final emp = employee;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        color: isSelected ? ApexColors.primary.withValues(alpha: 0.05) : (index.isEven ? Colors.white : ApexColors.neutral50),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => onSelect(v ?? false),
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(
              width: 180,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
                      child: emp.photoUrl == null
                          ? Text(emp.firstName[0].toUpperCase(), style: ApexTypography.captionSmall)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(emp.fullName, style: ApexTypography.tableCell.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 90, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.employeeCode, style: ApexTypography.tableCell))),
            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.departmentName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.designationName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            SizedBox(width: 100, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.branchName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            SizedBox(
              width: 80,
              child: _StatusBadge(status: emp.status),
            ),
            SizedBox(
              width: 60,
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'active';
    return isActive ? ApexBadge.success('ACTIVE') : ApexBadge.neutral('INACTIVE');
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: ApexColors.neutral500),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ApexButton(
                label: actionLabel!,
                onPressed: onAction,
                type: ApexButtonType.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
