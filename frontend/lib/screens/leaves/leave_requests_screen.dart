import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../providers/leave_provider.dart';
import '../../widgets/apex_badge.dart';
import '../../widgets/apex_button.dart';
import '../../widgets/apex_card.dart';
import '../../widgets/apex_text_field.dart';

class LeaveRequestsScreen extends ConsumerStatefulWidget {
  const LeaveRequestsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LeaveRequestsScreen> createState() => _LeaveRequestsScreenState();
}

class _LeaveRequestsScreenState extends ConsumerState<LeaveRequestsScreen> {
  String? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(leaveRequestsProvider);
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: ApexColors.neutral50,
      body: Column(
        children: [
          _Header(isMobile: isMobile),
          _StatusFilters(
            selected: _statusFilter,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              ref.read(leaveRequestsProvider.notifier).setFilters(status: v);
            },
          ),
          Expanded(
            child: listState.requests.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return _EmptyState(
                    icon: Icons.event_busy,
                    title: 'No Leave Requests',
                    description: 'No leave requests matching your filters.',
                    actionLabel: 'Apply Leave',
                    onAction: () => context.push('/leaves/apply'),
                  );
                }
                return _LeaveList(
                  requests: requests,
                  onApprove: (id) => ref.read(leaveRequestsProvider.notifier).approve(id),
                  onReject: (id, reason) => ref.read(leaveRequestsProvider.notifier).reject(id, reason),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 40, color: ApexColors.error),
                    const SizedBox(height: 16),
                    Text('Failed to load requests', style: ApexTypography.body.copyWith(color: ApexColors.neutral600)),
                    const SizedBox(height: 16),
                    ApexButton(
                      label: 'Retry',
                      type: ApexButtonType.outline,
                      onPressed: () => ref.read(leaveRequestsProvider.notifier).fetchRequests(isRefresh: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/leaves/apply'),
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
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: Row(
        children: [
          Text('Leave Requests', style: ApexTypography.sectionTitle),
          const Spacer(),
          if (!isMobile)
            IconButton(
              icon: Icon(Icons.history, size: 18, color: ApexColors.neutral600),
              tooltip: 'Leave Balances',
              onPressed: () => context.push('/leaves/balance'),
            ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _StatusFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: ApexColors.neutral200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _chip('All', null),
            const SizedBox(width: 8),
            _chip('Pending', 'pending'),
            const SizedBox(width: 8),
            _chip('Approved', 'approved'),
            const SizedBox(width: 8),
            _chip('Rejected', 'rejected'),
            const SizedBox(width: 8),
            _chip('Cancelled', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final isSelected = selected == value;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ApexColors.primary50 : null,
          border: Border.all(color: isSelected ? ApexColors.primary : ApexColors.neutral200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: ApexTypography.captionLarge.copyWith(
          color: isSelected ? ApexColors.primary : ApexColors.neutral500,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

class _LeaveList extends StatelessWidget {
  final List<dynamic> requests;
  final void Function(String) onApprove;
  final void Function(String, String) onReject;

  const _LeaveList({required this.requests, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        return _LeaveCard(request: r, onApprove: () => onApprove(r.id), onReject: (reason) => onReject(r.id, reason));
      },
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final dynamic request;
  final VoidCallback onApprove;
  final void Function(String) onReject;

  const _LeaveCard({required this.request, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final r = request;
    final statusBadge = _statusBadge(r.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ApexCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: ApexColors.primary50,
                  child: Text(
                    (r.employeeName ?? 'U')[0].toUpperCase(),
                    style: ApexTypography.captionSmall.copyWith(color: ApexColors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.employeeName ?? 'Unknown', style: ApexTypography.titleSmall.copyWith(color: ApexColors.neutral900)),
                      Text(
                        '${r.leaveTypeName ?? 'Leave'} · ${DateFormat('MMM dd').format(r.startDate)} - ${DateFormat('MMM dd').format(r.endDate)}',
                        style: ApexTypography.captionMedium.copyWith(color: ApexColors.neutral500),
                      ),
                    ],
                  ),
                ),
                statusBadge,
              ],
            ),
            if (r.reason != null && r.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(r.reason!, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            if (r.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ApexButton(
                    label: 'Reject',
                    type: ApexButtonType.danger,
                    onPressed: () => _showRejectDialog(context),
                  ),
                  const SizedBox(width: 12),
                  ApexButton(
                    label: 'Approve',
                    type: ApexButtonType.success,
                    onPressed: onApprove,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  ApexBadge _statusBadge(String status) {
    switch (status) {
      case 'pending':
        return ApexBadge.warning('Pending');
      case 'approved':
        return ApexBadge.success('Approved');
      case 'rejected':
        return ApexBadge.danger('Rejected');
      case 'cancelled':
        return ApexBadge(label: 'Cancelled');
      default:
        return ApexBadge(label: status);
    }
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Leave', style: ApexTypography.sectionTitle),
        content: ApexTextField(
          label: 'Reason for rejection',
          controller: controller,
          maxLines: 3,
          required: true,
        ),
        actions: [
          ApexButton(label: 'Cancel', type: ApexButtonType.ghost, onPressed: () => Navigator.pop(context)),
          ApexButton(
            label: 'Reject',
            type: ApexButtonType.danger,
            onPressed: () {
              onReject(controller.text);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({required this.icon, required this.title, required this.description, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: ApexColors.neutral300),
            const SizedBox(height: 16),
            Text(title, style: ApexTypography.cardTitle.copyWith(color: ApexColors.neutral900)),
            const SizedBox(height: 8),
            Text(description, style: ApexTypography.bodySmall.copyWith(color: ApexColors.neutral500), textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ApexButton(label: actionLabel!, type: ApexButtonType.primary, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
