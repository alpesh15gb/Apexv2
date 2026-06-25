import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/responsive.dart';
import '../../design_system/typography.dart';
import '../../providers/leave_provider.dart';

const _bg = Color(0xFFF8FAFC);
const _surface = Color(0xFFFFFFFF);
const _border = Color(0xFFE5E7EB);
const _primary = Color(0xFF2563EB);
const _success = Color(0xFF16A34A);
const _warning = Color(0xFFF59E0B);
const _danger = Color(0xFFDC2626);
const _text = Color(0xFF111827);
const _muted = Color(0xFF6B7280);

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
      backgroundColor: _bg,
      body: Column(
        children: [
          // Header
          _Header(isMobile: isMobile),
          // Status filters
          _StatusFilters(
            selected: _statusFilter,
            onChanged: (v) {
              setState(() => _statusFilter = v);
              ref.read(leaveRequestsProvider.notifier).setFilters(status: v);
            },
          ),
          // List
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
                    const Icon(Icons.error_outline, size: 40, color: _danger),
                    const SizedBox(height: 12),
                    Text('Error: ${e.toString()}', style: ApexTypography.bodySmall),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(leaveRequestsProvider.notifier).fetchRequests(isRefresh: true),
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
        onPressed: () => context.push('/leaves/apply'),
        backgroundColor: _primary,
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
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Text('Leave Requests', style: ApexTypography.pageTitle.copyWith(color: _text)),
          const Spacer(),
          if (!isMobile) ...[
            IconButton(icon: const Icon(Icons.history, size: 18), tooltip: 'Leave Balances', onPressed: () => context.push('/leaves/balance')),
          ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border)),
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
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.1) : null,
          border: Border.all(color: isSelected ? _primary : _border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: ApexTypography.captionLarge.copyWith(
          color: isSelected ? _primary : _muted,
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
      padding: const EdgeInsets.all(12),
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
    final statusConfig = _statusConfig(r.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                child: Text((r.employeeName ?? 'U')[0].toUpperCase(), style: ApexTypography.captionSmall),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.employeeName ?? 'Unknown', style: ApexTypography.titleSmall.copyWith(color: _text)),
                    Text('${r.leaveTypeName ?? 'Leave'} • ${DateFormat('MMM dd').format(r.startDate)} - ${DateFormat('MMM dd').format(r.endDate)}',
                      style: ApexTypography.captionMedium.copyWith(color: _muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusConfig.$2.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusConfig.$1, style: ApexTypography.captionSmall.copyWith(color: statusConfig.$2, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (r.reason != null && r.reason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(r.reason!, style: ApexTypography.bodySmall.copyWith(color: _muted), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          if (r.status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showRejectDialog(context),
                  child: const Text('Reject', style: TextStyle(color: _danger)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Leave'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onReject(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _danger, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  (String, Color) _statusConfig(String s) {
    switch (s) {
      case 'pending': return ('Pending', _warning);
      case 'approved': return ('Approved', _success);
      case 'rejected': return ('Rejected', _danger);
      case 'cancelled': return ('Cancelled', _muted);
      default: return (s, _muted);
    }
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
