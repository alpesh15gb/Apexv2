import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/border_radius.dart';
import '../../design_system/components/apex_card.dart';
import '../../design_system/components/apex_badge.dart';
import '../../design_system/components/apex_empty_state.dart';
import '../../design_system/components/apex_loading_skeleton.dart';
import '../../design_system/components/apex_button.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
import '../../providers/shift_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/leave_provider.dart';
import '../../services/employee_service.dart';

final employeeDetailProvider = FutureProvider.family<Employee, String>((ref, id) async {
  final service = ref.read(employeeServiceProvider);
  return await service.getEmployee(id);
});

class EmployeeDetailScreen extends ConsumerStatefulWidget {
  final String employeeId;

  const EmployeeDetailScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  ConsumerState<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends ConsumerState<EmployeeDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(employeeDetailProvider(widget.employeeId));
    final isMobile = Responsive.isMobile(context);

    return detailAsync.when(
      data: (emp) => Scaffold(
        appBar: AppBar(
          title: Text(emp.fullName),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _showEditDialog(context, ref, emp),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'View Attendance',
              onPressed: () => context.push('/attendance/detail?employeeId=${emp.id}'),
            ),
          ],
        ),
        body: Column(
          children: [
            // Profile Header
            _buildProfileHeader(context, emp, isMobile),

            // Tabs
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Leaves'),
                  Tab(text: 'Emergency'),
                  Tab(text: 'Devices'),
                  Tab(text: 'Activity'),
                  Tab(text: 'Audit'),
                ],
                labelColor: ApexColors.primary,
                unselectedLabelColor: ApexColors.neutral500,
                indicatorColor: ApexColors.primary,
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(employee: emp),
                  _AttendanceTab(employeeId: emp.id),
                  _LeavesTab(employeeId: emp.id),
                  _EmergencyTab(employee: emp),
                  _DevicesTab(employeeId: emp.id),
                  _ActivityTab(employeeId: emp.id),
                  _AuditTab(employeeId: emp.id),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const ApexLoadingSkeleton(count: 5, type: ApexSkeletonType.list),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ApexColors.error),
              const SizedBox(height: 16),
              Text('Error: ${err.toString()}', style: ApexTypography.bodyMedium),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(employeeDetailProvider(widget.employeeId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Employee emp, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? ApexColors.darkSurface
            : ApexColors.neutral0,
        border: const Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildAvatar(emp),
                const SizedBox(height: 12),
                _buildProfileInfo(context, emp),
              ],
            )
          : Row(
              children: [
                _buildAvatar(emp),
                const SizedBox(width: 24),
                Expanded(child: _buildProfileInfo(context, emp)),
                _buildQuickActions(context, emp),
              ],
            ),
    );
  }

  Widget _buildAvatar(Employee emp) {
    return CircleAvatar(
      radius: 28,
      backgroundImage: emp.photoUrl != null ? NetworkImage(emp.photoUrl!) : null,
      child: emp.photoUrl == null
          ? Text(
              emp.firstName[0].toUpperCase(),
              style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary),
            )
          : null,
    );
  }

  Widget _buildProfileInfo(BuildContext context, Employee emp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              emp.fullName,
              style: ApexTypography.headingMedium.copyWith(
                color: Theme.of(context).brightness == Brightness.dark
                    ? ApexColors.darkOnSurface
                    : ApexColors.neutral900,
              ),
            ),
            const SizedBox(width: 8),
            ApexBadge(status: emp.status, category: 'employee'),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '${emp.employeeCode} • ${emp.designationName ?? 'No Designation'}',
          style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (emp.departmentName != null)
              _buildInfoChip(Icons.business, emp.departmentName!),
            if (emp.branchName != null)
              _buildInfoChip(Icons.location_on, emp.branchName!),
            if (emp.shiftName != null)
              _buildInfoChip(Icons.schedule, emp.shiftName!),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ApexColors.neutral100,
        borderRadius: ApexRadius.mdAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ApexColors.neutral500),
          const SizedBox(width: 6),
          Text(label, style: ApexTypography.captionLarge),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, Employee emp) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: () => context.push('/attendance/detail?employeeId=${emp.id}'),
          icon: const Icon(Icons.calendar_today, size: 18),
          label: const Text('Attendance'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () => context.push('/leaves/requests'),
          icon: const Icon(Icons.event_busy, size: 18),
          label: const Text('Leaves'),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Employee emp) {
    // TODO: Implement edit dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon')),
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Employee employee;

  const _OverviewTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection('Personal Information', [
            _buildDetail('Email', employee.email ?? 'N/A'),
            _buildDetail('Phone', employee.phone ?? 'N/A'),
            _buildDetail('Gender', employee.gender ?? 'N/A'),
            _buildDetail('Blood Group', employee.bloodGroup ?? 'N/A'),
            _buildDetail('Date of Birth', employee.dateOfBirth != null
                ? DateFormat('MMM dd, yyyy').format(employee.dateOfBirth!)
                : 'N/A'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Employment Details', [
            _buildDetail('Employee Code', employee.employeeCode),
            _buildDetail('Joining Date', DateFormat('MMM dd, yyyy').format(employee.joiningDate)),
            _buildDetail('Department', employee.departmentName ?? 'N/A'),
            _buildDetail('Designation', employee.designationName ?? 'N/A'),
            _buildDetail('Branch', employee.branchName ?? 'N/A'),
            _buildDetail('Shift', employee.shiftName ?? 'N/A'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Address', [
            _buildDetail('Street', employee.address ?? 'N/A'),
            _buildDetail('City', employee.city ?? 'N/A'),
            _buildDetail('State', employee.state ?? 'N/A'),
            _buildDetail('Pincode', employee.pincode ?? 'N/A'),
          ]),
          const SizedBox(height: 24),
          _buildSection('Emergency Contact', [
            _buildDetail('Name', employee.emergencyContactName ?? 'N/A'),
            _buildDetail('Phone', employee.emergencyContactPhone ?? 'N/A'),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ApexCard(
      header: Text(title, style: ApexTypography.titleMedium),
      child: Column(children: children),
    );
  }

  Widget _buildDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
          ),
          Expanded(child: Text(value, style: ApexTypography.bodyMedium)),
        ],
      ),
    );
  }
}

// ── Attendance Tab ───────────────────────────────────────────────

class _AttendanceTab extends ConsumerWidget {
  final String employeeId;

  const _AttendanceTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the attendance provider to get employee attendance
    return Center(
      child: ApexCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_month, size: 48, color: ApexColors.primary),
            const SizedBox(height: 16),
            Text('Attendance History', style: ApexTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'View detailed attendance records for this employee.',
              style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => context.push('/attendance/detail?employeeId=$employeeId'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Leaves Tab ───────────────────────────────────────────────────

class _LeavesTab extends ConsumerWidget {
  final String employeeId;

  const _LeavesTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(leaveBalanceProvider(employeeId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave Balance', style: ApexTypography.headingSmall),
          const SizedBox(height: 16),
          balanceAsync.when(
            data: (balances) {
              if (balances.isEmpty) {
                return const ApexEmptyState(
                  icon: Icons.event_busy_outlined,
                  title: 'No Leave Balances',
                  description: 'Leave balances will appear here once configured.',
                );
              }
              return Column(
                children: balances.map((b) {
                  return ApexCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.leaveTypeName ?? 'Leave', style: ApexTypography.titleMedium),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildLeaveStat('Total', '${b.totalDays}', ApexColors.neutral600),
                                  const SizedBox(width: 16),
                                  _buildLeaveStat('Used', '${b.usedDays}', ApexColors.error),
                                  const SizedBox(width: 16),
                                  _buildLeaveStat('Pending', '${b.pendingDays}', ApexColors.warning),
                                  const SizedBox(width: 16),
                                  _buildLeaveStat('Available', '${b.availableDays}', ApexColors.success),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const ApexLoadingSkeleton(count: 3, type: ApexSkeletonType.card),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: ApexTypography.titleLarge.copyWith(color: color)),
        Text(label, style: ApexTypography.captionSmall.copyWith(color: ApexColors.neutral500)),
      ],
    );
  }
}

// ── Activity Tab ─────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final String employeeId;

  const _ActivityTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ApexCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline, size: 48, color: ApexColors.primary),
            const SizedBox(height: 16),
            Text('Activity Timeline', style: ApexTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Employee activity and audit logs will appear here.',
              style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Emergency Tab ────────────────────────────────────────────────

class _EmergencyTab extends StatelessWidget {
  final Employee employee;

  const _EmergencyTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ApexCard(
            header: Row(
              children: [
                const Icon(Icons.emergency, color: ApexColors.error, size: 20),
                const SizedBox(width: 8),
                Text('Emergency Contact', style: ApexTypography.titleMedium),
              ],
            ),
            child: Column(
              children: [
                _buildContactRow('Name', employee.emergencyContactName ?? 'Not provided'),
                const Divider(height: 1),
                _buildContactRow('Phone', employee.emergencyContactPhone ?? 'Not provided'),
                const Divider(height: 1),
                _buildContactRow('Relationship', 'Not specified'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ApexCard(
            header: Text('Blood Group', style: ApexTypography.titleMedium),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ApexColors.error.withOpacity(0.1),
                    borderRadius: ApexRadius.mdAll,
                  ),
                  child: const Icon(Icons.bloodtype, color: ApexColors.error),
                ),
                const SizedBox(width: 16),
                Text(
                  employee.bloodGroup ?? 'Not specified',
                  style: ApexTypography.headingMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
          Text(value, style: ApexTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Devices Tab ──────────────────────────────────────────────────

class _DevicesTab extends StatelessWidget {
  final String employeeId;

  const _DevicesTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ApexCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.devices, size: 48, color: ApexColors.primary),
            const SizedBox(height: 16),
            Text('Assigned Devices', style: ApexTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Biometric devices and access cards assigned to this employee will appear here.',
              style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/devices'),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Devices'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Audit Tab ────────────────────────────────────────────────────

class _AuditTab extends StatelessWidget {
  final String employeeId;

  const _AuditTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ApexCard(
        margin: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history, size: 48, color: ApexColors.primary),
            const SizedBox(height: 16),
            Text('Audit History', style: ApexTypography.headingMedium),
            const SizedBox(height: 8),
            Text(
              'Changes to employee records, attendance modifications, and system actions will appear here.',
              style: ApexTypography.bodyMedium.copyWith(color: ApexColors.neutral500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
