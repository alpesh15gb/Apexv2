import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/dio_client.dart';
import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../models/employee.dart';
import '../../providers/employee_provider.dart';
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
    _tabController = TabController(length: 6, vsync: this);
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
        backgroundColor: ApexColors.neutral50,
        body: Column(
          children: [
            // Header
            _ProfileHeader(
              employee: emp,
              isMobile: isMobile,
            ),
            // Tabs
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Attendance'),
                  Tab(text: 'Leaves'),
                  Tab(text: 'Devices'),
                  Tab(text: 'Emergency'),
                  Tab(text: 'Activity'),
                ],
                labelColor: ApexColors.primary,
                unselectedLabelColor: ApexColors.neutral500,
                indicatorColor: ApexColors.primary,
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _OverviewTab(employee: emp),
                  _AttendanceTab(employeeId: emp.id),
                  _LeavesTab(employeeId: emp.id),
                  _DevicesTab(employeeId: emp.id),
                  _EmergencyTab(employee: emp),
                  _ActivityTab(employeeId: emp.id),
                ],
              ),
            ),
          ],
        ),
      ),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: ApexColors.error),
              const SizedBox(height: 12),
              Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
              const SizedBox(height: 12),
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
}

// ── Profile Header ──────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final Employee employee;
  final bool isMobile;

  const _ProfileHeader({required this.employee, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: isMobile
          ? Column(
              children: [
                _avatar(),
                const SizedBox(height: 12),
                _info(context),
              ],
            )
          : Row(
              children: [
                _avatar(),
                const SizedBox(width: 16),
                Expanded(child: _info(context)),
                _actions(context),
              ],
            ),
    );
  }

  Widget _avatar() {
    return CircleAvatar(
      radius: 28,
      backgroundImage: employee.photoUrl != null ? NetworkImage(employee.photoUrl!) : null,
      child: employee.photoUrl == null
          ? Text(employee.firstName[0].toUpperCase(), style: ApexTypography.titleLarge.copyWith(color: ApexColors.primary))
          : null,
    );
  }

  Widget _info(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(employee.fullName, style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
            const SizedBox(width: 8),
            _StatusBadge(status: employee.status),
          ],
        ),
        const SizedBox(height: 2),
        Text('${employee.employeeCode} • ${employee.designationName ?? 'No Designation'}',
          style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (employee.departmentName != null) _infoChip(Icons.business, employee.departmentName!),
            if (employee.branchName != null) _infoChip(Icons.location_on, employee.branchName!),
            if (employee.shiftName != null) _infoChip(Icons.schedule, employee.shiftName!),
          ],
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ApexColors.neutral50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ApexColors.neutral500),
          const SizedBox(width: 4),
          Text(label, style: ApexTypography.captionSmall),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      children: [
        IconButton(icon: const Icon(Icons.edit, size: 18), tooltip: 'Edit', onPressed: () => context.push('/employees/${employee.id}/edit')),
        IconButton(icon: const Icon(Icons.calendar_today, size: 18), tooltip: 'Attendance', onPressed: () => context.push('/attendance/detail?employeeId=${employee.id}')),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'deactivate', child: Text('Deactivate')),
          ],
          onSelected: (v) {},
        ),
      ],
    );
  }
}

// ── Overview Tab ─────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final Employee employee;
  const _OverviewTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Current Status
          _Section(
            title: 'CURRENT STATUS',
            child: Column(
              children: [
                _statusRow('Status', employee.status.toUpperCase(), employee.status == 'active' ? ApexColors.success : ApexColors.error),
                _statusRow('Shift', employee.shiftName ?? 'Not assigned', ApexColors.primary),
                _statusRow('Department', employee.departmentName ?? 'Not assigned', ApexColors.neutral500),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Personal + Employment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Section(
                  title: 'PERSONAL',
                  child: Column(
                    children: [
                      _detailRow('Email', employee.email ?? '—'),
                      _detailRow('Phone', employee.phone ?? '—'),
                      _detailRow('Gender', employee.gender ?? '—'),
                      _detailRow('Blood Group', employee.bloodGroup ?? '—'),
                      _detailRow('DOB', employee.dateOfBirth != null ? DateFormat('MMM dd, yyyy').format(employee.dateOfBirth!) : '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Section(
                  title: 'EMPLOYMENT',
                  child: Column(
                    children: [
                      _detailRow('Code', employee.employeeCode),
                      _detailRow('Department', employee.departmentName ?? '—'),
                      _detailRow('Designation', employee.designationName ?? '—'),
                      _detailRow('Branch', employee.branchName ?? '—'),
                      _detailRow('Joined', employee.joiningDate != null ? DateFormat('MMM dd, yyyy').format(employee.joiningDate!) : '—'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Address
          _Section(
            title: 'ADDRESS',
            child: Column(
              children: [
                _detailRow('Street', employee.address ?? '—'),
                _detailRow('City', employee.city ?? '—'),
                _detailRow('State', employee.state ?? '—'),
                _detailRow('Pincode', employee.pincode ?? '—'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(label, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
          const Spacer(),
          Text(value, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600, color: ApexColors.neutral900)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500))),
          Expanded(child: Text(value, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ── Attendance Tab ───────────────────────────────────────────
class _AttendanceTab extends StatelessWidget {
  final String employeeId;
  const _AttendanceTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 48, color: ApexColors.neutral500),
          const SizedBox(height: 16),
          Text('Attendance History', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('View detailed attendance records', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.push('/attendance/detail?employeeId=$employeeId'),
            style: ElevatedButton.styleFrom(backgroundColor: ApexColors.primary, foregroundColor: Colors.white),
            child: const Text('View Attendance'),
          ),
        ],
      ),
    );
  }
}

// ── Leaves Tab ───────────────────────────────────────────────
class _LeavesTab extends ConsumerWidget {
  final String employeeId;
  const _LeavesTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(leaveBalanceProvider(employeeId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: balanceAsync.when(
        data: (balances) {
          if (balances.isEmpty) {
            return const _EmptyBlock(msg: 'No leave balances configured');
          }
          return Column(
            children: balances.map((b) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ApexColors.neutral200),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(b.leaveTypeName ?? 'Leave', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900))),
                  _leaveStat('Total', '${b.totalDays}'),
                  _leaveStat('Used', '${b.usedDays}'),
                  _leaveStat('Pending', '${b.pendingDays}'),
                  _leaveStat('Available', '${b.availableDays}'),
                ],
              ),
            )).toList(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }

  Widget _leaveStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(value, style: ApexTypography.titleMedium.copyWith(color: ApexColors.neutral900)),
          Text(label, style: ApexTypography.kpiLabel),
        ],
      ),
    );
  }
}

// ── Devices Tab ──────────────────────────────────────────────
class _DevicesTab extends StatelessWidget {
  final String employeeId;
  const _DevicesTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.biotech, size: 48, color: ApexColors.neutral500),
          const SizedBox(height: 16),
          Text('Assigned Devices', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('Biometric devices assigned to this employee', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}

// ── Emergency Tab ────────────────────────────────────────────
class _EmergencyTab extends StatelessWidget {
  final Employee employee;
  const _EmergencyTab({required this.employee});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _Section(
            title: 'EMERGENCY CONTACT',
            child: Column(
              children: [
                _detailRow('Name', employee.emergencyContactName ?? 'Not provided'),
                _detailRow('Phone', employee.emergencyContactPhone ?? 'Not provided'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'BLOOD GROUP',
            child: Row(
              children: [
                Icon(Icons.bloodtype, color: ApexColors.error),
                const SizedBox(width: 12),
                Text(employee.bloodGroup ?? 'Not specified', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500))),
          Expanded(child: Text(value, style: ApexTypography.bodySmall.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

// ── Activity Tab ─────────────────────────────────────────────
class _ActivityTab extends StatelessWidget {
  final String employeeId;
  const _ActivityTab({required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timeline, size: 48, color: ApexColors.neutral500),
          const SizedBox(height: 16),
          Text('Activity Timeline', style: ApexTypography.headingMedium.copyWith(color: ApexColors.neutral900)),
          const SizedBox(height: 8),
          Text('Employee activity and audit logs', style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500)),
        ],
      ),
    );
  }
}

// ── Shared Widgets ───────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ApexColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ApexTypography.sectionHeader),
          const SizedBox(height: 8),
          child,
        ],
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
        color: isActive ? ApexColors.success.withOpacity(0.1) : ApexColors.neutral500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: ApexTypography.captionSmall.copyWith(
          color: isActive ? ApexColors.success : ApexColors.neutral500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  final String msg;
  const _EmptyBlock({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(child: Text(msg, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500))),
    );
  }
}


