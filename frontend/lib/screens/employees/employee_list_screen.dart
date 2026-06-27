import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/border_radius.dart';
import '../../providers/employee_provider.dart';

// ── RULE 1: Exact colors ───────────────────────────────────
const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
      body: Column(
        children: [
          // ── RULE 4: Header ──────────────────────────────
          _Header(isMobile: isMobile),
          // ── RULE 5: Search + Filters always visible ─────
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
          // ── RULE 5: Bulk actions always visible ─────────
          if (_selected.isNotEmpty) _BulkBar(count: _selected.length, onClear: () => setState(() => _selected.clear())),
          // ── RULE 10: Table — 40px rows ──────────────────
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
                    decoration: const BoxDecoration(
                      color: _surface,
                      border: Border(bottom: BorderSide(color: _border, width: 1)),
                    ),
                    child: Row(children: [
                      const SizedBox(width: 50),
                      const Expanded(flex: 3, child: Text('EMPLOYEE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const Expanded(flex: 2, child: Text('DESIGNATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const Expanded(child: Text('BRANCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
                      const SizedBox(width: 70, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _muted, letterSpacing: 0.5))),
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
                            color: i.isEven ? _surface : _bg,
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
                                  backgroundColor: _primary.withOpacity(0.1),
                                  child: Text(
                                    emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : '?',
                                    style: TextStyle(color: _primary, fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(flex: 3, child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(emp.fullName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
                                    const SizedBox(height: 2),
                                    Text(emp.employeeCode, style: const TextStyle(fontSize: 12, color: _muted)),
                                  ],
                                )),
                                Expanded(flex: 2, child: Text(emp.departmentName ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
                                Expanded(flex: 2, child: Text(emp.designationName ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
                                Expanded(child: Text(emp.branchName ?? '—', style: const TextStyle(fontSize: 13, color: _text), overflow: TextOverflow.ellipsis)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: emp.status == 'active' ? _success.withOpacity(0.1) : _muted.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    emp.status.toUpperCase(),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: emp.status == 'active' ? _success : _muted),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios, size: 14, color: _muted),
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
                        const Icon(Icons.error_outline, size: 40, color: _danger),
                        const SizedBox(height: 12),
                        Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
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
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── RULE 4: Header ─────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isMobile;
  const _Header({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 20, 12, isMobile ? 16 : 20, 8),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('Employees', style: ApexTypography.pageTitle.copyWith(color: _text)),
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

// ── RULE 5: Toolbar — search + filters always visible ───────
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
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          // Search
          Expanded(
            flex: 3,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, code, email...',
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _border),
                ),
                isDense: true,
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(width: 12),
          // Department filter
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
          // Status filter
          _FilterChip(
            label: 'Status',
            value: statusFilter,
            onTap: () => _showStatusPicker(context),
          ),
          if (deptFilter != null || statusFilter != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear, size: 14),
              label: const Text('Clear'),
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
          color: value != null ? _primary.withOpacity(0.1) : null,
          border: Border.all(color: value != null ? _primary : _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value ?? label, style: ApexTypography.captionLarge.copyWith(
              color: value != null ? _primary : _muted,
            )),
            const SizedBox(width: 4),
            Icon(value != null ? Icons.close : Icons.arrow_drop_down, size: 14,
              color: value != null ? _primary : _muted),
          ],
        ),
      ),
    );
  }
}

// ── RULE 5: Bulk actions always visible ─────────────────────
class _BulkBar extends StatelessWidget {
  final int count;
  final VoidCallback onClear;

  const _BulkBar({required this.count, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: _primary.withOpacity(0.1),
      child: Row(
        children: [
          Text('$count selected', style: ApexTypography.titleSmall.copyWith(color: _primary)),
          const Spacer(),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 16), label: const Text('Export')),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.person_off, size: 16), label: const Text('Deactivate')),
          TextButton(onPressed: onClear, child: const Text('Clear')),
        ],
      ),
    );
  }
}

// ── RULE 10: Table — 40px rows, sticky header ──────────────
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
            // Header
            Container(
              height: 36,
              color: _bg,
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
            // Rows
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
        color: isSelected ? _primary.withOpacity(0.05) : (index.isEven ? _surface : _bg),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 40,
              child: Checkbox(
                value: isSelected,
                onChanged: (v) => onSelect(v ?? false),
                visualDensity: VisualDensity.compact,
              ),
            ),
            // Employee
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
            // Code
            SizedBox(width: 90, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.employeeCode, style: ApexTypography.tableCell))),
            // Department
            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.departmentName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            // Designation
            SizedBox(width: 120, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.designationName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            // Branch
            SizedBox(width: 100, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(emp.branchName ?? '—', style: ApexTypography.tableCell, overflow: TextOverflow.ellipsis))),
            // Status
            SizedBox(
              width: 80,
              child: _StatusBadge(status: emp.status),
            ),
            // Actions
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? _success.withOpacity(0.1) : _muted.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: ApexTypography.captionSmall.copyWith(
          color: isActive ? _success : _muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── RULE 9: Empty state — onboarding, not fake data ────────
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
            Icon(icon, size: 48, color: _muted),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.headingMedium.copyWith(color: _text)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: _muted), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
